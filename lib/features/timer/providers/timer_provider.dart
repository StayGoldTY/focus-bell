import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/sound_data.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/storage_service.dart';
import '../models/timer_state.dart';

final timerProvider =
    StateNotifierProvider<TimerNotifier, FocusTimerState>((ref) {
  return TimerNotifier(ref);
});

class TimerNotifier extends StateNotifier<FocusTimerState> {
  final Ref _ref;
  Timer? _ticker;
  final _random = Random();
  int _nextBellTarget = 0;
  int _focusingElapsed = 0;

  TimerNotifier(this._ref) : super(const FocusTimerState()) {
    _loadTodayStats();
  }

  StorageService get _storage => _ref.read(storageServiceProvider);
  AudioService get _audio => _ref.read(audioServiceProvider);

  void _loadTodayStats() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_storage.todayDate != today) {
      _storage.setTodayDate(today);
      _storage.setTodayFocusSeconds(0);
    }
    state = state.copyWith(todayFocusSeconds: _storage.todayFocusSeconds);
  }

  /// 开始专注
  void startFocus() {
    final totalSec = _storage.focusDuration * 60;
    _focusingElapsed = 0;
    _scheduleNextBell();

    state = state.copyWith(
      phase: TimerPhase.focusing,
      elapsedSeconds: 0,
      totalSeconds: totalSec,
      nextBellInSeconds: _nextBellTarget,
      microRestCount: 0,
    );

    _startTicker();
  }

  /// 暂停
  void pause() {
    _ticker?.cancel();
    state = state.copyWith(
      phase: TimerPhase.paused,
      pausedFromPhase: () => state.phase,
    );
  }

  /// 恢复
  void resume() {
    final target = state.pausedFromPhase ?? TimerPhase.focusing;
    state = state.copyWith(
      phase: target,
      pausedFromPhase: () => null,
    );
    _startTicker();
  }

  /// 停止并重置
  void stop() {
    _ticker?.cancel();
    _audio.stopAll();
    _saveFocusTime();
    state = FocusTimerState(todayFocusSeconds: _storage.todayFocusSeconds);
  }

  /// 跳过大休息
  void skipBreak() {
    _ticker?.cancel();
    _audio.stopAll();
    state = FocusTimerState(todayFocusSeconds: _storage.todayFocusSeconds);
  }

  /// 延长休息 5 分钟
  void extendBreak() {
    state = state.copyWith(
      totalSeconds: state.totalSeconds + 300,
    );
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
    _focusingElapsed++;
    final newElapsed = state.elapsedSeconds + 1;
    final newBellIn = state.nextBellInSeconds - 1;

    // 更新今日统计
    final newTodaySeconds = state.todayFocusSeconds + 1;
    _storage.setTodayFocusSeconds(newTodaySeconds);

    // 专注时间结束 -> 进入大休息
    if (newElapsed >= state.totalSeconds) {
      _ticker?.cancel();
      _saveFocusTime();
      _startLongBreak();
      return;
    }

    // 该响铃了 -> 进入微休息
    if (newBellIn <= 0) {
      _playAlertSound();
      _enterMicroRest();
      return;
    }

    state = state.copyWith(
      elapsedSeconds: newElapsed,
      nextBellInSeconds: newBellIn,
      todayFocusSeconds: newTodaySeconds,
    );
  }

  void _tickMicroRest() {
    final newElapsed = state.elapsedSeconds + 1;
    if (newElapsed >= state.totalSeconds) {
      _resumeFromMicroRest();
      return;
    }
    state = state.copyWith(elapsedSeconds: newElapsed);
  }

  void _tickLongBreak() {
    final newElapsed = state.elapsedSeconds + 1;
    if (newElapsed >= state.totalSeconds) {
      _ticker?.cancel();
      _audio.stopAll();
      _playAlertSound();
      state = FocusTimerState(todayFocusSeconds: state.todayFocusSeconds);
      return;
    }
    state = state.copyWith(elapsedSeconds: newElapsed);
  }

  void _enterMicroRest() {
    final microSec = _storage.microRestSeconds;
    state = state.copyWith(
      phase: TimerPhase.microRest,
      elapsedSeconds: 0,
      totalSeconds: microSec,
      microRestCount: state.microRestCount + 1,
    );
  }

  void _resumeFromMicroRest() {
    _scheduleNextBell();
    final focusTotalSec = _storage.focusDuration * 60;

    state = state.copyWith(
      phase: TimerPhase.focusing,
      elapsedSeconds: _focusingElapsed,
      totalSeconds: focusTotalSec,
      nextBellInSeconds: _nextBellTarget,
    );
  }

  void _startLongBreak() {
    final breakSec = _storage.breakDuration * 60;
    _storage.setCompletedSessions(_storage.completedSessions + 1);

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
    _nextBellTarget = minSec + _random.nextInt(maxSec - minSec + 1);
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
      _storage.totalFocusSeconds + _focusingElapsed,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
