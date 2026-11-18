import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../browse/library_list_scaffold.dart';

/// "N songs are not in your library" with the button that removes them: a
/// visible state line under the list bar, never behind a hint.
class PlaylistMissingNote extends StatelessWidget {
  const PlaylistMissingNote({
    super.key,
    required this.count,
    required this.onRemove,
  });

  final int count;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final gutter = libraryBarGutter(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, KSpace.x2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: KRadius.sm,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KSpace.x3,
            vertical: KSpace.x2,
          ),
          child: Row(
            children: [
              Icon(
                KIcons.musicOff,
                size: KIconSize.sm,
                color: scheme.onSurfaceVariant,
              ),
              const KGap(KSpace.x3),
              Expanded(
                child: Text(
                  l10n.playlistUnavailableNote(count),
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              const KGap(KSpace.x2),
              TextButton(
                onPressed: onRemove,
                child: Text(l10n.playlistRemoveUnavailableAction(count)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
