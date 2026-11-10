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
  String get playbackRepeatOff => 'Repeat: off';

  @override
  String get playbackRepeatAll => 'Repeat: all';

  @override
  String get playbackRepeatOne => 'Repeat: one track';

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
}
