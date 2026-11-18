import 'package:go_router/go_router.dart';

import 'ui/about/about_settings_page.dart';
import 'ui/appearance/appearance_settings_page.dart';
import 'ui/appearance/seek_bar_style_page.dart';
import 'ui/root/settings_root_page.dart';

/// Locations of the Settings pages. A page's header back arrow leads to its
/// parent: [seekBar] to [appearance], every other page to [root].
abstract final class SettingsPaths {
  static const root = '/settings';
  static const appearance = '/settings/appearance';
  static const seekBar = '/settings/appearance/seek-bar';
  static const about = '/settings/about';
}

/// The `/settings` branch route with the pages this module owns.
GoRoute buildSettingsRoute() => GoRoute(
  path: SettingsPaths.root,
  builder: (_, _) => const SettingsRootPage(),
  routes: [
    GoRoute(
      path: 'appearance',
      builder: (_, _) => const AppearanceSettingsPage(),
      routes: [
        GoRoute(path: 'seek-bar', builder: (_, _) => const SeekBarStylePage()),
      ],
    ),
    GoRoute(path: 'about', builder: (_, _) => const AboutSettingsPage()),
  ],
);
