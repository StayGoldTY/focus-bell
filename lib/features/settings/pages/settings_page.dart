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
  final TextEditingController _mainlandLibraryQueryController =
      TextEditingController(text: '雨声');
  final TextEditingController _wikimediaQueryController = TextEditingController(
    text: 'rain',
  );
  final TextEditingController _openverseQueryController = TextEditingController(
    text: 'rain ambience',
  );

  bool _focusPresetExpanded = false;
  bool _isSearchingMainlandLibrary = false;
  bool _isSearchingWikimedia = false;
  bool _isSearchingOpenverse = false;
  List<MainlandLibraryAudioResult> _mainlandLibraryResults = const [];
  List<WikimediaAudioResult> _wikimediaResults = const [];
  List<OpenverseAudioResult> _openverseResults = const [];
  String? _mainlandLibraryStatus;
  String? _wikimediaStatus;
  String? _openverseStatus;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _focusPresetController.dispose();
    _mainlandLibraryQueryController.dispose();
    _wikimediaQueryController.dispose();
    _openverseQueryController.dispose();
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
          if (!storage.focusSoundEnabled)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Icon(
                  Icons.info_outline_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('可先搜索和试听'),
                subtitle: const Text(
                  '即使当前关闭自动播放，你也可以先搜索、试听并选好背景音；真正开始专注时不会自动播放。',
                ),
              ),
            ),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in const [
                  (
                    FocusSoundSourceType.builtIn,
                    '内置',
                    Icons.offline_bolt_rounded,
                  ),
                  (
                    FocusSoundSourceType.mainlandLibrary,
                    '站内免费',
                    Icons.cloud_done_rounded,
                  ),
                  (
                    FocusSoundSourceType.wikimedia,
                    'Wiki免费',
                    Icons.public_rounded,
                  ),
                  (
                    FocusSoundSourceType.openverse,
                    'Openverse',
                    Icons.travel_explore_rounded,
                  ),
                ])
                  ChoiceChip(
                    avatar: Icon(
                      option.$3,
                      size: 18,
                      color: currentSource == option.$1
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                    ),
                    label: Text(option.$2),
                    selected: currentSource == option.$1,
                    onSelected: (_) async {
                      _markPresetCustom(storage);
                      await storage.setFocusSoundSourceType(option.$1);
                      ref
                          .read(timerProvider.notifier)
                          .syncCurrentFocusSoundFromSettings();
                      if (!mounted) {
                        return;
                      }
                      setState(() {});
                    },
                  ),
              ],
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
            leading: Icon(switch (currentSource) {
              FocusSoundSourceType.mainlandLibrary => Icons.cloud_done_rounded,
              FocusSoundSourceType.wikimedia => Icons.public_rounded,
              FocusSoundSourceType.openverse => Icons.travel_explore_rounded,
              FocusSoundSourceType.builtIn => Icons.graphic_eq_rounded,
            }, color: theme.colorScheme.primary),
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
        if (currentSource == FocusSoundSourceType.mainlandLibrary)
          _buildMainlandLibraryPanel(storage, theme, isFocusing)
        else if (currentSource == FocusSoundSourceType.wikimedia)
          _buildWikimediaPanel(storage, theme, isFocusing)
        else if (currentSource == FocusSoundSourceType.openverse)
          _buildOpenversePanel(storage, theme, isFocusing),
      ],
    );
  }

  Widget _buildMainlandLibraryPanel(
    StorageService storage,
    ThemeData theme,
    bool isFocusing,
  ) {
    final selectedExternal = _currentExternalForSource(
      storage,
      sourceType: FocusSoundSourceType.mainlandLibrary,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '站内免费资源库',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '走站内同源资源，不依赖境外搜索接口，更适合中国大陆使用。搜索结果会直接映射到应用内置的长循环背景音。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _mainlandLibraryQueryController,
              decoration: InputDecoration(
                labelText: '搜索关键词',
                hintText: '例如 雨声 / 海浪 / 咖啡馆 / 图书馆 / 白噪音 / 冥想',
                suffixIcon: _isSearchingMainlandLibrary
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
                        onPressed: _searchMainlandLibraryAudio,
                      ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchMainlandLibraryAudio(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in const [
                  '雨声',
                  '海浪',
                  '咖啡馆',
                  '图书馆',
                  '白噪音',
                  '冥想',
                ])
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      setState(() {
                        _mainlandLibraryQueryController.text = suggestion;
                      });
                    },
                  ),
              ],
            ),
            if (_mainlandLibraryStatus != null) ...[
              const SizedBox(height: 12),
              Text(
                _mainlandLibraryStatus!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            if (_mainlandLibraryResults.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '大陆友好可选结果',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              for (final result in _mainlandLibraryResults)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    selectedExternal?.id == 'mainland_${result.id}'
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selectedExternal?.id == 'mainland_${result.id}'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(result.name),
                  subtitle: Text(
                    '${result.category} · ${result.description}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    onPressed: () async {
                      await _previewMainlandLibraryResult(result, storage);
                    },
                  ),
                  onTap: () async {
                    await _selectMainlandLibraryResult(
                      result,
                      storage,
                      isFocusing,
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWikimediaPanel(
    StorageService storage,
    ThemeData theme,
    bool isFocusing,
  ) {
    final selectedExternal = _currentExternalForSource(
      storage,
      sourceType: FocusSoundSourceType.wikimedia,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wikimedia Commons',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '免费、免 Key，可直接搜索 Wikimedia Commons 上的开放授权音频文件。适合先快速扩充选择，再按喜欢的方向慢慢细化。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _wikimediaQueryController,
              decoration: InputDecoration(
                labelText: '搜索关键词',
                hintText: '例如 rain / forest / ocean / cafe / piano',
                suffixIcon: _isSearchingWikimedia
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
                        onPressed: _searchWikimediaAudio,
                      ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchWikimediaAudio(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in const [
                  'rain',
                  'forest',
                  'ocean',
                  'cafe',
                  'piano',
                ])
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      setState(() {
                        _wikimediaQueryController.text = suggestion;
                      });
                    },
                  ),
              ],
            ),
            if (_wikimediaStatus != null) ...[
              const SizedBox(height: 12),
              Text(
                _wikimediaStatus!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            if (_wikimediaResults.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '免费可选结果',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              for (final result in _wikimediaResults)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    selectedExternal?.id == 'wikimedia_${result.pageId}'
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selectedExternal?.id == 'wikimedia_${result.pageId}'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(result.title),
                  subtitle: Text(
                    '${result.license.isEmpty ? '开放授权音频' : result.license} · ${result.author.isEmpty ? 'Wikimedia Commons' : result.author}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    onPressed: () async {
                      await _previewWikimediaResult(result, storage);
                    },
                  ),
                  onTap: () async {
                    await _selectWikimediaResult(result, storage, isFocusing);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOpenversePanel(
    StorageService storage,
    ThemeData theme,
    bool isFocusing,
  ) {
    final selectedExternal = _currentExternalForSource(
      storage,
      sourceType: FocusSoundSourceType.openverse,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Openverse',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '免费聚合多个开放音频库，优先帮你筛出更长、更适合循环的环境音。默认不需要 Key，搜索到结果后就能直接试听和使用。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _openverseQueryController,
              decoration: InputDecoration(
                labelText: '搜索关键词',
                hintText:
                    '例如 rain ambience / forest ambience / ocean waves / cafe ambience',
                suffixIcon: _isSearchingOpenverse
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
                        onPressed: _searchOpenverseAudio,
                      ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchOpenverseAudio(),
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
                  'cafe ambience',
                  'fireplace ambience',
                  'night ambience',
                ])
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      setState(() {
                        _openverseQueryController.text = suggestion;
                      });
                    },
                  ),
              ],
            ),
            if (_openverseStatus != null) ...[
              const SizedBox(height: 12),
              Text(
                _openverseStatus!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            if (_openverseResults.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '免费可选结果',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              for (final result in _openverseResults)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    selectedExternal?.id == 'openverse_${result.id}'
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selectedExternal?.id == 'openverse_${result.id}'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(result.title),
                  subtitle: Text(
                    [
                      if (result.provider.isNotEmpty) result.provider,
                      if (result.durationSeconds != null)
                        _formatDurationLabel(result.durationSeconds!),
                      if (result.creator.isNotEmpty) result.creator,
                      result.license,
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    onPressed: () async {
                      await _previewOpenverseResult(result, storage);
                    },
                  ),
                  onTap: () async {
                    await _selectOpenverseResult(result, storage, isFocusing);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _searchMainlandLibraryAudio() async {
    final query = _mainlandLibraryQueryController.text.trim();

    setState(() {
      _isSearchingMainlandLibrary = true;
      _mainlandLibraryStatus = '正在从站内免费资源库筛选结果...';
    });

    final results = await ref
        .read(soundApiServiceProvider)
        .searchMainlandLibraryAudio(query: query, limit: 12);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSearchingMainlandLibrary = false;
      _mainlandLibraryResults = results;
      _mainlandLibraryStatus = results.isEmpty
          ? '没有找到匹配结果，试试 雨声、海浪、咖啡馆、图书馆、白噪音 或 冥想。'
          : '找到 ${results.length} 条站内免费结果，可直接试听并设为当前背景音。';
    });
  }

  Future<void> _previewMainlandLibraryResult(
    MainlandLibraryAudioResult result,
    StorageService storage,
  ) async {
    final soundscape = findFocusSoundscapeById(result.soundscapeId);
    if (soundscape == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _mainlandLibraryStatus = '没有找到对应的站内声音，请稍后再试。';
      });
      return;
    }

    await ref
        .read(audioServiceProvider)
        .playFocusSoundscape(soundscape, volume: storage.focusSoundVolume);

    if (!mounted) {
      return;
    }
    setState(() {
      _mainlandLibraryStatus = '正在试听 ${result.name}';
    });
  }

  Future<void> _selectMainlandLibraryResult(
    MainlandLibraryAudioResult result,
    StorageService storage,
    bool isFocusing,
  ) async {
    _markPresetCustom(storage);
    final selectedSound = FocusExternalSound(
      sourceType: FocusSoundSourceType.mainlandLibrary,
      id: 'mainland_${result.id}',
      name: result.name,
      description: '站内免费库 · ${result.category} · ${result.description}',
      author: 'FocusBell',
      apiParam: result.soundscapeId,
    );

    await storage.setSelectedExternalFocusSound(selectedSound);
    await storage.setRandomFocusSoundMode(false);
    ref.read(timerProvider.notifier).syncCurrentFocusSoundFromSettings();

    if (!isFocusing) {
      await _previewMainlandLibraryResult(result, storage);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _mainlandLibraryStatus = '已选择 ${result.name}';
    });
  }

  Future<void> _searchWikimediaAudio() async {
    final query = _wikimediaQueryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _wikimediaStatus = '先输入关键词，再开始搜索。';
      });
      return;
    }

    setState(() {
      _isSearchingWikimedia = true;
      _wikimediaStatus = '正在搜索免费的开放授权音频...';
    });

    final results = await ref
        .read(soundApiServiceProvider)
        .searchWikimediaAudio(query: query, limit: 12);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSearchingWikimedia = false;
      _wikimediaResults = results;
      _wikimediaStatus = results.isEmpty
          ? '没有找到合适结果，试试 rain、forest、ocean、cafe 或 piano。'
          : '找到 ${results.length} 条免费结果，点选即可设为当前背景音。';
    });
  }

  Future<void> _previewWikimediaResult(
    WikimediaAudioResult result,
    StorageService storage,
  ) async {
    await ref
        .read(audioServiceProvider)
        .playAmbientUrl(result.fileUrl, volume: storage.focusSoundVolume);
    if (!mounted) {
      return;
    }
    setState(() {
      _wikimediaStatus = '正在试听 ${result.title}';
    });
  }

  Future<void> _selectWikimediaResult(
    WikimediaAudioResult result,
    StorageService storage,
    bool isFocusing,
  ) async {
    _markPresetCustom(storage);
    final selectedSound = FocusExternalSound(
      sourceType: FocusSoundSourceType.wikimedia,
      id: 'wikimedia_${result.pageId}',
      name: result.title,
      description:
          'Wikimedia Commons · ${result.license.isEmpty ? '开放授权' : result.license} · ${result.author.isEmpty ? 'Wikimedia Commons' : result.author}',
      streamUrl: result.fileUrl,
      author: result.author.isEmpty ? 'Wikimedia Commons' : result.author,
      apiParam: _wikimediaQueryController.text.trim().isEmpty
          ? null
          : _wikimediaQueryController.text.trim(),
    );

    await storage.setSelectedExternalFocusSound(selectedSound);
    await storage.setRandomFocusSoundMode(false);
    ref.read(timerProvider.notifier).syncCurrentFocusSoundFromSettings();

    if (!isFocusing) {
      await _previewWikimediaResult(result, storage);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _wikimediaStatus = '已选择 ${result.title}';
    });
  }

  Future<void> _searchOpenverseAudio() async {
    final query = _openverseQueryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _openverseStatus = '先输入关键词，再开始搜索。';
      });
      return;
    }

    setState(() {
      _isSearchingOpenverse = true;
      _openverseStatus = '正在聚合免费的长音频结果...';
    });

    final results = await ref
        .read(soundApiServiceProvider)
        .searchOpenverseAudio(query: query, limit: 12, minDurationSeconds: 45);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSearchingOpenverse = false;
      _openverseResults = results;
      _openverseStatus = results.isEmpty
          ? '没有找到合适结果，试试 rain ambience、forest ambience、ocean waves 或 cafe ambience。'
          : '找到 ${results.length} 条免费结果，已经优先排到更长、更适合循环的音频。';
    });
  }

  Future<void> _previewOpenverseResult(
    OpenverseAudioResult result,
    StorageService storage,
  ) async {
    await ref
        .read(audioServiceProvider)
        .playAmbientUrl(result.fileUrl, volume: storage.focusSoundVolume);
    if (!mounted) {
      return;
    }
    setState(() {
      _openverseStatus = '正在试听 ${result.title}';
    });
  }

  Future<void> _selectOpenverseResult(
    OpenverseAudioResult result,
    StorageService storage,
    bool isFocusing,
  ) async {
    _markPresetCustom(storage);
    final selectedSound = FocusExternalSound(
      sourceType: FocusSoundSourceType.openverse,
      id: 'openverse_${result.id}',
      name: result.title,
      description: [
        'Openverse',
        if (result.provider.isNotEmpty) result.provider,
        if (result.durationSeconds != null)
          '时长 ${_formatDurationLabel(result.durationSeconds!)}',
        result.license,
      ].join(' · '),
      streamUrl: result.fileUrl,
      author: result.creator.isEmpty ? 'Openverse' : result.creator,
      durationSeconds: result.durationSeconds,
      apiParam: _openverseQueryController.text.trim().isEmpty
          ? null
          : _openverseQueryController.text.trim(),
    );

    await storage.setSelectedExternalFocusSound(selectedSound);
    await storage.setRandomFocusSoundMode(false);
    ref.read(timerProvider.notifier).syncCurrentFocusSoundFromSettings();

    if (!isFocusing) {
      await _previewOpenverseResult(result, storage);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _openverseStatus = '已选择 ${result.title}';
    });
  }

  Future<void> _previewExternalFocusSound(
    FocusExternalSound external,
    StorageService storage,
  ) async {
    if (external.sourceType == FocusSoundSourceType.builtIn) {
      return;
    }

    if (external.sourceType == FocusSoundSourceType.mainlandLibrary) {
      final soundscapeId = external.apiParam ?? external.id;
      final soundscape = findFocusSoundscapeById(soundscapeId);
      if (soundscape == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _mainlandLibraryStatus = '没有找到对应的站内声音，请稍后再试。';
        });
        return;
      }

      await ref
          .read(audioServiceProvider)
          .playFocusSoundscape(soundscape, volume: storage.focusSoundVolume);

      if (!mounted) {
        return;
      }
      setState(() {
        _mainlandLibraryStatus = '正在试听 ${external.name}';
      });
      return;
    }

    if (external.streamUrl == null || external.streamUrl!.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (external.sourceType == FocusSoundSourceType.wikimedia) {
          _wikimediaStatus = '这条 Wikimedia 结果没有可用播放地址。';
        } else {
          _openverseStatus = '这条 Openverse 结果没有可用播放地址。';
        }
      });
      return;
    }

    await ref
        .read(audioServiceProvider)
        .playAmbientUrl(external.streamUrl!, volume: storage.focusSoundVolume);

    if (!mounted) {
      return;
    }
    setState(() {
      if (external.sourceType == FocusSoundSourceType.wikimedia) {
        _wikimediaStatus = '正在试听 ${external.name}';
      } else {
        _openverseStatus = '正在试听 ${external.name}';
      }
    });
  }

  FocusExternalSound? _currentExternalForSource(
    StorageService storage, {
    FocusSoundSourceType? sourceType,
  }) {
    final currentSource = sourceType ?? storage.focusSoundSourceType;
    if (currentSource == FocusSoundSourceType.builtIn) {
      return null;
    }
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
      case FocusSoundSourceType.mainlandLibrary:
        return '站内免费资源库';
      case FocusSoundSourceType.wikimedia:
        return 'Wikimedia Commons';
      case FocusSoundSourceType.openverse:
        return 'Openverse';
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
