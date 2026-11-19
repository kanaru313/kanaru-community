import '../../../database/database.dart';
import '../../../storage/domain/local_folder_listing.dart';
import '../../domain/scan/scan_report.dart';
import 'native_tag_reader.dart';
import 'scan_yield.dart';

/// Default of `library.min_duration_ms`. Kept for code that has no access to
/// the setting (the playlist importer); the scan reads the setting itself.
const int shortTrackMs = 30000;

/// Rows per Rust tag call: `ceil(n / 20)` clamped to 32..256.
int tagBatchSize(int files) => ((files + 19) ~/ 20).clamp(32, 256);

/// Files found too short in this session. A file is remembered with the
/// stat it had and the duration that was read, so relaxing the minimum in the
/// same session reads it again instead of skipping it for good.
class ShortFileMemo {
  final Map<String, ({int mtimeMs, int sizeBytes, int durationMs})> _seen = {};

  static String _key(int sourceId, String locator) => '$sourceId|$locator';

  /// Whether [file] need not be read: the minimum is on, the file has the
  /// same mtime and size as when it was found short, and that duration is
  /// still below [minMs] (the current minimum).
  bool skips(int sourceId, ListedFile file, int minMs) {
    if (minMs <= 0) return false;
    final seen = _seen[_key(sourceId, file.locator)];
    return seen != null &&
        seen.mtimeMs == file.mtimeMs &&
        seen.sizeBytes == file.sizeBytes &&
        seen.durationMs < minMs;
  }

  /// Notes that [file] was read and is [durationMs] long.
  void remember(int sourceId, ListedFile file, int durationMs) {
    _seen[_key(sourceId, file.locator)] = (
      mtimeMs: file.mtimeMs,
      sizeBytes: file.sizeBytes,
      durationMs: durationMs,
    );
  }

  /// Drops the note of [file]: it was read and kept.
  void forget(int sourceId, ListedFile file) =>
      _seen.remove(_key(sourceId, file.locator));

  int get length => _seen.length;
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
