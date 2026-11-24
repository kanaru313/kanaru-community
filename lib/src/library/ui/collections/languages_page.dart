import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/browse_items.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/list_view_prefs.dart';
import '../../domain/library_tabs.dart';
import '../../state/browse/collection_providers.dart';
import '../browse/library_labels.dart';
import '../browse/library_list_frame.dart';
import '../browse/library_list_scaffold.dart';
import '../browse/library_navigation.dart';
import '../library_locations.dart';
import '../menus/open_menu.dart';
import '../selection/selection_inset.dart';
import 'collection_parts.dart';
import 'language_tile.dart';

/// The Languages list: coloured tiles (grid) or one row per language,
/// "unknown" last, with a note on where the language comes from.
class LanguagesPage extends StatelessWidget {
  const LanguagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LibraryListScaffold(
      tab: LibraryTab.languages,
      child: LibraryListFrame(
        list: BrowseList.languages,
        filterHint: l10n.libraryFilterLanguagesHint,
        viewBuilder: (context, input) =>
            CollectionViewSwitch(list: BrowseList.languages, view: input.view),
        builder: (context, input) => (
          leading: _LanguagesLeading(input: input),
          body: _LanguagesBody(input: input),
        ),
      ),
    );
  }
}

CollectionViewKey _key(LibraryListInput input) =>
    (sort: input.sort, filter: input.filter);

class _LanguagesLeading extends ConsumerWidget {
  const _LanguagesLeading({required this.input});

  final LibraryListInput input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shown = ref.watch(languageListProvider(_key(input))).value?.length;
    final total = ref.watch(languageSummariesProvider).value?.length;
    return CollectionBarLeading(
      text: collectionCountText(
        shown: shown,
        total: total,
        filtering: input.filter.isNotEmpty,
        plain: l10n.libraryLanguageCount,
        unit: l10n.libraryUnitLanguages,
        l10n: l10n,
      ),
    );
  }
}

class _LanguagesBody extends ConsumerWidget {
  const _LanguagesBody({required this.input});

  final LibraryListInput input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final scheme = Theme.of(context).colorScheme;
    final gutter = libraryGutter(context);
    final note = Padding(
      padding: EdgeInsets.fromLTRB(gutter, KSpace.x1, gutter, KSpace.x3),
      child: Text(
        l10n.libraryLanguagesNote,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
    return collectionBody(
      context,
      ref.watch(languageListProvider(_key(input))),
      (languages) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: note),
          if (input.view == CollectionView.grid)
            KCollectionGrid(
              itemCount: languages.length,
              mobileMinTileWidth: 150,
              desktopMinTileWidth: 200,
              tileAspect: 0,
              footerExtent: KColorTile.extentOf(
                scaler,
                Theme.of(context).textTheme,
              ),
              padding: EdgeInsets.symmetric(horizontal: gutter),
              itemBuilder: (context, i) =>
                  _LanguageCard(language: languages[i]),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: libraryRowGutter(context),
              ),
              sliver: SliverFixedExtentList(
                itemExtent: KMediaCard.extentOf(scaler),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => LanguageTile(language: languages[i]),
                  childCount: languages.length,
                  addAutomaticKeepAlives: false,
                ),
              ),
            ),
          const SelectionInsetSliver(),
        ],
      ),
      skeletonRows: input.view == CollectionView.list,
      roundCover: false,
      skeletonHeader: note,
    );
  }
}

/// Language tile of the grid: colour from the language code ("unknown" has a
/// fixed seed and the help icon).
class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.language});

  final LanguageSummary language;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final code = language.code;
    void menu({bool viaKeyboard = false}) =>
        openLanguageMenu(context, code, viaKeyboard: viaKeyboard);
    return KContextRegion(
      onOpen: (at) => menu(viaKeyboard: at == null),
      child: KColorTile(
        seed: languageColorSeed(code),
        title: languageDisplayName(l10n, code),
        subtitle: l10n.librarySongCount(language.trackCount),
        icon: code == null ? KIcons.help : KIcons.languages,
        onTap: () => openLibraryPage(context, LibraryLocations.language(code)),
        menuLabel: l10n.libraryMenuMore,
        onMenu: () => menu(viaKeyboard: true),
      ),
    );
  }
}
