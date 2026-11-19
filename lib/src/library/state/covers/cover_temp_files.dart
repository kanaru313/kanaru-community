import 'dart:io';

import 'package:logging/logging.dart';

final _log = Logger('library.cover_dialog');

/// Deletes [files], one after the other. A missing file is fine; any other
/// failure is logged, never thrown (it is cleanup: it must not hide the
/// outcome of the work it follows).
Future<void> deleteTempFiles(Iterable<File> files) async {
  for (final file in files) {
    try {
      await file.delete();
    } on PathNotFoundException {
      // already gone
    } on FileSystemException catch (e) {
      _log.warning('cannot delete ${file.path}: $e');
    }
  }
}
