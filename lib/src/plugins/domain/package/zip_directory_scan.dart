import 'dart:math';
import 'dart:typed_data';

import 'package_limits.dart';
import 'package_problem.dart';

// Record signatures, little endian.
const _endSignature = 0x06054b50;
const _zip64LocatorSignature = 0x07064b50;
const _centralSignature = 0x02014b50;
const _localSignature = 0x04034b50;

// Caps on the variable parts of a record. A legitimate plugin zip stays far
// below them; they bound what the zip parser may allocate per record.
const _maxNameLength = 1024;
const _maxExtraLength = 1024;
const _maxCommentLength = 1024;

PackageProblemError _notZip(String reason) =>
    PackageProblemError(NotAZip(reason));

/// Checks the central directory before the zip parser sees it, and returns
/// the number of entries the end record announces.
///
/// The parser builds an object graph per central record (and reads the local
/// header each one points at), so a few thousand tiny records aimed at one
/// large local header would use far more memory than the file is big. This
/// walk is cheap (it skips records by their lengths) and refuses before that:
///
/// - zip64 and multi-disk archives (a plugin of at most 5 MiB never needs
///   them);
/// - more than [maxZipEntries] entries (`TooManyEntries`), counted on the end
///   record first and again while walking, stopping at the first record over
///   the cap;
/// - a walk that does not end exactly at the announced count and size;
/// - over-long names, extra fields and comments, in central and local headers;
/// - entries whose local header plus data overlap each other or the central
///   directory (two records on one local header included);
/// - an end record that closes the file (no trailing data, no fake record
///   hidden in the comment);
/// - a local header that disagrees with its central record on name, method
///   or flags.
///
/// Throws [PackageProblemError]: `NotAZip` unless stated.
int scanZipDirectory(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final end = _findEndRecord(bytes, data);
  if (end < 0) throw _notZip('no end record');
  if (end >= 20 &&
      data.getUint32(end - 20, Endian.little) == _zip64LocatorSignature) {
    throw _notZip('zip64');
  }
  final thisDisk = data.getUint16(end + 4, Endian.little);
  final directoryDisk = data.getUint16(end + 6, Endian.little);
  final diskEntries = data.getUint16(end + 8, Endian.little);
  final total = data.getUint16(end + 10, Endian.little);
  final size = data.getUint32(end + 12, Endian.little);
  final offset = data.getUint32(end + 16, Endian.little);
  if (total == 0xffff || size == 0xffffffff || offset == 0xffffffff) {
    throw _notZip('zip64');
  }
  if (thisDisk != 0 || directoryDisk != 0 || diskEntries != total) {
    throw _notZip('multi-disk');
  }
  if (total > maxZipEntries) throw const PackageProblemError(TooManyEntries());
  if (offset + size > end) throw _notZip('directory out of range');

  var position = offset;
  var walked = 0;
  final ranges = <(int, int)>[];
  while (position < offset + size) {
    if (walked >= maxZipEntries) {
      throw const PackageProblemError(TooManyEntries());
    }
    if (position + 46 > offset + size ||
        data.getUint32(position, Endian.little) != _centralSignature) {
      throw _notZip('bad central record');
    }
    final nameLength = data.getUint16(position + 28, Endian.little);
    final extraLength = data.getUint16(position + 30, Endian.little);
    final commentLength = data.getUint16(position + 32, Endian.little);
    if (nameLength > _maxNameLength ||
        extraLength > _maxExtraLength ||
        commentLength > _maxCommentLength) {
      throw _notZip('over-long record field');
    }
    // All-ones marks a value that lives in a zip64 extra field.
    final compressed = data.getUint32(position + 20, Endian.little);
    final localOffset = data.getUint32(position + 42, Endian.little);
    if (compressed == 0xffffffff ||
        data.getUint32(position + 24, Endian.little) == 0xffffffff ||
        localOffset == 0xffffffff) {
      throw _notZip('zip64');
    }
    if (position + 46 + nameLength > offset + size) {
      throw _notZip('bad central record');
    }
    final headerEnd = _checkLocalHeader(
      bytes,
      data,
      localOffset,
      offset,
      centralAt: position,
      centralNameLength: nameLength,
    );
    ranges.add((localOffset, headerEnd + compressed));
    position += 46 + nameLength + extraLength + commentLength;
    walked++;
  }
  if (position != offset + size || walked != total) {
    throw _notZip('directory does not match the end record');
  }
  _checkNoOverlap(ranges, offset);
  return total;
}

/// The local header an entry points at is parsed too: bound its lengths and
/// compare its name, method and flags with the central record (the zip
/// parser reads the central values only, other readers the local ones). The
/// data-descriptor flag (bit 3) may differ, as writers that stream set it in
/// one place only. Returns where its data starts.
int _checkLocalHeader(
  Uint8List bytes,
  ByteData data,
  int at,
  int directoryStart, {
  required int centralAt,
  required int centralNameLength,
}) {
  if (at + 30 > directoryStart ||
      data.getUint32(at, Endian.little) != _localSignature) {
    throw _notZip('bad local header');
  }
  final nameLength = data.getUint16(at + 26, Endian.little);
  final extraLength = data.getUint16(at + 28, Endian.little);
  if (nameLength > _maxNameLength || extraLength > _maxExtraLength) {
    throw _notZip('over-long record field');
  }
  const descriptorBit = 0x8;
  final centralFlags = data.getUint16(centralAt + 8, Endian.little);
  final localFlags = data.getUint16(at + 6, Endian.little);
  if (nameLength != centralNameLength ||
      (centralFlags & ~descriptorBit) != (localFlags & ~descriptorBit) ||
      data.getUint16(centralAt + 10, Endian.little) !=
          data.getUint16(at + 8, Endian.little) ||
      !_sameBytes(bytes, centralAt + 46, at + 30, nameLength)) {
    throw _notZip('local header differs from the directory');
  }
  final dataStart = at + 30 + nameLength + extraLength;
  if (dataStart > directoryStart) throw _notZip('bad local header');
  return dataStart;
}

bool _sameBytes(Uint8List bytes, int a, int b, int length) {
  for (var i = 0; i < length; i++) {
    if (bytes[a + i] != bytes[b + i]) return false;
  }
  return true;
}

/// Each entry's local header and data (as the central record sizes them)
/// must end before the next one starts, and the last before the directory.
/// A data descriptor, which follows the data, only widens the gap.
void _checkNoOverlap(List<(int, int)> ranges, int directoryStart) {
  ranges.sort((a, b) => a.$1.compareTo(b.$1));
  for (var i = 0; i < ranges.length; i++) {
    final limit = i + 1 < ranges.length ? ranges[i + 1].$1 : directoryStart;
    if (ranges[i].$2 > limit) throw _notZip('overlapping entries');
  }
}

/// Offset of the end record, or -1. The zip parser takes the first end
/// signature found scanning back from 22 bytes before the end (the last one
/// in the file); so do we, and it must close the file: its comment length
/// reaches exactly the end. Other signature bytes earlier in the file (a
/// stored nested zip, binary data) are ignored, and a fake record inside the
/// real comment lies after the real one's start, so it is the one found and
/// fails the closing check.
int _findEndRecord(Uint8List bytes, ByteData data) {
  final lowest = max(0, bytes.length - 22 - 0xffff);
  for (var i = bytes.length - 22; i >= lowest; i--) {
    if (data.getUint32(i, Endian.little) != _endSignature) continue;
    final commentLength = data.getUint16(i + 20, Endian.little);
    if (i + 22 + commentLength != bytes.length) {
      throw _notZip('end record does not close the file');
    }
    return i;
  }
  return -1;
}
