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
  String get scanSetupPermissionsGranted => 'All permissions allowed';

  @override
  String get scanSetupPermissionsGrantedDesc =>
      'Music and audio · Photos and videos';

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
      'Folders with music that Android found. Music you just copied to the phone may not be here until Android rescans.';

  @override
  String get scanSetupFolderPickerEmpty =>
      'Every folder with music is already chosen.';

  @override
  String get scanSetupFolderSheetLoading => 'Looking for folders with music…';

  @override
  String get scanSetupNoMusicTitle => 'Android sees no music yet';

  @override
  String get scanSetupNoMusicBody =>
      'Music you just copied to the phone often does not show up until Android rescans.';

  @override
  String get scanSetupNoMusicCard =>
      'Android sees no music on this phone yet. Music you just copied often does not show up until Android rescans.';

  @override
  String get scanSetupRescan => 'Rescan';

  @override
  String get scanSetupRescanRow => 'Can\'t see your folder? Rescan';

  @override
  String get scanSetupRescanning => 'Rescanning…';

  @override
  String get scanSetupRescanningBody =>
      'Android is looking for music in the folders of internal storage and the SD card (Music and Download first).';

  @override
  String get scanSetupRescanningSheetNote =>
      'If you close this sheet, Android keeps scanning.';

  @override
  String scanSetupRescanDone(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rescanned · Android found $countString songs.',
      one: 'Rescanned · Android found 1 song.',
    );
    return '$_temp0';
  }

  @override
  String get scanSetupStillNoMusicTitle => 'Still no music found';

  @override
  String get scanSetupStillNoMusicBody =>
      'Android rescanned but found no music files.';

  @override
  String get scanSetupStillNoMusicTipShared =>
      'Music must be in shared storage (for example Music or Download), not inside another app\'s Android › data folder.';

  @override
  String get scanSetupStillNoMusicTipRestart =>
      'Restart the phone so Android rescans all storage, then reopen Kanaru.';

  @override
  String get scanSetupStillNoMusicCard => 'Android still sees no music.';

  @override
  String get scanSetupRescanFailed => 'Could not rescan.';

  @override
  String get scanSetupFolderListFailedTitle => 'Could not load the folder list';

  @override
  String get scanSetupFolderListFailedBody =>
      'Android did not answer in time or reported an error.';

  @override
  String get scanSetupExclusionSheetLoading => 'Looking for sub-folders…';

  @override
  String get scanSetupExclusionListFailed =>
      'Could not load the sub-folder list';

  @override
  String get scanSetupSheetAdd => 'Add';

  @override
  String scanSetupSheetAddCount(int count) {
    return 'Add $count';
  }

  @override
  String get scanSetupSheetCancel => 'Cancel';

  @override
  String get scanSetupSheetSelectAll => 'Select all';

  @override
  String scanSetupSheetSelectedCount(int count, int total) {
    return '$count / $total folders';
  }

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
      'Sub-folders with music that Android has seen, inside the music folders you chose.';

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
  String get scanHomeChangeFolders => 'Change folders';

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
  String get playbackStopAndClear => 'Stop playback';

  @override
  String get playbackStoppedAnnouncement => 'Playback stopped';

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
  String get playbackNowPlaying => 'Now playing';

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
  String get libraryShelfSeeAll => 'See all';

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
  String get libraryPlayAll => 'Play';

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
  String get librarySortDialogTitle => 'Sort by';

  @override
  String get librarySortChosen => 'Chosen';

  @override
  String get librarySortNotChosen => 'Not chosen';

  @override
  String get librarySortReset => 'Reset';

  @override
  String get librarySortDone => 'Done';

  @override
  String get libraryOrderReverse => 'Reverse order';

  @override
  String librarySortDragHint(String label) {
    return 'Drag to reorder $label';
  }

  @override
  String librarySortFlipTooltip(String word) {
    return 'Switch direction: $word';
  }

  @override
  String librarySortFlipSemantics(String label, String word) {
    return '$label: $word, tap to switch direction';
  }

  @override
  String librarySortRemove(String label) {
    return 'Remove $label';
  }

  @override
  String librarySortAdd(String label) {
    return 'Add $label';
  }

  @override
  String get libraryOrderOldFirst => 'Oldest first';

  @override
  String get libraryOrderNewFirst => 'Newest first';

  @override
  String get libraryOrderFirstToLast => 'First → last';

  @override
  String get libraryOrderLastToFirst => 'Last → first';

  @override
  String librarySortMore(String label, int count) {
    return '$label +$count';
  }

  @override
  String get librarySortAdvanced => 'Advanced…';

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
  String get librarySortName => 'Name';

  @override
  String get librarySortDateModified => 'Date modified';

  @override
  String get librarySortPlaylistOrder => 'Playlist order';

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
  String get libraryNothingToPlay => 'Nothing to play';

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
  String get libraryFavoriteLabel => 'Favorite';

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
  String libraryAppearsInAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
    );
    return 'Appears on $_temp0';
  }

  @override
  String get libraryLanguageNoTag => 'No language tag';

  @override
  String get libraryShowMore => 'Show more';

  @override
  String get libraryShowLess => 'Show less';

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
      'Keeps the files; undo in Settings › Library › Exclusions';

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

  @override
  String get libraryActionFailed => 'Couldn\'t complete the action';

  @override
  String get playlistFavoritesName => 'Favorites';

  @override
  String get playlistDefaultName => 'New playlist';

  @override
  String playlistCopyName(String name) {
    return '$name (copy)';
  }

  @override
  String playlistFavoritesCopyName(String date) {
    return 'Favorites ($date)';
  }

  @override
  String get playlistYours => 'Your playlists';

  @override
  String playlistCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count playlists',
      one: '1 playlist',
    );
    return '$_temp0';
  }

  @override
  String playlistTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
      zero: 'No songs',
    );
    return '$_temp0';
  }

  @override
  String playlistEditedOn(String date) {
    return 'Edited $date';
  }

  @override
  String get playlistFilterHint => 'Filter playlists';

  @override
  String get playlistFilterNoMatch => 'No playlists match.';

  @override
  String get playlistsEmptyTitle => 'No playlists yet';

  @override
  String get playlistsEmptyMessage =>
      'Create a playlist to keep songs in your own order, or import an M3U file.';

  @override
  String get playlistCreateAction => 'Create playlist';

  @override
  String get playlistImportM3uAction => 'Import M3U file…';

  @override
  String get playlistHubStats => 'Stats';

  @override
  String get playlistFabOpen => 'Create';

  @override
  String get playlistFabClose => 'Close';

  @override
  String get playlistFabNew => 'New playlist';

  @override
  String get playlistFabImport => 'Import M3U file';

  @override
  String get playlistFabSmart => 'Smart playlist';

  @override
  String get playlistFilterSongsNoMatch => 'No songs match.';

  @override
  String get playlistDragHandle => 'Drag to reorder';

  @override
  String get playlistNotInLibrary => 'Not in library';

  @override
  String playlistUnavailableNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs are',
      one: '1 song is',
    );
    return '$_temp0 not in your library: dimmed and skipped when playing.';
  }

  @override
  String playlistRemoveUnavailableAction(int count) {
    return 'Remove $count';
  }

  @override
  String get playlistEmptyTitle => 'This playlist is empty';

  @override
  String get playlistEmptyMessage =>
      'Add songs from the menu of any song, album or artist (Add to playlist…), or select several songs and add them at once.';

  @override
  String get playlistFavoritesEmptyTitle => 'No favorites yet';

  @override
  String get playlistFavoritesEmptyMessage =>
      'Tap [icon] on a song to add it here.';

  @override
  String get playlistFavoritesEmptyIconLabel => 'favorite';

  @override
  String get playlistNotFoundTitle => 'Playlist not found';

  @override
  String get playlistNotFoundMessage => 'It may have been deleted.';

  @override
  String get playlistSaveFailed => 'Couldn\'t save the playlist';

  @override
  String get playlistMenuGoTo => 'Go to playlist';

  @override
  String get playlistMenuGoToFavorites => 'Go to Favorites';

  @override
  String get playlistMenuCopyTo => 'Add to playlist…';

  @override
  String playlistMenuCopyToHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'Copy $_temp0 to another playlist.';
  }

  @override
  String get playlistMenuAskAi => 'Ask AI about this playlist';

  @override
  String get playlistMenuEdit => 'Edit playlist';

  @override
  String get playlistMenuEditHint => 'Change the name, description and cover.';

  @override
  String get playlistMenuChangeCover => 'Change playlist image';

  @override
  String get playlistMenuDelete => 'Delete playlist';

  @override
  String get playlistMenuDeleteHint => 'Music files stay';

  @override
  String get playlistMenuDuplicate => 'Duplicate playlist';

  @override
  String get playlistMenuExportM3u => 'Export M3U file…';

  @override
  String get playlistMenuExportM3uHint => 'Absolute paths';

  @override
  String get playlistMenuExportM3uRelative => 'Export M3U, relative paths…';

  @override
  String get playlistMenuExportM3uRelativeHint =>
      'Keep the .m3u8 file next to the music folder: copy the whole folder to another device and it still opens.';

  @override
  String get playlistMenuRemoveDuplicates => 'Remove duplicates';

  @override
  String playlistMenuRemoveDuplicatesHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repeated songs',
      one: '1 repeated song',
    );
    return '$_temp0 · keep the first';
  }

  @override
  String get playlistMenuRemoveUnavailable => 'Remove missing songs';

  @override
  String playlistMenuRemoveUnavailableHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0 not in your library';
  }

  @override
  String get playlistMenuSaveAs => 'Save as playlist';

  @override
  String get playlistMenuClearFavorites => 'Remove all from Favorites';

  @override
  String playlistMenuClearFavoritesHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0 · music files stay';
  }

  @override
  String get playlistMenuMoveUp => 'Move up';

  @override
  String get playlistMenuMoveDown => 'Move down';

  @override
  String get playlistMenuRemoveEntry => 'Remove from playlist';

  @override
  String get playlistMenuRemoveFavorite => 'Remove from Favorites';

  @override
  String playlistRemovedEntry(String title) {
    return 'Removed “$title”';
  }

  @override
  String playlistRemovedFavorite(String title) {
    return 'Removed “$title” from Favorites';
  }

  @override
  String playlistRemovedEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'Removed $_temp0';
  }

  @override
  String playlistRemovedDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicates',
      one: '1 duplicate',
    );
    return 'Removed $_temp0';
  }

  @override
  String playlistRemovedUnavailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missing songs',
      one: '1 missing song',
    );
    return 'Removed $_temp0';
  }

  @override
  String get playlistClearedFavorites => 'Removed everything from Favorites';

  @override
  String get playlistSaved => 'Playlist saved';

  @override
  String playlistCreated(String name) {
    return 'Created $name';
  }

  @override
  String playlistDuplicated(String name) {
    return 'Created “$name”';
  }

  @override
  String playlistFavoritedAll(int added, int skipped) {
    return 'Added $added to Favorites, skipped $skipped';
  }

  @override
  String get playlistCreateTitle => 'New playlist';

  @override
  String get playlistCreateConfirm => 'Create';

  @override
  String get playlistEditTitle => 'Edit playlist';

  @override
  String get playlistNameLabel => 'Name';

  @override
  String get playlistDescriptionLabel => 'Description';

  @override
  String get playlistDescriptionHint => 'Add a description (optional)';

  @override
  String get playlistNameEmpty => 'Name can\'t be empty';

  @override
  String get playlistNameTooLong => 'Too long';

  @override
  String get playlistDescriptionTooLong => 'Too long';

  @override
  String get playlistCoverChoose => 'Change cover…';

  @override
  String get playlistCoverAuto => 'Automatic cover';

  @override
  String get playlistCoverUsingAuto => 'Using the automatic cover';

  @override
  String get playlistCoverAutoHint =>
      'The automatic cover combines the covers of the first 4 albums in the playlist.';

  @override
  String playlistDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String playlistDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'The playlist has $_temp0. The songs stay in your library.';
  }

  @override
  String get playlistDeleteConfirm => 'Delete';

  @override
  String get playlistClearFavoritesTitle => 'Remove all from Favorites?';

  @override
  String playlistClearFavoritesBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs leave',
      one: '1 song leaves',
    );
    return '$_temp0 Favorites. The songs stay in your library.';
  }

  @override
  String get playlistClearFavoritesConfirm => 'Remove all';

  @override
  String get playlistCancel => 'Cancel';

  @override
  String get playlistSave => 'Save';

  @override
  String get playlistClose => 'Close';

  @override
  String get playlistConfirm => 'Confirm';

  @override
  String get playlistPickerTitle => 'Add to playlist';

  @override
  String playlistPickerSubtitle(int songs, String source) {
    String _temp0 = intl.Intl.pluralLogic(
      songs,
      locale: localeName,
      other: '$songs songs',
      one: '1 song',
    );
    return '$_temp0 · $source';
  }

  @override
  String playlistPickerFrom(String name) {
    return 'from $name';
  }

  @override
  String playlistPickerSelectedSongs(int count) {
    return '$count selected songs';
  }

  @override
  String get playlistPickerFavoritesHint => 'Songs already there are skipped.';

  @override
  String get playlistPickerNew => 'New playlist…';

  @override
  String get playlistPickerNewConfirm => 'Add to list';

  @override
  String get playlistPickerNewBadge => 'New';

  @override
  String get playlistPickerNewHint => 'Created when you press Add';

  @override
  String get playlistPickerHasThis => 'has this song';

  @override
  String playlistPickerHasSome(int have, int total) {
    return 'has $have / $total';
  }

  @override
  String get playlistPickerNoneSelected => 'Choose one or more playlists';

  @override
  String playlistPickerSelected(int count) {
    return '$count selected';
  }

  @override
  String get playlistPickerAdd => 'Add';

  @override
  String playlistPickerAddMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count playlists',
      one: '1 playlist',
    );
    return 'Add to $_temp0';
  }

  @override
  String get playlistAlreadyTitle => 'Already in the playlist';

  @override
  String get playlistAlreadySkip => 'Only add new songs';

  @override
  String get playlistAlreadySkipHint => 'Songs already there stay as they are';

  @override
  String get playlistAlreadyMove => 'Add all, drop the old copies';

  @override
  String get playlistAlreadyMoveHint => 'Songs already there move to the end';

  @override
  String get playlistAlreadyAll => 'Add all';

  @override
  String get playlistAlreadyAllHint => 'Songs already there appear twice';

  @override
  String get playlistAlreadyAppliesToAll =>
      'The choice applies to all of them.';

  @override
  String playlistAddedSummary(
    int songs,
    int playlists,
    int newPlaylists,
    int skipped,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      songs,
      locale: localeName,
      other: '$songs songs',
      one: '1 song',
    );
    String _temp1 = intl.Intl.pluralLogic(
      playlists,
      locale: localeName,
      other: '$playlists playlists',
      one: '1 playlist',
    );
    String _temp2 = intl.Intl.pluralLogic(
      newPlaylists,
      locale: localeName,
      other: ' ($newPlaylists new)',
      zero: '',
    );
    String _temp3 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: ', skipped $skipped',
      zero: '',
    );
    return 'Added $_temp0 to $_temp1$_temp2$_temp3';
  }

  @override
  String playlistAddedGone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count playlists were',
      one: '1 playlist was',
    );
    return '$_temp0 deleted meanwhile';
  }

  @override
  String get playlistAddFailed => 'Couldn\'t add to the playlist';

  @override
  String get playlistProSmartNote => 'Smart playlists are part of Pro';

  @override
  String get playlistM3uFileTypes => 'Playlist files';

  @override
  String playlistM3uImported(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'Imported $_temp0 into $name';
  }

  @override
  String get playlistM3uReportTitle => 'Playlist imported';

  @override
  String playlistM3uReportSummary(
    int added,
    int total,
    String file,
    String name,
  ) {
    return 'Added $added / $total lines of $file to “$name”.';
  }

  @override
  String playlistM3uReportNotInLibrary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count songs are not in your library yet: they appear after the next library scan.',
      one: '1 song is not in your library yet: it appears after the next library scan.',
    );
    return '$_temp0';
  }

  @override
  String playlistM3uReportUnresolved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines are',
      one: '1 line is',
    );
    return '$_temp0 not music files on this device or are outside your music folders (add that folder in Settings › Library):';
  }

  @override
  String playlistM3uReportSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines are files',
      one: '1 line is a file',
    );
    return '$_temp0 the library skips when scanning (in a hidden folder, or shorter than 30 seconds while “Skip short songs” is on in Settings › Library):';
  }

  @override
  String playlistM3uReportNoBase(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines use',
      one: '1 line uses',
    );
    return '$_temp0 relative paths, but the playlist file is not in internal storage, so their starting folder is unknown. Copy the playlist file next to the music folder and import it again:';
  }

  @override
  String get playlistM3uAllOutside =>
      'The songs of this playlist are outside your music folders. Add that folder in Settings › Library, then import again. Nothing was imported.';

  @override
  String playlistM3uReportLine(int line, String text) {
    return 'Line $line: $text';
  }

  @override
  String playlistM3uReportMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more lines',
      one: '1 more line',
    );
    return 'and $_temp0';
  }

  @override
  String get playlistM3uOpenPlaylist => 'Open playlist';

  @override
  String get playlistM3uNothingFound =>
      'No song of this playlist was found on this device. Nothing was imported.';

  @override
  String get playlistM3uTooLarge => 'The file is too large to be a playlist.';

  @override
  String get playlistM3uReadFailed => 'Couldn\'t read the file.';

  @override
  String playlistM3uExported(int count, String file) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'Saved $_temp0 to $file';
  }

  @override
  String playlistM3uReplaceTitle(String file) {
    return 'Replace $file?';
  }

  @override
  String get playlistM3uExportFailed => 'Couldn\'t save the file.';

  @override
  String get plScreensFavoritesLine => 'Songs you tapped';

  @override
  String get plScreensFavoritesLineSemantics => 'Songs you liked';

  @override
  String plScreensDeleted(String name) {
    return 'Deleted “$name”';
  }

  @override
  String get plScreensDeleteFailed => 'Couldn\'t delete the playlist';

  @override
  String plScreensCharCount(int count, int max) {
    return '$count / $max';
  }

  @override
  String get plScreensCoverFailed => 'Couldn\'t change the cover';

  @override
  String get plScreensDuplicateCopyCover => 'Copy the custom cover too';

  @override
  String get plScreensDuplicateConfirm => 'Duplicate';

  @override
  String get plScreensPlay => 'Play playlist';

  @override
  String get plScreensEditList => 'Edit list';

  @override
  String get plScreensEditDone => 'Done';

  @override
  String plScreensEditBarLead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0 · Playlist order';
  }

  @override
  String get plScreensUnitPlaylists => 'playlists';

  @override
  String plAddMovedSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ', dropped $count old copies',
      one: ', dropped 1 old copy',
    );
    return '$_temp0';
  }

  @override
  String plAddSkippedSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ', skipped $count',
      one: ', skipped 1',
    );
    return '$_temp0';
  }

  @override
  String plAddAlreadyInOne(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs are',
      one: '1 song is',
    );
    return '$_temp0 already in “$name”.';
  }

  @override
  String plAddAlreadyInMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Some songs are already in $count playlists.',
      one: 'Some songs are already in 1 playlist.',
    );
    return '$_temp0';
  }

  @override
  String plAddDefaultNameNumbered(int count) {
    return 'New playlist $count';
  }

  @override
  String plAddAddedToOne(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'Added $_temp0 to “$name”';
  }

  @override
  String plAddNothingNewOne(String name) {
    return 'Every song is already in “$name”';
  }

  @override
  String plAddNothingNewMany(int count) {
    return 'Every song is already in the $count playlists';
  }

  @override
  String get plAddSourceQueue => 'from the queue';

  @override
  String plAddDroppedSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ', $count songs no longer in the library',
      one: ', 1 song no longer in the library',
    );
    return '$_temp0';
  }

  @override
  String get plAddSongsGone => 'These songs are no longer in your library';

  @override
  String get plAddTimedOut => 'This is taking too long. Try again.';

  @override
  String get plAddNotConfirmed =>
      'Couldn\'t confirm the songs were added. Check the playlist.';

  @override
  String m3uImportProgressTitle(String file) {
    return 'Importing $file';
  }

  @override
  String m3uImportProgressLines(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$doneString / $totalString lines';
  }

  @override
  String get m3uImportFailed => 'Couldn\'t import the file.';

  @override
  String m3uReportTruncated(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'The file has more lines than the limit, so only the first $maxString were read.';
  }

  @override
  String m3uExportedSkipped(int count, String file, int skipped) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat skippedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String skippedString = skippedNumberFormat.format(skipped);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString songs',
      one: '1 song',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skippedString skipped (no file on this device)',
      one: '1 skipped (no file on this device)',
    );
    return 'Saved $_temp0 to $file, $_temp1';
  }

  @override
  String get m3uExportFolderUnknown =>
      'Couldn\'t write relative paths: the folder of this file is unknown. Save it in internal storage, or export with absolute paths.';

  @override
  String get m3uExportReplace => 'Replace';

  @override
  String m3uReportNotIndexed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$countString lines are files that are on this device but not in Android\'s media index, so the library cannot see them',
      one: '1 line is a file that is on this device but not in Android\'s media index, so the library cannot see it',
    );
    return '$_temp0. Go to Settings › Library › Music folders › Add folder, tap “Can\'t see your folder? Rescan”, then import again:';
  }

  @override
  String get m3uImportNotIndexed =>
      'Android\'s media index does not list the music files of this playlist yet, so the library cannot see them. Go to Settings › Library › Music folders › Add folder, tap “Can\'t see your folder? Rescan”, then import again. Nothing was imported.';

  @override
  String get coverDialogTitle => 'Cover';

  @override
  String get coverEditAlbumTooltip => 'Edit album cover';

  @override
  String get coverEditArtistTooltip => 'Set artist image';

  @override
  String get coverAutoTitle => 'Automatic';

  @override
  String get coverAutoSubtitleAlbum => 'Cover in the music file';

  @override
  String get coverAutoSubtitleArtist => 'First album cover';

  @override
  String get coverAutoSubtitlePlaylist => 'Made from the first 4 album covers';

  @override
  String get coverCurrentTitle => 'Current image';

  @override
  String get coverCurrentSubtitle => 'Chosen earlier';

  @override
  String get coverGroupArtistAlbums => 'Covers of the artist\'s albums';

  @override
  String get coverGroupPlaylistAlbums => 'Album covers in the playlist';

  @override
  String coverMoreAlbums(int count) {
    return 'Show $count more albums';
  }

  @override
  String get coverAlbumSubtitle => 'Album cover';

  @override
  String coverAlbumSubtitleYear(int year) {
    return 'Album cover · $year';
  }

  @override
  String get coverPickMobile => 'Choose image…';

  @override
  String get coverPickDesktop => 'Choose image from device…';

  @override
  String get coverPickedReading => 'Reading image…';

  @override
  String coverPickedSubtitle(int width, int height) {
    return 'From device · $width × $height';
  }

  @override
  String get coverPickedGeneratedName => 'Image from device';

  @override
  String get coverPanHint =>
      'Drag the image to choose the visible part (the image is cropped square)';

  @override
  String coverSmallImage(int width, int height) {
    return 'Small image ($width × $height px): it may look blurry in Now Playing and on the detail page. You can still save it.';
  }

  @override
  String get coverHintResetAlbum =>
      'Save: drops your image and uses the cover in the music file again';

  @override
  String get coverHintResetArtist =>
      'Save: drops your image and uses the automatic image again';

  @override
  String get coverHintResetPlaylist =>
      'Save: drops your image and uses the automatic cover again';

  @override
  String get coverHintCopied =>
      'The image is copied into Kanaru\'s data; the original file and tags are unchanged';

  @override
  String get coverScopeAlbum => 'Applies to the album everywhere';

  @override
  String get coverScopeArtist => 'The artist\'s image everywhere';

  @override
  String get coverScopePlaylist => 'This playlist only';

  @override
  String get coverScopeForm =>
      'Saved with the other changes when you tap Save in Edit playlist';

  @override
  String get coverCancel => 'Cancel';

  @override
  String get coverSave => 'Save';

  @override
  String get coverChoose => 'Choose';

  @override
  String get coverDropHere => 'Drop the image here';

  @override
  String get coverChanged => 'Cover changed';

  @override
  String get coverResetDone => 'Automatic cover restored';

  @override
  String get coverUndo => 'Undo';

  @override
  String get coverUndoFailed => 'Couldn\'t undo';

  @override
  String get coverErrorFormat =>
      'This image can\'t be used (only JPEG, PNG and WebP are supported)';

  @override
  String get coverErrorRead =>
      'Couldn\'t read the image file. Try again later.';

  @override
  String get coverLinuxDialogLabel => 'Images';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsNativeVersions => 'Native libraries';

  @override
  String get settingsSaveFailed =>
      'Couldn\'t save settings. Changes last until the app closes.';

  @override
  String get settingsRootAppearance => 'Appearance';

  @override
  String get settingsRootAppearanceDesc =>
      'Theme, language, colors, text, seek bar';

  @override
  String get settingsRootLibrary => 'Library';

  @override
  String get settingsRootLibraryDesc =>
      'Music folders, scan, tabs, artist split';

  @override
  String get settingsRootLibraryMissingPermission =>
      ' · music permission missing';

  @override
  String get settingsRootPlayback => 'Playback';

  @override
  String get settingsRootPlaybackDesc =>
      'Gapless, sound, ReplayGain, listening history';

  @override
  String get settingsRootLyrics => 'Lyrics';

  @override
  String get settingsRootLyricsDesc =>
      'Display, search and save, sources, translation';

  @override
  String get settingsRootPlugins => 'Plugins';

  @override
  String get settingsRootPluginsDesc =>
      'Installed plugins, plugin store, updates';

  @override
  String get settingsRootAi => 'AI chat';

  @override
  String get settingsRootAiDesc =>
      'AI services, permissions, tools, skills, history';

  @override
  String get settingsRootIntegrations => 'Integrations';

  @override
  String get settingsRootIntegrationsDescDesktop =>
      'MCP server, web server on the local network';

  @override
  String get settingsRootIntegrationsDescMobile =>
      'Web server on the local network';

  @override
  String get settingsRootData => 'Data and storage';

  @override
  String get settingsRootDataDesc => 'Cache, backup';

  @override
  String get settingsRootAdvanced => 'Advanced';

  @override
  String get settingsRootAdvancedDesc => 'Logs, privacy, reset';

  @override
  String get settingsRootPro => 'Kanaru Pro';

  @override
  String get settingsRootProFreeDesc =>
      'One-time purchase · sync, many sources, advanced stats…';

  @override
  String get settingsRootProActive => 'Activated · thank you';

  @override
  String get settingsRootAboutDesc => 'License, native libraries';

  @override
  String get settingsAppearanceColorMotionTitle => 'Color and motion';

  @override
  String get settingsAppearancePureBlack => 'Pure black';

  @override
  String get settingsAppearancePureBlackNeedsDark => 'Dark theme only';

  @override
  String get settingsAppearanceMotion => 'Animations';

  @override
  String get settingsAppearanceTextTitle => 'Text';

  @override
  String get settingsAppearanceFont => 'Font';

  @override
  String get settingsAppearanceTextSize => 'Text size';

  @override
  String get settingsAppearanceDisplayTitle => 'Display';

  @override
  String get settingsAppearanceSeekBar => 'Seek bar';

  @override
  String get settingsAppearanceWindowFrame => 'System window frame';

  @override
  String get settingsSeekBarCaption =>
      'Used in Now Playing and the lyrics screen.';

  @override
  String get settingsSeekBarWaveform => 'Waveform';

  @override
  String get settingsSeekBarWaveformCaption =>
      'Local files and some plugins. Tracks without a waveform use the flat bar.';

  @override
  String get settingsSeekBarFlat => 'Flat bar';

  @override
  String get settingsSeekBarFlatCaption => 'Every track';

  @override
  String get settingsAboutEditionFree => 'Free edition';

  @override
  String get settingsAboutEditionPro => 'Kanaru Pro';

  @override
  String get settingsAboutLicenses => 'Open source licenses';

  @override
  String settingsPercent(int percent) {
    return '$percent %';
  }

  @override
  String get settingsAboutLicense => 'License';

  @override
  String get settingsPlaybackBlockPlay => 'Playback';

  @override
  String get settingsPlaybackBlockSound => 'Sound';

  @override
  String get settingsPlaybackBlockHistory => 'Listening history';

  @override
  String get settingsPlaybackGapless => 'Gapless playback';

  @override
  String get settingsPlaybackGaplessDesc => 'Applies from the next track';

  @override
  String get settingsPlaybackFadeIn => 'Fade in when playing';

  @override
  String get settingsPlaybackFadeOut => 'Fade out when pausing';

  @override
  String get settingsPlaybackCrossfade => 'Crossfade';

  @override
  String get settingsPlaybackCrossfadeDesc =>
      'Crossfade: the old track fades out while the new one fades in.';

  @override
  String get settingsPlaybackOutputDevice => 'Output device';

  @override
  String get settingsPlaybackReplayGain => 'ReplayGain';

  @override
  String get settingsPlaybackPreamp => 'Preamp';

  @override
  String get settingsPlaybackClipping => 'Prevent clipping';

  @override
  String get settingsPlaybackClippingDesc =>
      'Lowers the level when the preamp would distort the sound.';

  @override
  String get settingsPlaybackOff => 'Off';

  @override
  String get settingsPlaybackAuto => 'Automatic';

  @override
  String get settingsPlaybackPreviousButton => 'Previous button';

  @override
  String get settingsPlaybackPreviousAlways =>
      'Always go to the previous track';

  @override
  String get settingsPlaybackPreviousAlwaysDesc => 'Default';

  @override
  String get settingsPlaybackPreviousRestart => 'Restart after 3 seconds';

  @override
  String get settingsPlaybackPreviousRestartDesc =>
      'Within the first 3 seconds it goes to the previous track.';

  @override
  String get settingsPlaybackHistory => 'Record listening history';

  @override
  String get settingsPlaybackHistoryDesc =>
      'Used by History, Most played and Continue listening.';

  @override
  String get settingsPlaybackHistoryOff => 'Off · what was recorded stays';

  @override
  String get settingsPlaybackListenRule => 'Count a listen after';

  @override
  String get settingsPlaybackListenCaption =>
      'A track counts as a listen when it reaches whichever comes first. Default: 4 minutes or 50 %.';

  @override
  String get settingsPlaybackListenNeedsHistory =>
      'Turn on Record listening history to use this';

  @override
  String get settingsPlaybackListenNoTime => 'Not used';

  @override
  String get settingsPlaybackListenEndLabel => 'Whole track';

  @override
  String settingsPlaybackListenTimeLive(String duration) {
    return 'After $duration of listening';
  }

  @override
  String get settingsPlaybackListenNoTimeLive => 'Not counted by time';

  @override
  String settingsPlaybackListenPercentLive(int percent) {
    return 'or after $percent % of the track';
  }

  @override
  String get settingsPlaybackListenEndLive => 'or after the whole track';

  @override
  String settingsPlaybackListenTimeOrPercent(String duration, int percent) {
    return '$duration or $percent %';
  }

  @override
  String settingsPlaybackListenTimeOrEnd(String duration) {
    return '$duration or the whole track';
  }

  @override
  String get settingsPlaybackListenEnd => 'Listen to the end';

  @override
  String settingsPlaybackListenPercentOnly(int percent) {
    return '$percent % of the track';
  }

  @override
  String settingsDurationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String settingsDurationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String settingsDurationMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String settingsPlaybackPreampValue(int db) {
    return '$db dB';
  }

  @override
  String get settingsAppearancePureBlackDesc =>
      'A fully black background in the Dark theme, good for OLED screens.';

  @override
  String get settingsAppearanceMotionDesc =>
      'Off: pages and sheets appear at once, without sliding.';

  @override
  String get settingsAppearanceWindowFrameDesc =>
      'Use the system title bar and window border instead of the Kanaru bar.';

  @override
  String get settingsAppearanceWindowFrameApply =>
      'Applies after Kanaru is reopened';

  @override
  String get settingsAppearanceTextSizeDefault => 'Default';

  @override
  String get settingsPlaybackNeedsReplayGain =>
      'Turn on ReplayGain to use this';

  @override
  String settingsSectionHintTooltip(String section) {
    return 'About $section';
  }

  @override
  String settingsLibraryTracksCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String settingsLibraryAlbumsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString albums',
      one: '1 album',
    );
    return '$_temp0';
  }

  @override
  String settingsLibraryArtistsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString artists',
      one: '1 artist',
    );
    return '$_temp0';
  }

  @override
  String settingsLibraryLastScan(String time, int added) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added songs added',
      one: '1 song added',
    );
    return 'Last scan $time · $_temp0';
  }

  @override
  String get settingsLibraryBlockScan => 'Scan';

  @override
  String get settingsLibraryBlockOrganise => 'Organise';

  @override
  String get settingsLibraryBlockRemoved => 'Removed';

  @override
  String settingsLibraryFoldersEstimate(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString songs',
      one: '1 song',
    );
    return 'About $_temp0';
  }

  @override
  String get settingsLibraryMinDuration => 'Skip files shorter than';

  @override
  String get settingsLibraryMinDurationCaption =>
      'Ringtones, alerts and short recordings. Applies at the next scan.';

  @override
  String get settingsLibraryMinSize => 'Skip files smaller than';

  @override
  String get settingsLibraryMinSizeCaption =>
      'Measured by file size. Applies at the next scan.';

  @override
  String settingsLibrarySizeKb(int kb) {
    final intl.NumberFormat kbNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kbString = kbNumberFormat.format(kb);

    return '$kbString KB';
  }

  @override
  String settingsLibrarySizeMb(double mb) {
    final intl.NumberFormat mbNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String mbString = mbNumberFormat.format(mb);

    return '$mbString MB';
  }

  @override
  String get settingsLibraryFormats => 'Scanned formats';

  @override
  String get settingsLibraryFormatsCaption =>
      'Untick a format to skip it when scanning. Keep at least one.';

  @override
  String get settingsLibraryFormatsKeepOne => 'keep at least one';

  @override
  String get settingsLibraryFormatsAll => 'All';

  @override
  String get settingsLibraryFormatsSelectAll => 'Select all';

  @override
  String settingsCountOfTotal(int n, int total) {
    return '$n / $total';
  }

  @override
  String get settingsLibraryDedupName => 'Merge tracks with the same file name';

  @override
  String get settingsLibraryDedupNameDesc =>
      'Files with the same name in different folders show as one track, the highest quality copy. Files are not deleted.';

  @override
  String get settingsLibraryNomedia => 'Skip folders with a .nomedia file';

  @override
  String get settingsLibraryNomediaDesc =>
      'Like Android: a folder with .nomedia is not scanned.';

  @override
  String get settingsLibraryWatch => 'Update when folders change';

  @override
  String get settingsLibraryWatchDesc =>
      'See new files at once, no rescan needed.';

  @override
  String get settingsLibraryRulesApplyLater => 'Applies at the next scan';

  @override
  String get settingsLibraryRescanning =>
      'Rescanning the library in the background';

  @override
  String get settingsLibraryMergeFolders =>
      'Merge folders with a single subfolder';

  @override
  String get settingsLibraryMergeFoldersDesc =>
      'Folders tab: go straight into the only subfolder.';

  @override
  String get settingsLibraryAlbumGrouping => 'Group albums by';

  @override
  String get settingsLibraryRemoved => 'Removed from library';

  @override
  String get settingsLibraryTabsHintMobile =>
      'Turn on the tabs you want, drag to reorder. At least one tab stays on. Tabs are the sub-tab row at the top of Library.';

  @override
  String get settingsLibraryTabsHintDesktop =>
      'Turn on the tabs you want, drag to reorder. At least one tab stays on. Tabs are the Library items in the sidebar.';

  @override
  String settingsLibraryRemoveFolderTitle(String name) {
    return 'Remove “$name”?';
  }

  @override
  String get settingsLibraryRemoveFolderBody =>
      'The songs in this folder leave the library (playlists keep their place and mark them as missing).\n\nFiles on your device are not deleted.';

  @override
  String settingsLibraryRemoveFolderBodyCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString songs',
      one: '1 song',
    );
    return '$_temp0 in this folder leave the library (playlists keep their place and mark them as missing).\n\nFiles on your device are not deleted.';
  }

  @override
  String get settingsLibraryRemoveFolderConfirm => 'Remove folder';

  @override
  String settingsLibraryFolderRemoved(String name) {
    return 'Removed “$name”';
  }

  @override
  String settingsLibraryFolderRemovedCount(String name, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString songs',
      one: '1 song',
    );
    return 'Removed “$name” · $_temp0 left the library';
  }

  @override
  String get settingsLibraryLastFolderTitle => 'Cannot remove the last folder';

  @override
  String settingsLibraryLastFolderBody(String name) {
    return 'The library needs at least one music folder. Add another folder first, then remove “$name”.';
  }

  @override
  String get settingsLibraryGotIt => 'Got it';

  @override
  String settingsLibraryExclusionRemoved(String name) {
    return '“$name” is no longer excluded · rescanning';
  }

  @override
  String get settingsLibraryArtistSplit => 'Split artists';

  @override
  String settingsLibrarySeparatorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count separators',
      one: '1 separator',
    );
    return '$_temp0';
  }

  @override
  String get settingsArtistSplitIntro =>
      'One song, several artists: Kanaru splits the names at these marks.';

  @override
  String get settingsArtistSplitExample => 'Example';

  @override
  String get settingsArtistSplitExampleNote =>
      'The default list has no , or & because many band names contain them. To split on them, add them here, then add those band names to Keep whole.';

  @override
  String get settingsArtistSplitSeparators => 'Separators';

  @override
  String get settingsArtistSplitSeparatorsHint =>
      'A space shows as ␣. Changes apply now; the library updates in the background.';

  @override
  String get settingsArtistSplitKeep => 'Keep whole';

  @override
  String get settingsArtistSplitKeepHint =>
      'Names that stay one artist even when they contain a separator.';

  @override
  String get settingsArtistSplitSeparatorInput => 'Add a separator, e.g. “ x ”';

  @override
  String get settingsArtistSplitKeepInput =>
      'Artist name, e.g. “Hồ Ngọc Hà / Noo”';

  @override
  String get settingsArtistSplitAdd => 'Add';

  @override
  String settingsArtistSplitRemove(String value) {
    return 'Remove $value';
  }

  @override
  String get settingsArtistSplitNoSeparators =>
      'No separators: artist names stay as they are.';

  @override
  String get settingsArtistSplitErrEmpty => 'Nothing typed';

  @override
  String get settingsArtistSplitErrDuplicate => 'Already in the list';

  @override
  String settingsArtistSplitErrTooLong(int max) {
    return 'At most $max characters';
  }

  @override
  String settingsArtistSplitErrFull(int max) {
    return 'At most $max entries';
  }

  @override
  String get settingsArtistSplitReset => 'Restore defaults';

  @override
  String get settingsArtistSplitResetIsDefault => 'Already the default';

  @override
  String settingsArtistSplitResetTo(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count separators',
      one: '1 separator',
    );
    return '$_temp0, “$names”';
  }

  @override
  String get settingsArtistSplitResetTitle => 'Restore the default separators?';

  @override
  String get settingsArtistSplitResetBody =>
      'The separators and the kept names go back to how they were at install. The library updates in the background.';

  @override
  String get settingsArtistSplitResetConfirm => 'Restore';

  @override
  String settingsArtistSplitAdded(String value) {
    return 'Added “$value”';
  }

  @override
  String settingsArtistSplitAddedGroup(String value) {
    return 'Added “$value” · add band names that contain it to Keep whole';
  }

  @override
  String settingsArtistSplitRemoved(String value) {
    return 'Removed “$value”';
  }

  @override
  String get settingsArtistSplitRestored => 'Defaults restored';

  @override
  String get settingsLibraryLanguageSource => 'Language source';

  @override
  String get settingsLibraryLanguageSourceCaption =>
      'How Kanaru decides which language a song is in (Language tab).';

  @override
  String get settingsLibraryLanguageBoth => 'Tag, then detection';

  @override
  String get settingsLibraryLanguageBothDesc =>
      'Use the file\'s language tag, else guess from the title and lyrics';

  @override
  String get settingsLibraryLanguageTag => 'Tag only';

  @override
  String get settingsLibraryLanguageTagDesc =>
      'Songs with no tag go to “Unknown”';

  @override
  String get settingsLibraryLanguageDetected => 'Detection only';

  @override
  String get settingsLibraryLanguageDetectedDesc =>
      'Ignore the file\'s language tag';

  @override
  String get sleepTimerHint => 'Tap an item to start right away.';

  @override
  String get sleepTimerCancel => 'Cancel';

  @override
  String get sleepTimerSectionDuration => 'After a while';

  @override
  String get sleepTimerSectionTracks => 'By track';

  @override
  String sleepTimerTileUntil(String time) {
    return 'until $time';
  }

  @override
  String sleepTimerTileStartLabel(String duration, String time) {
    return 'Start $duration, stops at $time';
  }

  @override
  String get sleepTimerCustom => 'Custom…';

  @override
  String sleepTimerCustomRange(int min, int max) {
    return '$min–$max minutes';
  }

  @override
  String get sleepTimerEndOfTrack => 'End of this track';

  @override
  String get sleepTimerEndOfAlbum => 'End of this album';

  @override
  String get sleepTimerEndOfQueue => 'End of the queue';

  @override
  String get sleepTimerAfterTracks => 'After a number of tracks…';

  @override
  String sleepTimerAfterTracksRange(int min, int max) {
    return '$min–$max tracks, this one included';
  }

  @override
  String get sleepTimerNoAlbum => 'This track has no album';

  @override
  String sleepTimerLeftTime(String time) {
    return '$time left';
  }

  @override
  String sleepTimerLeftTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks left',
      one: '1 track left',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerRepeatOneStops =>
      'Repeating one track · stops after this one';

  @override
  String sleepTimerLeftTracksCapped(int count) {
    return '$count+ tracks left';
  }

  @override
  String sleepTimerLeftTracksDuration(int count, String duration) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks left',
      one: '1 track left',
    );
    return '$_temp0 · $duration';
  }

  @override
  String get sleepTimerRunning => 'Running';

  @override
  String sleepTimerRunningWith(String status) {
    return 'Running · $status';
  }

  @override
  String get sleepTimerCustomTitle => 'Custom';

  @override
  String get sleepTimerKindLabel => 'Timer type';

  @override
  String get sleepTimerKindMinutes => 'Minutes';

  @override
  String get sleepTimerKindTracks => 'Tracks';

  @override
  String get sleepTimerFieldMinutes => 'Minutes';

  @override
  String get sleepTimerUnitMinutes => 'minutes';

  @override
  String sleepTimerUnitMinutesWords(String words) {
    return 'minutes · $words';
  }

  @override
  String sleepTimerUnitTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tracks',
      one: 'track',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerStopsAt(String time) {
    return 'Stops at $time';
  }

  @override
  String sleepTimerStopsAfterTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return 'Pauses after $_temp0, this one included';
  }

  @override
  String sleepTimerTracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerStart => 'Start';

  @override
  String sleepTimerMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '$count minute',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '$count hour',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String sleepTimerHoursMinutesShort(int hours, int minutes) {
    return '$hours h $minutes';
  }

  @override
  String sleepTimerChipMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String sleepTimerAddMinutes(int minutes) {
    return 'Add $minutes minutes';
  }

  @override
  String sleepTimerRemoveMinutes(int minutes) {
    return 'Take off $minutes minutes';
  }

  @override
  String get sleepTimerRemoveOneMinute => 'Take off 1 minute';

  @override
  String get sleepTimerAddTrack => 'Add one track';

  @override
  String get sleepTimerRemoveTrack => 'Remove one track';

  @override
  String sleepTimerChipPlusMinutes(int minutes) {
    return '+$minutes min';
  }

  @override
  String get sleepTimerChipPlusHour => '+1 h';

  @override
  String get sleepTimerAddHour => 'Add 1 hour';

  @override
  String sleepTimerStepMinus(int amount) {
    return '−$amount';
  }

  @override
  String sleepTimerStepPlus(int amount) {
    return '+$amount';
  }

  @override
  String get sleepTimerLabelSleepIn => 'Sleep in';

  @override
  String get sleepTimerLabelHeld => 'Counting paused';

  @override
  String get sleepTimerLabelPauseAfter => 'Pause after';

  @override
  String get sleepTimerLabelPauseAtEnd => 'Pause at the end of';

  @override
  String get sleepTimerWordTrack => 'this track';

  @override
  String get sleepTimerWordAlbum => 'this album';

  @override
  String get sleepTimerWordQueue => 'the queue';

  @override
  String get sleepTimerRowHeld => 'Counting paused';

  @override
  String get sleepTimerRowCurrentCounts => 'The current track counts as one';

  @override
  String get sleepTimerRowLastTrack => 'this is the last track';

  @override
  String sleepTimerRowTracksOf(int left, int total) {
    return '$left / $total';
  }

  @override
  String get sleepTimerRowQueueKept => 'the queue stays';

  @override
  String get sleepTimerPauseCounting => 'Pause counting';

  @override
  String get sleepTimerResumeCounting => 'Resume counting';

  @override
  String get sleepTimerTurnOff => 'Turn off timer';

  @override
  String get sleepTimerChange => 'Change…';

  @override
  String sleepTimerStatusMinutes(String duration) {
    return 'Sleep in $duration';
  }

  @override
  String sleepTimerStatusHeld(String duration) {
    return 'Counting paused · $duration left';
  }

  @override
  String sleepTimerStatusTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return 'Pause after $_temp0';
  }

  @override
  String get sleepTimerStatusEndTrack => 'Pause at the end of this track';

  @override
  String get sleepTimerStatusEndAlbum => 'Pause at the end of this album';

  @override
  String get sleepTimerStatusEndQueue => 'Pause at the end of the queue';

  @override
  String get sleepTimerPillTrack => 'Track';

  @override
  String get sleepTimerPillAlbum => 'Album';

  @override
  String get sleepTimerPillQueue => 'Queue';

  @override
  String get sleepTimerEntryEndTrack => 'end of this track';

  @override
  String get sleepTimerEntryEndAlbum => 'end of this album';

  @override
  String get sleepTimerEntryEndQueue => 'end of the queue';

  @override
  String sleepTimerEntryRunning(String status) {
    return 'Sleep timer: $status';
  }

  @override
  String sleepTimerMenuRunning(String status) {
    return 'Sleep timer · $status';
  }

  @override
  String get sleepTimerHeldSuffix => '(counting paused)';

  @override
  String sleepTimerAnnounceStartMinutes(String duration, String time) {
    return 'Sleep timer set for $duration, stops at $time';
  }

  @override
  String sleepTimerAnnounceStartTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return 'Sleep timer set, pausing after $_temp0';
  }

  @override
  String get sleepTimerAnnounceStartEndTrack =>
      'Sleep timer set, pausing at the end of this track';

  @override
  String get sleepTimerAnnounceStartEndAlbum =>
      'Sleep timer set, pausing at the end of this album';

  @override
  String get sleepTimerAnnounceStartEndQueue =>
      'Sleep timer set, pausing at the end of the queue';

  @override
  String get sleepTimerAnnounceHeld => 'Counting paused';

  @override
  String get sleepTimerAnnounceResumed => 'Counting resumed';

  @override
  String get sleepTimerAnnounceCancelled => 'Sleep timer turned off';

  @override
  String get sleepTimerAnnounceExpired => 'Sleep timer ended, playback paused';

  @override
  String get historyTitle => 'History';

  @override
  String historyHeroPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays',
      one: '1 play',
    );
    return '$_temp0';
  }

  @override
  String historyHeroSongsSince(int songs, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      songs,
      locale: localeName,
      other: '$songs songs',
      one: '1 song',
    );
    return '$_temp0 · since $date';
  }

  @override
  String historyBarCount(String year, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays',
      one: '1 play',
    );
    return '$year · $_temp0';
  }

  @override
  String get historyJumpToDay => 'Jump to date';

  @override
  String get historyYearsLabel => 'Years';

  @override
  String get historyDayToday => 'Today';

  @override
  String get historyDayYesterday => 'Yesterday';

  @override
  String historyDayPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays',
      one: '1 play',
    );
    return '$_temp0';
  }

  @override
  String historyDayMenuLabel(String day) {
    return 'More options for $day';
  }

  @override
  String historyRowOrdinal(String time, int n) {
    return '$time · play #$n';
  }

  @override
  String historyRowMissing(String time) {
    return '$time · can\'t play';
  }

  @override
  String get historyMissingTap => 'Can\'t play this song';

  @override
  String historyRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removed $count plays',
      one: 'Removed 1 play',
    );
    return '$_temp0';
  }

  @override
  String get historyRemoveFailed => 'Could not remove the play';

  @override
  String get historyWriteFailed => 'Could not save the change';

  @override
  String get historyEmptyMessage => 'The songs you play will show up here.';

  @override
  String get historyRecordingOff =>
      'Listening history is off. What was recorded stays.';

  @override
  String get historyRecordingOn => 'Turn on';

  @override
  String get historyRecordingOnLabel => 'Turn on recording listening history';

  @override
  String get historyRecordingEnabled => 'Listening history is on';

  @override
  String historyYearFooter(String year) {
    return 'See $year';
  }

  @override
  String get historyPlayFailed => 'Could not play the history';

  @override
  String get historyMenuMostPlayed => 'Most played';

  @override
  String get historyMenuClear => 'Clear history…';

  @override
  String get historyMenuPlayDay => 'Play the day';

  @override
  String get historyMenuDeleteDay => 'Remove the day from history';

  @override
  String get historyMenuTrackHistory => 'History of this song';

  @override
  String get historyMenuRemovePlay => 'Remove from history';

  @override
  String get historyNothingToAdd => 'No playable songs to add';

  @override
  String get historyMenuExportM3u => 'Export M3U…';

  @override
  String get historyNothingToExport => 'Nothing to export';

  @override
  String get historyClearTitle => 'Clear history?';

  @override
  String get historyClearHour => 'Last hour';

  @override
  String get historyClearToday => 'Today';

  @override
  String get historyClearWeek => 'Last 7 days';

  @override
  String get historyClearAll => 'Everything';

  @override
  String get historyClearConfirm => 'Clear';

  @override
  String get historyClearCountFailed => 'Could not count the plays';

  @override
  String get historyClearRetry => 'Try again';

  @override
  String get historyClearFailed => 'Could not clear the history';

  @override
  String historyCleared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removed $count plays',
      one: 'Removed 1 play',
    );
    return '$_temp0';
  }

  @override
  String get historyDeleteDayTitle => 'Remove this day from history?';

  @override
  String historyDeleteDayBody(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays',
      one: '1 play',
    );
    return '$_temp0 on $date will be removed. This cannot be undone.';
  }

  @override
  String historyFilterHint(String year) {
    return 'Filter in $year';
  }

  @override
  String historyFilterMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays match',
      one: '1 play matches',
    );
    return '$_temp0 · not split by day';
  }

  @override
  String historyFilterCapped(int max) {
    return 'Showing the first $max plays. Narrow the filter to see more.';
  }

  @override
  String historyFilterEmpty(String query) {
    return 'No plays match “$query”.';
  }

  @override
  String get historyMenuMissing => 'Can\'t play';

  @override
  String get historyTrackEmpty => 'No plays yet';

  @override
  String get historyTrackColDay => 'Day';

  @override
  String get historyTrackColTime => 'Time';

  @override
  String get historyTrackColListened => 'Listened';

  @override
  String historyTrackListHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays, newest first',
      one: '$count play, newest first',
    );
    return '$_temp0';
  }

  @override
  String historyTrackRemovePlayLabel(String time, String date) {
    return 'Remove the play at $time, $date';
  }

  @override
  String historyTrackSummaryLast(String when) {
    return 'Last played: $when';
  }

  @override
  String historyTrackSummaryFirst(String date) {
    return 'First played: $date';
  }

  @override
  String historyTrackSummaryTotal(String duration) {
    return 'Listened in total: $duration';
  }

  @override
  String historyTrackListened(String duration) {
    return 'listened $duration';
  }

  @override
  String historyTrackWhen(String day, String time) {
    return '$day $time';
  }

  @override
  String get historyRangeDialogCaption => 'Custom range';

  @override
  String get historyRangePickStart => 'Pick the start date';

  @override
  String get historyRangePickEnd => 'Pick the end date';

  @override
  String historyRangeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get historyRangeDayHasListens => 'Has listens';

  @override
  String get historyRangeStartPlaceholder => 'Start date';

  @override
  String get historyRangeEndPlaceholder => 'End date';

  @override
  String get historyRangeSave => 'Save';

  @override
  String get historyMostPlayedRange1Day => '1 day';

  @override
  String get historyMostPlayedRange7Days => '7 days';

  @override
  String get historyMostPlayedRange30Days => '30 days';

  @override
  String get historyMostPlayedRange6Months => '6 months';

  @override
  String get historyMostPlayedRange1Year => '1 year';

  @override
  String get historyMostPlayedRangeAll => 'All time';

  @override
  String get historyMostPlayedRangeCustom => 'Custom…';

  @override
  String get historyMostPlayedRangesLabel => 'Time range';

  @override
  String get historyMostPlayedPrevious => 'Previous period';

  @override
  String get historyMostPlayedNext => 'Next period';

  @override
  String historyMostPlayedTop(int count) {
    return 'Top $count';
  }

  @override
  String get historyMostPlayedTopLabel => 'Songs shown';

  @override
  String get historyMostPlayedLimitCustom => 'Custom…';

  @override
  String get historyMostPlayedLimitHint => 'From 1 to 1000 songs';

  @override
  String historyMostPlayedLimitCustomValue(int count) {
    return 'Top $count · from 1 to 1000 songs';
  }

  @override
  String get historyMostPlayedLimitTitle => 'Ranked songs';

  @override
  String get historyMostPlayedLimitField => 'Songs';

  @override
  String get historyMostPlayedLimitError => 'Only numbers from 1 to 1000';

  @override
  String historyMostPlayedHeroTotals(int songs, int plays) {
    String _temp0 = intl.Intl.pluralLogic(
      songs,
      locale: localeName,
      other: '$songs songs',
      one: '1 song',
    );
    String _temp1 = intl.Intl.pluralLogic(
      plays,
      locale: localeName,
      other: '$plays plays',
      one: '1 play',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String historyMostPlayedPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays',
      one: '1 play',
    );
    return '$_temp0';
  }

  @override
  String historyMostPlayedRowMissing(String plays) {
    return '$plays · can\'t play';
  }

  @override
  String get historyMostPlayedEmpty => 'No plays in this range.';

  @override
  String get historyMostPlayedPlayFailed => 'Couldn\'t play the list';

  @override
  String get historyMostPlayedMenuPlay => 'Play (by rank)';

  @override
  String historyMostPlayedPlaylistName(String range) {
    return 'Most played · $range';
  }

  @override
  String get historyMostPlayedOpenDay => 'Open in Most played';

  @override
  String get historyMostPlayedFavoriteFailed => 'Couldn\'t add to Favorites';

  @override
  String get savedQueueExplain =>
      'When you play something else, the queue it replaces is kept here (up to 20, the oldest is dropped).';

  @override
  String get savedQueueEmpty =>
      'No saved queues yet. When you play something else, the queue it replaces is kept here.';

  @override
  String savedQueueName(String day, String time) {
    return '$day · $time';
  }

  @override
  String savedQueueExportName(String date) {
    return 'Queue $date';
  }

  @override
  String savedQueueMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs gone',
      one: '1 song gone',
    );
    return '$_temp0';
  }

  @override
  String savedQueueFromAlbum(String name) {
    return 'From album $name';
  }

  @override
  String savedQueueFromArtist(String name) {
    return 'From artist $name';
  }

  @override
  String savedQueueFromGenre(String name) {
    return 'From genre $name';
  }

  @override
  String savedQueueFromLanguage(String name) {
    return 'From language $name';
  }

  @override
  String savedQueueFromFolder(String name) {
    return 'From folder $name';
  }

  @override
  String savedQueueFromPlaylist(String name) {
    return 'From playlist $name';
  }

  @override
  String get savedQueueFromFavorites => 'From Favorites';

  @override
  String get savedQueueFromSongs => 'From Songs';

  @override
  String get savedQueueFromSelection => 'From the selected songs';

  @override
  String savedQueueFromList(String name) {
    return 'From $name';
  }

  @override
  String get savedQueueNoSongs => 'This queue has no songs left.';

  @override
  String get savedQueuePlayRow => 'Play this queue';

  @override
  String savedQueueBar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs, in played order',
      one: '1 song, in played order',
    );
    return '$_temp0';
  }

  @override
  String savedQueuePlaying(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'Playing queue $name ($_temp0). The previous queue was saved.';
  }

  @override
  String get savedQueueNotFoundTitle => 'Queue not found';

  @override
  String get savedQueueNotFoundMessage =>
      'This queue was deleted, or dropped when there were more than 20.';

  @override
  String get savedQueueMenuPlay => 'Play (replace the current queue)';

  @override
  String get savedQueueMenuAppend => 'Add to the end of the queue';

  @override
  String get savedQueueMenuSaveAsPlaylist => 'Save as playlist…';

  @override
  String get savedQueueMenuRemoveMissing => 'Remove songs that are gone';

  @override
  String get savedQueueMenuDelete => 'Delete this queue';

  @override
  String get savedQueueDeleteTitle => 'Delete this queue?';

  @override
  String get savedQueueDeleteBody => 'The songs stay in your library.';

  @override
  String get savedQueueDeleted => 'Queue deleted';

  @override
  String get savedQueueDeleteFailed => 'Couldn\'t delete the queue';

  @override
  String savedQueueRemovedMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removed $count songs',
      one: 'Removed 1 song',
    );
    return '$_temp0';
  }

  @override
  String get savedQueueRemoveFailed => 'Couldn\'t remove the missing songs';

  @override
  String get lyricsLabelTagSynced => 'Lyrics in tag · Synced';

  @override
  String get lyricsLabelTagPlain => 'Lyrics in tag · Plain';

  @override
  String get lyricsLabelLrcSynced => 'LRC file · Synced';

  @override
  String get lyricsLabelLrcPlain => 'LRC file · Plain';

  @override
  String get lyricsLabelOff => 'Lyrics off';

  @override
  String get lyricsLabelNone => 'No lyrics';

  @override
  String get lyricsLabelShortTag => 'In tag';

  @override
  String get lyricsLabelShortLrc => 'LRC file';

  @override
  String get lyricsLabelShortOff => 'Off';

  @override
  String get lyricsPlainNote =>
      'Plain lyrics, no time marks: they do not scroll by themselves.';

  @override
  String get lyricsNoneTitle => 'No lyrics';

  @override
  String get lyricsNoneMessage =>
      'No lyrics in the file or in an .lrc file next to the song.';

  @override
  String get lyricsOffTitle => 'Lyrics are off for this song';

  @override
  String get lyricsOffMessageDesktop =>
      'Right-click the lyrics button to turn them back on.';

  @override
  String get lyricsOffMessageMobile =>
      'You chose “Don’t show lyrics” in Lyrics for this song.';

  @override
  String get lyricsOffOpenChoice => 'Lyrics for this song';

  @override
  String get lyricsBackToLine => 'Back to current line';

  @override
  String lyricsSeekHint(String time) {
    return 'Seek to $time';
  }

  @override
  String get lyricsGapLabel => 'Instrumental break';

  @override
  String get lyricsCardNone => 'No lyrics for this song';

  @override
  String get lyricsCardOff => 'Lyrics are off for this song';

  @override
  String get lyricsCardOpenHint => 'Open the lyrics screen';

  @override
  String lyricsCardLabel(String title, String source) {
    return '$title · $source';
  }

  @override
  String get lyricsTranslateSoon => 'Translate lyrics · Coming soon';

  @override
  String get lyricsForTrackTitle => 'Lyrics for this song';

  @override
  String get lyricsModalClose => 'Close';

  @override
  String get lyricsModalNoneOnDevice => 'No lyrics on this device';

  @override
  String get lyricsChoiceFile => 'Lyrics in file';

  @override
  String get lyricsChoiceFileNone => 'No lyrics in the file';

  @override
  String get lyricsChoiceOff => 'Don’t show lyrics';

  @override
  String get lyricsChoiceSubTagSynced => 'In tag · Synced';

  @override
  String get lyricsChoiceSubTagPlain => 'In tag · Plain';

  @override
  String get lyricsChoiceSubLrcSynced => 'LRC file · Synced';

  @override
  String get lyricsChoiceSubLrcPlain => 'LRC file · Plain';

  @override
  String get lyricsFindOnline => 'Find lyrics online…';

  @override
  String get lyricsFromAudio => 'Create lyrics from audio…';

  @override
  String get lyricsFromAudioSub => 'Groq Whisper';

  @override
  String get lyricsSaveLyrics => 'Save lyrics…';

  @override
  String lyricsSourceTooltipDesktop(String label) {
    return '$label (L)';
  }

  @override
  String get lyricsSourceToggleHint =>
      'Right-click: turn this song’s lyrics on or off';

  @override
  String get lyricsSettingsModalSettings => 'Lyrics settings';

  @override
  String get lyricsSettingsDefault => 'Default';

  @override
  String get lyricsSettingsDisplay => 'Display';

  @override
  String get lyricsSettingsFind => 'Find and save';

  @override
  String get lyricsSettingsSources => 'Online sources';

  @override
  String get lyricsSettingsWhere => 'Where lyrics show';

  @override
  String get lyricsSettingsTranslation => 'Translation';

  @override
  String get lyricsSettingsSpeech => 'Create lyrics from audio';

  @override
  String get lyricsSettingsSpeechHint =>
      'Speech-to-text plugins, used by “Create lyrics from audio…” in Lyrics for this song.';

  @override
  String get lyricsSettingsFontSize => 'Lyrics text size';

  @override
  String get lyricsSettingsFontSizeCaption =>
      'Applies to the lyrics screen, the Lyrics tab and the lyrics card.';

  @override
  String get lyricsSettingsSizeSmall => 'Small';

  @override
  String get lyricsSettingsSizeMedium => 'Medium';

  @override
  String get lyricsSettingsSizeLarge => 'Large';

  @override
  String get lyricsSettingsAlign => 'Lyrics alignment';

  @override
  String get lyricsSettingsAlignStart => 'Left';

  @override
  String get lyricsSettingsAlignCenter => 'Center';

  @override
  String get lyricsSettingsAutoReturn => 'Return to the current line';

  @override
  String get lyricsSettingsAutoReturnCaption =>
      'After you scroll the lyrics by hand. Off keeps the lyrics still until you tap “Back to current line”.';

  @override
  String get lyricsSettingsAutoReturnOff => 'Off';

  @override
  String get lyricsSettingsAutoReturn3 => '3 seconds';

  @override
  String get lyricsSettingsAutoReturn5 => '5 seconds';

  @override
  String get lyricsSettingsAutoReturn10 => '10 seconds';

  @override
  String get lyricsSettingsDim => 'Dim the lines not being sung';

  @override
  String get lyricsSettingsDimLight => 'Slightly dimmed';

  @override
  String get lyricsSettingsDimStrong => 'Strongly dimmed';

  @override
  String get lyricsSettingsDimOff => 'Off';

  @override
  String get lyricsSettingsRomanize => 'Transliteration';

  @override
  String get lyricsSettingsRomanizeDesc =>
      'Romaji, Pinyin, Furigana under Japanese, Chinese and Korean lyrics.';

  @override
  String get lyricsSettingsKeepAwake => 'Keep the screen on';

  @override
  String get lyricsSettingsKeepAwakeDesc =>
      'The screen stays on while the lyrics screen is open.';

  @override
  String get lyricsSettingsAutoFind => 'Find lyrics for songs without any';

  @override
  String get lyricsSettingsAutoFindDesc =>
      'Searches the enabled lyrics sources when a song has no lyrics on this device.';

  @override
  String get lyricsSettingsLocalFirst => 'Lyrics on this device';

  @override
  String get lyricsSettingsLocalFirstCaption =>
      'Synced lyrics always win over plain ones.';

  @override
  String get lyricsSettingsLocalTag => 'Lyrics in the music file first';

  @override
  String get lyricsSettingsLocalTagSub => 'Then the .lrc file';

  @override
  String get lyricsSettingsLocalLrc => '.lrc file first';

  @override
  String get lyricsSettingsLocalLrcSub => 'Then the lyrics in the music file';

  @override
  String get lyricsSettingsAutoSave => 'Save found lyrics as .lrc';

  @override
  String get lyricsSettingsAutoSaveDesc =>
      'Writes an .lrc file next to the song when online lyrics are found.';

  @override
  String get lyricsSettingsAddSource => 'Add an online lyrics source';

  @override
  String get lyricsSettingsFloating => 'Floating lyrics';

  @override
  String get lyricsSettingsFloatingDesc =>
      'A small lyrics window that stays above other windows.';

  @override
  String get lyricsSettingsLockScreen =>
      'Lyrics on the lock screen and notification';

  @override
  String get lyricsSettingsLockScreenDesc =>
      'The line being sung shows in the playback notification and on the lock screen.';

  @override
  String get lyricsSettingsTrService => 'Default translation service';

  @override
  String get lyricsSettingsTrServiceNone => 'Not chosen';

  @override
  String get lyricsSettingsTrTarget => 'Default translation language';

  @override
  String get lyricsSettingsTrTargetApp => 'Follows the app language';

  @override
  String get lyricsSettingsTrAhead => 'Translate ahead';

  @override
  String get lyricsSettingsTrAheadNow => 'Current song only';

  @override
  String get lyricsSettingsAddTrService => 'Add a translation service';

  @override
  String get lyricsSettingsAddSpeech => 'Add a speech-to-text plugin';

  @override
  String get lyricsSearchingTitle => 'Searching for lyrics…';

  @override
  String lyricsSearchingMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enabled sources',
      one: '1 enabled source',
    );
    return 'No lyrics on this device yet · searching $_temp0.';
  }

  @override
  String get lyricsNoneAutoOffMessage =>
      'No lyrics in the file or in an .lrc file next to the song. Automatic search is off.';

  @override
  String get lyricsFindManually => 'Search manually…';

  @override
  String get lyricsNotFoundTitle => 'Lyrics not found';

  @override
  String lyricsNotFoundAsked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enabled sources',
      one: '1 enabled source',
    );
    return 'Searched $_temp0.';
  }

  @override
  String lyricsNotFoundOff(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count other sources are off.',
      one: '1 other source is off.',
    );
    return '$_temp0';
  }

  @override
  String get lyricsNotFoundAllOff =>
      'No lyrics on this device · every online lyrics source is off.';

  @override
  String get lyricsNoSourceMessage =>
      'No lyrics on this device and no online lyrics source yet.';

  @override
  String get lyricsAddSource => 'Add an online lyrics source';

  @override
  String get lyricsInstrumentalTitle => 'Instrumental';

  @override
  String get lyricsInstrumentalMessage =>
      'The lyrics source says this song is instrumental.';

  @override
  String get lyricsInstrumentalFindOnline => 'Not right? Find lyrics online…';

  @override
  String get lyricsFailedTitle => 'Couldn’t find lyrics';

  @override
  String lyricsFailNetwork(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enabled sources',
      one: '1 enabled source',
    );
    return 'Network error searching $_temp0';
  }

  @override
  String get lyricsFailNeedsConfig => 'The sources need setting up';

  @override
  String get lyricsFailNoAnswer => 'The lyrics sources did not answer';

  @override
  String lyricsFailedMessage(String reason) {
    return '$reason.';
  }

  @override
  String lyricsFailedMessageRetry(String reason, String time) {
    return '$reason · trying again at $time.';
  }

  @override
  String get lyricsPausedTitle => 'Lyrics sources are paused';

  @override
  String lyricsPausedMessage(String time) {
    return 'The lyrics sources are paused until $time: the server reported too many requests. Kanaru searches again then.';
  }

  @override
  String get lyricsKindSynced => 'Synced';

  @override
  String get lyricsKindPlain => 'Plain';

  @override
  String lyricsOnlineLabel(String plugin, String kind) {
    return '$plugin · $kind';
  }

  @override
  String get lyricsLabelSearching => 'Searching…';

  @override
  String get lyricsLabelFailed => 'Couldn’t find lyrics';

  @override
  String get lyricsLabelPaused => 'Lyrics sources paused';

  @override
  String lyricsCardFailedRetry(String time) {
    return 'Couldn’t find lyrics · trying again at $time';
  }

  @override
  String lyricsCardPaused(String time) {
    return 'Lyrics sources paused until $time';
  }

  @override
  String get lyricsChoiceOnline => 'Online lyrics';

  @override
  String get lyricsOnlineAuto => 'found automatically';

  @override
  String get lyricsOnlineRemoved => 'plugin removed';

  @override
  String get lyricsOnlineInstrumental => 'Instrumental';

  @override
  String lyricsStatusSearching(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enabled sources',
      one: '1 enabled source',
    );
    return 'No lyrics on this device · searching $_temp0';
  }

  @override
  String lyricsStatusNotFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enabled sources',
      one: '1 enabled source',
    );
    return 'No lyrics found, even in $_temp0';
  }

  @override
  String get lyricsStatusAutoOff =>
      'No lyrics on this device · automatic search is off';

  @override
  String get lyricsStatusNoSource =>
      'No lyrics on this device · no online source yet';

  @override
  String get lyricsStatusAllOff =>
      'No lyrics on this device · every online source is off';

  @override
  String lyricsStatusFailed(String reason) {
    return 'Couldn’t find lyrics · $reason';
  }

  @override
  String lyricsStatusFailedRetry(String reason, String time) {
    return 'Couldn’t find lyrics · $reason · trying again at $time';
  }

  @override
  String get lyricsFailShortNetwork => 'network error';

  @override
  String get lyricsFailShortNeedsConfig => 'needs setting up';

  @override
  String get lyricsFailShortNoAnswer => 'no answer';

  @override
  String lyricsStatusPaused(String time) {
    return 'The lyrics sources are paused until $time (the server reported too many requests)';
  }

  @override
  String lyricsFindOnlineSub(int on, int off) {
    return '$on on · $off off';
  }

  @override
  String lyricsFindOnlineSubAllOff(int off) {
    return 'Every source is off ($off) · searches only when you tap';
  }

  @override
  String get lyricsAddSourceSub =>
      'No lyrics plugin installed · open the plugin store';

  @override
  String lyricsBarAutoTitle(String plugin) {
    return 'Found automatically on $plugin';
  }

  @override
  String get lyricsBarAutoSub => 'Keep it so Kanaru does not search again';

  @override
  String get lyricsBarKeptTitle => 'Using the kept copy';

  @override
  String get lyricsBarKeptSub => 'For this song only';

  @override
  String get lyricsBarReject => 'Wrong song';

  @override
  String get lyricsBarKeep => 'Keep this copy';

  @override
  String get lyricsStatusEnableAuto => 'Turn on auto search';

  @override
  String get lyricsPickerTitle => 'Choose lyrics';

  @override
  String get lyricsPickerBack => 'Back to Lyrics for this song';

  @override
  String get lyricsPickerSearchHint => 'Song, artist';

  @override
  String get lyricsPickerFilterAll => 'All sources';

  @override
  String lyricsPickerGroup(String name, int count) {
    return '$name · $count';
  }

  @override
  String lyricsPickerGroupOff(String name, int count) {
    return '$name · off · $count';
  }

  @override
  String get lyricsPickerBadgeOff => 'Source is off';

  @override
  String get lyricsPickerDeltaMatch => 'match';

  @override
  String get lyricsPickerDeltaMatchTip => 'Length matches the song';

  @override
  String lyricsPickerDeltaLonger(int seconds) {
    return '+$seconds s';
  }

  @override
  String lyricsPickerDeltaShorter(int seconds) {
    return '−$seconds s';
  }

  @override
  String lyricsPickerDeltaLongerTip(int seconds) {
    return '$seconds seconds longer than the song: may be another version (live, remix…)';
  }

  @override
  String lyricsPickerDeltaShorterTip(int seconds) {
    return '$seconds seconds shorter than the song: may be another version (live, remix…)';
  }

  @override
  String lyricsPickerSearching(String name) {
    return 'Searching $name…';
  }

  @override
  String lyricsPickerFailNetwork(String name) {
    return '$name: network error or timed out';
  }

  @override
  String lyricsPickerFailServer(String name) {
    return '$name: the server returned an error';
  }

  @override
  String lyricsPickerFailRateLimited(String name) {
    return '$name: the server says too many requests';
  }

  @override
  String lyricsPickerFailInvalid(String name) {
    return '$name: the answer could not be read';
  }

  @override
  String lyricsPickerNeedsConfig(String name) {
    return '$name · Needs setup';
  }

  @override
  String get lyricsPickerOpenPlugin => 'Open plugin page';

  @override
  String lyricsPickerPaused(String name, String time) {
    return '$name is paused until $time';
  }

  @override
  String get lyricsPickerMoreTitle => 'Not the lyrics you wanted?';

  @override
  String lyricsPickerMoreBody(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count sources are off: $names. Searched only when you tap, settings stay as they are.',
      one:
          'One source is off: $names. Searched only when you tap, settings stay as they are.',
    );
    return '$_temp0';
  }

  @override
  String get lyricsPickerMoreAction => 'Search';

  @override
  String get lyricsPickerEmptyNone => 'No source is on';

  @override
  String lyricsPickerEmptyNotFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nothing found in $count sources that are on',
      one: 'Nothing found in the source that is on',
    );
    return '$_temp0';
  }

  @override
  String lyricsPickerEmptyOff(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources are off ($names). Searched only when you tap.',
      one: 'One source is off ($names). Searched only when you tap.',
    );
    return '$_temp0';
  }

  @override
  String lyricsPickerEmptyAction(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Search $count sources that are off',
      one: 'Search the source that is off',
    );
    return '$_temp0';
  }

  @override
  String get lyricsPickerAllAsked =>
      'Sources that are off were searched too for this song. Source settings are unchanged.';

  @override
  String get lyricsPickerPreview => 'Preview';

  @override
  String lyricsPickerPreviewFrom(String name) {
    return 'Preview · $name';
  }

  @override
  String get lyricsPickerPickOne => 'Choose a result';

  @override
  String get lyricsPickerPreviewBack => 'Back to the list';

  @override
  String get lyricsPickerPreviewBackLabel => 'Back to the results';

  @override
  String get lyricsPickerPlainNote => 'Plain lyrics, no timestamps';

  @override
  String get lyricsPickerPreviewLoading => 'Loading lyrics…';

  @override
  String get lyricsPickerPreviewFailed =>
      'Could not load the lyrics of this result';

  @override
  String get lyricsPickerPreviewMissing => 'This result has no lyrics';

  @override
  String get lyricsPickerPreviewInstrumental => 'Instrumental';

  @override
  String get lyricsPickerFootNote => 'For this song only';

  @override
  String get lyricsPickerCancel => 'Cancel';

  @override
  String get lyricsPickerUse => 'Use these lyrics';

  @override
  String get lyricsPickerSourcesTitle => 'Search sources';

  @override
  String get lyricsPickerSourcesAll => 'All sources';

  @override
  String lyricsPickerSourcesResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get lyricsPickerSourcesNone => 'No results';

  @override
  String get lyricsPickerSourcesOff => 'OFF';

  @override
  String get lyricsPickerSourcesOffCaption =>
      'Searched only when you tap Search.';

  @override
  String lyricsPickerSourcesOffResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results · source is off',
      one: '1 result · source is off',
    );
    return '$_temp0';
  }

  @override
  String get lyricsPickerSourcesNotAsked => 'Not searched';

  @override
  String get lyricsPickerClearSearch => 'Clear the search text';

  @override
  String get lyricsKeepFailed => 'Couldn\'t save the lyrics. Try again.';

  @override
  String get pluginsStoreTitle => 'Plugin store';

  @override
  String get pluginsFilterTooltip => 'Filter';

  @override
  String pluginsFilterActiveLabel(int count) {
    return '$count on';
  }

  @override
  String get pluginsMenuTooltip => 'More options';

  @override
  String get pluginsMenuInstallFile => 'Install from file…';

  @override
  String get pluginsMenuInstallLink => 'Install from link…';

  @override
  String pluginsMenuRepositories(int count) {
    return 'Repositories ($count)';
  }

  @override
  String get pluginsMenuRefreshAll => 'Refresh all';

  @override
  String get pluginsMenuLogsDesktop => 'Open log folder';

  @override
  String get pluginsMenuLogsMobile => 'Share plugin logs…';

  @override
  String get pluginsSearchHint =>
      'Search name, author, repository, host, #type';

  @override
  String get pluginsSearchClear => 'Clear';

  @override
  String pluginsSectionUpdates(int count) {
    return 'Updates ($count)';
  }

  @override
  String pluginsSectionInstalled(int count) {
    return 'Installed ($count)';
  }

  @override
  String pluginsSectionAvailable(int count) {
    return 'Not installed ($count)';
  }

  @override
  String get pluginsUpdatesHint =>
      '“Update all” skips updates with new hosts or permissions: you open those one by one, as when installing.';

  @override
  String get pluginsUpdatesHintTooltip => 'About updates';

  @override
  String pluginsUpdateAll(int count) {
    return 'Update all ($count)';
  }

  @override
  String get pluginsUpdate => 'Update';

  @override
  String pluginsUpdateTooltip(String name) {
    return 'Update $name';
  }

  @override
  String pluginsReviewTooltip(String name) {
    return 'Review the update of $name';
  }

  @override
  String get pluginsPageSettingsTitle => 'The plugin’s settings';

  @override
  String get pluginsPageRefreshFailed => 'Could not refresh the list';

  @override
  String pluginsInstallTooltip(String name) {
    return 'Install $name';
  }

  @override
  String pluginsRemoveTooltip(String name) {
    return 'Remove $name';
  }

  @override
  String get pluginsAlertLabel => 'Has a problem';

  @override
  String get pluginsFreeStreamingLimit =>
      'The Free edition installs only one music source plugin. Remove the current one to install this.';

  @override
  String get pluginsKindLyrics => 'Lyrics';

  @override
  String get pluginsKindTranslate => 'Translation';

  @override
  String get pluginsKindStreaming => 'Music source';

  @override
  String get pluginsKindHelpLyrics =>
      'Finds lyrics for the song playing, with lines that follow the song.';

  @override
  String get pluginsKindHelpTranslate =>
      'Translates lyrics into the language you choose.';

  @override
  String get pluginsKindHelpStreaming =>
      'Searches and plays music from an online service.';

  @override
  String get pluginsAuthorUnknown => 'Unknown author';

  @override
  String pluginsFooterNewer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plugins need a newer Kanaru',
      one: '1 plugin needs a newer Kanaru',
    );
    return '$_temp0';
  }

  @override
  String get pluginsSandboxNote =>
      'Plugins run in a sandbox and can only connect to the addresses declared when installed.';

  @override
  String get pluginsNoMatch => 'No matching plugins.';

  @override
  String get pluginsClearFilters => 'Clear filters';

  @override
  String get pluginsLoadFailed => 'Couldn\'t read the plugin list.';

  @override
  String get pluginsNoRepoTitle => 'No repository yet';

  @override
  String get pluginsNoRepoBody =>
      'Kanaru has no built-in repository. A repository is a list of plugins (a plugins.json file) published by plugin authors.';

  @override
  String get pluginsNoRepoStep1 =>
      'Find the address of the plugins.json file of a repository you trust, usually in the author\'s README. It starts with https://.';

  @override
  String get pluginsNoRepoStep2 =>
      'Press Add repository, paste the address, then press Add.';

  @override
  String get pluginsNoRepoStep3 =>
      'The repository\'s plugins appear here; press Install to see hosts and facts before installing.';

  @override
  String get pluginsAddRepository => 'Add repository';

  @override
  String pluginsRepoFailedOne(String name, String reason) {
    return 'Couldn\'t load $name: $reason';
  }

  @override
  String pluginsRepoFailedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repositories couldn\'t load',
    );
    return '$_temp0';
  }

  @override
  String pluginsRepoShowingSaved(String time) {
    return 'Showing the list saved at $time.';
  }

  @override
  String get pluginsRetry => 'Retry';

  @override
  String get pluginsOfflineTitle => 'No network connection';

  @override
  String get pluginsOfflineBody =>
      'Showing the list saved last time. Installing and updating need a network.';

  @override
  String get pluginsLoadReasonNetwork => 'network error';

  @override
  String get pluginsLoadReasonNotFound => 'file not found';

  @override
  String get pluginsLoadReasonTooLarge => 'file too large';

  @override
  String get pluginsLoadReasonInvalid => 'not a valid plugin list';

  @override
  String get pluginsLoadReasonBlocked => 'address blocked';

  @override
  String get pluginsLoadReasonStorage => 'could not be saved';

  @override
  String get pluginsFilterTitle => 'Filter';

  @override
  String get pluginsFilterGroupKind => 'Plugin type';

  @override
  String get pluginsFilterGroupState => 'Status';

  @override
  String get pluginsFilterGroupLanguage => 'Language';

  @override
  String get pluginsFilterGroupAuthor => 'Author';

  @override
  String get pluginsFilterGroupRepository => 'Repository';

  @override
  String get pluginsStateInstalled => 'Installed';

  @override
  String get pluginsStateNotInstalled => 'Not installed';

  @override
  String get pluginsStateUpdatable => 'Update available';

  @override
  String pluginsFilterShowing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Showing $count plugins',
      one: 'Showing 1 plugin',
    );
    return '$_temp0';
  }

  @override
  String get pluginsFilterClearAll => 'Clear all';

  @override
  String get pluginsFilterDone => 'Done';

  @override
  String get pluginsReposTitle => 'Repositories';

  @override
  String get pluginsReposRefreshAll => 'Refresh all';

  @override
  String pluginsRepoPluginCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plugins',
      one: '1 plugin',
    );
    return '$_temp0';
  }

  @override
  String pluginsRepoLastError(String reason) {
    return 'Last load failed: $reason';
  }

  @override
  String pluginsRepoRemoveTooltip(String name) {
    return 'Remove repository $name';
  }

  @override
  String get pluginsReposEmpty => 'No repository yet.';

  @override
  String get pluginsReposFooter =>
      'Removing a repository keeps the plugins installed from it, but they no longer get updates.';

  @override
  String get pluginsAddDialogUrlLabel => 'URL';

  @override
  String get pluginsAddDialogUrlHint => 'https://…/plugins.json';

  @override
  String get pluginsAddDialogHelper =>
      'The address of the plugins.json file. Must be https, except for machines on your home network (localhost, 192.168.x…).';

  @override
  String get pluginsAddDialogConfirm => 'Add';

  @override
  String get pluginsAddDialogLoading => 'Loading…';

  @override
  String get pluginsCancel => 'Cancel';

  @override
  String pluginsAddedRepo(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $name · $count plugins',
      one: 'Added $name · 1 plugin',
    );
    return '$_temp0';
  }

  @override
  String get pluginsAddErrNeedsHttps => 'Public addresses need https';

  @override
  String get pluginsAddErrInvalidUrl => 'Invalid URL';

  @override
  String get pluginsAddErrDuplicate => 'This repository is already added';

  @override
  String get pluginsAddErrNetwork => 'Couldn\'t load the list: network error';

  @override
  String get pluginsAddErrNotFound => 'No plugin list found at this address';

  @override
  String get pluginsAddErrBadFormat => 'The file is not a valid plugin list';

  @override
  String get pluginsAddErrBlocked => 'This address is blocked';

  @override
  String pluginsAddErrBlockedReason(String reason) {
    return 'This address is blocked: $reason';
  }

  @override
  String get pluginsAddErrStorage => 'Couldn\'t save the repository';

  @override
  String get pluginsAddressUserInfo =>
      'the address must not contain a user name or password';

  @override
  String get pluginsAddressLocalFromPublic =>
      'a public repository must not point to a local address';

  @override
  String get pluginsAddressRefused => 'this address is not allowed';

  @override
  String get pluginsAddressMixed =>
      'the domain points to both local and public addresses';

  @override
  String get pluginsAddressLocalNamePublic =>
      'a local-looking name points to a public address';

  @override
  String pluginsRemoveRepoTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get pluginsRemoveRepoBody =>
      'Plugins already installed from this repository are kept, but they will no longer get updates.';

  @override
  String get pluginsRemoveRepoConfirm => 'Remove';

  @override
  String pluginsRemoveRepoFailed(String name) {
    return 'Couldn\'t remove $name';
  }

  @override
  String get pluginsRootAlertLabel =>
      'A plugin has a problem or an update needs review';

  @override
  String get pluginsPkgClose => 'Close';

  @override
  String get pluginsPkgLoading => 'Loading and checking the package…';

  @override
  String pluginsPkgProgress(int done, int total) {
    return '$done / $total KB · checking plugin.json, file names, hosts, scripts';
  }

  @override
  String pluginsPkgProgressUnknown(int done) {
    return '$done KB · checking plugin.json, file names, hosts, scripts';
  }

  @override
  String get pluginsPkgChecking =>
      'Checking plugin.json, file names, hosts, scripts';

  @override
  String pluginsPkgInstallTitle(String name) {
    return 'Install $name?';
  }

  @override
  String pluginsPkgUpdateTitle(String name) {
    return 'Update $name';
  }

  @override
  String pluginsPkgInstallSubtitle(String kind, int version, String author) {
    return 'Plugin $kind · version $version · $author';
  }

  @override
  String pluginsPkgUpdateSubtitle(String kind, String author) {
    return '$kind · $author';
  }

  @override
  String pluginsPkgAuthorDeclared(String author) {
    return '$author (self-declared)';
  }

  @override
  String pluginsPkgFromRepo(String name) {
    return 'From repository $name';
  }

  @override
  String pluginsPkgFromFile(String name, String size) {
    return 'From file $name · $size';
  }

  @override
  String get pluginsPkgFromLink => 'From link';

  @override
  String get pluginsPkgSendTo => 'Sends data to';

  @override
  String pluginsPkgWildcard(String labels) {
    return '$labels: only music source plugins may declare this (up to 10).';
  }

  @override
  String pluginsPkgWildcardHost(String domain) {
    return 'Every subdomain of $domain';
  }

  @override
  String pluginsPkgUserEndpoint(String field) {
    return 'Address you enter in $field';
  }

  @override
  String get pluginsPkgNoHosts => 'No fixed address.';

  @override
  String get pluginsPkgNewBadge => 'NEW';

  @override
  String get pluginsPkgConsentInstall =>
      'Installing a plugin means you agree to let it send data to these addresses. Kanaru does not ask again when the plugin runs.';

  @override
  String get pluginsPkgConsentUpdate =>
      'Updating means you agree to let the plugin send data to the new addresses too. Kanaru does not ask again when the plugin runs.';

  @override
  String get pluginsPkgFacts => 'Static facts';

  @override
  String get pluginsPkgFactsUpdate =>
      'Static facts · compared with the installed version';

  @override
  String get pluginsPkgAskAi => 'Ask AI about this plugin';

  @override
  String get pluginsPkgAskAiUpdate => 'Ask AI what the new version changes';

  @override
  String get pluginsPkgLater => 'Later';

  @override
  String get pluginsPkgInstall => 'Install';

  @override
  String get pluginsPkgUpdate => 'Update';

  @override
  String get pluginsPkgInstalling => 'Installing…';

  @override
  String get pluginsPkgUpdating => 'Updating…';

  @override
  String pluginsPkgInstalled(String name) {
    return 'Installed $name';
  }

  @override
  String pluginsPkgUpdated(String name, int version) {
    return 'Updated $name to version $version';
  }

  @override
  String pluginsPkgErrDownload(String reason) {
    return 'Couldn’t download the plugin package: $reason';
  }

  @override
  String pluginsPkgErrFile(String reason) {
    return 'Couldn’t read the file: $reason';
  }

  @override
  String get pluginsPkgNothingNetwork =>
      'Check your connection and try again. Nothing has been installed.';

  @override
  String get pluginsPkgNothing => 'Nothing has been installed.';

  @override
  String get pluginsPkgReasonNetwork => 'network error';

  @override
  String get pluginsPkgReasonTimeout => 'timed out';

  @override
  String pluginsPkgReasonStatus(int status) {
    return 'the server answered $status';
  }

  @override
  String get pluginsPkgReasonTooLarge => 'the package is too large';

  @override
  String get pluginsPkgReasonBlocked => 'the address is blocked';

  @override
  String get pluginsPkgReasonInvalidUrl => 'invalid URL';

  @override
  String get pluginsPkgReasonCancelled => 'cancelled';

  @override
  String get pluginsPkgReasonNotZip => 'not a .zip file';

  @override
  String get pluginsPkgReasonFileLarge => 'the file is too large';

  @override
  String get pluginsPkgReasonUnreadable => 'it can’t be read';

  @override
  String get pluginsPkgReasonFileSlow =>
      'the file provider did not answer in time';

  @override
  String get pluginsPkgErrGone =>
      'This plugin is no longer in its repository’s list.';

  @override
  String get pluginsPkgErrUnexpected =>
      'Something went wrong while checking the package. Nothing has been installed.';

  @override
  String get pluginsPkgErrWrite =>
      'The plugin could not be saved on this device. Nothing has changed.';

  @override
  String get pluginsPkgNoticeStale =>
      'The plugin changed while you were looking. Kanaru checked the package again: review it before installing.';

  @override
  String get pluginsPkgNoticeExpired =>
      'The package waited too long, so Kanaru checked it again.';

  @override
  String get pluginsPkgProTitle => 'Needs Kanaru Pro';

  @override
  String get pluginsPkgFilePickerFailed => 'Couldn’t open the file picker.';

  @override
  String get pluginsProblemTitle => 'Can’t install';

  @override
  String pluginsProblemFileBody(String name) {
    return 'The file $name isn’t a valid plugin.';
  }

  @override
  String pluginsProblemPluginBody(String name) {
    return '$name can’t be installed.';
  }

  @override
  String get pluginsProblemReasons => 'Reasons';

  @override
  String get pluginsProblemHostsNote =>
      'Plugins may only declare public domain names (https).';

  @override
  String get pluginsProblemNewerTitle => 'Needs a newer Kanaru';

  @override
  String pluginsProblemNewerBody(String name) {
    return '$name uses a newer plugin API than this Kanaru supports. Update Kanaru, then install it again.';
  }

  @override
  String pluginsProblemNewerBodyVersion(String name, String version, int max) {
    return '$name uses a newer plugin API than this Kanaru supports (apiVersion $version, this version supports up to $max). Update Kanaru, then install it again.';
  }

  @override
  String get pluginsReasonTooLarge =>
      'The package, or an entry in it, is too large';

  @override
  String get pluginsReasonNotZip => 'The file isn’t a readable zip package';

  @override
  String pluginsReasonUnsafeEntry(String detail) {
    return 'The package has an unsafe entry name ($detail)';
  }

  @override
  String get pluginsReasonTooManyEntries => 'The package has too many files';

  @override
  String get pluginsReasonMissingManifest =>
      'plugin.json not found at the top of the package';

  @override
  String pluginsReasonInvalidManifest(String detail) {
    return '“$detail” in plugin.json is not valid';
  }

  @override
  String get pluginsReasonInvalidManifestPlain => 'plugin.json is not valid';

  @override
  String pluginsReasonUnknownFormat(String detail) {
    return '$detail: this kind of field is not supported';
  }

  @override
  String get pluginsReasonNeedsNewerApp =>
      'Needs a newer Kanaru: the plugin uses a newer plugin API than this version supports';

  @override
  String get pluginsReasonUnsupportedKind =>
      'plugin.json: type is not a kind of plugin this Kanaru runs';

  @override
  String pluginsReasonBadHost(String detail) {
    return 'hosts: “$detail” is not a public domain name';
  }

  @override
  String pluginsReasonBadWildcard(String detail) {
    return 'hosts: “$detail” is not a valid wildcard: write *. and then a public domain name';
  }

  @override
  String pluginsReasonWildcardNotAllowed(String detail) {
    return 'hosts: “$detail”: only music source plugins may use a wildcard host';
  }

  @override
  String pluginsReasonSharedHosting(String detail) {
    return 'hosts: “$detail” covers a shared-hosting domain, where anyone can get a subdomain';
  }

  @override
  String pluginsReasonTooManyWildcards(String detail, int max) {
    return 'hosts: “$detail” is over the limit of $max wildcard hosts';
  }

  @override
  String pluginsReasonMissingScript(String detail) {
    return 'src/$detail not found in the package';
  }

  @override
  String pluginsReasonScriptNotUtf8(String detail) {
    return 'Script $detail is not valid UTF-8';
  }

  @override
  String pluginsReasonScriptError(String detail) {
    return 'Script $detail has an error';
  }

  @override
  String pluginsReasonScriptErrorLine(String detail, int line) {
    return 'Script $detail has an error at line $line';
  }

  @override
  String get pluginsReasonCheckUnavailable =>
      'Kanaru can’t check scripts right now (the plugin runtime did not load), so it can’t tell whether the package is valid';

  @override
  String get pluginsReasonSameVersion =>
      'This package is the same version as the installed one.';

  @override
  String get pluginsReasonOlderVersion =>
      'This package is older than the installed version, so it can’t be used.';

  @override
  String get pluginsReasonKindChange =>
      'This package is another kind of plugin than the installed one, so it can’t be used. Remove the plugin, then install the new one.';

  @override
  String pluginsReasonOtherOrigin(String source) {
    return 'This plugin is already installed from $source. A package from another place can’t replace it: remove the installed plugin, then install again.';
  }

  @override
  String pluginsOriginRepo(String url) {
    return 'repository $url';
  }

  @override
  String pluginsOriginFile(String name) {
    return 'file $name';
  }

  @override
  String get pluginsOriginLink => 'a link';

  @override
  String get pluginsOriginOther => 'another source';

  @override
  String get pluginsMismatchTitle => 'Package doesn’t match the list';

  @override
  String pluginsMismatchBody(String name, String repo) {
    return '$name · Repository: $repo';
  }

  @override
  String get pluginsMismatchDiffs => 'Differences';

  @override
  String get pluginsMismatchKind =>
      'The plugin type of the package differs from the list';

  @override
  String get pluginsMismatchVersion =>
      'The version of the package differs from the list';

  @override
  String get pluginsMismatchHosts =>
      'The hosts of the package differ from the list';

  @override
  String get pluginsMismatchSha =>
      'The checksum (sha256) of the package differs from the list';

  @override
  String get pluginsMismatchSize =>
      'The size of the package differs from the list';

  @override
  String get pluginsMismatchHint =>
      'This usually happens when the repository was just updated and its cache has not caught up. Refresh the list and try again in a few minutes. If it still differs, tell the repository owner.';

  @override
  String get pluginsMismatchRetry => 'Refresh and try again';

  @override
  String get pluginsLinkTitle => 'Install from link';

  @override
  String get pluginsLinkLabel => 'Link to the .zip package';

  @override
  String get pluginsLinkHint => 'https://…/plugin.zip';

  @override
  String get pluginsLinkHelper =>
      'Kanaru downloads the package and checks it, then shows the install screen. Nothing is installed until you tap Install.';

  @override
  String get pluginsLinkHelperCatalog =>
      'This is a plugin list (plugins.json), not a package. Add it as a repository?';

  @override
  String get pluginsLinkErrInvalid => 'Invalid URL';

  @override
  String get pluginsLinkContinue => 'Continue';

  @override
  String get pluginsLinkAddRepo => 'Add repository';

  @override
  String pluginsUpdateAllRunning(int done, int total) {
    return 'Updating $done / $total…';
  }

  @override
  String pluginsUpdateFailedLine(String reason) {
    return 'Couldn’t update: $reason';
  }

  @override
  String get pluginsUpdateReasonProblems => 'the new package is not valid';

  @override
  String get pluginsUpdateReasonGone => 'the plugin or its repository is gone';

  @override
  String get pluginsUpdateReasonNoNewer => 'no newer version';

  @override
  String get pluginsUpdateReasonStorage =>
      'it could not be saved on this device';

  @override
  String get pluginsUpdateReasonPro => 'needs Kanaru Pro';

  @override
  String get pluginsUpdateReasonOther => 'something went wrong';

  @override
  String pluginsUpdateNeedsReview(String name) {
    return 'The new version of $name adds hosts or permissions: tap Review.';
  }

  @override
  String pluginsUpdateAllUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Updated $count plugins',
      one: 'Updated 1 plugin',
    );
    return '$_temp0';
  }

  @override
  String pluginsUpdateAllReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count versions to review (new hosts or permissions): open each one',
      one: '1 version to review (new hosts or permissions): open it',
    );
    return '$_temp0';
  }

  @override
  String pluginsUpdateAllFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count could not be updated',
      one: '1 could not be updated',
    );
    return '$_temp0';
  }

  @override
  String pluginsRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String pluginsRemoveBy(String author, int version) {
    return '$author · version $version';
  }

  @override
  String get pluginsRemoveWillDelete => 'Will be removed';

  @override
  String get pluginsRemoveCode => 'The plugin’s code';

  @override
  String get pluginsRemoveSettings => 'The plugin’s settings';

  @override
  String get pluginsRemoveConfirm => 'Remove';

  @override
  String pluginsRemoved(String name) {
    return 'Removed $name';
  }

  @override
  String pluginsRemoveFailed(String name) {
    return 'Couldn’t remove $name';
  }

  @override
  String get pluginsPkgLoadingTitle => 'Install plugin';

  @override
  String pluginsUpdatedNoVersion(String name) {
    return 'Updated $name';
  }

  @override
  String get pluginsPageTitle => 'Plugin details';

  @override
  String get pluginsPageLoadFailed => 'Couldn’t read the plugin list';

  @override
  String get pluginsPageGone => 'This plugin is no longer installed.';

  @override
  String get pluginsPageToStore => 'Back to the plugin store';

  @override
  String pluginsPageByline(String author, int version) {
    return '$author · version $version';
  }

  @override
  String pluginsPageUpdateTitle(int version) {
    return 'New version $version';
  }

  @override
  String get pluginsPageUpdateBusy => 'Working';

  @override
  String pluginsPageReviewBody(String hosts) {
    return 'The new version also connects to $hosts: look before you update.';
  }

  @override
  String get pluginsPageReviewBodyAny =>
      'The new version adds hosts or permissions: look before you update.';

  @override
  String get pluginsPageReviewButton => 'See the update';

  @override
  String get pluginsPageRefreshList => 'Refresh the list';

  @override
  String pluginsPageNeedsConfigTitle(String name) {
    return '$name needs to be set up';
  }

  @override
  String pluginsPageNeedsConfigBody(String fields) {
    return 'The plugin can’t run until it has: $fields.';
  }

  @override
  String get pluginsPageOpenConfig => 'Open settings';

  @override
  String get pluginsPageBrokenTitle => 'Couldn’t read the plugin’s package';

  @override
  String get pluginsPageBrokenBody =>
      'The plugin’s folder is missing or damaged, so it doesn’t run. Reinstalling keeps its settings and data.';

  @override
  String get pluginsPageBrokenBodyFile =>
      'The plugin’s folder is missing or damaged, so it doesn’t run. This plugin was installed from a file: remove it and install the file again.';

  @override
  String get pluginsPageReinstall => 'Reinstall';

  @override
  String pluginsPageReinstalled(String name) {
    return 'Reinstalled $name';
  }

  @override
  String pluginsPageReinstallFailed(String reason) {
    return 'Couldn’t reinstall: $reason';
  }

  @override
  String get pluginsPageDetails => 'Details';

  @override
  String get pluginsPageFrom => 'Installed from';

  @override
  String pluginsPageFromRepo(String name) {
    return 'Repo: $name';
  }

  @override
  String pluginsPageFromFile(String name) {
    return 'File: $name';
  }

  @override
  String pluginsPageFromLink(String name) {
    return 'Link: $name';
  }

  @override
  String get pluginsPageNoUpdatesFile =>
      'This plugin was installed from a file, so it gets no updates. Remove it and install the new file.';

  @override
  String get pluginsPageNoUpdatesLink =>
      'This plugin was installed from a link, so it gets no updates. Remove it and install the new version.';

  @override
  String pluginsPageWildcardLine(String label, String host) {
    return '$label ($host)';
  }

  @override
  String get pluginsPageNotEntered => '(not entered)';

  @override
  String pluginsPageEndpointLine(String field, String hosts) {
    return 'Address you enter in $field: $hosts';
  }

  @override
  String get pluginsPageInstalledAt => 'Installed';

  @override
  String pluginsPageInstalledDates(String installed, String updated) {
    return '$installed · updated $updated';
  }

  @override
  String get pluginsPageDescription => 'Description';

  @override
  String get pluginsPageType => 'Type';

  @override
  String pluginsPageTypeValue(String kind, int api) {
    return 'Plugin for $kind · plugin API $api';
  }

  @override
  String pluginsPageTypeValueAi(String kind, int api) {
    return 'AI plugin for $kind · plugin API $api';
  }

  @override
  String get pluginsPageSourceCode => 'Source code';

  @override
  String get pluginsPageUseLyrics => 'Find lyrics automatically';

  @override
  String get pluginsPageUseTranslate => 'Default translation service';

  @override
  String get pluginsPageConnection => 'Connection';

  @override
  String get pluginsPageData => 'Data';

  @override
  String get pluginsPageOwnStorage => 'Plugin’s own storage';

  @override
  String get pluginsPageSavedLyrics => 'Lyrics saved from this source';

  @override
  String get pluginsPageTrackCache => 'Track and cover cache';

  @override
  String get pluginsPageLog => 'Log';

  @override
  String get pluginsPageOpen => 'Open';

  @override
  String get pluginsPageBadgeAi => 'AI';

  @override
  String get pluginsRepoAddressCopied => 'Repository address copied';

  @override
  String get pluginsRepoCopyAddress => 'Copy address';

  @override
  String get pluginsCfgReadFailed => 'Couldn’t read the plugin’s settings';

  @override
  String get pluginsCfgRequired => 'This setting is required';

  @override
  String get pluginsCfgNotNumber => 'Enter a number';

  @override
  String get pluginsCfgNotInteger => 'Enter a whole number';

  @override
  String pluginsCfgMin(String min) {
    return 'Must be $min or more';
  }

  @override
  String pluginsCfgMax(String max) {
    return 'Must be $max or less';
  }

  @override
  String pluginsCfgMinLength(String n) {
    return 'Enter at least $n characters';
  }

  @override
  String pluginsCfgMaxLength(String n) {
    return 'Enter at most $n characters';
  }

  @override
  String get pluginsCfgBadUrl => 'Enter an https address';

  @override
  String pluginsCfgTooFew(String n) {
    return 'Choose or add at least $n items';
  }

  @override
  String pluginsCfgTooMany(String n) {
    return 'At most $n items';
  }

  @override
  String get pluginsCfgBadItem => 'One of the items is not valid';

  @override
  String get pluginsCfgBadName =>
      'Enter a name of 1 to 100 characters with no space at either end';

  @override
  String get pluginsCfgDuplicateName => 'Another row already uses this name';

  @override
  String get pluginsCfgRefusedValue =>
      'This setting doesn’t accept that value.';

  @override
  String get pluginsCfgRefusedTooLarge =>
      'The plugin’s settings are too large to save.';

  @override
  String get pluginsCfgRefusedGone =>
      'This setting no longer exists. The plugin may have been removed or changed.';

  @override
  String get pluginsCfgRefusedOther =>
      'Couldn’t save the setting (try again later)';

  @override
  String get pluginsCfgNotChosen => 'Not chosen';

  @override
  String get pluginsCfgNoModel => 'No model';

  @override
  String get pluginsCfgOwnTag => 'Added by you';

  @override
  String get pluginsCfgRemoveModel => 'Remove this model';

  @override
  String get pluginsCfgAddModel => 'Add model…';

  @override
  String get pluginsCfgAddModelTitle => 'Add model';

  @override
  String get pluginsCfgModelNameHint =>
      'Model name, exactly as the server expects it';

  @override
  String get pluginsCfgModelNoteHint =>
      'Note (optional), for example: Ollama at home';

  @override
  String get pluginsCfgAddAndChoose => 'Add and choose';

  @override
  String pluginsCfgMaxChosen(String n) {
    return 'At most $n';
  }

  @override
  String get pluginsCfgAddRow => 'Add';

  @override
  String get pluginsCfgRemoveRow => 'Remove';

  @override
  String get pluginsCfgNameLabel => 'Name';

  @override
  String get pluginsCfgValueLabel => 'Value';

  @override
  String pluginsCfgStepDown(String step) {
    return 'Decrease by $step';
  }

  @override
  String pluginsCfgStepUp(String step) {
    return 'Increase by $step';
  }

  @override
  String pluginsPageUseLyricsOn(int position, int total) {
    return 'In use · $position of $total · change in Settings › Lyrics › Sources';
  }

  @override
  String get pluginsPageUseLyricsOff =>
      'Off: searches only when you tap “Find lyrics online…” · change in Settings › Lyrics › Sources';

  @override
  String pluginsDataStorageValue(int used, int quota) {
    return '$used KB / $quota KB';
  }

  @override
  String get pluginsDataClear => 'Clear';

  @override
  String get pluginsDataClearStorageTitle => 'Clear the plugin’s own storage?';

  @override
  String get pluginsDataClearStorageBody =>
      'The plugin may need to sign in or be set up again.';

  @override
  String get pluginsDataStorageCleared => 'Own storage cleared';

  @override
  String pluginsDataSavedLyricsValue(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0 · $size';
  }

  @override
  String get pluginsDataSavedLyricsNone => 'None yet';

  @override
  String get pluginsDataClearLyricsTitle =>
      'Clear the lyrics saved from this source?';

  @override
  String get pluginsDataClearLyricsBody =>
      'Lyrics saved from this source will be deleted. Pinned lyrics and .lrc files are kept.';

  @override
  String get pluginsDataLyricsCleared => 'Saved lyrics cleared';

  @override
  String get pluginsDataClearFailed => 'Couldn’t clear the data';

  @override
  String pluginsDataLogSummary(int errors, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      errors,
      locale: localeName,
      other: '$errors errors today',
      one: '1 error today',
    );
    String _temp1 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total entries',
      one: '1 entry',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get pluginsDataLogNoErrors => 'No errors';

  @override
  String pluginsPausedTitle(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return 'Paused for $_temp0: the server says too many requests (429)';
  }

  @override
  String pluginsPausedBody(String time) {
    return 'Kanaru asks this source again after $time. Other sources still search as usual.';
  }

  @override
  String get pluginsLogsTitle => 'Log';

  @override
  String get pluginsLogsFilterLabel => 'Filter the log';

  @override
  String get pluginsLogsAll => 'All';

  @override
  String get pluginsLogsErrors => 'Errors';

  @override
  String get pluginsLogsCaption =>
      'Every time the plugin fails or writes to the console. Kanaru hides the settings values, own storage and tokens it knows of. A plugin can still write other information: look before you share.';

  @override
  String pluginsLogsFooter(String path) {
    return 'Kept for the last 7 days (at most 1 MB per plugin). File: $path';
  }

  @override
  String get pluginsLogsEmpty => 'No entries yet';

  @override
  String get pluginsLogsLoadFailed => 'Couldn’t read the log';

  @override
  String get pluginsLogsOpenFolder => 'Open the log folder';

  @override
  String get pluginsLogsOpenFailed => 'Couldn’t open the log folder';

  @override
  String pluginsLogsShareSoon(String soon) {
    return 'Share · $soon';
  }

  @override
  String get pluginsLogsClear => 'Clear the log';

  @override
  String get pluginsLogsClearTitle => 'Clear the plugin’s log?';

  @override
  String pluginsLogsClearBody(String name) {
    return 'The log entries of $name will be deleted. The plugin is not affected.';
  }

  @override
  String get pluginsLogsCleared => 'Log cleared';

  @override
  String pluginsLogsJobTarget(String job, String target) {
    return '$job · $target';
  }

  @override
  String get pluginsLogsResultOk => 'Console output only';

  @override
  String pluginsLogsResultError(String reason) {
    return 'Error: $reason';
  }

  @override
  String pluginsLogsResultErrorWith(String reason, String message) {
    return 'Error: $reason · $message';
  }

  @override
  String get pluginsLogsKindRateLimited => 'too many requests (429)';

  @override
  String get pluginsLogsKindInvalidResponse => 'invalid response';

  @override
  String get pluginsLogsKindServer => 'server error';

  @override
  String get pluginsLogsKindAuth => 'sign-in needed or wrong key';

  @override
  String get pluginsLogsKindQuota => 'quota used up';

  @override
  String get pluginsLogsKindTimeout => 'timed out';

  @override
  String get pluginsLogsKindMemory => 'out of memory';

  @override
  String get pluginsLogsKindStack => 'code nested too deep';

  @override
  String get pluginsLogsKindOutputTooLarge => 'result too large';

  @override
  String get pluginsLogsKindInternal => 'internal error';

  @override
  String pluginsLogsKindOther(String kind) {
    return '$kind';
  }

  @override
  String pluginsRemoveStorage(int size) {
    return 'Own storage ($size KB)';
  }

  @override
  String get pluginsRemoveLog => 'The plugin’s log';

  @override
  String pluginsRemoveKeepLyrics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'Saved lyrics of $_temp0 and pinned lyrics from this source';
  }

  @override
  String get pluginsRemoveKeepPinned =>
      'Pinned lyrics from this source (if any)';

  @override
  String get pluginsRemoveKeepLrc => 'The .lrc files written next to songs';

  @override
  String get pluginsRemoveKeep => 'Kept';

  @override
  String get pluginsPageConnectionRow => 'Requests at once, spacing';

  @override
  String get fontsBuiltInTitle => 'Built in';

  @override
  String get fontsBuiltInHint =>
      'Chinese, Korean and Japanese characters and emoji always use the system font.';

  @override
  String get fontsDefaultSuffix => ' · default';

  @override
  String get fontsSystemFont => 'System font';

  @override
  String get fontsChanged => 'Font changed';

  @override
  String fontsUseFailed(String name) {
    return 'Couldn\'t use the font $name.';
  }

  @override
  String get fontsCatalogTitle => 'Online fonts';

  @override
  String get fontsCatalogHint =>
      'Download once, then use without a connection.';

  @override
  String fontsDownloadTooltip(String name) {
    return 'Download $name';
  }

  @override
  String fontsDeleteTooltip(String name) {
    return 'Delete $name';
  }

  @override
  String get fontsDownloaded => 'Font downloaded';

  @override
  String get fontsDeleted => 'Font deleted (you can download it again)';

  @override
  String fontsDownloadFailed(String name) {
    return 'Couldn\'t download the font $name. Check your connection and try again.';
  }

  @override
  String get fontsCustomTitle => 'Custom';

  @override
  String get fontsCustomHint => 'Fonts you import from a .ttf or .otf file.';

  @override
  String get fontsImportRow => 'Import font';

  @override
  String get fontsImportRowDialog => 'Import font…';

  @override
  String get fontsImportTitle => 'Import font';

  @override
  String get fontsImportBody =>
      'Only import fonts you have the right to use. Kanaru copies the .ttf / .otf file into the app\'s data folder.';

  @override
  String get fontsImportPick => 'Choose file…';

  @override
  String fontsImported(String name) {
    return 'Imported “$name” · tap to use';
  }

  @override
  String get fontsImportTooLarge =>
      'The font file is too large (20 MB at most).';

  @override
  String get fontsImportInvalid => 'This file is not a .ttf or .otf font.';

  @override
  String get fontsImportFileTypes => 'Fonts';

  @override
  String fontsDownloading(String name) {
    return 'Downloading $name';
  }

  @override
  String fontsRemoveTitle(String name) {
    return 'Delete the font “$name”?';
  }

  @override
  String get fontsRemoveBody =>
      'The imported font file is deleted from Kanaru. To use it again you have to import it again.';

  @override
  String get fontsRemoveConfirm => 'Delete';

  @override
  String get fontsRemoved => 'Font deleted';
}
