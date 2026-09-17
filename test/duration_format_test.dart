import 'package:flutter_test/flutter_test.dart';

import 'package:focus_bell/core/constants/focus_quotes.dart';
import 'package:focus_bell/core/constants/sound_data.dart';
import 'package:focus_bell/core/theme/color_schemes.dart';
import 'package:focus_bell/core/utils/duration_format.dart';

void main() {
  test('formatClock pads minutes and seconds', () {
    expect(formatClock(0), '00:00');
    expect(formatClock(25 * 60), '25:00');
    expect(formatClock(90 * 60 + 7), '90:07');
  });

  test('keeps three presets and three color schemes', () {
    expect(focusPresets.map((preset) => preset.id), [
      defaultFocusPresetId,
      'gentle_study',
      'mindful_reset',
    ]);
    expect(appColorSchemes.map((scheme) => scheme.id), [
      'deep_blue',
      'forest_green',
      'sunset_orange',
    ]);
  });

  test('daily quote is stable for the same date', () {
    final date = DateTime(2026, 9, 16);
    expect(FocusQuotes.forDate(date), FocusQuotes.forDate(date));
    expect(
      FocusQuotes.forDate(date),
      isNot(FocusQuotes.forDate(date.add(const Duration(days: 1)))),
    );
  });
}
