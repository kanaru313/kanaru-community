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

  // Shell and navigation.
  static const IconData songs = Icons.music_note;
  static const IconData albums = Icons.album;
  static const IconData artists = Icons.person;
  static const IconData genres = Icons.category;
  static const IconData languages = Icons.translate;
  static const IconData folders = Icons.folder;
  static const IconData favorites = Icons.favorite_border;
  static const IconData favoritesSelected = Icons.favorite;
  static const IconData queue = Icons.layers_outlined;
  static const IconData history = Icons.history;
  static const IconData mostPlayed = Icons.bar_chart;
  static const IconData rescan = Icons.sync;
  static const IconData keymap = Icons.keyboard;
  static const IconData ai = Icons.auto_awesome;
  static const IconData comingSoon = Icons.schedule;

  // Playback.
  static const IconData play = Icons.play_arrow;
  static const IconData pause = Icons.pause;
  static const IconData playCircle = Icons.play_circle;
  static const IconData skipNext = Icons.skip_next;
  static const IconData skipPrevious = Icons.skip_previous;
  static const IconData shuffle = Icons.shuffle;
  static const IconData repeat = Icons.repeat;
  static const IconData repeatOne = Icons.repeat_one;
  static const IconData collapse = Icons.keyboard_arrow_down;
  static const IconData expand = Icons.keyboard_arrow_up;
  static const IconData moreVert = Icons.more_vert;
  static const IconData moreHoriz = Icons.more_horiz;
  static const IconData dragHandle = Icons.drag_handle;
  static const IconData delete = Icons.delete_outline;
  static const IconData cleaning = Icons.cleaning_services;
  static const IconData libraryAdd = Icons.library_add;
  static const IconData playlistAdd = Icons.playlist_add;
  static const IconData playlistPlay = Icons.playlist_play;
  static const IconData queueMusic = Icons.queue_music;
  static const IconData lyrics = Icons.lyrics;
  static const IconData sleepTimer = Icons.bedtime;
  static const IconData volume = Icons.volume_up;
  static const IconData volumeOff = Icons.volume_off;
  static const IconData openFull = Icons.open_in_full;
  static const IconData heart = Icons.favorite_border;
  static const IconData heartFilled = Icons.favorite;
  static const IconData arrowUp = Icons.arrow_upward;
  static const IconData arrowDown = Icons.arrow_downward;
  static const IconData sidebarCover = Icons.vertical_split;

  // Library.
  static const IconData grid = Icons.grid_view;
  static const IconData list = Icons.view_list;
  static const IconData tree = Icons.account_tree;
  static const IconData flatList = Icons.format_list_bulleted;
  static const IconData filter = Icons.manage_search;
  static const IconData close = Icons.close;
  static const IconData sortAsc = Icons.arrow_upward;
  static const IconData sortDesc = Icons.arrow_downward;
  static const IconData chevronRight = Icons.chevron_right;
  static const IconData folderOpen = Icons.folder_open;
  static const IconData folderOff = Icons.folder_off;
  static const IconData folderAdd = Icons.create_new_folder;
  static const IconData theme = Icons.palette;
  static const IconData language = Icons.language;
  static const IconData multiSelect = Icons.checklist;
  static const IconData sdCard = Icons.sd_card;
  static const IconData help = Icons.help_outline;
  static const IconData openInNew = Icons.open_in_new;
  static const IconData select = Icons.check_circle;
  static const IconData selectAll = Icons.select_all;
  static const IconData cancel = Icons.cancel;
  static const IconData edit = Icons.edit;
  static const IconData info = Icons.info_outline;
  static const IconData copy = Icons.copy;
  static const IconData album = Icons.album;
  static const IconData check = Icons.check;

  // First-run setup.
  static const IconData dragIndicator = Icons.drag_indicator;
  static const IconData add = Icons.add;
  static const IconData arrowForward = Icons.arrow_forward;
  static const IconData permission = Icons.lock_open;
  static const IconData permissionMissing = Icons.gpp_maybe_outlined;
  static const IconData settingsApp = Icons.app_settings_alt;
  static const IconData image = Icons.image_outlined;
  static const IconData musicFile = Icons.audio_file;
  static const IconData circleOutline = Icons.circle_outlined;

  // Theme choice (first run, settings).
  static const IconData themeSystem = Icons.brightness_auto_outlined;
  static const IconData themeDark = Icons.dark_mode_outlined;
  static const IconData themeLight = Icons.light_mode_outlined;

  // Library sort criteria and menus.
  static const IconData duration = Icons.timer;
  static const IconData playCount = Icons.headphones;
  static const IconData dateAdded = Icons.today;
  static const IconData year = Icons.calendar_month;
  static const IconData count = Icons.tag;
  static const IconData trackNumber = Icons.format_list_numbered;
  static const IconData albumArtist = Icons.person_pin;
  static const IconData artistsMany = Icons.group;
  static const IconData deselect = Icons.remove_done;
  static const IconData advanced = Icons.tune;
  static const IconData hideFromLibrary = Icons.visibility_off;
}
