import 'package:material_ui/material_ui.dart';

/// Role-named icons. The only file that names a concrete icon set, so
/// switching sets (Material, Fluent, Symbols) is a one-file change.
abstract final class KIcons {
  static const IconData home = Icons.home_outlined;
  static const IconData homeSelected = Icons.home;
  static const IconData library = Icons.library_music_outlined;
  static const IconData librarySelected = Icons.library_music;
  static const IconData playlists = Icons.queue_music_outlined;
  static const IconData playlistsSelected = Icons.queue_music;
  static const IconData search = Icons.search;
  static const IconData searchSelected = Icons.search;
  static const IconData online = Icons.cloud_outlined;
  static const IconData onlineSelected = Icons.cloud;
  static const IconData settings = Icons.settings_outlined;
  static const IconData settingsSelected = Icons.settings;
  static const IconData back = Icons.arrow_back;
  static const IconData forward = Icons.arrow_forward;
  static const IconData sidebarToggle = Icons.menu;
  static const IconData appLogo = Icons.music_note;

  // Generic glyphs, used by tests and placeholders.
  static const IconData placeholder = Icons.circle;
  static const IconData extension = Icons.extension_outlined;
  static const IconData extensionSelected = Icons.extension;
  static const IconData bolt = Icons.bolt_outlined;
  static const IconData boltSelected = Icons.bolt;
}
