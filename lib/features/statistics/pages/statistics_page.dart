import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/sound_data.dart';
import '../../../core/models/focus_session_record.dart';
import '../../../core/models/focus_task_category.dart';
import '../../../shared/services/storage_service.dart';
import '../../timer/providers/timer_provider.dart';

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  _SessionFilter _filter = _SessionFilter.all;

  @override
  Widget build(BuildContext context) {
    final storage = ref.read(storageServiceProvider);
    final timerState = ref.watch(timerProvider);
    final theme = Theme.of(context);

    final allRecords = storage.getSessionRecords();
    final liveTodaySeconds = math.max(
      timerState.todayFocusSeconds,
      storage.todayFocusSeconds,
    );
    final currentStreak = storage.getEffectiveCurrentStreak();
    final bestStreak = storage.bestStreak;
    final totalSeconds = storage.totalFocusSeconds;
    final sessions = storage.completedSessions;
    final todayMinutes = liveTodaySeconds ~/ 60;
    final dailyGoalMinutes = storage.dailyGoalMinutes;
    final dailyProgress = dailyGoalMinutes > 0
        ? (liveTodaySeconds / (dailyGoalMinutes * 60)).clamp(0.0, 1.0)
        : 0.0;
    final recentDaily = storage.getRecentDailyFocusSeconds();
    final todayKey = focusDateKey(DateTime.now());
    recentDaily[todayKey] = math.max(
      recentDaily[todayKey] ?? 0,
      liveTodaySeconds,
    );
    final filteredRecords = allRecords
        .where((record) {
          switch (_filter) {
            case _SessionFilter.all:
              return true;
            case _SessionFilter.completed:
              return record.status == FocusSessionStatus.completed;
            case _SessionFilter.stopped:
              return record.status == FocusSessionStatus.stopped;
          }
        })
        .take(20)
        .toList();
    final showLegacyNotice = allRecords.isEmpty && totalSeconds > 0;
    final totalHours = totalSeconds ~/ 3600;
    final totalMinutes = (totalSeconds % 3600) ~/ 60;
    final averageMinutes = sessions > 0
        ? (totalSeconds / sessions / 60).round()
        : 0;
    final todayVisits = storage.getTodayVisits();
    final totalVisits = storage.totalVisits;
    final recentDailyVisits = storage.getRecentDailyVisits();

    return Scaffold(
      appBar: AppBar(title: const Text('专注统计')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '你的专注数据',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.timer_rounded,
                  label: '今日专注',
                  value: '${todayMinutes}min',
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle_rounded,
                  label: '完成轮次',
                  value: '$sessions',
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.access_time_filled_rounded,
                  label: '总专注时长',
                  value: totalHours > 0
                      ? '${totalHours}h ${totalMinutes}m'
                      : '${totalMinutes}min',
                  color: const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up_rounded,
                  label: '平均每轮',
                  value: '${averageMinutes}min',
                  color: const Color(0xFF6A1B9A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  label: '当前连续',
                  value: '$currentStreak 天',
                  color: const Color(0xFFD84315),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.workspace_premium_rounded,
                  label: '最佳连续',
                  value: '$bestStreak 天',
                  color: const Color(0xFF00897B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DailyGoalProgressCard(
            progress: dailyProgress,
            todaySeconds: liveTodaySeconds,
            dailyGoalMinutes: dailyGoalMinutes,
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: '最近 7 天',
            subtitle: '按本地时间统计你的每日专注时长',
            child: _WeeklyTrendChart(data: recentDaily),
          ),
          if (showLegacyNotice) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '你之前的累计时长已经保留，但完整历史记录会从这个版本开始逐步积累。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _VisitStatsCard(
            todayVisits: todayVisits,
            totalVisits: totalVisits,
            recentDailyVisits: recentDailyVisits,
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: '最近专注记录',
            subtitle: '默认展示最近 20 条，可切换查看已完成或提前结束的会话',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip(_SessionFilter.all, '全部'),
                    _buildFilterChip(_SessionFilter.completed, '已完成'),
                    _buildFilterChip(_SessionFilter.stopped, '提前结束'),
                  ],
                ),
                const SizedBox(height: 16),
                if (filteredRecords.isEmpty)
                  _buildEmptyHistoryState(theme, totalSeconds)
                else
                  ...filteredRecords.map((record) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SessionRecordCard(record: record),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getEncouragement(totalSeconds),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(_SessionFilter value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) {
        setState(() {
          _filter = value;
        });
      },
    );
  }

  Widget _buildEmptyHistoryState(ThemeData theme, int totalSeconds) {
    final message = totalSeconds > 0
        ? '旧版累计统计还在，新的历史记录会从你下一次专注开始出现。'
        : '还没有历史记录，开始一次专注后这里会显示你的任务与时长。';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }

  String _getEncouragement(int totalSeconds) {
    final hours = totalSeconds / 3600;
    if (hours < 1) {
      return '万事开头难，坚持就是胜利。\n开始你的第一轮专注吧。';
    }
    if (hours < 5) {
      return '很好的开局。\n你已经积累了 ${hours.toStringAsFixed(1)} 小时的深度专注。';
    }
    if (hours < 20) {
      return '稳步提升中。\n你的大脑正在更擅长进入专注状态。';
    }
    if (hours < 50) {
      return '这个节奏很扎实。\n持续的深度专注正在重塑你的工作习惯。';
    }
    return '专注大师。\n你已经建立起非常稳定的长期专注能力。';
  }
}

enum _SessionFilter { all, completed, stopped }

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyGoalProgressCard extends StatelessWidget {
  final double progress;
  final int todaySeconds;
  final int dailyGoalMinutes;

  const _DailyGoalProgressCard({
    required this.progress,
    required this.todaySeconds,
    required this.dailyGoalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
                '今日目标完成度',
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
            '已完成 ${_formatDuration(todaySeconds)} / 目标 $dailyGoalMinutes 分钟',
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

  static String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}min';
  }
}

class _VisitStatsCard extends StatelessWidget {
  final int todayVisits;
  final int totalVisits;
  final Map<String, int> recentDailyVisits;

  const _VisitStatsCard({
    required this.todayVisits,
    required this.totalVisits,
    required this.recentDailyVisits,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      title: '访问统计',
      subtitle: '当前浏览器本地记录',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _VisitMetric(
                  icon: Icons.today_rounded,
                  label: '今日访问',
                  value: '$todayVisits',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VisitMetric(
                  icon: Icons.all_inclusive_rounded,
                  label: '累计访问',
                  value: '$totalVisits',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _VisitTrend(data: recentDailyVisits),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '近 7 天',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _VisitMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitTrend extends StatelessWidget {
  final Map<String, int> data;

  const _VisitTrend({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxValue = entries.fold<int>(
      1,
      (current, entry) => math.max(current, entry.value),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: entries.map((entry) {
        final ratio = entry.value / maxValue;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${entry.value}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 48 * ratio.clamp(0.12, 1.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _WeeklyTrendChart._formatDayLabel(entry.key),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _WeeklyTrendChart extends StatelessWidget {
  final Map<String, int> data;

  const _WeeklyTrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxValue = entries.fold<int>(
      1,
      (current, entry) => math.max(current, entry.value),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: entries.map((entry) {
        final ratio = entry.value / maxValue;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  entry.value > 0 ? _formatMinutes(entry.value) : '0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 120 * ratio.clamp(0.08, 1.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDayLabel(entry.key),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  static String _formatMinutes(int seconds) {
    return '${(seconds / 60).round()}m';
  }

  static String _formatDayLabel(String dayKey) {
    final date = DateTime.tryParse(dayKey);
    if (date == null) {
      return '--';
    }
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return weekdays[date.weekday - 1];
  }
}

class _SessionRecordCard extends StatelessWidget {
  final FocusSessionRecord record;

  const _SessionRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preset = findFocusPresetById(record.presetId);
    final sound = record.focusSoundId != null
        ? findFocusSoundscapeById(record.focusSoundId!)
        : null;
    final category = findFocusTaskCategoryById(record.taskCategoryId);
    final statusColor = record.status == FocusSessionStatus.completed
        ? const Color(0xFF2E7D32)
        : const Color(0xFFD84315);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.taskTitle ?? '未命名任务',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  record.status == FocusSessionStatus.completed
                      ? '已完成'
                      : '提前结束',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatDateTime(record.startedAt)} - ${_formatTime(record.endedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RecordChip(
                icon: Icons.timelapse_rounded,
                label: _formatDuration(record.actualFocusSeconds),
              ),
              _RecordChip(
                icon: Icons.self_improvement_rounded,
                label: '${record.microRestCount} 次微休息',
              ),
              if (category != null)
                _RecordChip(icon: Icons.sell_rounded, label: category.label),
              if (preset != null)
                _RecordChip(
                  icon: Icons.auto_awesome_rounded,
                  label: preset.name,
                ),
              if (sound != null)
                _RecordChip(icon: Icons.headphones_rounded, label: sound.name),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}min';
  }
}

class _RecordChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RecordChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
