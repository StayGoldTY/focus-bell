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
      previewUrl: (previews['preview-lq-mp3'] ?? previews['preview-hq-mp3'] ?? '') as String,
      duration: (json['duration'] as num?)?.toDouble() ?? 0,
      username: json['username'] as String? ?? '',
    );
  }
}

class SoundApiService {
  final Dio _dio = Dio();

  // Freesound API Key（用户可在设置中配置自己的 key）
  String? _freesoundApiKey;
  String? _soundscapeApiKey;

  void setFreesoundApiKey(String key) => _freesoundApiKey = key;
  void setSoundscapeApiKey(String key) => _soundscapeApiKey = key;

  /// 搜索 Freesound 音效
  Future<List<FreesoundResult>> searchFreesound({
    required String query,
    int pageSize = 15,
    double maxDuration = 5.0,
  }) async {
    if (_freesoundApiKey == null || _freesoundApiKey!.isEmpty) return [];

    try {
      final response = await _dio.get(
        '${AppConstants.freesoundBaseUrl}/search/text/',
        queryParameters: {
          'query': query,
          'filter': 'duration:[0 TO $maxDuration]',
          'fields': 'id,name,previews,duration,username',
          'page_size': pageSize,
          'token': _freesoundApiKey,
        },
      );

      final results = response.data['results'] as List? ?? [];
      return results
          .map((e) => FreesoundResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 获取 Soundscape City 环境音 URL
  Future<String?> getSoundscapeUrl({required String environment}) async {
    if (_soundscapeApiKey == null || _soundscapeApiKey!.isEmpty) return null;

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
