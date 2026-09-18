import 'dart:math';
import 'dart:typed_data';

import 'ambient_recipe.dart';

/// Offline renderer that turns an [AmbientRecipe] into a seamless stereo loop.
///
/// Used on native platforms (where the loop is handed to `just_audio` as a
/// WAV) and by tests. The web build renders the same recipes in real time with
/// Web Audio (`web/focus_audio.js`); the two implementations mirror each other
/// layer by layer so a recipe sounds the same everywhere.
class AmbientRenderer {
  /// All noise sources are normalised to this RMS before shaping so that layer
  /// gains in a recipe mean the same thing on every platform.
  static const noiseRms = 0.2;

  /// Coefficients of swept filters are refreshed every this many frames.
  static const _controlBlock = 32;

  final int sampleRate;

  const AmbientRenderer({this.sampleRate = 32000});

  /// Renders [loopSeconds] of audio. The tail is cross-faded into the head so
  /// the result can be looped without clicks.
  RenderedAmbient render(
    AmbientRecipe recipe, {
    required double loopSeconds,
    int seed = 1,
  }) {
    final crossfadeSeconds = min(2.0, loopSeconds / 4);
    final loopFrames = (loopSeconds * sampleRate).round();
    final crossfadeFrames = (crossfadeSeconds * sampleRate).round();
    final totalFrames = loopFrames + crossfadeFrames;
    final random = Random(seed);
    final left = Float32List(totalFrames);
    final right = Float32List(totalFrames);
    final scales = _NoiseScales.measure(random);

    for (final layer in recipe.noise) {
      _renderNoiseLayer(layer, left, right, random, scales);
    }
    for (final layer in recipe.tones) {
      _renderToneLayer(layer, left, right, random, loopFrames / sampleRate);
    }
    for (final layer in recipe.events) {
      _renderEventLayer(layer, left, right, random, scales);
    }

    final outLeft = Float32List(loopFrames);
    final outRight = Float32List(loopFrames);
    for (var i = 0; i < loopFrames; i++) {
      var l = left[i];
      var r = right[i];
      if (i < crossfadeFrames) {
        final phase = i / crossfadeFrames * pi / 2;
        final headWeight = sin(phase);
        final tailWeight = cos(phase);
        l = l * headWeight + left[loopFrames + i] * tailWeight;
        r = r * headWeight + right[loopFrames + i] * tailWeight;
      }
      outLeft[i] = _softLimit(l * recipe.masterGain);
      outRight[i] = _softLimit(r * recipe.masterGain);
    }

    return RenderedAmbient(
      left: outLeft,
      right: outRight,
      sampleRate: sampleRate,
    );
  }

  void _renderNoiseLayer(
    NoiseLayer layer,
    Float32List left,
    Float32List right,
    Random random,
    _NoiseScales scales,
  ) {
    final frames = left.length;
    final primary = _NoiseSource(layer.color, random, scales.of(layer.color));
    final secondary = _NoiseSource(layer.color, random, scales.of(layer.color));
    final width = layer.width.clamp(0.0, 1.0);
    final widthNorm = 1 / sqrt((1 - width) * (1 - width) + width * width);

    final leftChain = _FilterChain(layer.filters, sampleRate);
    final rightChain = _FilterChain(layer.filters, sampleRate);
    final lfo = layer.lfo == null
        ? null
        : _Lfo(layer.lfo!.rateHz, random, sampleRate);
    final depth = layer.lfo?.depth ?? 0.0;
    final sweep = layer.lfo?.filterSweepHz ?? 0.0;
    final balance = _StereoBalance(layer.pan);

    var gainMod = 1.0;
    for (var i = 0; i < frames; i++) {
      if (lfo != null && i % _controlBlock == 0) {
        final s = lfo.valueAt(i);
        gainMod = (1 - depth / 2) + (depth / 2) * s;
        if (sweep != 0) {
          leftChain.sweepLast(sweep * s);
          rightChain.sweepLast(sweep * s);
        }
      }
      final a = primary.next();
      final b = secondary.next();
      final g = layer.gain * gainMod;
      final l = leftChain.process(a) * g;
      final r =
          rightChain.process((a * (1 - width) + b * width) * widthNorm) * g;
      left[i] += l * balance.leftToLeft + r * balance.rightToLeft;
      right[i] += l * balance.leftToRight + r * balance.rightToRight;
    }
  }

  /// Sustained tones are the one layer type where a cross-faded seam would be
  /// audible (two copies with different phases beat against each other), so
  /// every frequency is snapped to a whole number of cycles per loop. The
  /// snap is at most 1 / loopSeconds Hz, far below what the ear can notice.
  void _renderToneLayer(
    ToneLayer layer,
    Float32List left,
    Float32List right,
    Random random,
    double loopSeconds,
  ) {
    double loopCoherent(double frequency) {
      return max(1, (frequency * loopSeconds).round()) / loopSeconds;
    }

    final frames = left.length;
    // Binaural carriers are hard-panned: each ear gets its own full-level tone.
    final pan = layer.binauralBeatHz > 0
        ? const _Pan.hardSides()
        : _Pan(layer.pan);
    final voices = <_ToneVoice>[];
    final detune = pow(2, layer.detuneCents / 1200).toDouble();
    for (final partial in layer.partials) {
      final baseLeft = layer.frequency * partial.ratio;
      final baseRight =
          (layer.frequency + layer.binauralBeatHz) * partial.ratio;
      if (layer.detuneCents > 0) {
        voices.add(
          _ToneVoice(
            loopCoherent(baseLeft * detune),
            loopCoherent(baseRight * detune),
            partial.gain / 2,
          ),
        );
        voices.add(
          _ToneVoice(
            loopCoherent(baseLeft / detune),
            loopCoherent(baseRight / detune),
            partial.gain / 2,
          ),
        );
      } else {
        voices.add(
          _ToneVoice(
            loopCoherent(baseLeft),
            loopCoherent(baseRight),
            partial.gain,
          ),
        );
      }
    }
    final tremoloStep = layer.tremoloRateHz > 0
        ? 2 * pi * loopCoherent(layer.tremoloRateHz) / sampleRate
        : 0.0;
    final tremoloPhase = random.nextDouble() * 2 * pi;
    final depth = layer.tremoloDepth;

    for (var i = 0; i < frames; i++) {
      var l = 0.0;
      var r = 0.0;
      for (final voice in voices) {
        l += sin(voice.leftPhase) * voice.gain;
        r += sin(voice.rightPhase) * voice.gain;
        voice.leftPhase += 2 * pi * voice.leftFrequency / sampleRate;
        voice.rightPhase += 2 * pi * voice.rightFrequency / sampleRate;
      }
      var g = layer.gain;
      if (layer.tremoloRateHz > 0) {
        g *=
            (1 - depth / 2) + (depth / 2) * sin(tremoloPhase + tremoloStep * i);
      }
      left[i] += l * g * pan.left;
      right[i] += r * g * pan.right;
    }
  }

  void _renderEventLayer(
    EventLayer layer,
    Float32List left,
    Float32List right,
    Random random,
    _NoiseScales scales,
  ) {
    if (layer.ratePerSecond <= 0) {
      return;
    }
    final totalSeconds = left.length / sampleRate;
    var at = _exponential(random, layer.ratePerSecond) * 0.5;
    while (at < totalSeconds) {
      _renderEvent(layer, at, left, right, random, scales);
      at += max(layer.minGapSeconds, _exponential(random, layer.ratePerSecond));
    }
  }

  void _renderEvent(
    EventLayer layer,
    double startSeconds,
    Float32List left,
    Float32List right,
    Random random,
    _NoiseScales scales,
  ) {
    final duration = _uniform(
      random,
      layer.minDurationSeconds,
      layer.maxDurationSeconds,
    );
    final frames = max(2, (duration * sampleRate).round());
    final start = (startSeconds * sampleRate).round();
    final end = min(left.length, start + frames);
    if (start >= end) {
      return;
    }
    final startFrequency = _logUniform(
      random,
      layer.minFrequency,
      layer.maxFrequency,
    );
    final gain = layer.gain * (1 - layer.gainJitter * random.nextDouble());
    final pan = _Pan(_uniform(random, -layer.panSpread, layer.panSpread));
    final attackFrames = max(
      (0.002 * sampleRate).round(),
      (frames * layer.attackRatio).round(),
    );
    final decayFrames = max(1, frames - attackFrames);

    switch (layer.sound) {
      case EventSound.burst:
        final source = _NoiseSource(
          layer.color,
          random,
          scales.of(layer.color),
        );
        final filter = _Biquad(sampleRate);
        for (var i = 0; i < end - start; i++) {
          if (i % _controlBlock == 0) {
            final progress = i / frames;
            final frequency =
                startFrequency * pow(layer.sweepRatio, progress).toDouble();
            filter.configure(layer.filterType, frequency, layer.q);
          }
          final env = _envelope(i, attackFrames, decayFrames);
          final sample = filter.process(source.next()) * env * gain;
          left[start + i] += sample * pan.left;
          right[start + i] += sample * pan.right;
        }
        break;
      case EventSound.tone:
        final phases = Float64List(layer.partials.length);
        final trillStep = 2 * pi * layer.trillHz / sampleRate;
        for (var i = 0; i < end - start; i++) {
          final progress = i / frames;
          final frequency =
              startFrequency * pow(layer.sweepRatio, progress).toDouble();
          var sample = 0.0;
          for (var p = 0; p < layer.partials.length; p++) {
            final partial = layer.partials[p];
            sample += sin(phases[p]) * partial.gain;
            phases[p] += 2 * pi * frequency * partial.ratio / sampleRate;
          }
          var env = _envelope(i, attackFrames, decayFrames);
          if (layer.trillHz > 0) {
            env *= 0.5 + 0.5 * sin(trillStep * i);
          }
          sample *= env * gain;
          left[start + i] += sample * pan.left;
          right[start + i] += sample * pan.right;
        }
        break;
    }
  }

  static double _envelope(int frame, int attackFrames, int decayFrames) {
    if (frame < attackFrames) {
      return frame / attackFrames;
    }
    return exp(-6.9 * (frame - attackFrames) / decayFrames);
  }

  static double _softLimit(double x) {
    const knee = 0.6;
    final magnitude = x.abs();
    if (magnitude <= knee) {
      return x;
    }
    final excess = (magnitude - knee) / (1 - knee);
    final limited = knee + (1 - knee) * _tanh(excess);
    return x.isNegative ? -limited : limited;
  }

  static double _tanh(double x) {
    final e = exp(2 * x);
    return (e - 1) / (e + 1);
  }

  static double _exponential(Random random, double rate) {
    return -log(1 - random.nextDouble()) / rate;
  }

  static double _uniform(Random random, double min, double max) {
    return min + (max - min) * random.nextDouble();
  }

  static double _logUniform(Random random, double min, double max) {
    if (min <= 0 || max <= min) {
      return min;
    }
    return exp(_uniform(random, log(min), log(max)));
  }
}

class RenderedAmbient {
  final Float32List left;
  final Float32List right;
  final int sampleRate;

  const RenderedAmbient({
    required this.left,
    required this.right,
    required this.sampleRate,
  });

  int get frames => left.length;

  /// Encodes the loop as 16-bit stereo PCM WAV.
  Uint8List toWav() {
    const channels = 2;
    const bytesPerSample = 2;
    final dataSize = frames * channels * bytesPerSample;
    final buffer = ByteData(44 + dataSize);

    void writeAscii(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        buffer.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, channels, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * channels * bytesPerSample, Endian.little);
    buffer.setUint16(32, channels * bytesPerSample, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    var offset = 44;
    for (var i = 0; i < frames; i++) {
      buffer.setInt16(offset, _toPcm(left[i]), Endian.little);
      buffer.setInt16(offset + 2, _toPcm(right[i]), Endian.little);
      offset += 4;
    }
    return buffer.buffer.asUint8List();
  }

  static int _toPcm(double sample) {
    return (sample.clamp(-1.0, 1.0) * 32767).round();
  }
}

class _ToneVoice {
  final double leftFrequency;
  final double rightFrequency;
  final double gain;
  double leftPhase = 0;
  double rightPhase = 0;

  _ToneVoice(this.leftFrequency, this.rightFrequency, this.gain);
}

/// Equal-power pan for mono sources (tones, one-shot events); matches the
/// Web Audio `StereoPannerNode` law for mono input, i.e. -3 dB per side at
/// centre.
class _Pan {
  final double left;
  final double right;

  _Pan(double pan)
    : left = cos((pan.clamp(-1.0, 1.0) + 1) * pi / 4),
      right = sin((pan.clamp(-1.0, 1.0) + 1) * pi / 4);

  const _Pan.hardSides() : left = 1, right = 1;
}

/// Balance law for stereo sources; identity at centre, matching the Web Audio
/// `StereoPannerNode` law for stereo input.
class _StereoBalance {
  final double leftToLeft;
  final double rightToLeft;
  final double leftToRight;
  final double rightToRight;

  factory _StereoBalance(double pan) {
    final p = pan.clamp(-1.0, 1.0);
    if (p <= 0) {
      final x = (p + 1) * pi / 2;
      return _StereoBalance._(1, cos(x), 0, sin(x));
    }
    final x = p * pi / 2;
    return _StereoBalance._(cos(x), 0, sin(x), 1);
  }

  const _StereoBalance._(
    this.leftToLeft,
    this.rightToLeft,
    this.leftToRight,
    this.rightToRight,
  );
}

/// Two summed sines at incommensurate rates; output stays within [-1, 1].
class _Lfo {
  final double stepA;
  final double stepB;
  final double phaseA;
  final double phaseB;

  _Lfo(double rateHz, Random random, int sampleRate)
    : stepA = 2 * pi * rateHz / sampleRate,
      stepB = 2 * pi * rateHz * 0.7317 / sampleRate,
      phaseA = random.nextDouble() * 2 * pi,
      phaseB = random.nextDouble() * 2 * pi;

  double valueAt(int frame) {
    return 0.6 * sin(phaseA + stepA * frame) +
        0.4 * sin(phaseB + stepB * frame);
  }
}

/// White, pink (Kellet filter) and brown (leaky integrator) noise, scaled so
/// each colour has the same RMS.
class _NoiseSource {
  final NoiseColor color;
  final Random random;
  final double scale;
  double _b0 = 0, _b1 = 0, _b2 = 0, _b3 = 0, _b4 = 0, _b5 = 0, _b6 = 0;
  double _brown = 0;

  _NoiseSource(this.color, this.random, this.scale);

  double next() {
    final white = random.nextDouble() * 2 - 1;
    switch (color) {
      case NoiseColor.white:
        return white * scale;
      case NoiseColor.pink:
        _b0 = 0.99886 * _b0 + white * 0.0555179;
        _b1 = 0.99332 * _b1 + white * 0.0750759;
        _b2 = 0.96900 * _b2 + white * 0.1538520;
        _b3 = 0.86650 * _b3 + white * 0.3104856;
        _b4 = 0.55000 * _b4 + white * 0.5329522;
        _b5 = -0.7616 * _b5 - white * 0.0168980;
        final pink = _b0 + _b1 + _b2 + _b3 + _b4 + _b5 + _b6 + white * 0.5362;
        _b6 = white * 0.115926;
        return pink * scale;
      case NoiseColor.brown:
        _brown = (_brown + 0.02 * white) / 1.02;
        return _brown * scale;
    }
  }
}

/// Per-colour scale factors that bring raw generator output to [noiseRms].
class _NoiseScales {
  final Map<NoiseColor, double> _scales;

  _NoiseScales._(this._scales);

  factory _NoiseScales.measure(Random random) {
    const probeFrames = 32768;
    final scales = <NoiseColor, double>{};
    for (final color in NoiseColor.values) {
      final source = _NoiseSource(color, random, 1.0);
      // Let the recursive filters settle before measuring.
      for (var i = 0; i < 4096; i++) {
        source.next();
      }
      var sum = 0.0;
      for (var i = 0; i < probeFrames; i++) {
        final v = source.next();
        sum += v * v;
      }
      scales[color] = AmbientRenderer.noiseRms / sqrt(sum / probeFrames);
    }
    return _NoiseScales._(scales);
  }

  double of(NoiseColor color) => _scales[color]!;
}

class _FilterChain {
  final List<_Biquad> _filters;
  final AmbientFilter? _last;

  _FilterChain(List<AmbientFilter> specs, int sampleRate)
    : _filters = [
        for (final spec in specs)
          _Biquad(sampleRate)..configure(spec.type, spec.frequency, spec.q),
      ],
      _last = specs.isEmpty ? null : specs.last;

  void sweepLast(double offsetHz) {
    final last = _last;
    if (last == null) {
      return;
    }
    _filters.last.configure(last.type, last.frequency + offsetHz, last.q);
  }

  double process(double x) {
    var y = x;
    for (final filter in _filters) {
      y = filter.process(y);
    }
    return y;
  }
}

/// RBJ cookbook biquad; the bandpass variant has 0 dB peak gain, matching the
/// Web Audio `BiquadFilterNode`.
class _Biquad {
  final int sampleRate;
  double _b0 = 1, _b1 = 0, _b2 = 0, _a1 = 0, _a2 = 0;
  double _x1 = 0, _x2 = 0, _y1 = 0, _y2 = 0;

  _Biquad(this.sampleRate);

  void configure(AmbientFilterType type, double frequency, double q) {
    final f = frequency.clamp(20.0, sampleRate / 2 - 100.0);
    final safeQ = max(0.1, q);
    final w0 = 2 * pi * f / sampleRate;
    final cosW0 = cos(w0);
    final sinW0 = sin(w0);
    final alpha = sinW0 / (2 * safeQ);
    final a0 = 1 + alpha;
    double b0, b1, b2;
    switch (type) {
      case AmbientFilterType.lowpass:
        b0 = (1 - cosW0) / 2;
        b1 = 1 - cosW0;
        b2 = (1 - cosW0) / 2;
        break;
      case AmbientFilterType.highpass:
        b0 = (1 + cosW0) / 2;
        b1 = -(1 + cosW0);
        b2 = (1 + cosW0) / 2;
        break;
      case AmbientFilterType.bandpass:
        b0 = alpha;
        b1 = 0;
        b2 = -alpha;
        break;
    }
    _b0 = b0 / a0;
    _b1 = b1 / a0;
    _b2 = b2 / a0;
    _a1 = -2 * cosW0 / a0;
    _a2 = (1 - alpha) / a0;
  }

  double process(double x) {
    final y = _b0 * x + _b1 * _x1 + _b2 * _x2 - _a1 * _y1 - _a2 * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }
}
