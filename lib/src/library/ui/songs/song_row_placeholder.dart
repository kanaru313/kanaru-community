import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Skeleton of a song row whose page is still being read: a loading
/// `KMediaCard` (grey cover box and placeholder bars), the same size as a real
/// row and hidden from semantics. Shared by the song lists and the selection
/// panel. [filled] false (the selection panel, which has a surface of its
/// own) leaves out the neutral row fill.
class SongRowPlaceholder extends StatelessWidget {
  const SongRowPlaceholder({super.key, this.filled = true});

  final bool filled;

  @override
  Widget build(BuildContext context) =>
      KMediaCard(title: '', loading: true, filled: filled);
}

/// A song row whose page could not be read: "Could not load" and a Retry, in
/// the place of the row, so the message is where the user is looking.
class SongRowFailed extends StatelessWidget {
  const SongRowFailed({super.key, required this.extent, required this.onRetry});

  final double extent;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Same look as KMediaCard: the row fill, flat on mobile, a radius-14
    // card on desktop.
    final flat = FormFactor.of(context) == FormFactor.mobile;
    return Padding(
      padding: const EdgeInsets.only(bottom: KMediaCard.gap),
      child: SizedBox(
        height: extent - KMediaCard.gap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: KRowColors.fill(Theme.of(context).brightness),
            borderRadius: flat ? null : BorderRadius.circular(14),
          ),
          child: Padding(
            // The row padding of a loaded row on both sides, so the Retry
            // button ends where the ⋮ of a loaded row ends.
            padding: const EdgeInsets.symmetric(
              horizontal: KMediaCard.sidePadding,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.libraryLoadFailed,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.error),
                  ),
                ),
                TextButton(onPressed: onRetry, child: Text(l10n.libraryRetry)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
