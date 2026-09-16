class FocusQuotes {
  FocusQuotes._();

  static const List<String> all = [
    '把注意力收回来，往往比催自己开始更重要。',
    '这一轮只做一件事，其它念头可以稍后再见。',
    '短暂停一下，不是放弃，而是让大脑把刚处理的内容留下来。',
    '专注不是憋气，是给自己一个安静、可结束的时间盒。',
    '铃声响起时闭眼十秒，常常比多刷一页更有用。',
    '深度工作需要边界：开始、提醒、恢复，缺一不可。',
    '今天不必完美，只要把这一段时间完整地交给眼前的任务。',
    '随机提醒会让注意力保持清醒，而不是被固定节拍催眠。',
    '先开始 25 分钟也可以。真正难的是愿意坐下来。',
    '完成比完美更接近心流：先进入节奏，再谈质量。',
  ];

  static String forDate(DateTime date) {
    final local = date.toLocal();
    final dayKey = DateTime(
      local.year,
      local.month,
      local.day,
    ).difference(DateTime(local.year)).inDays;
    return all[(local.year + dayKey) % all.length];
  }
}
