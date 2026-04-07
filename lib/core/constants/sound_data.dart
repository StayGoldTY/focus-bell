enum SoundCategory {
  bell('轻柔铃声', '适合不打断思路的微提醒'),
  nature('自然声', '符合学习场景的舒适提醒'),
  digital('电子音', '现代简洁的数字提示'),
  voice('人声引导', '温和的语音引导');

  final String label;
  final String description;
  const SoundCategory(this.label, this.description);
}

class BuiltInSound {
  final String id;
  final String name;
  final String nameEn;
  final SoundCategory category;
  final int frequency;
  final double durationSeconds;

  const BuiltInSound({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.category,
    required this.frequency,
    required this.durationSeconds,
  });
}

/// 内置提示音列表（使用程序化合成，无需音频文件）
const List<BuiltInSound> builtInSounds = [
  // 铃声类
  BuiltInSound(id: 'singing_bowl', name: '藏钵钟声', nameEn: 'Singing Bowl', category: SoundCategory.bell, frequency: 432, durationSeconds: 2.0),
  BuiltInSound(id: 'wind_chime', name: '风铃', nameEn: 'Wind Chime', category: SoundCategory.bell, frequency: 880, durationSeconds: 1.5),
  BuiltInSound(id: 'wooden_fish', name: '木鱼', nameEn: 'Wooden Fish', category: SoundCategory.bell, frequency: 300, durationSeconds: 0.8),
  BuiltInSound(id: 'triangle_ding', name: '三角铁', nameEn: 'Triangle Ding', category: SoundCategory.bell, frequency: 1200, durationSeconds: 1.2),
  // 自然声类
  BuiltInSound(id: 'bird_chirp', name: '鸟鸣一声', nameEn: 'Bird Chirp', category: SoundCategory.nature, frequency: 2000, durationSeconds: 1.0),
  BuiltInSound(id: 'water_drop', name: '水滴声', nameEn: 'Water Drop', category: SoundCategory.nature, frequency: 600, durationSeconds: 0.6),
  BuiltInSound(id: 'bamboo_wind', name: '竹林风声', nameEn: 'Bamboo Wind', category: SoundCategory.nature, frequency: 400, durationSeconds: 2.0),
  BuiltInSound(id: 'cricket', name: '蟋蟀声', nameEn: 'Cricket Chirp', category: SoundCategory.nature, frequency: 3500, durationSeconds: 1.0),
  // 电子音类
  BuiltInSound(id: 'soft_ding', name: '柔和叮咚', nameEn: 'Soft Ding', category: SoundCategory.digital, frequency: 523, durationSeconds: 0.8),
  BuiltInSound(id: 'bubble_pop', name: '气泡音', nameEn: 'Bubble Pop', category: SoundCategory.digital, frequency: 700, durationSeconds: 0.5),
  BuiltInSound(id: 'harp_pluck', name: '琴弦拨动', nameEn: 'Harp Pluck', category: SoundCategory.digital, frequency: 660, durationSeconds: 1.0),
  BuiltInSound(id: 'digital_pulse', name: '数字脉冲', nameEn: 'Digital Pulse', category: SoundCategory.digital, frequency: 440, durationSeconds: 0.6),
  // 人声类
  BuiltInSound(id: 'gentle_rest', name: '轻声提醒', nameEn: 'Gentle Rest', category: SoundCategory.voice, frequency: 350, durationSeconds: 1.5),
  BuiltInSound(id: 'breathing_guide', name: '呼吸引导', nameEn: 'Breathing Guide', category: SoundCategory.voice, frequency: 280, durationSeconds: 2.0),
  BuiltInSound(id: 'bell_voice', name: '铃铛+语音', nameEn: 'Bell + Voice', category: SoundCategory.voice, frequency: 500, durationSeconds: 2.0),
];

/// 环境音场景预设
class AmbientScene {
  final String id;
  final String name;
  final String icon;
  final String apiParam;

  const AmbientScene({
    required this.id,
    required this.name,
    required this.icon,
    required this.apiParam,
  });
}

const List<AmbientScene> ambientScenes = [
  AmbientScene(id: 'forest', name: '森林', icon: '🌲', apiParam: 'forest'),
  AmbientScene(id: 'rain', name: '雨声', icon: '🌧️', apiParam: 'light_rain'),
  AmbientScene(id: 'ocean', name: '海洋', icon: '🌊', apiParam: 'ocean'),
  AmbientScene(id: 'coffee_shop', name: '咖啡馆', icon: '☕', apiParam: 'coffee_shop'),
  AmbientScene(id: 'river', name: '河流', icon: '🏞️', apiParam: 'river'),
  AmbientScene(id: 'lake', name: '湖泊', icon: '🏔️', apiParam: 'lake'),
  AmbientScene(id: 'beach', name: '沙滩', icon: '🏖️', apiParam: 'beach'),
  AmbientScene(id: 'fireplace', name: '壁炉', icon: '🔥', apiParam: 'fireplace'),
];

/// 科学小贴士（微休息时随机展示）
const List<String> scienceTips = [
  '你的大脑正在以 20 倍速复习刚才的内容 —— NIH 2021',
  '海马体涟漪波正在巩固你的记忆 —— Nature 2025',
  '短暂休息中的神经重激活直接预测学习增益 —— Nature 2024',
  '变比率奖励能维持持续的多巴胺释放，保持你的专注动力',
  '被中断的任务会激活"想要完成"的内在驱动力 —— Ovsiankina 效应',
  '90 分钟超日节律是健康大脑的标志性特征 —— Physical Review E 2025',
  '微休息能让你的表现更稳定，降低心理疲劳 —— Springer 2024',
  '学习后 10 分钟的深度休息可提升记忆保持率高达 50% —— Huberman',
  '你的运动皮层正在高速重激活任务相关的神经模式',
  '闭眼状态下 alpha 脑波增强，有助于信息整合与创造性思维',
  '每次铃声都是一次正向反馈，你的多巴胺系统正在帮你坚持',
  '短暂的中断反而让你更想完成手头的任务，这是大脑的自然机制',
];
