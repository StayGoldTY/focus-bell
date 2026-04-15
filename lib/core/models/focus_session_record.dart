enum FocusSessionStatus { completed, stopped }

extension FocusSessionStatusX on FocusSessionStatus {
  String get value {
    switch (this) {
      case FocusSessionStatus.completed:
        return 'completed';
      case FocusSessionStatus.stopped:
        return 'stopped';
    }
  }

  static FocusSessionStatus fromValue(String value) {
    switch (value) {
      case 'completed':
        return FocusSessionStatus.completed;
      case 'stopped':
        return FocusSessionStatus.stopped;
      default:
        throw FormatException('Unknown focus session status: $value');
    }
  }
}

class FocusSessionRecord {
  final String id;
  final String deviceId;
  final int schemaVersion;
  final DateTime startedAt;
  final DateTime endedAt;
  final int actualFocusSeconds;
  final int plannedFocusSeconds;
  final int microRestCount;
  final FocusSessionStatus status;
  final String presetId;
  final String? focusSoundId;
  final String? taskTitle;
  final String? taskCategoryId;

  const FocusSessionRecord({
    required this.id,
    required this.deviceId,
    required this.schemaVersion,
    required this.startedAt,
    required this.endedAt,
    required this.actualFocusSeconds,
    required this.plannedFocusSeconds,
    required this.microRestCount,
    required this.status,
    required this.presetId,
    required this.focusSoundId,
    required this.taskTitle,
    required this.taskCategoryId,
  });

  factory FocusSessionRecord.fromJson(Map<String, dynamic> json) {
    return FocusSessionRecord(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      schemaVersion: json['schemaVersion'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String).toLocal(),
      endedAt: DateTime.parse(json['endedAt'] as String).toLocal(),
      actualFocusSeconds: json['actualFocusSeconds'] as int,
      plannedFocusSeconds: json['plannedFocusSeconds'] as int,
      microRestCount: json['microRestCount'] as int,
      status: FocusSessionStatusX.fromValue(json['status'] as String),
      presetId: json['presetId'] as String,
      focusSoundId: json['focusSoundId'] as String?,
      taskTitle: json['taskTitle'] as String?,
      taskCategoryId: json['taskCategoryId'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'schemaVersion': schemaVersion,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'actualFocusSeconds': actualFocusSeconds,
      'plannedFocusSeconds': plannedFocusSeconds,
      'microRestCount': microRestCount,
      'status': status.value,
      'presetId': presetId,
      'focusSoundId': focusSoundId,
      'taskTitle': taskTitle,
      'taskCategoryId': taskCategoryId,
    };
  }
}

String focusDateKey(DateTime time) {
  final local = time.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
