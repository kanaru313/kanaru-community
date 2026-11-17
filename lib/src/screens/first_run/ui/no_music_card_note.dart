import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/domain/scan/folder_list_state.dart';
import '../../../library/state/scan/folder_candidates_provider.dart';
import '../../../library/state/scan/media_index_refresh.dart';
import 'folder_sheet_states.dart';
import 'section_states.dart';

/// The note of the "Thư mục nhạc" card on Android when no folder is chosen:
/// "Android sees no music" with Quét lại, the rescan progress, its result, or
/// the plain "no folder chosen" line. Shares the one index refresh with the
/// folder sheet and shows a result only for a run it saw (it was shown while
/// the run started or ended).
///
/// With [autoRun] (the audio permission is granted) the first time the card
/// shows "no music" it starts one rescan, once per app launch.
class NoMusicCardNote extends ConsumerStatefulWidget {
  const NoMusicCardNote({
    super.key,
    required this.autoRun,
    required this.seenFrom,
  });

  final bool autoRun;

  /// The run id the card was first shown at, kept by the section so the card
  /// remounting on a list reload does not forget a result it saw.
  final int seenFrom;

  @override
  ConsumerState<NoMusicCardNote> createState() => _NoMusicCardNoteState();
}

class _NoMusicCardNoteState extends ConsumerState<NoMusicCardNote> {
  bool _autoScheduled = false;

  void _rescan() => ref.read(mediaIndexRefreshProvider.notifier).run();

  /// Starts the once-per-launch rescan after this frame (never during build).
  void _scheduleAutoRun() {
    if (_autoScheduled) return;
    _autoScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(mediaIndexRefreshProvider.notifier).autoRunOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(folderCandidatesProvider);
    final refresh = ref.watch(mediaIndexRefreshProvider);
    final result = seenRefreshResult(refresh, widget.seenFrom);
    // A reload never shows the last "no music" as if it were current.
    final list = async.isLoading || async.hasError ? null : async.value;

    if (refresh is IndexRefreshRunning) {
      return const SetupNote(child: RescanProgress());
    }
    if (result != null && result.failed) {
      return SectionLoadFailed(
        message: l10n.scanSetupRescanFailed,
        onRetry: _rescan,
      );
    }
    if (async.isLoading) return const SetupNote(child: SectionSpinner());
    if (async.hasError || list is FolderListLoadFailed) {
      return SectionLoadFailed(
        message: l10n.scanSetupFolderListFailedTitle,
        onRetry: () => ref.invalidate(audioFoldersProvider),
      );
    }
    if (list is FolderListNoIndexedMusic) {
      if (widget.autoRun) _scheduleAutoRun();
      return _noMusic(l10n, result, canRescan: !refreshUnsupported(refresh));
    }
    final found = result?.found;
    if (result != null && result.looked && found != null && found > 0) {
      return SetupNote(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.scanSetupRescanDone(found)),
            const KGap(KSpace.x1),
            Text(l10n.scanSetupFoldersEmpty),
          ],
        ),
      );
    }
    return SetupNote(child: Text(l10n.scanSetupFoldersEmpty));
  }

  Widget _noMusic(
    AppLocalizations l10n,
    IndexRefreshFinished? result, {
    required bool canRescan,
  }) {
    final stillEmpty = result != null && result.looked;
    final textStyle = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return SetupNote(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            stillEmpty
                ? l10n.scanSetupStillNoMusicCard
                : l10n.scanSetupNoMusicCard,
          ),
          if (stillEmpty) ...[
            const KGap(KSpace.x2),
            StillNoMusicTips(style: textStyle),
          ],
          if (canRescan) ...[
            const KGap(KSpace.x2),
            if (stillEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _rescan,
                  icon: const Icon(KIcons.rescan),
                  label: Text(l10n.scanSetupRescan),
                ),
              )
            else
              FilledButton.tonalIcon(
                onPressed: _rescan,
                icon: const Icon(KIcons.rescan),
                label: Text(l10n.scanSetupRescan),
              ),
          ],
        ],
      ),
    );
  }
}
