import '../../platform/domain/document_picker.dart';
import 'app_font.dart';

/// A font the user imported from a file.
class CustomFont {
  const CustomFont({required this.id, required this.label});

  /// `custom_<slug>_<hash>`; also its family name in the engine.
  final String id;

  /// Family name read from the file.
  final String label;

  AppFont get asAppFont =>
      AppFont(id: id, label: label, family: id, kind: AppFontKind.custom);
}

/// Why an import was refused; nothing is kept in any of these cases.
enum CustomFontError {
  /// Over [maxCustomFontBytes].
  tooLarge,

  /// Not a usable `.ttf` / `.otf`, or unreadable.
  invalid,

  /// The file could not be stored.
  unwritable,
}

class CustomFontException implements Exception {
  const CustomFontException(this.error, [this.detail]);

  final CustomFontError error;
  final String? detail;

  @override
  String toString() => 'CustomFontException(${error.name}, $detail)';
}

/// Filter of the import dialog. Android providers report font MIME types
/// inconsistently, so [withMimeTypes] lists the usual ones (the picker adds
/// the generic one); on Linux the
/// extensions alone are used (a generic MIME type would show every binary).
/// The extension check stays the final word.
DocumentFilter customFontDocumentFilter({
  required String label,
  required bool withMimeTypes,
}) => DocumentFilter(
  label: label,
  extensions: const ['ttf', 'otf'],
  mimeTypes: withMimeTypes
      ? const [
          'font/ttf',
          'font/otf',
          'font/sfnt',
          'application/x-font-ttf',
          'application/x-font-otf',
          'application/font-sfnt',
          'application/vnd.ms-opentype',
          'application/x-font-opentype',
        ]
      : const [],
);
