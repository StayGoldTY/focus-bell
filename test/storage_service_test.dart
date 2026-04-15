import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_bell/core/constants/app_constants.dart';
import 'package:focus_bell/core/models/focus_backup_payload.dart';
import 'package:focus_bell/core/models/focus_session_record.dart';
import 'package:focus_bell/shared/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService', () {
    test('initializes daily goal from focus duration when missing', () async {
      SharedPreferences.setMockInitialValues({'focusDuration': 75});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      expect(storage.dailyGoalMinutes, 75);
      expect(prefs.getInt('dailyGoalMinutes'), 75);
    });

    test(
      'restores exported backup including legacy cumulative stats',
      () async {
        SharedPreferences.setMockInitialValues({
          'focusDuration': 90,
          'totalFocusSeconds': 5400,
          'completedSessions': 3,
          'todayFocusSeconds': 1200,
          'todayDate': '2026-04-14',
          'currentStreak': 2,
          'bestStreak': 5,
          'lastFocusDate': '2026-04-14',
        });

        final sourcePrefs = await SharedPreferences.getInstance();
        final sourceStorage = StorageService(sourcePrefs);
        final backup = sourceStorage.exportBackup();

        SharedPreferences.setMockInitialValues({});
        final targetPrefs = await SharedPreferences.getInstance();
        final targetStorage = StorageService(targetPrefs);
        await targetStorage.restoreBackup(
          FocusBackupPayload.fromJsonString(backup.toJsonString()),
        );

        expect(targetStorage.totalFocusSeconds, 5400);
        expect(targetStorage.completedSessions, 3);
        expect(targetStorage.currentStreak, 2);
        expect(targetStorage.bestStreak, 5);
      },
    );

    test('keeps only the latest history records up to the limit', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      final base = DateTime(2026, 4, 1, 8);
      for (var index = 0; index < AppConstants.focusHistoryLimit + 5; index++) {
        await storage.appendSessionRecord(
          _buildRecord(
            id: 'session-$index',
            startedAt: base.add(Duration(minutes: index * 5)),
            actualFocusSeconds: 1800,
          ),
        );
      }

      final records = storage.getSessionRecords();
      expect(records.length, AppConstants.focusHistoryLimit);
      expect(records.any((record) => record.id == 'session-0'), isFalse);
      expect(records.any((record) => record.id == 'session-4'), isFalse);
      expect(records.any((record) => record.id == 'session-5'), isTrue);
      expect(records.any((record) => record.id == 'session-2004'), isTrue);
    });

    test('recomputes stats from session records', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      await storage.appendSessionRecord(
        _buildRecord(
          id: 'day-1',
          startedAt: DateTime(2026, 4, 12, 9),
          actualFocusSeconds: 1800,
          status: FocusSessionStatus.completed,
        ),
      );
      await storage.appendSessionRecord(
        _buildRecord(
          id: 'day-2',
          startedAt: DateTime(2026, 4, 13, 9),
          actualFocusSeconds: 1200,
          status: FocusSessionStatus.stopped,
        ),
      );
      await storage.appendSessionRecord(
        _buildRecord(
          id: 'day-3',
          startedAt: DateTime(2026, 4, 14, 9),
          actualFocusSeconds: 3600,
          status: FocusSessionStatus.completed,
        ),
      );

      await storage.recomputeStatsFromRecords(now: DateTime(2026, 4, 14, 12));

      expect(storage.totalFocusSeconds, 6600);
      expect(storage.completedSessions, 2);
      expect(storage.todayFocusSeconds, 3600);
      expect(storage.currentStreak, 3);
      expect(storage.bestStreak, 3);
      expect(storage.lastFocusDate, '2026-04-14');
    });
  });
}

FocusSessionRecord _buildRecord({
  required String id,
  required DateTime startedAt,
  required int actualFocusSeconds,
  FocusSessionStatus status = FocusSessionStatus.completed,
}) {
  return FocusSessionRecord(
    id: id,
    deviceId: 'device-test',
    schemaVersion: AppConstants.focusSessionSchemaVersion,
    startedAt: startedAt,
    endedAt: startedAt.add(Duration(seconds: actualFocusSeconds)),
    actualFocusSeconds: actualFocusSeconds,
    plannedFocusSeconds: 5400,
    microRestCount: 2,
    status: status,
    presetId: 'classic_brac',
    focusSoundId: 'brown_noise',
    taskTitle: '测试任务',
    taskCategoryId: 'study',
  );
}
