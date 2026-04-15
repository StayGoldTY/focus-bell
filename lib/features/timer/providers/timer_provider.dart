import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/sound_data.dart';
import '../../../core/models/focus_session_record.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/storage_service.dart';
import '../models/timer_state.dart';
import 'focus_session_draft_provider.dart';

final timerProvider = StateNotifierProvider<TimerNotifier, FocusTimerState>((
  ref,
) {
  return TimerNotifier(ref);
});

class TimerNotifier extends StateNotifier<FocusTimerState>
    with WidgetsBindingObserver {
  final Ref _ref;
  final StorageService _storage;
  final AudioService _audio;
  final _random = Random();
  Timer? _ticker;
  String? _activeFocusSoundId;
  DateTime _phaseStartedAt = DateTime.now();
  int _phaseAccumulated = 0;
  int _focusingAccumulated = 0;
  DateTime? _nextBellAt;
  int _baseTodayFocusSeconds = 0;
  _FocusSessionSnapshot? _sessionSnapshot;
  bool _shouldResumeAmbientAfterMicroRest = false;

  TimerNotifier(this._ref)
    : _storage = _ref.read(storageServiceProvider),
      _audio = _ref.read(audioServiceProvider),
      super(const FocusTimerState()) {
    WidgetsBinding.instance.addObserver(this);
    _loadTodayStats();
  }

  int get _currentPhaseElapsed {
    if (state.phase == TimerPhase.paused || state.phase == TimerPhase.idle) {
      return _phaseAccumulated;
    }
    return _phaseAccumulated +
        DateTime.now().difference(_phaseStartedAt).inSeconds;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  void _onAppResumed() {
    final phase = state.phase;
    if (phase != TimerPhase.idle && phase != TimerPhase.paused) {
      _tick();
    }
  }

  void _loadTodayStats() {
    final today = focusDateKey(DateTime.now());
    if (_storage.todayDate != today) {
      unawaited(_storage.setTodayDate(today));
      unawaited(_storage.setTodayFocusSeconds(0));
      state = state.copyWith(todayFocusSeconds: 0);
      return;
    }

    state = state.copyWith(todayFocusSeconds: _storage.todayFocusSeconds);
  }

  void startFocus() {
    final totalSeconds = _storage.focusDuration * 60;
    final now = DateTime.now();
    final draft = _ref.read(focusSessionDraftProvider);

    _focusingAccumulated = 0;
    _phaseAccumulated = 0;
    _phaseStartedAt = now;
    _baseTodayFocusSeconds = _storage.todayFocusSeconds;
    _scheduleNextBell();
    _selectFocusSoundscapeForSession();
    _sessionSnapshot = _FocusSessionSnapshot(
      startedAt: now,
      plannedFocusSeconds: totalSeconds,
      presetId: _storage.selectedFocusPresetId,
      focusSoundId: _activeFocusSoundId,
      taskTitle: draft.normalizedTitle,
      taskCategoryId: draft.categoryId,
    );

    _audio.requestWakeLock();
    _restartFocusSoundscape();

    state = state.copyWith(
      phase: TimerPhase.focusing,
      elapsedSeconds: 0,
      totalSeconds: totalSeconds,
      nextBellInSeconds: _nextBellAt!.difference(DateTime.now()).inSeconds,
      microRestCount: 0,
      activeFocusSoundId: () => _activeFocusSoundId,
    );

    _startTicker();
  }

  void pause() {
    final currentPhase = state.phase;
    final elapsed = _currentPhaseElapsed;

    if (currentPhase == TimerPhase.focusing) {
      _focusingAccumulated += elapsed;
      _stopFocusSoundscape();
    }
    _phaseAccumulated = elapsed;
    _ticker?.cancel();

    state = state.copyWith(
      phase: TimerPhase.paused,
      pausedFromPhase: () => currentPhase,
    );
  }

  void resume() {
    final target = state.pausedFromPhase ?? TimerPhase.focusing;
    _phaseStartedAt = DateTime.now();

    if (target == TimerPhase.focusing) {
      _phaseAccumulated = 0;
      _scheduleNextBell();
      _restartFocusSoundscape();
    }

    state = state.copyWith(
      phase: target,
      pausedFromPhase: () => null,
      activeFocusSoundId: () => _activeFocusSoundId,
    );
    _startTicker();
  }

  void stop() {
    _ticker?.cancel();
    unawaited(_audio.stopAll());
    _audio.releaseWakeLock();

    if (state.phase == TimerPhase.focusing) {
      _captureCurrentFocusProgressBeforeExit();
    }

    if (state.phase == TimerPhase.focusing ||
        state.pausedFromPhase == TimerPhase.focusing) {
      _finalizeFocusSession(
        status: FocusSessionStatus.stopped,
        microRestCount: state.microRestCount,
      );
    } else {
      _clearSessionMetadata();
    }

    _resetToIdleState();
  }

  void skipBreak() {
    _ticker?.cancel();
    unawaited(_audio.stopAll());
    _audio.releaseWakeLock();
    _clearSessionMetadata();
    _resetToIdleState();
  }

  void extendBreak() {
    state = state.copyWith(totalSeconds: state.totalSeconds + 300);
  }

  void syncCurrentFocusSoundFromSettings() {
    final snapshot = _sessionSnapshot;
    if (snapshot == null) {
      return;
    }

    _shouldResumeAmbientAfterMicroRest = false;

    if (!_storage.focusSoundEnabled) {
      _activeFocusSoundId = null;
      _sessionSnapshot = snapshot.copyWith(focusSoundId: () => null);
      _stopFocusSoundscape();
      state = state.copyWith(activeFocusSoundId: () => null);
      return;
    }

    if (_storage.randomFocusSoundMode) {
      _selectFocusSoundscapeForSession();
    } else {
      _activeFocusSoundId = _storage.selectedFocusSoundId;
    }

    _sessionSnapshot = snapshot.copyWith(
      focusSoundId: () => _activeFocusSoundId,
    );
    if (state.phase == TimerPhase.focusing) {
      _restartFocusSoundscape();
    }
    state = state.copyWith(activeFocusSoundId: () => _activeFocusSoundId);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    switch (state.phase) {
      case TimerPhase.focusing:
        _tickFocusing();
        break;
      case TimerPhase.microRest:
        _tickMicroRest();
        break;
      case TimerPhase.longBreak:
        _tickLongBreak();
        break;
      case TimerPhase.idle:
      case TimerPhase.paused:
        break;
    }
  }

  void _tickFocusing() {
    final phaseElapsed = _currentPhaseElapsed;
    final totalFocusing = _focusingAccumulated + phaseElapsed;
    final totalSeconds = _sessionSnapshot?.plannedFocusSeconds ?? 0;
    final newTodaySeconds = _baseTodayFocusSeconds + totalFocusing;

    unawaited(_storage.setTodayFocusSeconds(newTodaySeconds));

    if (totalFocusing >= totalSeconds) {
      _ticker?.cancel();
      _focusingAccumulated = totalFocusing;
      _finalizeFocusSession(
        status: FocusSessionStatus.completed,
        microRestCount: state.microRestCount,
      );
      _startLongBreak();
      return;
    }

    final now = DateTime.now();
    if (_nextBellAt != null && now.isAfter(_nextBellAt!)) {
      _focusingAccumulated += phaseElapsed;
      _playAlertSound();
      _enterMicroRest();
      return;
    }

    final bellIn = _nextBellAt != null
        ? _nextBellAt!.difference(now).inSeconds.clamp(0, 99999)
        : 0;

    state = state.copyWith(
      elapsedSeconds: totalFocusing,
      totalSeconds: totalSeconds,
      nextBellInSeconds: bellIn,
      todayFocusSeconds: newTodaySeconds,
    );
  }

  void _tickMicroRest() {
    final elapsed = _currentPhaseElapsed;
    if (elapsed >= state.totalSeconds) {
      _resumeFromMicroRest();
      return;
    }
    state = state.copyWith(elapsedSeconds: elapsed);
  }

  void _tickLongBreak() {
    final elapsed = _currentPhaseElapsed;
    if (elapsed >= state.totalSeconds) {
      _ticker?.cancel();
      unawaited(_audio.stopAll());
      _audio.releaseWakeLock();
      _playAlertSound();
      state = FocusTimerState(todayFocusSeconds: state.todayFocusSeconds);
      return;
    }
    state = state.copyWith(elapsedSeconds: elapsed);
  }

  void _enterMicroRest() {
    final microSeconds = _storage.microRestSeconds;
    _phaseStartedAt = DateTime.now();
    _phaseAccumulated = 0;
    _shouldResumeAmbientAfterMicroRest = _activeFocusSoundId != null;
    _pauseFocusSoundscape();

    state = state.copyWith(
      phase: TimerPhase.microRest,
      elapsedSeconds: 0,
      totalSeconds: microSeconds,
      microRestCount: state.microRestCount + 1,
      activeFocusSoundId: () => _activeFocusSoundId,
    );
  }

  void _resumeFromMicroRest() {
    _phaseStartedAt = DateTime.now();
    _phaseAccumulated = 0;
    _scheduleNextBell();
    _playAlertSound();
    if (_shouldResumeAmbientAfterMicroRest) {
      _resumeFocusSoundscape();
    } else {
      _restartFocusSoundscape();
    }
    _shouldResumeAmbientAfterMicroRest = false;

    state = state.copyWith(
      phase: TimerPhase.focusing,
      elapsedSeconds: _focusingAccumulated,
      totalSeconds: _sessionSnapshot?.plannedFocusSeconds ?? 0,
      nextBellInSeconds: _nextBellAt!.difference(DateTime.now()).inSeconds,
      activeFocusSoundId: () => _activeFocusSoundId,
    );
  }

  void _startLongBreak() {
    final breakSeconds = _storage.breakDuration * 60;
    _phaseStartedAt = DateTime.now();
    _phaseAccumulated = 0;
    _focusingAccumulated = 0;
    _shouldResumeAmbientAfterMicroRest = false;
    _stopFocusSoundscape();
    _activeFocusSoundId = null;

    state = state.copyWith(
      phase: TimerPhase.longBreak,
      elapsedSeconds: 0,
      totalSeconds: breakSeconds,
      todayFocusSeconds: state.todayFocusSeconds,
      activeFocusSoundId: () => null,
    );
    _startTicker();
  }

  void _scheduleNextBell() {
    final minSeconds = _storage.minInterval * 60;
    final maxSeconds = _storage.maxInterval * 60;
    final delay = minSeconds + _random.nextInt(maxSeconds - minSeconds + 1);
    _nextBellAt = DateTime.now().add(Duration(seconds: delay));
  }

  void _playAlertSound() {
    final sounds = builtInSounds;
    if (sounds.isEmpty) {
      return;
    }

    if (_storage.randomSoundMode) {
      final sound = sounds[_random.nextInt(sounds.length)];
      unawaited(_audio.playBuiltInSound(sound, volume: _storage.alertVolume));
      return;
    }

    final sound = sounds.firstWhere(
      (item) => item.id == _storage.selectedSoundId,
      orElse: () => sounds.first,
    );
    unawaited(_audio.playBuiltInSound(sound, volume: _storage.alertVolume));
  }

  void _selectFocusSoundscapeForSession() {
    if (!_storage.focusSoundEnabled || focusSoundscapes.isEmpty) {
      _activeFocusSoundId = null;
      return;
    }

    if (_storage.randomFocusSoundMode) {
      final soundscape =
          focusSoundscapes[_random.nextInt(focusSoundscapes.length)];
      _activeFocusSoundId = soundscape.id;
      return;
    }

    final selected = focusSoundscapes.firstWhere(
      (soundscape) => soundscape.id == _storage.selectedFocusSoundId,
      orElse: () => focusSoundscapes.first,
    );
    _activeFocusSoundId = selected.id;
  }

  void _restartFocusSoundscape() {
    if (!_storage.focusSoundEnabled || _activeFocusSoundId == null) {
      return;
    }

    final soundscape = focusSoundscapes.firstWhere(
      (item) => item.id == _activeFocusSoundId,
      orElse: () => focusSoundscapes.first,
    );
    unawaited(
      _audio.playFocusSoundscape(soundscape, volume: _storage.focusSoundVolume),
    );
  }

  void _stopFocusSoundscape() {
    unawaited(_audio.stopAmbient());
  }

  void _pauseFocusSoundscape() {
    unawaited(_audio.pauseAmbient());
  }

  void _resumeFocusSoundscape() {
    if (!_storage.focusSoundEnabled || _activeFocusSoundId == null) {
      return;
    }
    unawaited(_audio.resumeAmbient());
  }

  void _captureCurrentFocusProgressBeforeExit() {
    if (state.phase == TimerPhase.focusing) {
      _focusingAccumulated += _currentPhaseElapsed;
    }
  }

  void _finalizeFocusSession({
    required FocusSessionStatus status,
    required int microRestCount,
  }) {
    final snapshot = _sessionSnapshot;
    if (snapshot == null) {
      _clearSessionMetadata();
      return;
    }

    final shouldPersist =
        status == FocusSessionStatus.completed ||
        _focusingAccumulated >= AppConstants.minRecordableFocusSeconds;

    if (shouldPersist && _focusingAccumulated > 0) {
      final record = FocusSessionRecord(
        id: _buildSessionRecordId(snapshot.startedAt),
        deviceId: _storage.deviceId,
        schemaVersion: AppConstants.focusSessionSchemaVersion,
        startedAt: snapshot.startedAt,
        endedAt: DateTime.now(),
        actualFocusSeconds: _focusingAccumulated,
        plannedFocusSeconds: snapshot.plannedFocusSeconds,
        microRestCount: microRestCount,
        status: status,
        presetId: snapshot.presetId,
        focusSoundId: snapshot.focusSoundId,
        taskTitle: snapshot.taskTitle,
        taskCategoryId: snapshot.taskCategoryId,
      );

      unawaited(_storage.appendSessionRecord(record));
      unawaited(
        _storage.setTotalFocusSeconds(
          _storage.totalFocusSeconds + _focusingAccumulated,
        ),
      );
      if (status == FocusSessionStatus.completed) {
        unawaited(
          _storage.setCompletedSessions(_storage.completedSessions + 1),
        );
      }
      _updateFocusStreak(record.startedAt);
    }

    _clearSessionMetadata();
  }

  void _updateFocusStreak(DateTime focusDate) {
    final todayKey = focusDateKey(focusDate);
    final lastKey = _storage.lastFocusDate;

    if (lastKey == todayKey) {
      return;
    }

    var currentStreak = _storage.currentStreak;

    if (lastKey.isNotEmpty) {
      final lastDate = DateTime.tryParse(lastKey);
      if (lastDate != null) {
        final diffDays =
            DateTime(focusDate.year, focusDate.month, focusDate.day)
                .difference(
                  DateTime(lastDate.year, lastDate.month, lastDate.day),
                )
                .inDays;
        currentStreak = diffDays == 1 ? currentStreak + 1 : 1;
      } else {
        currentStreak = 1;
      }
    } else {
      currentStreak = 1;
    }

    unawaited(_storage.setCurrentStreak(currentStreak));
    if (currentStreak > _storage.bestStreak) {
      unawaited(_storage.setBestStreak(currentStreak));
    }
    unawaited(_storage.setLastFocusDate(todayKey));
  }

  String _buildSessionRecordId(DateTime startedAt) {
    return '${_storage.deviceId}-${startedAt.microsecondsSinceEpoch}';
  }

  void _clearSessionMetadata() {
    _sessionSnapshot = null;
    _activeFocusSoundId = null;
    _shouldResumeAmbientAfterMicroRest = false;
    _ref.read(focusSessionDraftProvider.notifier).clear();
  }

  void _resetToIdleState() {
    _focusingAccumulated = 0;
    _phaseAccumulated = 0;
    _nextBellAt = null;
    _shouldResumeAmbientAfterMicroRest = false;
    state = FocusTimerState(todayFocusSeconds: _storage.todayFocusSeconds);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _audio.releaseWakeLock();
    super.dispose();
  }
}

class _FocusSessionSnapshot {
  final DateTime startedAt;
  final int plannedFocusSeconds;
  final String presetId;
  final String? focusSoundId;
  final String? taskTitle;
  final String? taskCategoryId;

  const _FocusSessionSnapshot({
    required this.startedAt,
    required this.plannedFocusSeconds,
    required this.presetId,
    required this.focusSoundId,
    required this.taskTitle,
    required this.taskCategoryId,
  });

  _FocusSessionSnapshot copyWith({
    int? plannedFocusSeconds,
    String? presetId,
    String? Function()? focusSoundId,
    String? taskTitle,
    String? Function()? taskCategoryId,
  }) {
    return _FocusSessionSnapshot(
      startedAt: startedAt,
      plannedFocusSeconds: plannedFocusSeconds ?? this.plannedFocusSeconds,
      presetId: presetId ?? this.presetId,
      focusSoundId: focusSoundId != null ? focusSoundId() : this.focusSoundId,
      taskTitle: taskTitle ?? this.taskTitle,
      taskCategoryId: taskCategoryId != null
          ? taskCategoryId()
          : this.taskCategoryId,
    );
  }
}
