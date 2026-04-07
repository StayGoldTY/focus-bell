class AppConstants {
  AppConstants._();

  static const String appName = 'FocusBell';
  static const String appVersion = '1.0.0';

  // 默认计时参数（基于 BRAC 超日节律研究）
  static const int defaultFocusDurationMinutes = 90;
  static const int defaultBreakDurationMinutes = 20;
  static const int defaultMicroRestSeconds = 10;
  static const int defaultMinIntervalMinutes = 3;
  static const int defaultMaxIntervalMinutes = 5;

  // 参数可调范围
  static const int minFocusDuration = 15;
  static const int maxFocusDuration = 120;
  static const int minBreakDuration = 5;
  static const int maxBreakDuration = 30;
  static const int minMicroRestSeconds = 5;
  static const int maxMicroRestSeconds = 30;
  static const int minIntervalMinutes = 1;
  static const int maxIntervalMinutes = 10;

  // 动画时长
  static const Duration fadeInDuration = Duration(milliseconds: 800);
  static const Duration fadeOutDuration = Duration(milliseconds: 500);
  static const Duration pulseAnimationDuration = Duration(milliseconds: 2000);

  // API
  static const String freesoundBaseUrl = 'https://freesound.org/apiv2';
  static const String soundscapeCityBaseUrl = 'https://api.soundscape.city/v1';
}
