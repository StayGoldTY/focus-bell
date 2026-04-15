import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/sound_data.dart';
import '../../../core/models/focus_task_category.dart';
import '../../../shared/services/storage_service.dart';
import '../models/focus_session_draft.dart';
import '../models/timer_state.dart';
import '../providers/focus_session_draft_provider.dart';
import '../providers/timer_provider.dart';
import '../widgets/circular_timer.dart';

class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({super.key});

  @override
  ConsumerState<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage> {
  static const _contentMaxWidth = 360.0;
  late final TextEditingController _taskController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(focusSessionDraftProvider);
    _taskController = TextEditingController(text: draft.title);
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FocusSessionDraft>(focusSessionDraftProvider, (previous, next) {
      if (_taskController.text == next.title) {
        return;
      }

      _taskController.value = TextEditingValue(
        text: next.title,
        selection: TextSelection.collapsed(offset: next.title.length),
      );
    });

    final timerState = ref.watch(timerProvider);
    final draft = ref.watch(focusSessionDraftProvider);
    final theme = Theme.of(context);
    final storage = ref.read(storageServiceProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth > 420 ? 24.0 : 20.0;
          final verticalPadding = constraints.maxHeight > 700 ? 28.0 : 20.0;
          final contentWidth = (constraints.maxWidth - horizontalPadding * 2)
              .clamp(0.0, _contentMaxWidth);
          final minHeight = (constraints.maxHeight - verticalPadding * 2).clamp(
            0.0,
            double.infinity,
          );

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                    const SizedBox(height: 24),
                    Text(
                      'FocusBell',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '基于神经节律的专注训练',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (timerState.phase == TimerPhase.idle) ...[
                      _buildTaskComposer(draft, theme),
                      const SizedBox(height: 20),
                    ],
                    _buildTimer(timerState),
                    const SizedBox(height: 28),
                    _buildStatusInfo(timerState, theme),
                    const SizedBox(height: 16),
                    _buildSessionOverview(timerState, storage, draft, theme),
                    const SizedBox(height: 20),
                    _buildControls(ref, timerState),
                    const SizedBox(height: 16),
                    _buildDailyGoalCard(timerState, storage, theme),
                    const SizedBox(height: 24),
                  ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskComposer(FocusSessionDraft draft, ThemeData theme) {
    final draftNotifier = ref.read(focusSessionDraftProvider.notifier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '本轮任务',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _taskController,
            maxLength: 40,
            decoration: const InputDecoration(
              hintText: '可选，比如：整理需求文档 / 刷 2 套题 / 改这个 bug',
              counterText: '',
            ),
            onChanged: draftNotifier.setTitle,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('不分类'),
                selected: draft.categoryId == null,
                onSelected: (_) => draftNotifier.setCategory(null),
              ),
              ...focusTaskCategories.map((category) {
                return ChoiceChip(
                  label: Text(category.label),
                  selected: draft.categoryId == category.id,
                  onSelected: (selected) {
                    draftNotifier.setCategory(selected ? category.id : null);
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            draft.normalizedTitle == null
                ? '这项是可选的，不填也可以直接开始专注。'
                : '当前任务：${draft.normalizedTitle}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer(FocusTimerState timerState) {
    final isActive = timerState.phase != TimerPhase.idle;
    return Align(
      alignment: Alignment.center,
      child: CircularTimer(
        progress: isActive ? timerState.progress : 0,
        timeText: isActive ? timerState.remainingFormatted : '00:00',
        label: timerState.phaseLabel,
        subtitle: timerState.phase == TimerPhase.focusing
            ? '下次提醒 ~ ${_formatSeconds(timerState.nextBellInSeconds)}'
            : null,
      ),
    );
  }

  Widget _buildStatusInfo(FocusTimerState timerState, ThemeData theme) {
    if (timerState.phase == TimerPhase.idle) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            '每隔几分钟随机响一次提示音，提醒你闭眼微休息 10 秒；完整专注结束后再进入深度休息。',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ),
      );
    }

    if (timerState.phase == TimerPhase.focusing) {
      return Align(
        alignment: Alignment.center,
        child: Container(
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
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSessionOverview(
    FocusTimerState timerState,
    StorageService storage,
    FocusSessionDraft draft,
    ThemeData theme,
  ) {
    final preset = findFocusPresetById(storage.selectedFocusPresetId);
    final activeSound = timerState.activeFocusSoundId != null
        ? findFocusSoundscapeById(timerState.activeFocusSoundId!)
        : null;
    final configuredSound = findFocusSoundscapeById(
      storage.selectedFocusSoundId,
    );
    final category = findFocusTaskCategoryById(draft.categoryId);

    final presetLabel = preset?.name ?? '自定义方案';
    final soundLabel = !storage.focusSoundEnabled
        ? '关闭'
        : activeSound?.name ??
              (storage.randomFocusSoundMode
                  ? '随机专注背景音'
                  : (configuredSound?.name ?? '已开启'));

    final summaryItems = [
      _OverviewChip(
        label: '预设',
        value: presetLabel,
        icon: Icons.auto_awesome_rounded,
      ),
      _OverviewChip(
        label: '专注 / 休息',
        value: '${storage.focusDuration}/${storage.breakDuration} 分钟',
        icon: Icons.timelapse_rounded,
      ),
      _OverviewChip(
        label: '微休息',
        value: '${storage.microRestSeconds} 秒',
        icon: Icons.self_improvement_rounded,
      ),
      _OverviewChip(
        label: '提醒间隔',
        value: '${storage.minInterval}-${storage.maxInterval} 分钟',
        icon: Icons.notifications_active_rounded,
      ),
      _OverviewChip(
        label: '背景音',
        value: soundLabel,
        icon: Icons.headphones_rounded,
      ),
      _OverviewChip(
        label: '每日目标',
        value: '${storage.dailyGoalMinutes} 分钟',
        icon: Icons.flag_circle_rounded,
      ),
      if (draft.normalizedTitle != null)
        _OverviewChip(
          label: '任务',
          value: draft.normalizedTitle!,
          icon: Icons.task_alt_rounded,
        ),
      if (category != null)
        _OverviewChip(
          label: '分类',
          value: category.label,
          icon: Icons.sell_rounded,
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                timerState.phase == TimerPhase.idle
                    ? Icons.tune_rounded
                    : Icons.play_circle_outline_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                timerState.phase == TimerPhase.idle ? '开始前概览' : '本轮专注设置',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: summaryItems.map((item) {
              return _buildOverviewChip(item, theme);
            }).toList(),
          ),
          if (preset != null) ...[
            const SizedBox(height: 12),
            Text(
              '${preset.emoji} ${preset.description}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControls(WidgetRef ref, FocusTimerState timerState) {
    final notifier = ref.read(timerProvider.notifier);

    switch (timerState.phase) {
      case TimerPhase.idle:
        return Align(
          alignment: Alignment.center,
          child: FilledButton.icon(
            onPressed: notifier.startFocus,
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: const Text('开始专注', style: TextStyle(fontSize: 18)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
          ),
        );
      case TimerPhase.focusing:
        return Align(
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
          ),
        );
      case TimerPhase.paused:
        return Align(
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
          ),
        );
      case TimerPhase.longBreak:
        return Align(
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
          ),
        );
      case TimerPhase.microRest:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDailyGoalCard(
    FocusTimerState timerState,
    StorageService storage,
    ThemeData theme,
  ) {
    final todaySeconds = timerState.todayFocusSeconds;
    final goalSeconds = storage.dailyGoalMinutes * 60;
    final progress = goalSeconds > 0
        ? (todaySeconds / goalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final todayText = _formatDurationCompact(todaySeconds);
    final goalText = '${storage.dailyGoalMinutes} 分钟';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '已专注 $todayText / 目标 $goalText',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
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
          Flexible(
            child: Text(
              '${item.label} · ${item.value}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
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
