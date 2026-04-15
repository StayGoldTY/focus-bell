enum TimerPhase { idle, focusing, microRest, longBreak, paused }

class FocusTimerState {
  final TimerPhase phase;
  final int elapsedSeconds;
  final int totalSeconds;
  final int nextBellInSeconds;
  final int microRestCount;
  final int todayFocusSeconds;
  final String? activeFocusSoundId;
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

  double get progress => totalSeconds > 0 ? elapsedSeconds / totalSeconds : 0.0;

  String get remainingFormatted {
    final remaining = remainingSeconds.clamp(0, totalSeconds);
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
        return '闭眼微休息';
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
      pausedFromPhase: pausedFromPhase != null
          ? pausedFromPhase()
          : this.pausedFromPhase,
    );
  }
}
