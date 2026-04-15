import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/sound_data.dart';
import '../../../shared/services/storage_service.dart';
import '../models/timer_state.dart';
import '../providers/timer_provider.dart';
import '../widgets/circular_timer.dart';

class TimerPage extends ConsumerWidget {
  const TimerPage({super.key});

  static const _contentMaxWidth = 360.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final storage = ref.read(storageServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compactLayout = constraints.maxHeight < 620;
          final denseLayout = constraints.maxHeight < 540;
          final horizontalPadding = constraints.maxWidth > 420 ? 24.0 : 20.0;
          final verticalPadding = denseLayout
              ? 12.0
              : compactLayout
              ? 16.0
              : 24.0;
          final contentWidth = (constraints.maxWidth - horizontalPadding * 2)
              .clamp(0.0, _contentMaxWidth);
          final sectionSpacing = denseLayout ? 10.0 : 16.0;
          final timerBaseSize = denseLayout
              ? 184.0
              : compactLayout
              ? 216.0
              : 272.0;

          return SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      Text(
                        'FocusBell',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '基于神经节律的专注训练',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: sectionSpacing),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, timerConstraints) {
                            final timerSize = math.min(
                              timerBaseSize,
                              math.min(
                                timerConstraints.maxWidth,
                                timerConstraints.maxHeight.isFinite
                                    ? timerConstraints.maxHeight
                                    : timerBaseSize,
                              ),
                            );

                            return Center(
                              child: _buildTimer(
                                timerState,
                                timerSize: timerSize,
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: sectionSpacing),
                      _buildStatusInfo(
                        timerState,
                        theme,
                        compactLayout: compactLayout,
                      ),
                      SizedBox(height: denseLayout ? 10 : 12),
                      _buildSessionOverview(
                        timerState,
                        storage,
                        theme,
                        compactLayout: compactLayout,
                      ),
                      SizedBox(height: sectionSpacing),
                      _buildControls(ref, timerState, denseLayout: denseLayout),
                      SizedBox(height: sectionSpacing),
                      _buildTodayProgress(
                        timerState,
                        storage,
                        theme,
                        denseLayout: denseLayout,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimer(FocusTimerState timerState, {required double timerSize}) {
    final isActive = timerState.phase != TimerPhase.idle;
    return CircularTimer(
      progress: isActive ? timerState.progress : 0,
      timeText: isActive ? timerState.remainingFormatted : '00:00',
      label: timerState.phaseLabel,
      subtitle: timerState.phase == TimerPhase.focusing
          ? '下次提醒 ${_formatSeconds(timerState.nextBellInSeconds)}'
          : null,
      size: timerSize,
    );
  }

  Widget _buildStatusInfo(
    FocusTimerState timerState,
    ThemeData theme, {
    required bool compactLayout,
  }) {
    if (timerState.phase == TimerPhase.idle) {
      return Text(
        compactLayout
            ? '随机提示音会提醒你闭眼微休息 10 秒。'
            : '随机提示音会提醒你闭眼微休息 10 秒，完整专注结束后再进入深度休息。',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      );
    }

    if (timerState.phase == TimerPhase.focusing) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compactLayout ? 14 : 18,
          vertical: compactLayout ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '已完成 ${timerState.microRestCount} 次微休息',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Text(
      timerState.phase == TimerPhase.paused ? '当前已暂停，随时继续。' : '正在进行深度休息。',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildSessionOverview(
    FocusTimerState timerState,
    StorageService storage,
    ThemeData theme, {
    required bool compactLayout,
  }) {
    final preset = findFocusPresetById(storage.selectedFocusPresetId);
    final activeSound = timerState.activeFocusSoundId != null
        ? findFocusSoundscapeById(timerState.activeFocusSoundId!)
        : null;
    final configuredSound = findFocusSoundscapeById(
      storage.selectedFocusSoundId,
    );

    final summaryItems = <_OverviewChip>[
      _OverviewChip(
        label: '模式',
        value: preset?.name ?? '自定义',
        icon: Icons.auto_awesome_rounded,
      ),
      _OverviewChip(
        label: '节奏',
        value: '${storage.focusDuration}/${storage.breakDuration} 分钟',
        icon: Icons.timelapse_rounded,
      ),
      _OverviewChip(
        label: '提醒',
        value: '${storage.minInterval}-${storage.maxInterval} 分钟',
        icon: Icons.notifications_active_rounded,
      ),
      if (!compactLayout || timerState.phase != TimerPhase.idle)
        _OverviewChip(
          label: '背景音',
          value: !storage.focusSoundEnabled
              ? '关闭'
              : activeSound?.name ??
                    (storage.randomFocusSoundMode
                        ? '随机'
                        : (configuredSound?.name ?? '开启')),
          icon: Icons.headphones_rounded,
        ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compactLayout ? 12 : 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: summaryItems
            .map((item) => _buildOverviewChip(item, theme))
            .toList(),
      ),
    );
  }

  Widget _buildControls(
    WidgetRef ref,
    FocusTimerState timerState, {
    required bool denseLayout,
  }) {
    final notifier = ref.read(timerProvider.notifier);
    final horizontalPadding = denseLayout ? 22.0 : 32.0;
    final verticalPadding = denseLayout ? 12.0 : 14.0;

    switch (timerState.phase) {
      case TimerPhase.idle:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: notifier.startFocus,
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: Text(
              '开始专注',
              style: TextStyle(fontSize: denseLayout ? 16 : 18),
            ),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
            ),
          ),
        );
      case TimerPhase.focusing:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: notifier.stop,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('结束'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: notifier.pause,
                icon: const Icon(Icons.pause_rounded),
                label: const Text('暂停'),
              ),
            ),
          ],
        );
      case TimerPhase.paused:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: notifier.stop,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('结束'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: notifier.resume,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('继续'),
              ),
            ),
          ],
        );
      case TimerPhase.longBreak:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: notifier.skipBreak,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('跳过'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: notifier.extendBreak,
                icon: const Icon(Icons.add_rounded),
                label: const Text('+5 分钟'),
              ),
            ),
          ],
        );
      case TimerPhase.microRest:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTodayProgress(
    FocusTimerState timerState,
    StorageService storage,
    ThemeData theme, {
    required bool denseLayout,
  }) {
    final todaySeconds = timerState.todayFocusSeconds;
    final goalSeconds = storage.dailyGoalMinutes * 60;
    final progress = goalSeconds > 0
        ? (todaySeconds / goalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: denseLayout ? 12 : 14,
        vertical: denseLayout ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '今日进度',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${_formatDurationCompact(todaySeconds)} / ${storage.dailyGoalMinutes}min',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: denseLayout ? 6 : 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewChip(_OverviewChip item, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '${item.label} · ${item.value}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  String _formatDurationCompact(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}min';
  }
}

class _OverviewChip {
  final String label;
  final String value;
  final IconData icon;

  const _OverviewChip({
    required this.label,
    required this.value,
    required this.icon,
  });
}
