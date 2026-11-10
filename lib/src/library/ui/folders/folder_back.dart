import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'folder_locations.dart';

/// Moves the Folders page to [to] without adding a page: the page is replaced.
/// [entry], the level the page was opened at, rides along as the route's
/// `extra`, because a replaced page is a new page and could not remember it.
void moveToFolder(
  BuildContext context,
  FolderLocation to, {
  required FolderLocation entry,
}) => context.replace(to.path, extra: entry);

/// Back on the Folders page goes up one folder before it leaves the tab.
///
/// The page leaves (`canPop`) at the top of the tab, and at the level it was
/// opened at: a Folders page pushed from another page ("Go to folder" from an
/// album) can be drilled into, and Back climbs the same levels and then
/// returns to the page it came from. Climbing is `replace`, so the pages
/// below stay as they were.
class FolderBackGuard extends StatelessWidget {
  const FolderBackGuard({
    super.key,
    required this.parent,
    required this.entry,
    required this.current,
    required this.filterOpen,
    required this.child,
  });

  /// Where Back goes from the level on screen; null at the top of the tab.
  final FolderLocation? parent;

  /// The level the page was opened at (carried through replaces).
  final FolderLocation entry;

  /// The level on screen.
  final FolderLocation current;

  /// The filter field is open: Back closes it first (the list frame does
  /// that), and this guard stays out of the way.
  final bool filterOpen;
  final Widget child;

  /// Climbing may skip folders (merged chain links); it must not skip the
  /// level the page was opened at, which is where Back hands over to the page
  /// below.
  FolderLocation? _stopAtEntry(FolderLocation? up) {
    if (up == null || up.sourceUid == null || entry.key.isEmpty) return up;
    final inside =
        entry.sourceUid == up.sourceUid &&
        entry.key != current.key &&
        current.key.startsWith('${entry.key}/') &&
        (up.key.isEmpty || entry.key.startsWith('${up.key}/'));
    return inside ? entry : up;
  }

  @override
  Widget build(BuildContext context) {
    final up = _stopAtEntry(parent);
    return PopScope(
      canPop: up == null || current == entry || filterOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && up != null && !filterOpen) {
          moveToFolder(context, up, entry: entry);
        }
      },
      child: child,
    );
  }
}
