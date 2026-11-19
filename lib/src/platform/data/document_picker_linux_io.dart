import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../../foundation/result.dart';
import '../domain/document_picker.dart';

const _chunk = 1024 * 1024;

/// Reads the regular file at [path], at most [maxBytes].
///
/// The type is checked before opening, so a FIFO or device is never opened
/// (opening a FIFO would block). The file is then read in 1 MiB chunks to
/// EOF, never trusting its reported size (procfs / FUSE report 0), and the
/// read stops at [maxBytes] + 1 bytes: that is [DocumentError.tooLarge].
Future<Result<Uint8List, DocumentError>> readBounded(
  String path,
  int maxBytes,
) async {
  try {
    if (FileSystemEntity.typeSync(path) != FileSystemEntityType.file) {
      return const Err(DocumentError.notAFile);
    }
    final out = BytesBuilder(copy: false);
    final raf = await File(path).open();
    try {
      while (out.length <= maxBytes) {
        final want = min(_chunk, maxBytes + 1 - out.length);
        final data = await raf.read(want);
        if (data.isEmpty) break;
        out.add(data);
      }
    } finally {
      await raf.close();
    }
    if (out.length > maxBytes) return const Err(DocumentError.tooLarge);
    return Ok(out.takeBytes());
  } on FileSystemException {
    return const Err(DocumentError.unreadable);
  }
}

/// Replaces the file at [target] with [bytes] without ever leaving half a
/// file: the bytes go to a new temporary file next to it (created
/// `exclusive`, so an existing file or symlink of that name is never reused
/// or followed), flushed, then renamed over the target. When [target] is a
/// symlink the file it points to is replaced and the link kept. The
/// temporary file is deleted on any failure.
Future<Result<void, DocumentError>> writeExclusiveTemp(
  String target,
  Uint8List bytes,
) async {
  File? temporary;
  try {
    final real = await _resolveTarget(target);
    temporary = await _createTemporary(real);
    final raf = await temporary.open(mode: FileMode.write);
    try {
      await raf.writeFrom(bytes);
      await raf.flush();
    } finally {
      await raf.close();
    }
    await temporary.rename(real);
    return const Ok(null);
  } on FileSystemException {
    if (temporary != null) {
      try {
        await temporary.delete();
      } on FileSystemException {
        // Already renamed or gone.
      }
    }
    return const Err(DocumentError.unwritable);
  }
}

/// [target] with a symlink (also in the folder part) resolved; a target
/// that does not exist yet keeps its name inside the resolved folder.
Future<String> _resolveTarget(String target) async {
  final String resolved;
  if (await FileSystemEntity.isLink(target)) {
    resolved = await File(target).resolveSymbolicLinks();
  } else {
    resolved = target;
  }
  final slash = resolved.lastIndexOf('/');
  final folder = await Directory(
    slash <= 0 ? '/' : resolved.substring(0, slash),
  ).resolveSymbolicLinks();
  final name = resolved.substring(slash + 1);
  return folder == '/' ? '/$name' : '$folder/$name';
}

/// A new, empty `<path>.<pid>[.<random>].tmp`; a clash retries with a
/// random suffix, up to 4 tries.
Future<File> _createTemporary(String path) async {
  final random = Random();
  for (var attempt = 0; ; attempt++) {
    final suffix = attempt == 0 ? '$pid' : '$pid.${random.nextInt(1 << 32)}';
    final file = File('$path.$suffix.tmp');
    try {
      return await file.create(exclusive: true);
    } on FileSystemException {
      if (attempt >= 3) rethrow;
    }
  }
}
