import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// A song row whose page is still being read: same size, no content. Shared by
/// the song lists and the selection panel.
class SongRowPlaceholder extends StatelessWidget {
  const SongRowPlaceholder({super.key, this.showNumber = false});

  /// The loaded rows carry a track-number prefix (album pages): reserve the
  /// same empty prefix so the bars line up with their titles.
  final bool showNumber;

  @override
  Widget build(BuildContext context) => KMediaCard(
    title: '',
    loading: true,
    prefix: showNumber ? const SizedBox.shrink() : null,
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
    // Same look as KMediaCard: flat (no fill, 16 dp inset) on mobile, card on
    // desktop.
    final flat = FormFactor.of(context) == FormFactor.mobile;
    return Padding(
      padding: const EdgeInsets.only(bottom: KMediaCard.gap),
      child: SizedBox(
        height: extent - KMediaCard.gap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: flat ? null : scheme.surfaceContainerLow,
            borderRadius: flat ? null : BorderRadius.circular(14),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: flat ? KLayout.gutterMobile : KSpace.x4,
              // The Retry TextButton has its own padding, so the right inset
              // is the gutter minus that padding (KSpace.x2) to line up with
              // the ⋮ of a loaded row.
              right: flat ? KLayout.gutterMobile - KSpace.x2 : 0,
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
