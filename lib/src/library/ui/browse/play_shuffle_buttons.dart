import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// The one pair of "play all" and "shuffle" buttons every library page uses:
/// play on the left, shuffle on the right, icon only on every shell (the label
/// is the tooltip).
///
/// [compact] (a list bar) draws two flat icon buttons, 16 dp glyphs with 8 dp
/// around them: play in `primary`, shuffle quiet. Otherwise (a page's hero
/// row) they are Material buttons: [labelled] makes play a filled button with
/// [playLabel], else a filled and a tonal icon button. A null callback
/// disables its button.
class PlayShuffleButtons extends StatelessWidget {
  const PlayShuffleButtons({
    super.key,
    required this.onPlay,
    required this.onShuffle,
    required this.playLabel,
    this.compact = true,
    this.labelled = false,
    this.trailing = const [],
  });

  final VoidCallback? onPlay;
  final VoidCallback? onShuffle;
  final String playLabel;

  /// The flat icons of a list bar; false keeps the Material buttons (a page's
  /// hero row).
  final bool compact;

  /// Play is a filled button with [playLabel] (a page's hero row).
  final bool labelled;

  /// More buttons after shuffle (a page's ⋮), in the same wrapping run.
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Wraps onto a second line when large text leaves no room side by side.
    return Wrap(
      spacing: compact ? 0 : KSpace.x2,
      runSpacing: KSpace.x2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (compact) ...[
          KIconButton(
            tooltip: playLabel,
            onPressed: onPlay,
            icon: KIcons.play,
            size: KIconSize.xs,
            emphasis: KIconEmphasis.primary,
            padding: const EdgeInsets.all(KSpace.x2),
          ),
          KIconButton(
            tooltip: l10n.libraryShuffle,
            onPressed: onShuffle,
            icon: KIcons.shuffle,
            size: KIconSize.xs,
            padding: const EdgeInsets.all(KSpace.x2),
          ),
        ] else ...[
          if (labelled)
            FilledButton.icon(
              onPressed: onPlay,
              icon: const Icon(KIcons.play),
              label: Text(playLabel),
            )
          else
            KIconButton.yieldSpace(
              child: IconButton.filled(
                tooltip: playLabel,
                onPressed: onPlay,
                icon: const Icon(KIcons.play),
              ),
            ),
          KIconButton.yieldSpace(
            child: IconButton.filledTonal(
              tooltip: l10n.libraryShuffle,
              onPressed: onShuffle,
              icon: const Icon(KIcons.shuffle),
            ),
          ),
        ],
        ...trailing,
      ],
    );
  }
}
