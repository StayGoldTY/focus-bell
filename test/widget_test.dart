import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_bell/app.dart';
import 'package:focus_bell/shared/services/audio_service.dart';
import 'package:focus_bell/shared/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app smoke test', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final audio = AudioService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          audioServiceProvider.overrideWithValue(audio),
        ],
        child: const FocusBellApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('FocusBell'), findsOneWidget);
    expect(find.text('开始专注'), findsOneWidget);
  });
}
