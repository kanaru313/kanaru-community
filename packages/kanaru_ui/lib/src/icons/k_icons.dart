import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';

/// Role-named icons. Maps the entire design system to Fluent System Icons
/// (by Microsoft, MIT License), maintaining visual parity with the original app.
abstract final class KIcons {
  static const IconData home = FluentIcons.home_24_regular;
  static const IconData homeSelected = FluentIcons.home_24_filled;
  static const IconData library = FluentIcons.library_24_regular;
  static const IconData librarySelected = FluentIcons.library_24_filled;
  static const IconData playlists =
      FluentIcons.text_bullet_list_square_24_regular;
  static const IconData playlistsSelected =
      FluentIcons.text_bullet_list_square_24_filled;
  static const IconData search = FluentIcons.search_24_regular;
  static const IconData searchSelected = FluentIcons.search_24_filled;
  static const IconData online = FluentIcons.globe_24_regular;
  static const IconData onlineSelected = FluentIcons.globe_24_filled;
  static const IconData settings = FluentIcons.settings_24_regular;
  static const IconData settingsSelected = FluentIcons.settings_24_filled;
  static const IconData back = FluentIcons.arrow_left_24_regular;
  static const IconData forward = FluentIcons.arrow_right_24_regular;
  static const IconData sidebarToggle = FluentIcons.navigation_24_regular;

  // Generic glyphs, used by tests and placeholders.
  static const IconData placeholder = FluentIcons.circle_24_filled;
  static const IconData extension = FluentIcons.puzzle_piece_24_regular;
  static const IconData extensionSelected = FluentIcons.puzzle_piece_24_filled;
  static const IconData bolt = FluentIcons.flash_24_regular;
  static const IconData boltSelected = FluentIcons.flash_24_filled;

  // Shell and navigation.
  static const IconData songs = FluentIcons.music_note_2_24_regular;
  static const IconData albums = FluentIcons.album_24_regular;
  static const IconData artists = FluentIcons.person_24_regular;
  static const IconData genres = FluentIcons.shapes_24_regular;
  static const IconData languages = FluentIcons.translate_24_regular;
  static const IconData folders = FluentIcons.folder_24_regular;
  static const IconData favorites = FluentIcons.heart_24_regular;
  static const IconData favoritesSelected = FluentIcons.heart_24_filled;
  static const IconData queue = FluentIcons.reorder_20_regular;
  static const IconData history = FluentIcons.history_24_regular;

  /// History switched off (the "recording is off" notice).
  static const IconData historyOff = FluentIcons.history_dismiss_24_regular;
  static const IconData mostPlayed = FluentIcons.data_histogram_24_regular;
  static const IconData rescan = FluentIcons.arrow_sync_24_regular;

  /// Restore defaults (not [history], which means listening history).
  static const IconData reset = FluentIcons.arrow_reset_24_regular;
  static const IconData keymap = FluentIcons.keyboard_24_regular;
  static const IconData ai = FluentIcons.sparkle_24_regular;
  static const IconData comingSoon = FluentIcons.clock_24_regular;

  // Playback.
  static const IconData play = FluentIcons.play_24_filled;
  static const IconData pause = FluentIcons.pause_24_filled;
  static const IconData playCircle = FluentIcons.play_circle_24_regular;
  static const IconData skipNext = FluentIcons.next_24_filled;
  static const IconData skipPrevious = FluentIcons.previous_24_filled;
  static const IconData shuffle = FluentIcons.arrow_shuffle_24_regular;
  static const IconData repeat = FluentIcons.arrow_repeat_all_24_regular;
  static const IconData repeatOne = FluentIcons.arrow_repeat_1_24_regular;
  static const IconData collapse = FluentIcons.chevron_down_24_regular;
  static const IconData expand = FluentIcons.chevron_up_24_regular;
  static const IconData moreVert = FluentIcons.more_vertical_24_regular;
  static const IconData moreHoriz = FluentIcons.more_horizontal_24_regular;
  static const IconData dragHandle =
      FluentIcons.re_order_dots_vertical_24_regular;
  static const IconData delete = FluentIcons.delete_24_regular;
  static const IconData cleaning = FluentIcons.delete_dismiss_24_regular;
  static const IconData libraryAdd = FluentIcons.add_square_multiple_24_regular;
  static const IconData playlistAdd =
      FluentIcons.text_bullet_list_add_24_regular;
  static const IconData playlistPlay = FluentIcons.music_note_2_play_20_regular;
  static const IconData queueMusic =
      FluentIcons.text_bullet_list_square_24_regular;
  static const IconData lyrics = FluentIcons.subtitles_24_regular;

  /// Lyrics turned off for a song.
  static const IconData lyricsOff = FluentIcons.closed_caption_off_24_regular;

  /// Lyrics without time marks (the note line above plain lyrics).
  static const IconData lyricsNote = FluentIcons.note_24_regular;
  static const IconData sleepTimer = FluentIcons.timer_24_regular;
  static const IconData sleepTimerActive = FluentIcons.timer_24_filled;

  /// "Stops at 23:40": the moon of the sleep timer's stop-time pill.
  static const IconData sleepAt = FluentIcons.weather_moon_24_regular;
  static const IconData volume = FluentIcons.speaker_2_24_regular;
  static const IconData volumeOff = FluentIcons.speaker_off_24_regular;
  static const IconData openFull = FluentIcons.arrow_maximize_24_regular;
  static const IconData heart = FluentIcons.heart_24_regular;
  static const IconData heartFilled = FluentIcons.heart_24_filled;
  static const IconData arrowUp = FluentIcons.arrow_up_24_regular;
  static const IconData arrowDown = FluentIcons.arrow_down_24_regular;
  static const IconData sidebarCover = FluentIcons.layout_column_two_24_regular;

  // Library.
  static const IconData grid = FluentIcons.grid_24_regular;
  static const IconData list = FluentIcons.text_bullet_list_ltr_24_regular;
  static const IconData tree = FluentIcons.text_bullet_list_tree_24_regular;
  static const IconData flatList = FluentIcons.text_bullet_list_24_regular;
  static const IconData filter = FluentIcons.filter_24_regular;
  static const IconData close = FluentIcons.dismiss_24_regular;
  static const IconData sortAsc = FluentIcons.arrow_sort_up_24_regular;
  static const IconData sortDesc = FluentIcons.arrow_sort_down_24_regular;

  /// "Nâng cao…" row of the sort dropdown.
  static const IconData sortAdvanced = FluentIcons.options_24_regular;
  static const IconData chevronRight = FluentIcons.chevron_right_24_regular;

  /// The previous-page chevron, the counterpart of [chevronRight].
  static const IconData chevronLeft = FluentIcons.chevron_left_24_regular;
  static const IconData folderOpen = FluentIcons.folder_open_24_regular;
  static const IconData folderOff = FluentIcons.folder_prohibited_24_regular;
  static const IconData folderAdd = FluentIcons.folder_add_24_regular;
  static const IconData theme = FluentIcons.color_24_regular;
  static const IconData language = FluentIcons.translate_24_regular;
  static const IconData multiSelect = FluentIcons.checkbox_checked_24_regular;
  static const IconData sdCard = FluentIcons.storage_24_regular;
  static const IconData help = FluentIcons.question_circle_24_regular;
  static const IconData openInNew = FluentIcons.open_24_regular;
  static const IconData select = FluentIcons.checkmark_circle_24_regular;
  static const IconData selectAll = FluentIcons.select_all_on_24_regular;
  static const IconData cancel = FluentIcons.dismiss_circle_24_regular;
  static const IconData edit = FluentIcons.edit_24_regular;
  static const IconData info = FluentIcons.info_24_regular;
  static const IconData copy = FluentIcons.copy_24_regular;
  static const IconData album = FluentIcons.album_24_regular;
  static const IconData check = FluentIcons.checkmark_24_regular;

  // First-run setup.
  static const IconData dragIndicator =
      FluentIcons.re_order_dots_vertical_24_regular;
  static const IconData add = FluentIcons.add_24_regular;
  static const IconData download = FluentIcons.arrow_download_24_regular;
  static const IconData remove = FluentIcons.subtract_24_regular;
  static const IconData arrowForward = FluentIcons.arrow_right_24_regular;
  static const IconData permission = FluentIcons.shield_keyhole_24_regular;
  static const IconData permissionMissing = FluentIcons.warning_24_regular;
  static const IconData image = FluentIcons.image_24_regular;
  static const IconData musicFile = FluentIcons.document_24_regular;
  static const IconData circleOutline = FluentIcons.circle_24_regular;

  // Theme choice (first run, settings).
  static const IconData themeSystem = FluentIcons.desktop_24_regular;
  static const IconData themeDark = FluentIcons.weather_moon_24_regular;
  static const IconData themeLight = FluentIcons.weather_sunny_24_regular;

  // Library sort criteria and menus.
  static const IconData duration = FluentIcons.hourglass_half_24_regular;
  static const IconData playCount = FluentIcons.headphones_24_regular;
  static const IconData dateAdded = FluentIcons.calendar_ltr_24_regular;
  static const IconData year = FluentIcons.calendar_24_regular;
  static const IconData count = FluentIcons.number_symbol_24_regular;
  static const IconData trackNumber =
      FluentIcons.text_number_list_ltr_24_regular;
  static const IconData albumArtist = FluentIcons.person_star_24_regular;
  static const IconData artistsMany = FluentIcons.people_24_regular;
  static const IconData deselect = FluentIcons.select_all_off_24_regular;
  static const IconData advanced = FluentIcons.wrench_24_regular;
  static const IconData hideFromLibrary = FluentIcons.eye_off_24_regular;

  // Playlists.
  static const IconData editList =
      FluentIcons.text_bullet_list_square_edit_24_regular;
  static const IconData playlistRemove = FluentIcons.subtract_circle_24_regular;
  static const IconData musicOff = FluentIcons.music_note_off_2_24_regular;
  static const IconData fileImport = FluentIcons.arrow_import_24_regular;
  static const IconData fileExport = FluentIcons.arrow_export_ltr_24_regular;
  static const IconData duplicate = FluentIcons.copy_add_24_regular;
  static const IconData removeDuplicates = FluentIcons.copy_select_24_regular;
  static const IconData heartOff = FluentIcons.heart_off_24_regular;
  static const IconData smartPlaylist =
      FluentIcons.text_bullet_list_square_sparkle_24_regular;
  static const IconData imageEdit = FluentIcons.image_edit_24_regular;
  static const IconData imageAdd = FluentIcons.image_add_24_regular;
  static const IconData pan = FluentIcons.hand_left_24_regular;
  static const IconData warning = FluentIcons.warning_24_regular;
  static const IconData dateModified = FluentIcons.calendar_edit_24_regular;
  static const IconData sortName = FluentIcons.text_sort_ascending_24_regular;
  static const IconData stats = FluentIcons.data_trending_24_regular;
  static const IconData linkOff = FluentIcons.link_dismiss_24_regular;

  // Settings rows (glyphs of mockups/_settings.js, named by meaning).
  static const IconData appearance = FluentIcons.paint_brush_24_regular;
  static const IconData integrations = FluentIcons.plug_connected_24_regular;
  static const IconData dataStorage = FluentIcons.database_24_regular;
  static const IconData proEdition = FluentIcons.diamond_24_regular;
  static const IconData pureBlack = FluentIcons.dark_theme_24_regular;
  static const IconData motion = FluentIcons.sparkle_24_regular;
  static const IconData font = FluentIcons.text_font_24_regular;
  static const IconData textSize = FluentIcons.text_font_size_24_regular;
  static const IconData seekBar = FluentIcons.data_bar_vertical_24_regular;
  static const IconData windowFrame = FluentIcons.window_24_regular;
  static const IconData gapless = FluentIcons.arrow_right_24_regular;
  static const IconData fadeIn = FluentIcons.speaker_2_24_regular;
  static const IconData fadeOut = FluentIcons.speaker_1_24_regular;
  static const IconData previousButton = FluentIcons.previous_24_regular;
  static const IconData crossfade = FluentIcons.arrow_swap_24_regular;
  static const IconData outputDevice = FluentIcons.headphones_24_regular;
  static const IconData replayGain = FluentIcons.options_24_regular;
  static const IconData preamp = FluentIcons.add_circle_24_regular;
  static const IconData clipping = FluentIcons.shield_24_regular;
  static const IconData license = FluentIcons.scales_24_regular;
  static const IconData openSourceLicenses = FluentIcons.book_open_24_regular;

  // Settings › Library scan rules.
  static const IconData skipShort = FluentIcons.timer_24_regular;
  static const IconData fileSize = FluentIcons.document_data_24_regular;
  static const IconData scanFormats = FluentIcons.filter_24_regular;
  static const IconData noMedia = FluentIcons.document_dismiss_24_regular;
  static const IconData watchFolders = FluentIcons.eye_24_regular;
}
