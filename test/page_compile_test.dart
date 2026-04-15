import 'package:flutter_test/flutter_test.dart';

import 'package:focus_bell/features/settings/pages/settings_page.dart';
import 'package:focus_bell/features/statistics/pages/statistics_page.dart';
import 'package:focus_bell/features/timer/pages/timer_page.dart';

void main() {
  test('main pages can be instantiated', () {
    expect(const TimerPage(), isA<TimerPage>());
    expect(const SettingsPage(), isA<SettingsPage>());
    expect(const StatisticsPage(), isA<StatisticsPage>());
  });
}
