import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../../state/custom_cover_providers.dart';
import '../../covers/pick_custom_cover.dart';
import '../../playlist_common/playlist_cover.dart';

/// Cover part of the Edit form: a live preview, [Change cover…], and either
/// [Automatic cover] (a custom cover exists: stages its removal until Save)
/// or the plain statement that the automatic cover is in use.
///
/// Nothing is written here: [automaticCover] only records the choice, the
/// dialog's Save applies it and Cancel drops it.
class PlaylistCoverEditor extends ConsumerWidget {
  const PlaylistCoverEditor({
    super.key,
    required this.summary,
    required this.automaticCover,
    required this.dimension,
    this.enabled = true,
  });

  final PlaylistSummary summary;

  /// True once the user chose the automatic cover.
  final ValueNotifier<bool> automaticCover;

  /// Preview side: 200 on desktop, 120 on mobile.
  final double dimension;

  /// False while the dialog saves.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final custom = ref.watch(
      customCoverKeyProvider((
        kind: CustomCoverKind.playlist,
        itemKey: summary.uid,
      )),
    );
    return ValueListenableBuilder<bool>(
      valueListenable: automaticCover,
      builder: (context, staged, _) {
        final hasCustom = custom.value != null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlaylistCover(
              uid: summary.uid,
              autoCoverKeys: summary.autoCoverKeys,
              dimension: dimension,
              automaticOnly: staged,
            ),
            const KGap(KSpace.x3),
            FilledButton.tonalIcon(
              onPressed: !enabled
                  ? null
                  : () => pickCustomCover(
                      context,
                      CustomCoverKind.playlist,
                      summary.uid,
                    ),
              icon: const Icon(KIcons.image),
              label: Text(l10n.playlistCoverChoose),
            ),
            if (hasCustom && !staged)
              TextButton(
                onPressed: enabled ? () => automaticCover.value = true : null,
                child: Text(l10n.playlistCoverAuto),
              )
            else if (!custom.isLoading)
              // State, not a hint: which cover the playlist uses. The longer
              // explanation is only a screen-reader hint.
              Padding(
                padding: const EdgeInsets.only(top: KSpace.x2),
                child: Semantics(
                  hint: l10n.playlistCoverAutoHint,
                  child: Text(
                    l10n.playlistCoverUsingAuto,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
