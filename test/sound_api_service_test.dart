import 'package:flutter_test/flutter_test.dart';

import 'package:focus_bell/shared/services/sound_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundApiService mainland library', () {
    test(
      'finds China-friendly local catalog entries by Chinese keyword',
      () async {
        final service = SoundApiService();

        final results = await service.searchMainlandLibraryAudio(
          query: '雨声',
          limit: 12,
        );

        expect(results, isNotEmpty);
        expect(results.first.id, 'rain_drift');
        expect(
          results.any((item) => item.tags.any((tag) => tag.contains('雨声'))),
          isTrue,
        );
      },
    );

    test(
      'returns multiple built-in long loop options for broad queries',
      () async {
        final service = SoundApiService();

        final results = await service.searchMainlandLibraryAudio(
          query: '学习',
          limit: 12,
        );

        expect(results.length, greaterThanOrEqualTo(2));
        expect(
          results.every((item) => item.soundscapeId.trim().isNotEmpty),
          isTrue,
        );
      },
    );
  });
}
