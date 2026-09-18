import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:focus_bell/core/audio/ambient_recipe.dart';
import 'package:focus_bell/core/audio/ambient_renderer.dart';
import 'package:focus_bell/core/constants/sound_data.dart';

void main() {
  const renderer = AmbientRenderer(sampleRate: 22050);
  const loopSeconds = 8.0;

  group('focus soundscape library', () {
    test('ids are unique and every category has sounds', () {
      final ids = focusSoundscapes.map((sound) => sound.id).toSet();
      expect(ids.length, focusSoundscapes.length);
      for (final category in FocusSoundCategory.values) {
        expect(
          focusSoundscapes.where((sound) => sound.category == category),
          isNotEmpty,
          reason: '${category.label} should not be empty',
        );
      }
    });

    test('presets and defaults point at existing sounds', () {
      for (final preset in focusPresets) {
        expect(findFocusSoundscapeById(preset.selectedFocusSoundId), isNotNull);
      }
      expect(findFocusSoundscapeById('brown_noise'), isNotNull);
    });

    test('retired ids keep resolving for old preferences and history', () {
      expect(findFocusSoundscapeById('meditation_drone')?.id, 'deep_space');
      expect(findFocusSoundscapeById('study_lofi')?.id, 'cafe_hum');
      expect(findFocusSoundscapeById('does_not_exist'), isNull);
    });

    test('recipes serialise to the layer list the web engine expects', () {
      for (final sound in focusSoundscapes) {
        final json = jsonDecode(jsonEncode(sound.recipe.toJson())) as Map;
        final layers = json['layers'] as List;
        expect(layers, isNotEmpty, reason: sound.id);
        for (final layer in layers) {
          expect(
            (layer as Map)['kind'],
            anyOf('noise', 'tone', 'event'),
            reason: sound.id,
          );
        }
        expect(json['masterGain'], greaterThan(0));
      }
    });

    test('LFO filter sweeps never push a cutoff below the audible floor', () {
      for (final sound in focusSoundscapes) {
        for (final layer in sound.recipe.noise) {
          final lfo = layer.lfo;
          if (lfo == null || lfo.filterSweepHz == 0 || layer.filters.isEmpty) {
            continue;
          }
          expect(
            layer.filters.last.frequency - lfo.filterSweepHz,
            greaterThan(30),
            reason: '${sound.id} sweep dips too low',
          );
        }
      }
    });
  });

  group('AmbientRenderer', () {
    late final Map<String, _LoopStats> stats;

    setUpAll(() {
      stats = {
        for (final sound in focusSoundscapes)
          sound.id: _LoopStats.of(
            renderer.render(sound.recipe, loopSeconds: loopSeconds, seed: 7),
          ),
      };
    });

    test('every soundscape renders without clipping and is not silent', () {
      for (final entry in stats.entries) {
        expect(entry.value.peak, lessThan(0.95), reason: entry.key);
        expect(entry.value.rms, greaterThan(0.02), reason: entry.key);
      }
    });

    test('soundscapes sit within a ±6 dB perceived-loudness window', () {
      final levels = stats.map(
        (id, s) => MapEntry(id, 20 * _log10(s.weightedRms)),
      );
      final sorted = levels.values.toList()..sort();
      final median = sorted[sorted.length ~/ 2];
      for (final entry in levels.entries) {
        expect(
          (entry.value - median).abs(),
          lessThanOrEqualTo(6.0),
          reason:
              '${entry.key} is ${entry.value.toStringAsFixed(1)} dBFS, '
              'median ${median.toStringAsFixed(1)} dBFS',
        );
      }
    });

    test('loop boundary is as smooth as the rest of the loop', () {
      for (final entry in stats.entries) {
        expect(
          entry.value.seamJump,
          lessThanOrEqualTo(entry.value.maxInnerJump * 1.05),
          reason: '${entry.key} clicks at the loop seam',
        );
      }
    });

    test('stereo layers are decorrelated but not out of phase', () {
      for (final entry in stats.entries) {
        expect(entry.value.correlation, greaterThan(-0.2), reason: entry.key);
        expect(entry.value.correlation, lessThan(1.0), reason: entry.key);
      }
    });

    test('encodes a valid 16-bit stereo WAV', () {
      final rendered = renderer.render(
        const AmbientRecipe(
          noise: [NoiseLayer(color: NoiseColor.pink, gain: 0.5)],
        ),
        loopSeconds: 0.5,
      );
      final wav = rendered.toWav();
      final data = ByteData.sublistView(wav);
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(data.getUint16(22, Endian.little), 2);
      expect(data.getUint32(24, Endian.little), 22050);
      expect(data.getUint16(34, Endian.little), 16);
      expect(data.getUint32(40, Endian.little), rendered.frames * 4);
      expect(wav.length, 44 + rendered.frames * 4);
    });

    test('rendering is deterministic for a given seed', () {
      final recipe = findFocusSoundscapeById('fireplace_glow')!.recipe;
      final a = renderer.render(recipe, loopSeconds: 1, seed: 3);
      final b = renderer.render(recipe, loopSeconds: 1, seed: 3);
      expect(a.left, b.left);
      expect(a.right, b.right);
    });
  });
}

double _log10(double x) => log(x) / ln10;

class _LoopStats {
  final double peak;
  final double rms;

  /// RMS after a 200 Hz high-pass: a crude stand-in for A-weighting so that a
  /// bass-heavy brown noise and a bright rain bed compare by loudness rather
  /// than by raw energy.
  final double weightedRms;
  final double seamJump;
  final double maxInnerJump;
  final double correlation;

  const _LoopStats({
    required this.peak,
    required this.rms,
    required this.weightedRms,
    required this.seamJump,
    required this.maxInnerJump,
    required this.correlation,
  });

  factory _LoopStats.of(RenderedAmbient rendered) {
    var peak = 0.0;
    var sumSquares = 0.0;
    var maxInnerJump = 0.0;
    var dot = 0.0;
    var leftEnergy = 0.0;
    var rightEnergy = 0.0;
    var weightedSquares = 0.0;
    final left = rendered.left;
    final right = rendered.right;
    final weighting = _HighPass(200, rendered.sampleRate);
    for (var i = 0; i < rendered.frames; i++) {
      peak = max(peak, max(left[i].abs(), right[i].abs()));
      sumSquares += left[i] * left[i] + right[i] * right[i];
      final weighted = weighting.process(left[i]);
      weightedSquares += weighted * weighted;
      dot += left[i] * right[i];
      leftEnergy += left[i] * left[i];
      rightEnergy += right[i] * right[i];
      if (i > 0) {
        maxInnerJump = max(maxInnerJump, (left[i] - left[i - 1]).abs());
      }
    }
    final seamJump = (left[0] - left[rendered.frames - 1]).abs();
    return _LoopStats(
      peak: peak,
      rms: sqrt(sumSquares / (rendered.frames * 2)),
      weightedRms: sqrt(weightedSquares / rendered.frames),
      seamJump: seamJump,
      maxInnerJump: maxInnerJump,
      correlation: dot / sqrt(leftEnergy * rightEnergy),
    );
  }
}

class _HighPass {
  late final double _b0, _b1, _b2, _a1, _a2;
  double _x1 = 0, _x2 = 0, _y1 = 0, _y2 = 0;

  _HighPass(double frequency, int sampleRate) {
    final w0 = 2 * pi * frequency / sampleRate;
    final alpha = sin(w0) / (2 * 0.707);
    final a0 = 1 + alpha;
    _b0 = ((1 + cos(w0)) / 2) / a0;
    _b1 = -(1 + cos(w0)) / a0;
    _b2 = _b0;
    _a1 = (-2 * cos(w0)) / a0;
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
