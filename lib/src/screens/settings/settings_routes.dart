import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import 'ui/about/about_settings_page.dart';
import 'ui/appearance/appearance_settings_page.dart';
import 'ui/appearance/seek_bar_style_page.dart';
import 'ui/playback/playback_settings_page.dart';
import 'ui/root/settings_root_page.dart';

/// Locations of the Settings pages. A page's header back arrow leads to its
/// parent: [seekBar] to [appearance], every other page to [root].
abstract final class SettingsPaths {
  static const root = '/settings';
  static const appearance = '/settings/appearance';
  static const seekBar = '/settings/appearance/seek-bar';
  static const playback = '/settings/playback';
  static const about = '/settings/about';
}

/// The `/settings` branch route with the pages this module owns.
GoRoute buildSettingsRoute() => GoRoute(
  path: SettingsPaths.root,
  builder: (_, _) => const SettingsRootPage(),
  routes: [
    GoRoute(
      path: 'appearance',
      pageBuilder: (_, s) => _page(s, const AppearanceSettingsPage()),
      routes: [
        GoRoute(
          path: 'seek-bar',
          pageBuilder: (_, s) => _page(s, const SeekBarStylePage()),
        ),
      ],
    ),
    GoRoute(
      path: 'playback',
      pageBuilder: (_, s) => _page(s, const PlaybackSettingsPage()),
    ),
    GoRoute(
      path: 'about',
      pageBuilder: (_, s) => _page(s, const AboutSettingsPage()),
    ),
  ],
);

/// Sub-pages share the transition of the library detail pages.
Page<void> _page(GoRouterState state, Widget child) =>
    KDetailPage(key: state.pageKey, child: child);
