import 'dart:async';

import 'package:logging/logging.dart';

import '../../../platform/domain/local_audio_catalog.dart';
import '../../../platform/domain/storage_volumes.dart' show isPathInside;
import 'm3u_scan_rules.dart';

final _log = Logger('library.m3u.index');

/// What the platform scanner's listing says about one existing file.
enum M3uIndexState {
  /// The scanner lists it.
  listed,

  /// The scanner lists it, but its real duration is under the short-track
  /// threshold while "skip short songs" is on, so the scan drops it.
  short,

  /// The scanner does not list it (not indexed, or a pending row of another
  /// app): a placeholder could never be revived.
  unseen,
}

/// One verdict. [listedPath] is the listing's spelling of the path (MediaStore
/// keeps the on-disk case); null when the file is [M3uIndexState.unseen].
class M3uIndexVerdict {
  const M3uIndexVerdict(this.state, [this.listedPath]);

  final M3uIndexState state;
  final String? listedPath;
}

/// Answers, for [paths] (absolute, existing files), what the platform scanner
/// would list. A path missing from the result is unknown (the listing failed,
/// timed out or was skipped): the caller keeps the previous behaviour for it.
/// Used on Android, where the scan reads MediaStore only: a file on disk that
/// MediaStore hides from the app would become a placeholder no scan revives.
typedef M3uIndexCheck = Future<Map<String, M3uIndexVerdict>> Function(
  List<String> paths,
);

/// Whole-check budget: a stuck MediaStore must not hold the import.
const m3uIndexCheckBudget = Duration(seconds: 20);

String _fold(String path) =>
    path.replaceAllMapped(RegExp('[A-Z]'), (m) => m[0]!.toLowerCase());

String _parent(String path) => path.substring(0, path.lastIndexOf('/'));

/// `/storage/<volume>` and `/storage/emulated/<n>`: listing one would read
/// every audio row of the device, so files directly in it are not checked.
final _volumeRoot = RegExp(r'^/storage/(?:emulated/\d+|[^/]+)$');

/// The check backed by [catalog]. It only lists, once per folder: a folder
/// whose ancestor is also listed is covered by the ancestor's listing. Lists
/// without the short filter and classifies by the listed duration. Never
/// throws; a failed listing leaves its files unknown.
M3uIndexCheck catalogIndexCheck(
  LocalAudioCatalog catalog, {
  ShortTrackRule short = const ShortTrackRule.off(),
  Duration budget = m3uIndexCheckBudget,
}) => (paths) async {
  final parents = {for (final p in paths) _parent(p)}
    ..removeWhere(_volumeRoot.hasMatch);
  final foldedParents = {for (final d in parents) d: _fold(d)};
  final dirs = [
    for (final d in parents)
      if (!parents.any(
        (o) => o != d && isPathInside(foldedParents[d]!, foldedParents[o]!),
      ))
        d,
  ];
  // Folder -> its listing by folded path; null when it could not be read.
  final listings = <String, Map<String, LocalAudioFile>?>{};
  // Set when the budget ends: the abandoned loop must not list more folders.
  var stopped = false;

  Future<void> listAll() async {
    for (final dir in dirs) {
      if (stopped) return;
      try {
        final r = await catalog.listAudio(
          root: dir,
          excludedKeys: const {},
          skipShorterThanMs: 0,
        );
        if (r.reachable) {
          listings[dir] = {for (final f in r.audio) _fold(f.path): f};
        } else {
          _log.warning(
            'M3U index check: $dir unreachable (${r.unreachableReason})',
          );
          listings[dir] = null;
        }
      } on Object catch (e, st) {
        _log.warning('M3U index check: listing $dir failed', e, st);
        listings[dir] = null;
      }
    }
  }

  try {
    await listAll().timeout(budget);
  } on TimeoutException {
    stopped = true;
    _log.warning('M3U index check ran past $budget; unlisted folders skipped');
  }

  final out = <String, M3uIndexVerdict>{};
  for (final path in paths) {
    final folded = _fold(path);
    final dir = dirs.where((d) => isPathInside(folded, _fold(d))).firstOrNull;
    // Not covered (volume root) or not listed in time: unknown.
    if (dir == null || !listings.containsKey(dir)) continue;
    final listing = listings[dir];
    if (listing == null) continue;
    final file = listing[folded];
    out[path] = file == null
        ? const M3uIndexVerdict(M3uIndexState.unseen)
        : M3uIndexVerdict(
            short.isShort(file.durationMs)
                ? M3uIndexState.short
                : M3uIndexState.listed,
            file.path,
          );
  }
  return out;
};
