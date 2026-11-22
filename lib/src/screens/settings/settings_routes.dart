import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../lyrics/ui/lyrics_settings_link.dart';
import '../plugins/plugin_routes.dart';
import 'ui/about/about_settings_page.dart';
import 'ui/appearance/appearance_settings_page.dart';
import 'ui/appearance/seek_bar_style_page.dart';
import 'ui/library/artist_split_page.dart';
import 'ui/library/library_settings_page.dart';
import 'ui/lyrics/lyrics_settings_page.dart';
import 'ui/playback/playback_settings_page.dart';
import 'ui/root/settings_root_page.dart';

/// Locations of the Settings pages. A page's header back arrow leads to its
/// parent: [seekBar] to [appearance], every other page to [root]; [artistSplit] to [library].
/// The plugin store and its repositories live in `PluginPaths`.
abstract final class SettingsPaths {
  static const root = '/settings';
  static const appearance = '/settings/appearance';
  static const seekBar = '/settings/appearance/seek-bar';
  static const library = '/settings/library';
  static const artistSplit = '/settings/library/artist-split';
  static const playback = '/settings/playback';
  static const lyrics = lyricsSettingsLocation;
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
      path: 'library',
      pageBuilder: (_, s) => _page(s, const LibrarySettingsPage()),
      routes: [
        GoRoute(
          path: 'artist-split',
          pageBuilder: (_, s) => _page(s, const ArtistSplitPage()),
        ),
      ],
    ),
    GoRoute(
      path: 'playback',
      pageBuilder: (_, s) => _page(s, const PlaybackSettingsPage()),
    ),
    GoRoute(
      path: 'lyrics',
      pageBuilder: (_, s) => _page(s, const LyricsSettingsPage()),
    ),
    GoRoute(
      path: 'about',
      pageBuilder: (_, s) => _page(s, const AboutSettingsPage()),
    ),
    buildPluginsRoute(),
  ],
);

/// Sub-pages share the transition of the library detail pages.
Page<void> _page(GoRouterState state, Widget child) =>
    KDetailPage(key: state.pageKey, child: child);
