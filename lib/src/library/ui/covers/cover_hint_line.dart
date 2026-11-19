import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/covers/cover_dialog_options.dart';
import '../../state/covers/cover_dialog_state.dart';
import '../../state/custom_cover_providers.dart';

/// The visible line under the preview: how to pan, what saving the automatic
/// cover does, or that an image is copied into Kanaru's data.
class CoverHintLine extends StatelessWidget {
  const CoverHintLine({super.key, required this.kind, required this.state});

  final CustomCoverKind kind;
  final CoverDialogState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auto = state.selectedId == CoverRowIds.automatic;
    final hasCustom = state.options.value?.current != null;
    // Automatic with no custom cover to drop needs no sentence.
    final String? text = state.panPossible
        ? l10n.coverPanHint
        : auto
        ? switch ((kind, hasCustom)) {
            (_, false) => null,
            (CustomCoverKind.album, true) => l10n.coverHintResetAlbum,
            (CustomCoverKind.artist, true) => l10n.coverHintResetArtist,
            (CustomCoverKind.playlist, true) => l10n.coverHintResetPlaylist,
          }
        : l10n.coverHintCopied;
    if (text == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(KSpace.x6, KSpace.x3, KSpace.x6, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.panPossible) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                KIcons.pan,
                size: KIconSize.xs,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const KGap(KSpace.x1),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
