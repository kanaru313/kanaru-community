import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;

import '../domain/image_file_picker.dart';

/// Signature of file_selector's `openFile`, injectable for tests.
typedef OpenFileFn = Future<XFile?> Function({
  List<XTypeGroup> acceptedTypeGroups,
});

Future<XFile?> _defaultOpenFile({
  List<XTypeGroup> acceptedTypeGroups = const [],
}) => openFile(acceptedTypeGroups: acceptedTypeGroups);

/// [ImageFilePicker] for Linux: the system file dialog filtered to images.
/// Returns the user's own file (`temporary` false).
class LinuxImageFilePicker implements ImageFilePicker {
  LinuxImageFilePicker({this.label = 'Images', OpenFileFn? openFile})
    : _open = openFile ?? _defaultOpenFile;

  /// Name of the filter in the dialog (the UI passes a localized one).
  final String label;
  final OpenFileFn _open;

  /// GTK matches extensions case-sensitively, so both cases are listed.
  static const _extensions = ['jpg', 'jpeg', 'png', 'webp'];

  @override
  Future<PickedImage?> pick() async {
    final picked = await _open(
      acceptedTypeGroups: [
        XTypeGroup(
          label: label,
          extensions: [
            ..._extensions,
            ..._extensions.map((e) => e.toUpperCase()),
          ],
          mimeTypes: const ['image/jpeg', 'image/png', 'image/webp'],
        ),
      ],
    );
    if (picked == null) return null;
    return PickedImage(
      file: File(picked.path),
      name: p.basename(picked.path),
      temporary: false,
    );
  }
}
