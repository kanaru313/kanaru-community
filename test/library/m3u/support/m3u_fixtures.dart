import 'dart:convert';
import 'dart:typed_data';

import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';
import 'package:kanaru/src/storage/data/m3u/m3u_line_resolver.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_parse.dart';

/// A resolved line: [path] for a found file, else [reason] (and optionally
/// [candidate]).
M3uResolvedLine rline(
  String text, {
  String? path,
  String? candidate,
  M3uUnresolvedReason? reason,
  M3uExtInf? extinf,
  int line = 1,
}) => M3uResolvedLine(
  M3uEntry(line: line, text: text, extinf: extinf),
  path: path,
  candidatePath: candidate,
  reason: reason,
);

/// An in-memory picker: `files` by handle, records writes and discards.
class FakePicker implements DocumentPicker {
  final Map<String, Uint8List> files = {};
  final List<({SaveTarget target, String text})> writes = [];
  final List<SaveTarget> discarded = [];
  Result<void, DocumentError> writeResult = const Ok(null);

  /// Thrown by [write] when set.
  Object? writeThrows;

  void put(String handle, String text) =>
      files[handle] = Uint8List.fromList(utf8.encode(text));

  String? get lastText => writes.isEmpty ? null : writes.last.text;

  @override
  Future<Result<Uint8List, DocumentError>> read(
    PickedDocument doc, {
    required int maxBytes,
  }) async {
    final bytes = files[doc.handle];
    if (bytes == null) return const Err(DocumentError.unreadable);
    if (bytes.length > maxBytes) return const Err(DocumentError.tooLarge);
    return Ok(bytes);
  }

  @override
  Future<Result<void, DocumentError>> write(
    SaveTarget target,
    Uint8List bytes,
  ) async {
    if (writeThrows != null) throw writeThrows!;
    if (writeResult is Ok) {
      writes.add((target: target, text: utf8.decode(bytes)));
    }
    return writeResult;
  }

  @override
  Future<void> discard(SaveTarget target) async => discarded.add(target);

  @override
  Future<PickedDocument?> openDocument(DocumentFilter filter) =>
      throw UnimplementedError();

  @override
  Future<SaveTarget?> createDocument({
    required String suggestedName,
    DocumentFilter? filter,
  }) => throw UnimplementedError();
}

/// Counts `rescan` calls; throws [failure] when set.
class FakeScans implements LibraryScanCommands {
  int calls = 0;
  Object? failure;

  @override
  Future<void> rescan({bool full = false}) async {
    calls++;
    if (failure != null) throw failure!;
  }
}
