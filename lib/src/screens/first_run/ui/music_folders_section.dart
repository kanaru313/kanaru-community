import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/domain/music_folder.dart';
import '../../../library/state/music_folders_providers.dart';
import '../../../library/state/scan/display_volumes_provider.dart';
import '../../../library/state/scan/folder_candidates_provider.dart';
import '../../../library/state/scan/music_folder_editor_provider.dart';
import '../../../library/ui/scan/folder_display_path.dart';
import '../../../platform/domain/local_audio_catalog.dart';
import '../../../platform/domain/media_permissions.dart';
import '../../../platform/state/local_audio_catalog_provider.dart';
import '../../../platform/state/media_permissions_provider.dart';
import 'folder_actions.dart';
import 'section_states.dart';

final _log = Logger('screens.first_run');

/// The folders Kanaru scans: rows with a remove cross, then "Add folder".
class MusicFoldersSection extends ConsumerStatefulWidget {
  const MusicFoldersSection({super.key});

  @override
  ConsumerState<MusicFoldersSection> createState() =>
      _MusicFoldersSectionState();
}

class _MusicFoldersSectionState extends ConsumerState<MusicFoldersSection> {
  bool _busy = false;

  Future<void> _add() async {
    setState(() => _busy = true);
    try {
      await addMusicFolders(context, ref);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(MusicFolder folder) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
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
    final total = ref.watch(estimatedTrackCountProvider).value;
    final hint = total != null && total > 0
        ? l10n.scanSetupFoldersHintCount(total)
        : l10n.scanSetupFoldersHint;
    return SetupSection(
      title: Text(l10n.scanSetupFoldersTitle),
      subtitle: Text(blocked ? l10n.scanSetupFoldersNeedPermission : hint),
      children: blocked
          ? const [SetupNote(child: Text('—'))]
          : _rows(l10n, android),
    );
  }

  List<Widget> _rows(AppLocalizations l10n, bool android) {
    final folders = ref.watch(musicFoldersProvider);
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
            if (list.isEmpty) _emptyNote(l10n, android),
            for (final folder in list) _row(l10n, folder),
          ],
        ),
      ),
      SetupAddRow(
        icon: KIcons.folderAdd,
        label: Text(
          android ? l10n.scanSetupAddFolder : l10n.scanSetupAddFolderDialog,
        ),
        onTap: _busy ? null : _add,
      ),
    ];
  }

  Widget _emptyNote(AppLocalizations l10n, bool android) {
    final suggestion = ref.watch(suggestedFolderProvider).value;
    return SetupNote(
      child: Text(
        !android && suggestion == null
            ? l10n.scanSetupFoldersNoSystemMusic
            : l10n.scanSetupFoldersEmpty,
      ),
    );
  }

  Widget _row(AppLocalizations l10n, MusicFolder folder) {
    final volumes = ref.watch(displayVolumesProvider).value;
    final suggested = ref.watch(suggestedFolderProvider).value;
    final count = ref.watch(folderCountsProvider).value?[folder.root];
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
      onRemove: _busy ? null : () => _remove(folder),
    );
  }
}
