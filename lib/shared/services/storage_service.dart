import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/sound_data.dart';
import '../../core/models/focus_backup_payload.dart';
import '../../core/models/focus_external_sound.dart';
import '../../core/models/focus_session_record.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

class StorageService {
  static const _focusDurationKey = 'focusDuration';
  static const _breakDurationKey = 'breakDuration';
  static const _microRestSecondsKey = 'microRestSeconds';
  static const _minIntervalKey = 'minInterval';
  static const _maxIntervalKey = 'maxInterval';
  static const _selectedSoundIdKey = 'selectedSoundId';
  static const _randomSoundModeKey = 'randomSoundMode';
  static const _focusSoundEnabledKey = 'focusSoundEnabled';
  static const _selectedFocusSoundIdKey = 'selectedFocusSoundId';
  static const _randomFocusSoundModeKey = 'randomFocusSoundMode';
  static const _focusSoundSourceTypeKey = 'focusSoundSourceType';
  static const _selectedExternalFocusSoundJsonKey =
      'selectedExternalFocusSoundJson';
  static const _freesoundApiKeyKey = 'freesoundApiKey';
  static const _soundscapeApiKeyKey = 'soundscapeApiKey';
  static const _selectedFocusPresetIdKey = 'selectedFocusPresetId';
  static const _vibrationEnabledKey = 'vibrationEnabled';
  static const _showScienceTipsKey = 'showScienceTips';
  static const _themeModeKey = 'themeMode';
  static const _colorSchemeIdKey = 'colorSchemeId';
  static const _alertVolumeKey = 'alertVolume';
  static const _ambientVolumeKey = 'ambientVolume';
  static const _focusSoundVolumeKey = 'focusSoundVolume';
  static const _dailyGoalMinutesKey = 'dailyGoalMinutes';
  static const _deviceIdKey = 'deviceId';
  static const _sessionRecordsJsonKey = 'sessionRecordsJson';
  static const _totalFocusSecondsKey = 'totalFocusSeconds';
  static const _completedSessionsKey = 'completedSessions';
  static const _todayFocusSecondsKey = 'todayFocusSeconds';
  static const _todayDateKey = 'todayDate';
  static const _currentStreakKey = 'currentStreak';
  static const _bestStreakKey = 'bestStreak';
  static const _lastFocusDateKey = 'lastFocusDate';

  final SharedPreferences _prefs;
  final Random _random = Random.secure();

  StorageService(this._prefs);

  int get focusDuration =>
      _prefs.getInt(_focusDurationKey) ??
      AppConstants.defaultFocusDurationMinutes;
  Future<void> setFocusDuration(int value) =>
      _prefs.setInt(_focusDurationKey, value);

  int get breakDuration =>
      _prefs.getInt(_breakDurationKey) ??
      AppConstants.defaultBreakDurationMinutes;
  Future<void> setBreakDuration(int value) =>
      _prefs.setInt(_breakDurationKey, value);

  int get microRestSeconds =>
      _prefs.getInt(_microRestSecondsKey) ??
      AppConstants.defaultMicroRestSeconds;
  Future<void> setMicroRestSeconds(int value) =>
      _prefs.setInt(_microRestSecondsKey, value);

  int get minInterval =>
      _prefs.getInt(_minIntervalKey) ?? AppConstants.defaultMinIntervalMinutes;
  Future<void> setMinInterval(int value) =>
      _prefs.setInt(_minIntervalKey, value);

  int get maxInterval =>
      _prefs.getInt(_maxIntervalKey) ?? AppConstants.defaultMaxIntervalMinutes;
  Future<void> setMaxInterval(int value) =>
      _prefs.setInt(_maxIntervalKey, value);

  String get selectedSoundId =>
      _prefs.getString(_selectedSoundIdKey) ?? 'singing_bowl';
  Future<void> setSelectedSoundId(String value) =>
      _prefs.setString(_selectedSoundIdKey, value);

  bool get randomSoundMode => _prefs.getBool(_randomSoundModeKey) ?? false;
  Future<void> setRandomSoundMode(bool value) =>
      _prefs.setBool(_randomSoundModeKey, value);

  bool get focusSoundEnabled => _prefs.getBool(_focusSoundEnabledKey) ?? false;
  Future<void> setFocusSoundEnabled(bool value) =>
      _prefs.setBool(_focusSoundEnabledKey, value);

  String get selectedFocusSoundId =>
      _prefs.getString(_selectedFocusSoundIdKey) ?? 'brown_noise';
  Future<void> setSelectedFocusSoundId(String value) =>
      _prefs.setString(_selectedFocusSoundIdKey, value);

  bool get randomFocusSoundMode =>
      _prefs.getBool(_randomFocusSoundModeKey) ?? false;
  Future<void> setRandomFocusSoundMode(bool value) =>
      _prefs.setBool(_randomFocusSoundModeKey, value);

  FocusSoundSourceType get focusSoundSourceType =>
      parseFocusSoundSourceType(_prefs.getString(_focusSoundSourceTypeKey));
  Future<void> setFocusSoundSourceType(FocusSoundSourceType value) =>
      _prefs.setString(_focusSoundSourceTypeKey, value.name);

  FocusExternalSound? get selectedExternalFocusSound {
    final raw = _prefs.getString(_selectedExternalFocusSoundJsonKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final rawSource = json['sourceType'] as String?;
      if (rawSource != FocusSoundSourceType.wikimedia.name &&
          rawSource != FocusSoundSourceType.openverse.name) {
        return null;
      }
      return FocusExternalSound.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> setSelectedExternalFocusSound(FocusExternalSound value) async {
    await setFocusSoundSourceType(value.sourceType);
    await _prefs.setString(
      _selectedExternalFocusSoundJsonKey,
      jsonEncode(value.toJson()),
    );
  }

  Future<void> clearSelectedExternalFocusSound() =>
      _prefs.remove(_selectedExternalFocusSoundJsonKey);

  String get freesoundApiKey => _prefs.getString(_freesoundApiKeyKey) ?? '';
  Future<void> setFreesoundApiKey(String value) =>
      _prefs.setString(_freesoundApiKeyKey, value.trim());

  String get soundscapeApiKey => _prefs.getString(_soundscapeApiKeyKey) ?? '';
  Future<void> setSoundscapeApiKey(String value) =>
      _prefs.setString(_soundscapeApiKeyKey, value.trim());

  String get selectedFocusPresetId =>
      _prefs.getString(_selectedFocusPresetIdKey) ?? defaultFocusPresetId;
  Future<void> setSelectedFocusPresetId(String value) =>
      _prefs.setString(_selectedFocusPresetIdKey, value);

  Future<void> markFocusPresetCustom() =>
      _prefs.setString(_selectedFocusPresetIdKey, customFocusPresetId);

  Future<void> applyFocusPreset(FocusPreset preset) async {
    await setFocusDuration(preset.focusDurationMinutes);
    await setBreakDuration(preset.breakDurationMinutes);
    await setMicroRestSeconds(preset.microRestSeconds);
    await setMinInterval(preset.minIntervalMinutes);
    await setMaxInterval(preset.maxIntervalMinutes);
    await setFocusSoundEnabled(preset.focusSoundEnabled);
    await setFocusSoundSourceType(FocusSoundSourceType.builtIn);
    await setRandomFocusSoundMode(preset.randomFocusSoundMode);
    await setSelectedFocusSoundId(preset.selectedFocusSoundId);
    await setSelectedFocusPresetId(preset.id);
    if (!_prefs.containsKey(_dailyGoalMinutesKey)) {
      await setDailyGoalMinutes(preset.focusDurationMinutes);
    }
  }

  bool get vibrationEnabled => _prefs.getBool(_vibrationEnabledKey) ?? true;
  Future<void> setVibrationEnabled(bool value) =>
      _prefs.setBool(_vibrationEnabledKey, value);

  bool get showScienceTips => _prefs.getBool(_showScienceTipsKey) ?? true;
  Future<void> setShowScienceTips(bool value) =>
      _prefs.setBool(_showScienceTipsKey, value);

  String get themeMode => _prefs.getString(_themeModeKey) ?? 'system';
  Future<void> setThemeMode(String value) =>
      _prefs.setString(_themeModeKey, value);

  String get colorSchemeId =>
      _prefs.getString(_colorSchemeIdKey) ?? 'deep_blue';
  Future<void> setColorSchemeId(String value) =>
      _prefs.setString(_colorSchemeIdKey, value);

  double get alertVolume => _prefs.getDouble(_alertVolumeKey) ?? 0.7;
  Future<void> setAlertVolume(double value) =>
      _prefs.setDouble(_alertVolumeKey, value);

  double get ambientVolume => _prefs.getDouble(_ambientVolumeKey) ?? 0.5;
  Future<void> setAmbientVolume(double value) =>
      _prefs.setDouble(_ambientVolumeKey, value);

  double get focusSoundVolume =>
      _prefs.getDouble(_focusSoundVolumeKey) ?? ambientVolume;
  Future<void> setFocusSoundVolume(double value) =>
      _prefs.setDouble(_focusSoundVolumeKey, value);

  int get dailyGoalMinutes {
    final existing = _prefs.getInt(_dailyGoalMinutesKey);
    if (existing != null) {
      return existing;
    }

    final fallback = focusDuration.clamp(
      AppConstants.minDailyGoalMinutes,
      AppConstants.maxDailyGoalMinutes,
    );
    unawaited(_prefs.setInt(_dailyGoalMinutesKey, fallback));
    return fallback;
  }

  Future<void> setDailyGoalMinutes(int value) =>
      _prefs.setInt(_dailyGoalMinutesKey, value);

  String get deviceId {
    final existing = _prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final created = _generateId(prefix: 'device');
    unawaited(_prefs.setString(_deviceIdKey, created));
    return created;
  }

  Future<void> setDeviceId(String value) =>
      _prefs.setString(_deviceIdKey, value);

  int get totalFocusSeconds => _prefs.getInt(_totalFocusSecondsKey) ?? 0;
  Future<void> setTotalFocusSeconds(int value) =>
      _prefs.setInt(_totalFocusSecondsKey, value);

  int get completedSessions => _prefs.getInt(_completedSessionsKey) ?? 0;
  Future<void> setCompletedSessions(int value) =>
      _prefs.setInt(_completedSessionsKey, value);

  int get todayFocusSeconds => _prefs.getInt(_todayFocusSecondsKey) ?? 0;
  Future<void> setTodayFocusSeconds(int value) =>
      _prefs.setInt(_todayFocusSecondsKey, value);

  String get todayDate => _prefs.getString(_todayDateKey) ?? '';
  Future<void> setTodayDate(String value) =>
      _prefs.setString(_todayDateKey, value);

  int get currentStreak => _prefs.getInt(_currentStreakKey) ?? 0;
  Future<void> setCurrentStreak(int value) =>
      _prefs.setInt(_currentStreakKey, value);

  int get bestStreak => _prefs.getInt(_bestStreakKey) ?? 0;
  Future<void> setBestStreak(int value) => _prefs.setInt(_bestStreakKey, value);

  String get lastFocusDate => _prefs.getString(_lastFocusDateKey) ?? '';
  Future<void> setLastFocusDate(String value) =>
      _prefs.setString(_lastFocusDateKey, value);

  int getEffectiveCurrentStreak({DateTime? now}) {
    final stored = currentStreak;
    if (stored <= 0) {
      return 0;
    }

    final lastKey = lastFocusDate;
    if (lastKey.isEmpty) {
      return 0;
    }

    final lastDate = DateTime.tryParse(lastKey);
    if (lastDate == null) {
      return stored;
    }

    final today = _dateOnly(now ?? DateTime.now());
    final diffDays = today.difference(_dateOnly(lastDate)).inDays;
    if (diffDays <= 1) {
      return stored;
    }

    return 0;
  }

  Future<int> normalizeTodayStats({DateTime? now}) async {
    final todayKey = focusDateKey(now ?? DateTime.now());
    if (todayDate != todayKey) {
      await setTodayDate(todayKey);
      await setTodayFocusSeconds(0);
      return 0;
    }

    return todayFocusSeconds;
  }

  List<FocusSessionRecord> getSessionRecords() {
    final raw = _prefs.getString(_sessionRecordsJsonKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return const [];
      }

      final records = decoded
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (item) =>
                FocusSessionRecord.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      records.sort((a, b) => b.endedAt.compareTo(a.endedAt));
      return records;
    } catch (_) {
      return const [];
    }
  }

  Future<void> appendSessionRecord(FocusSessionRecord record) async {
    final records = [...getSessionRecords()];
    records.removeWhere((item) => item.id == record.id);
    records.add(record);
    records.sort((a, b) => b.endedAt.compareTo(a.endedAt));
    final trimmed = records.take(AppConstants.focusHistoryLimit).toList();
    await _writeSessionRecords(trimmed);
  }

  FocusBackupPayload exportBackup() {
    return FocusBackupPayload(
      version: AppConstants.backupSchemaVersion,
      exportedAt: DateTime.now(),
      deviceId: deviceId,
      settings: _exportSettingsMap(),
      stats: _exportStatsMap(),
      sessions: getSessionRecords(),
    );
  }

  Future<void> restoreBackup(FocusBackupPayload payload) async {
    if (payload.version > AppConstants.backupSchemaVersion) {
      throw const FormatException('Backup version is newer than this app.');
    }

    await _restoreSettings(payload.settings);
    await _restoreStats(payload.stats);
    await _writeSessionRecords(
      payload.sessions.take(AppConstants.focusHistoryLimit).toList(),
    );
    await normalizeTodayStats();
  }

  Future<void> clearHistoryOnly() async {
    await _writeSessionRecords(const []);
    await setTotalFocusSeconds(0);
    await setCompletedSessions(0);
    await setTodayFocusSeconds(0);
    await setTodayDate(focusDateKey(DateTime.now()));
    await setCurrentStreak(0);
    await setBestStreak(0);
    await setLastFocusDate('');
  }

  Future<void> recomputeStatsFromRecords({DateTime? now}) async {
    final today = _dateOnly(now ?? DateTime.now());
    final todayKey = focusDateKey(today);
    final records = getSessionRecords();

    var total = 0;
    var completed = 0;
    var todayTotal = 0;
    final perDay = <String, int>{};

    for (final record in records) {
      total += record.actualFocusSeconds;
      if (record.status == FocusSessionStatus.completed) {
        completed += 1;
      }

      final dayKey = focusDateKey(record.startedAt);
      perDay.update(
        dayKey,
        (value) => value + record.actualFocusSeconds,
        ifAbsent: () => record.actualFocusSeconds,
      );
      if (dayKey == todayKey) {
        todayTotal += record.actualFocusSeconds;
      }
    }

    final sortedDays = perDay.keys.toList()..sort();
    final best = _computeBestStreak(sortedDays);
    final current = _computeCurrentStreak(sortedDays, today);
    final latestDay = sortedDays.isEmpty ? '' : sortedDays.last;

    await setTotalFocusSeconds(total);
    await setCompletedSessions(completed);
    await setTodayDate(todayKey);
    await setTodayFocusSeconds(todayTotal);
    await setCurrentStreak(current);
    await setBestStreak(best);
    await setLastFocusDate(latestDay);
  }

  Map<String, int> getRecentDailyFocusSeconds({int days = 7, DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final records = getSessionRecords();
    final result = <String, int>{};

    for (var index = days - 1; index >= 0; index--) {
      final day = today.subtract(Duration(days: index));
      result[focusDateKey(day)] = 0;
    }

    for (final record in records) {
      final dayKey = focusDateKey(record.startedAt);
      if (result.containsKey(dayKey)) {
        result[dayKey] = result[dayKey]! + record.actualFocusSeconds;
      }
    }

    return result;
  }

  Future<void> _writeSessionRecords(List<FocusSessionRecord> records) {
    final encoded = jsonEncode(
      records.map((record) => record.toJson()).toList(),
    );
    return _prefs.setString(_sessionRecordsJsonKey, encoded);
  }

  Map<String, Object?> _exportSettingsMap() {
    return {
      _focusDurationKey: focusDuration,
      _breakDurationKey: breakDuration,
      _microRestSecondsKey: microRestSeconds,
      _minIntervalKey: minInterval,
      _maxIntervalKey: maxInterval,
      _selectedSoundIdKey: selectedSoundId,
      _randomSoundModeKey: randomSoundMode,
      _focusSoundEnabledKey: focusSoundEnabled,
      _selectedFocusSoundIdKey: selectedFocusSoundId,
      _randomFocusSoundModeKey: randomFocusSoundMode,
      _focusSoundSourceTypeKey: focusSoundSourceType.name,
      _selectedExternalFocusSoundJsonKey: selectedExternalFocusSound != null
          ? jsonEncode(selectedExternalFocusSound!.toJson())
          : null,
      _selectedFocusPresetIdKey: selectedFocusPresetId,
      _vibrationEnabledKey: vibrationEnabled,
      _showScienceTipsKey: showScienceTips,
      _themeModeKey: themeMode,
      _colorSchemeIdKey: colorSchemeId,
      _alertVolumeKey: alertVolume,
      _ambientVolumeKey: ambientVolume,
      _focusSoundVolumeKey: focusSoundVolume,
      _dailyGoalMinutesKey: dailyGoalMinutes,
    };
  }

  Map<String, Object?> _exportStatsMap() {
    return {
      _totalFocusSecondsKey: totalFocusSeconds,
      _completedSessionsKey: completedSessions,
      _todayFocusSecondsKey: todayFocusSeconds,
      _todayDateKey: todayDate,
      _currentStreakKey: currentStreak,
      _bestStreakKey: bestStreak,
      _lastFocusDateKey: lastFocusDate,
    };
  }

  Future<void> _restoreSettings(Map<String, Object?> settings) async {
    Future<void> writeValue(String key, Object? value) async {
      if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is double) {
        await _prefs.setDouble(key, value);
      } else if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is String) {
        await _prefs.setString(key, value);
      }
    }

    for (final entry in settings.entries) {
      await writeValue(entry.key, entry.value);
    }
  }

  Future<void> _restoreStats(Map<String, Object?> stats) async {
    Future<void> writeInt(String key, Object? value) async {
      if (value is int) {
        await _prefs.setInt(key, value);
      }
    }

    Future<void> writeString(String key, Object? value) async {
      if (value is String) {
        await _prefs.setString(key, value);
      }
    }

    await writeInt(_totalFocusSecondsKey, stats[_totalFocusSecondsKey]);
    await writeInt(_completedSessionsKey, stats[_completedSessionsKey]);
    await writeInt(_todayFocusSecondsKey, stats[_todayFocusSecondsKey]);
    await writeString(_todayDateKey, stats[_todayDateKey]);
    await writeInt(_currentStreakKey, stats[_currentStreakKey]);
    await writeInt(_bestStreakKey, stats[_bestStreakKey]);
    await writeString(_lastFocusDateKey, stats[_lastFocusDateKey]);
  }

  int _computeBestStreak(List<String> sortedDays) {
    if (sortedDays.isEmpty) {
      return 0;
    }

    var best = 0;
    var current = 0;
    DateTime? previous;

    for (final dayKey in sortedDays) {
      final date = DateTime.tryParse(dayKey);
      if (date == null) {
        continue;
      }

      if (previous == null ||
          _dateOnly(date).difference(_dateOnly(previous)).inDays > 1) {
        current = 1;
      } else if (_dateOnly(date).difference(_dateOnly(previous)).inDays == 1) {
        current += 1;
      }

      if (current > best) {
        best = current;
      }
      previous = date;
    }

    return best;
  }

  int _computeCurrentStreak(List<String> sortedDays, DateTime today) {
    if (sortedDays.isEmpty) {
      return 0;
    }

    final dates = sortedDays
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .map(_dateOnly)
        .toList();
    if (dates.isEmpty) {
      return 0;
    }

    final last = dates.last;
    final gap = today.difference(last).inDays;
    if (gap > 1) {
      return 0;
    }

    var streak = 1;
    for (var index = dates.length - 1; index > 0; index--) {
      final diff = dates[index].difference(dates[index - 1]).inDays;
      if (diff == 1) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String _generateId({required String prefix}) {
    final micros = DateTime.now().microsecondsSinceEpoch;
    final randomBits = _random.nextInt(1 << 32).toRadixString(16);
    return '$prefix-$micros-$randomBits';
  }
}
