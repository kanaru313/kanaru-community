import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/browse_items.dart';
import '../browse/group_play.dart';
import '../browse/library_navigation.dart';
import '../library_locations.dart';
import '../menus/more_button.dart';
import '../menus/open_menu.dart';
import 'collection_parts.dart';

/// Genre row: coloured icon, name, song count; ▶ plays the whole genre.
class GenreTile extends ConsumerWidget {
  const GenreTile({super.key, required this.genre});

  final GenreSummary genre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    void menu({bool viaKeyboard = false}) => openGenreMenu(
      context,
      genreKey: genre.key,
      name: genre.name,
      viaKeyboard: viaKeyboard,
    );
    return KContextRegion(
      onOpen: (at) => menu(viaKeyboard: at == null),
      child: KMediaCard(
        title: genre.name,
        line2: l10n.librarySongCount(genre.trackCount),
        leading: CategoryIcon.genre(genre: genre.name),
        onAction: () => playGenre(ref, context, genre.key, genre.name),
        actionLabel: l10n.libraryPlayAll,
        trailing: LibraryMoreButton(onPressed: menu),
        onTap: () =>
            openLibraryPage(context, LibraryLocations.genre(genre.key)),
      ),
    );
  }
}
