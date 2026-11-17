import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/sort_order.dart';
import '../../domain/browse/song_scope.dart';
import '../../state/browse/song_list_providers.dart';
import '../browse/library_labels.dart';

/// `N songs · length`, or `6 / 34 songs` while a filter narrows the list.
class DetailSongsCount extends ConsumerWidget {
  const DetailSongsCount({
    super.key,
    required this.scope,
    required this.sort,
    required this.filter,
    required this.durationMs,
  });

  final SongScope scope;
  final SortOrder sort;
  final String filter;
  final int? durationMs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shown = ref
        .watch(songIdsProvider((scope: scope, sort: sort, filter: filter)))
        .value
        ?.length;
    final total = ref.watch(songCountProvider(scope)).value;
    final String text;
    if (shown == null) {
      text = '';
    } else if (filter.isNotEmpty && total != null) {
      text = l10n.libraryCountOf(shown, total, l10n.libraryUnitSongs);
    } else {
      final length = durationMs;
      text = length == null
          ? l10n.librarySongCount(shown)
          : '${l10n.librarySongCount(shown)} · '
                '${formatTotalDuration(l10n, length)}';
    }
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}
