import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/sound_data.dart';
import '../../../core/models/focus_task_category.dart';
import '../../../core/utils/duration_format.dart';
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
  static const _quickDurations = [25, 45, 90];

  late final TextEditingController _titleController;
  late final FocusNode _titleFocusNode;
  bool _stopDialogOpen = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(focusSessionDraftProvider);
    _titleController = TextEditingController(text: draft.title);
    _titleFocusNode = FocusNode();
    _titleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    ref
        .read(focusSessionDraftProvider.notifier)
        .setTitle(_titleController.text);
  }

  bool get _isTyping => _titleFocusNode.hasFocus;

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final draft = ref.watch(focusSessionDraftProvider);
    final storage = ref.read(storageServiceProvider);
    final theme = Theme.of(context);

    ref.listen<FocusSessionDraft>(focusSessionDraftProvider, (previous, next) {
      if (next.title != _titleController.text) {
        _titleController.value = TextEditingValue(
          text: next.title,
          selection: TextSelection.collapsed(offset: next.title.length),
        );
      }
    });

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () {
          if (_isTyping) {
            return;
          }
          _handleSpaceShortcut(timerState);
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_isTyping) {
            _titleFocusNode.unfocus();
            return;
          }
          if (timerState.isTimedSession) {
            unawaited(_confirmStop());
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final compactLayout = constraints.maxHeight < 720;
              final denseLayout = constraints.maxHeight < 620;
              final horizontalPadding = constraints.maxWidth > 420
                  ? 24.0
                  : 20.0;
              final verticalPadding = denseLayout
                  ? 10.0
                  : compactLayout
                  ? 14.0
                  : 20.0;
              final contentWidth =
                  (constraints.maxWidth - horizontalPadding * 2).clamp(
                    0.0,
                    _contentMaxWidth,
                  );
              final timerBaseSize = denseLayout
                  ? 156.0
                  : compactLayout
                  ? 184.0
                  : 216.0;
              return SafeArea(
                bottom: false,
                child: Center(
                  child: SizedBox(
                    width: contentWidth + horizontalPadding * 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              verticalPadding,
                              horizontalPadding,
                              8,
                            ),
                            child: SizedBox(
                              width: contentWidth,
                              child: Column(
                                children: [
                                  _buildHeader(timerState, storage, theme),
                                  SizedBox(height: denseLayout ? 10 : 14),
                                  _buildTimer(
                                    timerState,
                                    storage,
                                    timerSize: timerBaseSize,
                                  ),
                                  SizedBox(height: denseLayout ? 10 : 12),
                                  _buildStatusInfo(
                                    timerState,
                                    draft,
                                    theme,
                                    compactLayout: compactLayout,
                                  ),
                                  if (timerState.isIdle) ...[
                                    SizedBox(height: denseLayout ? 10 : 12),
                                    _buildQuickDurations(storage, theme),
                                  ],
                                  SizedBox(height: denseLayout ? 12 : 14),
                                  _buildControls(
                                    timerState,
                                    denseLayout: denseLayout,
                                  ),
                                  if (kIsWeb && timerState.isIdle) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '空格开始 / 暂停 · Esc 结束',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (timerState.isIdle) ...[
                                    SizedBox(height: denseLayout ? 12 : 16),
                                    _buildIntentionCard(
                                      draft,
                                      theme,
                                      denseLayout: denseLayout,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            4,
                            horizontalPadding,
                            denseLayout ? 8 : 12,
                          ),
                          child: SizedBox(
                            width: contentWidth,
                            child: _buildTodayProgress(
                              timerState,
                              storage,
                              theme,
                              denseLayout: denseLayout,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    FocusTimerState timerState,
    StorageService storage,
    ThemeData theme,
  ) {
    final streak = storage.getEffectiveCurrentStreak();

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
            ),
          ),
          child: Icon(
            Icons.notifications_active_rounded,
            color: theme.colorScheme.onPrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FocusBell',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                timerState.isIdle ? '给这段时间一个清晰边界' : timerState.phaseLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (streak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$streak 天连续',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimer(
    FocusTimerState timerState,
    StorageService storage, {
    required double timerSize,
  }) {
    final isActive = !timerState.isIdle;
    return CircularTimer(
      progress: isActive ? timerState.progress : 0,
      timeText: isActive
          ? timerState.remainingFormatted
          : formatClock(storage.focusDuration * 60),
      label: timerState.phaseLabel,
      subtitle: timerState.phase == TimerPhase.focusing
          ? '下次提醒 ${formatClock(timerState.nextBellInSeconds)}'
          : timerState.isIdle
          ? '随机铃声 · 闭眼微休息 ${storage.microRestSeconds} 秒'
          : null,
      size: timerSize,
      pulse: timerState.isIdle,
    );
  }

  Widget _buildStatusInfo(
    FocusTimerState timerState,
    FocusSessionDraft draft,
    ThemeData theme, {
    required bool compactLayout,
  }) {
    if (timerState.phase == TimerPhase.focusing) {
      final title = draft.normalizedTitle;
      return Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compactLayout ? 14 : 18,
              vertical: compactLayout ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              title == null
                  ? '已完成 ${timerState.microRestCount} 次微休息'
                  : '$title · ${timerState.microRestCount} 次微休息',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '建议开启系统勿扰，让铃声成为唯一提醒',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    if (timerState.phase == TimerPhase.paused) {
      return Text(
        '当前已暂停，随时继续。',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildIntentionCard(
    FocusSessionDraft draft,
    ThemeData theme, {
    required bool denseLayout,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(denseLayout ? 12 : 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '这一轮打算做什么？',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            maxLength: 40,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: '例如：写周报、刷算法、读论文',
              counterText: '',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in focusTaskCategories)
                ChoiceChip(
                  avatar: Icon(category.icon, size: 16),
                  label: Text(category.label),
                  selected: draft.categoryId == category.id,
                  onSelected: (selected) {
                    ref
                        .read(focusSessionDraftProvider.notifier)
                        .setCategory(selected ? category.id : null);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDurations(StorageService storage, ThemeData theme) {
    final isCustom = storage.selectedFocusPresetId == customFocusPresetId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快速时长',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var index = 0; index < _quickDurations.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(
                child: _DurationChip(
                  minutes: _quickDurations[index],
                  selected: storage.focusDuration == _quickDurations[index],
                  onTap: () async {
                    await storage.setFocusDuration(_quickDurations[index]);
                    if (storage.selectedFocusPresetId != customFocusPresetId) {
                      await storage.markFocusPresetCustom();
                    }
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
              ),
            ],
          ],
        ),
        if (isCustom) ...[
          const SizedBox(height: 8),
          Text(
            '已改为自定义时长，也可在设置里改回方案。',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildControls(
    FocusTimerState timerState, {
    required bool denseLayout,
  }) {
    final notifier = ref.read(timerProvider.notifier);
    final horizontalPadding = denseLayout ? 22.0 : 28.0;
    final verticalPadding = denseLayout ? 12.0 : 14.0;

    switch (timerState.phase) {
      case TimerPhase.idle:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: notifier.startFocus,
            icon: const Icon(Icons.play_arrow_rounded, size: 26),
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
                onPressed: () => unawaited(_confirmStop()),
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
                onPressed: () => unawaited(_confirmStop()),
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
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
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
                '${formatDurationCompact(todaySeconds)} / ${storage.dailyGoalMinutes}min',
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
              value: todaySeconds < 60 ? 0 : progress,
              minHeight: denseLayout ? 7 : 9,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSpaceShortcut(FocusTimerState timerState) {
    final notifier = ref.read(timerProvider.notifier);
    switch (timerState.phase) {
      case TimerPhase.idle:
        notifier.startFocus();
        break;
      case TimerPhase.focusing:
        notifier.pause();
        break;
      case TimerPhase.paused:
        notifier.resume();
        break;
      case TimerPhase.microRest:
      case TimerPhase.longBreak:
        break;
    }
  }

  Future<void> _confirmStop() async {
    if (_stopDialogOpen) {
      return;
    }
    _stopDialogOpen = true;
    ref.read(sessionEndPromptOpenProvider.notifier).state = true;
    final shouldStop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('结束本次专注？'),
          content: const Text('满 1 分钟的进度会记入统计。不到 1 分钟的尝试不会留下记录。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('继续专注'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认结束'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      ref
          .read(timerProvider.notifier)
          .onSessionEndPromptResolved(confirmedStop: shouldStop == true);
      return;
    }
    _stopDialogOpen = false;
    ref
        .read(timerProvider.notifier)
        .onSessionEndPromptResolved(confirmedStop: shouldStop == true);
  }
}

class _DurationChip extends StatelessWidget {
  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary
          : theme.colorScheme.surface.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                '$minutes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '分钟',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.84)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
