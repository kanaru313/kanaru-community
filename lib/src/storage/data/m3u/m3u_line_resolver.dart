import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../platform/domain/local_audio_catalog.dart';
import '../../domain/m3u/m3u_line_form.dart';
import '../../domain/m3u/m3u_parse.dart';
import 'm3u_fs_probe.dart';

/// Why a line did not become a file path.
enum M3uUnresolvedReason {
  notFound,
  notAudio,
  noBaseFolder,
  outsideFolders,
  uri,
  badFileUri,
  driveLetter,
  nul,
  tooLong,
}

/// One line after resolving: [path] is set for a usable audio file, else
/// [reason]. [candidatePath] is where a missing file under a live root would
/// be, so a caller can still match a library row for a file that is gone.
class M3uResolvedLine {
  const M3uResolvedLine(
    this.entry, {
    this.path,
    this.candidatePath,
    this.reason,
  });

  final M3uEntry entry;
  final String? path;
  final String? candidatePath;
  final M3uUnresolvedReason? reason;
}

Future<FileSystemEntityType> _statFollowingLinks(String path) =>
    FileSystemEntity.type(path, followLinks: true);

/// Same rule as the library's `isSameOrInside`; storage cannot import library,
/// a test pins both equal. Both paths normalised.
bool isSameOrInsideRoot(String inner, String outer) =>
    inner == outer ||
    (outer == '/' ? inner.startsWith('/') : inner.startsWith('$outer/'));

/// Resolves [entries] to canonical audio paths, in order, [batch] at a time.
/// Only audio files are statted; each stat gets [statTimeout] (a stale mount
/// counts as not found). [onProgress] fires with `(0, total)` first, then
/// after each batch.
Future<List<M3uResolvedLine>> resolveM3uLines(
  List<M3uEntry> entries, {
  required String? baseDir,
  required List<String> liveRoots,
  required Future<String> Function(String) canonicalize,
  Future<FileSystemEntityType> Function(String path) stat = _statFollowingLinks,
  Duration statTimeout = const Duration(seconds: 5),
  int batch = 32,
  void Function(int done, int total)? onProgress,
}) async {
  if (batch < 1) throw ArgumentError.value(batch, 'batch', 'must be >= 1');
  final roots = [for (final r in liveRoots) trimTrailingSlashes(r)];
  final probe = M3uFsProbe(
    canonicalize: canonicalize,
    stat: stat,
    timeout: statTimeout,
  );

  // One joined path: found (path), or not found (candidate, when under a root).
  Future<M3uResolvedLine> resolveOne(M3uEntry entry, String joined) async {
    if (!isAudioPath(joined)) {
      return M3uResolvedLine(entry, reason: M3uUnresolvedReason.notAudio);
    }
    final folder = await probe.folder(p.posix.dirname(joined));
    final name = p.posix.basename(joined);
    final full = folder.path == '/' ? '/$name' : '${folder.path}/$name';
    final inside = roots.any((r) => isSameOrInsideRoot(full, r));
    if (!await probe.isFile(full, folder)) {
      return M3uResolvedLine(
        entry,
        candidatePath: inside ? full : null,
        reason: M3uUnresolvedReason.notFound,
      );
    }
    return inside
        ? M3uResolvedLine(entry, path: full)
        : M3uResolvedLine(entry, reason: M3uUnresolvedReason.outsideFolders);
  }

  Future<M3uResolvedLine> resolve(M3uEntry entry) async {
    if (entry.tooLong) {
      return M3uResolvedLine(entry, reason: M3uUnresolvedReason.tooLong);
    }
    switch (classifyM3uLine(entry.text)) {
      case M3uRejected(:final problem):
        return M3uResolvedLine(
          entry,
          reason: switch (problem) {
            M3uLineProblem.uri => M3uUnresolvedReason.uri,
            M3uLineProblem.badFileUri => M3uUnresolvedReason.badFileUri,
            M3uLineProblem.driveLetter => M3uUnresolvedReason.driveLetter,
            M3uLineProblem.nul => M3uUnresolvedReason.nul,
            M3uLineProblem.tooLong => M3uUnresolvedReason.tooLong,
          },
        );
      case M3uAbsolute(:final path):
        return resolveOne(entry, path);
      case M3uRelative(:final path, :final backslashAlt):
        if (baseDir == null) {
          return M3uResolvedLine(
            entry,
            reason: M3uUnresolvedReason.noBaseFolder,
          );
        }
        final literal = await resolveOne(entry, p.posix.join(baseDir, path));
        if (literal.path != null || backslashAlt == null) return literal;
        // The literal name is absent: try the Windows-style separators.
        final alt = await resolveOne(
          entry,
          p.posix.join(baseDir, backslashAlt),
        );
        return alt.reason == M3uUnresolvedReason.notFound &&
                alt.candidatePath == null
            ? literal
            : alt;
    }
  }

  final total = entries.length;
  onProgress?.call(0, total);
  final out = <M3uResolvedLine>[];
  for (var i = 0; i < total; i += batch) {
    final end = i + batch < total ? i + batch : total;
    out.addAll(await Future.wait(entries.sublist(i, end).map(resolve)));
    onProgress?.call(end, total);
  }
  return out;
}
