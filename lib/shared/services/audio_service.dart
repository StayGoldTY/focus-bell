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

  Future<void> playBuiltInSound(
    BuiltInSound sound, {
    double volume = 0.7,
  }) async {
    try {
      if (kIsWeb) {
        playToneOnWeb(
          sound.frequency.toDouble(),
          sound.durationSeconds,
          volume,
        );
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

  Future<void> playNoise({required NoiseType type, double volume = 0.5}) async {
    try {
      await stopAmbient();
      _ambientPlayer = AudioPlayer();
      await _ambientPlayer!.setVolume(volume);
      final audioData = _generateNoiseWav(
        type: type,
        durationSeconds: 10,
        sampleRate: 44100,
      );
      final source = _WavAudioSource(audioData);
      await _ambientPlayer!.setAudioSource(source);
      await _ambientPlayer!.setLoopMode(LoopMode.one);
      await _ambientPlayer!.play();
    } catch (e) {
      debugPrint('AudioService.playNoise error: $e');
    }
  }

  Future<void> playFocusSoundscape(
    FocusSoundscape soundscape, {
    double volume = 0.35,
  }) async {
    try {
      await stopAmbient();
      _ambientPlayer = AudioPlayer();
      await _ambientPlayer!.setVolume(volume);
      final audioData = _generateFocusSoundscapeWav(
        kind: soundscape.kind,
        durationSeconds: 12,
        sampleRate: 44100,
      );
      final source = _WavAudioSource(audioData);
      await _ambientPlayer!.setAudioSource(source);
      await _ambientPlayer!.setLoopMode(LoopMode.one);
      await _ambientPlayer!.play();
    } catch (e) {
      debugPrint('AudioService.playFocusSoundscape error: $e');
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
    double gain = 1.0,
  }) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final samples = Float64List(numSamples);

    double lastValue = 0;
    for (var i = 0; i < numSamples; i++) {
      final white = _random.nextDouble() * 2 - 1;
      switch (type) {
        case NoiseType.white:
          samples[i] = white * 0.3 * gain;
          break;
        case NoiseType.brown:
          lastValue = (lastValue + white * 0.02).clamp(-1.0, 1.0);
          samples[i] = lastValue * 0.8 * gain;
          break;
        case NoiseType.pink:
          lastValue = lastValue * 0.96 + white * 0.04;
          samples[i] = lastValue * 3.0 * gain;
          break;
      }
    }

    return _encodeWav(samples, sampleRate);
  }

  Uint8List _generateFocusSoundscapeWav({
    required FocusSoundKind kind,
    required double durationSeconds,
    required int sampleRate,
  }) {
    switch (kind) {
      case FocusSoundKind.brownNoise:
        return _generateNoiseWav(
          type: NoiseType.brown,
          durationSeconds: durationSeconds,
          sampleRate: sampleRate,
          gain: 0.4,
        );
      case FocusSoundKind.pinkNoise:
        return _generateNoiseWav(
          type: NoiseType.pink,
          durationSeconds: durationSeconds,
          sampleRate: sampleRate,
          gain: 0.18,
        );
      case FocusSoundKind.rainDrift:
        return _encodeWav(
          _buildRainDriftSamples(durationSeconds, sampleRate),
          sampleRate,
        );
      case FocusSoundKind.forestCanopy:
        return _encodeWav(
          _buildForestCanopySamples(durationSeconds, sampleRate),
          sampleRate,
        );
      case FocusSoundKind.streamFlow:
        return _encodeWav(
          _buildStreamFlowSamples(durationSeconds, sampleRate),
          sampleRate,
        );
      case FocusSoundKind.oceanWave:
        return _encodeWav(
          _buildOceanWaveSamples(durationSeconds, sampleRate),
          sampleRate,
        );
      case FocusSoundKind.fireplaceGlow:
        return _encodeWav(
          _buildFireplaceGlowSamples(durationSeconds, sampleRate),
          sampleRate,
        );
      case FocusSoundKind.nightCrickets:
        return _encodeWav(
          _buildNightCricketsSamples(durationSeconds, sampleRate),
          sampleRate,
        );
      case FocusSoundKind.meditationDrone:
        return _encodeWav(
          _buildMeditationDroneSamples(durationSeconds, sampleRate),
          sampleRate,
        );
      case FocusSoundKind.cafeHum:
        return _encodeWav(
          _buildCafeHumSamples(durationSeconds, sampleRate),
          sampleRate,
        );
      case FocusSoundKind.studyLofi:
        return _encodeWav(
          _buildStudyLofiSamples(durationSeconds, sampleRate),
          sampleRate,
        );
    }
  }

  Float64List _buildRainDriftSamples(double durationSeconds, int sampleRate) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final samples = Float64List(numSamples);
    final random = Random(13);
    var rainBed = 0.0;
    var droplet = 0.0;

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final white = random.nextDouble() * 2 - 1;
      rainBed = rainBed * 0.86 + white.abs() * 0.14;

      if (random.nextDouble() > 0.9992) {
        droplet = 1.0;
      }
      droplet *= 0.992;

      final hiss = (rainBed - 0.5) * 0.22;
      final sparkle =
          sin(2 * pi * (1800 + 600 * sin(2 * pi * 0.17 * t)) * t) *
          droplet *
          0.08;
      final air = white * 0.015;

      samples[i] = (hiss + sparkle + air).clamp(-1.0, 1.0);
    }

    return samples;
  }

  Float64List _buildForestCanopySamples(double durationSeconds, int sampleRate) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final samples = Float64List(numSamples);
    final random = Random(61);
    var breeze = 0.0;
    var birdEnvelope = 0.0;
    var birdFrequency = 1700.0;

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final white = random.nextDouble() * 2 - 1;
      breeze = breeze * 0.985 + white * 0.015;

      if (random.nextDouble() > 0.99972) {
        birdEnvelope = 1.0;
        birdFrequency = 1500 + random.nextDouble() * 900;
      }
      birdEnvelope *= 0.993;

      final canopy =
          breeze * 0.12 * (0.65 + 0.35 * sin(2 * pi * 0.05 * t));
      final rustle =
          white * 0.012 * (0.55 + 0.45 * sin(2 * pi * 0.19 * t + 0.4));
      final chirp =
          (sin(2 * pi * birdFrequency * t) +
                  0.4 * sin(2 * pi * birdFrequency * 1.6 * t)) *
              birdEnvelope *
              0.045;
      final distant = sin(2 * pi * 260 * t + sin(2 * pi * 0.08 * t)) * 0.004;

      samples[i] = (canopy + rustle + chirp + distant).clamp(-1.0, 1.0);
    }

    return samples;
  }

  Float64List _buildStreamFlowSamples(double durationSeconds, int sampleRate) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final samples = Float64List(numSamples);
    final random = Random(73);
    var current = 0.0;
    var ripple = 0.0;

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final white = random.nextDouble() * 2 - 1;
      current = current * 0.92 + white.abs() * 0.08;
      ripple = ripple * 0.96 + white * 0.04;

      final bed = (current - 0.48) * 0.22;
      final shimmer =
          ripple * 0.08 * (0.7 + 0.3 * sin(2 * pi * 0.33 * t + 0.5));
      final eddy =
          sin(2 * pi * (420 + 60 * sin(2 * pi * 0.09 * t)) * t) *
          max(0.0, sin(2 * pi * 0.7 * t)).toDouble() *
          0.018;
      final air = white * 0.01;

      samples[i] = (bed + shimmer + eddy + air).clamp(-1.0, 1.0);
    }

    return samples;
  }

  Float64List _buildOceanWaveSamples(double durationSeconds, int sampleRate) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final samples = Float64List(numSamples);
    final random = Random(29);
    var surf = 0.0;

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final white = random.nextDouble() * 2 - 1;
      surf = surf * 0.995 + white * 0.005;

      final swell = 0.55 + 0.45 * sin(2 * pi * 0.075 * t - pi / 2);
      final foam = surf * 0.24 * swell;
      final lowRumble =
          (sin(2 * pi * 52 * t) + 0.5 * sin(2 * pi * 104 * t)) * 0.02;
      final air = white * 0.008;

      samples[i] = (foam + lowRumble + air).clamp(-1.0, 1.0);
    }

    return samples;
  }

  Float64List _buildFireplaceGlowSamples(
    double durationSeconds,
    int sampleRate,
  ) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final samples = Float64List(numSamples);
    final random = Random(83);
    var warmth = 0.0;
    var ember = 0.0;

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final white = random.nextDouble() * 2 - 1;
      warmth = warmth * 0.99 + white * 0.01;

      if (random.nextDouble() > 0.99945) {
        ember = 1.0;
      }
      ember *= 0.965;

      final fireBed = warmth.abs() * 0.12 * (0.65 + 0.35 * sin(2 * pi * 0.07 * t));
      final rumble =
          sin(2 * pi * 58 * t) * 0.025 + sin(2 * pi * 116 * t) * 0.01;
      final crackle =
          (white >= 0 ? 1.0 : -1.0) *
          pow(white.abs(), 3).toDouble() *
          ember *
          0.18;
      final hiss = white * 0.004;

      samples[i] = (fireBed + rumble + crackle + hiss).clamp(-1.0, 1.0);
    }

    return samples;
  }

  Float64List _buildNightCricketsSamples(
    double durationSeconds,
    int sampleRate,
  ) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final samples = Float64List(numSamples);
    final random = Random(97);
    var air = 0.0;

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final white = random.nextDouble() * 2 - 1;
      air = air * 0.99 + white * 0.01;

      final gateA = max(0.0, sin(2 * pi * 1.05 * t)).toDouble();
      final gateB = max(0.0, sin(2 * pi * 0.92 * t + 0.8)).toDouble();
      final chirpA =
          sin(2 * pi * 3900 * t) *
          pow(max(0.0, sin(2 * pi * 17 * t)).toDouble(), 12).toDouble() *
          pow(gateA, 2).toDouble() *
          0.028;
      final chirpB =
          sin(2 * pi * 4700 * t) *
          pow(max(0.0, sin(2 * pi * 13.5 * t + 1.7)).toDouble(), 10)
              .toDouble() *
          (0.55 + 0.45 * gateB) *
          0.02;
      final nightAir = air * 0.018 + sin(2 * pi * 180 * t) * 0.003;

      samples[i] = (chirpA + chirpB + nightAir).clamp(-1.0, 1.0);
    }

    return samples;
  }

  Float64List _buildMeditationDroneSamples(
    double durationSeconds,
    int sampleRate,
  ) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final samples = Float64List(numSamples);
    final random = Random(109);
    var air = 0.0;

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final white = random.nextDouble() * 2 - 1;
      air = air * 0.996 + white * 0.004;

      final breath = 0.7 + 0.3 * sin(2 * pi * 0.045 * t - pi / 2);
      final drone =
          (sin(2 * pi * 110 * t) +
                  0.6 * sin(2 * pi * 165 * t + 0.3) +
                  0.35 * sin(2 * pi * 220 * t + 1.2)) *
              0.035 *
              breath;
      final shimmer =
          sin(2 * pi * 528 * t + 0.25 * sin(2 * pi * 0.12 * t)) *
          0.01 *
          (0.4 + 0.6 * breath);
      final bellPhase = t % 6.0;
      final bellEnv = exp(-2.8 * bellPhase);
      final bowl =
          (sin(2 * pi * 432 * t) + 0.5 * sin(2 * pi * 864 * t)) *
          bellEnv *
          0.015;
      final haze = air * 0.012;

      samples[i] = (drone + shimmer + bowl + haze).clamp(-1.0, 1.0);
    }

    return samples;
  }

  Float64List _buildCafeHumSamples(double durationSeconds, int sampleRate) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final samples = Float64List(numSamples);
    final random = Random(47);
    var murmur = 0.0;
    var clink = 0.0;

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final white = random.nextDouble() * 2 - 1;
      murmur = murmur * 0.985 + white * 0.015;

      if (random.nextDouble() > 0.99965) {
        clink = 1.0;
      }
      clink *= 0.985;

      final hum = sin(2 * pi * 110 * t) * 0.015 + sin(2 * pi * 220 * t) * 0.008;
      final room = murmur * 0.18;
      final chatter =
          sin(2 * pi * (240 + 20 * sin(2 * pi * 0.11 * t)) * t) *
          murmur.abs() *
          0.02;
      final cup = sin(2 * pi * 1450 * t) * clink * 0.05;

      samples[i] = (hum + room + chatter + cup).clamp(-1.0, 1.0);
    }

    return samples;
  }

  Float64List _buildStudyLofiSamples(double durationSeconds, int sampleRate) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final samples = Float64List(numSamples);
    const melody = <double>[
      261.63,
      329.63,
      392.0,
      329.63,
      440.0,
      392.0,
      329.63,
      293.66,
      261.63,
      329.63,
      392.0,
      523.25,
      493.88,
      392.0,
      329.63,
      293.66,
    ];
    const bassline = <double>[130.81, 146.83, 174.61, 146.83, 130.81, 146.83, 196.0, 174.61];
    final random = Random(131);
    var dust = 0.0;
    const melodyStep = 0.75;
    const bassStep = 1.5;

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final white = random.nextDouble() * 2 - 1;
      dust = dust * 0.98 + white * 0.02;

      final melodyIndex = ((t / melodyStep).floor()) % melody.length;
      final melodyPhase = t - (t / melodyStep).floor() * melodyStep;
      final melodyEnv = exp(-4.8 * melodyPhase);
      final note = melody[melodyIndex];
      final lead =
          (sin(2 * pi * note * t) * 0.02 +
                  sin(2 * pi * note * 2 * t) * 0.008 +
                  sin(2 * pi * note * 3 * t) * 0.003) *
              melodyEnv;

      final bassIndex = ((t / bassStep).floor()) % bassline.length;
      final bassPhase = t - (t / bassStep).floor() * bassStep;
      final bassEnv = exp(-2.8 * bassPhase);
      final bass =
          (sin(2 * pi * bassline[bassIndex] * t) +
                  0.4 * sin(2 * pi * bassline[bassIndex] * 2 * t)) *
              0.018 *
              bassEnv;

      final pad =
          (sin(2 * pi * 196 * t + 0.2 * sin(2 * pi * 0.08 * t)) +
                  0.6 * sin(2 * pi * 246.94 * t + 1.0)) *
              0.01;
      final vinyl = dust * 0.01;

      samples[i] = (lead + bass + pad + vinyl).clamp(-1.0, 1.0);
    }

    return samples;
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
