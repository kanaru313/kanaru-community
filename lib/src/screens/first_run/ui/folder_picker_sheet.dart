import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/domain/scan/folder_list_state.dart';
import '../../../library/state/music_folders_providers.dart';
import '../../../library/state/scan/display_volumes_provider.dart';
import '../../../library/state/scan/folder_candidates_provider.dart';
import '../../../library/state/scan/media_index_refresh.dart';
import '../../../library/ui/scan/folder_display_path.dart';
import '../../../platform/domain/local_audio_catalog.dart';
import 'folder_actions.dart' show baseName;
import 'folder_sheet_states.dart';

/// Which Android folder sheet: music folders to add, or sub-folders to
/// exclude (no rescan there: an unindexed sub-folder holds no song to skip).
enum FolderSheetKind { add, exclude }

/// The multi-select sheet of the folders Android's index holds. It opens at
/// once and turns into the loading, empty, failed or list state as the list
/// provider and the shared index refresh change. Resolves (through the sheet
/// route) to the picked paths; nothing is written here.
class FolderPickerSheet extends ConsumerStatefulWidget {
  const FolderPickerSheet({super.key, required this.kind});

  final FolderSheetKind kind;

  @override
  ConsumerState<FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends ConsumerState<FolderPickerSheet> {
  /// Refresh results at or below this run id predate the sheet and stay
  /// hidden.
  late final int _seenFrom = refreshSeenFrom(
    ref.read(mediaIndexRefreshProvider),
  );

  /// The Music suggestion is offered once per sheet: later frames never
  /// offer it again, so a pick the user cleared stays cleared.
  String? _offered;

  bool get _add => widget.kind == FolderSheetKind.add;

  void _rescan() => ref.read(mediaIndexRefreshProvider.notifier).run();

  void _reload() => ref.invalidate(audioFoldersProvider);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(
      _add ? folderCandidatesProvider : exclusionCandidatesProvider,
    );
    final volumesAsync = ref.watch(displayVolumesProvider);
    final refresh = ref.watch(mediaIndexRefreshProvider);
    final chosen = ref.watch(musicFoldersProvider).value;
    final suggestion = _add ? ref.watch(suggestedFolderProvider).value : null;

    // A reload keeps the last list (picks and rows stay); an error with
    // nothing newer is a failed read.
    final FolderListState? list = async.hasError && !async.isLoading
        ? const FolderListLoadFailed()
        : async.value;
    final reloading = async.isLoading || volumesAsync.isLoading;
    final volumes = volumesAsync.value;
    final result = _add ? seenRefreshResult(refresh, _seenFrom) : null;
    final running = refresh is IndexRefreshRunning;
    final canRescan = _add && !refreshUnsupported(refresh);

    final candidates = switch (list) {
      FolderListReady(:final candidates) when volumes != null => candidates,
      _ => const <AudioFolderSummary>[],
    };

    // Only a list that is ready keeps its rows through a reload; every other
    // state shows the loading note while it reloads.
    Widget? banner;
    Widget? footer;
    Widget? emptyNote;
    var preselect = const <String>{};

    if (_add && running) {
      if (list is FolderListReady) {
        banner = const FolderSheetScanning();
        emptyNote = Text(l10n.scanSetupFolderPickerEmpty);
        footer = const FolderSheetRescanRow(onTap: null);
      } else {
        emptyNote = const FolderSheetScanning();
      }
    } else if (list == null ||
        volumes == null ||
        (reloading && list is! FolderListReady)) {
      emptyNote = FolderSheetLoading(
        label: _add
            ? l10n.scanSetupFolderSheetLoading
            : l10n.scanSetupExclusionSheetLoading,
      );
    } else {
      switch (list) {
        case FolderListLoadFailed():
          emptyNote = FolderSheetFailed(
            title: _add
                ? l10n.scanSetupFolderListFailedTitle
                : l10n.scanSetupExclusionListFailed,
            onRetry: result?.failed == true ? _rescan : _reload,
          );
        case FolderListNoIndexedMusic() when !_add:
          emptyNote = Text(l10n.scanSetupExclusionPickerEmpty);
        case FolderListNoIndexedMusic():
          emptyNote = result == null
              ? FolderSheetNoMusic(onRescan: canRescan ? _rescan : null)
              : result.looked
              ? FolderSheetStillNoMusic(onRescan: _rescan)
              : result.failed
              ? FolderSheetFailed(
                  title: l10n.scanSetupFolderListFailedTitle,
                  onRetry: _rescan,
                )
              : FolderSheetNoMusic(onRescan: null);
        case FolderListReady():
          emptyNote = Text(
            _add
                ? l10n.scanSetupFolderPickerEmpty
                : l10n.scanSetupExclusionPickerEmpty,
          );
          if (_add) {
            if (canRescan) footer = FolderSheetRescanRow(onTap: _rescan);
            final found = result?.found;
            banner = result == null
                ? null
                : result.failed
                ? FolderSheetRescanFailed(onRetry: _rescan)
                : result.looked && found != null
                ? FolderSheetRescanDone(found: found)
                : null;
            // Music is suggested only after a rescan this sheet saw found
            // music and nothing is chosen yet; written only by Thêm.
            if (result?.looked == true &&
                (chosen?.isEmpty ?? false) &&
                suggestion != null &&
                candidates.any((c) => c.path == suggestion)) {
              // Safe in build: idempotent and set at most once, it only
              // latches the preselect so later frames cannot re-offer it.
              _offered ??= suggestion;
            }
          }
      }
    }

    final offered = _offered;
    if (offered != null) preselect = {offered};

    return MultiSelectionSheet<String>(
      options: [
        if (volumes != null)
          for (final c in candidates)
            SelectionOption(
              value: c.path,
              leading: const Icon(KIcons.folders),
              title: Text(baseName(c.path)),
              subtitle: Text(
                '${folderDisplayPathOf(l10n, volumes, c.path)} · '
                '${l10n.scanSetupFolderSongs(c.audioCount)}',
              ),
            ),
      ],
      initial: preselect,
      title: Text(
        _add
            ? l10n.scanSetupFolderPickerTitle
            : l10n.scanSetupExclusionPickerTitle,
      ),
      subtitle: Text(
        _add
            ? l10n.scanSetupFolderPickerHint
            : l10n.scanSetupExclusionPickerHint,
      ),
      emptyNote: emptyNote,
      banner: banner,
      footerNote: footer,
      confirmLabel: (n) =>
          n == 0 ? l10n.scanSetupSheetAdd : l10n.scanSetupSheetAddCount(n),
      cancelLabel: l10n.scanSetupSheetCancel,
      selectAllLabel: l10n.scanSetupSheetSelectAll,
      selectedCountLabel: (n, total) =>
          l10n.scanSetupSheetSelectedCount(n, total),
    );
  }
}
