import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/sound_data.dart';
import '../../../core/theme/color_schemes.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/storage_service.dart';
import '../../timer/providers/settings_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final storage = ref.read(storageServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSectionHeader('提示音', theme),
          _buildSoundSelector(storage, theme),
          _buildSwitchTile('随机提示音', '每次随机播放不同的提示音', storage.randomSoundMode, (
            v,
          ) {
            storage.setRandomSoundMode(v);
            setState(() {});
          }, theme),
          _buildSliderTile('提示音音量', storage.alertVolume, (v) {
            storage.setAlertVolume(v);
            setState(() {});
          }, theme),

          const Divider(height: 32),
          _buildSectionHeader('专注背景音', theme),
          _buildSwitchTile(
            '开始专注时播放背景音',
            '播放循环的专注声音，暂停或休息时会自动停止',
            storage.focusSoundEnabled,
            (v) {
              storage.setFocusSoundEnabled(v);
              if (!v) {
                ref.read(audioServiceProvider).stopAmbient();
              }
              setState(() {});
            },
            theme,
          ),
          if (storage.focusSoundEnabled) ...[
            _buildFocusSoundSelector(storage, theme),
            _buildSwitchTile(
              '随机专注背景音',
              '每次开始专注时，随机选择一种专注背景音',
              storage.randomFocusSoundMode,
              (v) {
                storage.setRandomFocusSoundMode(v);
                setState(() {});
              },
              theme,
            ),
            _buildSliderTile('背景音音量', storage.focusSoundVolume, (v) {
              storage.setFocusSoundVolume(v);
              ref.read(audioServiceProvider).setAmbientVolume(v);
              setState(() {});
            }, theme),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Icon(
                  Icons.stop_circle_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('停止试听'),
                subtitle: const Text('停止当前正在试听的专注背景音'),
                onTap: () {
                  ref.read(audioServiceProvider).stopAmbient();
                },
              ),
            ),
          ],

          const Divider(height: 32),
          _buildSectionHeader('时间参数', theme),
          _buildRangeSelector(
            '专注时长',
            '${storage.focusDuration} 分钟',
            storage.focusDuration.toDouble(),
            AppConstants.minFocusDuration.toDouble(),
            AppConstants.maxFocusDuration.toDouble(),
            (v) {
              storage.setFocusDuration(v.round());
              setState(() {});
            },
            theme,
          ),
          _buildRangeSelector(
            '大休息时长',
            '${storage.breakDuration} 分钟',
            storage.breakDuration.toDouble(),
            AppConstants.minBreakDuration.toDouble(),
            AppConstants.maxBreakDuration.toDouble(),
            (v) {
              storage.setBreakDuration(v.round());
              setState(() {});
            },
            theme,
          ),
          _buildRangeSelector(
            '微休息时长',
            '${storage.microRestSeconds} 秒',
            storage.microRestSeconds.toDouble(),
            AppConstants.minMicroRestSeconds.toDouble(),
            AppConstants.maxMicroRestSeconds.toDouble(),
            (v) {
              storage.setMicroRestSeconds(v.round());
              setState(() {});
            },
            theme,
          ),
          _buildIntervalSelector(storage, theme),

          const Divider(height: 32),
          _buildSectionHeader('外观', theme),
          _buildThemeModeSelector(theme),
          _buildColorSchemeSelector(theme),

          const Divider(height: 32),
          _buildSectionHeader('其他', theme),
          _buildSwitchTile('震动反馈', '铃声响起时震动提醒', storage.vibrationEnabled, (v) {
            storage.setVibrationEnabled(v);
            setState(() {});
          }, theme),
          _buildSwitchTile('科学小贴士', '微休息时显示神经科学小知识', storage.showScienceTips, (
            v,
          ) {
            storage.setShowScienceTips(v);
            setState(() {});
          }, theme),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSoundSelector(StorageService storage, ThemeData theme) {
    final selectedId = storage.selectedSoundId;
    final audio = ref.read(audioServiceProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          Icons.music_note_rounded,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          builtInSounds
              .firstWhere(
                (s) => s.id == selectedId,
                orElse: () => builtInSounds.first,
              )
              .name,
        ),
        subtitle: const Text('点击展开选择提示音'),
        children: [
          for (final category in SoundCategory.values) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '${category.label} · ${category.description}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...builtInSounds
                .where((s) => s.category == category)
                .map(
                  (sound) => ListTile(
                    dense: true,
                    leading: Icon(
                      sound.id == selectedId
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: sound.id == selectedId
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      storage.setSelectedSoundId(sound.id);
                      setState(() {});
                    },
                    title: Text(sound.name),
                    subtitle: Text(sound.nameEn),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      onPressed: () {
                        audio.playBuiltInSound(
                          sound,
                          volume: storage.alertVolume,
                        );
                      },
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildFocusSoundSelector(StorageService storage, ThemeData theme) {
    final selectedId = storage.selectedFocusSoundId;
    final audio = ref.read(audioServiceProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          Icons.headphones_rounded,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          focusSoundscapes
              .firstWhere(
                (soundscape) => soundscape.id == selectedId,
                orElse: () => focusSoundscapes.first,
              )
              .name,
        ),
        subtitle: const Text('点击展开选择专注背景音'),
        children: [
          for (final category in FocusSoundCategory.values) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '${category.label} · ${category.description}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...focusSoundscapes
                .where((soundscape) => soundscape.category == category)
                .map(
                  (soundscape) => ListTile(
                    dense: true,
                    leading: Icon(
                      soundscape.id == selectedId
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: soundscape.id == selectedId
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      storage.setSelectedFocusSoundId(soundscape.id);
                      setState(() {});
                    },
                    title: Text(soundscape.name),
                    subtitle: Text(soundscape.description),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      onPressed: () {
                        audio.playFocusSoundscape(
                          soundscape,
                          volume: storage.focusSoundVolume,
                        );
                      },
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    double value,
    ValueChanged<double> onChanged,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(title),
        subtitle: Slider(
          value: value,
          min: 0,
          max: 1,
          divisions: 10,
          label: '${(value * 100).round()}%',
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildRangeSelector(
    String title,
    String valueText,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(
              valueText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        subtitle: Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildIntervalSelector(StorageService storage, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('随机铃声间隔'),
            Text(
              '${storage.minInterval}~${storage.maxInterval} 分钟',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        subtitle: RangeSlider(
          values: RangeValues(
            storage.minInterval.toDouble(),
            storage.maxInterval.toDouble(),
          ),
          min: AppConstants.minIntervalMinutes.toDouble(),
          max: AppConstants.maxIntervalMinutes.toDouble(),
          divisions:
              AppConstants.maxIntervalMinutes - AppConstants.minIntervalMinutes,
          labels: RangeLabels(
            '${storage.minInterval}分钟',
            '${storage.maxInterval}分钟',
          ),
          onChanged: (values) {
            storage.setMinInterval(values.start.round());
            storage.setMaxInterval(values.end.round());
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildThemeModeSelector(ThemeData theme) {
    final currentMode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          Icons.brightness_6_rounded,
          color: theme.colorScheme.primary,
        ),
        title: const Text('主题模式'),
        trailing: SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.auto_mode)),
            ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode)),
            ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
          ],
          selected: {currentMode},
          onSelectionChanged: (s) => notifier.setMode(s.first),
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),
      ),
    );
  }

  Widget _buildColorSchemeSelector(ThemeData theme) {
    final currentScheme = ref.watch(colorSchemeProvider);
    final notifier = ref.read(colorSchemeProvider.notifier);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(Icons.palette_rounded, color: theme.colorScheme.primary),
        title: const Text('配色方案'),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Wrap(
            spacing: 8,
            children: appColorSchemes.map((scheme) {
              final isSelected = scheme.id == currentScheme.id;
              return GestureDetector(
                onTap: () => notifier.setScheme(scheme),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.onSurface,
                            width: 3,
                          )
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
