import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/saved_queues/saved_queue_store.dart';
import '../../state/saved_queues/saved_queue_providers.dart';
import '../browse/library_list_scaffold.dart';
import '../collections/collection_parts.dart';
import '../history/history_page_frame.dart';
import '../selection/selection_inset.dart';
import 'saved_queue_tile.dart';

/// The Queue page of the Playlist tab: the queues the player replaced or
/// cleared, newest first (at most 20), one row each. Plain page: the header
/// names it, nothing is tinted.
///
/// The line under the header says what the list is; the empty page says it
/// itself and has no such line. While the first read runs the rows are
/// skeletons under the same line.
class SavedQueuesPage extends ConsumerWidget {
  const SavedQueuesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(savedQueuesProvider);
    return HistoryPageFrame(
      title: l10n.playbackNavQueue,
      child: collectionBody<SavedQueueRow>(
        context,
        async,
        (rows) => rows.isEmpty
            ? KEmpty(icon: KIcons.queue, message: l10n.savedQueueEmpty)
            : _List(rows: rows),
        skeletonRows: true,
        skeletonHeader: const _Note(),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.rows});

  final List<SavedQueueRow> rows;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      const SliverToBoxAdapter(child: _Note()),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: libraryRowGutter(context)),
        sliver: SliverFixedExtentList(
          itemExtent: KMediaCard.extentOf(MediaQuery.textScalerOf(context)),
          delegate: SliverChildBuilderDelegate(
            (context, i) => SavedQueueTile(
              key: ValueKey(rows[i].summary.uid),
              row: rows[i],
            ),
            childCount: rows.length,
            addAutomaticKeepAlives: false,
          ),
        ),
      ),
      const SelectionInsetSliver(),
    ],
  );
}

/// What this list is, as a visible line (no ⓘ outside Settings).
class _Note extends StatelessWidget {
  const _Note();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gutter = libraryBarGutter(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, KSpace.x1, gutter, KSpace.x3),
      child: Text(
        AppLocalizations.of(context).savedQueueExplain,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
