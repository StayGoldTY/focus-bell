import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_bell/core/constants/sound_data.dart';
import 'package:focus_bell/core/models/focus_session_record.dart';
import 'package:focus_bell/features/timer/models/timer_state.dart';
import 'package:focus_bell/features/timer/providers/timer_provider.dart';
import 'package:focus_bell/shared/services/audio_service.dart';
import 'package:focus_bell/shared/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('startup wipes unrecorded ghost today minutes', () async {
    final todayKey = focusDateKey(DateTime.now());
    final env = await _setup(
      initialValues: {'todayFocusSeconds': 900, 'todayDate': todayKey},
    );

    expect(env.storage.todayFocusSeconds, 0);
    expect(env.container.read(timerProvider).todayFocusSeconds, 0);

    env.container.dispose();
  });

  test('sub-minute stop does not write today minutes or history', () async {
    final env = await _setup();
    final notifier = env.container.read(timerProvider.notifier);

    notifier.startFocus();
    notifier.debugSetFocusElapsed(40);
    expect(env.storage.todayFocusSeconds, 0);
    expect(env.container.read(timerProvider).todayFocusSeconds, 0);

    notifier.stop();

    expect(env.storage.getSessionRecords(), isEmpty);
    expect(env.storage.todayFocusSeconds, 0);
    expect(env.storage.totalFocusSeconds, 0);
    expect(env.storage.completedSessions, 0);
    expect(env.storage.currentStreak, 0);
    expect(env.container.read(timerProvider).todayFocusSeconds, 0);

    env.container.dispose();
  });

  test('confirmed stop persists the same ledger across sessions and totals', () async {
    final env = await _setup();
    final notifier = env.container.read(timerProvider.notifier);

    notifier.startFocus();
    notifier.debugSetFocusElapsed(90);
    expect(env.storage.todayFocusSeconds, 0);

    notifier.stop();

    final records = env.storage.getSessionRecords();
    expect(records, hasLength(1));
    expect(records.single.actualFocusSeconds, 90);
    expect(records.single.status, FocusSessionStatus.stopped);
    expect(env.storage.todayFocusSeconds, 90);
    expect(env.storage.totalFocusSeconds, 90);
    expect(env.storage.completedSessions, 0);
    expect(env.storage.currentStreak, 1);
    expect(env.container.read(timerProvider).todayFocusSeconds, 90);
    expect(env.container.read(timerProvider).phase, TimerPhase.idle);

    env.container.dispose();
  });

  test('pagehide persist-or-discard matches recorded history', () async {
    final env = await _setup();
    final notifier = env.container.read(timerProvider.notifier);

    notifier.startFocus();
    notifier.debugSetFocusElapsed(40);
    notifier.handleUnload();
    expect(env.storage.getSessionRecords(), isEmpty);
    expect(env.storage.todayFocusSeconds, 0);

    notifier.startFocus();
    notifier.debugSetFocusElapsed(125);
    notifier.handleUnload();

    final records = env.storage.getSessionRecords();
    expect(records, hasLength(1));
    expect(records.single.actualFocusSeconds, 125);
    expect(env.storage.todayFocusSeconds, 125);
    expect(env.storage.totalFocusSeconds, 125);
    expect(env.container.read(timerProvider).phase, TimerPhase.idle);

    env.container.dispose();
  });

  test('end-session prompt wins over micro-rest overlay', () async {
    final env = await _setup();
    final notifier = env.container.read(timerProvider.notifier);

    notifier.startFocus();
    env.container.read(sessionEndPromptOpenProvider.notifier).state = true;
    notifier.debugEnterMicroRest();

    expect(env.container.read(timerProvider).phase, TimerPhase.focusing);

    notifier.onSessionEndPromptResolved(confirmedStop: false);
    expect(env.container.read(timerProvider).phase, TimerPhase.microRest);

    notifier.skipMicroRest();
    env.container.read(sessionEndPromptOpenProvider.notifier).state = true;
    notifier.debugEnterMicroRest();
    expect(env.container.read(timerProvider).phase, TimerPhase.focusing);

    notifier.onSessionEndPromptResolved(confirmedStop: true);
    expect(env.container.read(timerProvider).phase, TimerPhase.idle);
    expect(env.container.read(sessionEndPromptOpenProvider), isFalse);

    env.container.dispose();
  });
}

class SilentAudioService extends AudioService {
  @override
  Future<void> init() async {}

  @override
  Future<void> playBuiltInSound(
    BuiltInSound sound, {
    double volume = 0.7,
  }) async {}

  @override
  Future<void> playTone({
    double frequency = 440,
    double durationSeconds = 1.0,
    double volume = 0.7,
  }) async {}

  @override
  Future<void> playFocusSoundscape(
    FocusSoundscape soundscape, {
    double volume = 0.35,
  }) async {}

  @override
  Future<void> playAmbientUrl(String url, {double volume = 0.35}) async {}

  @override
  Future<void> stopAlert() async {}

  @override
  Future<void> stopAmbient() async {}

  @override
  Future<void> pauseAmbient() async {}

  @override
  Future<void> resumeAmbient() async {}

  @override
  Future<void> stopAll() async {}

  @override
  void requestWakeLock() {}

  @override
  void releaseWakeLock() {}
}

class _Env {
  final ProviderContainer container;
  final StorageService storage;

  const _Env(this.container, this.storage);
}

Future<_Env> _setup({Map<String, Object> initialValues = const {}}) async {
  SharedPreferences.setMockInitialValues(initialValues);
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  final container = ProviderContainer(
    overrides: [
      storageServiceProvider.overrideWithValue(storage),
      audioServiceProvider.overrideWithValue(SilentAudioService()),
    ],
  );
  container.read(timerProvider);
  return _Env(container, storage);
}
