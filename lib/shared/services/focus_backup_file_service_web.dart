// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

Future<void> downloadBackupFile(String fileName, String content) async {
  final blob = html.Blob(<Object>[utf8.encode(content)], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

Future<String?> pickBackupFileText() async {
  final input = html.FileUploadInputElement()
    ..accept = '.json,application/json';
  final completer = Completer<String?>();

  input.onChange.first.then((_) {
    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) {
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.onLoadEnd.first.then((_) {
      completer.complete(reader.result as String?);
    });
    reader.onError.first.then((_) {
      completer.completeError(
        StateError('Failed to read the selected backup file.'),
      );
    });
    reader.readAsText(file);
  });

  input.click();
  return completer.future;
}
