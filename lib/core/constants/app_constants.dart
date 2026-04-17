class AppConstants {
  AppConstants._();

  static const String appName = 'FocusBell';
  static const String appVersion = '1.0.0';

  static const int focusSessionSchemaVersion = 1;
  static const int backupSchemaVersion = 1;
  static const int focusHistoryLimit = 2000;
  static const int minRecordableFocusSeconds = 60;

  static const int defaultFocusDurationMinutes = 90;
  static const int defaultBreakDurationMinutes = 20;
  static const int defaultMicroRestSeconds = 10;
  static const int defaultMinIntervalMinutes = 3;
  static const int defaultMaxIntervalMinutes = 5;
  static const int defaultDailyGoalMinutes = defaultFocusDurationMinutes;

  static const int minFocusDuration = 15;
  static const int maxFocusDuration = 120;
  static const int minBreakDuration = 5;
  static const int maxBreakDuration = 30;
  static const int minMicroRestSeconds = 5;
  static const int maxMicroRestSeconds = 30;
  static const int minIntervalMinutes = 1;
  static const int maxIntervalMinutes = 10;
  static const int minDailyGoalMinutes = 30;
  static const int maxDailyGoalMinutes = 360;

  static const Duration fadeInDuration = Duration(milliseconds: 800);
  static const Duration fadeOutDuration = Duration(milliseconds: 500);
  static const Duration pulseAnimationDuration = Duration(milliseconds: 2000);

  static const String wikimediaCommonsApiUrl =
      'https://commons.wikimedia.org/w/api.php';
  static const String openverseApiUrl = 'https://api.openverse.org/v1/audio/';
}
