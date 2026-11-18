import 'dart:io';

import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import '../domain/image_file_picker.dart';

/// [ImageFilePicker] for Android: the system Photo Picker (no permission).
/// The plugin copies the chosen image into the app cache, so the result is
/// `temporary`. No size or quality arguments: the original bytes are kept.
class AndroidImageFilePicker implements ImageFilePicker {
  AndroidImageFilePicker({ImagePickerPlatform? platform})
    : _platform = platform ?? ImagePickerPlatform.instance {
    final impl = _platform;
    if (impl is ImagePickerAndroid) impl.useAndroidPhotoPicker = true;
  }

  final ImagePickerPlatform _platform;

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// True for names the plugin made up (`image_picker.jpg` when the provider
  /// gave no name, `scaled_` copies, a bare uuid) instead of the photo's name.
  static bool looksGenerated(String name) {
    if (name.startsWith('image_picker') || name.startsWith('scaled_')) {
      return true;
    }
    final dot = name.lastIndexOf('.');
    return _uuid.hasMatch(dot > 0 ? name.substring(0, dot) : name);
  }

  @override
  Future<PickedImage?> pick() async {
    final picked = await _platform.getImageFromSource(
      source: ImageSource.gallery,
      options: const ImagePickerOptions(requestFullMetadata: false),
    );
    if (picked == null) return null;
    final name = picked.name;
    return PickedImage(
      file: File(picked.path),
      name: name,
      temporary: true,
      nameIsGenerated: looksGenerated(name),
    );
  }
}
