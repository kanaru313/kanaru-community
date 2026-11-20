import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../detail/detail_header.dart';
import '../library_locations.dart';

/// Frame of the pages of the History family (History, one song's plays, Most
/// played): a detail frame with the page ground, plus the two-column layout
/// for pages that have a hero.
///
/// The hero names the page, so the header shows no title until the hero's
/// scrolls out of sight (narrow only). On the mobile shell the page is a child
/// of the Playlist tab with a back button; on desktop a sidebar page has none
/// (and fills the width), a sub-page does ([showBack]).
class HistoryPageFrame extends StatelessWidget {
  /// A page of any content (a state, an empty page).
  const HistoryPageFrame({
    super.key,
    required this.title,
    required this.child,
    this.titleInContent = false,
    this.showBack,
  });

  /// A page with a hero in [header] and the lists in [slivers]: one column
  /// when narrow, the hero in a fixed 320 dp column from 840 dp of page
  /// width (measured on the page, not the window).
  HistoryPageFrame.layout({
    super.key,
    required this.title,
    required Widget header,
    required List<Widget> slivers,
    this.showBack,
  }) : titleInContent = true,
       child = KDetailLayout(header: header, slivers: slivers);

  /// Name of the page; the header shows it while the hero's name is hidden.
  final String title;
  final Widget child;
  final bool titleInContent;

  /// Null: a back button on the mobile shell only.
  final bool? showBack;

  @override
  Widget build(BuildContext context) => DetailFrame(
    title: title,
    titleInContent: titleInContent,
    fallback: LibraryLocations.playlists,
    showBack: showBack ?? FormFactor.of(context) != FormFactor.desktop,
    child: child,
  );
}
