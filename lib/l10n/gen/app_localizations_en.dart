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
  String get playbackSeekCancel => 'Release to cancel';

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
  String get playbackNoticeRetry => 'Retry';

  @override
  String get playbackNoticeOpenSettings => 'Open settings';

  @override
  String playbackNoticeFailedLink(String title, String source, String code) {
    return 'Could not play “$title”: $source returned no stream link ($code)';
  }

  @override
  String playbackNoticeFailedFormat(String title, String source) {
    return 'Could not play “$title”: Kanaru cannot play $source\'s format yet';
  }

  @override
  String playbackNoticeFailedGone(String title, String source) {
    return 'Skipped “$title”: no longer on $source';
  }

  @override
  String playbackNoticeFailedCode(String title, String code) {
    return 'Could not play “$title” ($code)';
  }

  @override
  String get playbackNoticePausedOffline =>
      'No network: online tracks cannot play';

  @override
  String playbackNoticePausedRateLimited(
    String source,
    String length,
    String time,
  ) {
    return '$source paused for $length (429). Playback can resume in $time.';
  }

  @override
  String playbackNoticePauseEnded(String source) {
    return '$source is no longer paused.';
  }

  @override
  String playbackNoticePauseMinutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String playbackNoticePauseSeconds(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String playbackNoticePausedNeedsConfig(String source) {
    return '$source needs setting up before it can play.';
  }

  @override
  String playbackNoticePausedBusy(String source) {
    return '$source is not answering: paused at this track.';
  }

  @override
  String playbackNoticeSkippedRemoved(String title) {
    return 'Skipped “$title”: its plugin was removed';
  }

  @override
  String playbackNoticeSkippedRemovedMany(String title, String others) {
    return 'Skipped “$title” and $others more: their plugin was removed';
  }

  @override
  String playbackNoticeSkippedLocked(String title) {
    return 'Skipped “$title”: needs Kanaru Pro';
  }

  @override
  String playbackNoticeSkippedLockedMany(String title, String others) {
    return 'Skipped “$title” and $others more: need Kanaru Pro';
  }

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
  String get libraryInfoPath => 'Path';

  @override
  String get libraryInfoPlayCount => 'Plays';

  @override
  String get libraryInfoUnknown => 'Unknown';

  @override
  String get libraryInfoGroupTags => 'Tags';

  @override
  String get libraryInfoGroupAudio => 'Audio';

  @override
  String get libraryInfoGroupFile => 'File';

  @override
  String get libraryInfoGroupYou => 'Yours';

  @override
  String get libraryInfoTitle => 'Title';

  @override
  String get libraryInfoArtist => 'Artist';

  @override
  String get libraryInfoAlbum => 'Album';

  @override
  String get libraryInfoAlbumArtist => 'Album artist';

  @override
  String get libraryInfoGenre => 'Genre';

  @override
  String get libraryInfoComposer => 'Composer';

  @override
  String get libraryInfoReleased => 'Release date';

  @override
  String get libraryInfoTrackNo => 'Track';

  @override
  String get libraryInfoDisc => 'Disc';

  @override
  String get libraryInfoLanguage => 'Language';

  @override
  String get libraryInfoComment => 'Comment';

  @override
  String get libraryInfoDescription => 'Description';

  @override
  String get libraryInfoDuration => 'Duration';

  @override
  String get libraryInfoCodec => 'Codec';

  @override
  String get libraryInfoChannels => 'Channels';

  @override
  String get libraryInfoReplayGain => 'ReplayGain';

  @override
  String get libraryInfoMusicFolder => 'Music folder';

  @override
  String get libraryInfoModified => 'File modified';

  @override
  String get libraryInfoAdded => 'Added';

  @override
  String get libraryInfoFavorite => 'Favorite';

  @override
  String get libraryInfoRating => 'Rating';

  @override
  String get libraryInfoSkips => 'Skipped';

  @override
  String get libraryInfoFirstPlayed => 'First played';

  @override
  String get libraryInfoLastPlayed => 'Last played';

  @override
  String get libraryInfoNeverPlayed => 'Never played';

  @override
  String get libraryInfoFavoriteOn => 'Favorite';

  @override
  String get libraryInfoFavoriteOff => 'Not a favorite';

  @override
  String get libraryInfoUnknownArtist => 'Unknown artist';

  @override
  String get libraryInfoAutoDetected => 'detected';

  @override
  String get libraryInfoThisYear => 'this year';

  @override
  String get libraryInfoMono => 'Mono';

  @override
  String get libraryInfoStereo => 'Stereo';

  @override
  String libraryInfoYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String libraryInfoChannelCount(int count) {
    return '$count channels';
  }

  @override
  String libraryInfoTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String libraryInfoBitrateAverage(int kbps) {
    return '$kbps kbps (average)';
  }

  @override
  String libraryInfoDateWithAge(String date, String age) {
    return '$date · $age';
  }

  @override
  String libraryInfoShowEmpty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count empty fields',
      one: 'Show 1 empty field',
    );
    return '$_temp0';
  }

  @override
  String get libraryInfoHideEmpty => 'Hide empty fields';

  @override
  String get libraryInfoNoEmpty => 'No empty fields';

  @override
  String libraryInfoEmptyBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count empty fields',
      one: '1 empty field',
    );
    return '$_temp0';
  }

  @override
  String get libraryInfoMissingTitle => 'File not found';

  @override
  String libraryInfoMissingBody(String date) {
    return 'Missing since $date. The song stays in the library with what was read last; it returns when the file is back and scanned again.';
  }

  @override
  String get libraryInfoMissingBodyNoDate =>
      'The song stays in the library with what was read last; it returns when the file is back and scanned again.';

  @override
  String get libraryInfoScanErrorTitle => 'Tags could not be read';

  @override
  String get libraryInfoScanErrorBody =>
      'The file is damaged or in a format Kanaru cannot read tags from.';

  @override
  String get libraryInfoTaglessTitle => 'This file has almost no tags';

  @override
  String get libraryInfoTaglessBody =>
      'No artist, album, genre or year. The title comes from the file name. Edit tags in the song menu › Edit song info.';

  @override
  String libraryInfoCopied(String value) {
    return 'Copied: $value';
  }

  @override
  String libraryInfoGoArtist(String name) {
    return 'Open artist page $name';
  }

  @override
  String libraryInfoGoAlbum(String name) {
    return 'Open album page $name';
  }

  @override
  String libraryInfoGoGenre(String name) {
    return 'Open genre page $name';
  }

  @override
  String libraryInfoGoLanguage(String name) {
    return 'Open language page $name';
  }

  @override
  String get libraryInfoMore => 'More options';

  @override
  String get libraryInfoClose => 'Close';

  @override
  String get libraryInfoLoadFailed => 'Could not read the song info';

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
      'AI services, permissions, tools, prompts, history';

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
  String get settingsSeekBarStyleBars => 'Bars';

  @override
  String get settingsSeekBarStyleDots => 'Dots';

  @override
  String get settingsSeekBarStyleLine => 'Line';

  @override
  String get settingsSeekBarStyleMirror => 'Mirror';

  @override
  String get settingsSeekBarStyleSquiggle => 'Squiggle';

  @override
  String get settingsSeekBarFlat => 'Flat bar';

  @override
  String get settingsSeekBarStyleBarsCaption =>
      'Default, compact and easy to read';

  @override
  String get settingsSeekBarStyleDotsCaption =>
      'A column of dots like an LED meter';

  @override
  String get settingsSeekBarStyleLineCaption =>
      'A continuous wave outline, filled in';

  @override
  String get settingsSeekBarStyleMirrorCaption =>
      'Wave on top, a faint reflection below';

  @override
  String get settingsSeekBarStyleSquiggleCaption =>
      'A wavy line that drifts while playing, flat when paused';

  @override
  String get settingsSeekBarFlatCaption => 'Every track, no waveform needed';

  @override
  String get settingsSeekBarPreviewHint =>
      'Tap or drag to try seeking · drag up to cancel';

  @override
  String get settingsSeekBarStylesTitle => 'Style';

  @override
  String get settingsSeekBarStylesHint =>
      'Used in Now Playing and the lyrics screen. The mini player and the player bar keep the flat bar.\n\n★ on Squiggle or Flat bar: the style shown while a track has no waveform yet (being computed, or the source has none), with that style\'s options. The wave grows in place when it arrives. Only one style has the ★.';

  @override
  String settingsSeekBarFallbackUse(String style) {
    return 'Use $style while a track has no waveform';
  }

  @override
  String get settingsSeekBarFallbackActive =>
      'Shown while a track has no waveform';

  @override
  String get settingsSeekBarCustomise => 'Customise';

  @override
  String settingsSeekBarCustomiseTitle(String style) {
    return 'Customise · $style';
  }

  @override
  String get settingsSeekBarCustomiseClose => 'Close';

  @override
  String get settingsSeekBarReset => 'Reset to default';

  @override
  String get settingsSeekBarDriftNote =>
      'A track with no waveform drifts steadily.';

  @override
  String get settingsSeekBarRowDensity => 'Density';

  @override
  String get settingsSeekBarRowPlayed => 'Played colour';

  @override
  String get settingsSeekBarRowRest => 'Unplayed part';

  @override
  String get settingsSeekBarRowFeedback => 'Seek feedback';

  @override
  String get settingsSeekBarRowAmplitude => 'Wave height';

  @override
  String get settingsSeekBarRowWavelength => 'Wave length';

  @override
  String get settingsSeekBarRowMotion => 'Motion';

  @override
  String get settingsSeekBarRowThumb => 'Thumb';

  @override
  String get settingsSeekBarRowThickness => 'Thickness';

  @override
  String get settingsSeekBarRowEffect => 'Effect while playing';

  @override
  String get settingsSeekBarOptLoose => 'Loose';

  @override
  String get settingsSeekBarOptMid => 'Medium';

  @override
  String get settingsSeekBarOptThick => 'Thick';

  @override
  String get settingsSeekBarOptDense => 'Dense';

  @override
  String get settingsSeekBarOptLow => 'Low';

  @override
  String get settingsSeekBarOptHigh => 'High';

  @override
  String get settingsSeekBarOptShort => 'Short';

  @override
  String get settingsSeekBarOptLong => 'Long';

  @override
  String get settingsSeekBarOptThin => 'Thin';

  @override
  String get settingsSeekBarOptSingle => 'One colour';

  @override
  String get settingsSeekBarOptGradient => 'Gradient';

  @override
  String get settingsSeekBarOptByHeight => 'By height';

  @override
  String get settingsSeekBarOptDim => 'Faded';

  @override
  String get settingsSeekBarOptOutline => 'Outline';

  @override
  String get settingsSeekBarOptHidden => 'Hidden';

  @override
  String get settingsSeekBarOptJelly => 'Jelly';

  @override
  String get settingsSeekBarOptLens => 'Magnify';

  @override
  String get settingsSeekBarOptOff => 'Off';

  @override
  String get settingsSeekBarOptDrift => 'Drift';

  @override
  String get settingsSeekBarOptMusic => 'Follow music';

  @override
  String get settingsSeekBarOptStill => 'Still';

  @override
  String get settingsSeekBarOptThumbBar => 'Bar';

  @override
  String get settingsSeekBarOptThumbDot => 'Dot';

  @override
  String get settingsSeekBarOptThumbNone => 'None';

  @override
  String get settingsSeekBarOptShine => 'Shine';

  @override
  String get settingsSeekBarOptComet => 'Comet';

  @override
  String get settingsSeekBarOptSparks => 'Sparks';

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
  String get lyricsSettingsTrAhead => 'Translate ahead';

  @override
  String get lyricsSettingsTrAheadNow => 'Current song only';

  @override
  String get lyricsSettingsAddTrService => 'Add a translation service';

  @override
  String lyricsSettingsTrTargetAppNamed(String name) {
    return 'Follows the app language ($name)';
  }

  @override
  String get lyricsSettingsTrTargetCaption =>
      'Used for songs that have no language of their own.';

  @override
  String get lyricsSettingsTrSize => 'Translation text size';

  @override
  String get lyricsSettingsTrSizeCaption =>
      'The translation line under the lyrics, or the small original line when the translation replaces it. Applies to the lyrics screen, the Lyrics tab and the lyrics card.';

  @override
  String lyricsSettingsTrServiceNeedsConfig(String fields) {
    return 'Needs setup: $fields';
  }

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
  String lyricsToastKept(String plugin) {
    return 'Kept the $plugin copy for this song';
  }

  @override
  String get lyricsToastRefusedAuto => 'Dropped this copy, searching again…';

  @override
  String get lyricsToastRefusedKept => 'Dropped the kept copy';

  @override
  String lyricsToastChosen(String plugin) {
    return 'Chose the lyrics from $plugin for this song';
  }

  @override
  String get lyricsSettingsAutoFindNone =>
      'No lyrics source is on · turn one on below';

  @override
  String lyricsSettingsSourcesCount(int on, int total) {
    return '$on / $total sources on';
  }

  @override
  String get lyricsSettingsSourcesHint =>
      'Order of the search when it runs by itself: drag to sort. A source that is off is only searched when you tap “Search online lyrics…”. A plugin installed from a repository starts on and goes to the end of the list. A plugin installed from a file or a link starts off (searched only when you tap) until you turn it on.';

  @override
  String lyricsSettingsSourceRepo(int version) {
    return 'Plugin · v$version';
  }

  @override
  String lyricsSettingsSourceFile(int version) {
    return 'Installed from a file · v$version';
  }

  @override
  String lyricsSettingsSourceLink(int version) {
    return 'Installed from a link · v$version';
  }

  @override
  String lyricsSettingsSourceOff(String line) {
    return '$line · only searched when you tap';
  }

  @override
  String get lyricsSettingsSourceNeedsConfig =>
      'Needs setup · open the plugin page to fill it in';

  @override
  String lyricsSettingsSourcePaused(String time) {
    return 'Paused until $time';
  }

  @override
  String get lyricsSettingsSourceBroken =>
      'Broken package · open the plugin page';

  @override
  String lyricsSettingsSourceSwitch(String name) {
    return '$name: use for automatic search';
  }

  @override
  String get lyricsSettingsSourceDrag => 'Drag to reorder';

  @override
  String lyricsSettingsSourceOnToast(String name) {
    return '$name: on for automatic search';
  }

  @override
  String lyricsSettingsSourceOffToast(String name) {
    return '$name: off · only searched when you tap';
  }

  @override
  String get lyricsInfoGroup => 'Lyrics';

  @override
  String get lyricsInfoSourceRow => 'Lyrics source';

  @override
  String get lyricsInfoSourceTag => 'In the file\'s tags';

  @override
  String lyricsInfoSourceLrc(String name) {
    return '.lrc file next to the song · $name';
  }

  @override
  String get lyricsInfoSourceLrcBare => '.lrc file next to the song';

  @override
  String lyricsInfoSourceKept(String plugin) {
    return 'Kept online copy · $plugin';
  }

  @override
  String get lyricsInfoNone => 'No lyrics yet';

  @override
  String get lyricsInfoNoneHint =>
      'Add lyrics from the song menu › Lyrics source';

  @override
  String lyricsInfoLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines',
      one: '1 line',
    );
    return '$_temp0';
  }

  @override
  String get lyricsInfoSeeAll => 'See all lyrics';

  @override
  String get lyricsInfoCopy => 'Copy lyrics';

  @override
  String lyricsInfoCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lyrics copied ($count lines)',
      one: 'Lyrics copied (1 line)',
    );
    return '$_temp0';
  }

  @override
  String get lyricsInfoShowStamps => 'Show timestamps';

  @override
  String get lyricsInfoHideStamps => 'Hide timestamps';

  @override
  String get lyricsInfoUnreadable => 'Couldn\'t read the lyrics';

  @override
  String lyricsTranslationCredit(String by, String language) {
    return 'Translated by $by · $language';
  }

  @override
  String lyricsTranslationCreditPartial(
    String by,
    String language,
    int done,
    int total,
  ) {
    return 'Translated by $by · $language · partial $done/$total lines';
  }

  @override
  String lyricsTranslationCreditOther(String plugin) {
    return 'Existing translation from $plugin';
  }

  @override
  String get lyricsLangVi => 'Vietnamese';

  @override
  String get lyricsLangEn => 'English';

  @override
  String get lyricsLangJa => 'Japanese';

  @override
  String get lyricsLangKo => 'Korean';

  @override
  String get lyricsLangZhHans => 'Chinese (Simplified)';

  @override
  String get lyricsLangZhHant => 'Chinese (Traditional)';

  @override
  String get lyricsLangFr => 'French';

  @override
  String get lyricsLangDe => 'German';

  @override
  String get lyricsLangEs => 'Spanish';

  @override
  String get lyricsLangIt => 'Italian';

  @override
  String get lyricsLangRu => 'Russian';

  @override
  String get lyricsLangPt => 'Portuguese';

  @override
  String get lyricsLangTh => 'Thai';

  @override
  String get lyricsLangId => 'Indonesian';

  @override
  String get lyricsLangHi => 'Hindi';

  @override
  String get lyricsLangAr => 'Arabic';

  @override
  String get lyricsLangNl => 'Dutch';

  @override
  String get lyricsLangSv => 'Swedish';

  @override
  String get lyricsLangPl => 'Polish';

  @override
  String get lyricsLangTr => 'Turkish';

  @override
  String get lyricsLangUk => 'Ukrainian';

  @override
  String get lyricsLangCs => 'Czech';

  @override
  String get lyricsLangEl => 'Greek';

  @override
  String get lyricsLangFa => 'Persian';

  @override
  String get lyricsLangRo => 'Romanian';

  @override
  String get lyricsLangMs => 'Malay';

  @override
  String get lyricsLangHe => 'Hebrew';

  @override
  String get lyricsLangFi => 'Finnish';

  @override
  String get lyricsLangDa => 'Danish';

  @override
  String get lyricsLangNo => 'Norwegian';

  @override
  String get lyricsLangHu => 'Hungarian';

  @override
  String get lyricsLangCy => 'Welsh';

  @override
  String get lyricsLangSk => 'Slovak';

  @override
  String get lyricsLangSq => 'Albanian';

  @override
  String get lyricsLangHy => 'Armenian';

  @override
  String get lyricsLangEu => 'Basque';

  @override
  String get lyricsLangMy => 'Burmese';

  @override
  String get lyricsLangKa => 'Georgian';

  @override
  String get lyricsLangIs => 'Icelandic';

  @override
  String get lyricsLangMk => 'Macedonian';

  @override
  String get lyricsLangMi => 'Māori';

  @override
  String get lyricsTranslateTitle => 'Translate lyrics';

  @override
  String get lyricsTranslateSettings => 'Translation settings';

  @override
  String get lyricsTranslatePreview => 'Preview';

  @override
  String get lyricsTranslateDisplay => 'How the translation shows';

  @override
  String get lyricsTranslateDisplayUnder => 'Below line';

  @override
  String get lyricsTranslateDisplayReplace => 'Replace line';

  @override
  String lyricsTranslateBy(String by) {
    return 'Translated by $by';
  }

  @override
  String lyricsTranslateByPartial(String by, int done, int total) {
    return 'Translated by $by · $done/$total lines only';
  }

  @override
  String get lyricsTranslateRedoing =>
      'Translating again, the old translation stays';

  @override
  String get lyricsTranslateRetranslate => 'Translate again';

  @override
  String get lyricsTranslateSection => 'Translation';

  @override
  String get lyricsTranslateSourceAuto => 'Auto-detect';

  @override
  String lyricsTranslateSourceDetected(String language) {
    return '$language · detected';
  }

  @override
  String get lyricsTranslateSourceHint =>
      'Language of the lyrics, detected by the translation service';

  @override
  String get lyricsTranslateSwitch => 'Show translation';

  @override
  String lyricsTranslateTarget(String language) {
    return 'Translate into $language';
  }

  @override
  String get lyricsTranslateNoPluginTitle => 'No translation plugin yet';

  @override
  String get lyricsTranslateNoPluginBody =>
      'Install a translation plugin (Google, DeepL, Gemini…) from the plugin store to translate lyrics.';

  @override
  String get lyricsTranslateOpenStore => 'Open plugin store';

  @override
  String get lyricsTranslateServiceTitle => 'Service';

  @override
  String get lyricsTranslateServiceUnset => 'No service chosen';

  @override
  String get lyricsTranslateServiceGone =>
      'The default service was removed, choose another';

  @override
  String get lyricsTranslateServiceScope => 'Default for every song';

  @override
  String get lyricsTranslateAiTag => 'AI';

  @override
  String get lyricsTranslateTuneTitle => 'AI tuning';

  @override
  String get lyricsTranslatePhoneticSection => 'Transliteration';

  @override
  String get lyricsTranslatePhoneticTitle => 'Furigana, Romaji';

  @override
  String get lyricsTranslatePhoneticDesc =>
      'Transliteration of Japanese, Chinese and Korean lyrics';

  @override
  String get lyricsTranslateSoonTag => 'Coming soon';

  @override
  String get lyricsTranslateWorking => 'Translating…';

  @override
  String lyricsTranslateWorkingCount(int done, int total) {
    return 'Translating… $done/$total lines';
  }

  @override
  String get lyricsTranslateWorkingAgain => 'Translating again…';

  @override
  String lyricsTranslateWorkingAgainCount(int done, int total) {
    return 'Translating again… $done/$total lines';
  }

  @override
  String get lyricsTranslateCancel => 'Cancel';

  @override
  String lyricsTranslateSame(String language, String service) {
    return 'The lyrics already are in $language (per $service)';
  }

  @override
  String lyricsTranslatePartialTitle(int done, int total) {
    return 'Only $done/$total lines translated';
  }

  @override
  String lyricsTranslatePartialLine(String reason) {
    return 'The rest failed: $reason';
  }

  @override
  String lyricsTranslatePausedTitle(String service) {
    return '$service is paused';
  }

  @override
  String lyricsTranslatePausedLine(String time) {
    return 'The server reports too many requests (429) · Kanaru translates again after $time';
  }

  @override
  String lyricsTranslateNetworkTitle(String service) {
    return 'Cannot reach $service';
  }

  @override
  String get lyricsTranslateNetworkLine => 'Network error or timeout';

  @override
  String lyricsTranslateServerTitle(String service) {
    return '$service has an error';
  }

  @override
  String get lyricsTranslateServerLine =>
      'The service\'s server returned an error';

  @override
  String lyricsTranslateQuotaTitle(String service) {
    return '$service is out of quota';
  }

  @override
  String get lyricsTranslateQuotaLine =>
      'This API key has no translations left · wait for the next period or change service';

  @override
  String lyricsTranslateBadKeyTitle(String service) {
    return '$service reports an error';
  }

  @override
  String get lyricsTranslateBadKeyLine => 'The API key is invalid or expired';

  @override
  String lyricsTranslateConfigTitle(String service) {
    return '$service needs to be set up';
  }

  @override
  String lyricsTranslateConfigLine(String fields) {
    return 'Missing: $fields';
  }

  @override
  String get lyricsTranslateInvalidTitle =>
      'The translation has the wrong number of lines';

  @override
  String lyricsTranslateInvalidLine(String service) {
    return '$service returned a different number of lines than the lyrics';
  }

  @override
  String get lyricsTranslateTooLongTitle =>
      'The lyrics are too long to translate';

  @override
  String lyricsTranslateTooLongLine(String service) {
    return 'The lyrics exceed what $service translates in one run';
  }

  @override
  String lyricsTranslateUnsupportedTitle(String service, String language) {
    return '$service does not translate into $language';
  }

  @override
  String get lyricsTranslateUnsupportedLine =>
      'Choose another language or change service';

  @override
  String get lyricsTranslateGoneTitle => 'The translation service was removed';

  @override
  String get lyricsTranslateGoneLine =>
      'Choose another service to keep translating';

  @override
  String get lyricsTranslateUnsetTitle => 'No translation service chosen';

  @override
  String get lyricsTranslateUnsetLine =>
      'The lyrics are sent only after you choose';

  @override
  String lyricsTranslateReasonPaused(String service) {
    return '$service is paused';
  }

  @override
  String lyricsTranslateReasonNetwork(String service) {
    return 'cannot reach $service';
  }

  @override
  String lyricsTranslateReasonServer(String service) {
    return '$service has an error';
  }

  @override
  String lyricsTranslateReasonQuota(String service) {
    return '$service is out of quota';
  }

  @override
  String get lyricsTranslateReasonBadKey => 'the API key is invalid or expired';

  @override
  String lyricsTranslateReasonConfig(String service) {
    return '$service needs to be set up';
  }

  @override
  String get lyricsTranslateReasonInvalid =>
      'the translation had the wrong number of lines';

  @override
  String get lyricsTranslateReasonTooLong =>
      'the lyrics are too long to translate';

  @override
  String lyricsTranslateReasonUnsupported(String service, String language) {
    return '$service does not translate into $language';
  }

  @override
  String get lyricsTranslateReasonGone => 'the service was removed';

  @override
  String get lyricsTranslateReasonNoService => 'no service chosen';

  @override
  String get lyricsTranslateRetry => 'Try again';

  @override
  String get lyricsTranslateConfigure => 'Set up';

  @override
  String get lyricsTranslateChangeService => 'Change service';

  @override
  String get lyricsTranslateChoose => 'Choose';

  @override
  String lyricsTranslateBarOtherLine(String service) {
    return 'Translate again with $service';
  }

  @override
  String get lyricsTranslateBarDiffTitle =>
      'Settings differ from the translation shown';

  @override
  String get lyricsTranslateDiffNote => 'instruction changed';

  @override
  String get lyricsTranslateDiffVersion => 'plugin updated';

  @override
  String lyricsTranslateRetranslated(String name) {
    return 'Translated again · $name';
  }

  @override
  String get lyricsTranslateServicePageTitle => 'Translation service';

  @override
  String get lyricsTranslateServiceSent =>
      'Lyrics, song title and artist are sent to the plugin when translating.';

  @override
  String get lyricsTranslateScopeTitle => 'Apply to';

  @override
  String get lyricsTranslateScopeSong => 'This song';

  @override
  String get lyricsTranslateScopeQueue => 'Queue';

  @override
  String get lyricsTranslateScopeAll => 'Every song';

  @override
  String get lyricsTranslateScopePro =>
      'A service of its own for a song or the queue: a Pro feature';

  @override
  String get lyricsTranslateServiceSection => 'Service';

  @override
  String get lyricsTranslateMoreServices => 'Get more translation plugins';

  @override
  String get lyricsTranslateMoreServicesSub => 'Open plugin store';

  @override
  String get lyricsTranslateTargetTitle => 'Translate into';

  @override
  String get lyricsTranslateTargetApp => 'Follows the app language';

  @override
  String get lyricsTranslateTargetFailed => 'Could not save the language';

  @override
  String get lyricsTranslateModelTitle => 'Model';

  @override
  String get lyricsTranslateStyleTitle => 'Style';

  @override
  String get lyricsTranslateStylePickerTitle => 'Translation style';

  @override
  String get lyricsTranslateNoteTitle => 'Extra instructions';

  @override
  String lyricsTranslateNoteHelper(String plugin) {
    return 'Extra instructions for every song (saved in the settings of $plugin).';
  }

  @override
  String lyricsTranslateSearchHint(int count) {
    return 'Search $count items';
  }

  @override
  String get lyricsTranslateDefaultTag => 'default';

  @override
  String get lyricsTranslateLater => 'Later';

  @override
  String get lyricsTranslateDone => 'Done';

  @override
  String get lyricsTranslateWriteInvalid => 'The value is not valid';

  @override
  String get lyricsTranslateWriteTooLarge => 'The instructions are too long';

  @override
  String get lyricsTranslateWriteUnknown => 'This plugin has no such setting';

  @override
  String get lyricsTranslateWriteFailed => 'Could not save the setting';

  @override
  String lyricsTranslateMenuOn(String language) {
    return 'Translating into $language';
  }

  @override
  String get lyricsTranslateMenuOff => 'Off';

  @override
  String get lyricsTranslateEntryFailed => 'Translation failed';

  @override
  String get lyricsTranslateEntryNoLyrics => 'No lyrics to translate';

  @override
  String get lyricsTranslatePillWorking => 'Translating';

  @override
  String lyricsTranslateToastOn(String language) {
    return 'Translation: $language';
  }

  @override
  String get lyricsTranslateToastOff => 'Translation off';

  @override
  String get lyricsTranslateEntryHintDesktop =>
      'Right-click or T: turn translation on or off';

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
  String get pluginsKindNounLyrics => 'Lyrics plugin';

  @override
  String get pluginsKindNounTranslate => 'Translation plugin';

  @override
  String get pluginsKindNounStreaming => 'Music source plugin';

  @override
  String get pluginsKindNounAiChat => 'AI plugin';

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
  String get pluginsKindAiChat => 'AI chat';

  @override
  String get pluginsKindHelpAiChat =>
      'Connects an AI service you can chat with.';

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
    return '$kind · version $version · $author';
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
    return '$kind · plugin API $api';
  }

  @override
  String pluginsPageTypeValueAi(String kind, int api) {
    return '$kind · AI · plugin API $api';
  }

  @override
  String get pluginsPageSourceCode => 'Source code';

  @override
  String get pluginsPageUseLyrics => 'Find lyrics automatically';

  @override
  String get pluginsPageUseTranslate => 'Default translation service';

  @override
  String get pluginsPageUseTranslateAt =>
      'Change in Settings › Lyrics › Translation';

  @override
  String get pluginsPageUseTranslateHint =>
      'Songs with no service of their own use the default service.';

  @override
  String get pluginsPageUseTranslateIs => 'Default';

  @override
  String get pluginsPageUseTranslateSet => 'Set as default';

  @override
  String get pluginsRemoveKeepTranslations =>
      'Saved translations, until you choose “Delete saved translations”';

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
  String get pluginsLogsKindNetwork => 'network error';

  @override
  String get pluginsLogsKindUnavailable => 'no longer on the source';

  @override
  String get pluginsLogsKindUnsupported => 'not supported';

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

  @override
  String get aiChatPlayContextLabel => 'AI assistant';

  @override
  String get aiChatNewTitle => 'New conversation';

  @override
  String get aiChatMenuTooltip => 'Chat options';

  @override
  String get aiChatMenuHistory => 'Chat history';

  @override
  String get aiChatMenuRename => 'Rename';

  @override
  String get aiChatMenuDelete => 'Delete this conversation';

  @override
  String get aiChatMenuSettings => 'AI settings';

  @override
  String get aiChatRenameField => 'Conversation name';

  @override
  String get aiChatRenameSave => 'Save name';

  @override
  String get aiChatCloseMobile => 'Close chat';

  @override
  String get aiChatClosePanel => 'Close panel (Ctrl+J)';

  @override
  String get aiChatDeleteTitle => 'Delete this conversation?';

  @override
  String get aiChatDeleteBody =>
      'Its messages and attached images are removed from this device. This cannot be undone.';

  @override
  String get aiChatDeleteConfirm => 'Delete';

  @override
  String get aiChatDeleted => 'Conversation deleted';

  @override
  String get aiChatEmptyTitle => 'What do you want to ask about your music?';

  @override
  String get aiChatEmptyBody =>
      'The AI can read your library, the playing song, lyrics and the queue through the tools you turn on in Settings.';

  @override
  String get aiChatGuideTitle => 'Choose an AI service';

  @override
  String get aiChatGuideBody =>
      'Kanaru has no AI server of its own. You use your own service; data goes straight to it.';

  @override
  String get aiChatGuideCloudTitle => 'Cloud service';

  @override
  String get aiChatGuideCloudBody =>
      'Claude, Gemini, OpenAI… Install a plugin, then enter your API key (kept in the plugin\'s settings).';

  @override
  String get aiChatGuideCloudAction => 'Open the AI plugin store';

  @override
  String get aiChatGuideFoot =>
      'Installing a plugin lets it send data to the addresses it declares. The chat does not ask again.';

  @override
  String get aiChatCopy => 'Copy';

  @override
  String get aiChatStopped => 'Stopped';

  @override
  String get aiChatAnswering => 'Answering';

  @override
  String aiChatToolRunning(String name) {
    return 'Running: $name';
  }

  @override
  String get aiChatToolParams => 'Parameters';

  @override
  String get aiChatToolResult => 'Result';

  @override
  String aiChatPluginSwitch(String plugin, String model) {
    return 'From here on: $plugin · $model';
  }

  @override
  String aiChatPluginSwitchNoModel(String plugin) {
    return 'From here on: $plugin';
  }

  @override
  String get aiChatJumpToEnd => 'Jump to the end';

  @override
  String get aiChatMessagesError => 'Could not load this conversation.';

  @override
  String get aiChatMessagesRetry => 'Try again';

  @override
  String get aiChatTrackMenu => 'Song menu';

  @override
  String get aiChatToolPlayTracks => 'Play songs';

  @override
  String get aiChatToolQueueTracks => 'Add to queue';

  @override
  String get aiChatToolRemoveFromQueue => 'Remove from queue';

  @override
  String get aiChatToolListPlaylists => 'List playlists';

  @override
  String get aiChatToolGetPlaylistTracks => 'Playlist songs';

  @override
  String get aiChatToolGetLyrics => 'Lyrics';

  @override
  String get aiChatToolGetListeningStats => 'Listening stats';

  @override
  String get aiChatToolCreatePlaylist => 'Create playlist';

  @override
  String get aiChatToolAddToPlaylist => 'Add to playlist';

  @override
  String get aiChatToolRemoveFromPlaylist => 'Remove from playlist';

  @override
  String get aiChatToolGetNowPlaying => 'Now playing';

  @override
  String get aiChatToolGetQueue => 'Queue';

  @override
  String aiChatToolSummaryList(int shown, int total) {
    final intl.NumberFormat shownNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shownString = shownNumberFormat.format(shown);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$shownString / $totalString songs';
  }

  @override
  String aiChatToolSummaryListMore(int shown, int total) {
    final intl.NumberFormat shownNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shownString = shownNumberFormat.format(shown);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$shownString / $totalString songs · the AI can look further';
  }

  @override
  String aiChatToolSummaryCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String aiChatToolSummaryItems(int shown, int total) {
    final intl.NumberFormat shownNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shownString = shownNumberFormat.format(shown);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$shownString / $totalString items';
  }

  @override
  String aiChatToolSummaryItemsMore(int shown, int total) {
    final intl.NumberFormat shownNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shownString = shownNumberFormat.format(shown);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$shownString / $totalString items · the AI can look further';
  }

  @override
  String aiChatToolSummaryItemsCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get aiChatToolSearchLibrary => 'Search the library';

  @override
  String get aiChatToolGetLibraryOverview => 'Library overview';

  @override
  String get aiChatToolGetTrackInfo => 'Song info';

  @override
  String get aiChatComposerLabel => 'Message';

  @override
  String get aiChatComposerHint => 'Ask about your music…';

  @override
  String get aiChatComposerHintLocked => 'Choose a plugin to continue…';

  @override
  String get aiChatSend => 'Send';

  @override
  String get aiChatStop => 'Stop';

  @override
  String get aiChatStopTools =>
      'Stop (the running tool finishes, later ones do not run)';

  @override
  String aiChatPluginTooltip(String plugin) {
    return 'AI service: $plugin';
  }

  @override
  String get aiChatPluginGone => 'Plugin removed · choose another';

  @override
  String aiChatPermissionTooltip(String mode, String description) {
    return 'Permission: $mode · $description';
  }

  @override
  String aiChatPermissionLabel(String mode) {
    return 'Permission: $mode';
  }

  @override
  String get aiChatPermissionReadOnly => 'Read only';

  @override
  String get aiChatPermissionAsk => 'Ask first';

  @override
  String get aiChatPermissionAuto => 'Automatic';

  @override
  String get aiChatPermissionReadOnlyHint =>
      'Reads and suggests, never changes data';

  @override
  String get aiChatPermissionAskHint => 'Asks before changing anything';

  @override
  String get aiChatPermissionAutoHint => 'Makes changes without asking';

  @override
  String get aiChatPermissionPickerCaption => 'For this conversation only.';

  @override
  String get aiChatModelNeeded => 'Choose a model';

  @override
  String aiChatModelLabel(String model) {
    return 'Model: $model';
  }

  @override
  String get aiChatModelCustom => 'Custom';

  @override
  String get aiChatCapVision => 'Images';

  @override
  String get aiChatCapTools => 'Tools';

  @override
  String aiChatCapUnavailable(String cap) {
    return '$cap: unavailable';
  }

  @override
  String get aiChatPluginPickerTitle => 'AI service';

  @override
  String aiChatModelPickerTitle(String plugin) {
    return 'Model · $plugin';
  }

  @override
  String get aiChatModelPickerCaption => 'Applies from the next message.';

  @override
  String get aiChatPermissionPickerTitle => 'Permission in this chat';

  @override
  String get aiChatPluginPickerCaption =>
      'Applies from the next message. History stays as it is.';

  @override
  String get aiChatPluginPickerAdd => 'Add an AI service…';

  @override
  String get aiChatPluginHasKey => 'API key set';

  @override
  String get aiChatPluginReady => 'Ready';

  @override
  String get aiChatPluginNeedsKey => 'Needs an API key';

  @override
  String get aiChatPluginNeedsModel => 'No model chosen';

  @override
  String get aiChatPluginNeedsConfig => 'Needs setup';

  @override
  String get aiChatNoticeDismiss => 'Dismiss';

  @override
  String get aiChatActionOpenPluginSettings => 'Open plugin settings';

  @override
  String get aiChatActionPickModel => 'Choose a model';

  @override
  String get aiChatActionPickPlugin => 'Choose a plugin';

  @override
  String get aiChatActionFindLyrics => 'Find lyrics for this song';

  @override
  String get aiChatActionCancel => 'Cancel';

  @override
  String get aiChatActionSendShort => 'Send the short version';

  @override
  String get aiChatActionDropChip => 'Remove chip';

  @override
  String get aiChatActionAiSettings => 'AI settings';

  @override
  String aiChatNoticeNeedsKey(String plugin) {
    return '$plugin needs an API key before it can send.';
  }

  @override
  String aiChatNoticeNeedsModel(String plugin) {
    return '$plugin has no model. Choose a model before sending.';
  }

  @override
  String aiChatNoticeNeedsConfig(String plugin, String fields) {
    return '$plugin needs setup: $fields.';
  }

  @override
  String get aiChatNoticeRemoved =>
      'This chat\'s plugin was removed. Choose another plugin to continue.';

  @override
  String aiChatNoticeRemovedNamed(String plugin) {
    return 'Plugin “$plugin” was removed. Choose another plugin to continue.';
  }

  @override
  String aiChatNoticeReinstalled(String plugin) {
    return 'Plugin “$plugin” was removed and installed again. Choose a plugin to continue this chat.';
  }

  @override
  String aiChatNoticeStruckChip(String group) {
    return 'The “$group” tool is off, so this chip cannot be sent.';
  }

  @override
  String aiChatNoticeMissingLyrics(String variable) {
    return 'The playing song has no lyrics, so $variable cannot be filled. Nothing was sent; your text is still here.';
  }

  @override
  String aiChatNoticeMissingPlaying(String variable) {
    return 'Nothing is playing, so $variable cannot be filled. Nothing was sent; your text is still here.';
  }

  @override
  String aiChatNoticeMissingQueue(String variable) {
    return 'The queue is empty, so $variable cannot be filled. Nothing was sent; your text is still here.';
  }

  @override
  String aiChatNoticeGroupOff(String group, String variable) {
    return 'The “$group” tool is off, so $variable cannot be filled. Nothing was sent.';
  }

  @override
  String aiChatNoticeLeftoverInput(String variable) {
    return '$variable is still in the message: type your text in its place, then send. Nothing was sent.';
  }

  @override
  String aiChatNoticeChipUnavailable(String chip) {
    return 'Could not read the data of the chip “$chip”. Nothing was sent.';
  }

  @override
  String aiChatNoticeOversize(String variables, String model) {
    return '$variables is too large to send to $model.';
  }

  @override
  String aiChatNoticeOversizeQueue(String variable, int count, String model) {
    return '$variable has $count songs, over the limit $model accepts.';
  }

  @override
  String aiChatActionSendShortQueue(int count) {
    return 'Send the short version: $count songs around the playing one';
  }

  @override
  String get aiChatNoticeSendFailed =>
      'The message could not be saved. Your text is still here; try again.';

  @override
  String aiChatNoticeNoTools(String model) {
    return '$model does not use tools: the AI only sees variables and chips you attach, it does not read the library itself.';
  }

  @override
  String get aiChatChipNowPlaying => 'Now playing';

  @override
  String aiChatChipNowPlayingNamed(String title) {
    return 'Now playing: $title';
  }

  @override
  String get aiChatChipSong => 'Song';

  @override
  String aiChatChipSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '$count song',
    );
    return '$_temp0';
  }

  @override
  String aiChatChipAlbum(String label) {
    return 'Album: $label';
  }

  @override
  String aiChatChipArtist(String label) {
    return 'Artist: $label';
  }

  @override
  String aiChatChipGenre(String label) {
    return 'Genre: $label';
  }

  @override
  String aiChatChipLanguage(String label) {
    return 'Language: $label';
  }

  @override
  String aiChatChipPlaylist(String label) {
    return 'Playlist: $label';
  }

  @override
  String aiChatChipRemove(String label) {
    return 'Remove chip $label';
  }

  @override
  String get aiChatChipStruckHint => 'This chip\'s tool is off';

  @override
  String get aiChatGroupNowPlaying => 'Now playing';

  @override
  String get aiChatGroupTrackInfo => 'Song info';

  @override
  String get aiChatGroupPlaylists => 'Playlists';

  @override
  String get aiChatGroupLyrics => 'Lyrics';

  @override
  String get aiChatGroupQueue => 'Queue';

  @override
  String get aiChatVarListLabel => 'Insert a variable';

  @override
  String get aiChatVarListTitle =>
      'Insert a variable · the app fills it when you send';

  @override
  String get aiChatPromptsLabel => 'Saved prompts';

  @override
  String get aiChatPromptNoPlaying => 'Nothing is playing';

  @override
  String get aiChatPromptEmptyQueue => 'The queue is empty';

  @override
  String get aiChatCardAllow => 'Allow';

  @override
  String get aiChatCardDeny => 'Decline';

  @override
  String get aiChatCardView => 'View';

  @override
  String get aiChatCardOpenQueue => 'Open queue';

  @override
  String get aiChatCardReplayQueue => 'Play the old queue again';

  @override
  String aiChatCardRetryIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds',
      one: '1 second',
    );
    return 'Try again in $_temp0';
  }

  @override
  String aiChatCardRetryInMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return 'Try again in $_temp0';
  }

  @override
  String aiChatCardRetryInMinutesSeconds(int minutes, int seconds) {
    return 'Try again in $minutes min $seconds s';
  }

  @override
  String aiChatCardRetryAt(String time) {
    return 'Try again at $time';
  }

  @override
  String get aiChatCardCanRetry => 'You can try again now';

  @override
  String aiChatCardAddedFold(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0 added';
  }

  @override
  String aiChatCardRemovedFold(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0 removed';
  }

  @override
  String aiChatCardOldQueueFold(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'Old queue · $_temp0';
  }

  @override
  String aiChatCardMoreTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '+$_temp0';
  }

  @override
  String aiChatCardTrackList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String get aiChatCardTrackGone => 'No longer in the library';

  @override
  String aiChatActCreatePlaylist(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'create playlist “$name” · $_temp0';
  }

  @override
  String aiChatActAddToPlaylist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'add $_temp0 to a playlist';
  }

  @override
  String aiChatActAddToPlaylistNamed(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'add $_temp0 to playlist “$name”';
  }

  @override
  String aiChatActRemoveFromPlaylist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'remove $_temp0 from a playlist';
  }

  @override
  String aiChatActRemoveFromPlaylistNamed(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'remove $_temp0 from playlist “$name”';
  }

  @override
  String aiChatActPlay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'play $_temp0';
  }

  @override
  String aiChatActQueue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'add $_temp0 to the queue';
  }

  @override
  String aiChatActRemoveFromQueue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'remove $_temp0 from the queue';
  }

  @override
  String get aiChatGroupPlay => 'Playback control';

  @override
  String get aiChatGroupQueueEdit => 'Queue edits';

  @override
  String get aiChatGroupPlaylistCreate => 'Playlist creation';

  @override
  String get aiChatGroupPlaylistEdit => 'Playlist edits';

  @override
  String aiChatCardNeedsAllow(String tool) {
    return '$tool · needs your OK';
  }

  @override
  String get aiChatCardAllowedByUser => 'You allowed it';

  @override
  String get aiChatCardAutomatic => 'Automatic';

  @override
  String aiChatCardDoneTitle(String action) {
    return 'Done: $action';
  }

  @override
  String get aiChatCardOldQueueReplaced => 'the old queue was replaced';

  @override
  String aiChatCardGoneFromQueue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0 already gone from the queue';
  }

  @override
  String aiChatCardGoneFromPlaylist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0 already gone from the playlist';
  }

  @override
  String aiChatCardNotInLibrary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0 not in the library';
  }

  @override
  String get aiChatCardDenied => 'Declined';

  @override
  String get aiChatCardDeniedByNewMessage =>
      'Declined (you sent another message)';

  @override
  String get aiChatCardDeniedNotAllowed => 'Declined: no longer allowed';

  @override
  String get aiChatCardExpired => 'Expired';

  @override
  String get aiChatCardSkippedStopped => 'Not run: you stopped it';

  @override
  String get aiChatCardSkipped => 'Not run';

  @override
  String aiChatCardNothingChanged(String action) {
    return '$action · nothing changed';
  }

  @override
  String get aiChatCardExpiredWhy =>
      'The card waited over 24 hours. Ask the AI again if you still want it.';

  @override
  String get aiChatCardWhyReadOnly =>
      'You switched this chat to Read-only before this ran.';

  @override
  String get aiChatCardWhyGroupOff =>
      'You turned this tool group off before this ran.';

  @override
  String get aiChatCardWhyPluginChanged =>
      'This chat\'s plugin changed before this ran.';

  @override
  String get aiChatCardWhyModelChanged =>
      'This chat\'s model changed before this ran.';

  @override
  String get aiChatCardWhyChangedAfterAllow =>
      'This changed after you allowed it, so Kanaru did not run it.';

  @override
  String get aiChatCardWhyNotAllowed => 'This is no longer allowed to run.';

  @override
  String get aiChatCardWhyTooLarge => 'This chat grew too long to send.';

  @override
  String get aiChatCardWhyLimit =>
      'The AI reached its change limit for this message.';

  @override
  String aiChatCardUnknownTitle(String action) {
    return 'Result unknown: $action';
  }

  @override
  String get aiChatCardUnknownClosed =>
      'Kanaru was closed while this was running, so it is not known whether it finished.';

  @override
  String get aiChatCardUnknownTimedOut =>
      'This took too long, so it is not known whether it finished.';

  @override
  String get aiChatCardLookQueue =>
      'Check the queue before asking the AI to do it again.';

  @override
  String get aiChatCardLookPlaylist =>
      'Check the playlist before asking the AI to do it again.';

  @override
  String get aiChatCardLimitTitle =>
      'The AI reached its change limit for this message';

  @override
  String aiChatCardLimitBody(int removed, int added) {
    String _temp0 = intl.Intl.pluralLogic(
      removed,
      locale: localeName,
      other: '$removed songs',
      one: '1 song',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added songs',
      one: '1 song',
    );
    return 'One message may remove at most $_temp0 and add at most $_temp1. Send a new message to continue.';
  }

  @override
  String aiChatCardLimitBodyAction(int removed, int added, String action) {
    String _temp0 = intl.Intl.pluralLogic(
      removed,
      locale: localeName,
      other: '$removed songs',
      one: '1 song',
    );
    String _temp1 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added songs',
      one: '1 song',
    );
    return 'One message may remove at most $_temp0 and add at most $_temp1. “$action” did not run. Send a new message to continue.';
  }

  @override
  String get aiChatErrPluginFallback => 'Plugin';

  @override
  String aiChatErrNetworkTitle(String host) {
    return 'Could not reach $host';
  }

  @override
  String get aiChatErrNetworkTitleNoHost => 'Could not reach the server';

  @override
  String get aiChatErrNetworkBody =>
      'Check your connection and try again. Your message is still here.';

  @override
  String aiChatErrRateTitle(String plugin) {
    return '$plugin is limiting requests';
  }

  @override
  String get aiChatErrRateBody =>
      'The plugin reported error 429 (too many requests). When the countdown ends, tap Try again; Kanaru never resends on its own.';

  @override
  String get aiChatErrRateBodyNoClock =>
      'The plugin reported error 429 (too many requests). Wait a moment, then tap Try again; Kanaru never resends on its own.';

  @override
  String get aiChatErrBusyTitle => 'The previous turn has not stopped yet';

  @override
  String get aiChatErrBusyBody =>
      'Kanaru is still finishing the previous answer. Try again in a moment.';

  @override
  String get aiChatErrBusyStuckTitle =>
      'The previous turn still has not stopped';

  @override
  String get aiChatErrBusyStuckBody =>
      'Tried 3 times and the previous turn has not ended. Restart Kanaru and try again.';

  @override
  String aiChatErrKeyTitle(String plugin) {
    return '$plugin did not accept the API key';
  }

  @override
  String get aiChatErrKeyBody =>
      'The API key is wrong or was revoked. Fix it in the plugin\'s settings, then try again.';

  @override
  String aiChatErrQuotaTitle(String plugin) {
    return 'The $plugin account is out of quota';
  }

  @override
  String get aiChatErrQuotaBody =>
      'Top up or change your plan on the provider\'s site, then try again.';

  @override
  String aiChatErrConfigTitle(String plugin) {
    return 'The settings of $plugin are incomplete';
  }

  @override
  String get aiChatErrConfigBody =>
      'The plugin says a setting is missing. Open its settings, fill it in and try again.';

  @override
  String aiChatErrModelGoneTitle(String model) {
    return 'Model no longer available: $model';
  }

  @override
  String get aiChatErrModelGoneTitleNoModel => 'Model no longer available';

  @override
  String aiChatErrModelGoneBody(String plugin) {
    return '$plugin no longer has this model. Pick another model, then try again.';
  }

  @override
  String get aiChatErrContextTitle =>
      'This conversation is too long for this model';

  @override
  String aiChatErrContextBody(String model) {
    return '$model cannot take more. Start a new conversation to go on; this one stays readable.';
  }

  @override
  String get aiChatErrTooLargeTitle => 'This conversation is too long to send';

  @override
  String get aiChatErrTooLargeBody =>
      'Kanaru shortened the older turns and it is still over the send limit. Start a new conversation, or send a shorter message.';

  @override
  String get aiChatErrBlockedTitle => 'The model will not answer this request';

  @override
  String aiChatErrBlockedBody(String model) {
    return '$model refused (the provider\'s reason). Rephrase it, or change the model in the input box.';
  }

  @override
  String get aiChatErrEmptyTitle => 'The model gave no answer';

  @override
  String aiChatErrEmptyBody(String model) {
    return '$model returned an empty answer. Try again, or change the model in the input box.';
  }

  @override
  String aiChatErrGenericTitle(String plugin) {
    return '$plugin ran into an error';
  }

  @override
  String aiChatErrGenericBody(String code) {
    return 'The service reported an error (code: $code). Try again in a few minutes.';
  }

  @override
  String aiChatErrHostTitle(String host) {
    return 'The plugin is not allowed to call $host';
  }

  @override
  String get aiChatErrHostTitleNoHost =>
      'The plugin is not allowed to call this address';

  @override
  String get aiChatErrHostBody =>
      'This address is not in the list the plugin declared at install, so Kanaru blocks it.';

  @override
  String get aiChatErrUpdatedTitle => 'The plugin was just updated';

  @override
  String aiChatErrUpdatedBody(String plugin) {
    return '$plugin was updated during the answer, so this turn stopped. What was received stays above.';
  }

  @override
  String get aiChatErrRemovedTitle => 'Plugin removed';

  @override
  String aiChatErrRemovedBody(String plugin) {
    return '$plugin was removed during the answer. Pick another plugin to go on.';
  }

  @override
  String get aiChatErrBrokenTitle =>
      'The plugin is broken and needs reinstalling';

  @override
  String aiChatErrBrokenBody(String plugin) {
    return 'The package of $plugin cannot be read. Open the plugin page to reinstall it.';
  }

  @override
  String get aiChatErrTimeoutTitle => 'Timed out';

  @override
  String aiChatErrTimeoutBody(String plugin) {
    return '$plugin sent nothing more, so this turn stopped. What was received stays above.';
  }

  @override
  String get aiChatErrCrashTitle => 'The plugin ran into an error';

  @override
  String aiChatErrCrashBody(String plugin) {
    return '$plugin stopped midway because of an error inside the plugin. Try again; if it repeats, check the plugin\'s log.';
  }

  @override
  String get aiChatErrCutOffTitle =>
      'The answer was cut off when Kanaru closed';

  @override
  String get aiChatErrCutOffBody =>
      'What was received stays above. Kanaru does not resend when it opens; tap Try again to let the AI go on.';

  @override
  String get aiChatErrCutOffBodyEmpty =>
      'Nothing of the answer had arrived when Kanaru closed. Kanaru does not resend when it opens; tap Try again to let the AI answer.';

  @override
  String get aiChatActionOpenPlugin => 'Open plugin';

  @override
  String get aiChatActionChangeModel => 'Change model';

  @override
  String get aiChatHistoryTitle => 'Chat history';

  @override
  String get aiChatHistoryBackPanel => 'Back to the open conversation';

  @override
  String get aiChatHistoryBackPage => 'Back';

  @override
  String get aiChatHistorySearch => 'Search conversations';

  @override
  String get aiChatHistoryToday => 'Today';

  @override
  String get aiChatHistoryWeek => 'Past 7 days';

  @override
  String get aiChatHistoryOlder => 'Older';

  @override
  String get aiChatHistoryPluginRemoved => 'plugin removed';

  @override
  String aiChatHistoryNoMatch(String query) {
    return 'No conversation matches “$query”.';
  }

  @override
  String aiChatHistoryRowOptions(String title) {
    return 'Options for $title';
  }

  @override
  String get aiSetServicesTitle => 'AI services';

  @override
  String get aiSetServicesHint =>
      'Tap a service to open its plugin settings (API key, default model). New chats use the service you picked last in the chat.';

  @override
  String get aiSetServicesEmpty =>
      'No AI service installed. AI chat needs an AI plugin (for example Gemini or OpenAI-compatible) and your own API key.';

  @override
  String get aiSetServiceAdd => 'Add AI service';

  @override
  String aiSetServiceModelLastUsed(String model) {
    return '$model · last used';
  }

  @override
  String get aiSetServiceLastUsed => 'Last used';

  @override
  String get aiSetServiceNeedsKey => 'Needs API key';

  @override
  String aiSetServiceNeedsConfig(String fields) {
    return 'Needs setup: $fields';
  }

  @override
  String aiSetServicesGone(String removed, String next) {
    return 'The service you used last ($removed) was removed. New chats use $next until you pick another service in the chat.';
  }

  @override
  String get aiSetPermTitle => 'Permission';

  @override
  String get aiSetPermRow => 'Default permission for new chats';

  @override
  String get aiSetPermCaption =>
      'Each chat keeps its own permission and you can change it at once in the input box.';

  @override
  String get aiSetPermReadOnly => 'Read only';

  @override
  String get aiSetPermReadOnlyDesc => 'Reads and suggests, never changes data';

  @override
  String get aiSetPermAsk => 'Ask first';

  @override
  String get aiSetPermAskDesc => 'Asks before changing anything · default';

  @override
  String get aiSetPermAuto => 'Automatic';

  @override
  String get aiSetPermAutoDesc => 'Makes changes without asking';

  @override
  String get aiSetInstructionsTitle => 'General instructions';

  @override
  String get aiSetInstructionsHint =>
      'Sent with every chat, to every AI service.';

  @override
  String get aiSetInstructionsPlaceholder =>
      'For example: answer in English, keep it short';

  @override
  String get aiSetToolsTitle => 'Tools';

  @override
  String get aiSetToolsHint =>
      'The AI fetches data through the tools that are on. With a tool off, it does not fetch that data by itself.';

  @override
  String get aiSetToolsGroupRead => 'Read';

  @override
  String get aiSetToolsGroupWrite => 'Changes · follow the chat permission';

  @override
  String get aiSetToolsStatsLocked =>
      'Turn on “Record listening history” in Playback first';

  @override
  String get aiSetToolNowPlaying => 'Now playing';

  @override
  String aiSetToolNowPlayingDesc(String variables) {
    return 'Title, artist, album · variables $variables';
  }

  @override
  String get aiSetToolQueue => 'Queue';

  @override
  String aiSetToolQueueDesc(String variables) {
    return 'Up to 50 songs around the playing one · variable $variables';
  }

  @override
  String get aiSetToolLibrarySearch => 'Search the library';

  @override
  String get aiSetToolLibrarySearchDesc =>
      'Up to 50 results at a time, the AI can ask for more';

  @override
  String get aiSetToolLyrics => 'Lyrics';

  @override
  String aiSetToolLyricsDesc(String variables) {
    return 'Plain text, no timestamps · variable $variables';
  }

  @override
  String get aiSetToolTrackInfo => 'Song info';

  @override
  String get aiSetToolTrackInfoDesc =>
      'Song tags, album, the selected songs · Album and N selected songs cards';

  @override
  String get aiSetToolListeningStats => 'Listening stats';

  @override
  String get aiSetToolListeningStatsDesc => 'History, most played';

  @override
  String get aiSetToolPlaylists => 'Playlist list';

  @override
  String get aiSetToolPlaylistsDesc =>
      'Names, song counts and the songs in each playlist';

  @override
  String get aiSetToolPlayControl => 'Playback control';

  @override
  String get aiSetToolPlayControlDesc => 'Play a song';

  @override
  String get aiSetToolQueueEdit => 'Edit queue';

  @override
  String get aiSetToolQueueEditDesc => 'Add, remove';

  @override
  String get aiSetToolPlaylistCreate => 'Create playlist';

  @override
  String get aiSetToolPlaylistEdit => 'Edit playlist';

  @override
  String get aiSetToolPlaylistEditDesc => 'Add, remove songs';

  @override
  String get aiSetVarBypassTitle => 'Send variables even when a tool is off';

  @override
  String get aiSetVarBypassDesc =>
      'Variables and context cards you send yourself still insert data (lyrics, queue, now playing…) even if its tool is off. A tool that is off then only stops the AI from fetching the data by itself.';

  @override
  String get aiSetAutoTitleDefault => 'Turn on Automatic for new chats?';

  @override
  String get aiSetAutoTitleConversation => 'Turn on Automatic for this chat?';

  @override
  String get aiSetAutoBody =>
      'The AI will create and edit playlists, edit the queue and control playback without asking again. Every change still shows as a “Done” card. There is no undo.';

  @override
  String get aiSetAutoShowAgain => 'Show this again next time';

  @override
  String get aiSetAutoConfirm => 'Turn on Automatic';

  @override
  String get aiSetAutoToastDefault => 'New chats: Automatic';

  @override
  String get aiSetAutoToastConversation => 'This chat: Automatic';

  @override
  String get aiSetAutoToastDefaultQuiet =>
      'New chats: Automatic · will not ask next time (turn it back on in the Confirmation box block)';

  @override
  String get aiSetAutoToastConversationQuiet =>
      'This chat: Automatic · will not ask next time (turn it back on in Settings › AI chat)';

  @override
  String get aiSetTemplateExplainLyricsLabel => 'Explain the lyrics';

  @override
  String aiSetTemplateExplainLyricsBody(String lyrics, String nowPlaying) {
    return 'Explain the lyrics of $nowPlaying: $lyrics';
  }

  @override
  String get aiSetTemplateSimilarSongsLabel => 'Similar songs in my library';

  @override
  String aiSetTemplateSimilarSongsBody(String nowPlaying) {
    return 'Find songs in my library like $nowPlaying';
  }

  @override
  String get aiSetTemplateMoodPlaylistLabel => 'Playlist for a mood';

  @override
  String aiSetTemplateMoodPlaylistBody(String input) {
    return 'Create a playlist for this mood: $input';
  }

  @override
  String get aiSetTemplateSongStoryLabel => 'About this song';

  @override
  String aiSetTemplateSongStoryBody(String nowPlaying) {
    return 'Tell me about $nowPlaying';
  }

  @override
  String get aiSetTemplateTranslateLyricsLabel => 'Translate the lyrics';

  @override
  String aiSetTemplateTranslateLyricsBody(String lyrics, String nowPlaying) {
    return 'Translate the lyrics of $nowPlaying into English: $lyrics';
  }

  @override
  String get aiSetTemplateTasteSummaryLabel => 'Summarise my listening';

  @override
  String get aiSetTemplateTasteSummaryBody =>
      'Summarise my listening habits this month';

  @override
  String get aiSetVarNowPlaying => 'Now playing: title and artist';

  @override
  String get aiSetVarTitle => 'Title of the playing song';

  @override
  String get aiSetVarArtist => 'Artist of the playing song';

  @override
  String get aiSetVarAlbum => 'Album of the playing song';

  @override
  String get aiSetVarLyrics => 'Lyrics of the playing song, plain text';

  @override
  String get aiSetVarQueue =>
      'The queue, up to 50 songs around the playing one';

  @override
  String get aiSetVarInput =>
      'Where you type next: tapping the chip only fills the prompt into the box, with the cursor here';

  @override
  String get aiSetPromptsTitle => 'Prompt templates';

  @override
  String get aiSetPromptsHint =>
      'Shown as chips on the input, in this order. Tap a row to edit.';

  @override
  String get aiSetPromptDrag => 'Drag to reorder';

  @override
  String aiSetPromptSwitch(String label) {
    return 'Show “$label” on the input';
  }

  @override
  String aiSetPromptTap(String label) {
    return '$label, open to edit';
  }

  @override
  String get aiSetPromptBad => 'Broken variable';

  @override
  String aiSetPromptBadLine(String variable) {
    return 'Variable $variable no longer exists · tap to edit';
  }

  @override
  String get aiSetPromptsEmpty =>
      'No prompts yet: the chat input has no prompt chips. Add a prompt, or restore the built-in ones.';

  @override
  String get aiSetPromptAdd => 'Add prompt';

  @override
  String get aiSetPromptRestore => 'Restore default prompts';

  @override
  String get aiSetPromptRestoreDesc =>
      'Only adds back built-in prompts you deleted; edited and your own prompts stay';

  @override
  String aiSetPromptRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added back $count built-in prompts',
      one: 'Added back $count built-in prompt',
    );
    return '$_temp0';
  }

  @override
  String get aiSetPromptRestoredNone => 'No built-in prompt was deleted';

  @override
  String get aiSetHistTitle => 'Chat history';

  @override
  String get aiSetHistLoading => 'Reading chat history…';

  @override
  String get aiSetHistErrorTitle => 'Could not read chat history';

  @override
  String get aiSetHistErrorDesc =>
      'The count and size are not available. Delete all still works.';

  @override
  String get aiSetHistRetry => 'Retry';

  @override
  String aiSetHistCount(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conversations · $size MB',
      one: '$count conversation · $size MB',
    );
    return '$_temp0';
  }

  @override
  String get aiSetHistNone => 'No conversations yet';

  @override
  String get aiSetHistWhere => 'Stored on this device';

  @override
  String get aiSetHistClearTitle => 'Delete all conversations';

  @override
  String get aiSetHistClearDesc =>
      'Prompt templates and settings stay. Cannot be undone';

  @override
  String get aiSetHistClearButton => 'Delete';

  @override
  String get aiSetHistDialogTitle => 'Delete all conversations?';

  @override
  String aiSetHistDialogWhat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count AI conversations',
      one: '$count AI conversation',
    );
    return '$_temp0';
  }

  @override
  String get aiSetHistDialogWhatAll => 'Every AI conversation';

  @override
  String aiSetHistDialogRemoved(String what) {
    return '$what will be deleted from this device.';
  }

  @override
  String get aiSetHistDialogStop => 'The answer in progress will stop.';

  @override
  String get aiSetHistDialogLogs =>
      'The run logs of the AI services are deleted too. Prompt templates and settings stay.';

  @override
  String get aiSetHistDialogUndo => 'Cannot be undone.';

  @override
  String get aiSetHistDialogConfirm => 'Delete all';

  @override
  String get aiSetHistCleared => 'All conversations deleted';

  @override
  String get aiSetConfirmTitle => 'Confirmation box';

  @override
  String get aiSetConfirmRow => 'Ask before turning on Automatic';

  @override
  String get aiSetConfirmDesc =>
      'You turned this box off in the chat: choosing Automatic turns it on at once, without asking. Turn it back on to be asked every time.';

  @override
  String get aiSetConfirmOn => 'Turn on';

  @override
  String get aiSetConfirmToast =>
      'Choosing Automatic in the chat will ask again';

  @override
  String get aiSetPluginUse => 'Use in AI chat';

  @override
  String get aiSetPluginUseDesc =>
      'Pick it in the chat input; new chats use the service picked last.';

  @override
  String get aiSetPluginUseAt => 'Change in Settings › AI chat';

  @override
  String get aiSetRemoveKeepChats =>
      'Chats that used this plugin (readable; pick another plugin to continue)';

  @override
  String get aiSetEdTitleEdit => 'Edit prompt';

  @override
  String get aiSetEdTitleNew => 'New prompt';

  @override
  String get aiSetEdLabel => 'Label';

  @override
  String get aiSetEdLabelPlaceholder => 'e.g. Explain the lyrics';

  @override
  String get aiSetEdLabelHelp => 'Text on the chip in the chat input';

  @override
  String get aiSetEdBodyTitle => 'Prompt';

  @override
  String aiSetEdBodyHint(String input) {
    return 'Kanaru fills in variables when sending; with no data it sends nothing and the text stays in the box. $input is where you type next: tapping a chip with $input only fills the prompt into the box, with the cursor there. There are no custom variables.';
  }

  @override
  String aiSetEdBodyPlaceholder(String nowPlaying, String lyrics) {
    return 'e.g. Explain the lyrics of $nowPlaying: $lyrics';
  }

  @override
  String get aiSetEdBodyHelp =>
      'Sent as your own message when you tap the chip in the chat input.';

  @override
  String get aiSetEdVars => 'Insert variable';

  @override
  String aiSetEdUnknown(String names, String allowed) {
    return 'Variable $names does not exist. You can use: $allowed';
  }

  @override
  String aiSetEdGroupOff(String names, String groups, String setting) {
    return '$names needs the $groups tool, which is off. You can still save; tapping the chip will not send it until the tool is back on, or turn on “$setting”.';
  }

  @override
  String aiSetEdGroupOffBypass(String names, String groups, String setting) {
    return '$names: the $groups tool is off, but the variable is still sent because “$setting” is on.';
  }

  @override
  String get aiSetEdPreviewTitle => 'Preview';

  @override
  String get aiSetEdPreviewHint =>
      'Filled with sample data (the song Blinding Lights), not the playing song. When you tap the chip, Kanaru fills in the real data when sending.';

  @override
  String get aiSetEdPreviewEmpty => 'Type the prompt above to preview it.';

  @override
  String get aiSetEdPreviewUnknown => 'No such variable';

  @override
  String aiSetEdPreviewOff(String variable, String group) {
    return '$variable · the “$group” tool is off';
  }

  @override
  String get aiSetEdSampleNowPlaying => 'Blinding Lights · The Weeknd';

  @override
  String get aiSetEdSampleTitle => 'Blinding Lights';

  @override
  String get aiSetEdSampleArtist => 'The Weeknd';

  @override
  String get aiSetEdSampleAlbum => 'After Hours';

  @override
  String get aiSetEdSampleLyrics => '‹lyrics of Blinding Lights · 42 lines›';

  @override
  String get aiSetEdSampleQueue => '‹queue · 12 songs›';

  @override
  String get aiSetEdSampleInput => '‹what you type›';

  @override
  String get aiSetEdDeleteRow => 'Delete prompt';

  @override
  String aiSetEdDeleteBuiltinDesc(String restore) {
    return 'Built-in prompt: “$restore” adds the original back';
  }

  @override
  String aiSetEdDeleteTitle(String label) {
    return 'Delete the prompt “$label”?';
  }

  @override
  String aiSetEdDeleteBodyBuiltin(String restore) {
    return 'This is a built-in prompt: “$restore” adds the original back, but your edits are lost.';
  }

  @override
  String get aiSetEdDeleteBodyCustom =>
      'The chip of this prompt disappears from the chat input. This cannot be undone.';

  @override
  String get aiSetEdDeleteConfirm => 'Delete';

  @override
  String aiSetEdDeleted(String label) {
    return 'Deleted “$label”';
  }

  @override
  String aiSetEdSaved(String label) {
    return 'Saved “$label”';
  }

  @override
  String get aiSetEdCancel => 'Cancel';

  @override
  String get aiSetEdSave => 'Save';

  @override
  String get aiSetEdDiscardTitle => 'Discard changes?';

  @override
  String get aiSetEdDiscardBody => 'The changes to this prompt are not saved.';

  @override
  String get aiSetEdDiscardKeep => 'Keep editing';

  @override
  String get aiSetEdDiscardConfirm => 'Discard';

  @override
  String get onlineTitle => 'Online';

  @override
  String onlineSearchTooltip(String source) {
    return 'Search $source or paste a link';
  }

  @override
  String get onlineNoSourceTitle => 'No online sources yet.';

  @override
  String get onlineNoSourceMessage =>
      'Install a music source plugin (Audius, ZingMP3, Radio Browser…) to search and play music online.';

  @override
  String get onlineAddSource => 'Add a music source';

  @override
  String get onlineOfflineTitle => 'No network.';

  @override
  String get onlineOfflineMessage =>
      'Online needs a network. Music on this device still plays from Library.';

  @override
  String get onlineRetry => 'Retry';

  @override
  String onlineRetryIn(String time) {
    return 'Retry in $time';
  }

  @override
  String onlineServerDownTitle(String source) {
    return 'Could not reach $source.';
  }

  @override
  String get onlineServerDownMessage =>
      'The source\'s server is not answering. Try again in a few minutes.';

  @override
  String onlineNeedsConfigTitle(String field) {
    return 'Needs setting up: $field';
  }

  @override
  String onlineNeedsConfigMessage(String source) {
    return '$source needs this field before it can load anything.';
  }

  @override
  String get onlineOpenPluginSettings => 'Open plugin settings';

  @override
  String onlineRateLimitedTitle(String length) {
    return 'Paused for $length: the server reported too many requests (429)';
  }

  @override
  String get onlineRateLimitedMessage => 'Showing what was loaded before.';

  @override
  String onlineInvalidDataTitle(String source) {
    return '$source returned data Kanaru cannot read';
  }

  @override
  String get onlineInvalidDataMessage =>
      'The source\'s site may have changed. A plugin update usually fixes this.';

  @override
  String get onlineCheckUpdates => 'Check for updates';
}
