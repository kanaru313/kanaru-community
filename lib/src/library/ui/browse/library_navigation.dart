import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/library_tabs.dart';

/// Opens a library page (album, artist, genre, language, see-all, a folder
/// level) from another page. A push, so Back returns one page at a time.
/// Switching between the six lists uses `context.go` instead.
Future<T?> openLibraryPage<T extends Object?>(
  BuildContext context,
  String location,
) => context.push<T>(location);

/// The list page shown last (memory only). `/library` redirects to it, and
/// the page that opens next slides in from the side this tab lies on.
class LastLibraryTab extends Notifier<LibraryTab?> {
  @override
  LibraryTab? build() => null;

  void visit(LibraryTab tab) => state = tab;
}

final lastLibraryTabProvider = NotifierProvider<LastLibraryTab, LibraryTab?>(
  LastLibraryTab.new,
);

/// Scroll offset of the mobile sub-tab row, so the row of the next list page
/// starts where this one stopped and scrolls on from there.
class SubTabOffset extends Notifier<double> {
  @override
  double build() => 0;

  void update(double offset) => state = offset;
}

final subTabOffsetProvider = NotifierProvider<SubTabOffset, double>(
  SubTabOffset.new,
);
