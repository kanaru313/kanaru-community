import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../playback/state/now_playing_panel.dart';
import '../lyrics_settings_link.dart';

/// Opens the plugin store filtered to lyrics plugins. The desktop Now Playing
/// panel is closed so the page is visible; the router is taken first because
/// a modal that called this is gone once it pops.
void openLyricsPluginStore(BuildContext context, WidgetRef ref) {
  final router = GoRouter.of(context);
  ref.read(nowPlayingPanelProvider.notifier).close();
  router.go(lyricsPluginStoreLocation);
}
