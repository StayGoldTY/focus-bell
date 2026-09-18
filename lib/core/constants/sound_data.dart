import '../audio/ambient_recipe.dart';

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

enum FocusSoundCategory {
  nature('自然', '雨、海浪、溪流、篝火这类有呼吸感的环境音'),
  noise('噪音', '稳定的遮罩底噪，最擅长盖住人声和键盘声'),
  ambience('氛围', '咖啡馆、图书馆、音垫和双耳节拍，营造陪伴感');

  final String label;
  final String description;

  const FocusSoundCategory(this.label, this.description);
}

class FocusSoundscape {
  final String id;
  final String name;
  final String nameEn;
  final String icon;
  final String description;
  final FocusSoundCategory category;
  final AmbientRecipe recipe;

  const FocusSoundscape({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.icon,
    required this.description,
    required this.category,
    required this.recipe,
  });
}

/// Rain bed shared by the three rain variants: a bright pink-noise sheet, a
/// dull brown roof rumble, a sparkle band, gutter drips and individual splats.
const _rainBed = <NoiseLayer>[
  NoiseLayer(
    color: NoiseColor.pink,
    filters: [AmbientFilter.highpass(900), AmbientFilter.lowpass(7000)],
    gain: 0.55,
    lfo: AmbientLfo(rateHz: 0.05, depth: 0.25),
    width: 0.9,
  ),
  NoiseLayer(
    color: NoiseColor.brown,
    filters: [AmbientFilter.lowpass(500)],
    gain: 0.25,
    lfo: AmbientLfo(rateHz: 0.03, depth: 0.3),
  ),
  NoiseLayer(
    color: NoiseColor.white,
    filters: [AmbientFilter.bandpass(4500, q: 0.8)],
    gain: 0.12,
    lfo: AmbientLfo(rateHz: 0.11, depth: 0.4),
    width: 1.0,
  ),
];

const _rainDrops = <EventLayer>[
  EventLayer.tone(
    ratePerSecond: 1.5,
    minDurationSeconds: 0.03,
    maxDurationSeconds: 0.08,
    gain: 0.10,
    gainJitter: 0.7,
    panSpread: 0.9,
    minFrequency: 1800,
    maxFrequency: 3800,
    sweepRatio: 0.6,
    partials: [TonePartial(1, 1), TonePartial(2.3, 0.3)],
  ),
  EventLayer.burst(
    ratePerSecond: 8,
    minDurationSeconds: 0.012,
    maxDurationSeconds: 0.04,
    gain: 0.12,
    gainJitter: 0.8,
    panSpread: 1.0,
    minFrequency: 2500,
    maxFrequency: 6000,
    q: 1.5,
  ),
];

const List<FocusSoundscape> focusSoundscapes = [
  // ---------------------------------------------------------------- 自然
  FocusSoundscape(
    id: 'rain_drift',
    name: '细雨',
    nameEn: 'Light Rain',
    icon: '🌦️',
    description: '窗外的稀疏雨声，带远处屋檐滴水，适合长时间遮蔽干扰',
    category: FocusSoundCategory.nature,
    recipe: AmbientRecipe(noise: _rainBed, events: _rainDrops, masterGain: 1.4),
  ),
  FocusSoundscape(
    id: 'heavy_rain',
    name: '大雨',
    nameEn: 'Heavy Rain',
    icon: '🌧️',
    description: '更厚、更密的雨幕，偶有一阵风把雨吹过来',
    category: FocusSoundCategory.nature,
    recipe: AmbientRecipe(
      noise: [
        NoiseLayer(
          color: NoiseColor.pink,
          filters: [AmbientFilter.highpass(600), AmbientFilter.lowpass(9000)],
          gain: 0.8,
          lfo: AmbientLfo(rateHz: 0.07, depth: 0.2, filterSweepHz: 800),
          width: 0.9,
        ),
        NoiseLayer(
          color: NoiseColor.brown,
          filters: [AmbientFilter.lowpass(700)],
          gain: 0.45,
          lfo: AmbientLfo(rateHz: 0.04, depth: 0.25),
        ),
        NoiseLayer(
          color: NoiseColor.white,
          filters: [AmbientFilter.bandpass(3500, q: 0.5)],
          gain: 0.25,
          lfo: AmbientLfo(rateHz: 0.13, depth: 0.3),
          width: 1.0,
        ),
      ],
      events: [
        EventLayer.burst(
          ratePerSecond: 25,
          minDurationSeconds: 0.008,
          maxDurationSeconds: 0.03,
          gain: 0.12,
          gainJitter: 0.8,
          panSpread: 1.0,
          minFrequency: 2000,
          maxFrequency: 7000,
          q: 1.5,
        ),
        EventLayer.burst(
          ratePerSecond: 0.08,
          minGapSeconds: 6,
          minDurationSeconds: 4,
          maxDurationSeconds: 8,
          attackRatio: 0.4,
          gain: 0.2,
          gainJitter: 0.4,
          panSpread: 0.5,
          minFrequency: 1500,
          maxFrequency: 2500,
          sweepRatio: 0.7,
          filterType: AmbientFilterType.highpass,
          q: 0.7,
        ),
      ],
      masterGain: 0.75,
    ),
  ),
  FocusSoundscape(
    id: 'storm_rain',
    name: '远雷夜雨',
    nameEn: 'Distant Thunder',
    icon: '⛈️',
    description: '夜雨里每隔一会儿滚过一声很远的闷雷，氛围完整而不吵',
    category: FocusSoundCategory.nature,
    recipe: AmbientRecipe(
      noise: [
        ..._rainBed,
        NoiseLayer(
          color: NoiseColor.brown,
          filters: [AmbientFilter.lowpass(160, q: 0.8)],
          gain: 0.2,
          lfo: AmbientLfo(rateHz: 0.02, depth: 0.4),
        ),
      ],
      events: [
        ..._rainDrops,
        EventLayer.burst(
          ratePerSecond: 0.022,
          minGapSeconds: 20,
          minDurationSeconds: 5,
          maxDurationSeconds: 10,
          attackRatio: 0.25,
          gain: 1.6,
          gainJitter: 0.4,
          panSpread: 0.7,
          minFrequency: 140,
          maxFrequency: 260,
          sweepRatio: 0.35,
          color: NoiseColor.brown,
          filterType: AmbientFilterType.lowpass,
          q: 0.8,
        ),
      ],
      masterGain: 1.35,
    ),
  ),
  FocusSoundscape(
    id: 'ocean_wave',
    name: '海浪',
    nameEn: 'Ocean Waves',
    icon: '🌊',
    description: '十几秒一次的慢涌与泡沫铺开，适合稳定呼吸和情绪',
    category: FocusSoundCategory.nature,
    recipe: AmbientRecipe(
      noise: [
        NoiseLayer(
          color: NoiseColor.brown,
          filters: [
            AmbientFilter.highpass(80),
            AmbientFilter.lowpass(900, q: 0.6),
          ],
          gain: 0.6,
          lfo: AmbientLfo(rateHz: 0.085, depth: 0.75, filterSweepHz: 600),
          width: 0.9,
        ),
        NoiseLayer(
          color: NoiseColor.pink,
          filters: [AmbientFilter.bandpass(1800, q: 0.5)],
          gain: 0.3,
          lfo: AmbientLfo(rateHz: 0.085, depth: 0.85, filterSweepHz: 1000),
          width: 1.0,
        ),
        NoiseLayer(
          color: NoiseColor.brown,
          filters: [AmbientFilter.lowpass(120)],
          gain: 0.2,
          lfo: AmbientLfo(rateHz: 0.02, depth: 0.4),
        ),
      ],
      events: [
        EventLayer.burst(
          ratePerSecond: 0.09,
          minGapSeconds: 6,
          minDurationSeconds: 4,
          maxDurationSeconds: 7,
          attackRatio: 0.35,
          gain: 0.45,
          gainJitter: 0.3,
          panSpread: 0.4,
          minFrequency: 1200,
          maxFrequency: 2200,
          sweepRatio: 0.5,
          q: 0.7,
        ),
      ],
      masterGain: 1.6,
    ),
  ),
  FocusSoundscape(
    id: 'stream_flow',
    name: '溪流',
    nameEn: 'Mountain Stream',
    icon: '🏞️',
    description: '连绵的水流、细碎气泡和石缝里的咕咚声，适合阅读和思考',
    category: FocusSoundCategory.nature,
    recipe: AmbientRecipe(
      noise: [
        NoiseLayer(
          color: NoiseColor.pink,
          filters: [AmbientFilter.bandpass(1400, q: 0.6)],
          gain: 0.5,
          lfo: AmbientLfo(rateHz: 0.9, depth: 0.35, filterSweepHz: 400),
          width: 0.9,
        ),
        NoiseLayer(
          color: NoiseColor.white,
          filters: [AmbientFilter.bandpass(4000, q: 0.7)],
          gain: 0.18,
          lfo: AmbientLfo(rateHz: 1.7, depth: 0.4, filterSweepHz: 900),
          width: 1.0,
        ),
        NoiseLayer(
          color: NoiseColor.brown,
          filters: [AmbientFilter.lowpass(400)],
          gain: 0.25,
          lfo: AmbientLfo(rateHz: 0.3, depth: 0.3),
        ),
      ],
      events: [
        EventLayer.tone(
          ratePerSecond: 5,
          minDurationSeconds: 0.04,
          maxDurationSeconds: 0.12,
          gain: 0.06,
          gainJitter: 0.7,
          panSpread: 0.9,
          minFrequency: 500,
          maxFrequency: 1600,
          sweepRatio: 1.8,
        ),
        EventLayer.burst(
          ratePerSecond: 2,
          minDurationSeconds: 0.08,
          maxDurationSeconds: 0.25,
          gain: 0.2,
          gainJitter: 0.6,
          panSpread: 0.8,
          minFrequency: 300,
          maxFrequency: 900,
          sweepRatio: 1.5,
          color: NoiseColor.pink,
          q: 2.0,
        ),
      ],
      masterGain: 1.5,
    ),
  ),
  FocusSoundscape(
    id: 'forest_canopy',
    name: '森林',
    nameEn: 'Forest',
    icon: '🌲',
    description: '风穿过树冠、树叶沙沙，偶尔两三声远处鸟鸣',
    category: FocusSoundCategory.nature,
    recipe: AmbientRecipe(
      noise: [
        NoiseLayer(
          color: NoiseColor.brown,
          filters: [
            AmbientFilter.highpass(120),
            AmbientFilter.lowpass(800, q: 0.6),
          ],
          gain: 0.45,
          lfo: AmbientLfo(rateHz: 0.06, depth: 0.8, filterSweepHz: 500),
          width: 0.9,
        ),
        NoiseLayer(
          color: NoiseColor.white,
          filters: [AmbientFilter.bandpass(3500, q: 0.6)],
          gain: 0.14,
          lfo: AmbientLfo(rateHz: 0.13, depth: 0.85, filterSweepHz: 1200),
          width: 1.0,
        ),
        NoiseLayer(
          color: NoiseColor.pink,
          filters: [AmbientFilter.lowpass(300)],
          gain: 0.12,
          lfo: AmbientLfo(rateHz: 0.02, depth: 0.3),
        ),
      ],
      events: [
        EventLayer.tone(
          ratePerSecond: 0.18,
          minGapSeconds: 1.5,
          minDurationSeconds: 0.12,
          maxDurationSeconds: 0.35,
          attackRatio: 0.15,
          gain: 0.16,
          gainJitter: 0.5,
          panSpread: 1.0,
          minFrequency: 1800,
          maxFrequency: 4200,
          sweepRatio: 1.35,
          partials: [TonePartial(1, 1), TonePartial(2, 0.15)],
          trillHz: 14,
        ),
        EventLayer.tone(
          ratePerSecond: 0.1,
          minGapSeconds: 2,
          minDurationSeconds: 0.06,
          maxDurationSeconds: 0.14,
          gain: 0.1,
          gainJitter: 0.5,
          panSpread: 1.0,
          minFrequency: 2500,
          maxFrequency: 5000,
          sweepRatio: 0.7,
        ),
        EventLayer.burst(
          ratePerSecond: 0.25,
          minDurationSeconds: 0.03,
          maxDurationSeconds: 0.1,
          gain: 0.06,
          gainJitter: 0.6,
          panSpread: 1.0,
          minFrequency: 1500,
          maxFrequency: 4000,
        ),
      ],
      masterGain: 2.6,
    ),
  ),
  FocusSoundscape(
    id: 'mountain_wind',
    name: '山风',
    nameEn: 'Wind',
    icon: '🌬️',
    description: '开阔山口的长风，低沉的气压和高处的呼啸交替起伏',
    category: FocusSoundCategory.nature,
    recipe: AmbientRecipe(
      noise: [
        NoiseLayer(
          color: NoiseColor.brown,
          filters: [AmbientFilter.bandpass(350, q: 0.7)],
          gain: 0.7,
          lfo: AmbientLfo(rateHz: 0.055, depth: 0.85, filterSweepHz: 240),
          width: 0.9,
        ),
        NoiseLayer(
          color: NoiseColor.pink,
          filters: [AmbientFilter.bandpass(900, q: 1.5)],
          gain: 0.25,
          lfo: AmbientLfo(rateHz: 0.09, depth: 0.9, filterSweepHz: 500),
          width: 1.0,
        ),
        NoiseLayer(
          color: NoiseColor.brown,
          filters: [AmbientFilter.lowpass(150)],
          gain: 0.3,
          lfo: AmbientLfo(rateHz: 0.03, depth: 0.5),
        ),
        NoiseLayer(
          color: NoiseColor.white,
          filters: [AmbientFilter.highpass(2500)],
          gain: 0.05,
          lfo: AmbientLfo(rateHz: 0.07, depth: 0.9),
          width: 1.0,
        ),
      ],
      events: [
        EventLayer.burst(
          ratePerSecond: 0.07,
          minGapSeconds: 5,
          minDurationSeconds: 5,
          maxDurationSeconds: 9,
          attackRatio: 0.45,
          gain: 0.6,
          gainJitter: 0.4,
          panSpread: 0.7,
          minFrequency: 500,
          maxFrequency: 1200,
          sweepRatio: 0.6,
          color: NoiseColor.pink,
          q: 1.2,
        ),
      ],
      masterGain: 2.5,
    ),
  ),
  FocusSoundscape(
    id: 'fireplace_glow',
    name: '壁炉',
    nameEn: 'Fireplace',
    icon: '🔥',
    description: '低沉炉火、细碎噼啪和偶尔一声木柴爆裂，适合夜晚',
    category: FocusSoundCategory.nature,
    recipe: AmbientRecipe(
      noise: [
        NoiseLayer(
          color: NoiseColor.brown,
          filters: [AmbientFilter.lowpass(250)],
          gain: 0.45,
          lfo: AmbientLfo(rateHz: 0.09, depth: 0.5),
        ),
        NoiseLayer(
          color: NoiseColor.pink,
          filters: [AmbientFilter.bandpass(1500, q: 0.6)],
          gain: 0.12,
          lfo: AmbientLfo(rateHz: 0.35, depth: 0.6, filterSweepHz: 500),
          width: 1.0,
        ),
      ],
      events: [
        EventLayer.burst(
          ratePerSecond: 6,
          minDurationSeconds: 0.004,
          maxDurationSeconds: 0.02,
          attackRatio: 0.05,
          gain: 0.5,
          gainJitter: 0.85,
          panSpread: 0.8,
          minFrequency: 2500,
          maxFrequency: 7000,
          q: 1.2,
        ),
        EventLayer.burst(
          ratePerSecond: 0.5,
          minDurationSeconds: 0.04,
          maxDurationSeconds: 0.12,
          gain: 0.45,
          gainJitter: 0.6,
          panSpread: 0.7,
          minFrequency: 350,
          maxFrequency: 900,
          sweepRatio: 0.5,
          color: NoiseColor.pink,
          q: 1.5,
        ),
        EventLayer.burst(
          ratePerSecond: 0.3,
          minDurationSeconds: 0.5,
          maxDurationSeconds: 1.5,
          attackRatio: 0.3,
          gain: 0.08,
          gainJitter: 0.5,
          panSpread: 0.6,
          minFrequency: 4000,
          maxFrequency: 6000,
          filterType: AmbientFilterType.highpass,
          q: 0.7,
        ),
      ],
      masterGain: 2.6,
    ),
  ),
  FocusSoundscape(
    id: 'night_crickets',
    name: '夏夜虫鸣',
    nameEn: 'Night Crickets',
    icon: '🌙',
    description: '安静夜色里两种节奏的蟋蟀此起彼伏，适合独处时使用',
    category: FocusSoundCategory.nature,
    recipe: AmbientRecipe(
      noise: [
        NoiseLayer(
          color: NoiseColor.brown,
          filters: [AmbientFilter.lowpass(220)],
          gain: 0.18,
          lfo: AmbientLfo(rateHz: 0.02, depth: 0.4),
        ),
        NoiseLayer(
          color: NoiseColor.pink,
          filters: [AmbientFilter.bandpass(3000, q: 0.5)],
          gain: 0.03,
          width: 1.0,
        ),
      ],
      events: [
        EventLayer.tone(
          ratePerSecond: 1.6,
          minGapSeconds: 0.25,
          minDurationSeconds: 0.35,
          maxDurationSeconds: 0.7,
          attackRatio: 0.1,
          gain: 0.09,
          gainJitter: 0.5,
          panSpread: 1.0,
          minFrequency: 4100,
          maxFrequency: 4400,
          partials: [TonePartial(1, 1), TonePartial(2, 0.08)],
          trillHz: 32,
        ),
        EventLayer.tone(
          ratePerSecond: 0.9,
          minGapSeconds: 0.3,
          minDurationSeconds: 0.5,
          maxDurationSeconds: 1.0,
          attackRatio: 0.1,
          gain: 0.06,
          gainJitter: 0.5,
          panSpread: 1.0,
          minFrequency: 3300,
          maxFrequency: 3600,
          trillHz: 22,
        ),
        EventLayer.burst(
          ratePerSecond: 0.5,
          minDurationSeconds: 0.02,
          maxDurationSeconds: 0.05,
          gain: 0.05,
          gainJitter: 0.6,
          panSpread: 1.0,
          minFrequency: 5000,
          maxFrequency: 7000,
          q: 2.0,
        ),
      ],
      masterGain: 4.0,
    ),
  ),
  // ---------------------------------------------------------------- 噪音
  FocusSoundscape(
    id: 'white_noise',
    name: '白噪音',
    nameEn: 'White Noise',
    icon: '📻',
    description: '最亮、最均匀的遮罩，办公室和人声环境首选',
    category: FocusSoundCategory.noise,
    recipe: AmbientRecipe(
      noise: [
        NoiseLayer(
          color: NoiseColor.white,
          filters: [AmbientFilter.lowpass(12000, q: 0.5)],
          gain: 0.5,
          width: 1.0,
        ),
      ],
      masterGain: 0.8,
    ),
  ),
  FocusSoundscape(
    id: 'pink_noise',
    name: '粉噪音',
    nameEn: 'Pink Noise',
    icon: '🌸',
    description: '每个八度能量相同，像远处瀑布，久听不累',
    category: FocusSoundCategory.noise,
    recipe: AmbientRecipe(
      noise: [NoiseLayer(color: NoiseColor.pink, gain: 0.6, width: 1.0)],
      masterGain: 0.8,
    ),
  ),
  FocusSoundscape(
    id: 'brown_noise',
    name: '棕噪音',
    nameEn: 'Brown Noise',
    icon: '🟤',
    description: '低频最厚，像机舱或远处的瀑布，最适合深度沉浸',
    category: FocusSoundCategory.noise,
    recipe: AmbientRecipe(
      noise: [
        NoiseLayer(
          color: NoiseColor.brown,
          filters: [AmbientFilter.highpass(30)],
          gain: 0.9,
          lfo: AmbientLfo(rateHz: 0.02, depth: 0.15),
          width: 1.0,
        ),
      ],
      masterGain: 0.85,
    ),
  ),
  FocusSoundscape(
    id: 'box_fan',
    name: '风扇',
    nameEn: 'Box Fan',
    icon: '🌀',
    description: '带一点电机嗡鸣的风扇声，比纯噪音更有房间感',
    category: FocusSoundCategory.noise,
    recipe: AmbientRecipe(
      noise: [
        NoiseLayer(
          color: NoiseColor.brown,
          filters: [AmbientFilter.bandpass(220, q: 0.6)],
          gain: 0.7,
          lfo: AmbientLfo(rateHz: 0.25, depth: 0.12),
          width: 0.6,
        ),
        NoiseLayer(
          color: NoiseColor.pink,
          filters: [AmbientFilter.lowpass(2500)],
          gain: 0.25,
          width: 1.0,
        ),
      ],
      tones: [
        ToneLayer(
          frequency: 120,
          partials: [
            TonePartial(1, 1),
            TonePartial(2, 0.5),
            TonePartial(3, 0.2),
          ],
          gain: 0.05,
          detuneCents: 3,
          tremoloRateHz: 0.4,
          tremoloDepth: 0.2,
        ),
      ],
      masterGain: 1.15,
    ),
  ),
  // ---------------------------------------------------------------- 氛围
  FocusSoundscape(
    id: 'cafe_hum',
    name: '咖啡馆',
    nameEn: 'Cafe Murmur',
    icon: '☕',
    description: '听不清内容的低语、杯碟轻碰和偶尔的椅子声，模拟陪伴感',
    category: FocusSoundCategory.ambience,
    recipe: AmbientRecipe(
      noise: [
        NoiseLayer(
          color: NoiseColor.pink,
          filters: [AmbientFilter.bandpass(320, q: 1.4)],
          gain: 0.4,
          lfo: AmbientLfo(rateHz: 0.6, depth: 0.6, filterSweepHz: 120),
          width: 0.9,
        ),
        NoiseLayer(
          color: NoiseColor.pink,
          filters: [AmbientFilter.bandpass(850, q: 1.8)],
          gain: 0.22,
          lfo: AmbientLfo(rateHz: 0.43, depth: 0.75, filterSweepHz: 300),
          width: 1.0,
        ),
        NoiseLayer(
          color: NoiseColor.brown,
          filters: [AmbientFilter.lowpass(180)],
          gain: 0.28,
          lfo: AmbientLfo(rateHz: 0.05, depth: 0.3),
        ),
        NoiseLayer(
          color: NoiseColor.white,
          filters: [AmbientFilter.highpass(4000)],
          gain: 0.02,
          width: 1.0,
        ),
      ],
      events: [
        EventLayer.burst(
          ratePerSecond: 2.5,
          minDurationSeconds: 0.12,
          maxDurationSeconds: 0.3,
          attackRatio: 0.3,
          gain: 0.18,
          gainJitter: 0.7,
          panSpread: 0.9,
          minFrequency: 250,
          maxFrequency: 700,
          sweepRatio: 0.8,
          color: NoiseColor.pink,
          q: 3.0,
        ),
        EventLayer.tone(
          ratePerSecond: 0.12,
          minGapSeconds: 2,
          minDurationSeconds: 0.15,
          maxDurationSeconds: 0.45,
          attackRatio: 0.01,
          gain: 0.12,
          gainJitter: 0.6,
          panSpread: 1.0,
          minFrequency: 2400,
          maxFrequency: 4200,
          partials: [
            TonePartial(1, 1),
            TonePartial(2.76, 0.4),
            TonePartial(5.4, 0.15),
          ],
        ),
        EventLayer.burst(
          ratePerSecond: 0.09,
          minDurationSeconds: 0.08,
          maxDurationSeconds: 0.2,
          gain: 0.6,
          gainJitter: 0.5,
          panSpread: 0.8,
          minFrequency: 120,
          maxFrequency: 220,
          color: NoiseColor.brown,
          filterType: AmbientFilterType.lowpass,
          q: 0.8,
        ),
        EventLayer.burst(
          ratePerSecond: 0.02,
          minGapSeconds: 25,
          minDurationSeconds: 2,
          maxDurationSeconds: 4,
          attackRatio: 0.2,
          gain: 0.06,
          gainJitter: 0.3,
          panSpread: 0.6,
          minFrequency: 3000,
          maxFrequency: 4000,
          filterType: AmbientFilterType.highpass,
          q: 0.7,
        ),
      ],
      masterGain: 2.8,
    ),
  ),
  FocusSoundscape(
    id: 'library_air',
    name: '图书馆',
    nameEn: 'Library',
    icon: '📚',
    description: '空调低鸣、纸页翻动和很远的椅子声，几乎安静',
    category: FocusSoundCategory.ambience,
    recipe: AmbientRecipe(
      noise: [
        NoiseLayer(
          color: NoiseColor.brown,
          filters: [AmbientFilter.lowpass(140)],
          gain: 0.3,
          lfo: AmbientLfo(rateHz: 0.04, depth: 0.2),
        ),
        NoiseLayer(
          color: NoiseColor.pink,
          filters: [AmbientFilter.lowpass(1200)],
          gain: 0.1,
          lfo: AmbientLfo(rateHz: 0.03, depth: 0.3),
          width: 1.0,
        ),
      ],
      tones: [
        ToneLayer(
          frequency: 100,
          partials: [TonePartial(1, 1), TonePartial(2, 0.3)],
          gain: 0.02,
          detuneCents: 2,
        ),
      ],
      events: [
        EventLayer.burst(
          ratePerSecond: 0.07,
          minGapSeconds: 4,
          minDurationSeconds: 0.12,
          maxDurationSeconds: 0.3,
          gain: 0.12,
          gainJitter: 0.5,
          panSpread: 1.0,
          minFrequency: 1500,
          maxFrequency: 3500,
          sweepRatio: 1.5,
          q: 0.8,
        ),
        EventLayer.burst(
          ratePerSecond: 0.05,
          minDurationSeconds: 0.01,
          maxDurationSeconds: 0.03,
          gain: 0.08,
          gainJitter: 0.5,
          panSpread: 1.0,
          minFrequency: 3000,
          maxFrequency: 6000,
        ),
        EventLayer.burst(
          ratePerSecond: 0.03,
          minDurationSeconds: 0.1,
          maxDurationSeconds: 0.25,
          gain: 0.4,
          gainJitter: 0.5,
          panSpread: 0.8,
          minFrequency: 150,
          maxFrequency: 250,
          color: NoiseColor.brown,
          filterType: AmbientFilterType.lowpass,
          q: 0.8,
        ),
      ],
      masterGain: 2.8,
    ),
  ),
  FocusSoundscape(
    id: 'deep_space',
    name: '深空音垫',
    nameEn: 'Deep Drone',
    icon: '🪐',
    description: '缓慢呼吸的低音音垫，带轻微合唱式漂移，适合超长专注',
    category: FocusSoundCategory.ambience,
    recipe: AmbientRecipe(
      noise: [
        NoiseLayer(
          color: NoiseColor.pink,
          filters: [AmbientFilter.lowpass(600)],
          gain: 0.12,
          lfo: AmbientLfo(rateHz: 0.03, depth: 0.5, filterSweepHz: 300),
          width: 1.0,
        ),
        NoiseLayer(
          color: NoiseColor.brown,
          filters: [AmbientFilter.lowpass(90)],
          gain: 0.15,
          lfo: AmbientLfo(rateHz: 0.017, depth: 0.5),
        ),
      ],
      tones: [
        ToneLayer(
          frequency: 55,
          partials: [
            TonePartial(1, 1),
            TonePartial(2, 0.6),
            TonePartial(3, 0.3),
            TonePartial(4, 0.15),
          ],
          gain: 0.12,
          detuneCents: 4,
          tremoloRateHz: 0.05,
          tremoloDepth: 0.3,
        ),
        ToneLayer(
          frequency: 82.4,
          partials: [TonePartial(1, 0.8), TonePartial(2, 0.4)],
          gain: 0.06,
          detuneCents: 5,
          tremoloRateHz: 0.037,
          tremoloDepth: 0.4,
          pan: -0.35,
        ),
        ToneLayer(
          frequency: 220,
          gain: 0.02,
          detuneCents: 7,
          tremoloRateHz: 0.08,
          tremoloDepth: 0.6,
          pan: 0.4,
        ),
      ],
      events: [
        EventLayer.burst(
          ratePerSecond: 0.04,
          minGapSeconds: 8,
          minDurationSeconds: 6,
          maxDurationSeconds: 12,
          attackRatio: 0.5,
          gain: 0.12,
          gainJitter: 0.4,
          panSpread: 0.8,
          minFrequency: 800,
          maxFrequency: 1600,
          sweepRatio: 0.6,
          color: NoiseColor.pink,
          q: 2.0,
        ),
      ],
      masterGain: 2.8,
    ),
  ),
  FocusSoundscape(
    id: 'binaural_focus',
    name: '双耳专注',
    nameEn: 'Binaural Focus',
    icon: '🎧',
    description: '左右耳相差 10Hz 的柔和载波（α 节律），需戴耳机，配少量粉噪遮罩',
    category: FocusSoundCategory.ambience,
    recipe: AmbientRecipe(
      noise: [
        NoiseLayer(
          color: NoiseColor.pink,
          filters: [AmbientFilter.lowpass(1000)],
          gain: 0.12,
          lfo: AmbientLfo(rateHz: 0.03, depth: 0.3),
          width: 1.0,
        ),
        NoiseLayer(
          color: NoiseColor.brown,
          filters: [AmbientFilter.lowpass(120)],
          gain: 0.12,
        ),
      ],
      tones: [ToneLayer(frequency: 200, gain: 0.10, binauralBeatHz: 10)],
      masterGain: 1.15,
    ),
  ),
];

/// Ids of soundscapes that were retired. Old preferences and history records
/// keep resolving to the closest surviving sound.
const Map<String, String> _legacyFocusSoundAliases = {
  'meditation_drone': 'deep_space',
  'cave_drip': 'stream_flow',
  'train_cabin': 'box_fan',
  'study_lofi': 'cafe_hum',
  'piano_mist': 'deep_space',
};

FocusSoundscape? findFocusSoundscapeById(String id) {
  final resolvedId = _legacyFocusSoundAliases[id] ?? id;
  for (final soundscape in focusSoundscapes) {
    if (soundscape.id == resolvedId) {
      return soundscape;
    }
  }
  return null;
}

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
    id: 'gentle_study',
    name: '45 分钟',
    emoji: '📚',
    description: '适合阅读、写作和中等长度的专注',
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
    name: '25 分钟',
    emoji: '🍅',
    description: '短周期专注，适合快速推进一件事',
    focusDurationMinutes: 25,
    breakDurationMinutes: 5,
    microRestSeconds: 10,
    minIntervalMinutes: 3,
    maxIntervalMinutes: 4,
    focusSoundEnabled: true,
    randomFocusSoundMode: false,
    selectedFocusSoundId: 'deep_space',
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
