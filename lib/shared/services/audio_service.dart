import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/audio/ambient_renderer.dart';
import '../../core/constants/sound_data.dart';
import 'web_audio_stub.dart' if (dart.library.html) 'web_audio.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

class AudioService {
  /// Native loops are rendered offline; 45 s is long enough that the random
  /// events do not feel repetitive and small enough to render in well under a
  /// second on a phone.
  static const _nativeLoopSeconds = 45.0;
  static const _nativeSampleRate = 32000;
  static const _nativeLoopCacheSize = 3;

  AudioPlayer? _alertPlayer;
  AudioPlayer? _ambientPlayer;
  final _random = Random();

  /// Rendered native loops keyed by soundscape id (small LRU).
  final _nativeLoopCache = <String, Uint8List>{};

  /// Incremented on every ambient request so a slow offline render cannot
  /// start playing after a newer request superseded it.
  int _ambientRequest = 0;

  /// True while `_ambientPlayer` is the active ambient source (native loops
  /// and streamed URLs). On the web, built-in soundscapes play through the
  /// Web Audio engine instead of `just_audio`.
  bool _ambientPlayerActive = false;

  Future<void> init() async {
    _alertPlayer = AudioPlayer();
    _ambientPlayer = AudioPlayer();
  }

  Future<void> playBuiltInSound(
    BuiltInSound sound, {
    double volume = 0.7,
  }) async {
    try {
      if (kIsWeb) {
        playBuiltInSoundOnWeb(
          sound.frequency.toDouble(),
          sound.durationSeconds,
          volume,
          sound.texture.name,
          sound.pulseCount,
        );
        return;
      }
      _alertPlayer?.stop();
      _alertPlayer = AudioPlayer();
      await _alertPlayer!.setVolume(volume);
      final audioData = _generateBuiltInSoundWav(sound, sampleRate: 44100);
      final source = _WavAudioSource(audioData);
      await _alertPlayer!.setAudioSource(source);
      await _alertPlayer!.play();
    } catch (e) {
      debugPrint('AudioService.playBuiltInSound error: $e');
    }
  }

  Future<void> playFocusSoundscape(
    FocusSoundscape soundscape, {
    double volume = 0.35,
  }) async {
    final request = ++_ambientRequest;
    try {
      if (kIsWeb) {
        await _stopAmbientPlayer();
        playAmbientRecipeOnWeb(jsonEncode(soundscape.recipe.toJson()), volume);
        return;
      }
      final audioData = await _nativeLoopFor(soundscape);
      if (request != _ambientRequest) {
        return;
      }
      await _recreateAmbientPlayer();
      await _ambientPlayer!.setVolume(volume);
      await _ambientPlayer!.setAudioSource(_WavAudioSource(audioData));
      await _ambientPlayer!.setLoopMode(LoopMode.one);
      _ambientPlayerActive = true;
      await _ambientPlayer!.play();
    } catch (e) {
      debugPrint('AudioService.playFocusSoundscape error: $e');
    }
  }

  Future<void> playAmbientUrl(String url, {double volume = 0.35}) async {
    _ambientRequest++;
    try {
      if (kIsWeb) {
        stopAmbientOnWeb();
      }
      await _recreateAmbientPlayer();
      await _ambientPlayer!.setVolume(volume);
      await _ambientPlayer!.setUrl(url);
      await _ambientPlayer!.setLoopMode(LoopMode.one);
      _ambientPlayerActive = true;
      await _ambientPlayer!.play();
    } catch (e) {
      debugPrint('AudioService.playAmbientUrl error: $e');
    }
  }

  Future<void> setAlertVolume(double volume) async {
    await _alertPlayer?.setVolume(volume);
  }

  Future<void> setAmbientVolume(double volume) async {
    if (kIsWeb) {
      setAmbientVolumeOnWeb(volume);
    }
    await _ambientPlayer?.setVolume(volume);
  }

  Future<void> stopAlert() async {
    await _alertPlayer?.stop();
  }

  Future<void> stopAmbient() async {
    _ambientRequest++;
    if (kIsWeb) {
      stopAmbientOnWeb();
    }
    await _stopAmbientPlayer();
  }

  Future<void> pauseAmbient() async {
    if (kIsWeb) {
      pauseAmbientOnWeb();
    }
    if (_ambientPlayerActive) {
      await _ambientPlayer?.pause();
    }
  }

  Future<void> resumeAmbient() async {
    if (kIsWeb) {
      resumeAmbientOnWeb();
    }
    if (_ambientPlayerActive) {
      await _ambientPlayer?.play();
    }
  }

  Future<void> stopAll() async {
    try {
      await stopAlert();
    } catch (e) {
      debugPrint('AudioService.stopAlert error: $e');
    }
    try {
      await stopAmbient();
    } catch (e) {
      debugPrint('AudioService.stopAmbient error: $e');
    }
  }

  void requestWakeLock() {
    if (kIsWeb) requestWakeLockOnWeb();
  }

  void releaseWakeLock() {
    if (kIsWeb) releaseWakeLockOnWeb();
  }

  void dispose() {
    _alertPlayer?.dispose();
    _ambientPlayer?.dispose();
  }

  Future<void> _stopAmbientPlayer() async {
    _ambientPlayerActive = false;
    await _ambientPlayer?.stop();
  }

  Future<void> _recreateAmbientPlayer() async {
    await _stopAmbientPlayer();
    await _ambientPlayer?.dispose();
    _ambientPlayer = AudioPlayer();
  }

  Future<Uint8List> _nativeLoopFor(FocusSoundscape soundscape) async {
    final cached = _nativeLoopCache.remove(soundscape.id);
    if (cached != null) {
      _nativeLoopCache[soundscape.id] = cached;
      return cached;
    }
    final recipe = soundscape.recipe;
    final seed = _random.nextInt(1 << 30);
    final wav = await Isolate.run(
      () => const AmbientRenderer(
        sampleRate: _nativeSampleRate,
      ).render(recipe, loopSeconds: _nativeLoopSeconds, seed: seed).toWav(),
    );
    _nativeLoopCache[soundscape.id] = wav;
    if (_nativeLoopCache.length > _nativeLoopCacheSize) {
      _nativeLoopCache.remove(_nativeLoopCache.keys.first);
    }
    return wav;
  }

  /// 合成提示音 WAV（原生平台用；Web 走 focus_audio.js）
  Uint8List _generateBuiltInSoundWav(
    BuiltInSound sound, {
    required int sampleRate,
  }) {
    final numSamples = (sampleRate * sound.durationSeconds).toInt();
    final samples = Float64List(numSamples);
    final pulseGap = max(
      0.14,
      sound.durationSeconds / (sound.pulseCount + 1.8),
    );
    final baseFrequency = sound.frequency.toDouble();

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final pulseIndex = min(
        sound.pulseCount - 1,
        (t / pulseGap).floor().clamp(0, sound.pulseCount - 1),
      );
      final pulseStart = pulseIndex * pulseGap;
      final localTime = max(0.0, t - pulseStart);
      final pulseSpan = max(0.12, sound.durationSeconds - pulseStart);
      final envelope = exp(-3.8 * localTime / pulseSpan);
      final softGate =
          localTime > pulseGap * 0.92 && pulseIndex < sound.pulseCount - 1
          ? 0.0
          : 1.0;
      final pulseWeight = (1.0 - pulseIndex * 0.12).clamp(0.55, 1.0);
      final gate = envelope * pulseWeight * softGate;

      double sample;
      switch (sound.texture) {
        case BuiltInSoundTexture.bowl:
          sample =
              (sin(2 * pi * baseFrequency * t) +
                  0.48 * sin(2 * pi * baseFrequency * 2.02 * t + 0.15) +
                  0.2 * sin(2 * pi * baseFrequency * 2.98 * t + 0.4)) *
              gate *
              0.52;
          break;
        case BuiltInSoundTexture.chime:
          sample =
              (sin(2 * pi * baseFrequency * t) +
                  0.38 * sin(2 * pi * baseFrequency * 3 * t) +
                  0.18 * sin(2 * pi * baseFrequency * 4.6 * t)) *
              gate *
              0.42;
          break;
        case BuiltInSoundTexture.wood:
          final knock =
              (sin(2 * pi * baseFrequency * 0.78 * t) +
                  0.2 * sin(2 * pi * baseFrequency * 1.9 * t)) *
              gate *
              0.55;
          final click = sin(2 * pi * 2100 * t) * exp(-18 * localTime) * 0.05;
          sample = knock + click;
          break;
        case BuiltInSoundTexture.water:
          final glide = baseFrequency * (1.12 - 0.24 * (localTime / pulseSpan));
          sample =
              (sin(2 * pi * glide * t) +
                  0.16 * sin(2 * pi * glide * 2.2 * t + 0.3)) *
              gate *
              0.45;
          break;
        case BuiltInSoundTexture.digital:
          final carrier = sin(2 * pi * baseFrequency * t);
          final modulator = sin(2 * pi * baseFrequency * 0.5 * t) * 0.25;
          sample =
              (carrier +
                  modulator +
                  0.08 * sin(2 * pi * baseFrequency * 6 * t)) *
              gate *
              0.38;
          break;
        case BuiltInSoundTexture.pulse:
          final pulse = max(0.0, sin(2 * pi * baseFrequency * t));
          sample =
              (pulse * 0.9 + 0.18 * sin(2 * pi * baseFrequency * 2 * t)) *
              gate *
              0.44;
          break;
        case BuiltInSoundTexture.breath:
          final breath =
              0.5 - 0.5 * cos(pi * (localTime / pulseSpan).clamp(0.0, 1.0));
          sample =
              (sin(2 * pi * baseFrequency * t) * 0.7 +
                  0.12 * sin(2 * pi * baseFrequency * 0.5 * t)) *
              gate *
              breath *
              0.34;
          break;
        case BuiltInSoundTexture.crystal:
          sample =
              (sin(2 * pi * baseFrequency * t) +
                  0.55 * sin(2 * pi * baseFrequency * 2.7 * t + 0.2) +
                  0.24 * sin(2 * pi * baseFrequency * 5.1 * t + 0.35)) *
              gate *
              0.34;
          break;
        case BuiltInSoundTexture.harp:
          final pluck = exp(-5.5 * localTime / pulseSpan);
          sample =
              (sin(2 * pi * baseFrequency * t) +
                  0.3 * sin(2 * pi * baseFrequency * 2 * t + 0.4) +
                  0.1 * sin(2 * pi * baseFrequency * 4 * t + 0.8)) *
              pluck *
              gate *
              0.42;
          break;
      }

      if (i < sampleRate * 0.01) {
        sample *= i / (sampleRate * 0.01);
      }
      samples[i] = sample.clamp(-1.0, 1.0);
    }

    return _encodeWav(samples, sampleRate);
  }

  /// 将采样数据编码为 16 位 PCM WAV 格式
  Uint8List _encodeWav(Float64List samples, int sampleRate) {
    final numSamples = samples.length;
    const numChannels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = numSamples * blockAlign;
    final fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);
    // RIFF header
    buffer.setUint8(0, 0x52); // R
    buffer.setUint8(1, 0x49); // I
    buffer.setUint8(2, 0x46); // F
    buffer.setUint8(3, 0x46); // F
    buffer.setUint32(4, fileSize, Endian.little);
    buffer.setUint8(8, 0x57); // W
    buffer.setUint8(9, 0x41); // A
    buffer.setUint8(10, 0x56); // V
    buffer.setUint8(11, 0x45); // E
    // fmt chunk
    buffer.setUint8(12, 0x66); // f
    buffer.setUint8(13, 0x6D); // m
    buffer.setUint8(14, 0x74); // t
    buffer.setUint8(15, 0x20); // (space)
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little); // PCM
    buffer.setUint16(22, numChannels, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, byteRate, Endian.little);
    buffer.setUint16(32, blockAlign, Endian.little);
    buffer.setUint16(34, bitsPerSample, Endian.little);
    // data chunk
    buffer.setUint8(36, 0x64); // d
    buffer.setUint8(37, 0x61); // a
    buffer.setUint8(38, 0x74); // t
    buffer.setUint8(39, 0x61); // a
    buffer.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < numSamples; i++) {
      final sample = (samples[i].clamp(-1.0, 1.0) * 32767).toInt();
      buffer.setInt16(44 + i * 2, sample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}

/// 自定义 AudioSource，从内存中的 WAV 数据播放
class _WavAudioSource extends StreamAudioSource {
  final Uint8List _data;
  _WavAudioSource(this._data);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final s = start ?? 0;
    final e = end ?? _data.length;
    return StreamAudioResponse(
      sourceLength: _data.length,
      contentLength: e - s,
      offset: s,
      stream: Stream.value(_data.sublist(s, e)),
      contentType: 'audio/wav',
    );
  }
}
