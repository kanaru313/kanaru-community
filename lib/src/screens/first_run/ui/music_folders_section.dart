import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/domain/music_folder.dart';
import '../../../library/state/music_folders_providers.dart';
import '../../../library/state/scan/display_volumes_provider.dart';
import '../../../library/state/scan/folder_candidates_provider.dart';
import '../../../library/state/scan/media_index_refresh.dart';
import '../../../library/state/scan/music_folder_editor_provider.dart';
import '../../../library/ui/scan/folder_display_path.dart';
import '../../../platform/domain/local_audio_catalog.dart';
import '../../../platform/domain/media_permissions.dart';
import '../../../platform/state/local_audio_catalog_provider.dart';
import '../../../platform/state/media_permissions_provider.dart';
import 'folder_actions.dart';
import 'folder_sheet_states.dart' show refreshSeenFrom;
import 'no_music_card_note.dart';
import 'section_states.dart';
import 'setup_mode.dart';

final _log = Logger('screens.first_run');

/// The folders Kanaru scans: rows with a remove cross, then "Add folder".
///
/// In [SetupMode.settings] an edit rescans in the background, removing asks
/// first and the last folder cannot be removed. The Android estimate and the
/// per-folder counts are read only while the section is shown (the Settings
/// branch stays mounted behind other tabs and must not query MediaStore).
class MusicFoldersSection extends ConsumerStatefulWidget {
  const MusicFoldersSection({super.key, this.mode = SetupMode.firstRun});

  final SetupMode mode;

  @override
  ConsumerState<MusicFoldersSection> createState() =>
      _MusicFoldersSectionState();
}

class _MusicFoldersSectionState extends ConsumerState<MusicFoldersSection> {
  bool _busy = false;

  /// Refresh results at or below this run id predate the section.
  late final int _refreshSeenFrom;

  @override
  void initState() {
    super.initState();
    _refreshSeenFrom = refreshSeenFrom(ref.read(mediaIndexRefreshProvider));
  }

  Future<void> _add() async {
    setState(() => _busy = true);
    try {
      await addMusicFolders(context, ref, mode: widget.mode);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(MusicFolder folder, int? songs) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      if (widget.mode == SetupMode.settings) {
        await removeMusicFolderChecked(context, ref, folder, songs: songs);
        return;
      }
      final ok = await ref.read(musicFolderEditorProvider).removeFolder(folder);
      if (!ok && mounted) showAppSnackBar(context, l10n.scanSetupWriteFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final permission = ref.watch(mediaPermissionStateProvider).value;
    final catalog = ref.watch(localAudioCatalogProvider);
    final android = catalog.folderChoice == FolderChoice.mediaStoreSheet;
    final blocked =
        permission != null &&
        permission.applies &&
        permission.audio != MediaPermissionStatus.granted;
    final shown = TickerMode.valuesOf(context).enabled;
    final total = shown ? ref.watch(estimatedTrackCountProvider).value : null;
    final estimate = total != null && total > 0 ? total : null;
    final settings = widget.mode == SetupMode.settings;
    return captionedSection(
      context,
      mode: widget.mode,
      title: l10n.scanSetupFoldersTitle,
      caption: !settings && estimate != null
          ? l10n.scanSetupFoldersHintCount(estimate)
          : l10n.scanSetupFoldersHint,
      state: blocked
          ? l10n.scanSetupFoldersNeedPermission
          : settings && estimate != null
          ? l10n.settingsLibraryFoldersEstimate(estimate)
          : null,
      children: blocked
          ? const [SetupNote(child: Text('—'))]
          : _rows(
              l10n,
              android,
              audioGranted:
                  permission != null &&
                  permission.applies &&
                  permission.audio == MediaPermissionStatus.granted,
              shown: shown,
            ),
    );
  }

  List<Widget> _rows(
    AppLocalizations l10n,
    bool android, {
    required bool audioGranted,
    required bool shown,
  }) {
    final folders = ref.watch(musicFoldersProvider);
    // Android is indexing: the card and the sheet share one run.
    final scanning =
        android && ref.watch(mediaIndexRefreshProvider) is IndexRefreshRunning;
    return [
      folders.when(
        loading: () => const SetupNote(child: SectionSpinner()),
        error: (e, st) {
          _log.warning('music folders failed to load', e, st);
          return SectionLoadFailed(
            onRetry: () => ref.invalidate(musicFoldersProvider),
          );
        },
        data: (list) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (list.isEmpty) _emptyNote(l10n, android, audioGranted),
            for (final folder in list) _row(l10n, folder, shown),
          ],
        ),
      ),
      SetupAddRow(
        icon: KIcons.folderAdd,
        label: Text(
          android ? l10n.scanSetupAddFolder : l10n.scanSetupAddFolderDialog,
        ),
        onTap: _busy || scanning ? null : _add,
      ),
    ];
  }

  Widget _emptyNote(AppLocalizations l10n, bool android, bool audioGranted) {
    if (android) {
      return NoMusicCardNote(autoRun: audioGranted, seenFrom: _refreshSeenFrom);
    }
    final suggestion = ref.watch(suggestedFolderProvider).value;
    return SetupNote(
      child: Text(
        suggestion == null
            ? l10n.scanSetupFoldersNoSystemMusic
            : l10n.scanSetupFoldersEmpty,
      ),
    );
  }

  Widget _row(AppLocalizations l10n, MusicFolder folder, bool shown) {
    final volumes = ref.watch(displayVolumesProvider).value;
    final suggested = ref.watch(suggestedFolderProvider).value;
    final counts = shown ? ref.watch(folderCountsProvider).value : null;
    final count = counts?[folder.root];
    return SetupPathRow(
      key: ValueKey(folder.sourceId),
      icon: KIcons.folders,
      title: Text(folder.name),
      path: Text(
        volumes == null
            ? folder.root
            : folderDisplayPathOf(l10n, volumes, folder.root),
      ),
      count: count == null ? null : Text(l10n.scanSetupFolderSongs(count)),
      badge: suggested == folder.root
          ? Text(l10n.scanSetupFolderSuggested)
          : null,
      removeTooltip: l10n.scanSetupFolderRemove(folder.name),
      onRemove: _busy ? null : () => _remove(folder, count),
    );
  }
}
