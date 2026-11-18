import 'dart:io';

import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final _log = Logger('platform.image_picker_leftovers');

/// Deletes regular files in [dir] (not its subfolders) whose name satisfies
/// [match] and that were last modified more than [maxAge] ago. Links are never
/// followed or deleted. A missing [dir] is fine; errors are logged, never
/// thrown. Returns the number of files deleted.
Future<int> deleteOldFiles(
  Directory dir, {
  required bool Function(String name) match,
  Duration maxAge = const Duration(hours: 1),
  DateTime Function() now = DateTime.now,
}) async {
  var deleted = 0;
  try {
    if (!await dir.exists()) return 0;
    final cutoff = now().subtract(maxAge);
    await for (final entry in dir.list(followLinks: false)) {
      try {
        // `stat` follows links, so the type is read without following.
        final type = await FileSystemEntity.type(
          entry.path,
          followLinks: false,
        );
        if (type != FileSystemEntityType.file) continue;
        if (!match(p.basename(entry.path))) continue;
        if (!(await entry.stat()).modified.isBefore(cutoff)) continue;
        await entry.delete();
        deleted++;
      } on FileSystemException catch (e) {
        _log.warning('cannot sweep ${entry.path}: $e');
      }
    }
  } on FileSystemException catch (e) {
    _log.warning('cannot sweep ${dir.path}: $e');
  }
  return deleted;
}

final _uuidName = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// image_picker (Android) copies each pick to `{cacheDir}/{uuid}/{fileName}`
/// (`FileUtils.getPathFromUri`; `cacheDir` = [getTemporaryDirectory]). Deletes
/// copies older than [maxAge] inside those uuid folders and the folders left
/// empty. Returns the number of files deleted.
Future<int> sweepPickerCache(
  Directory cacheDir, {
  Duration maxAge = const Duration(hours: 1),
  DateTime Function() now = DateTime.now,
}) async {
  var deleted = 0;
  try {
    if (!await cacheDir.exists()) return 0;
    await for (final entry in cacheDir.list(followLinks: false)) {
      if (!_uuidName.hasMatch(p.basename(entry.path))) continue;
      if (await FileSystemEntity.type(entry.path, followLinks: false) !=
          FileSystemEntityType.directory) {
        continue;
      }
      deleted += await deleteOldFiles(
        Directory(entry.path),
        match: (_) => true,
        maxAge: maxAge,
        now: now,
      );
      try {
        await Directory(entry.path).delete(); // only succeeds when empty
      } on FileSystemException {
        // still holds a young file
      }
    }
  } on FileSystemException catch (e) {
    _log.warning('cannot sweep picker cache: $e');
  }
  return deleted;
}

/// Android startup cleanup, to run in the background after the first frame:
/// sweeps old picker copies and deletes the file of a pick lost to process
/// death (the result is not handed back to any dialog). No-op elsewhere.
Future<void> cleanImagePickerLeftovers({
  ImagePickerPlatform? platform,
  Directory? cacheDir,
}) async {
  try {
    final impl = platform ?? ImagePickerPlatform.instance;
    if (impl is! ImagePickerAndroid) return;
    final lost = await impl.getLostData();
    for (final file in lost.files ?? const <XFile>[]) {
      try {
        await File(file.path).delete();
      } on FileSystemException catch (e) {
        _log.warning('cannot delete lost pick: $e');
      }
    }
    await sweepPickerCache(cacheDir ?? await getTemporaryDirectory());
  } catch (e, st) {
    _log.warning('image picker cleanup failed', e, st);
  }
}
