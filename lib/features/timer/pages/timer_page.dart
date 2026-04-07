import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timer_state.dart';
import '../providers/timer_provider.dart';
import '../widgets/circular_timer.dart';

class TimerPage extends ConsumerWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // 标题
            Text(
              'FocusBell',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '基于神经科学的专注训练',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const Spacer(),

            // 环形计时器
            _buildTimer(timerState, theme),

            const SizedBox(height: 32),

            // 状态信息
            _buildStatusInfo(timerState, theme),

            const Spacer(),

            // 操作按钮
            _buildControls(context, ref, timerState, theme),

            const SizedBox(height: 16),

            // 今日统计
            _buildTodayStats(timerState, theme),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer(FocusTimerState timerState, ThemeData theme) {
    final isActive = timerState.phase != TimerPhase.idle;
    return CircularTimer(
      progress: isActive ? timerState.progress : 0,
      timeText: isActive ? timerState.remainingFormatted : '00:00',
      label: timerState.phaseLabel,
      subtitle: timerState.phase == TimerPhase.focusing
          ? '下次铃声 ~${_formatSeconds(timerState.nextBellInSeconds)}'
          : null,
    );
  }

  Widget _buildStatusInfo(FocusTimerState timerState, ThemeData theme) {
    if (timerState.phase == TimerPhase.idle) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          '每 3~5 分钟随机提示音 → 闭眼休息 10 秒\n专注 90 分钟后 → 深度休息 20 分钟',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      );
    }

    if (timerState.phase == TimerPhase.focusing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '已完成 ${timerState.microRestCount} 次微休息',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildControls(
    BuildContext context,
    WidgetRef ref,
    FocusTimerState timerState,
    ThemeData theme,
  ) {
    final notifier = ref.read(timerProvider.notifier);

    switch (timerState.phase) {
      case TimerPhase.idle:
        return FilledButton.icon(
          onPressed: notifier.startFocus,
          icon: const Icon(Icons.play_arrow_rounded, size: 28),
          label: const Text('开始专注', style: TextStyle(fontSize: 18)),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          ),
        );

      case TimerPhase.focusing:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: notifier.stop,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('结束'),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: notifier.pause,
              icon: const Icon(Icons.pause_rounded),
              label: const Text('暂停'),
            ),
          ],
        );

      case TimerPhase.paused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: notifier.stop,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('结束'),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: notifier.resume,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('继续'),
            ),
          ],
        );

      case TimerPhase.longBreak:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: notifier.skipBreak,
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('跳过'),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: notifier.extendBreak,
              icon: const Icon(Icons.add_rounded),
              label: const Text('+5 分钟'),
            ),
          ],
        );

      case TimerPhase.microRest:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTodayStats(FocusTimerState timerState, ThemeData theme) {
    final hours = timerState.todayFocusSeconds ~/ 3600;
    final minutes = (timerState.todayFocusSeconds % 3600) ~/ 60;
    final display = hours > 0 ? '${hours}h ${minutes}min' : '${minutes}min';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '今日已专注: $display',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  String _formatSeconds(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
