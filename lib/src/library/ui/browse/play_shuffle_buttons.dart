import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// The one pair of "play all" and "shuffle" buttons every library page uses:
/// play on the left, shuffle on the right. Shuffle is always a tonal icon;
/// play is a filled button with [playLabel] when [labelled], a filled icon
/// (with the label as tooltip) otherwise. A null callback disables its button.
class PlayShuffleButtons extends StatelessWidget {
  const PlayShuffleButtons({
    super.key,
    required this.onPlay,
    required this.onShuffle,
    required this.playLabel,
    this.labelled = false,
    this.trailing = const [],
  });

  final VoidCallback? onPlay;
  final VoidCallback? onShuffle;
  final String playLabel;
  final bool labelled;

  /// More buttons after shuffle (a page's ⋮), in the same wrapping run.
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Wraps onto a second line when large text leaves no room side by side.
    return Wrap(
      spacing: labelled ? KSpace.x2 : 0,
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
            onPressed: onPlay,
            icon: const Icon(KIcons.play),
          ),
        IconButton.filledTonal(
          tooltip: l10n.libraryShuffle,
          onPressed: onShuffle,
          icon: const Icon(KIcons.shuffle),
        ),
        ...trailing,
      ],
    );
  }
}
