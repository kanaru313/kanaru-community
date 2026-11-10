import 'dart:async';
import 'dart:io';

import 'package:kanaru/src/database/database.dart' show AppDatabase;
import 'package:kanaru/src/library/data/scan/cover_pass.dart';
import 'package:kanaru/src/library/data/scan/native_cover_maker.dart';
import 'package:kanaru/src/library/domain/scan/cover_read.dart';
import 'package:kanaru/src/library/domain/scan/native_failure.dart';
import 'package:kanaru/src/media/domain/cover_colors.dart';
import 'package:kanaru/src/media/domain/cover_files.dart';

import 'scan_fixtures.dart';

/// A valid cover key for [n].
String keyFor(int n) {
  final hex = n.toRadixString(16).padLeft(32, '0');
  return '${hex.substring(0, 2)}/$hex';
}

const sampleColors = CoverColors(seed: 0xFF336699, palette: [0xFF336699]);

/// A found result with the paths Rust would report.
CoverRead found(
  int trackId,
  String key, {
  bool made = true,
  CoverColors? colors = sampleColors,
}) => CoverRead(
  trackId: trackId,
  status: CoverStatus.found,
  key: key,
  made: made,
  thumbRel: coverRelativePath(key, CoverSize.thumb),
  fullRel: coverRelativePath(key, CoverSize.full),
  colors: colors,
);

CoverRead noCover(int trackId) =>
    CoverRead(trackId: trackId, status: CoverStatus.noCover);

CoverRead coverFailed(
  int trackId, {
  required bool transient,
  String kind = 'io',
  bool cache = false,
}) => CoverRead(
  trackId: trackId,
  status: CoverStatus.failed,
  error: NativeFailure(kind: kind, transient: transient),
  cacheFailure: cache,
);

/// A cover maker that answers from a function, with hooks for the tests.
class FakeCoverMaker implements CoverMaker {
  /// Answer for one item; default: a made cover with a key from the id.
  CoverRead Function(int trackId, String path) respond = (id, _) =>
      found(id, keyFor(id));
  Map<String, CoverColors?> colors = {};
  final List<List<int>> extractCalls = [];
  final List<bool> sidecarFlags = [];
  final List<List<String>> colorCalls = [];
  Completer<List<CoverRead>>? hang;
  Completer<List<CoverColorsRead>>? colorHang;
  void Function()? onExtract;
  void Function()? onColors;
  Object? throwWith;

  @override
  Future<List<CoverRead>> extract({
    required String cacheDir,
    required List<({int trackId, String path})> items,
    required bool sidecars,
  }) async {
    extractCalls.add([for (final i in items) i.trackId]);
    sidecarFlags.add(sidecars);
    onExtract?.call();
    if (throwWith != null) throw throwWith!;
    if (hang != null) return hang!.future;
    return [for (final i in items) respond(i.trackId, i.path)];
  }

  @override
  Future<List<CoverColorsRead>> colorsFor({
    required String cacheDir,
    required List<String> keys,
  }) async {
    colorCalls.add(keys);
    onColors?.call();
    if (colorHang != null) return colorHang!.future;
    return [for (final k in keys) CoverColorsRead(key: k, colors: colors[k])];
  }
}

Directory makeCacheDir() =>
    Directory.systemTemp.createTempSync('kanaru_cover_test');

/// Marks the cache layout as current, so a pass does not reset anything.
void writeLayoutMarker(Directory cache) {
  Directory('${cache.path}/covers/thumb').createSync(recursive: true);
  Directory('${cache.path}/covers/full').createSync(recursive: true);
  File('${cache.path}/covers/$coverLayoutMarker').writeAsStringSync('v1\n');
}

CoverPassDeps coverDeps(
  AppDatabase db,
  FakeCoverMaker maker,
  Directory cache, {
  bool sidecars = true,
  Set<int>? skip,
  Set<String>? noColors,
  bool Function()? shouldStop,
  Duration timeout = const Duration(seconds: 5),
  void Function(int, int)? onProgress,
}) => CoverPassDeps(
  db: db,
  maker: maker,
  cacheDir: cache.path,
  sidecars: sidecars,
  now: () => scanNow,
  skip: skip,
  noColors: noColors,
  shouldStop: shouldStop,
  timeout: timeout,
  onProgress: onProgress,
);

Future<List<Map<String, Object?>>> coverRows(AppDatabase db) async {
  final rows = await db
      .customSelect(
        'SELECT id, locator, status, cover_key, cover_scan_version, '
        'scan_error FROM tracks ORDER BY id',
      )
      .get();
  return [for (final r in rows) r.data];
}
