import 'dart:io';

/// An image the user chose, ready to be read by the app.
class PickedImage {
  const PickedImage({
    required this.file,
    required this.name,
    required this.temporary,
    this.nameIsGenerated = false,
  });

  /// The image on disk.
  final File file;

  /// File name shown to the user (the original name where the platform
  /// reports it).
  final String name;

  /// True when [file] is a copy the app made: whoever holds the
  /// [PickedImage] deletes it when done. False for the user's own file, which
  /// must never be deleted.
  final bool temporary;

  /// True when [name] was invented by the picker (not the user's file name),
  /// so the UI shows a neutral label instead.
  final bool nameIsGenerated;
}

/// Lets the user choose one image from the device.
abstract interface class ImageFilePicker {
  /// Opens the platform picker; null when the user cancels. No permission is
  /// requested. Bytes are returned as chosen (no resize, no re-encode).
  Future<PickedImage?> pick();
}
