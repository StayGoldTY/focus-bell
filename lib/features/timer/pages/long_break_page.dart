import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timer_state.dart';
import '../providers/timer_provider.dart';
import '../widgets/circular_timer.dart';

class LongBreakOverlay extends ConsumerWidget {
  const LongBreakOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    if (timerState.phase != TimerPhase.longBreak) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(timerProvider.notifier);
    final theme = Theme.of(context);

    return Material(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.surface,
              theme.colorScheme.tertiaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 1),

              // 标题
              Text(
                '深度休息',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 4,
                ),
              ).animate().fadeIn(duration: 800.ms),

              const SizedBox(height: 8),

              Text(
                'NSDR · 非睡眠深度休息',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

              const Spacer(flex: 1),

              // 计时器
              CircularTimer(
                progress: timerState.progress,
                timeText: timerState.remainingFormatted,
                label: '放松身心',
                size: 240,
              ).animate().scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),

              const Spacer(flex: 1),

              // 休息建议
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow
                        .withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.spa_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '学习后的深度休息可以提升记忆保持率高达 50%\n'
                        '试试闭上眼睛，放松身体每一个部位',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

              const Spacer(flex: 1),

              // 操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: notifier.skipBreak,
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('跳过休息'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: notifier.extendBreak,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('+5 分钟'),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
