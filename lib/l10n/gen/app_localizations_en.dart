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
}
