import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';

final soundApiServiceProvider = Provider<SoundApiService>((ref) {
  return SoundApiService();
});

class FreesoundResult {
  final int id;
  final String name;
  final String previewUrl;
  final double duration;
  final String username;

  FreesoundResult({
    required this.id,
    required this.name,
    required this.previewUrl,
    required this.duration,
    required this.username,
  });

  factory FreesoundResult.fromJson(Map<String, dynamic> json) {
    final previews = json['previews'] as Map<String, dynamic>? ?? {};
    return FreesoundResult(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      previewUrl:
          (previews['preview-lq-mp3'] ?? previews['preview-hq-mp3'] ?? '')
              as String,
      duration: (json['duration'] as num?)?.toDouble() ?? 0,
      username: json['username'] as String? ?? '',
    );
  }
}

class WikimediaAudioResult {
  final int pageId;
  final String title;
  final String fileUrl;
  final String descriptionUrl;
  final String mime;
  final String description;
  final String author;
  final String license;

  const WikimediaAudioResult({
    required this.pageId,
    required this.title,
    required this.fileUrl,
    required this.descriptionUrl,
    required this.mime,
    required this.description,
    required this.author,
    required this.license,
  });

  factory WikimediaAudioResult.fromJson(Map<String, dynamic> json) {
    final imageInfoList = json['imageinfo'] as List? ?? const [];
    final imageInfo = imageInfoList.isNotEmpty
        ? imageInfoList.first as Map<String, dynamic>
        : const <String, dynamic>{};
    final extMetadata =
        imageInfo['extmetadata'] as Map<String, dynamic>? ??
        const <String, dynamic>{};

    String metadataValue(String key) {
      final raw = extMetadata[key];
      if (raw is Map<String, dynamic>) {
        return _cleanMetadataValue(raw['value'] as String? ?? '');
      }
      return '';
    }

    final rawTitle = json['title'] as String? ?? '';
    final displayTitle = rawTitle.startsWith('File:')
        ? rawTitle.substring(5)
        : rawTitle;

    return WikimediaAudioResult(
      pageId: json['pageid'] as int? ?? 0,
      title: displayTitle,
      fileUrl: imageInfo['url'] as String? ?? '',
      descriptionUrl: imageInfo['descriptionurl'] as String? ?? '',
      mime: imageInfo['mime'] as String? ?? '',
      description: metadataValue('ImageDescription'),
      author: metadataValue('Artist'),
      license: metadataValue('LicenseShortName'),
    );
  }

  static String _cleanMetadataValue(String value) {
    final withoutTags = value.replaceAll(RegExp(r'<[^>]*>'), ' ');
    return withoutTags
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class SoundApiService {
  SoundApiService() {
    _dio.options.headers['User-Agent'] =
        'FocusBell/1.0 (https://github.com/StayGoldTY/focus-bell)';
  }

  final Dio _dio = Dio();

  String? _freesoundApiKey;
  String? _soundscapeApiKey;

  void configure({String? freesoundApiKey, String? soundscapeApiKey}) {
    _freesoundApiKey = freesoundApiKey?.trim();
    _soundscapeApiKey = soundscapeApiKey?.trim();
  }

  void setFreesoundApiKey(String key) => _freesoundApiKey = key.trim();

  void setSoundscapeApiKey(String key) => _soundscapeApiKey = key.trim();

  Future<List<FreesoundResult>> searchFreesound({
    required String query,
    int pageSize = 15,
    double minDuration = 0.0,
    double? maxDuration,
  }) async {
    if (_freesoundApiKey == null || _freesoundApiKey!.isEmpty) {
      return [];
    }

    try {
      final durationFilter = maxDuration == null
          ? 'duration:[$minDuration TO *]'
          : 'duration:[$minDuration TO $maxDuration]';
      final response = await _dio.get(
        '${AppConstants.freesoundBaseUrl}/search/text/',
        queryParameters: {
          'query': query,
          'filter': durationFilter,
          'fields': 'id,name,previews,duration,username',
          'page_size': pageSize,
          'token': _freesoundApiKey,
        },
      );

      final results = response.data['results'] as List? ?? [];
      return results
          .map((e) => FreesoundResult.fromJson(e as Map<String, dynamic>))
          .where((item) => item.previewUrl.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<WikimediaAudioResult>> searchWikimediaAudio({
    required String query,
    int limit = 12,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return [];
    }

    try {
      final response = await _dio.get(
        AppConstants.wikimediaCommonsApiUrl,
        queryParameters: {
          'action': 'query',
          'generator': 'search',
          'gsrsearch': '$trimmedQuery filemime:audio',
          'gsrnamespace': 6,
          'gsrlimit': limit,
          'prop': 'imageinfo',
          'iiprop': 'url|mime|extmetadata',
          'format': 'json',
          'origin': '*',
        },
      );

      final pages =
          (response.data['query']?['pages'] as Map?)?.values.toList() ??
          const [];
      pages.sort(
        (left, right) => ((left as Map)['index'] as int? ?? 0).compareTo(
          (right as Map)['index'] as int? ?? 0,
        ),
      );

      const supportedMimes = {
        'audio/mpeg',
        'audio/ogg',
        'audio/wav',
        'audio/flac',
        'audio/webm',
      };

      return pages
          .map(
            (item) =>
                WikimediaAudioResult.fromJson(item as Map<String, dynamic>),
          )
          .where(
            (item) =>
                item.fileUrl.isNotEmpty &&
                item.mime.isNotEmpty &&
                supportedMimes.contains(item.mime),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> getSoundscapeUrl({required String environment}) async {
    if (_soundscapeApiKey == null || _soundscapeApiKey!.isEmpty) {
      return null;
    }

    try {
      final response = await _dio.get(
        '${AppConstants.soundscapeCityBaseUrl}/environment',
        queryParameters: {'env': environment},
        options: Options(headers: {'x-api-key': _soundscapeApiKey}),
      );

      return response.data['url'] as String?;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _dio.close();
  }
}
