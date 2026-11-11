// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navLibrary => 'Library';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get navSearch => 'Search';

  @override
  String get navOnline => 'Online';

  @override
  String get navSettings => 'Settings';

  @override
  String get emptyHome => 'Nothing here yet. Your music will show up here.';

  @override
  String get emptyLibrary => 'Your library is empty.';

  @override
  String get emptyPlaylists => 'No playlists yet.';

  @override
  String get emptySearch => 'Search your music.';

  @override
  String get emptyOnline => 'No online sources yet.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsNativeVersions => 'Native libraries';

  @override
  String get settingsNoSections => 'No other settings yet.';

  @override
  String get proBadge => 'Pro';

  @override
  String get tooltipToggleSidebar => 'Show or hide the sidebar';

  @override
  String get tooltipBack => 'Back';

  @override
  String get tooltipForward => 'Forward';

  @override
  String get tooltipHome => 'Home';

  @override
  String get appComingSoon => 'Coming soon';

  @override
  String get appKeymap => 'Keyboard shortcuts';

  @override
  String get appAiChat => 'AI chat';

  @override
  String get appSearch => 'Search';

  @override
  String get appRescan => 'Rescan library';

  @override
  String get scanSetupWelcomeTitle => 'Welcome to Kanaru';

  @override
  String get scanSetupWelcomeSubtitle =>
      'A few basics to set up. You can change them in Settings at any time.';

  @override
  String get scanSetupPermissionsTitle => 'Permissions';

  @override
  String get scanSetupPermissionAudioTitle => 'Music and audio';

  @override
  String get scanSetupPermissionAudioSubtitle =>
      'Find and play songs on the device, read .lrc lyrics';

  @override
  String get scanSetupPermissionImagesTitle => 'Photos and videos';

  @override
  String get scanSetupPermissionImagesSubtitle =>
      'Only to read cover art (cover.jpg) in music folders. Kanaru does not look at your photos or videos.';

  @override
  String get scanSetupPermissionAllowedLabel => 'Allowed';

  @override
  String get scanSetupPermissionMissingLabel => 'Not allowed';

  @override
  String get scanSetupPermissionsGranted =>
      'All permissions allowed · Music and audio · Photos and videos';

  @override
  String get scanSetupGrant => 'Allow';

  @override
  String get scanSetupGrantMissing => 'Allow the missing permission';

  @override
  String get scanSetupOpenAppSettings => 'Open app settings';

  @override
  String get scanSetupPermissionNote =>
      'Both are needed to continue. Kanaru does not ask for “All files access”.';

  @override
  String get scanSetupPermissionBlockedNote =>
      'Android will not ask again because the permission was denied several times. Turn on both permissions in Settings › Apps › Kanaru › Permissions, then come back here.';

  @override
  String get scanSetupAudioDenied =>
      'Music permission is needed to find songs on the device.';

  @override
  String get scanSetupImagesDenied =>
      'Photos permission is needed to read cover art in music folders.';

  @override
  String get scanSetupImagesLimited =>
      'Choosing only some photos cannot read cover.jpg: choose “Allow all”.';

  @override
  String get scanSetupAppearanceTitle => 'Appearance';

  @override
  String get scanSetupThemeLabel => 'Theme';

  @override
  String get scanSetupLanguageLabel => 'Language';

  @override
  String get scanSetupThemeSystem => 'Follow system';

  @override
  String get scanSetupThemeDark => 'Dark';

  @override
  String get scanSetupThemeLight => 'Light';

  @override
  String get scanSetupLanguageVietnamese => 'Tiếng Việt';

  @override
  String get scanSetupLanguageEnglish => 'English';

  @override
  String get scanSetupTabsTitle => 'Library tabs';

  @override
  String get scanSetupTabsHint =>
      'Turn on the tabs you want, drag to reorder. At least one tab stays on.';

  @override
  String scanSetupTabShow(String tab) {
    return 'Show the $tab tab';
  }

  @override
  String get scanSetupTabDrag => 'Drag to reorder';

  @override
  String get scanSetupTabLocked => 'At least one tab stays on';

  @override
  String get scanSetupFoldersTitle => 'Music folders';

  @override
  String get scanSetupFoldersHint =>
      'Kanaru scans these folders and everything inside them.';

  @override
  String scanSetupFoldersHintCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'Kanaru scans these folders · about $_temp0';
  }

  @override
  String get scanSetupFoldersNeedPermission =>
      'Allow music access to see the folders that have music.';

  @override
  String get scanSetupFoldersEmpty => 'No folder chosen yet.';

  @override
  String get scanSetupFoldersNoSystemMusic =>
      'Kanaru could not find the system Music folder. Add the folder that holds your music.';

  @override
  String get scanSetupAddFolder => 'Add folder';

  @override
  String get scanSetupAddFolderDialog => 'Add folder…';

  @override
  String get scanSetupFolderSuggested => 'Suggested';

  @override
  String scanSetupFolderRemove(String name) {
    return 'Remove $name';
  }

  @override
  String scanSetupFolderSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String get scanSetupFolderPickerTitle => 'Add music folders';

  @override
  String get scanSetupFolderPickerHint =>
      'Folders with music that Android found.';

  @override
  String get scanSetupFolderPickerEmpty =>
      'Every folder with music is already chosen.';

  @override
  String get scanSetupSheetAdd => 'Add';

  @override
  String scanSetupSheetAddCount(int count) {
    return 'Add $count';
  }

  @override
  String get scanSetupSheetCancel => 'Cancel';

  @override
  String get scanSetupExclusionsTitle => 'Excluded';

  @override
  String get scanSetupExclusionsHint =>
      'Skip these sub-folders when scanning (ringtones, recordings…).';

  @override
  String get scanSetupExclusionsEmpty => 'No folder excluded.';

  @override
  String get scanSetupAddExclusion => 'Add excluded folder';

  @override
  String get scanSetupAddExclusionDialog => 'Add excluded folder…';

  @override
  String get scanSetupExclusionPickerTitle => 'Exclude folders';

  @override
  String get scanSetupExclusionPickerHint =>
      'Sub-folders of the music folders you chose.';

  @override
  String get scanSetupExclusionPickerEmpty =>
      'There are no sub-folders to exclude.';

  @override
  String scanSetupRefusedAlreadyChosen(String folder) {
    return '“$folder” is already chosen.';
  }

  @override
  String scanSetupRefusedInside(String folder, String root) {
    return '“$folder” is already inside “$root”.';
  }

  @override
  String scanSetupRefusedContains(String folder, String root) {
    return '“$folder” contains “$root”, which is already chosen.';
  }

  @override
  String scanSetupRefusedTooBroad(String folder) {
    return '“$folder” is too broad to scan.';
  }

  @override
  String scanSetupRefusedNotFolder(String folder) {
    return '“$folder” is not a folder.';
  }

  @override
  String scanSetupRefusedOutside(String folder) {
    return '“$folder” is not inside a music folder.';
  }

  @override
  String scanSetupRefusedAlreadyExcluded(String folder) {
    return '“$folder” is already excluded.';
  }

  @override
  String get scanSetupWriteFailed => 'Could not save that change. Try again.';

  @override
  String get scanSetupNext => 'Continue';

  @override
  String get scanSetupNextDisabled => 'Add at least one music folder';

  @override
  String get scanSetupLoadFailed => 'Could not load this section.';

  @override
  String get scanSetupRetry => 'Try again';

  @override
  String get scanVolumeInternal => 'Internal storage';

  @override
  String get scanVolumeSdCard => 'SD card';

  @override
  String get scanVolumeUsb => 'USB drive';

  @override
  String get scanHomeScanning => 'Scanning the library';

  @override
  String scanHomeProgress(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Reading tags and covers · $doneString / $totalString songs';
  }

  @override
  String scanHomeAdded(int added) {
    final intl.NumberFormat addedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String addedString = addedNumberFormat.format(added);

    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: 'Added $addedString songs',
      one: 'Added 1 song',
    );
    return '$_temp0';
  }

  @override
  String scanHomeAddedDetail(int albums, int artists) {
    final intl.NumberFormat albumsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String albumsString = albumsNumberFormat.format(albums);
    final intl.NumberFormat artistsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String artistsString = artistsNumberFormat.format(artists);

    String _temp0 = intl.Intl.pluralLogic(
      albums,
      locale: localeName,
      other: '$albumsString albums',
      one: '1 album',
    );
    String _temp1 = intl.Intl.pluralLogic(
      artists,
      locale: localeName,
      other: '$artistsString artists',
      one: '1 artist',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get scanHomeNoTracks => 'No songs found';

  @override
  String get playbackCover => 'Cover art';

  @override
  String get playbackNavQueue => 'Queue';

  @override
  String get playbackPlay => 'Play';

  @override
  String get playbackPause => 'Pause';

  @override
  String get playbackNext => 'Next';

  @override
  String get playbackPrevious => 'Previous';

  @override
  String get playbackShuffle => 'Shuffle';

  @override
  String get playbackRepeatOff => 'Stop at the end';

  @override
  String get playbackRepeatOne => 'Repeat this song';

  @override
  String playbackRepeatTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Repeat this song $count more times',
      one: 'Repeat this song 1 more time',
    );
    return '$_temp0';
  }

  @override
  String get playbackRepeatAll => 'Repeat the whole queue';

  @override
  String get playbackRepeatAllShuffled =>
      'Repeat the whole queue, reshuffled every pass';

  @override
  String get playbackRepeatFewer => 'One time fewer';

  @override
  String get playbackRepeatMore => 'One time more';

  @override
  String get playbackFavoriteAdd => 'Add to favorites';

  @override
  String get playbackFavoriteRemove => 'Remove from favorites';

  @override
  String get playbackSleepTimer => 'Sleep timer';

  @override
  String get playbackLyrics => 'Lyrics';

  @override
  String get playbackVolume => 'Volume';

  @override
  String get playbackMute => 'Mute';

  @override
  String get playbackUnmute => 'Unmute';

  @override
  String get playbackExpand => 'Open Now Playing';

  @override
  String get playbackOpenNowPlaying => 'Open Now Playing';

  @override
  String get playbackPlayer => 'Player';

  @override
  String get playbackSeek => 'Playback position';

  @override
  String playbackPositionValue(String position, String duration) {
    return '$position of $duration';
  }

  @override
  String playbackNoticeSkipped(String title) {
    return 'Skipped “$title”: file is gone';
  }

  @override
  String playbackNoticeSkippedMany(String title, String others) {
    return 'Skipped “$title” and $others more: files are gone';
  }

  @override
  String playbackNoticeFailed(String title) {
    return 'Could not play “$title”';
  }

  @override
  String get playbackNoticeFirstTrack => 'This is the first track';

  @override
  String get playbackNoticeQueueEnd => 'End of the queue';

  @override
  String get playbackNoticeQueueEmpty => 'The queue is empty';

  @override
  String get playbackNoticeFocusDenied =>
      'Could not play: another app is using the audio';

  @override
  String get playbackSidebarOpen => 'Menu';

  @override
  String get playbackSidebarClose => 'Close menu';

  @override
  String playbackQueueMobileCounts(int position, int total, String remaining) {
    return '$position/$total · $remaining left';
  }

  @override
  String playbackRemainingHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String playbackRemainingMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get playbackRemainingUnderMinute => 'under 1 min';

  @override
  String get playbackMore => 'More';

  @override
  String get playbackMinimize => 'Minimise';

  @override
  String get playbackQueueSelectMany => 'Select several';

  @override
  String get playbackQueueAddTracks => 'Add tracks';

  @override
  String get playbackQueueCleanup => 'Clean up';

  @override
  String get playbackQueueSavePlaylist => 'Save as playlist';

  @override
  String get playbackQueueCleanupTitle => 'Remove from queue';

  @override
  String get playbackCleanupDuplicates => 'Duplicate tracks';

  @override
  String get playbackCleanupBefore => 'Earlier tracks';

  @override
  String get playbackCleanupAfter => 'Later tracks';

  @override
  String get playbackCleanupAll => 'All except the current track';

  @override
  String get playbackQueueLocate => 'Go to current track';

  @override
  String get playbackQueueReorder => 'Drag to reorder';

  @override
  String playbackQueueRemovedOne(String title) {
    return 'Removed “$title”';
  }

  @override
  String playbackQueueRemovedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removed $count tracks',
      one: 'Removed 1 track',
    );
    return '$_temp0';
  }

  @override
  String get playbackUndo => 'Undo';

  @override
  String get playbackRowPlay => 'Play this track';

  @override
  String get playbackRowPlayNext => 'Play next';

  @override
  String get playbackGoAlbum => 'Go to album';

  @override
  String get playbackGoArtist => 'Go to artist';

  @override
  String get playbackAskAi => 'Ask AI';

  @override
  String get playbackRemoveFromQueue => 'Remove from queue';

  @override
  String get playbackQueueStale => 'That track is no longer in the queue';

  @override
  String get playbackPickArtist => 'Choose an artist';

  @override
  String get playbackSourceSongs => 'Songs';

  @override
  String get playbackSourceAlbum => 'Album';

  @override
  String get playbackSourceArtist => 'Artist';

  @override
  String get playbackSourceGenre => 'Genre';

  @override
  String get playbackSourceLanguage => 'Language';

  @override
  String get playbackSourceFolder => 'Folder';

  @override
  String get playbackSourceFavorites => 'Favorites';

  @override
  String get playbackSourceSelection => 'Selection';

  @override
  String get playbackSourceQueue => 'Queue';

  @override
  String get playbackLyricsCard => 'Lyrics';

  @override
  String get playbackAddToPlaylist => 'Add to playlist';

  @override
  String get playbackLyricsSource => 'Lyrics source';

  @override
  String get playbackTranslateLyrics => 'Translate lyrics…';

  @override
  String get playbackVisualEffects => 'Visual effects';

  @override
  String get playbackTrackInfo => 'Track info';

  @override
  String playbackInfoPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays',
      one: '1 play',
    );
    return '$_temp0';
  }

  @override
  String playbackInfoSampleRate(String khz) {
    return '$khz kHz';
  }

  @override
  String playbackInfoBitrate(int kbps) {
    return '$kbps kbps';
  }

  @override
  String get playbackToggleCoverColumn => 'Show or hide the cover column';

  @override
  String get playbackTranslate => 'Translate';

  @override
  String get playbackTabLyrics => 'Lyrics';

  @override
  String get playbackLyricsTabSoon => 'Lyrics: coming soon';

  @override
  String get playbackPanelClose => 'Close panel';

  @override
  String playbackQueuePanelCounts(int total, String remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total tracks',
      one: '1 track',
    );
    return '$_temp0 · $remaining left';
  }

  @override
  String playbackQueuePanelShort(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String playbackQueuePlayingAt(int position) {
    return 'Playing track $position';
  }

  @override
  String get playbackQueueEmpty => 'The queue is empty';

  @override
  String get libraryTabSongs => 'Songs';

  @override
  String get libraryTabAlbums => 'Albums';

  @override
  String get libraryTabArtists => 'Artists';

  @override
  String get libraryTabGenres => 'Genres';

  @override
  String get libraryTabLanguages => 'Languages';

  @override
  String get libraryTabFolders => 'Folders';

  @override
  String get libraryNavFavorites => 'Favorites';

  @override
  String get libraryNavHistory => 'History';

  @override
  String get libraryNavMostPlayed => 'Most played';

  @override
  String librarySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String libraryAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
    );
    return '$_temp0';
  }

  @override
  String libraryArtistCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artists',
      one: '1 artist',
    );
    return '$_temp0';
  }

  @override
  String libraryGenreCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count genres',
      one: '1 genre',
    );
    return '$_temp0';
  }

  @override
  String libraryLanguageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count languages',
      one: '1 language',
    );
    return '$_temp0';
  }

  @override
  String libraryFolderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count folders',
      one: '1 folder',
    );
    return '$_temp0';
  }

  @override
  String libraryCountOf(int shown, int total, String unit) {
    return '$shown / $total $unit';
  }

  @override
  String get libraryUnitSongs => 'songs';

  @override
  String get libraryUnitAlbums => 'albums';

  @override
  String get libraryUnitArtists => 'artists';

  @override
  String get libraryUnitGenres => 'genres';

  @override
  String get libraryUnitLanguages => 'languages';

  @override
  String get libraryUnitFolders => 'folders';

  @override
  String get libraryPlayAll => 'Play all';

  @override
  String get libraryShuffle => 'Shuffle';

  @override
  String get libraryPlayAlbum => 'Play album';

  @override
  String get libraryPlayArtist => 'Play all songs';

  @override
  String get libraryFilter => 'Filter';

  @override
  String get libraryFilterClose => 'Close filter';

  @override
  String get libraryFilterSongsHint => 'Filter songs';

  @override
  String get libraryFilterAlbumsHint => 'Filter albums';

  @override
  String get libraryFilterArtistsHint => 'Filter artists';

  @override
  String get libraryFilterGenresHint => 'Filter genres';

  @override
  String get libraryFilterLanguagesHint => 'Filter languages';

  @override
  String get libraryFilterFoldersHint => 'Filter in this folder';

  @override
  String get libraryOrderTooltip => 'Sort';

  @override
  String get libraryOrderAscText => 'A → Z';

  @override
  String get libraryOrderDescText => 'Z → A';

  @override
  String get libraryOrderAscNumber => 'Ascending';

  @override
  String get libraryOrderDescNumber => 'Descending';

  @override
  String get librarySortTitle => 'Name';

  @override
  String get librarySortArtist => 'Artist';

  @override
  String get librarySortAlbum => 'Album';

  @override
  String get librarySortYear => 'Year';

  @override
  String get librarySortDateAdded => 'Date added';

  @override
  String get librarySortPlayCount => 'Play count';

  @override
  String get librarySortDuration => 'Duration';

  @override
  String get librarySortTrackCount => 'Songs';

  @override
  String get librarySortAlbumCount => 'Albums';

  @override
  String get librarySortTrackNumber => 'Track number';

  @override
  String get libraryViewGrid => 'Grid';

  @override
  String get libraryViewList => 'List';

  @override
  String get libraryViewTree => 'Folder tree';

  @override
  String get libraryViewFlat => 'Flat list';

  @override
  String get libraryScanning => 'Scanning…';

  @override
  String libraryScanningTags(int done, int total) {
    return 'Scanning · $done / $total songs';
  }

  @override
  String libraryScanningTagsCount(int done) {
    return 'Scanning · $done songs';
  }

  @override
  String libraryScanningCovers(int done, int total) {
    return 'Fetching covers · $done / $total';
  }

  @override
  String get libraryScanningCoversStart => 'Fetching covers…';

  @override
  String get libraryEmptyTitle => 'Library is empty';

  @override
  String get libraryEmptyMessage => 'No songs in the chosen folders.';

  @override
  String get libraryChooseFolders => 'Choose music folders';

  @override
  String get libraryPlayFailed => 'Could not start playback';

  @override
  String get libraryLoadFailed => 'Could not load the list';

  @override
  String get libraryNowPlaying => 'Now playing';

  @override
  String get libraryFavoriteAdd => 'Add to favorites';

  @override
  String get libraryFavoriteRemove => 'Remove from favorites';

  @override
  String get libraryFavoriteFailed => 'Could not change favorites';

  @override
  String libraryDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String libraryDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String get librarySelectionGone =>
      'The selected songs are no longer in the library';

  @override
  String libraryDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String libraryAlbumStats(int songs, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      songs,
      locale: localeName,
      other: '$songs songs',
      one: '1 song',
    );
    return '$_temp0 • $minutes min';
  }

  @override
  String get libraryLanguageUnknown => 'Unknown';

  @override
  String libraryLanguageStatsDetected(int songs, int detected) {
    String _temp0 = intl.Intl.pluralLogic(
      songs,
      locale: localeName,
      other: '$songs songs',
      one: '1 song',
    );
    return '$_temp0 · $detected auto-detected';
  }

  @override
  String get libraryLanguagesNote =>
      'From the language tag of each song; songs without a tag are detected by Kanaru. Change this in Settings › Library.';

  @override
  String get libraryFoldersAll => 'All folders';

  @override
  String get libraryFoldersHidden => 'Hidden levels';

  @override
  String get libraryGoToFolder => 'Go to folder';

  @override
  String get libraryVolumeInternal => 'Internal storage';

  @override
  String get libraryVolumeSdCard => 'SD card';

  @override
  String get libraryVolumeUsb => 'USB drive';

  @override
  String libraryFolderCounts(int songs, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      songs,
      locale: localeName,
      other: '$songs songs',
      one: '1 song',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders folders',
      one: '1 folder',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String libraryFolderSongsHeader(int count) {
    return 'Songs in this folder · $count';
  }

  @override
  String libraryFlatSongsHeader(int count) {
    return '$count songs in this folder (not including subfolders)';
  }

  @override
  String get libraryRetry => 'Retry';

  @override
  String get libraryPermissionMissing => 'Missing permission to read music';

  @override
  String get libraryGrantPermission => 'Grant';

  @override
  String get libraryNotFoundTitle => 'Not found';

  @override
  String get libraryNotFoundMessage => 'This is no longer in your library.';

  @override
  String get libraryPlay => 'Play';

  @override
  String get libraryAppearsIn => 'Appears on';

  @override
  String libraryAlbumsOf(String name) {
    return 'Albums · $name';
  }

  @override
  String libraryArtistsOf(String name) {
    return 'Artists · $name';
  }

  @override
  String libraryAppearsInOf(String name) {
    return 'Appears on · $name';
  }

  @override
  String libraryDetectedCount(int count) {
    return '$count auto-detected';
  }

  @override
  String get libraryAutoDetectedTag => 'auto-detected';

  @override
  String get libraryLanguageDetectedNote =>
      'Songs labelled “auto-detected” have no language tag; Kanaru guesses it from the title and lyrics.';

  @override
  String get libraryLanguageUnknownNote =>
      'These songs have no language tag and Kanaru could not detect one (often instrumentals). Add a language tag in Edit info, or change how languages are detected in Settings › Library.';

  @override
  String get libraryMenuGoAlbum => 'Go to album';

  @override
  String get libraryMenuGoArtist => 'Go to artist';

  @override
  String get libraryMenuGoAlbumArtist => 'Go to album artist';

  @override
  String get libraryMenuGoGenre => 'Go to genre';

  @override
  String get libraryMenuGoLanguage => 'Go to language';

  @override
  String get libraryMenuGoFolder => 'Go to folder';

  @override
  String get libraryMenuReveal => 'Show in file manager';

  @override
  String get libraryMenuNoAlbum => 'No album';

  @override
  String get libraryMenuNoArtist => 'No artist';

  @override
  String libraryMenuAppearsCount(int count) {
    return 'appears on $count';
  }

  @override
  String libraryMenuSongsInFolders(int songs, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      songs,
      locale: localeName,
      other: '$songs songs',
      one: '1 song',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders folders',
      one: '1 folder',
    );
    return '$_temp0 in $_temp1';
  }

  @override
  String libraryMenuFoldersOf(String name) {
    return 'Folders · $name';
  }

  @override
  String libraryMenuFoldersIntroAlbum(int count) {
    return 'This album\'s songs are stored in $count folders. Pick one to open it in Folders.';
  }

  @override
  String libraryMenuFoldersIntroArtist(int count) {
    return 'This artist\'s songs are stored in $count folders. Pick one to open it in Folders.';
  }

  @override
  String libraryMenuFoldersIntroGenre(int count) {
    return 'The songs of this genre are stored in $count folders. Pick one to open it in Folders.';
  }

  @override
  String libraryMenuFoldersIntroLanguage(int count) {
    return 'The songs of this language are stored in $count folders. Pick one to open it in Folders.';
  }

  @override
  String get libraryMenuAddToPlaylist => 'Add to playlist…';

  @override
  String get libraryMenuFavoriteAll => 'Add all to favorites';

  @override
  String get libraryMenuEditSong => 'Edit song info';

  @override
  String get libraryMenuEditAlbum => 'Edit album info';

  @override
  String get libraryMenuSelect => 'Select';

  @override
  String get libraryMenuDeselect => 'Deselect';

  @override
  String get libraryMenuAskAiSong => 'Ask AI about this song';

  @override
  String get libraryMenuAskAiAlbum => 'Ask AI about this album';

  @override
  String get libraryMenuAskAiArtist => 'Ask AI about this artist';

  @override
  String get libraryMenuAskAiSongs => 'Ask AI about these songs';

  @override
  String get libraryMenuAdvanced => 'Advanced';

  @override
  String get libraryMenuFindLyrics => 'Find lyrics online…';

  @override
  String get libraryMenuHide => 'Remove from library';

  @override
  String get libraryMenuHideNote =>
      'Keeps the files; undo in Settings › Library';

  @override
  String get libraryMenuDeleteFiles => 'Delete files from device';

  @override
  String get libraryMenuMoveToTrash => 'Move files to Trash';

  @override
  String libraryMenuFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get libraryMenuSplitArtists => 'Split or merge artists';

  @override
  String get libraryMenuSplitArtistsNote =>
      'Treat one name as two artists, or merge spellings';

  @override
  String get libraryMenuSplitGenres => 'Split or merge genres';

  @override
  String get libraryMenuSplitGenresNote =>
      'Split a combined genre tag, or merge spellings';

  @override
  String get libraryMenuLanguageDetection => 'How languages are detected';

  @override
  String get libraryMenuLanguageDetectionNote => 'Settings › Library';

  @override
  String get libraryMenuCopyPath => 'Copy path';

  @override
  String get libraryMenuExclude => 'Exclude from library';

  @override
  String get libraryMenuExcludeNote =>
      'Keeps the files; undo in Settings › Library › Folders';

  @override
  String get libraryMenuIncludesSubfolders => 'Includes subfolders';

  @override
  String get libraryMenuPlayDirect => 'Play only songs in this folder';

  @override
  String libraryMenuPlayDirectNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0, without subfolders';
  }

  @override
  String libraryMenuSelectionTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs selected',
      one: '1 song selected',
    );
    return '$_temp0';
  }

  @override
  String get libraryMenuMore => 'More options';

  @override
  String get libraryMenuBack => 'Back';

  @override
  String get libraryMenuPlayNext => 'Play next';

  @override
  String get libraryMenuAddToQueue => 'Add to queue';

  @override
  String get libraryMenuPlayingNext => 'Playing next';

  @override
  String get libraryMenuQueued => 'Added to queue';

  @override
  String get libraryMenuQueueFailed => 'Could not change the queue';

  @override
  String libraryMenuExcluded(String name) {
    return 'Excluded “$name” from the library';
  }

  @override
  String get libraryMenuUndo => 'Undo';

  @override
  String get libraryMenuExcludeFailed => 'Could not exclude the folder';

  @override
  String get libraryMenuUndoFailed => 'Could not undo';

  @override
  String get libraryMenuPathCopied => 'Path copied';

  @override
  String get libraryMenuRevealFailed => 'Could not open the file manager';

  @override
  String get libraryMenuLoadFailed => 'Could not open the menu';

  @override
  String get libraryMenuSongInfo => 'Song info';

  @override
  String get libraryInfoFormat => 'Format';

  @override
  String get libraryInfoBitrate => 'Bitrate';

  @override
  String libraryInfoBitrateValue(int kbps) {
    return '$kbps kbps';
  }

  @override
  String get libraryInfoSampleRate => 'Sample rate';

  @override
  String libraryInfoSampleRateValue(String khz) {
    return '$khz kHz';
  }

  @override
  String get libraryInfoBitDepth => 'Bit depth';

  @override
  String libraryInfoBitDepthValue(int bits) {
    return '$bits-bit';
  }

  @override
  String get libraryInfoSize => 'Size';

  @override
  String get libraryInfoPath => 'File';

  @override
  String get libraryInfoPlayCount => 'Plays';

  @override
  String get libraryInfoUnknown => 'Unknown';

  @override
  String get libraryPanelLabel => 'Selected songs';

  @override
  String get libraryPanelClear => 'Clear selection';

  @override
  String get libraryPanelPlayAll => 'Play all selected';

  @override
  String get libraryPanelEdit => 'Edit info';

  @override
  String get libraryPanelAddToPlaylist => 'Add to playlist…';

  @override
  String get libraryPanelMore => 'Options for the selection';

  @override
  String get libraryPanelSelectAll => 'Select all songs on this screen';

  @override
  String get libraryPanelExpand => 'Show the selected songs';

  @override
  String get libraryPanelCollapse => 'Collapse';

  @override
  String get libraryPanelReorder => 'Drag to change the play order';

  @override
  String get libraryMenuCopyFailed => 'Could not copy';
}
