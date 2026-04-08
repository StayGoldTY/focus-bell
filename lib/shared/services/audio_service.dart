import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/constants/sound_data.dart';
import 'web_audio_stub.dart' if (dart.library.html) 'web_audio.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

class AudioService {
  AudioPlayer? _alertPlayer;
  AudioPlayer? _ambientPlayer;
  final _random = Random();

  Future<void> init() async {
    _alertPlayer = AudioPlayer();
    _ambientPlayer = AudioPlayer();
  }

  Future<void> playBuiltInSound(BuiltInSound sound, {double volume = 0.7}) async {
    try {
      if (kIsWeb) {
        playToneOnWeb(sound.frequency.toDouble(), sound.durationSeconds, volume);
        return;
      }
      _alertPlayer?.stop();
      _alertPlayer = AudioPlayer();
      await _alertPlayer!.setVolume(volume);
      final audioData = _generateToneWav(
        frequency: sound.frequency.toDouble(),
        durationSeconds: sound.durationSeconds,
        sampleRate: 44100,
      );
      final source = _WavAudioSource(audioData);
      await _alertPlayer!.setAudioSource(source);
      await _alertPlayer!.play();
    } catch (e) {
      debugPrint('AudioService.playBuiltInSound error: $e');
    }
  }

  Future<void> playTone({
    double frequency = 440,
    double durationSeconds = 1.0,
    double volume = 0.7,
  }) async {
    try {
      if (kIsWeb) {
        playToneOnWeb(frequency, durationSeconds, volume);
        return;
      }
      _alertPlayer?.stop();
      _alertPlayer = AudioPlayer();
      await _alertPlayer!.setVolume(volume);
      final audioData = _generateToneWav(
        frequency: frequency,
        durationSeconds: durationSeconds,
        sampleRate: 44100,
      );
      final source = _WavAudioSource(audioData);
      await _alertPlayer!.setAudioSource(source);
      await _alertPlayer!.play();
    } catch (e) {
      debugPrint('AudioService.playTone error: $e');
    }
  }

  Future<void> playNoise({
    required NoiseType type,
    double volume = 0.5,
  }) async {
    try {
      await stopAmbient();
      _ambientPlayer = AudioPlayer();
      await _ambientPlayer!.setVolume(volume);
      final audioData = _generateNoiseWav(type: type, durationSeconds: 10, sampleRate: 44100);
      final source = _WavAudioSource(audioData);
      await _ambientPlayer!.setAudioSource(source);
      await _ambientPlayer!.setLoopMode(LoopMode.one);
      await _ambientPlayer!.play();
    } catch (e) {
      debugPrint('AudioService.playNoise error: $e');
    }
  }

  Future<void> setAlertVolume(double volume) async {
    await _alertPlayer?.setVolume(volume);
  }

  Future<void> setAmbientVolume(double volume) async {
    await _ambientPlayer?.setVolume(volume);
  }

  Future<void> stopAlert() async {
    await _alertPlayer?.stop();
  }

  Future<void> stopAmbient() async {
    await _ambientPlayer?.stop();
  }

  Future<void> stopAll() async {
    await stopAlert();
    await stopAmbient();
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

  /// 合成正弦波 WAV 数据（带淡入淡出避免爆音）
  Uint8List _generateToneWav({
    required double frequency,
    required double durationSeconds,
    required int sampleRate,
  }) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final fadeLength = (sampleRate * 0.05).toInt();

    final samples = Float64List(numSamples);
    for (var i = 0; i < numSamples; i++) {
      var amplitude = sin(2 * pi * frequency * i / sampleRate);

      // 多个泛音叠加使音色更丰富
      amplitude += 0.5 * sin(2 * pi * frequency * 2 * i / sampleRate);
      amplitude += 0.25 * sin(2 * pi * frequency * 3 * i / sampleRate);
      amplitude /= 1.75;

      // 淡入
      if (i < fadeLength) {
        amplitude *= i / fadeLength;
      }
      // 淡出
      if (i > numSamples - fadeLength) {
        amplitude *= (numSamples - i) / fadeLength;
      }

      // 指数衰减
      amplitude *= exp(-3.0 * i / numSamples);

      samples[i] = amplitude;
    }

    return _encodeWav(samples, sampleRate);
  }

  /// 生成噪音 WAV 数据
  Uint8List _generateNoiseWav({
    required NoiseType type,
    required double durationSeconds,
    required int sampleRate,
  }) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final samples = Float64List(numSamples);

    double lastValue = 0;
    for (var i = 0; i < numSamples; i++) {
      final white = _random.nextDouble() * 2 - 1;
      switch (type) {
        case NoiseType.white:
          samples[i] = white * 0.3;
          break;
        case NoiseType.brown:
          lastValue = (lastValue + white * 0.02).clamp(-1.0, 1.0);
          samples[i] = lastValue * 0.8;
          break;
        case NoiseType.pink:
          lastValue = lastValue * 0.96 + white * 0.04;
          samples[i] = lastValue * 3.0;
          break;
      }
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

enum NoiseType { white, brown, pink }

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
