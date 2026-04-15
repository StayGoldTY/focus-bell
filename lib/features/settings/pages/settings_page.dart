import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/sound_data.dart';
import '../../../core/models/focus_backup_payload.dart';
import '../../../core/models/focus_external_sound.dart';
import '../../../core/theme/color_schemes.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/focus_backup_file_service.dart';
import '../../../shared/services/sound_api_service.dart';
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
  final ExpansibleController _focusPresetController = ExpansibleController();
  final TextEditingController _freesoundApiKeyController =
      TextEditingController();
  final TextEditingController _soundscapeApiKeyController =
      TextEditingController();
  final TextEditingController _freesoundQueryController = TextEditingController(
    text: 'rain ambience',
  );

  bool _focusPresetExpanded = false;
  bool _isSearchingFreesound = false;
  bool _isLoadingSoundscape = false;
  List<FreesoundResult> _freesoundResults = const [];
  String? _freesoundStatus;
  String? _soundscapeStatus;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(storageServiceProvider);
    _freesoundApiKeyController.text = storage.freesoundApiKey;
    _soundscapeApiKeyController.text = storage.soundscapeApiKey;
  }

  @override
  void dispose() {
    _focusPresetController.dispose();
    _freesoundApiKeyController.dispose();
    _soundscapeApiKeyController.dispose();
    _freesoundQueryController.dispose();
    super.dispose();
  }

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
          _buildSectionHeader('专注方案', theme),
          _buildFocusPresetSelector(
            storage,
            theme,
            timerState.phase == TimerPhase.focusing,
          ),
          const Divider(height: 32),
          _buildSectionHeader('专注背景音', theme),
          _buildSwitchTile(
            '开始专注时播放背景音',
            '播放循环的专注背景音，暂停或休息时会自动停止',
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
            if (storage.focusSoundSourceType == FocusSoundSourceType.builtIn)
              _buildSwitchTile(
                '随机专注背景音',
                '每次开始专注时自动随机选择一种内置背景音',
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
          _buildSwitchTile('振动反馈', '提示音响起时提供轻微振动反馈', storage.vibrationEnabled, (
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
    final selectedSound = builtInSounds.firstWhere(
      (sound) => sound.id == selectedId,
      orElse: () => builtInSounds.first,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          Icons.music_note_rounded,
          color: theme.colorScheme.primary,
        ),
        title: Text(selectedSound.name),
        subtitle: const Text('点开后可直接试听，点击某个提示音会自动播放'),
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
                      await audio.playBuiltInSound(
                        sound,
                        volume: storage.alertVolume,
                      );
                      if (!mounted) {
                        return;
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

  Widget _buildFocusSoundSelector(
    StorageService storage,
    ThemeData theme,
    bool isFocusing,
  ) {
    return Column(
      children: [
        _buildFocusSoundSourceSelector(storage, theme),
        if (storage.focusSoundSourceType == FocusSoundSourceType.builtIn)
          _buildBuiltInFocusSoundSelector(storage, theme, isFocusing)
        else
          _buildApiFocusSoundSection(storage, theme, isFocusing),
      ],
    );
  }

  Widget _buildFocusSoundSourceSelector(
    StorageService storage,
    ThemeData theme,
  ) {
    final currentSource = storage.focusSoundSourceType;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.headphones_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '背景音来源',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _currentFocusSoundSummary(storage),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            SegmentedButton<FocusSoundSourceType>(
              segments: const [
                ButtonSegment(
                  value: FocusSoundSourceType.builtIn,
                  icon: Icon(Icons.offline_bolt_rounded),
                  label: Text('内置'),
                ),
                ButtonSegment(
                  value: FocusSoundSourceType.freesound,
                  icon: Icon(Icons.travel_explore_rounded),
                  label: Text('Freesound'),
                ),
                ButtonSegment(
                  value: FocusSoundSourceType.soundscape,
                  icon: Icon(Icons.waves_rounded),
                  label: Text('Soundscape'),
                ),
              ],
              selected: {currentSource},
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              onSelectionChanged: (selection) async {
                _markPresetCustom(storage);
                await storage.setFocusSoundSourceType(selection.first);
                ref
                    .read(timerProvider.notifier)
                    .syncCurrentFocusSoundFromSettings();
                if (!mounted) {
                  return;
                }
                setState(() {});
              },
            ),
            if (currentSource != FocusSoundSourceType.builtIn &&
                _currentExternalForSource(storage) == null) ...[
              const SizedBox(height: 10),
              Text(
                '先选择来源，再在下面挑选一条具体背景音。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBuiltInFocusSoundSelector(
    StorageService storage,
    ThemeData theme,
    bool isFocusing,
  ) {
    final selectedId = storage.selectedFocusSoundId;
    final audio = ref.read(audioServiceProvider);
    final timerNotifier = ref.read(timerProvider.notifier);
    final selectedSoundscape = focusSoundscapes.firstWhere(
      (soundscape) => soundscape.id == selectedId,
      orElse: () => focusSoundscapes.first,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          Icons.graphic_eq_rounded,
          color: theme.colorScheme.primary,
        ),
        title: Text(selectedSoundscape.name),
        subtitle: const Text('本地生成的 2 分钟无缝循环，更长、更连贯，也不依赖网络'),
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
                      await storage.setFocusSoundSourceType(
                        FocusSoundSourceType.builtIn,
                      );
                      await storage.setRandomFocusSoundMode(false);
                      await storage.setSelectedFocusSoundId(soundscape.id);
                      timerNotifier.syncCurrentFocusSoundFromSettings();
                      if (!isFocusing) {
                        await audio.playFocusSoundscape(
                          soundscape,
                          volume: storage.focusSoundVolume,
                        );
                      }
                      if (!mounted) {
                        return;
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

  Widget _buildApiFocusSoundSection(
    StorageService storage,
    ThemeData theme,
    bool isFocusing,
  ) {
    final currentSource = storage.focusSoundSourceType;
    final selectedExternal = _currentExternalForSource(storage);

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              currentSource == FocusSoundSourceType.freesound
                  ? Icons.travel_explore_rounded
                  : Icons.waves_rounded,
              color: theme.colorScheme.primary,
            ),
            title: Text(_providerLabel(currentSource)),
            subtitle: Text(
              selectedExternal == null
                  ? '还没有选定具体声音'
                  : '${selectedExternal.name}\n${selectedExternal.description}',
            ),
            isThreeLine: selectedExternal != null,
            trailing: selectedExternal == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    onPressed: () async {
                      await _previewExternalFocusSound(
                        selectedExternal,
                        storage,
                      );
                    },
                  ),
          ),
        ),
        if (currentSource == FocusSoundSourceType.freesound)
          _buildFreesoundPanel(storage, theme, isFocusing)
        else if (currentSource == FocusSoundSourceType.soundscape)
          _buildSoundscapePanel(storage, theme, isFocusing),
      ],
    );
  }

  Widget _buildFreesoundPanel(
    StorageService storage,
    ThemeData theme,
    bool isFocusing,
  ) {
    final selectedExternal = _currentExternalForSource(
      storage,
      sourceType: FocusSoundSourceType.freesound,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Freesound API',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '适合快速扩展可选声音库。这里优先搜索更长的环境音素材，并通过公开预览流做试听和循环。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _freesoundApiKeyController,
              decoration: InputDecoration(
                labelText: 'Freesound API Key',
                hintText: '粘贴你的 Freesound Token',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save_outlined),
                  onPressed: _saveFreesoundApiKey,
                ),
              ),
              enableSuggestions: false,
              autocorrect: false,
              onSubmitted: (_) => _saveFreesoundApiKey(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _freesoundQueryController,
              decoration: InputDecoration(
                labelText: '搜索关键词',
                hintText: '例如 rain ambience / forest night / cafe ambience',
                suffixIcon: _isSearchingFreesound
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search_rounded),
                        onPressed: _searchFreesound,
                      ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchFreesound(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in const [
                  'rain ambience',
                  'forest ambience',
                  'ocean waves',
                  'coffee shop ambience',
                  'lofi study',
                ])
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      setState(() {
                        _freesoundQueryController.text = suggestion;
                      });
                    },
                  ),
              ],
            ),
            if (_freesoundStatus != null) ...[
              const SizedBox(height: 12),
              Text(
                _freesoundStatus!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            if (_freesoundResults.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '可选结果',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              for (final result in _freesoundResults)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    selectedExternal?.id == 'freesound_${result.id}'
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selectedExternal?.id == 'freesound_${result.id}'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    result.name.isEmpty
                        ? 'Freesound ${result.id}'
                        : result.name,
                  ),
                  subtitle: Text(
                    '原音频时长 ${_formatDurationLabel(result.duration)} · ${result.username}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    onPressed: () async {
                      await _previewFreesoundResult(result, storage);
                    },
                  ),
                  onTap: () async {
                    await _selectFreesoundResult(result, storage, isFocusing);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSoundscapePanel(
    StorageService storage,
    ThemeData theme,
    bool isFocusing,
  ) {
    final selectedExternal = _currentExternalForSource(
      storage,
      sourceType: FocusSoundSourceType.soundscape,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soundscape City',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '更适合整段专注时长的连续环境流。配置 API Key 后，可以直接按场景切换并实时试听。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _soundscapeApiKeyController,
              decoration: InputDecoration(
                labelText: 'Soundscape API Key',
                hintText: '粘贴你的 Soundscape City Key',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save_outlined),
                  onPressed: _saveSoundscapeApiKey,
                ),
              ),
              enableSuggestions: false,
              autocorrect: false,
              onSubmitted: (_) => _saveSoundscapeApiKey(),
            ),
            if (_soundscapeStatus != null) ...[
              const SizedBox(height: 12),
              Text(
                _soundscapeStatus!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ambientScenes.map((scene) {
                final isSelected =
                    selectedExternal?.id == 'soundscape_${scene.id}';
                return ChoiceChip(
                  avatar: Text(scene.icon),
                  label: Text(scene.name),
                  selected: isSelected,
                  onSelected: (_) async {
                    await _selectSoundscapeScene(scene, storage, isFocusing);
                  },
                );
              }).toList(),
            ),
            if (_isLoadingSoundscape) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveFreesoundApiKey() async {
    final key = _freesoundApiKeyController.text.trim();
    await ref.read(storageServiceProvider).setFreesoundApiKey(key);
    ref.read(soundApiServiceProvider).setFreesoundApiKey(key);
    if (!mounted) {
      return;
    }
    setState(() {
      _freesoundStatus = key.isEmpty
          ? '已清空 Freesound API Key'
          : 'Freesound API Key 已保存';
    });
  }

  Future<void> _saveSoundscapeApiKey() async {
    final key = _soundscapeApiKeyController.text.trim();
    await ref.read(storageServiceProvider).setSoundscapeApiKey(key);
    ref.read(soundApiServiceProvider).setSoundscapeApiKey(key);
    if (!mounted) {
      return;
    }
    setState(() {
      _soundscapeStatus = key.isEmpty
          ? '已清空 Soundscape API Key'
          : 'Soundscape API Key 已保存';
    });
  }

  Future<void> _searchFreesound() async {
    final query = _freesoundQueryController.text.trim();
    final apiKey = _freesoundApiKeyController.text.trim();

    if (apiKey.isEmpty) {
      setState(() {
        _freesoundStatus = '先填写并保存 Freesound API Key，再搜索更多背景音。';
      });
      return;
    }

    if (query.isEmpty) {
      setState(() {
        _freesoundStatus = '先输入关键词，再开始搜索。';
      });
      return;
    }

    final soundApi = ref.read(soundApiServiceProvider);
    soundApi.setFreesoundApiKey(apiKey);

    setState(() {
      _isSearchingFreesound = true;
      _freesoundStatus = '正在搜索较长的环境音素材...';
    });

    final results = await soundApi.searchFreesound(
      query: query,
      pageSize: 12,
      minDuration: 180,
    );
    results.sort((left, right) => right.duration.compareTo(left.duration));

    if (!mounted) {
      return;
    }

    setState(() {
      _isSearchingFreesound = false;
      _freesoundResults = results;
      _freesoundStatus = results.isEmpty
          ? '没有找到合适结果，试试 rain ambience、forest ambience 或 coffee shop ambience。'
          : '找到 ${results.length} 条可试听结果，点选即可设为当前背景音。';
    });
  }

  Future<void> _previewFreesoundResult(
    FreesoundResult result,
    StorageService storage,
  ) async {
    await ref
        .read(audioServiceProvider)
        .playAmbientUrl(result.previewUrl, volume: storage.focusSoundVolume);
    if (!mounted) {
      return;
    }
    setState(() {
      _freesoundStatus =
          '正在试听 ${result.name.isEmpty ? 'Freesound ${result.id}' : result.name}';
    });
  }

  Future<void> _selectFreesoundResult(
    FreesoundResult result,
    StorageService storage,
    bool isFocusing,
  ) async {
    _markPresetCustom(storage);
    final displayName = result.name.isEmpty
        ? 'Freesound ${result.id}'
        : result.name;
    final selectedSound = FocusExternalSound(
      sourceType: FocusSoundSourceType.freesound,
      id: 'freesound_${result.id}',
      name: displayName,
      description:
          'Freesound · 原音频时长 ${_formatDurationLabel(result.duration)} · ${result.username}',
      streamUrl: result.previewUrl,
      author: result.username,
      durationSeconds: result.duration,
      apiParam: _freesoundQueryController.text.trim().isEmpty
          ? null
          : _freesoundQueryController.text.trim(),
    );

    await storage.setSelectedExternalFocusSound(selectedSound);
    await storage.setRandomFocusSoundMode(false);
    ref.read(timerProvider.notifier).syncCurrentFocusSoundFromSettings();

    if (!isFocusing) {
      await _previewFreesoundResult(result, storage);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _freesoundStatus = '已选择 $displayName';
    });
  }

  Future<void> _selectSoundscapeScene(
    AmbientScene scene,
    StorageService storage,
    bool isFocusing,
  ) async {
    _markPresetCustom(storage);
    final selectedSound = FocusExternalSound(
      sourceType: FocusSoundSourceType.soundscape,
      id: 'soundscape_${scene.id}',
      name: scene.name,
      description: 'Soundscape City · 连续环境流',
      author: 'Soundscape City',
      apiParam: scene.apiParam,
    );

    await storage.setSelectedExternalFocusSound(selectedSound);
    await storage.setRandomFocusSoundMode(false);
    ref.read(timerProvider.notifier).syncCurrentFocusSoundFromSettings();

    if (!mounted) {
      return;
    }
    setState(() {
      _soundscapeStatus = '已选择 ${scene.name}';
    });

    if (!isFocusing) {
      await _previewExternalFocusSound(selectedSound, storage);
    }
  }

  Future<void> _previewExternalFocusSound(
    FocusExternalSound external,
    StorageService storage,
  ) async {
    final soundApi = ref.read(soundApiServiceProvider);
    soundApi.configure(
      freesoundApiKey: storage.freesoundApiKey,
      soundscapeApiKey: storage.soundscapeApiKey,
    );

    if (external.sourceType == FocusSoundSourceType.freesound) {
      if (external.streamUrl == null || external.streamUrl!.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _freesoundStatus = '这条 Freesound 结果没有可用预览流。';
        });
        return;
      }

      await ref
          .read(audioServiceProvider)
          .playAmbientUrl(
            external.streamUrl!,
            volume: storage.focusSoundVolume,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _freesoundStatus = '正在试听 ${external.name}';
      });
      return;
    }

    if (external.sourceType != FocusSoundSourceType.soundscape) {
      return;
    }

    if (storage.soundscapeApiKey.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _soundscapeStatus = '已选择场景，但需要先保存 Soundscape API Key 才能播放。';
      });
      return;
    }

    setState(() {
      _isLoadingSoundscape = true;
      _soundscapeStatus = '正在连接 ${external.name}...';
    });

    final url = await soundApi.getSoundscapeUrl(
      environment: external.apiParam ?? external.id,
    );

    if (!mounted) {
      return;
    }

    if (url == null || url.isEmpty) {
      setState(() {
        _isLoadingSoundscape = false;
        _soundscapeStatus = '没有拿到可播放地址，请稍后再试。';
      });
      return;
    }

    await ref
        .read(audioServiceProvider)
        .playAmbientUrl(url, volume: storage.focusSoundVolume);

    if (!mounted) {
      return;
    }
    setState(() {
      _isLoadingSoundscape = false;
      _soundscapeStatus = '正在试听 ${external.name}';
    });
  }

  FocusExternalSound? _currentExternalForSource(
    StorageService storage, {
    FocusSoundSourceType? sourceType,
  }) {
    final currentSource = sourceType ?? storage.focusSoundSourceType;
    final external = storage.selectedExternalFocusSound;
    if (external == null || external.sourceType != currentSource) {
      return null;
    }
    return external;
  }

  String _currentFocusSoundSummary(StorageService storage) {
    if (!storage.focusSoundEnabled) {
      return '当前已关闭背景音。';
    }

    if (storage.focusSoundSourceType == FocusSoundSourceType.builtIn) {
      if (storage.randomFocusSoundMode) {
        return '当前使用内置长循环，并会在每次开始专注时随机挑选一种声音。';
      }
      final soundscape = findFocusSoundscapeById(storage.selectedFocusSoundId);
      return '当前使用内置长循环：${soundscape?.name ?? '未选择'}。';
    }

    final external = _currentExternalForSource(storage);
    if (external == null) {
      return '当前来源是 ${_providerLabel(storage.focusSoundSourceType)}，但还没有选定具体声音。';
    }
    return '当前来源是 ${_providerLabel(storage.focusSoundSourceType)}：${external.name}。';
  }

  String _focusPresetSummaryLine(StorageService storage) {
    return '${storage.focusDuration}/${storage.breakDuration} 分钟 · 微休息 ${storage.microRestSeconds} 秒 · 提醒 ${storage.minInterval}-${storage.maxInterval} 分钟 · ${_currentFocusSoundSummary(storage)}';
  }

  String _providerLabel(FocusSoundSourceType sourceType) {
    switch (sourceType) {
      case FocusSoundSourceType.builtIn:
        return '内置长循环';
      case FocusSoundSourceType.freesound:
        return 'Freesound API';
      case FocusSoundSourceType.soundscape:
        return 'Soundscape City';
    }
  }

  String _formatDurationLabel(double seconds) {
    final totalSeconds = seconds.round();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final remainSeconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours 小时 $minutes 分钟';
    }
    if (minutes > 0) {
      return '$minutes 分 ${remainSeconds.toString().padLeft(2, '0')} 秒';
    }
    return '$remainSeconds 秒';
  }

  Widget _buildFocusPresetSelector(
    StorageService storage,
    ThemeData theme,
    bool isFocusing,
  ) {
    final selectedPresetId = storage.selectedFocusPresetId;
    final selectedPreset = findFocusPresetById(selectedPresetId);
    final timerNotifier = ref.read(timerProvider.notifier);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        controller: _focusPresetController,
        onExpansionChanged: (expanded) {
          setState(() {
            _focusPresetExpanded = expanded;
          });
        },
        leading: Icon(
          Icons.auto_awesome_rounded,
          color: theme.colorScheme.primary,
        ),
        trailing: Icon(
          _focusPresetExpanded ? Icons.remove_rounded : Icons.add_rounded,
          color: theme.colorScheme.primary,
        ),
        title: Text(selectedPreset?.name ?? '自定义方案'),
        subtitle: Text(
          '${selectedPreset?.description ?? '已按当前设置微调'}\n${_focusPresetSummaryLine(storage)}',
        ),
        children: [
          ListTile(
            leading: Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
            title: Text(selectedPreset?.name ?? '自定义方案'),
            subtitle: Text(_focusPresetSummaryLine(storage)),
            isThreeLine: true,
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
                  : Icon(
                      Icons.radio_button_unchecked_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              onTap: () async {
                await storage.applyFocusPreset(preset);
                timerNotifier.syncCurrentFocusSoundFromSettings();
                if (!isFocusing) {
                  await ref.read(audioServiceProvider).stopAmbient();
                }
                _focusPresetController.collapse();
                if (!mounted) {
                  return;
                }
                setState(() {
                  _focusPresetExpanded = false;
                });
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
