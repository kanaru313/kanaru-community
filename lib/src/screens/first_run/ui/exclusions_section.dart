import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
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
import 'setup_mode.dart';

/// Sub-folders of the music folders that scans skip. In [SetupMode.settings]
/// an edit rescans in the background and says so.
class ExclusionsSection extends ConsumerStatefulWidget {
  const ExclusionsSection({super.key, this.mode = SetupMode.firstRun});

  final SetupMode mode;

  @override
  ConsumerState<ExclusionsSection> createState() => _ExclusionsSectionState();
}

class _ExclusionsSectionState extends ConsumerState<ExclusionsSection> {
  bool _busy = false;

  Future<void> _add() async {
    setState(() => _busy = true);
    try {
      await addExclusions(context, ref, mode: widget.mode);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(MusicFolder folder, String key, String name) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final ok = await ref
          .read(musicFolderEditorProvider)
          .includeFolder(folder, key);
      if (!ok) {
        showAppSnackBarOn(messenger, l10n.scanSetupWriteFailed);
      } else if (widget.mode == SetupMode.settings) {
        // Undoing an exclusion already asked for the rescan.
        showAppSnackBarOn(
          messenger,
          l10n.settingsLibraryExclusionRemoved(name),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final permission = ref.watch(mediaPermissionStateProvider).value;
    final blocked =
        permission != null &&
        permission.applies &&
        permission.audio != MediaPermissionStatus.granted;
    final android =
        ref.watch(localAudioCatalogProvider).folderChoice ==
        FolderChoice.mediaStoreSheet;
    final folders = ref.watch(musicFoldersProvider).value ?? const [];
    final entries = ref.watch(exclusionEntriesProvider);
    return captionedSection(
      context,
      mode: widget.mode,
      title: l10n.scanSetupExclusionsTitle,
      caption: l10n.scanSetupExclusionsHint,
      state: blocked ? l10n.scanSetupFoldersNeedPermission : null,
      children: blocked
          ? const [SetupNote(child: Text('—'))]
          : [
              entries.when(
                loading: () => const SetupNote(child: SectionSpinner()),
                error: (_, _) => SectionLoadFailed(
                  onRetry: () => ref.invalidate(exclusionEntriesProvider),
                ),
                data: (list) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (list.isEmpty)
                      SetupNote(child: Text(l10n.scanSetupExclusionsEmpty)),
                    for (final entry in list)
                      _row(
                        l10n,
                        entry.sourceId,
                        entry.folderKey,
                        entry.displayPath,
                        folders,
                      ),
                  ],
                ),
              ),
              SetupAddRow(
                icon: KIcons.add,
                label: Text(
                  android
                      ? l10n.scanSetupAddExclusion
                      : l10n.scanSetupAddExclusionDialog,
                ),
                // Only sub-folders of a chosen folder can be excluded.
                onTap: _busy || folders.isEmpty ? null : _add,
              ),
            ],
    );
  }

  Widget _row(
    AppLocalizations l10n,
    int sourceId,
    String key,
    String path,
    List<MusicFolder> folders,
  ) {
    final volumes = ref.watch(displayVolumesProvider).value;
    final shown = TickerMode.valuesOf(context).enabled;
    final counts = shown ? ref.watch(folderCountsProvider).value : null;
    final count = counts?[path];
    final owner = folders.where((f) => f.sourceId == sourceId).firstOrNull;
    final name = baseName(path);
    return SetupPathRow(
      key: ValueKey('$sourceId/$key'),
      icon: KIcons.folderOff,
      title: Text(name),
      path: Text(
        volumes == null ? path : folderDisplayPathOf(l10n, volumes, path),
      ),
      count: count == null ? null : Text(l10n.scanSetupFolderSongs(count)),
      removeTooltip: l10n.scanSetupFolderRemove(name),
      onRemove: _busy || owner == null ? null : () => _remove(owner, key, name),
    );
  }
}
