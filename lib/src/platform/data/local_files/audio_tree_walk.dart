import 'dart:io';

import '../../domain/local_audio_catalog.dart';

/// How many folders with undecodable names a walk remembers for the log.
const maxUndecodableSamples = 3;

/// Folders under these prefixes that list empty are treated as unmounted
/// drives (their stored rows are kept), as are mount points.
const defaultRemovableMediaPrefixes = ['/media', '/run/media', '/mnt'];

/// What a walk needs; plain data so it can be sent to an isolate.
class WalkRequest {
  const WalkRequest({
    required this.root,
    this.excludedKeys = const {},
    this.mountPoints = const {},
    this.removableMediaPrefixes = defaultRemovableMediaPrefixes,
  });

  /// Absolute, canonical, no trailing slash.
  final String root;

  /// Folder keys relative to [root].
  final Set<String> excludedKeys;

  /// Mount points of the machine (`/proc/self/mounts`).
  final Set<String> mountPoints;

  /// Folders listed empty below these count as unmounted drives.
  final List<String> removableMediaPrefixes;
}

bool _isSameOrInside(String ancestor, String path) =>
    path == ancestor || path.startsWith('$ancestor/');

bool _isExcluded(String relative, Set<String> keys) {
  for (final key in keys) {
    if (relative == key || relative.startsWith('$key/')) return true;
  }
  return false;
}

/// Lists every audio file and `.lrc` sidecar under `request.root`.
///
/// Folder links are not followed (so link loops cannot trap the walk) but are
/// counted. File links are followed through `stat`; FIFOs, sockets and devices
/// are never listed (opening some blocks forever). A listed entry that cannot
/// be stat-ed (broken link, unplugged target) goes to `unstattable`. Failures
/// are reported in the result, never thrown.
///
/// Synchronous on purpose: it runs on a worker isolate.
AudioListing walkAudioTree(WalkRequest request) {
  final root = request.root;
  final audio = <LocalAudioFile>[];
  final lyrics = <LocalSidecarFile>[];
  final unreadable = <String>[];
  final unstattable = <String>[];
  final empty = <String>[];
  final sampleDirs = <String>[];
  final aliased = <String>{};
  var excludedOut = 0, skippedOut = 0, skippedLinks = 0, undecodable = 0;

  void noteUndecodable(String dir) {
    undecodable++;
    if (sampleDirs.length < maxUndecodableSamples && !sampleDirs.contains(dir)) {
      sampleDirs.add(dir);
    }
  }

  bool emptyMeansUnmounted(String dir) =>
      request.mountPoints.contains(dir) ||
      request.removableMediaPrefixes.any((prefix) => _isSameOrInside(prefix, dir));

  final relativeStart = root.endsWith('/') ? root.length : root.length + 1;
  final pending = <String>[root];
  while (pending.isNotEmpty) {
    final dir = pending.removeLast();
    final List<FileSystemEntity> entries;
    try {
      entries = Directory(dir).listSync(followLinks: false);
    } on FileSystemException {
      if (dir == root) return const AudioListing.unreachable();
      unreadable.add(dir);
      if (dir.contains('�')) {
        noteUndecodable(dir.substring(0, dir.lastIndexOf('/')));
      }
      continue;
    }
    if (entries.isEmpty && dir != root && emptyMeansUnmounted(dir)) {
      empty.add(dir);
    }
    for (final entry in entries) {
      final path = entry.path;
      final name = path.substring(path.lastIndexOf('/') + 1);
      if (entry is Directory) {
        if (isSkippedFolderName(name)) {
          // Not counted: such folders say nothing about the user's filters.
        } else if (name.contains('\uFFFD') && !aliased.add(path)) {
          // Several byte names decode to one lossy path: handle it once.
        } else if (name.contains('\uFFFD') &&
            FileSystemEntity.typeSync(path, followLinks: false) !=
                FileSystemEntityType.directory) {
          // The lossy path opens nothing: the real name is not valid UTF-8.
          noteUndecodable(dir);
        } else if (_isExcluded(
          path.substring(relativeStart),
          request.excludedKeys,
        )) {
          excludedOut++;
        } else {
          pending.add(path);
        }
        continue;
      }
      final isAudio = isAudioPath(path);
      if (!isAudio && !isLyricsSidecarPath(path)) {
        if (entry is Link &&
            FileSystemEntity.typeSync(path) == FileSystemEntityType.directory) {
          skippedLinks++;
        }
        continue;
      }
      if (name.startsWith('.')) {
        skippedOut++;
        continue;
      }
      final stat = FileStat.statSync(path);
      final lossy = path.contains('�');
      if (lossy && stat.type != FileSystemEntityType.file) {
        // The lossy path opens nothing: the real name is not valid UTF-8.
        unstattable.add(path);
        noteUndecodable(dir);
        continue;
      }
      // Several different byte names can decode to one lossy path.
      if (lossy && !aliased.add(path)) continue;
      switch (stat.type) {
        case FileSystemEntityType.file:
          final mtimeMs = stat.modified.millisecondsSinceEpoch;
          if (isAudio) {
            audio.add(
              LocalAudioFile(path: path, sizeBytes: stat.size, mtimeMs: mtimeMs),
            );
          } else {
            lyrics.add(
              LocalSidecarFile(path: path, sizeBytes: stat.size, mtimeMs: mtimeMs),
            );
          }
        case FileSystemEntityType.notFound:
          // Listed but not stat-able (raced away, broken link, unplugged
          // target): its stored row must survive.
          if (isAudio) unstattable.add(path);
        default:
          // Folder link named like a file, FIFO, socket, device: not music.
          if (entry is Link &&
              stat.type == FileSystemEntityType.directory) {
            skippedLinks++;
          }
      }
    }
  }
  return AudioListing(
    audio: audio,
    lyrics: lyrics,
    unreadableDirs: unreadable,
    emptyDirs: empty,
    unstattable: unstattable,
    excludedOut: excludedOut,
    skippedOut: skippedOut,
    skippedLinks: skippedLinks,
    undecodableNames: undecodable,
    undecodableSampleDirs: sampleDirs,
  );
}
