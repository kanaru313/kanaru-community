import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/list_view_prefs.dart';
import '../../state/browse/list_prefs_providers.dart';
import '../browse/library_list_scaffold.dart';
import '../browse/library_view_toggle.dart';

/// Left group of the bar of Albums, Artists, Genres and Languages: the count
/// (`6 / 34 artists` while filtering) and, for the lists that have two
/// layouts, the grid / list switch.
class CollectionBarLeading extends ConsumerWidget {
  const CollectionBarLeading({
    super.key,
    required this.text,
    this.switchFor,
    this.view,
  });

  /// The count, already worded.
  final String text;

  /// The list whose layout the switch changes; null = no switch.
  final BrowseList? switchFor;
  final CollectionView? view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = switchFor;
    return Row(
      children: [
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (list != null && view != null) ...[
          const KGap(KSpace.x2),
          LibraryViewToggle<CollectionView>(
            value: view!,
            options: [
              ViewOption(
                CollectionView.grid,
                KIcons.grid,
                l10n.libraryViewGrid,
              ),
              ViewOption(
                CollectionView.list,
                KIcons.list,
                l10n.libraryViewList,
              ),
            ],
            onChanged: (v) =>
                ref.read(libraryListViewsProvider.notifier).setView(list, v),
          ),
        ],
      ],
    );
  }
}

/// The body of a list fed by a provider: the data while there is some (also
/// while a newer answer loads), before the first answer skeleton rows when
/// [skeletonRows] (list view; [roundCover] for artists) or nothing, a short
/// message when the query failed and there is nothing to show.
Widget collectionBody<T>(
  BuildContext context,
  AsyncValue<List<T>> async,
  Widget Function(List<T> items) data, {
  bool skeletonRows = false,
  bool roundCover = false,
}) {
  final items = async.value;
  if (items != null) return data(items);
  if (async.hasError) {
    return Center(
      child: Text(
        AppLocalizations.of(context).libraryLoadFailed,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
  if (skeletonRows) {
    return KMediaCardSkeletonList(
      horizontalPadding: libraryRowGutter(context),
      roundCover: roundCover,
    );
  }
  return const SizedBox.shrink();
}

/// Count text of a list: `34 albums`, or `6 / 34 albums` while filtering.
String collectionCountText({
  required int? shown,
  required int? total,
  required bool filtering,
  required String Function(int count) plain,
  required String unit,
  required AppLocalizations l10n,
}) {
  if (shown == null) return '';
  if (filtering && total != null) {
    return l10n.libraryCountOf(shown, total, unit);
  }
  return plain(shown);
}

/// Icon block of a genre or language row: a [KMediaCard.coverSize] square with
/// rounded corners and a centred icon.
class CategoryIcon extends StatelessWidget {
  /// Genre block: colours seeded by [genre], the same as its grid tile.
  const CategoryIcon.genre({super.key, required String this.genre})
    : icon = KIcons.genres;

  /// Language block; [known] false (the "unknown" row) shows the help icon.
  const CategoryIcon.language({super.key, required bool known})
    : genre = null,
      icon = known ? KIcons.languages : KIcons.help;

  /// Seed of the genre colours; null = the language look.
  final String? genre;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final seed = genre;
    final colors = seed == null
        ? null
        : KCoverPlaceholderColors.of(seed, Theme.of(context).brightness);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors?.fill ?? scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox.square(
        dimension: KMediaCard.coverSize,
        child: Icon(icon, color: colors?.ink ?? scheme.onSecondaryContainer),
      ),
    );
  }
}
