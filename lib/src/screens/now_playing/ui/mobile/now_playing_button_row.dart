import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../playback/ui/transport_buttons.dart';

/// Height of the button row.
const double nowPlayingButtonRowHeight = 52;

/// Shuffle · Repeat · Ask AI (soon) · Queue, icon only, equal widths, 52 dp
/// tall, radius 16.
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
          child: Center(child: child),
        ),
      ),
    );
    return Row(
      spacing: KSpace.x2,
      children: [
        cell(const ShuffleButton()),
        cell(const RepeatButton()),
        cell(
          IconButton(
            icon: const Icon(KIcons.ai),
            color: scheme.primary,
            tooltip: '${l10n.playbackAskAi} · ${l10n.appComingSoon}',
            onPressed: null,
          ),
        ),
        cell(
          IconButton(
            icon: const Icon(KIcons.queueMusic),
            tooltip: l10n.playbackNavQueue,
            onPressed: onQueue,
          ),
        ),
      ],
    );
  }
}
