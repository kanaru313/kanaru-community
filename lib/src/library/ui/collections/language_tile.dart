import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/browse_items.dart';
import '../browse/library_labels.dart';
import '../browse/library_navigation.dart';
import '../library_locations.dart';
import '../menus/more_button.dart';
import '../menus/open_menu.dart';
import 'collection_parts.dart';

/// Language row: icon, display name, song count (and how many were detected).
/// No play button.
class LanguageTile extends StatelessWidget {
  const LanguageTile({super.key, required this.language});

  final LanguageSummary language;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detected = language.detectedCount;
    void menu({bool viaKeyboard = false}) =>
        openLanguageMenu(context, language.code, viaKeyboard: viaKeyboard);
    return KContextRegion(
      onOpen: (at) => menu(viaKeyboard: at == null),
      child: KMediaCard(
        title: languageDisplayName(l10n, language.code),
        line2: detected > 0
            ? l10n.libraryLanguageStatsDetected(language.trackCount, detected)
            : l10n.librarySongCount(language.trackCount),
        leading: CategoryIcon.language(known: language.code != null),
        trailing: LibraryMoreButton(onPressed: menu),
        onTap: () =>
            openLibraryPage(context, LibraryLocations.language(language.code)),
      ),
    );
  }
}
