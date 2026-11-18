import 'dart:convert';

import 'package:drift/drift.dart' show Variable;

import '../../../database/database.dart';
import '../../../storage/data/m3u/m3u_line_resolver.dart';
import '../../domain/playlists/playlist_import.dart';
import '../../domain/scan/root_rules.dart';
import '../../domain/scan/scan_folder.dart';
import '../scan/scan_folders.dart';
import '../scan/track_row_builder.dart' show stemOf;
import '../../../media/domain/track_id.dart';
import 'm3u_results.dart';
import 'm3u_scan_rules.dart';

typedef _Place = ({int sourceId, String root, String locator});
typedef _Row = ({int id, String status});

/// Maps resolved M3U lines to library tracks, placeholders and problems.
/// [folders] defaults to a fresh `liveScanFolders` read; [androidStorage]
/// (Android shared storage: case-insensitive, `<volume>/Android` is app data)
/// turns on the case-insensitive fallback lookup and the app-data rule.
Future<M3uMatch> matchM3uLines(
  AppDatabase db,
  List<M3uResolvedLine> lines, {
  List<ScanFolder>? folders,
  ShortTrackRule short = const ShortTrackRule.off(),
  bool truncated = false,
  required bool androidStorage,
}) async {
  final roots = [
    for (final f in folders ?? await liveScanFolders(db))
      (sourceId: f.sourceId, root: normalizeRootPath(f.root)),
  ];
  _Place? place(String path) {
    _Place? best;
    for (final r in roots) {
      if (!isSameOrInside(path, r.root)) continue;
      if (best != null && best.root.length >= r.root.length) continue;
      final locator = r.root == '/'
          ? path.substring(1)
          : path.length == r.root.length
          ? ''
          : path.substring(r.root.length + 1);
      best = (sourceId: r.sourceId, root: r.root, locator: locator);
    }
    return best;
  }

  final placed = <_Place?>[
    for (final l in lines)
      if (l.path ?? l.candidatePath case final p?) place(p) else null,
  ];
  final known = await _existing(db, caseInsensitive: androidStorage, [
    for (final p in placed)
      if (p != null && p.locator.isNotEmpty) p,
  ]);

  final entries = <ImportedEntry>[];
  final problems = <M3uProblemLine>[];
  var outside = 0, notScanned = 0, notPresent = 0;
  void problem(M3uResolvedLine l, M3uProblemKind kind) {
    problems.add(
      M3uProblemLine(line: l.entry.line, text: l.entry.text, kind: kind),
    );
    if (kind == M3uProblemKind.outsideFolders) outside++;
    if (kind == M3uProblemKind.notScanned) notScanned++;
  }

  for (var i = 0; i < lines.length; i++) {
    final l = lines[i];
    final p = placed[i];
    if (p == null) {
      problem(l, switch (l.reason) {
        M3uUnresolvedReason.noBaseFolder => M3uProblemKind.noBaseFolder,
        M3uUnresolvedReason.outsideFolders => M3uProblemKind.outsideFolders,
        // A resolved path that no live root contains (roots changed since).
        null => M3uProblemKind.outsideFolders,
        _ => M3uProblemKind.unresolved,
      });
      continue;
    }
    final row = p.locator.isEmpty ? null : known.find(p);
    if (row != null) {
      entries.add(ImportedTrack(TrackId(row.id)));
      if (row.status != TrackStatus.present) notPresent++;
    } else if (l.path == null || p.locator.isEmpty) {
      problem(l, M3uProblemKind.unresolved);
    } else if (!scannerWouldList(
      root: p.root,
      locator: p.locator,
      durationMs: l.entry.extinf?.durationMs,
      short: short,
      androidAppData: androidStorage,
    )) {
      problem(l, M3uProblemKind.notScanned);
    } else {
      final info = l.entry.extinf;
      final title = info?.title?.trim() ?? '';
      entries.add(
        ImportedMissing(
          sourceId: p.sourceId,
          locator: p.locator,
          title: title.isEmpty ? stemOf(p.locator) : title,
          artist: info?.artist,
          durationMs: info?.durationMs,
        ),
      );
    }
  }
  return M3uMatch(
    entries: entries,
    problems: problems,
    outsideFolders: outside,
    notScanned: notScanned,
    notPresent: notPresent,
    totalLines: lines.length,
    truncated: truncated,
  );
}

/// SQLite `lower()` folds ASCII only; the same fold keeps both sides equal.
String _asciiLower(String s) =>
    s.replaceAllMapped(RegExp('[A-Z]'), (m) => m[0]!.toLowerCase());

/// Existing rows of the lines' places: exact `(source, locator)` first, then,
/// for places with no exact row, one case-insensitive hit (the file systems
/// of SD cards and Android shared storage ignore case, the scanner stores
/// the on-disk spelling). Several case-insensitive hits are not guessed.
class _Known {
  final _exact = <String, _Row>{};
  final _folded = <String, List<_Row>>{};

  static String _key(int source, String locator) => '$source\u0000$locator';

  _Row? find(_Place p) {
    final exact = _exact[_key(p.sourceId, p.locator)];
    if (exact != null) return exact;
    final hits = _folded[_key(p.sourceId, _asciiLower(p.locator))];
    return hits != null && hits.length == 1 ? hits.single : null;
  }
}

/// One `json_each` query per source for the exact locators, and one more per
/// source for the locators that found nothing.
Future<_Known> _existing(
  AppDatabase db,
  List<_Place> places, {
  required bool caseInsensitive,
}) async {
  final known = _Known();
  final bySource = <int, Set<String>>{};
  for (final p in places) {
    (bySource[p.sourceId] ??= {}).add(p.locator);
  }
  for (final MapEntry(key: source, value: locators) in bySource.entries) {
    final rows = await db
        .customSelect(
          'SELECT id, locator, status FROM tracks WHERE source_id = ? '
          'AND locator IN (SELECT value FROM json_each(?))',
          variables: [
            Variable.withInt(source),
            Variable.withString(jsonEncode(locators.toList())),
          ],
          readsFrom: {db.tracks},
        )
        .get();
    for (final r in rows) {
      known._exact[_Known._key(source, r.read<String>('locator'))] = (
        id: r.read<int>('id'),
        status: r.read<String>('status'),
      );
    }
    if (!caseInsensitive) continue;
    final misses = {
      for (final l in locators)
        if (!known._exact.containsKey(_Known._key(source, l))) _asciiLower(l),
    };
    if (misses.isEmpty) continue;
    final folded = await db
        .customSelect(
          'SELECT id, lower(locator) AS lk, status FROM tracks '
          'WHERE source_id = ? AND lower(locator) IN '
          '(SELECT value FROM json_each(?))',
          variables: [
            Variable.withInt(source),
            Variable.withString(jsonEncode(misses.toList())),
          ],
          readsFrom: {db.tracks},
        )
        .get();
    for (final r in folded) {
      (known._folded[_Known._key(source, r.read<String>('lk'))] ??= []).add((
        id: r.read<int>('id'),
        status: r.read<String>('status'),
      ));
    }
  }
  return known;
}
