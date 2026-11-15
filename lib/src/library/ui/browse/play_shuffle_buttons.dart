import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// The one pair of "play all" and "shuffle" buttons every library page uses:
/// play on the left, shuffle on the right, icon only on every shell (the label
/// is the tooltip). Both are small discs, a filled one for play and a tonal one
/// for shuffle, 36 dp wide (a small icon with padding 8); they keep the
/// Material disc, sized here. A null callback disables its button.
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

  /// The 36 dp discs of a list bar; false keeps the Material size (a page's
  /// hero row).
  final bool compact;

  /// Play is a filled button with [playLabel] (a page's hero row).
  final bool labelled;

  /// More buttons after shuffle (a page's ⋮), in the same wrapping run.
  final List<Widget> trailing;

  static const double disc = KIconSize.sm + 2 * KSpace.x2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = !compact
        ? null
        : IconButton.styleFrom(
            fixedSize: const Size.square(disc),
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
    // Wraps onto a second line when large text leaves no room side by side.
    return Wrap(
      spacing: KSpace.x2,
      runSpacing: KSpace.x2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (labelled)
          FilledButton.icon(
            onPressed: onPlay,
            icon: const Icon(KIcons.play),
            label: Text(playLabel),
          )
        else
          IconButton.filled(
            tooltip: playLabel,
            style: style,
            iconSize: compact ? KIconSize.sm : null,
            onPressed: onPlay,
            icon: const Icon(KIcons.play),
          ),
        IconButton.filledTonal(
          tooltip: l10n.libraryShuffle,
          style: style,
          iconSize: compact ? KIconSize.sm : null,
          onPressed: onShuffle,
          icon: const Icon(KIcons.shuffle),
        ),
        ...trailing,
      ],
    );
  }
}
