import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../../domain/playlists/playlist_text_rules.dart';
import '../../../state/custom_cover_providers.dart';
import '../../../state/playlists/playlist_providers.dart';
import '../../playlist_common/playlist_labels.dart';
import 'playlist_name_dialog.dart';

/// "Nhân bản playlist": asks for the copy's name (prefilled with the name plus " (copy)",
/// cut to the limit) and, only when the playlist has a custom cover, whether
/// to copy it too (off by default). Returns the copy's uid; null when the user
/// cancelled or the playlist was gone (then a "not in the library" toast
/// shows). The caller stays on its page.
Future<String?> showDuplicatePlaylistDialog(
  BuildContext context,
  PlaylistSummary summary,
) async {
  assert(!summary.isFavorites, 'Favorites is never duplicated this way');
  final l10n = AppLocalizations.of(context);
  final store = ProviderScope.containerOf(context).read(playlistStoreProvider);
  // Captured before any await: the page may be gone when the toast shows.
  final messenger = ScaffoldMessenger.of(context);
  String? copyUid;
  await showKDialog<void>(
    context,
    builder: (_) => _DuplicateDialog(
      summary: summary,
      submit: (name, copyCover) async {
        copyUid = await store.duplicatePlaylist(
          summary.uid,
          name: name,
          copyCover: copyCover,
        );
        showAppSnackBarOn(
          messenger,
          copyUid == null
              ? l10n.libraryNotFoundMessage
              : l10n.playlistDuplicated(name),
        );
      },
    ),
  );
  return copyUid;
}

/// Owns the "copy the cover" choice so it lives as long as the dialog.
class _DuplicateDialog extends StatefulWidget {
  const _DuplicateDialog({required this.summary, required this.submit});

  final PlaylistSummary summary;
  final Future<void> Function(String name, bool copyCover) submit;

  @override
  State<_DuplicateDialog> createState() => _DuplicateDialogState();
}

class _DuplicateDialogState extends State<_DuplicateDialog> {
  final _copyCover = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _copyCover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = widget.summary;
    return PlaylistNameDialog(
      title: l10n.playlistMenuDuplicate,
      confirmLabel: l10n.plScreensDuplicateConfirm,
      initialName: capPlaylistName(
        l10n.playlistCopyName(playlistDisplayName(l10n, summary)),
      ),
      submit: (name) => widget.submit(name, _copyCover.value),
      extra: Consumer(
        builder: (context, ref, _) {
          final cover = ref.watch(
            customCoverKeyProvider((
              kind: CustomCoverKind.playlist,
              itemKey: summary.uid,
            )),
          );
          // No custom cover (or not known yet): nothing to copy, no row.
          if (cover.value == null) return const SizedBox.shrink();
          return ValueListenableBuilder<bool>(
            valueListenable: _copyCover,
            builder: (context, on, _) => KSwitchRow(
              title: Text(l10n.plScreensDuplicateCopyCover),
              value: on,
              onChanged: (value) => _copyCover.value = value,
            ),
          );
        },
      ),
    );
  }
}
