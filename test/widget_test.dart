import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_bell/app.dart';
import 'package:focus_bell/features/timer/models/timer_state.dart';
import 'package:focus_bell/features/timer/providers/timer_provider.dart';
import 'package:focus_bell/core/constants/sound_data.dart';
import 'package:focus_bell/shared/services/audio_service.dart';
import 'package:focus_bell/shared/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app smoke test', (tester) async {
    final container = await _pumpApp(tester);

    expect(find.text('FocusBell'), findsWidgets);
    expect(find.text('开始专注'), findsOneWidget);
    expect(find.text('这一轮打算做什么？'), findsOneWidget);
    expect(find.text('快速时长'), findsOneWidget);

    container.dispose();
  });

  testWidgets('sets intention then starts and pauses a session', (
    tester,
  ) async {
    final container = await _pumpApp(tester);

    await tester.enterText(find.byType(TextField), '写周报');
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, '写作'));
    await tester.pump();
    await tester.ensureVisible(find.text('开始专注'));
    await tester.tap(find.text('开始专注'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('专注中'), findsWidgets);
    expect(find.textContaining('写周报'), findsWidgets);
    expect(container.read(timerProvider).phase, TimerPhase.focusing);

    await tester.tap(find.text('暂停'));
    await tester.pump();
    expect(find.text('已暂停'), findsWidgets);
    expect(container.read(timerProvider).phase, TimerPhase.paused);

    await tester.tap(find.text('结束'));
    await tester.pump();
    expect(find.text('结束本次专注？'), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    expect(find.text('结束本次专注？'), findsOneWidget);
    expect(container.read(timerProvider).phase, TimerPhase.paused);

    await tester.tap(find.text('继续专注'));
    await tester.pump();
    expect(find.text('结束本次专注？'), findsNothing);
    expect(container.read(timerProvider).phase, TimerPhase.paused);

    await tester.tap(find.text('结束'));
    await tester.pump();
    await tester.tap(find.text('确认结束'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('开始专注'), findsOneWidget);
    expect(container.read(timerProvider).phase, TimerPhase.idle);
    expect(find.text('写周报'), findsWidgets);
    expect(find.widgetWithText(ChoiceChip, '写作'), findsOneWidget);

    container.dispose();
  });

  testWidgets('quick duration updates planned clock', (tester) async {
    final container = await _pumpApp(tester);

    await tester.ensureVisible(find.text('25'));
    await tester.tap(find.text('25'));
    await tester.pump();

    expect(find.text('25:00'), findsOneWidget);
    expect(container.read(storageServiceProvider).focusDuration, 25);

    container.dispose();
  });

  testWidgets('statistics empty state and settings remain reachable', (
    tester,
  ) async {
    final container = await _pumpApp(tester);

    await tester.tap(find.text('统计'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('你的专注数据'), findsOneWidget);
    expect(find.textContaining('还没有历史记录'), findsOneWidget);
    expect(find.textContaining('还没有分类数据'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('访问统计'), findsNothing);

    await tester.tap(find.text('科学'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('为什么 FocusBell 有效'), findsOneWidget);

    await tester.tap(find.text('设置'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('提示音'), findsOneWidget);
    expect(find.text('专注方案'), findsOneWidget);
    expect(find.text('振动反馈'), findsNothing);
    expect(find.text('Openverse'), findsNothing);
    expect(find.text('经典 90/20'), findsOneWidget);

    await tester.tap(find.text('专注'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('开始专注'), findsOneWidget);

    container.dispose();
  });

  testWidgets('skip micro rest returns to focusing', (tester) async {
    final container = await _pumpApp(tester);
    container.read(timerProvider.notifier).debugEnterMicroRest();
    await tester.pump(const Duration(milliseconds: 400));

    expect(container.read(timerProvider).phase, TimerPhase.microRest);
    expect(find.text('提前回来'), findsOneWidget);

    await tester.tap(find.text('提前回来'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(container.read(timerProvider).phase, TimerPhase.focusing);
    expect(find.text('专注中'), findsWidgets);

    container.read(timerProvider.notifier).stop();
    await tester.pump();
    container.dispose();
  });

  testWidgets('idle home stays slim and shows today progress', (tester) async {
    final container = await _pumpApp(tester, size: const Size(390, 844));

    expect(find.text('开始专注'), findsOneWidget);
    expect(find.text('快速时长'), findsOneWidget);
    expect(find.text('这一轮打算做什么？'), findsOneWidget);
    expect(find.text('今日进度'), findsOneWidget);
    expect(find.text('开始连续'), findsNothing);
    expect(find.textContaining('模式 ·'), findsNothing);

    final progressRect = tester.getRect(find.text('今日进度'));
    expect(progressRect.bottom, lessThan(844 - 72));

    container.dispose();
  });

  testWidgets('stop confirm stays open when a micro-rest would start', (
    tester,
  ) async {
    final container = await _pumpApp(tester);

    await tester.ensureVisible(find.text('开始专注'));
    await tester.tap(find.text('开始专注'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('结束'));
    await tester.pump();
    expect(find.text('结束本次专注？'), findsOneWidget);

    container.read(timerProvider.notifier).debugEnterMicroRest();
    await tester.pump();

    expect(find.text('结束本次专注？'), findsOneWidget);
    expect(find.text('提前回来'), findsNothing);
    expect(container.read(timerProvider).phase, TimerPhase.focusing);

    await tester.tap(find.text('确认结束'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(timerProvider).phase, TimerPhase.idle);
    expect(find.text('开始专注'), findsOneWidget);

    container.dispose();
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

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  Size size = const Size(1200, 2200),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  final container = ProviderContainer(
    overrides: [
      storageServiceProvider.overrideWithValue(storage),
      audioServiceProvider.overrideWithValue(SilentAudioService()),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const FocusBellApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return container;
}
