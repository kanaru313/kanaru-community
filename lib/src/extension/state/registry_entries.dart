import 'package:flutter/widgets.dart';

import '../../database/app_database.dart';

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
  });

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
}

/// Block on the Settings page.
class SettingsSection {
  const SettingsSection({required this.id, required this.order, required this.builder});

  final String id;
  final int order;
  final WidgetBuilder builder;
}

/// Widget in the right side of the desktop top bar.
class TopBarAction {
  const TopBarAction({required this.id, required this.order, required this.builder});

  final String id;
  final int order;
  final WidgetBuilder builder;
}

/// What a startup hook may use. Hooks run after the public database is open and
/// migrated, so an extension can migrate its own tables here.
class StartupContext {
  const StartupContext({required this.database});

  final AppDatabase database;
}

typedef StartupHook = Future<void> Function(StartupContext context);
