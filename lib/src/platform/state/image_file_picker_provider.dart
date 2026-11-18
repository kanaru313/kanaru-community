import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/image_file_picker_android.dart';
import '../data/image_file_picker_linux.dart';
import '../domain/image_file_picker.dart';

/// Image picker of the running platform. Tests override it.
final imageFilePickerProvider = Provider<ImageFilePicker>((ref) {
  if (Platform.isAndroid) return AndroidImageFilePicker();
  return LinuxImageFilePicker();
});
