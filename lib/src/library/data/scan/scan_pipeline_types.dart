import '../../../database/database.dart';
import '../../../platform/domain/media_permissions.dart';
import '../../../storage/data/local_folder_source.dart';
import '../../domain/scan_status.dart';
import 'library_counts.dart';
import 'native_cover_maker.dart';
import 'native_tag_reader.dart';
import 'scan_yield.dart';
import 'tag_pass_types.dart';

/// Everything a scan needs from the outside. Built when a scan starts, so the
/// platform and native ports are touched only then.
class ScanPipelineDeps {
  ScanPipelineDeps({
    required this.db,
    required this.source,
    required this.permissions,
    required this.reader,
    required this.maker,
    required this.cacheDir,
    required this.skipShortTracks,
    required this.now,
    ScanYield? yielder,
    this.tagTimeout = const Duration(seconds: 90),
    this.coverTimeout = const Duration(seconds: 60),
  }) : yielder = yielder ?? ScanYield();

  final AppDatabase db;
  final LocalFolderSource source;
  final MediaPermissions permissions;
  final TagReader reader;
  final CoverMaker maker;

  /// Absolute path of the app cache folder.
  final String cacheDir;
  final bool skipShortTracks;

  /// Milliseconds since the epoch.
  final int Function() now;
  final ScanYield yielder;
  final Duration tagTimeout;
  final Duration coverTimeout;
}

/// What lives across scans of one app session: short files already seen,
/// covers that failed, covers with no colours, and native calls still stuck.
class ScanSession {
  /// Key of the cover pass in [stuck] (a music folder uses its root path).
  static const String coversKey = 'covers';

  final ShortFileMemo shortMemo = ShortFileMemo();
  final Set<int> coverSkip = {};
  final Set<String> noColors = {};

  /// Roots (and [coversKey]) whose last native call has not returned yet.
  final Set<String> stuck = {};
}

/// The controller's view of a running pass.
class ScanHooks {
  const ScanHooks({required this.onStatus, required this.shouldStop});

  final void Function(ScanRunning status) onStatus;
  final bool Function() shouldStop;
}

/// A native call that timed out; [future] completes when it returns.
typedef NativePending = ({String key, Future<void> future});

/// How one pass ended.
class ScanOutcome {
  /// A `ScanFailed.kind`, or null when the pass worked.
  String? failureKind;

  /// New visible tracks of this pass.
  int added = 0;

  /// The caller asked to stop before the end.
  bool stopped = false;

  /// Present only when the pass ended without failure or stop.
  LibraryCounts? counts;

  /// Timed-out native calls to wait for (then scan once more).
  final List<NativePending> pending = [];

  bool get completed => failureKind == null && !stopped;
}
