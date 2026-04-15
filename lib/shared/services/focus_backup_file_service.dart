import 'focus_backup_file_service_stub.dart'
    if (dart.library.html) 'focus_backup_file_service_web.dart'
    as impl;

Future<void> downloadBackupFile(String fileName, String content) {
  return impl.downloadBackupFile(fileName, content);
}

Future<String?> pickBackupFileText() {
  return impl.pickBackupFileText();
}
