enum SoundCategory {
  bell('轻柔铃声', '适合不打断思路的微提醒'),
  nature('自然声', '更贴近学习和放松场景的温和提示'),
  digital('数字音', '简洁现代、清晰利落的提示音'),
  voice('呼吸引导', '更柔和、恢复感更强的提示方式');

  final String label;
  final String description;

  const SoundCategory(this.label, this.description);
}

enum BuiltInSoundTexture {
  bowl,
  chime,
  wood,
  water,
  digital,
  pulse,
  breath,
  crystal,
  harp,
}

class BuiltInSound {
  final String id;
  final String name;
  final String nameEn;
  final SoundCategory category;
  final int frequency;
  final double durationSeconds;
  final BuiltInSoundTexture texture;
  final int pulseCount;

  const BuiltInSound({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.category,
    required this.frequency,
    required this.durationSeconds,
    this.texture = BuiltInSoundTexture.chime,
    this.pulseCount = 1,
  });
}

const List<BuiltInSound> builtInSounds = [
  BuiltInSound(
    id: 'singing_bowl',
    name: '颂钵回响',
    nameEn: 'Singing Bowl',
    category: SoundCategory.bell,
    frequency: 432,
    durationSeconds: 2.0,
    texture: BuiltInSoundTexture.bowl,
  ),
  BuiltInSound(
    id: 'wind_chime',
    name: '风铃微光',
    nameEn: 'Wind Chime',
    category: SoundCategory.bell,
    frequency: 880,
    durationSeconds: 1.5,
    texture: BuiltInSoundTexture.chime,
  ),
  BuiltInSound(
    id: 'temple_echo',
    name: '寺钟余韵',
    nameEn: 'Temple Echo',
    category: SoundCategory.bell,
    frequency: 392,
    durationSeconds: 2.3,
    texture: BuiltInSoundTexture.crystal,
  ),
  BuiltInSound(
    id: 'wooden_fish',
    name: '木鱼轻敲',
    nameEn: 'Wooden Fish',
    category: SoundCategory.bell,
    frequency: 300,
    durationSeconds: 0.85,
    texture: BuiltInSoundTexture.wood,
  ),
  BuiltInSound(
    id: 'silver_bell',
    name: '银铃提醒',
    nameEn: 'Silver Bell',
    category: SoundCategory.bell,
    frequency: 1046,
    durationSeconds: 1.4,
    texture: BuiltInSoundTexture.crystal,
  ),
  BuiltInSound(
    id: 'bird_chirp',
    name: '晨鸟轻鸣',
    nameEn: 'Bird Chirp',
    category: SoundCategory.nature,
    frequency: 1800,
    durationSeconds: 1.1,
    texture: BuiltInSoundTexture.chime,
    pulseCount: 2,
  ),
  BuiltInSound(
    id: 'water_drop',
    name: '水滴落下',
    nameEn: 'Water Drop',
    category: SoundCategory.nature,
    frequency: 620,
    durationSeconds: 0.7,
    texture: BuiltInSoundTexture.water,
  ),
  BuiltInSound(
    id: 'bamboo_wind',
    name: '竹影微风',
    nameEn: 'Bamboo Wind',
    category: SoundCategory.nature,
    frequency: 360,
    durationSeconds: 1.8,
    texture: BuiltInSoundTexture.breath,
  ),
  BuiltInSound(
    id: 'river_pebble',
    name: '溪石叮咚',
    nameEn: 'River Pebble',
    category: SoundCategory.nature,
    frequency: 540,
    durationSeconds: 1.2,
    texture: BuiltInSoundTexture.water,
    pulseCount: 2,
  ),
  BuiltInSound(
    id: 'soft_ding',
    name: '柔和叮声',
    nameEn: 'Soft Ding',
    category: SoundCategory.digital,
    frequency: 523,
    durationSeconds: 0.85,
    texture: BuiltInSoundTexture.digital,
  ),
  BuiltInSound(
    id: 'bubble_pop',
    name: '气泡弹起',
    nameEn: 'Bubble Pop',
    category: SoundCategory.digital,
    frequency: 700,
    durationSeconds: 0.55,
    texture: BuiltInSoundTexture.water,
  ),
  BuiltInSound(
    id: 'harp_pluck',
    name: '竖琴拨片',
    nameEn: 'Harp Pluck',
    category: SoundCategory.digital,
    frequency: 660,
    durationSeconds: 1.0,
    texture: BuiltInSoundTexture.harp,
  ),
  BuiltInSound(
    id: 'digital_pulse',
    name: '数字脉冲',
    nameEn: 'Digital Pulse',
    category: SoundCategory.digital,
    frequency: 440,
    durationSeconds: 0.7,
    texture: BuiltInSoundTexture.pulse,
    pulseCount: 2,
  ),
  BuiltInSound(
    id: 'focus_spark',
    name: '专注火花',
    nameEn: 'Focus Spark',
    category: SoundCategory.digital,
    frequency: 780,
    durationSeconds: 0.95,
    texture: BuiltInSoundTexture.pulse,
    pulseCount: 3,
  ),
  BuiltInSound(
    id: 'glass_bloom',
    name: '玻璃绽放',
    nameEn: 'Glass Bloom',
    category: SoundCategory.digital,
    frequency: 936,
    durationSeconds: 1.5,
    texture: BuiltInSoundTexture.crystal,
  ),
  BuiltInSound(
    id: 'gentle_rest',
    name: '轻声提醒',
    nameEn: 'Gentle Rest',
    category: SoundCategory.voice,
    frequency: 350,
    durationSeconds: 1.6,
    texture: BuiltInSoundTexture.breath,
  ),
  BuiltInSound(
    id: 'breathing_guide',
    name: '呼吸引导',
    nameEn: 'Breathing Guide',
    category: SoundCategory.voice,
    frequency: 280,
    durationSeconds: 2.2,
    texture: BuiltInSoundTexture.breath,
    pulseCount: 2,
  ),
  BuiltInSound(
    id: 'bell_voice',
    name: '铃音回身',
    nameEn: 'Bell + Voice',
    category: SoundCategory.voice,
    frequency: 500,
    durationSeconds: 1.9,
    texture: BuiltInSoundTexture.bowl,
  ),
  BuiltInSound(
    id: 'calm_countdown',
    name: '平缓唤醒',
    nameEn: 'Calm Wake',
    category: SoundCategory.voice,
    frequency: 330,
    durationSeconds: 2.4,
    texture: BuiltInSoundTexture.breath,
    pulseCount: 3,
  ),
];

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
  AmbientScene(
    id: 'light_rain',
    name: '细雨',
    icon: '🌦️',
    apiParam: 'light_rain',
  ),
  AmbientScene(id: 'ocean', name: '海浪', icon: '🌊', apiParam: 'ocean'),
  AmbientScene(
    id: 'coffee_shop',
    name: '咖啡馆',
    icon: '☕',
    apiParam: 'coffee_shop',
  ),
  AmbientScene(id: 'river', name: '溪流', icon: '🏞️', apiParam: 'river'),
  AmbientScene(id: 'lake', name: '湖畔', icon: '🛶', apiParam: 'lake'),
  AmbientScene(id: 'beach', name: '海滩', icon: '🏖️', apiParam: 'beach'),
  AmbientScene(id: 'fireplace', name: '壁炉', icon: '🔥', apiParam: 'fireplace'),
];

enum FocusSoundCategory {
  noise('遮罩底噪', '更稳定地盖住环境杂音与人声'),
  nature('自然环境', '雨声、海浪、山风、溪流等更沉浸的环境音'),
  meditation('冥想舒缓', '更慢、更深、更适合静心和恢复'),
  study('学习陪伴', '适合阅读、写作、刷题和长时轻专注');

  final String label;
  final String description;

  const FocusSoundCategory(this.label, this.description);
}

enum FocusSoundKind {
  whiteNoise,
  brownNoise,
  pinkNoise,
  rainDrift,
  stormRain,
  forestCanopy,
  mountainWind,
  streamFlow,
  caveDrip,
  oceanWave,
  fireplaceGlow,
  nightCrickets,
  meditationDrone,
  deepSpace,
  cafeHum,
  libraryAir,
  trainCabin,
  studyLofi,
  pianoMist,
}

class FocusSoundscape {
  final String id;
  final String name;
  final String nameEn;
  final String description;
  final FocusSoundCategory category;
  final FocusSoundKind kind;

  const FocusSoundscape({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.category,
    required this.kind,
  });
}

const List<FocusSoundscape> focusSoundscapes = [
  FocusSoundscape(
    id: 'white_noise',
    name: '明亮白噪',
    nameEn: 'White Noise',
    description: '更亮、更均匀，适合办公室与人声环境',
    category: FocusSoundCategory.noise,
    kind: FocusSoundKind.whiteNoise,
  ),
  FocusSoundscape(
    id: 'brown_noise',
    name: '深度棕噪',
    nameEn: 'Brown Noise',
    description: '低频更稳，更适合深度沉浸和编码',
    category: FocusSoundCategory.noise,
    kind: FocusSoundKind.brownNoise,
  ),
  FocusSoundscape(
    id: 'pink_noise',
    name: '柔和粉噪',
    nameEn: 'Pink Noise',
    description: '更柔和的宽频底噪，适合阅读和写作',
    category: FocusSoundCategory.noise,
    kind: FocusSoundKind.pinkNoise,
  ),
  FocusSoundscape(
    id: 'rain_drift',
    name: '细雨幕布',
    nameEn: 'Rain Drift',
    description: '轻雨幕感，适合长时间遮蔽干扰',
    category: FocusSoundCategory.nature,
    kind: FocusSoundKind.rainDrift,
  ),
  FocusSoundscape(
    id: 'storm_rain',
    name: '远雷夜雨',
    nameEn: 'Storm Rain',
    description: '雨声更厚，偶有低沉雷鸣，氛围更完整',
    category: FocusSoundCategory.nature,
    kind: FocusSoundKind.stormRain,
  ),
  FocusSoundscape(
    id: 'forest_canopy',
    name: '林间晨风',
    nameEn: 'Forest Canopy',
    description: '风穿树梢，偶有鸟鸣，适合自然场景学习',
    category: FocusSoundCategory.nature,
    kind: FocusSoundKind.forestCanopy,
  ),
  FocusSoundscape(
    id: 'mountain_wind',
    name: '山口长风',
    nameEn: 'Mountain Wind',
    description: '更开阔的风声层次，适合高强度独处专注',
    category: FocusSoundCategory.nature,
    kind: FocusSoundKind.mountainWind,
  ),
  FocusSoundscape(
    id: 'stream_flow',
    name: '山涧溪流',
    nameEn: 'Stream Flow',
    description: '连绵细流与水面反光感，适合阅读和思考',
    category: FocusSoundCategory.nature,
    kind: FocusSoundKind.streamFlow,
  ),
  FocusSoundscape(
    id: 'cave_drip',
    name: '洞穴滴泉',
    nameEn: 'Cave Drip',
    description: '带空间感的水滴和低回响，氛围更沉静',
    category: FocusSoundCategory.nature,
    kind: FocusSoundKind.caveDrip,
  ),
  FocusSoundscape(
    id: 'ocean_wave',
    name: '海浪呼吸',
    nameEn: 'Ocean Wave',
    description: '更慢的海浪起伏，帮助稳定节奏和情绪',
    category: FocusSoundCategory.nature,
    kind: FocusSoundKind.oceanWave,
  ),
  FocusSoundscape(
    id: 'fireplace_glow',
    name: '壁炉炉火',
    nameEn: 'Fireplace Glow',
    description: '细碎火苗与温暖低频，适合夜晚或低照环境',
    category: FocusSoundCategory.nature,
    kind: FocusSoundKind.fireplaceGlow,
  ),
  FocusSoundscape(
    id: 'night_crickets',
    name: '夜色虫鸣',
    nameEn: 'Night Crickets',
    description: '安静夜色里的细碎虫鸣，更适合独处时使用',
    category: FocusSoundCategory.nature,
    kind: FocusSoundKind.nightCrickets,
  ),
  FocusSoundscape(
    id: 'meditation_drone',
    name: '冥想音垫',
    nameEn: 'Meditation Drone',
    description: '慢呼吸般的低频音垫，适合静心和恢复',
    category: FocusSoundCategory.meditation,
    kind: FocusSoundKind.meditationDrone,
  ),
  FocusSoundscape(
    id: 'deep_space',
    name: '深空静流',
    nameEn: 'Deep Space',
    description: '更空旷、更轻的长线条氛围，适合超长专注',
    category: FocusSoundCategory.meditation,
    kind: FocusSoundKind.deepSpace,
  ),
  FocusSoundscape(
    id: 'cafe_hum',
    name: '咖啡馆陪伴',
    nameEn: 'Cafe Hum',
    description: '轻环境人声与器皿声，模拟陪伴感',
    category: FocusSoundCategory.study,
    kind: FocusSoundKind.cafeHum,
  ),
  FocusSoundscape(
    id: 'library_air',
    name: '图书馆空气',
    nameEn: 'Library Air',
    description: '更安静的室内空气感，适合阅读和刷题',
    category: FocusSoundCategory.study,
    kind: FocusSoundKind.libraryAir,
  ),
  FocusSoundscape(
    id: 'train_cabin',
    name: '列车车厢',
    nameEn: 'Train Cabin',
    description: '规律低频与远处轨道节奏，适合长时间稳态工作',
    category: FocusSoundCategory.study,
    kind: FocusSoundKind.trainCabin,
  ),
  FocusSoundscape(
    id: 'study_lofi',
    name: '学习轻旋律',
    nameEn: 'Study Lo-Fi',
    description: '低刺激的轻循环旋律，适合阅读与轻写作',
    category: FocusSoundCategory.study,
    kind: FocusSoundKind.studyLofi,
  ),
  FocusSoundscape(
    id: 'piano_mist',
    name: '雾中钢琴',
    nameEn: 'Piano Mist',
    description: '更稀疏的钢琴颗粒与长尾，适合需要灵感的工作',
    category: FocusSoundCategory.study,
    kind: FocusSoundKind.pianoMist,
  ),
];

const String defaultFocusPresetId = 'classic_brac';
const String customFocusPresetId = 'custom';

class FocusPreset {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int focusDurationMinutes;
  final int breakDurationMinutes;
  final int microRestSeconds;
  final int minIntervalMinutes;
  final int maxIntervalMinutes;
  final bool focusSoundEnabled;
  final bool randomFocusSoundMode;
  final String selectedFocusSoundId;

  const FocusPreset({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.focusDurationMinutes,
    required this.breakDurationMinutes,
    required this.microRestSeconds,
    required this.minIntervalMinutes,
    required this.maxIntervalMinutes,
    required this.focusSoundEnabled,
    required this.randomFocusSoundMode,
    required this.selectedFocusSoundId,
  });
}

const List<FocusPreset> focusPresets = [
  FocusPreset(
    id: defaultFocusPresetId,
    name: '经典 90/20',
    emoji: '🧠',
    description: '经典神经节律方案，适合深度工作和长时专注',
    focusDurationMinutes: 90,
    breakDurationMinutes: 20,
    microRestSeconds: 10,
    minIntervalMinutes: 3,
    maxIntervalMinutes: 5,
    focusSoundEnabled: false,
    randomFocusSoundMode: false,
    selectedFocusSoundId: 'brown_noise',
  ),
  FocusPreset(
    id: 'deep_immersion',
    name: '沉浸深潜',
    emoji: '🌊',
    description: '适合写代码、写方案和连续高强度思考',
    focusDurationMinutes: 60,
    breakDurationMinutes: 15,
    microRestSeconds: 10,
    minIntervalMinutes: 4,
    maxIntervalMinutes: 6,
    focusSoundEnabled: true,
    randomFocusSoundMode: false,
    selectedFocusSoundId: 'brown_noise',
  ),
  FocusPreset(
    id: 'gentle_study',
    name: '轻柔学习',
    emoji: '📚',
    description: '适合阅读、背诵、刷题和长时间安静学习',
    focusDurationMinutes: 45,
    breakDurationMinutes: 10,
    microRestSeconds: 8,
    minIntervalMinutes: 4,
    maxIntervalMinutes: 6,
    focusSoundEnabled: true,
    randomFocusSoundMode: false,
    selectedFocusSoundId: 'rain_drift',
  ),
  FocusPreset(
    id: 'mindful_reset',
    name: '冥想回稳',
    emoji: '🪷',
    description: '适合整理情绪、冥想练习和恢复型专注',
    focusDurationMinutes: 25,
    breakDurationMinutes: 5,
    microRestSeconds: 10,
    minIntervalMinutes: 3,
    maxIntervalMinutes: 4,
    focusSoundEnabled: true,
    randomFocusSoundMode: false,
    selectedFocusSoundId: 'meditation_drone',
  ),
  FocusPreset(
    id: 'exam_sprint',
    name: '刷题冲刺',
    emoji: '⚡',
    description: '适合短周期高效率输出，节奏更紧凑',
    focusDurationMinutes: 30,
    breakDurationMinutes: 5,
    microRestSeconds: 6,
    minIntervalMinutes: 2,
    maxIntervalMinutes: 3,
    focusSoundEnabled: true,
    randomFocusSoundMode: false,
    selectedFocusSoundId: 'study_lofi',
  ),
];

FocusPreset? findFocusPresetById(String id) {
  for (final preset in focusPresets) {
    if (preset.id == id) {
      return preset;
    }
  }
  return null;
}

FocusSoundscape? findFocusSoundscapeById(String id) {
  for (final soundscape in focusSoundscapes) {
    if (soundscape.id == id) {
      return soundscape;
    }
  }
  return null;
}

const List<String> scienceTips = [
  '短暂闭眼微休息能帮助大脑更快巩固刚刚处理过的信息。',
  '随机提醒比固定节拍更不容易让大脑形成机械忽略。',
  '高质量的 10 秒闭眼休息，常常比低质量的 1 分钟刷手机更有效。',
  '专注中穿插短暂停顿，有助于降低心理疲劳并稳定后续表现。',
  '完成一次微休息，本质上是在给注意力系统做一次“软重置”。',
  '环境声的作用不是制造刺激，而是帮助你把外界噪声推到背景层。',
  '节律稳定的背景音更适合长时间工作，过于频繁的变化反而会分心。',
  '深度专注不只靠意志力，也靠环境、节奏和恢复窗口的配合。',
  '当你及时停一下、闭一下眼，大脑往往会更愿意继续完成眼前任务。',
  '对很多人来说，低频、平稳、重复度低的声音最适合沉浸工作。',
  '休息结束的提示音越清晰，你越容易无摩擦地重新进入任务。',
  '背景音的“连贯感”比“花样多”更重要，好的循环应该让人忘记它在循环。',
];
