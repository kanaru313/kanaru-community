import 'dart:typed_data';

import '../../foundation/result.dart';
import '../domain/document_picker.dart';

/// Picker for platforms without one (tests, other OS): nothing opens.
class UnsupportedDocumentPicker implements DocumentPicker {
  const UnsupportedDocumentPicker();

  @override
  Future<PickedDocument?> openDocument(DocumentFilter filter) async => null;

  @override
  Future<SaveTarget?> createDocument({
    required String suggestedName,
    DocumentFilter? filter,
  }) async => null;

  @override
  Future<Result<Uint8List, DocumentError>> read(
    PickedDocument doc, {
    required int maxBytes,
  }) async => const Err(DocumentError.unsupported);

  @override
  Future<Result<void, DocumentError>> write(
    SaveTarget target,
    Uint8List bytes,
  ) async => const Err(DocumentError.unsupported);

  @override
  Future<void> discard(SaveTarget target) async {}
}
