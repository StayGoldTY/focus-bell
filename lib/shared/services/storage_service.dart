import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/sound_data.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

class StorageService {
  final SharedPreferences _prefs;
  StorageService(this._prefs);

  // 专注时长（分钟）
  int get focusDuration =>
      _prefs.getInt('focusDuration') ??
      AppConstants.defaultFocusDurationMinutes;
  Future<void> setFocusDuration(int v) => _prefs.setInt('focusDuration', v);

  // 休息时长（分钟）
  int get breakDuration =>
      _prefs.getInt('breakDuration') ??
      AppConstants.defaultBreakDurationMinutes;
  Future<void> setBreakDuration(int v) => _prefs.setInt('breakDuration', v);

  // 微休息时长（秒）
  int get microRestSeconds =>
      _prefs.getInt('microRestSeconds') ?? AppConstants.defaultMicroRestSeconds;
  Future<void> setMicroRestSeconds(int v) =>
      _prefs.setInt('microRestSeconds', v);

  // 随机间隔最小值（分钟）
  int get minInterval =>
      _prefs.getInt('minInterval') ?? AppConstants.defaultMinIntervalMinutes;
  Future<void> setMinInterval(int v) => _prefs.setInt('minInterval', v);

  // 随机间隔最大值（分钟）
  int get maxInterval =>
      _prefs.getInt('maxInterval') ?? AppConstants.defaultMaxIntervalMinutes;
  Future<void> setMaxInterval(int v) => _prefs.setInt('maxInterval', v);

  // 选中的提示音 ID
  String get selectedSoundId =>
      _prefs.getString('selectedSoundId') ?? 'singing_bowl';
  Future<void> setSelectedSoundId(String v) =>
      _prefs.setString('selectedSoundId', v);

  // 随机提示音模式
  bool get randomSoundMode => _prefs.getBool('randomSoundMode') ?? false;
  Future<void> setRandomSoundMode(bool v) =>
      _prefs.setBool('randomSoundMode', v);

  // 专注背景音开关
  bool get focusSoundEnabled => _prefs.getBool('focusSoundEnabled') ?? false;
  Future<void> setFocusSoundEnabled(bool v) =>
      _prefs.setBool('focusSoundEnabled', v);

  // 选中的专注背景音 ID
  String get selectedFocusSoundId =>
      _prefs.getString('selectedFocusSoundId') ?? 'brown_noise';
  Future<void> setSelectedFocusSoundId(String v) =>
      _prefs.setString('selectedFocusSoundId', v);

  // 随机专注背景音模式
  bool get randomFocusSoundMode =>
      _prefs.getBool('randomFocusSoundMode') ?? false;
  Future<void> setRandomFocusSoundMode(bool v) =>
      _prefs.setBool('randomFocusSoundMode', v);

  // 当前选择的专注预设
  String get selectedFocusPresetId =>
      _prefs.getString('selectedFocusPresetId') ?? defaultFocusPresetId;
  Future<void> setSelectedFocusPresetId(String v) =>
      _prefs.setString('selectedFocusPresetId', v);
  Future<void> markFocusPresetCustom() =>
      _prefs.setString('selectedFocusPresetId', customFocusPresetId);

  Future<void> applyFocusPreset(FocusPreset preset) async {
    await setFocusDuration(preset.focusDurationMinutes);
    await setBreakDuration(preset.breakDurationMinutes);
    await setMicroRestSeconds(preset.microRestSeconds);
    await setMinInterval(preset.minIntervalMinutes);
    await setMaxInterval(preset.maxIntervalMinutes);
    await setFocusSoundEnabled(preset.focusSoundEnabled);
    await setRandomFocusSoundMode(preset.randomFocusSoundMode);
    await setSelectedFocusSoundId(preset.selectedFocusSoundId);
    await setSelectedFocusPresetId(preset.id);
  }

  // 震动开关
  bool get vibrationEnabled => _prefs.getBool('vibrationEnabled') ?? true;
  Future<void> setVibrationEnabled(bool v) =>
      _prefs.setBool('vibrationEnabled', v);

  // 科学贴士显示
  bool get showScienceTips => _prefs.getBool('showScienceTips') ?? true;
  Future<void> setShowScienceTips(bool v) =>
      _prefs.setBool('showScienceTips', v);

  // 主题模式: 'light', 'dark', 'system'
  String get themeMode => _prefs.getString('themeMode') ?? 'system';
  Future<void> setThemeMode(String v) => _prefs.setString('themeMode', v);

  // 主题配色方案 ID
  String get colorSchemeId => _prefs.getString('colorSchemeId') ?? 'deep_blue';
  Future<void> setColorSchemeId(String v) =>
      _prefs.setString('colorSchemeId', v);

  // 提示音音量 0.0~1.0
  double get alertVolume => _prefs.getDouble('alertVolume') ?? 0.7;
  Future<void> setAlertVolume(double v) => _prefs.setDouble('alertVolume', v);

  // 环境音音量
  double get ambientVolume => _prefs.getDouble('ambientVolume') ?? 0.5;
  Future<void> setAmbientVolume(double v) =>
      _prefs.setDouble('ambientVolume', v);

  // 专注背景音音量
  double get focusSoundVolume =>
      _prefs.getDouble('focusSoundVolume') ?? ambientVolume;
  Future<void> setFocusSoundVolume(double v) =>
      _prefs.setDouble('focusSoundVolume', v);

  // 统计数据：总专注秒数
  int get totalFocusSeconds => _prefs.getInt('totalFocusSeconds') ?? 0;
  Future<void> setTotalFocusSeconds(int v) =>
      _prefs.setInt('totalFocusSeconds', v);

  // 统计数据：完成轮次
  int get completedSessions => _prefs.getInt('completedSessions') ?? 0;
  Future<void> setCompletedSessions(int v) =>
      _prefs.setInt('completedSessions', v);

  // 今日专注秒数
  int get todayFocusSeconds => _prefs.getInt('todayFocusSeconds') ?? 0;
  Future<void> setTodayFocusSeconds(int v) =>
      _prefs.setInt('todayFocusSeconds', v);

  // 今日日期标记
  String get todayDate => _prefs.getString('todayDate') ?? '';
  Future<void> setTodayDate(String v) => _prefs.setString('todayDate', v);

  // 连续专注天数
  int get currentStreak => _prefs.getInt('currentStreak') ?? 0;
  Future<void> setCurrentStreak(int v) => _prefs.setInt('currentStreak', v);

  int get bestStreak => _prefs.getInt('bestStreak') ?? 0;
  Future<void> setBestStreak(int v) => _prefs.setInt('bestStreak', v);

  String get lastFocusDate => _prefs.getString('lastFocusDate') ?? '';
  Future<void> setLastFocusDate(String v) => _prefs.setString('lastFocusDate', v);
}
