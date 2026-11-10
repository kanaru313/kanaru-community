import '../../../database/database.dart';
import '../../../storage/domain/local_folder_listing.dart';
import '../../domain/scan/scan_report.dart';
import 'native_tag_reader.dart';
import 'scan_yield.dart';

/// Files under this length are skipped when the setting is on.
const int shortTrackMs = 30000;

/// Rows per Rust tag call: `ceil(n / 20)` clamped to 32..256.
int tagBatchSize(int files) => ((files + 19) ~/ 20).clamp(32, 256);

/// Files already found too short in this session, by `(locator, mtime,
/// size)`, so a rescan does not read them again.
class ShortFileMemo {
  final Set<String> _keys = {};

  static String _key(int sourceId, String locator, int mtimeMs, int size) =>
      '$sourceId|$locator|$mtimeMs|$size';

  bool contains(int sourceId, String locator, int mtimeMs, int size) =>
      _keys.contains(_key(sourceId, locator, mtimeMs, size));

  void add(int sourceId, String locator, int mtimeMs, int size) =>
      _keys.add(_key(sourceId, locator, mtimeMs, size));

  int get length => _keys.length;
}

/// What the tag pass needs from its caller.
class TagPassDeps {
  TagPassDeps({
    required this.db,
    required this.reader,
    required this.now,
    bool Function()? shouldStop,
    this.onProgress,
    this.tagTimeout = const Duration(seconds: 90),
    this.skipShorterThanMs = 0,
    ShortFileMemo? shortMemo,
    ScanYield? yielder,
    this.isolateDiffAbove = 5000,
    required this.rootStillThere,
  }) : shouldStop = shouldStop ?? (() => false),
       shortMemo = shortMemo ?? ShortFileMemo(),
       yielder = yielder ?? ScanYield();

  final AppDatabase db;
  final TagReader reader;

  /// Current time in milliseconds since the epoch.
  final int Function() now;

  /// Checked before every batch; true ends the pass without more writes.
  final bool Function() shouldStop;

  /// Called after each batch with `(done, total)` files read.
  final void Function(int done, int total)? onProgress;
  final Duration tagTimeout;

  /// Files shorter than this are not stored (0 = keep all).
  final int skipShorterThanMs;
  final ShortFileMemo shortMemo;
  final ScanYield yielder;

  /// Stored rows above which the diff runs in an isolate.
  final int isolateDiffAbove;

  /// Asked once, after the reads, before rows whose file the reader could
  /// not find are marked missing. Build it with `LocalFolderSource.
  /// presenceCheck` before the listing: not present (the folder is empty or
  /// gone, or the mount it sat on is no longer mounted: an unplugged drive
  /// leaves an empty mount-point folder) means nothing is marked; mounts
  /// nested in the folder that vanished protect just their own files.
  final Future<RootPresence> Function() rootStillThere;
}

/// How a folder's tag pass ended.
class FolderTagResult {
  FolderTagResult(this.report);

  final ScanReport report;

  /// The pass reached its end: missing marks done and `last_scan_at` written.
  bool finished = false;

  /// Stopped by the caller before the end.
  bool stopped = false;

  /// The source was removed or its mount disabled during the pass.
  bool sourceGone = false;

  /// A tag call ran past its timeout; the folder is skipped until
  /// [pendingNative] completes.
  bool nativeStuck = false;

  /// Completes (never with an error) when the timed-out native call returns.
  Future<void>? pendingNative;

  /// The folder vanished during the pass (every `NotFound` answer was a
  /// symptom): nothing was marked missing.
  bool rootVanished = false;

  /// `native_unavailable` when the native call threw instead of answering,
  /// `io` when the database failed for every row of a batch.
  String? failureKind;
}
