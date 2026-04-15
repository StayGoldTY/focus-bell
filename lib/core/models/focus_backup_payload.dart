import 'dart:convert';

import 'focus_session_record.dart';

class FocusBackupPayload {
  final int version;
  final DateTime exportedAt;
  final String deviceId;
  final Map<String, Object?> settings;
  final Map<String, Object?> stats;
  final List<FocusSessionRecord> sessions;

  const FocusBackupPayload({
    required this.version,
    required this.exportedAt,
    required this.deviceId,
    required this.settings,
    required this.stats,
    required this.sessions,
  });

  factory FocusBackupPayload.fromJson(Map<String, dynamic> json) {
    final settings = Map<String, Object?>.from(json['settings'] as Map);
    final stats = Map<String, Object?>.from(json['stats'] as Map);
    final sessionsJson = (json['sessions'] as List<dynamic>)
        .cast<Map<dynamic, dynamic>>();

    return FocusBackupPayload(
      version: json['version'] as int,
      exportedAt: DateTime.parse(json['exportedAt'] as String).toLocal(),
      deviceId: json['deviceId'] as String,
      settings: settings,
      stats: stats,
      sessions: sessionsJson
          .map(
            (item) =>
                FocusSessionRecord.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  factory FocusBackupPayload.fromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup payload must be a JSON object.');
    }
    return FocusBackupPayload.fromJson(decoded);
  }

  Map<String, Object?> toJson() {
    return {
      'version': version,
      'exportedAt': exportedAt.toIso8601String(),
      'deviceId': deviceId,
      'settings': settings,
      'stats': stats,
      'sessions': sessions.map((record) => record.toJson()).toList(),
    };
  }

  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}
