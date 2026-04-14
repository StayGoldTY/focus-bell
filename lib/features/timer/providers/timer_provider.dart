import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/sound_data.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/storage_service.dart';
import '../models/timer_state.dart';

final timerProvider = StateNotifierProvider<TimerNotifier, FocusTimerState>((
  ref,
) {
  return TimerNotifier(ref);
});

class TimerNotifier extends StateNotifier<FocusTimerState>
    with WidgetsBindingObserver {
  final Ref _ref;
  Timer? _ticker;
  final _random = Random();

  /// Wall-clock anchor: when the current phase segment started
  DateTime _phaseStartedAt = DateTime.now();

  /// Seconds accumulated in this phase before the current segment
  /// (used to survive pause/resume without losing progress)
  int _phaseAccumulated = 0;

  /// Total focusing seconds accumulated across micro-rest interruptions
  int _focusingAccumulated = 0;

  /// Wall-clock time when the next bell should ring
  DateTime? _nextBellAt;

  /// Today's focus seconds at the start of the current session
  int _baseTodayFocusSeconds = 0;

  TimerNotifier(this._ref) : super(const FocusTimerState()) {
    WidgetsBinding.instance.addObserver(this);
    _loadTodayStats();
  }

  StorageService get _storage => _ref.read(storageServiceProvider);
  AudioService get _audio => _ref.read(audioServiceProvider);

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
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_storage.todayDate != today) {
      _storage.setTodayDate(today);
      _storage.setTodayFocusSeconds(0);
    }
    state = state.copyWith(todayFocusSeconds: _storage.todayFocusSeconds);
  }

  void startFocus() {
    final totalSec = _storage.focusDuration * 60;
    _focusingAccumulated = 0;
    _phaseAccumulated = 0;
    _phaseStartedAt = DateTime.now();
    _baseTodayFocusSeconds = _storage.todayFocusSeconds;
    _scheduleNextBell();

    _audio.requestWakeLock();

    state = state.copyWith(
      phase: TimerPhase.focusing,
      elapsedSeconds: 0,
      totalSeconds: totalSec,
      nextBellInSeconds: _nextBellAt!.difference(DateTime.now()).inSeconds,
      microRestCount: 0,
    );

    _startTicker();
  }

  void pause() {
    final currentPhase = state.phase;
    final elapsed = _currentPhaseElapsed;

    if (currentPhase == TimerPhase.focusing) {
      _focusingAccumulated += elapsed;
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
    }

    state = state.copyWith(phase: target, pausedFromPhase: () => null);
    _startTicker();
  }

  void stop() {
    _ticker?.cancel();
    _audio.stopAll();
    _audio.releaseWakeLock();

    if (state.phase == TimerPhase.focusing ||
        state.pausedFromPhase == TimerPhase.focusing) {
      _saveFocusTime();
    }
    state = FocusTimerState(todayFocusSeconds: _storage.todayFocusSeconds);
  }

  void skipBreak() {
    _ticker?.cancel();
    _audio.stopAll();
    _audio.releaseWakeLock();
    state = FocusTimerState(todayFocusSeconds: _storage.todayFocusSeconds);
  }

  void extendBreak() {
    state = state.copyWith(totalSeconds: state.totalSeconds + 300);
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
      default:
        break;
    }
  }

  void _tickFocusing() {
    final phaseElapsed = _currentPhaseElapsed;
    final totalFocusing = _focusingAccumulated + phaseElapsed;
    final totalSec = _storage.focusDuration * 60;

    final newTodaySeconds = _baseTodayFocusSeconds + totalFocusing;
    _storage.setTodayFocusSeconds(newTodaySeconds);

    if (totalFocusing >= totalSec) {
      _ticker?.cancel();
      _focusingAccumulated = totalFocusing;
      _saveFocusTime();
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
      totalSeconds: totalSec,
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
      _audio.stopAll();
      _audio.releaseWakeLock();
      _playAlertSound();
      state = FocusTimerState(todayFocusSeconds: state.todayFocusSeconds);
      return;
    }
    state = state.copyWith(elapsedSeconds: elapsed);
  }

  void _enterMicroRest() {
    final microSec = _storage.microRestSeconds;
    _phaseStartedAt = DateTime.now();
    _phaseAccumulated = 0;

    state = state.copyWith(
      phase: TimerPhase.microRest,
      elapsedSeconds: 0,
      totalSeconds: microSec,
      microRestCount: state.microRestCount + 1,
    );
  }

  void _resumeFromMicroRest() {
    _phaseStartedAt = DateTime.now();
    _phaseAccumulated = 0;
    _scheduleNextBell();
    final focusTotalSec = _storage.focusDuration * 60;

    state = state.copyWith(
      phase: TimerPhase.focusing,
      elapsedSeconds: _focusingAccumulated,
      totalSeconds: focusTotalSec,
      nextBellInSeconds: _nextBellAt!.difference(DateTime.now()).inSeconds,
    );
  }

  void _startLongBreak() {
    final breakSec = _storage.breakDuration * 60;
    _storage.setCompletedSessions(_storage.completedSessions + 1);
    _phaseStartedAt = DateTime.now();
    _phaseAccumulated = 0;

    state = state.copyWith(
      phase: TimerPhase.longBreak,
      elapsedSeconds: 0,
      totalSeconds: breakSec,
      todayFocusSeconds: state.todayFocusSeconds,
    );
    _startTicker();
  }

  void _scheduleNextBell() {
    final minSec = _storage.minInterval * 60;
    final maxSec = _storage.maxInterval * 60;
    final delay = minSec + _random.nextInt(maxSec - minSec + 1);
    _nextBellAt = DateTime.now().add(Duration(seconds: delay));
  }

  void _playAlertSound() {
    final sounds = builtInSounds;
    if (sounds.isEmpty) return;

    if (_storage.randomSoundMode) {
      final sound = sounds[_random.nextInt(sounds.length)];
      _audio.playBuiltInSound(sound, volume: _storage.alertVolume);
    } else {
      final sound = sounds.firstWhere(
        (s) => s.id == _storage.selectedSoundId,
        orElse: () => sounds.first,
      );
      _audio.playBuiltInSound(sound, volume: _storage.alertVolume);
    }
  }

  void _saveFocusTime() {
    _storage.setTotalFocusSeconds(
      _storage.totalFocusSeconds + _focusingAccumulated,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _audio.releaseWakeLock();
    super.dispose();
  }
}
