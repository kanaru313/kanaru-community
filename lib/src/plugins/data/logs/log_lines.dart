import 'dart:convert';
import 'dart:io';

import '../../domain/logs/run_log_event.dart';

/// The non-empty lines of a log [file]; empty when it is missing or
/// unreadable. A byte that is not UTF-8 never fails the read.
Future<List<String>> readLogLines(File file) async {
  try {
    final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
    return const LineSplitter()
        .convert(text)
        .where((l) => l.isNotEmpty)
        .toList();
  } on FileSystemException {
    return const [];
  }
}

/// The event of one log [line]; null for a corrupt line.
RunLogEvent? parseLogLine(String line) {
  try {
    return RunLogEvent.tryParse(jsonDecode(line));
  } on FormatException {
    return null;
  }
}
