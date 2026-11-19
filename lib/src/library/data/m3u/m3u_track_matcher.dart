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
import 'm3u_index_check.dart';
import 'm3u_results.dart';
import 'm3u_scan_rules.dart';

typedef _Place = ({int sourceId, String root, String locator});
typedef _Row = ({int id, String status});

/// Maps resolved M3U lines to library tracks, placeholders and problems.
/// [folders] defaults to a fresh `liveScanFolders` read; [androidStorage]
/// (Android shared storage: case-insensitive, `<volume>/Android` is app data)
/// turns on the case-insensitive fallback lookup and the app-data rule.
/// [indexCheck] (Android) turns would-be placeholders the platform scanner
/// cannot list into `notIndexed` problems.
Future<M3uMatch> matchM3uLines(
  AppDatabase db,
  List<M3uResolvedLine> lines, {
  List<ScanFolder>? folders,
  ShortTrackRule short = const ShortTrackRule.off(),
  bool truncated = false,
  required bool androidStorage,
  M3uIndexCheck? indexCheck,
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

  final entries = <ImportedEntry?>[];
  // Would-be placeholders: entry index, line, absolute path.
  final candidates = <({int at, M3uResolvedLine line, String path})>[];
  final problems = <M3uProblemLine>[];
  var outside = 0, notScanned = 0, notIndexed = 0;
  final notPresent = <int>{};
  void problem(M3uResolvedLine l, M3uProblemKind kind) {
    problems.add(
      M3uProblemLine(line: l.entry.line, text: l.entry.text, kind: kind),
    );
    if (kind == M3uProblemKind.outsideFolders) outside++;
    if (kind == M3uProblemKind.notScanned) notScanned++;
    if (kind == M3uProblemKind.notIndexed) notIndexed++;
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
      if (row.status != TrackStatus.present) notPresent.add(row.id);
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
      if (indexCheck != null) {
        candidates.add((at: entries.length, line: l, path: l.path!));
      }
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
  if (candidates.isNotEmpty) {
    final verdicts = await indexCheck!(
      {for (final c in candidates) c.path}.toList(),
    );
    for (final c in candidates) {
      final v = verdicts[c.path];
      if (v == null || v.state == M3uIndexState.listed) {
        // Unknown (check failed): keep the placeholder. Listed: use the
        // listing's spelling so the scan, which stores it, revives the row.
        final listed = v?.listedPath;
        final old = entries[c.at]! as ImportedMissing;
        if (listed != null &&
            listed != c.path &&
            listed.length == c.path.length) {
          entries[c.at] = ImportedMissing(
            sourceId: old.sourceId,
            locator: listed.substring(listed.length - old.locator.length),
            title: old.title,
            artist: old.artist,
            durationMs: old.durationMs,
          );
        }
        continue;
      }
      entries[c.at] = null;
      problem(
        c.line,
        v.state == M3uIndexState.short
            ? M3uProblemKind.notScanned
            : M3uProblemKind.notIndexed,
      );
    }
    problems.sort((a, b) => a.line.compareTo(b.line));
  }
  return M3uMatch(
    entries: [for (final e in entries) ?e],
    problems: problems,
    outsideFolders: outside,
    notScanned: notScanned,
    notIndexed: notIndexed,
    notPresent: notPresent.length,
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
