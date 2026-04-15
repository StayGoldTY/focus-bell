import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/sound_data.dart';
import '../../../core/models/focus_backup_payload.dart';
import '../../../core/theme/color_schemes.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/focus_backup_file_service.dart';
import '../../../shared/services/storage_service.dart';
import '../../timer/models/timer_state.dart';
import '../../timer/providers/focus_session_draft_provider.dart';
import '../../timer/providers/settings_provider.dart';
import '../../timer/providers/timer_provider.dart';

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
    final timerState = ref.watch(timerProvider);
    final dataActionsLocked = timerState.phase != TimerPhase.idle;
    final timerNotifier = ref.read(timerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSectionHeader('提示音', theme),
          _buildSoundSelector(storage, theme),
          _buildSwitchTile(
            '随机提示音',
            '每次提醒时随机播放不同的提示音',
            storage.randomSoundMode,
            (value) async {
              await storage.setRandomSoundMode(value);
              setState(() {});
            },
          ),
          _buildSliderTile(
            title: '提示音音量',
            value: storage.alertVolume,
            onChanged: (value) async {
              await storage.setAlertVolume(value);
              await ref.read(audioServiceProvider).setAlertVolume(value);
              setState(() {});
            },
          ),
          const Divider(height: 32),
          _buildSectionHeader('专注预设', theme),
          _buildFocusPresetSelector(storage, theme),
          const Divider(height: 32),
          _buildSectionHeader('专注背景音', theme),
          _buildSwitchTile(
            '开始专注时播放背景音',
            '播放循环的专注声音，暂停或休息时会自动停止',
            storage.focusSoundEnabled,
            (value) async {
              _markPresetCustom(storage);
              await storage.setFocusSoundEnabled(value);
              timerNotifier.syncCurrentFocusSoundFromSettings();
              if (!value) {
                await ref.read(audioServiceProvider).stopAmbient();
              }
              setState(() {});
            },
          ),
          if (storage.focusSoundEnabled) ...[
            _buildFocusSoundSelector(
              storage,
              theme,
              timerState.phase == TimerPhase.focusing,
            ),
            _buildSwitchTile(
              '随机专注背景音',
              '每次开始专注时自动随机选择一种背景音',
              storage.randomFocusSoundMode,
              (value) async {
                _markPresetCustom(storage);
                await storage.setRandomFocusSoundMode(value);
                timerNotifier.syncCurrentFocusSoundFromSettings();
                setState(() {});
              },
            ),
            _buildSliderTile(
              title: '背景音音量',
              value: storage.focusSoundVolume,
              onChanged: (value) async {
                await storage.setFocusSoundVolume(value);
                await ref.read(audioServiceProvider).setAmbientVolume(value);
                setState(() {});
              },
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Icon(
                  Icons.stop_circle_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('停止试听'),
                subtitle: const Text('停止当前正在试听的专注背景音'),
                onTap: () async {
                  await ref.read(audioServiceProvider).stopAmbient();
                },
              ),
            ),
          ],
          const Divider(height: 32),
          _buildSectionHeader('时间参数', theme),
          _buildRangeSelector(
            title: '专注时长',
            valueText: '${storage.focusDuration} 分钟',
            value: storage.focusDuration.toDouble(),
            min: AppConstants.minFocusDuration.toDouble(),
            max: AppConstants.maxFocusDuration.toDouble(),
            onChanged: (value) async {
              _markPresetCustom(storage);
              await storage.setFocusDuration(value.round());
              setState(() {});
            },
          ),
          _buildRangeSelector(
            title: '深度休息时长',
            valueText: '${storage.breakDuration} 分钟',
            value: storage.breakDuration.toDouble(),
            min: AppConstants.minBreakDuration.toDouble(),
            max: AppConstants.maxBreakDuration.toDouble(),
            onChanged: (value) async {
              _markPresetCustom(storage);
              await storage.setBreakDuration(value.round());
              setState(() {});
            },
          ),
          _buildRangeSelector(
            title: '微休息时长',
            valueText: '${storage.microRestSeconds} 秒',
            value: storage.microRestSeconds.toDouble(),
            min: AppConstants.minMicroRestSeconds.toDouble(),
            max: AppConstants.maxMicroRestSeconds.toDouble(),
            onChanged: (value) async {
              _markPresetCustom(storage);
              await storage.setMicroRestSeconds(value.round());
              setState(() {});
            },
          ),
          _buildIntervalSelector(storage, theme),
          _buildRangeSelector(
            title: '每日目标',
            valueText: '${storage.dailyGoalMinutes} 分钟',
            value: storage.dailyGoalMinutes.toDouble(),
            min: AppConstants.minDailyGoalMinutes.toDouble(),
            max: AppConstants.maxDailyGoalMinutes.toDouble(),
            onChanged: (value) async {
              await storage.setDailyGoalMinutes(value.round());
              setState(() {});
            },
          ),
          const Divider(height: 32),
          _buildSectionHeader('外观', theme),
          _buildThemeModeSelector(theme),
          _buildColorSchemeSelector(theme),
          const Divider(height: 32),
          _buildSectionHeader('其他', theme),
          _buildSwitchTile('震动反馈', '提示音响起时提供轻微反馈', storage.vibrationEnabled, (
            value,
          ) async {
            await storage.setVibrationEnabled(value);
            setState(() {});
          }),
          _buildSwitchTile(
            '科学小贴士',
            '微休息时显示神经科学相关的小提示',
            storage.showScienceTips,
            (value) async {
              await storage.setShowScienceTips(value);
              setState(() {});
            },
          ),
          const Divider(height: 32),
          _buildSectionHeader('数据管理', theme),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.download_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('导出备份'),
                  subtitle: const Text('导出当前设置、统计数据和历史记录为 JSON 文件'),
                  onTap: _handleExportBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.upload_file_rounded,
                    color: dataActionsLocked
                        ? theme.colorScheme.outline
                        : theme.colorScheme.primary,
                  ),
                  title: const Text('导入备份'),
                  subtitle: Text(
                    dataActionsLocked ? '请先结束当前专注，再导入备份' : '导入后会覆盖当前本地设置和历史记录',
                  ),
                  enabled: !dataActionsLocked,
                  onTap: dataActionsLocked ? null : _handleImportBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: dataActionsLocked
                        ? theme.colorScheme.outline
                        : theme.colorScheme.error,
                  ),
                  title: const Text('清空历史'),
                  subtitle: Text(
                    dataActionsLocked
                        ? '请先结束当前专注，再清空历史数据'
                        : '会清空历史记录与累计统计，无法撤销',
                  ),
                  enabled: !dataActionsLocked,
                  onTap: dataActionsLocked ? null : _handleClearHistory,
                ),
              ],
            ),
          ),
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
                (sound) => sound.id == selectedId,
                orElse: () => builtInSounds.first,
              )
              .name,
        ),
        subtitle: const Text('点击展开并试听提示音'),
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
                .where((sound) => sound.category == category)
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
                    title: Text(sound.name),
                    subtitle: Text(sound.nameEn),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      onPressed: () async {
                        await audio.playBuiltInSound(
                          sound,
                          volume: storage.alertVolume,
                        );
                      },
                    ),
                    onTap: () async {
                      await storage.setSelectedSoundId(sound.id);
                      setState(() {});
                    },
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildFocusSoundSelector(
    StorageService storage,
    ThemeData theme,
    bool isFocusing,
  ) {
    final selectedId = storage.selectedFocusSoundId;
    final audio = ref.read(audioServiceProvider);
    final timerNotifier = ref.read(timerProvider.notifier);

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
        subtitle: const Text('点击展开并试听专注背景音'),
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
                    title: Text(soundscape.name),
                    subtitle: Text(soundscape.description),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      onPressed: () async {
                        await audio.playFocusSoundscape(
                          soundscape,
                          volume: storage.focusSoundVolume,
                        );
                      },
                    ),
                    onTap: () async {
                      _markPresetCustom(storage);
                      await storage.setRandomFocusSoundMode(false);
                      await storage.setSelectedFocusSoundId(soundscape.id);
                      timerNotifier.syncCurrentFocusSoundFromSettings();
                      if (!isFocusing) {
                        await audio.playFocusSoundscape(
                          soundscape,
                          volume: storage.focusSoundVolume,
                        );
                      }
                      setState(() {});
                    },
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildFocusPresetSelector(StorageService storage, ThemeData theme) {
    final selectedPresetId = storage.selectedFocusPresetId;
    final selectedPreset = findFocusPresetById(selectedPresetId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.auto_awesome_rounded,
              color: theme.colorScheme.primary,
            ),
            title: Text(selectedPreset?.name ?? '自定义方案'),
            subtitle: Text(selectedPreset?.description ?? '你已经对预设做了个性化调整'),
          ),
          const Divider(height: 1),
          ...focusPresets.map((preset) {
            final isSelected = preset.id == selectedPresetId;
            return ListTile(
              leading: Text(preset.emoji, style: const TextStyle(fontSize: 20)),
              title: Text(preset.name),
              subtitle: Text(
                '${preset.description}\n'
                '${preset.focusDurationMinutes}/${preset.breakDurationMinutes} 分钟 · 微休息 ${preset.microRestSeconds} 秒',
              ),
              isThreeLine: true,
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: theme.colorScheme.primary,
                    )
                  : const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                await storage.applyFocusPreset(preset);
                await ref.read(audioServiceProvider).stopAmbient();
                setState(() {});
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
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

  Widget _buildSliderTile({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
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

  Widget _buildRangeSelector({
    required String title,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
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
            const Text('随机提醒间隔'),
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
            '${storage.minInterval} 分钟',
            '${storage.maxInterval} 分钟',
          ),
          onChanged: (values) async {
            _markPresetCustom(storage);
            await storage.setMinInterval(values.start.round());
            await storage.setMaxInterval(values.end.round());
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
          onSelectionChanged: (selection) => notifier.setMode(selection.first),
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

  Future<void> _handleExportBackup() async {
    final storage = ref.read(storageServiceProvider);
    final backup = storage.exportBackup();
    final date = DateTime.now();
    final fileName =
        'focus-bell-backup-${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}.json';

    try {
      await downloadBackupFile(fileName, backup.toJsonString());
      _showMessage('备份文件已经开始下载。');
    } on UnsupportedError catch (_) {
      _showMessage('当前平台暂不支持浏览器式导出，请在 Web 版本中使用。');
    } catch (_) {
      _showMessage('导出失败，请稍后重试。');
    }
  }

  Future<void> _handleImportBackup() async {
    final shouldImport = await _confirmAction(
      title: '导入备份',
      content: '导入后会覆盖当前本地设置、统计和历史记录，是否继续？',
      confirmText: '确认导入',
    );
    if (!shouldImport) {
      return;
    }

    try {
      final raw = await pickBackupFileText();
      if (raw == null || raw.trim().isEmpty) {
        return;
      }

      final payload = FocusBackupPayload.fromJsonString(raw);
      await ref.read(audioServiceProvider).stopAll();
      await ref.read(storageServiceProvider).restoreBackup(payload);
      ref.read(focusSessionDraftProvider.notifier).clear();
      ref.invalidate(themeModeProvider);
      ref.invalidate(colorSchemeProvider);
      ref.invalidate(timerProvider);
      if (!mounted) {
        return;
      }
      setState(() {});
      _showMessage('备份已导入，本地数据已经恢复。');
    } on FormatException catch (_) {
      _showMessage('备份文件格式不正确，未覆盖当前数据。');
    } on UnsupportedError catch (_) {
      _showMessage('当前平台暂不支持浏览器式导入，请在 Web 版本中使用。');
    } catch (_) {
      _showMessage('导入失败，当前数据没有被修改。');
    }
  }

  Future<void> _handleClearHistory() async {
    final confirmed = await _confirmAction(
      title: '清空历史',
      content: '这会清空历史记录和累计统计，操作无法撤销，是否继续？',
      confirmText: '确认清空',
    );
    if (!confirmed) {
      return;
    }

    await ref.read(storageServiceProvider).clearHistoryOnly();
    ref.read(focusSessionDraftProvider.notifier).clear();
    ref.invalidate(timerProvider);
    if (!mounted) {
      return;
    }
    setState(() {});
    _showMessage('历史记录和累计统计已清空。');
  }

  Future<bool> _confirmAction({
    required String title,
    required String content,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _markPresetCustom(StorageService storage) {
    if (storage.selectedFocusPresetId != customFocusPresetId) {
      storage.markFocusPresetCustom();
    }
  }
}
