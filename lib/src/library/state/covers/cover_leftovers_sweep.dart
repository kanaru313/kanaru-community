import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../platform/data/image_picker_leftovers.dart';
import '../../data/scan/native_cover_import.dart' show coverPreviewPrefix;
import '../custom_cover_providers.dart';

final _log = Logger('library.cover_dialog');

/// Preview files older than this are leftovers of a dialog that never got to
/// clean up (the app was killed); a dialog that is open keeps its own young.
const Duration coverLeftoverAge = Duration(hours: 1);

/// Removes what the cover dialog may have left behind: picker copies and a
/// pick lost to process death (Android), and old preview files in
/// [previewDir]. Meant for the background after the first frame; never
/// throws. [cleanPicker] is replaced in tests.
Future<void> sweepCoverLeftovers({
  required Directory previewDir,
  Future<void> Function() cleanPicker = cleanImagePickerLeftovers,
  DateTime Function() now = DateTime.now,
}) async {
  try {
    await cleanPicker();
    await deleteOldFiles(
      previewDir,
      match: (name) => name.startsWith(coverPreviewPrefix),
      maxAge: coverLeftoverAge,
      now: now,
    );
  } on Object catch (e, st) {
    _log.warning('cover leftovers sweep failed', e, st);
  }
}

/// The startup sweep of [sweepCoverLeftovers] with the app's folders; called
/// once from the scan startup hook.
final coverLeftoversSweepProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    try {
      await sweepCoverLeftovers(previewDir: ref.read(coverPreviewDirProvider));
    } on Object catch (e, st) {
      _log.warning('cover leftovers sweep not started', e, st);
    }
  },
);
