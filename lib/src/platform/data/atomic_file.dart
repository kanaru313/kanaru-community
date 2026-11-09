import 'dart:io';

/// Writes [contents] to [file] through `<file>.tmp` + rename, so a crash never
/// leaves a half-written file.
Future<void> writeFileAtomic(File file, String contents) async {
  final tmp = File('${file.path}.tmp');
  await tmp.writeAsString(contents, flush: true);
  await tmp.rename(file.path);
}
