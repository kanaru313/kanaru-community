import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

import '../../foundation/result.dart';
import '../domain/document_picker.dart';
import 'document_picker_linux_io.dart';

/// Shows the GTK open dialog; the chosen path or null.
typedef OpenFileDialog = Future<String?> Function(DocumentFilter filter);

/// Shows the GTK save dialog; the chosen path or null.
typedef SaveFileDialog = Future<String?> Function(
  String suggestedName,
  DocumentFilter? filter,
);

Future<String?> _defaultOpen(DocumentFilter filter) async {
  final file = await openFile(acceptedTypeGroups: [_typeGroup(filter)]);
  return file?.path;
}

Future<String?> _defaultSave(String name, DocumentFilter? filter) async {
  final location = await getSaveLocation(
    suggestedName: name,
    acceptedTypeGroups: [if (filter != null) _typeGroup(filter)],
  );
  return location?.path;
}

/// Upper-case extensions are listed too: GTK matches them case-sensitively.
XTypeGroup _typeGroup(DocumentFilter f) => XTypeGroup(
  label: f.label,
  extensions: [
    for (final e in f.extensions) ...{e.toLowerCase(), e.toUpperCase()},
  ],
  mimeTypes: f.mimeTypes,
);

/// Linux picker: GTK dialogs through `file_selector`, plain `dart:io` files.
class LinuxDocumentPicker implements DocumentPicker {
  LinuxDocumentPicker({OpenFileDialog? open, SaveFileDialog? save})
    : _open = open ?? _defaultOpen,
      _save = save ?? _defaultSave;

  final OpenFileDialog _open;
  final SaveFileDialog _save;

  @override
  Future<PickedDocument?> openDocument(DocumentFilter filter) async {
    final path = await _dialog(() => _open(filter));
    if (path == null) return null;
    return PickedDocument(
      name: path.substring(path.lastIndexOf('/') + 1),
      localPath: path,
      handle: path,
    );
  }

  @override
  Future<SaveTarget?> createDocument({
    required String suggestedName,
    DocumentFilter? filter,
  }) async {
    var path = await _dialog(() => _save(suggestedName, filter));
    if (path == null) return null;
    // The GTK dialog adds no extension: do it here, before looking at what
    // exists, so the overwrite check is about the file that will be written.
    if (filter != null &&
        filter.extensions.isNotEmpty &&
        !filter.matchesName(path.substring(path.lastIndexOf('/') + 1))) {
      // `Mix.` becomes `Mix.m3u8`, not `Mix..m3u8`.
      path =
          '${path.replaceFirst(RegExp(r'\.+$'), '')}.${filter.extensions.first}';
    }
    return SaveTarget(
      name: path.substring(path.lastIndexOf('/') + 1),
      localPath: path,
      handle: path,
      // Not following links: a dangling symlink still blocks the name.
      exists:
          FileSystemEntity.typeSync(path, followLinks: false) !=
          FileSystemEntityType.notFound,
    );
  }

  /// Runs a dialog and maps its platform errors to the domain exception.
  Future<String?> _dialog(Future<String?> Function() show) async {
    try {
      return await show();
    } on MissingPluginException catch (e) {
      throw DocumentPickerException(
        DocumentPickerFailure.unavailable,
        e.message,
      );
    } on PlatformException catch (e) {
      throw DocumentPickerException(DocumentPickerFailure.failed, e.message);
    }
  }

  @override
  Future<Result<Uint8List, DocumentError>> read(
    PickedDocument doc, {
    required int maxBytes,
  }) => readBounded(doc.handle, maxBytes);

  @override
  Future<Result<void, DocumentError>> write(
    SaveTarget target,
    Uint8List bytes,
  ) => // Atomic replace by design: the file mode becomes the default one.
      writeExclusiveTemp(target.handle, bytes);

  @override
  Future<void> discard(SaveTarget target) async {}
}
