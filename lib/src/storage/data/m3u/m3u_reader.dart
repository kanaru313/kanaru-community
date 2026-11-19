import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../../foundation/result.dart';
import '../../../platform/domain/document_picker.dart';
import '../../domain/m3u/m3u_limits.dart';
import '../../domain/m3u/m3u_parse.dart';
import 'm3u_document_filter.dart';

/// Result of reading a picked M3U document.
sealed class M3uReadOutcome {
  const M3uReadOutcome();
}

/// The file was read and parsed. [baseDir] is the folder of the file when its
/// path is known (relative lines need it), else null.
final class M3uReadOk extends M3uReadOutcome {
  const M3uReadOk({required this.parse, required this.fileName, this.baseDir});
  final M3uParse parse;
  final String fileName;
  final String? baseDir;
}

final class M3uReadFailed extends M3uReadOutcome {
  const M3uReadFailed(this.error);
  final DocumentError error;
}

/// Reads [doc] (at most [m3uMaxBytes]) and parses it off the UI isolate. A
/// name that does not match [filter] is [DocumentError.notAFile], because the
/// picker does not enforce its filter. [parseFile] must be a top-level or
/// static function (it runs in the isolate).
Future<M3uReadOutcome> readM3u(
  DocumentPicker picker,
  PickedDocument doc, {
  DocumentFilter? filter,
  M3uParse Function(Uint8List) parseFile = parseM3u,
}) async {
  if (!(filter ?? m3uDocumentFilter()).matchesName(doc.name)) {
    return const M3uReadFailed(DocumentError.notAFile);
  }
  final read = await picker.read(doc, maxBytes: m3uMaxBytes);
  final Uint8List bytes;
  switch (read) {
    case Ok(:final value):
      bytes = value;
    case Err(:final error):
      return M3uReadFailed(error);
  }
  // A parser error is a bug: it propagates to the flow, which reports it.
  final parse = await Isolate.run(() => parseFile(bytes));
  final path = doc.localPath;
  return M3uReadOk(
    parse: parse,
    fileName: doc.name,
    baseDir: path == null ? null : _parent(path),
  );
}

String? _parent(String path) =>
    path.contains('/') ? p.posix.dirname(path) : null;
