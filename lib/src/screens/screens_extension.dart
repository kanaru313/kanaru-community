import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../extension/kanaru_extension.dart';
import '../extension/state/extension_registry.dart';
import '../extension/state/registry_entries.dart';
import 'ui/home_page.dart';
import 'ui/search_page.dart';
import 'ui/settings_page.dart';

/// Home, Search and Settings. Settings is a pushed page (not a tab); desktop
/// pins it at the foot of the sidebar.
class ScreensExtension implements KanaruExtension {
  const ScreensExtension();

  @override
  String get id => 'screens';

  @override
  void register(ExtensionRegistry registry) {
    registry
      ..addNavItem(NavItem(
        id: 'home',
        path: '/',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: (c) => AppLocalizations.of(c).navHome,
        order: 10,
      ))
      ..addNavItem(NavItem(
        id: 'search',
        path: '/search',
        icon: Icons.search,
        selectedIcon: Icons.search,
        label: (c) => AppLocalizations.of(c).navSearch,
        order: 40,
      ))
      ..addNavItem(NavItem(
        id: 'settings',
        path: '/settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: (c) => AppLocalizations.of(c).navSettings,
        order: 100,
        mobileTab: false,
        footer: true,
        pushed: true,
      ))
      ..addRoute(GoRoute(path: '/', builder: (_, _) => const HomePage()))
      ..addRoute(GoRoute(path: '/search', builder: (_, _) => const SearchPage()))
      ..addRoute(GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()));
  }
}
