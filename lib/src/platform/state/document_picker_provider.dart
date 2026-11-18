import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/document_picker_android.dart';
import '../data/document_picker_linux.dart';
import '../data/document_picker_unsupported.dart';
import '../domain/document_picker.dart';

/// True where a real [DocumentPicker] exists. The provider and every
/// feature gate (e.g. M3U import / export) use this one answer.
bool get documentPickerSupported => Platform.isLinux || Platform.isAndroid;

/// Document picker of the running platform. Tests override it.
final documentPickerProvider = Provider<DocumentPicker>((ref) {
  if (Platform.isLinux) return LinuxDocumentPicker();
  if (Platform.isAndroid) return AndroidDocumentPicker();
  return const UnsupportedDocumentPicker();
});
