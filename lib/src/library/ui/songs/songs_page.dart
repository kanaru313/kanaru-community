import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
import '../../domain/library_tabs.dart';
import '../../state/browse/song_list_providers.dart';
import '../browse/library_list_frame.dart';
import '../browse/library_list_scaffold.dart';
import '../browse/play_actions.dart';
import 'song_list.dart';

/// The Songs list: every visible track, in the remembered sort.
class SongsPage extends StatelessWidget {
  const SongsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final playContext = PlayContext(
      PlayContextKind.songs,
      label: l10n.libraryTabSongs,
    );
    return LibraryListScaffold(
      tab: LibraryTab.songs,
      child: LibraryListFrame(
        list: BrowseList.songs,
        filterHint: l10n.libraryFilterSongsHint,
        builder: (context, input) => (
          leading: _SongsBarLeading(input: input, playContext: playContext),
          body: SongList(
            scope: const SongScope.all(),
            sort: input.sort,
            filter: input.filter,
            playContext: playContext,
          ),
        ),
      ),
    );
  }
}

/// Left group of the Songs bar: shuffle, play all and the count.
class _SongsBarLeading extends ConsumerWidget {
  const _SongsBarLeading({required this.input, required this.playContext});

  final LibraryListInput input;
  final PlayContext playContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final key = (
      scope: const SongScope.all(),
      sort: input.sort,
      filter: input.filter,
    );
    final ids = ref.watch(songIdsProvider(key)).value;
    final list = ids ?? const <TrackId>[];
    final total = ref.watch(songCountProvider(const SongScope.all())).value;
    final shown = ids?.length;
    final enabled = list.isNotEmpty;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final count = shown == null
        ? ''
        : input.filter.isNotEmpty && total != null
        ? l10n.libraryCountOf(shown, total, l10n.libraryUnitSongs)
        : l10n.librarySongCount(shown);
    return Row(
      children: [
        if (desktop) ...[
          OutlinedButton.icon(
            onPressed: enabled
                ? () => shuffleAll(ref, context, list, playContext)
                : null,
            icon: const Icon(KIcons.shuffle),
            label: Text(l10n.libraryShuffle),
          ),
          const KGap(KSpace.x2),
          FilledButton.tonalIcon(
            onPressed: enabled
                ? () => playAll(ref, context, list, playContext)
                : null,
            icon: const Icon(KIcons.play),
            label: Text(l10n.libraryPlayAll),
          ),
        ] else ...[
          IconButton(
            tooltip: l10n.libraryShuffle,
            onPressed: enabled
                ? () => shuffleAll(ref, context, list, playContext)
                : null,
            icon: const Icon(KIcons.shuffle),
          ),
          IconButton.filledTonal(
            tooltip: l10n.libraryPlayAll,
            onPressed: enabled
                ? () => playAll(ref, context, list, playContext)
                : null,
            icon: const Icon(KIcons.play),
          ),
        ],
        if (count.isNotEmpty)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: KSpace.x3),
              child: Text(
                count,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
