import '../../../database/database.dart';
import 'native_cover_maker.dart';
import 'scan_yield.dart';

/// Tracks per Rust cover call.
const int coverBatchSize = 32;

/// What the cover pass needs from its caller.
class CoverPassDeps {
  CoverPassDeps({
    required this.db,
    required this.maker,
    required this.cacheDir,
    required this.sidecars,
    required this.now,
    bool Function()? shouldStop,
    Set<int>? skip,
    Set<String>? noColors,
    this.onProgress,
    this.timeout = const Duration(seconds: 60),
    ScanYield? yielder,
  }) : shouldStop = shouldStop ?? (() => false),
       skip = skip ?? <int>{},
       noColors = noColors ?? <String>{},
       yielder = yielder ?? ScanYield();

  final AppDatabase db;
  final CoverMaker maker;

  /// Absolute path of the app cache folder.
  final String cacheDir;

  /// Whether image files next to the audio may be read (false on Android
  /// without the images permission: embedded art only).
  final bool sidecars;
  final int Function() now;
  final bool Function() shouldStop;

  /// Track ids that failed earlier in this session; not tried again. Owned by
  /// the caller so it lives across passes.
  final Set<int> skip;

  /// Cover keys already answered "no colours" (near-gray covers have no row
  /// by design); not asked again this session. Owned by the caller.
  final Set<String> noColors;

  /// Called after each batch with `(done, total)` tracks.
  final void Function(int done, int total)? onProgress;
  final Duration timeout;
  final ScanYield yielder;
}

/// How a cover pass ended.
class CoverPassResult {
  int total = 0;
  int done = 0;
  int found = 0;
  int noCover = 0;
  int transientFailed = 0;
  int permanentFailed = 0;
  int deferred = 0;
  int colorsWritten = 0;

  /// Ran to the end of its work set.
  bool finished = false;
  bool stopped = false;

  /// A cover call ran past its timeout; the pass is skipped until
  /// [pendingNative] completes.
  bool stuck = false;
  Future<void>? pendingNative;

  /// Writing under the cache folder failed; the next scan tries again.
  bool cacheFailed = false;

  /// `native_unavailable` when the native call threw instead of answering.
  String? failureKind;
}
