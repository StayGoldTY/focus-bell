enum TimerPhase {
  idle,
  focusing,
  microRest,
  longBreak,
  paused,
}

class FocusTimerState {
  final TimerPhase phase;

  /// 当前阶段已经过的秒数
  final int elapsedSeconds;

  /// 当前阶段的总时长（秒）
  final int totalSeconds;

  /// 距离下次铃声的剩余秒数
  final int nextBellInSeconds;

  /// 本轮已完成的微休息次数
  final int microRestCount;

  /// 今日已专注总秒数
  final int todayFocusSeconds;

  /// 本轮实际激活的专注背景音 ID
  final String? activeFocusSoundId;

  /// 暂停前的阶段
  final TimerPhase? pausedFromPhase;

  const FocusTimerState({
    this.phase = TimerPhase.idle,
    this.elapsedSeconds = 0,
    this.totalSeconds = 0,
    this.nextBellInSeconds = 0,
    this.microRestCount = 0,
    this.todayFocusSeconds = 0,
    this.activeFocusSoundId,
    this.pausedFromPhase,
  });

  int get remainingSeconds => totalSeconds - elapsedSeconds;

  double get progress =>
      totalSeconds > 0 ? elapsedSeconds / totalSeconds : 0.0;

  String get remainingFormatted {
    final remaining = remainingSeconds;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get phaseLabel {
    switch (phase) {
      case TimerPhase.idle:
        return '准备开始';
      case TimerPhase.focusing:
        return '专注中';
      case TimerPhase.microRest:
        return '闭眼休息';
      case TimerPhase.longBreak:
        return '深度休息';
      case TimerPhase.paused:
        return '已暂停';
    }
  }

  FocusTimerState copyWith({
    TimerPhase? phase,
    int? elapsedSeconds,
    int? totalSeconds,
    int? nextBellInSeconds,
    int? microRestCount,
    int? todayFocusSeconds,
    String? Function()? activeFocusSoundId,
    TimerPhase? Function()? pausedFromPhase,
  }) {
    return FocusTimerState(
      phase: phase ?? this.phase,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      nextBellInSeconds: nextBellInSeconds ?? this.nextBellInSeconds,
      microRestCount: microRestCount ?? this.microRestCount,
      todayFocusSeconds: todayFocusSeconds ?? this.todayFocusSeconds,
      activeFocusSoundId: activeFocusSoundId != null
          ? activeFocusSoundId()
          : this.activeFocusSoundId,
      pausedFromPhase: pausedFromPhase != null ? pausedFromPhase() : this.pausedFromPhase,
    );
  }
}
