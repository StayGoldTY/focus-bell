import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/storage_service.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.read(storageServiceProvider);
    final theme = Theme.of(context);

    final totalSeconds = storage.totalFocusSeconds;
    final totalHours = totalSeconds ~/ 3600;
    final totalMinutes = (totalSeconds % 3600) ~/ 60;
    final sessions = storage.completedSessions;
    final todaySeconds = storage.todayFocusSeconds;
    final todayMinutes = todaySeconds ~/ 60;
    final currentStreak = storage.currentStreak;
    final bestStreak = storage.bestStreak;
    final dailyTargetMinutes = storage.focusDuration;
    final dailyProgress = dailyTargetMinutes > 0
        ? (todayMinutes / dailyTargetMinutes).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('专注统计')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '你的专注数据',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),

            // 统计卡片网格
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.timer_rounded,
                    label: '今日专注',
                    value: '${todayMinutes}min',
                    color: theme.colorScheme.primary,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_rounded,
                    label: '完成轮次',
                    value: '$sessions',
                    color: const Color(0xFF2E7D32),
                    theme: theme,
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
                    label: '总专注时间',
                    value: totalHours > 0
                        ? '${totalHours}h ${totalMinutes}m'
                        : '${totalMinutes}min',
                    color: const Color(0xFFE65100),
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.trending_up_rounded,
                    label: '平均每轮',
                    value: sessions > 0
                        ? '${(totalSeconds / sessions / 60).round()}min'
                        : '0min',
                    color: const Color(0xFF6A1B9A),
                    theme: theme,
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
                    value: '$currentStreak天',
                    color: const Color(0xFFD84315),
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.workspace_premium_rounded,
                    label: '最佳连续',
                    value: '$bestStreak天',
                    color: const Color(0xFF00897B),
                    theme: theme,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Container(
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
                        '今日完成度',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${(dailyProgress * 100).round()}%',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '以当前专注时长 $dailyTargetMinutes 分钟为一个完整目标',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: dailyProgress,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 鼓励信息
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
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
      ),
    );
  }

  String _getEncouragement(int totalSeconds) {
    final hours = totalSeconds / 3600;
    if (hours < 1) return '万事开头难，坚持就是胜利！\n开始你的第一次专注吧';
    if (hours < 5) return '很好的开始！\n你已经积累了 ${hours.toStringAsFixed(1)} 小时的深度专注';
    if (hours < 20) return '稳步提升中！\n你的大脑正在变得更善于集中注意力';
    if (hours < 50) return '令人印象深刻！\n持续的深度专注正在重塑你的神经回路';
    return '专注大师！\n你的专注力已经远超大多数人';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
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
