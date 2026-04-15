Future<void> downloadBackupFile(String fileName, String content) async {
  throw UnsupportedError('Backup export is only supported on the web build.');
}

Future<String?> pickBackupFileText() async {
  throw UnsupportedError('Backup import is only supported on the web build.');
}
