import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../playback/ui/transport_buttons.dart';

/// Even space between a tile's edge and the focus ring of its button.
const EdgeInsets tilePadding = EdgeInsets.all(KSpace.x1);

/// Height of the button row.
const double nowPlayingButtonRowHeight = 52;

/// Shuffle · Repeat · Ask AI (soon) · Queue, icon only, equal widths, 52 dp
/// tall, radius 16; each tile is one button from edge to edge.
class NowPlayingButtonRow extends StatelessWidget {
  const NowPlayingButtonRow({super.key, required this.onQueue});

  /// Opens the queue sheet; null leaves the button inert.
  final VoidCallback? onQueue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    Widget cell(Widget child) => Expanded(
      child: SizedBox(
        height: nowPlayingButtonRowHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: KRadius.md,
          ),
          // The button fills the tile, so the whole tile is one tap target.
          child: SizedBox.expand(child: child),
        ),
      ),
    );
    return Row(
      spacing: KSpace.x2,
      children: [
        cell(const ShuffleButton(padding: tilePadding)),
        cell(const RepeatButton(padding: tilePadding)),
        cell(
          KIconButton(
            icon: KIcons.ai,
            padding: tilePadding,
            color: scheme.primary,
            tooltip: '${l10n.playbackAskAi} · ${l10n.appComingSoon}',
            onPressed: null,
          ),
        ),
        cell(
          KIconButton(
            icon: KIcons.queueMusic,
            padding: tilePadding,
            tooltip: l10n.playbackNavQueue,
            onPressed: onQueue,
          ),
        ),
      ],
    );
  }
}
