import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrinciplesPage extends StatelessWidget {
  const PrinciplesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('科学原理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '为什么 FocusBell 有效？',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '基于四大核心神经科学原理，每一条都有前沿论文支撑',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _PrincipleCard(
            icon: Icons.psychology_rounded,
            color: const Color(0xFF1565C0),
            title: '神经重放',
            titleEn: 'Neural Replay',
            summary: '休息时大脑以 20 倍速"回放"刚学过的内容',
            details:
                'NIH 2021 年研究发现，学习新技能后的短暂休息中，大脑会以约 20 倍的速度压缩回放刚才练习的神经活动模式。'
                '2024 年 Nature 研究进一步证实，运动皮层在短暂休息中的重激活率直接预测了学习增益。'
                '2025 年 Nature Communications 发现，海马体涟漪波 (70-150Hz) 在仅 10-30 秒的休息中就能驱动运动学习巩固。',
            appExplanation: 'FocusBell 的 10 秒闭眼休息正是触发神经重放的最佳窗口',
            references: const [
              _Reference(
                text: 'Buch et al. (2021) Cell Reports - 清醒休息中的海马-新皮层重放',
                url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC8259719/',
              ),
              _Reference(
                text: 'Nature (2024) - 短暂休息中的集成重激活驱动序列快速学习',
                url: 'https://www.nature.com/articles/s41586-024-08414-9',
              ),
              _Reference(
                text: 'Nature Communications (2025) - 海马涟漪波预测短暂休息中的运动学习',
                url: 'https://www.nature.com/articles/s41467-025-61136-y',
              ),
            ],
          ),
          _PrincipleCard(
            icon: Icons.casino_rounded,
            color: const Color(0xFFC62828),
            title: '变比率强化',
            titleEn: 'Variable-Ratio Reinforcement',
            summary: '不可预测的奖励时机产生最强的行为持续力',
            details:
                '行为心理学研究表明，变比率强化是最强效的强化程式。'
                '不可预测的奖励时机会让多巴胺系统持续保持活跃，产生最高、最稳定的行为持续率。'
                '2025 年 Nature Communications 研究发现，多巴胺神经元活动更多反映行为动机强度而非单纯的学习信号，'
                '变比率奖励能维持持续的多巴胺释放。',
            appExplanation: '3-5 分钟随机铃声间隔制造"惊喜感"，每次铃声都是正向反馈，维持专注动力',
            references: const [
              _Reference(
                text: 'Nature Communications (2025) - 多巴胺动态与奖励学习的行为绩效关联',
                url: 'https://www.nature.com/articles/s41467-025-64132-4',
              ),
            ],
          ),
          _PrincipleCard(
            icon: Icons.replay_rounded,
            color: const Color(0xFF2E7D32),
            title: '任务恢复效应',
            titleEn: 'Ovsiankina Effect',
            summary: '被打断的任务会激活强烈的"想要完成"驱动力',
            details:
                '2025 年 Nature Humanities & Social Sciences Communications 发表的元分析对蔡格尼克效应进行了重要修正：'
                '被中断的任务虽不一定记得更牢（传统蔡格尼克效应缺乏普遍支持），'
                '但人们表现出强烈的恢复未完成任务的倾向——这被称为 Ovsiankina 效应。'
                '这个效应更加稳健可靠，已在多项研究中得到一致验证。',
            appExplanation: '短暂的 10 秒中断激活"想要完成"的内在驱动力，帮助你更快回到心流状态',
            references: const [
              _Reference(
                text:
                    'Nature HSS Communications (2025) - 蔡格尼克与 Ovsiankina 效应元分析',
                url: 'https://www.nature.com/articles/s41599-025-05000-w',
              ),
            ],
          ),
          _PrincipleCard(
            icon: Icons.schedule_rounded,
            color: const Color(0xFF6A1B9A),
            title: '超日节律 90/20',
            titleEn: 'Ultradian BRAC',
            summary: '大脑天然以 ~90 分钟为周期运作，之后需要 20 分钟恢复',
            details:
                'Kleitman 发现的基本休息-活动周期 (BRAC) 表明，人体存在约 90 分钟的超日节律。'
                '2025 年 Physical Review E 的数学模型证实这是健康人脑的标志性特征，'
                '由多巴胺、去甲肾上腺素和乙酰胆碱的波动驱动。'
                '2024 年 Nature Communications 通过颅内 EEG 证实这是可观测的神经生物学现象。'
                '斯坦福 Huberman 教授推荐 90 分钟深度工作 + NSDR 深度休息，'
                '学习后的 NSDR 可提升记忆保持率高达 50%。'
                '2024 年企业试验表明，按此节律工作可使项目完成率提升 12%，倦怠降低 9%。',
            appExplanation: 'FocusBell 默认 90 分钟专注 + 20 分钟 NSDR 深度休息，完美对齐大脑节律',
            references: const [
              _Reference(
                text: 'Physical Review E (2025) - 超日节律动力学机制模型',
                url:
                    'https://journals.aps.org/pre/abstract/10.1103/PhysRevE.111.044215',
              ),
              _Reference(
                text: 'Nature Communications (2024) - 脑组织中超日节律的颅内 EEG 证据',
                url: 'https://www.nature.com/articles/s41467-024-52769-6',
              ),
              _Reference(
                text: 'Springer (2024) - 系统性微休息对认知任务中注意力的影响',
                url:
                    'https://link.springer.com/article/10.1007/s43674-024-00074-6',
              ),
              _Reference(
                text: 'NIH/NINDS (2021) - 短暂休息帮助大脑学习新技能',
                url:
                    'https://www.ninds.nih.gov/news-events/news/press-releases/study-shows-how-taking-short-breaks-may-help-our-brains-learn-new-skills',
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Reference {
  final String text;
  final String url;
  const _Reference({required this.text, required this.url});
}

class _PrincipleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String titleEn;
  final String summary;
  final String details;
  final String appExplanation;
  final List<_Reference> references;

  const _PrincipleCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.titleEn,
    required this.summary,
    required this.details,
    required this.appExplanation,
    required this.references,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text(
              titleEn,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            summary,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: color,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '在 FocusBell 中：$appExplanation',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '参考文献',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...references.map(
                  (ref) => InkWell(
                    onTap: () => _launchUrl(ref.url),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ref.text,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
