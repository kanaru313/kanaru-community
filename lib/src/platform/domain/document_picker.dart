import 'dart:typed_data';

import '../../foundation/result.dart';

/// Which documents a picker offers: a label plus extensions (no dot, any
/// case) and MIME types. Providers often report a wrong MIME type, so the
/// extensions are the final check.
class DocumentFilter {
  const DocumentFilter({
    required this.label,
    required this.extensions,
    this.mimeTypes = const [],
  });

  final String label;
  final List<String> extensions;
  final List<String> mimeTypes;

  /// True when [name] ends with one of [extensions] (case-insensitive).
  bool matchesName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return false;
    final ext = name.substring(dot + 1).toLowerCase();
    return extensions.any((e) => e.toLowerCase() == ext);
  }
}

/// A document the user picked.
class PickedDocument {
  const PickedDocument({
    required this.name,
    required this.handle,
    this.localPath,
  });

  /// Display name with extension.
  final String name;

  /// Absolute filesystem path when known (Linux: always; Android: only for
  /// providers whose ids map to a path, else null).
  final String? localPath;

  /// Linux: the path. Android: the content URI. Opaque for callers.
  final String handle;
}

/// A place the user chose to create a document at.
class SaveTarget {
  const SaveTarget({
    required this.name,
    required this.handle,
    this.localPath,
    this.exists = false,
  });

  /// Final display name (the provider may have renamed it on a collision).
  final String name;
  final String? localPath;
  final String handle;

  /// True when a file is already there (Linux only; Android always creates
  /// a new document).
  final bool exists;
}

enum DocumentError {
  /// Not a regular file, missing, or of the wrong type.
  notAFile,

  /// Bigger than the allowed size.
  tooLarge,

  /// Reading failed (permission, vanished, I/O).
  unreadable,

  /// Writing failed.
  unwritable,

  /// No picker on this platform.
  unsupported,
}

enum DocumentPickerFailure {
  /// Another dialog of the app is still open.
  busy,

  /// The system dialog is missing or could not start.
  unavailable,

  /// The dialog or the provider failed.
  failed,
}

/// Thrown by [DocumentPicker.openDocument] / [DocumentPicker.createDocument]
/// for every dialog failure, so callers never meet a platform exception.
class DocumentPickerException implements Exception {
  const DocumentPickerException(this.failure, [this.message]);

  final DocumentPickerFailure failure;
  final String? message;

  @override
  String toString() => 'DocumentPickerException(${failure.name}, $message)';
}

/// Opens and creates single user documents through the system dialogs.
abstract interface class DocumentPicker {
  /// Shows the open dialog; null when cancelled. Throws
  /// [DocumentPickerException] when the dialog fails (never on Linux: busy).
  ///
  /// The picker does not enforce [filter] (dialogs treat it as a hint): the
  /// caller checks `filter.matchesName(doc.name)` and treats a mismatch as
  /// [DocumentError.notAFile].
  Future<PickedDocument?> openDocument(DocumentFilter filter);

  /// Shows the save dialog; null when cancelled. Throws
  /// [DocumentPickerException] like [openDocument].
  ///
  /// With [filter], Linux appends `.<first extension>` unless the typed name
  /// already ends in one of its extensions, then reports `exists`, `name` and
  /// `handle` of that final path. On Android the MIME type comes from the
  /// extension of [suggestedName] and the provider picks the final name.
  Future<SaveTarget?> createDocument({
    required String suggestedName,
    DocumentFilter? filter,
  });

  /// Reads at most [maxBytes]; more is [DocumentError.tooLarge].
  Future<Result<Uint8List, DocumentError>> read(
    PickedDocument doc, {
    required int maxBytes,
  });

  /// Replaces the content of [target] with [bytes].
  Future<Result<void, DocumentError>> write(SaveTarget target, Uint8List bytes);

  /// Gives up a created target: Android deletes the empty document, Linux
  /// does nothing (nothing exists until [write]).
  Future<void> discard(SaveTarget target);
}
