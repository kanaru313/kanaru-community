import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// A song row whose page is still being read: same size, no content. Shared by
/// the song lists and the selection panel.
class SongRowPlaceholder extends StatelessWidget {
  const SongRowPlaceholder({super.key, required this.extent});

  final double extent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: KMediaCard.gap),
    child: SizedBox(
      height: extent - KMediaCard.gap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
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
    return Padding(
      padding: const EdgeInsets.only(bottom: KMediaCard.gap),
      child: SizedBox(
        height: extent - KMediaCard.gap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: KSpace.x4),
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
