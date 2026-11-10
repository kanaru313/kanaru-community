import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;

/// Entry of the navigation (bottom bar on mobile, sidebar on desktop).
class NavItem {
  const NavItem({
    required this.id,
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.order,
    this.mobileTab = true,
    this.footer = false,
    this.pushed = false,
    this.parentId,
    this.sidebar = true,
    int? mobileOrder,
    this.comingSoon = false,
    this.onSelect,
  }) : mobileOrder = mobileOrder ?? order;

  final String id;

  /// Absolute location of the item's root page; the registry must hold a
  /// route with exactly this path.
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String Function(BuildContext context) label;

  /// Ascending; ties keep registration order.
  final int order;

  /// Shown in the mobile bottom bar. Mobile reaches the others by link only.
  final bool mobileTab;

  /// Desktop: pinned at the foot of the sidebar instead of the main list.
  final bool footer;

  /// Opens above the shell as a full page with its own back (the sidebar still
  /// lists it) instead of being a tab of the shell.
  final bool pushed;

  /// Id of the tab item whose branch hosts this item's route (a child route of
  /// the parent's path). Not a branch, not in the mobile bar; the desktop
  /// sidebar lists it and marks it selected while the location is at or under
  /// [path].
  final String? parentId;

  /// Listed in the desktop sidebar. False for Search and, once the six library
  /// lists exist, for the Library tab.
  final bool sidebar;

  /// Position in the mobile bottom bar (ascending); defaults to [order].
  final int mobileOrder;

  /// Shown dimmed with a "coming soon" tooltip, not selectable; needs no route.
  final bool comingSoon;

  /// Runs instead of navigating to [path] (for example Queue opens the Now
  /// Playing queue tab). An item with [onSelect] needs no route at [path].
  final void Function(BuildContext context)? onSelect;

  /// Whether this item is a shell tab with its own branch: not pushed, not a
  /// child of another item, and one that navigates.
  bool get isBranch =>
      !pushed && parentId == null && !comingSoon && onSelect == null;

  /// Whether [location] is this item's page or below it.
  bool containsLocation(String location) =>
      location == path ||
      (path != '/' &&
          location.startsWith(path.endsWith('/') ? path : '$path/'));
}

/// Block on the Settings page.
class SettingsSection {
  const SettingsSection({
    required this.id,
    required this.order,
    required this.builder,
  });

  final String id;
  final int order;
  final WidgetBuilder builder;
}

/// Widget in the right side of the desktop top bar.
class TopBarAction {
  const TopBarAction({
    required this.id,
    required this.order,
    required this.builder,
  });

  final String id;
  final int order;
  final WidgetBuilder builder;
}

/// What a startup hook may use. Hooks run after the public database is open and
/// migrated, so an extension can migrate its own tables here.
class StartupContext {
  const StartupContext({required this.connection});

  /// The public database's connection, already open and migrated (from
  /// `AppDatabase.openedConnection()`); an extension opens its own drift
  /// database on it (`ProDatabase.connect(context.connection)`).
  final DatabaseConnection connection;
}

/// Runs when the app goes to the background or asks to exit, after the settings
/// store is flushed. Use it to persist state that is otherwise written lazily.
typedef FlushHook = Future<void> Function(ProviderContainer container);

typedef StartupHook = Future<void> Function(StartupContext context);
