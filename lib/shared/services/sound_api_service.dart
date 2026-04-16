import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
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

const _supportedOpenverseFileTypes = {
  'aac',
  'flac',
  'm4a',
  'mp3',
  'ogg',
  'opus',
  'wav',
  'webm',
};

const _ambientKeywordHints = {
  'ambient',
  'ambience',
  'ambiance',
  'background',
  'cafe',
  'coffee',
  'fireplace',
  'forest',
  'nature',
  'night',
  'noise',
  'ocean',
  'rain',
  'river',
  'sea',
  'soundscape',
  'stream',
  'waves',
  'white noise',
};

const _ambientFirstProviders = {'freesound', 'wikimedia'};
const _musicFirstProviders = {'ccmixter', 'jamendo'};
const _musicQueryKeywords = {
  'classical',
  'guitar',
  'jazz',
  'lo-fi',
  'lofi',
  'music',
  'piano',
  'song',
  'study beat',
};
const _queryStopWords = {
  'ambient',
  'ambiance',
  'ambience',
  'audio',
  'background',
  'sound',
  'soundscape',
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

class OpenverseAudioResult {
  final String id;
  final String title;
  final String fileUrl;
  final String creator;
  final String provider;
  final String license;
  final String detailUrl;
  final String fileType;
  final List<String> tags;
  final double? durationSeconds;

  const OpenverseAudioResult({
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.creator,
    required this.provider,
    required this.license,
    required this.detailUrl,
    required this.fileType,
    required this.tags,
    required this.durationSeconds,
  });

  factory OpenverseAudioResult.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as String? ?? '').trim();
    final provider =
        (json['provider'] as String? ?? json['source'] as String? ?? '').trim();
    final fileType = (json['filetype'] as String? ?? '').trim().toLowerCase();
    final rawTags = json['tags'] as List? ?? const [];
    return OpenverseAudioResult(
      id: (json['id'] ?? '').toString(),
      title: title.isEmpty ? 'Untitled audio' : title,
      fileUrl: (json['url'] as String? ?? '').trim(),
      creator: (json['creator'] as String? ?? '').trim(),
      provider: provider,
      license: _buildLicenseLabel(
        json['license'] as String?,
        json['license_version'] as String?,
      ),
      detailUrl:
          (json['foreign_landing_url'] as String? ??
                  json['detail_url'] as String? ??
                  '')
              .trim(),
      fileType: fileType,
      tags: rawTags
          .map((tag) {
            if (tag is Map<String, dynamic>) {
              return (tag['name'] as String? ?? '').trim();
            }
            return tag is String ? tag.trim() : '';
          })
          .where((tag) => tag.isNotEmpty)
          .toList(),
      durationSeconds: _parseDurationSeconds(json['duration']),
    );
  }

  static String _buildLicenseLabel(String? license, String? version) {
    final normalizedLicense = (license ?? '').trim();
    final normalizedVersion = (version ?? '').trim();
    if (normalizedLicense.isEmpty) {
      return 'Open license';
    }

    final prefix = normalizedLicense.toLowerCase().startsWith('cc')
        ? normalizedLicense.toUpperCase()
        : 'CC ${normalizedLicense.toUpperCase()}';
    return normalizedVersion.isEmpty ? prefix : '$prefix $normalizedVersion';
  }

  static double? _parseDurationSeconds(Object? rawDuration) {
    if (rawDuration is! num) {
      return null;
    }

    final value = rawDuration.toDouble();
    if (value <= 0) {
      return null;
    }

    return value > 1000 ? value / 1000 : value;
  }
}

class MainlandLibraryAudioResult {
  final String id;
  final String name;
  final String description;
  final String category;
  final String soundscapeId;
  final List<String> tags;

  const MainlandLibraryAudioResult({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.soundscapeId,
    required this.tags,
  });

  factory MainlandLibraryAudioResult.fromJson(Map<String, dynamic> json) {
    final tags = (json['tags'] as List? ?? const [])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return MainlandLibraryAudioResult(
      id: (json['id'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      category: (json['category'] as String? ?? '').trim(),
      soundscapeId: (json['soundscapeId'] as String? ?? '').trim(),
      tags: tags,
    );
  }
}

class SoundApiService {
  SoundApiService() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 20)
      ..receiveTimeout = const Duration(seconds: 20)
      ..headers['User-Agent'] =
          'FocusBell/1.0 (https://github.com/StayGoldTY/focus-bell)';
  }

  final Dio _dio = Dio();
  List<MainlandLibraryAudioResult>? _mainlandLibraryCache;

  Future<List<MainlandLibraryAudioResult>> searchMainlandLibraryAudio({
    required String query,
    int limit = 12,
  }) async {
    final library = await _loadMainlandLibraryCatalog();
    if (library.isEmpty) {
      return [];
    }

    final trimmedQuery = query.trim().toLowerCase();
    final results = library.where((item) {
      if (trimmedQuery.isEmpty) {
        return true;
      }
      final haystack = [
        item.name,
        item.description,
        item.category,
        ...item.tags,
      ].join(' ').toLowerCase();
      return haystack.contains(trimmedQuery);
    }).toList();

    results.sort((left, right) {
      final scoreCompare = _scoreMainlandLibraryResult(
        right,
        trimmedQuery,
      ).compareTo(_scoreMainlandLibraryResult(left, trimmedQuery));
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return left.name.compareTo(right.name);
    });

    return results.take(limit).toList();
  }

  Future<List<MainlandLibraryAudioResult>> _loadMainlandLibraryCatalog() async {
    if (_mainlandLibraryCache != null) {
      return _mainlandLibraryCache!;
    }

    try {
      final raw = await rootBundle.loadString(
        AppConstants.mainlandLibraryCatalogPath,
      );
      final decoded = jsonDecode(raw) as List;
      _mainlandLibraryCache = decoded
          .map(
            (item) => MainlandLibraryAudioResult.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .where(
            (item) =>
                item.id.isNotEmpty &&
                item.name.isNotEmpty &&
                item.soundscapeId.isNotEmpty,
          )
          .toList();
      return _mainlandLibraryCache!;
    } catch (_) {
      _mainlandLibraryCache = const [];
      return _mainlandLibraryCache!;
    }
  }

  int _scoreMainlandLibraryResult(
    MainlandLibraryAudioResult item,
    String query,
  ) {
    if (query.isEmpty) {
      return 1;
    }

    var score = 0;
    final searchable = [
      item.name,
      item.description,
      item.category,
      ...item.tags,
    ].join(' ').toLowerCase();

    if (item.name.toLowerCase().contains(query)) {
      score += 6;
    }
    if (item.category.toLowerCase().contains(query)) {
      score += 3;
    }
    if (item.description.toLowerCase().contains(query)) {
      score += 2;
    }
    for (final tag in item.tags) {
      if (tag.toLowerCase().contains(query)) {
        score += 4;
      }
    }

    if (searchable.contains(query)) {
      score += 1;
    }

    return score;
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

  Future<List<OpenverseAudioResult>> searchOpenverseAudio({
    required String query,
    int limit = 12,
    double minDurationSeconds = 45,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return [];
    }

    try {
      final response = await _dio.get(
        AppConstants.openverseApiUrl,
        queryParameters: {
          'q': _normalizeOpenverseQuery(trimmedQuery),
          'mature': false,
          'page_size': limit * 4,
        },
      );

      final data = response.data;
      if (data is! Map) {
        return [];
      }

      final preferAmbientProviders = _shouldPreferAmbientProviders(
        trimmedQuery,
      );
      final results = (data['results'] as List? ?? const [])
          .map(
            (item) =>
                OpenverseAudioResult.fromJson(item as Map<String, dynamic>),
          )
          .where(_isPlayableOpenverseResult)
          .where(
            (item) =>
                item.durationSeconds == null ||
                item.durationSeconds! >= minDurationSeconds,
          )
          .where(
            (item) =>
                !preferAmbientProviders ||
                !_musicFirstProviders.contains(item.provider.toLowerCase()),
          )
          .toList();

      results.sort((left, right) {
        final scoreCompare = _scoreOpenverseResult(
          right,
          trimmedQuery,
        ).compareTo(_scoreOpenverseResult(left, trimmedQuery));
        if (scoreCompare != 0) {
          return scoreCompare;
        }

        final durationCompare = (right.durationSeconds ?? 0).compareTo(
          left.durationSeconds ?? 0,
        );
        if (durationCompare != 0) {
          return durationCompare;
        }

        return left.title.compareTo(right.title);
      });

      return results.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  bool _isPlayableOpenverseResult(OpenverseAudioResult item) {
    return item.fileUrl.isNotEmpty &&
        item.fileType.isNotEmpty &&
        _supportedOpenverseFileTypes.contains(item.fileType);
  }

  int _scoreOpenverseResult(OpenverseAudioResult item, String query) {
    var score = 0;
    final searchableText = [
      item.title,
      item.creator,
      item.provider,
      ...item.tags,
    ].join(' ').toLowerCase();

    for (final token in _tokenizeQuery(query)) {
      if (searchableText.contains(token)) {
        score += 3;
      }
    }

    for (final hint in _ambientKeywordHints) {
      if (searchableText.contains(hint)) {
        score += 2;
      }
    }

    final provider = item.provider.toLowerCase();
    if (_ambientFirstProviders.contains(provider)) {
      score += 3;
    }

    final duration = item.durationSeconds ?? 0;
    if (duration >= 600) {
      score += 6;
    } else if (duration >= 180) {
      score += 5;
    } else if (duration >= 60) {
      score += 3;
    }

    if (item.fileType == 'mp3' || item.fileType == 'ogg') {
      score += 1;
    }

    return score;
  }

  String _normalizeOpenverseQuery(String query) {
    final lower = query.toLowerCase();
    if (_looksLikeMusicQuery(lower) || _hasAmbientHint(lower)) {
      return query;
    }
    return '$query ambience';
  }

  bool _shouldPreferAmbientProviders(String query) {
    return !_looksLikeMusicQuery(query.toLowerCase());
  }

  bool _looksLikeMusicQuery(String query) {
    return _musicQueryKeywords.any(query.contains);
  }

  bool _hasAmbientHint(String query) {
    return _ambientKeywordHints.any(query.contains);
  }

  Iterable<String> _tokenizeQuery(String query) {
    return query
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where(
          (token) => token.length >= 2 && !_queryStopWords.contains(token),
        );
  }

  void dispose() {
    _dio.close();
  }
}
