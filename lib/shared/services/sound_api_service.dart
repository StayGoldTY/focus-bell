import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';

final soundApiServiceProvider = Provider<SoundApiService>((ref) {
  return SoundApiService();
});

const _supportedWikimediaMimes = {
  'audio/flac',
  'audio/mpeg',
  'audio/ogg',
  'audio/wav',
  'audio/webm',
};

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
      title: displayTitle.trim().isEmpty ? 'Untitled audio' : displayTitle,
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
    _dio.options
      ..connectTimeout = const Duration(seconds: 20)
      ..receiveTimeout = const Duration(seconds: 20);
    if (!kIsWeb) {
      _dio.options.headers['User-Agent'] =
          'FocusBell/1.0 (https://github.com/StayGoldTY/focus-bell)';
    }
  }

  final Dio _dio = Dio();

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

      final data = response.data;
      if (data is! Map) {
        return [];
      }

      final pages =
          (data['query']?['pages'] as Map?)?.values.toList() ?? const [];
      pages.sort(
        (left, right) => ((left as Map)['index'] as int? ?? 0).compareTo(
          (right as Map)['index'] as int? ?? 0,
        ),
      );

      return pages
          .map(
            (item) =>
                WikimediaAudioResult.fromJson(item as Map<String, dynamic>),
          )
          .where(
            (item) =>
                item.fileUrl.isNotEmpty &&
                item.mime.isNotEmpty &&
                _supportedWikimediaMimes.contains(item.mime),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  void dispose() {
    _dio.close();
  }
}
