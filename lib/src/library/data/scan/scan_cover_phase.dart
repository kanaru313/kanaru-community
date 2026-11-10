import 'package:logging/logging.dart';

import '../../../platform/domain/media_permissions.dart';
import 'cover_pass.dart';
import 'cover_reextract.dart';
import 'scan_pipeline_types.dart';
import '../../domain/scan_status.dart';

final _log = Logger('library.scan');

/// Whether sidecar images may be read: always off Android, and on Android
/// only with the images permission (embedded art needs just the audio one).
bool _sidecarsAllowed(MediaPermissionState p) =>
    !p.applies || p.images == MediaPermissionStatus.granted;

CoverPassDeps _coverDeps(
  ScanPipelineDeps d,
  ScanSession session,
  ScanHooks hooks,
  MediaPermissionState perms, {
  void Function(int done, int total)? onProgress,
}) => CoverPassDeps(
  db: d.db,
  maker: d.maker,
  cacheDir: d.cacheDir,
  sidecars: _sidecarsAllowed(perms),
  now: d.now,
  shouldStop: hooks.shouldStop,
  skip: session.coverSkip,
  noColors: session.noColors,
  onProgress: onProgress,
  timeout: d.coverTimeout,
  yielder: d.yielder,
);

/// The cover pass over the music folders whose tag pass finished.
Future<void> runCoverPhase(
  ScanPipelineDeps d,
  ScanSession session,
  ScanHooks hooks,
  ScanOutcome out,
  MediaPermissionState perms,
  Set<int> sourceIds,
) async {
  if (session.stuck.contains(ScanSession.coversKey)) {
    out.failureKind ??= 'native_timeout';
    return;
  }
  try {
    final result = await runCoverPass(
      _coverDeps(
        d,
        session,
        hooks,
        perms,
        onProgress: (done, total) => hooks.onStatus(
          ScanRunning(phase: ScanPhase.covers, done: done, total: total),
        ),
      ),
      sourceIds: sourceIds,
    );
    _noteCoverResult(session, out, result);
  } on Object catch (e, st) {
    _log.severe('cover pass failed', e, st);
    out.failureKind ??= 'io';
  }
}

void _noteCoverResult(
  ScanSession session,
  ScanOutcome out,
  CoverPassResult result,
) {
  if (result.stuck) {
    session.stuck.add(ScanSession.coversKey);
    final pending = result.pendingNative;
    if (pending != null) {
      out.pending.add((key: ScanSession.coversKey, future: pending));
    }
    out.failureKind ??= 'native_timeout';
  }
  out.failureKind ??= result.failureKind ?? (result.cacheFailed ? 'io' : null);
}

/// Re-extracts the covers of [keys] (the cache lost their files). Quiet: it
/// publishes no status. The same session flags as a full scan apply.
Future<ScanOutcome> runCoverMisses(
  ScanPipelineDeps d,
  ScanSession session,
  ScanHooks hooks,
  Set<String> keys,
) async {
  final out = ScanOutcome();
  if (session.stuck.contains(ScanSession.coversKey)) {
    return out..failureKind = 'native_timeout';
  }
  try {
    final perms = await d.permissions.status();
    if (perms.applies && perms.audio != MediaPermissionStatus.granted) {
      return out..failureKind = 'permission';
    }
    final result = await reExtractCovers(
      _coverDeps(d, session, hooks, perms),
      keys,
    );
    _noteCoverResult(session, out, result);
    if (hooks.shouldStop()) out.stopped = true;
  } on Object catch (e, st) {
    _log.severe('cover re-extract failed', e, st);
    out.failureKind ??= 'io';
  }
  return out;
}
