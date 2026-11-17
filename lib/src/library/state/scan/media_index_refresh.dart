import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../database/state/database_providers.dart';
import '../../../platform/domain/local_audio_catalog.dart';
import '../../../platform/domain/storage_volumes.dart';
import '../../../platform/state/local_audio_catalog_provider.dart';
import '../../../platform/state/storage_volumes_provider.dart';
import '../../data/scan/scan_folders.dart';
import '../scan_providers.dart';
import 'folder_candidates_provider.dart';

final _log = Logger('library.media_index_refresh');

/// State of the "ask Android to index the music" run. [runId] grows with each
/// run, so a screen can tell a result it saw start or end from a stale one.
sealed class IndexRefreshState {
  const IndexRefreshState(this.runId);

  final int runId;
}

final class IndexRefreshIdle extends IndexRefreshState {
  const IndexRefreshIdle() : super(0);
}

final class IndexRefreshRunning extends IndexRefreshState {
  const IndexRefreshRunning(super.runId);
}

/// [found] is the audio the index holds after the run; null when it could not
/// be read or the run did not complete.
final class IndexRefreshFinished extends IndexRefreshState {
  const IndexRefreshFinished(super.runId, this.outcome, this.found);

  final MediaIndexRefresh outcome;
  final int? found;
}

/// Runs one media index refresh at a time, shared by the folder sheet and the
/// first-run card. It outlives both (the provider is not autoDispose) and
/// watches nothing, so it is never rebuilt in the middle of a run.
class MediaIndexRefreshNotifier extends Notifier<IndexRefreshState> {
  Future<void>? _inFlight;
  int _runs = 0;
  bool _autoRan = false;

  @override
  IndexRefreshState build() => const IndexRefreshIdle();

  /// Starts a run, or joins the one in flight.
  Future<void> run() =>
      _inFlight ??= _run().whenComplete(() => _inFlight = null);

  /// [run] at most once per app launch (the first-run card calls it when
  /// Android shows no music).
  Future<void> autoRunOnce() async {
    if (_autoRan) return;
    _autoRan = true;
    await run();
  }

  Future<void> _run() async {
    final id = ++_runs;
    state = IndexRefreshRunning(id);
    var outcome = MediaIndexRefresh.failed;
    int? found;
    try {
      // Every dependency is read before the first await; a failing read ends
      // the run as failed instead of leaving it running.
      final catalog = ref.read(localAudioCatalogProvider);
      final volumes = ref.read(storageVolumesProvider);
      final db = ref.read(appDatabaseProvider);
      final scan = ref.read(libraryScanCommandsProvider);
      final roots = [
        for (final v in await volumes.list())
          if (v.kind != StorageVolumeKind.other) v.root,
      ];
      if (!ref.mounted) return;
      final folders = [for (final f in await liveScanFolders(db)) f.root];
      if (!ref.mounted) return;
      outcome = await catalog.refreshMediaIndex(
        volumeRoots: roots,
        folders: folders,
      );
      if (!ref.mounted) return;
      if (outcome == MediaIndexRefresh.done ||
          outcome == MediaIndexRefresh.timedOut) {
        final after = await catalog.audioFolders();
        if (!ref.mounted) return;
        if (after case AudioFoldersListed(:final folders)) {
          found = folders.fold<int>(0, (n, f) => n + f.audioCount);
        }
        ref
          ..invalidate(audioFoldersProvider)
          ..invalidate(suggestedFolderProvider);
        // A no-op before setup; acts when setup finished during the scan.
        unawaited(scan.rescan());
      }
    } on Object catch (e, st) {
      _log.warning('media index refresh failed', e, st);
      outcome = MediaIndexRefresh.failed;
    }
    if (ref.mounted) state = IndexRefreshFinished(id, outcome, found);
  }
}

final mediaIndexRefreshProvider =
    NotifierProvider<MediaIndexRefreshNotifier, IndexRefreshState>(
      MediaIndexRefreshNotifier.new,
    );
