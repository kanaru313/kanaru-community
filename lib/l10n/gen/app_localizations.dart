import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get navPlaylists;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get navOnline;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @emptyHome.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet. Your music will show up here.'**
  String get emptyHome;

  /// No description provided for @emptyLibrary.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty.'**
  String get emptyLibrary;

  /// No description provided for @emptyPlaylists.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet.'**
  String get emptyPlaylists;

  /// No description provided for @emptySearch.
  ///
  /// In en, this message translates to:
  /// **'Search your music.'**
  String get emptySearch;

  /// No description provided for @emptyOnline.
  ///
  /// In en, this message translates to:
  /// **'No online sources yet.'**
  String get emptyOnline;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsNativeVersions.
  ///
  /// In en, this message translates to:
  /// **'Native libraries'**
  String get settingsNativeVersions;

  /// No description provided for @settingsNoSections.
  ///
  /// In en, this message translates to:
  /// **'No other settings yet.'**
  String get settingsNoSections;

  /// No description provided for @proBadge.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get proBadge;

  /// No description provided for @tooltipToggleSidebar.
  ///
  /// In en, this message translates to:
  /// **'Show or hide the sidebar'**
  String get tooltipToggleSidebar;

  /// No description provided for @tooltipBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tooltipBack;

  /// No description provided for @tooltipForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get tooltipForward;

  /// No description provided for @tooltipHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tooltipHome;

  /// No description provided for @appComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get appComingSoon;

  /// No description provided for @appKeymap.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get appKeymap;

  /// No description provided for @appAiChat.
  ///
  /// In en, this message translates to:
  /// **'AI chat'**
  String get appAiChat;

  /// No description provided for @appSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get appSearch;

  /// No description provided for @appRescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan library'**
  String get appRescan;

  /// No description provided for @scanSetupWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Kanaru'**
  String get scanSetupWelcomeTitle;

  /// No description provided for @scanSetupWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A few basics to set up. You can change them in Settings at any time.'**
  String get scanSetupWelcomeSubtitle;

  /// No description provided for @scanSetupPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get scanSetupPermissionsTitle;

  /// No description provided for @scanSetupPermissionAudioTitle.
  ///
  /// In en, this message translates to:
  /// **'Music and audio'**
  String get scanSetupPermissionAudioTitle;

  /// No description provided for @scanSetupPermissionAudioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find and play songs on the device, read .lrc lyrics'**
  String get scanSetupPermissionAudioSubtitle;

  /// No description provided for @scanSetupPermissionImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos and videos'**
  String get scanSetupPermissionImagesTitle;

  /// No description provided for @scanSetupPermissionImagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only to read cover art (cover.jpg) in music folders. Kanaru does not look at your photos or videos.'**
  String get scanSetupPermissionImagesSubtitle;

  /// No description provided for @scanSetupPermissionAllowedLabel.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get scanSetupPermissionAllowedLabel;

  /// No description provided for @scanSetupPermissionMissingLabel.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get scanSetupPermissionMissingLabel;

  /// No description provided for @scanSetupPermissionsGranted.
  ///
  /// In en, this message translates to:
  /// **'All permissions allowed · Music and audio · Photos and videos'**
  String get scanSetupPermissionsGranted;

  /// No description provided for @scanSetupGrant.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get scanSetupGrant;

  /// No description provided for @scanSetupGrantMissing.
  ///
  /// In en, this message translates to:
  /// **'Allow the missing permission'**
  String get scanSetupGrantMissing;

  /// No description provided for @scanSetupOpenAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get scanSetupOpenAppSettings;

  /// No description provided for @scanSetupPermissionNote.
  ///
  /// In en, this message translates to:
  /// **'Both are needed to continue. Kanaru does not ask for “All files access”.'**
  String get scanSetupPermissionNote;

  /// No description provided for @scanSetupPermissionBlockedNote.
  ///
  /// In en, this message translates to:
  /// **'Android will not ask again because the permission was denied several times. Turn on both permissions in Settings › Apps › Kanaru › Permissions, then come back here.'**
  String get scanSetupPermissionBlockedNote;

  /// No description provided for @scanSetupAudioDenied.
  ///
  /// In en, this message translates to:
  /// **'Music permission is needed to find songs on the device.'**
  String get scanSetupAudioDenied;

  /// No description provided for @scanSetupImagesDenied.
  ///
  /// In en, this message translates to:
  /// **'Photos permission is needed to read cover art in music folders.'**
  String get scanSetupImagesDenied;

  /// No description provided for @scanSetupImagesLimited.
  ///
  /// In en, this message translates to:
  /// **'Choosing only some photos cannot read cover.jpg: choose “Allow all”.'**
  String get scanSetupImagesLimited;

  /// No description provided for @scanSetupAppearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get scanSetupAppearanceTitle;

  /// No description provided for @scanSetupThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get scanSetupThemeLabel;

  /// No description provided for @scanSetupLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get scanSetupLanguageLabel;

  /// No description provided for @scanSetupThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get scanSetupThemeSystem;

  /// No description provided for @scanSetupThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get scanSetupThemeDark;

  /// No description provided for @scanSetupThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get scanSetupThemeLight;

  /// No description provided for @scanSetupLanguageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get scanSetupLanguageVietnamese;

  /// No description provided for @scanSetupLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get scanSetupLanguageEnglish;

  /// No description provided for @scanSetupTabsTitle.
  ///
  /// In en, this message translates to:
  /// **'Library tabs'**
  String get scanSetupTabsTitle;

  /// No description provided for @scanSetupTabsHint.
  ///
  /// In en, this message translates to:
  /// **'Turn on the tabs you want, drag to reorder. At least one tab stays on.'**
  String get scanSetupTabsHint;

  /// No description provided for @scanSetupTabShow.
  ///
  /// In en, this message translates to:
  /// **'Show the {tab} tab'**
  String scanSetupTabShow(String tab);

  /// No description provided for @scanSetupTabDrag.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get scanSetupTabDrag;

  /// No description provided for @scanSetupTabLocked.
  ///
  /// In en, this message translates to:
  /// **'At least one tab stays on'**
  String get scanSetupTabLocked;

  /// No description provided for @scanSetupFoldersTitle.
  ///
  /// In en, this message translates to:
  /// **'Music folders'**
  String get scanSetupFoldersTitle;

  /// No description provided for @scanSetupFoldersHint.
  ///
  /// In en, this message translates to:
  /// **'Kanaru scans these folders and everything inside them.'**
  String get scanSetupFoldersHint;

  /// No description provided for @scanSetupFoldersHintCount.
  ///
  /// In en, this message translates to:
  /// **'Kanaru scans these folders · about {count, plural, =1{1 song} other{{count} songs}}'**
  String scanSetupFoldersHintCount(int count);

  /// No description provided for @scanSetupFoldersNeedPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow music access to see the folders that have music.'**
  String get scanSetupFoldersNeedPermission;

  /// No description provided for @scanSetupFoldersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No folder chosen yet.'**
  String get scanSetupFoldersEmpty;

  /// No description provided for @scanSetupFoldersNoSystemMusic.
  ///
  /// In en, this message translates to:
  /// **'Kanaru could not find the system Music folder. Add the folder that holds your music.'**
  String get scanSetupFoldersNoSystemMusic;

  /// No description provided for @scanSetupAddFolder.
  ///
  /// In en, this message translates to:
  /// **'Add folder'**
  String get scanSetupAddFolder;

  /// No description provided for @scanSetupAddFolderDialog.
  ///
  /// In en, this message translates to:
  /// **'Add folder…'**
  String get scanSetupAddFolderDialog;

  /// No description provided for @scanSetupFolderSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get scanSetupFolderSuggested;

  /// No description provided for @scanSetupFolderRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String scanSetupFolderRemove(String name);

  /// No description provided for @scanSetupFolderSongs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}}'**
  String scanSetupFolderSongs(int count);

  /// No description provided for @scanSetupFolderPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add music folders'**
  String get scanSetupFolderPickerTitle;

  /// No description provided for @scanSetupFolderPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Folders with music that Android found.'**
  String get scanSetupFolderPickerHint;

  /// No description provided for @scanSetupFolderPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'Every folder with music is already chosen.'**
  String get scanSetupFolderPickerEmpty;

  /// No description provided for @scanSetupSheetAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get scanSetupSheetAdd;

  /// No description provided for @scanSetupSheetAddCount.
  ///
  /// In en, this message translates to:
  /// **'Add {count}'**
  String scanSetupSheetAddCount(int count);

  /// No description provided for @scanSetupSheetCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get scanSetupSheetCancel;

  /// No description provided for @scanSetupExclusionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Excluded'**
  String get scanSetupExclusionsTitle;

  /// No description provided for @scanSetupExclusionsHint.
  ///
  /// In en, this message translates to:
  /// **'Skip these sub-folders when scanning (ringtones, recordings…).'**
  String get scanSetupExclusionsHint;

  /// No description provided for @scanSetupExclusionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No folder excluded.'**
  String get scanSetupExclusionsEmpty;

  /// No description provided for @scanSetupAddExclusion.
  ///
  /// In en, this message translates to:
  /// **'Add excluded folder'**
  String get scanSetupAddExclusion;

  /// No description provided for @scanSetupAddExclusionDialog.
  ///
  /// In en, this message translates to:
  /// **'Add excluded folder…'**
  String get scanSetupAddExclusionDialog;

  /// No description provided for @scanSetupExclusionPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Exclude folders'**
  String get scanSetupExclusionPickerTitle;

  /// No description provided for @scanSetupExclusionPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Sub-folders of the music folders you chose.'**
  String get scanSetupExclusionPickerHint;

  /// No description provided for @scanSetupExclusionPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no sub-folders to exclude.'**
  String get scanSetupExclusionPickerEmpty;

  /// No description provided for @scanSetupRefusedAlreadyChosen.
  ///
  /// In en, this message translates to:
  /// **'“{folder}” is already chosen.'**
  String scanSetupRefusedAlreadyChosen(String folder);

  /// No description provided for @scanSetupRefusedInside.
  ///
  /// In en, this message translates to:
  /// **'“{folder}” is already inside “{root}”.'**
  String scanSetupRefusedInside(String folder, String root);

  /// No description provided for @scanSetupRefusedContains.
  ///
  /// In en, this message translates to:
  /// **'“{folder}” contains “{root}”, which is already chosen.'**
  String scanSetupRefusedContains(String folder, String root);

  /// No description provided for @scanSetupRefusedTooBroad.
  ///
  /// In en, this message translates to:
  /// **'“{folder}” is too broad to scan.'**
  String scanSetupRefusedTooBroad(String folder);

  /// No description provided for @scanSetupRefusedNotFolder.
  ///
  /// In en, this message translates to:
  /// **'“{folder}” is not a folder.'**
  String scanSetupRefusedNotFolder(String folder);

  /// No description provided for @scanSetupRefusedOutside.
  ///
  /// In en, this message translates to:
  /// **'“{folder}” is not inside a music folder.'**
  String scanSetupRefusedOutside(String folder);

  /// No description provided for @scanSetupRefusedAlreadyExcluded.
  ///
  /// In en, this message translates to:
  /// **'“{folder}” is already excluded.'**
  String scanSetupRefusedAlreadyExcluded(String folder);

  /// No description provided for @scanSetupWriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save that change. Try again.'**
  String get scanSetupWriteFailed;

  /// No description provided for @scanSetupNext.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get scanSetupNext;

  /// No description provided for @scanSetupNextDisabled.
  ///
  /// In en, this message translates to:
  /// **'Add at least one music folder'**
  String get scanSetupNextDisabled;

  /// No description provided for @scanSetupLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this section.'**
  String get scanSetupLoadFailed;

  /// No description provided for @scanSetupRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get scanSetupRetry;

  /// No description provided for @scanVolumeInternal.
  ///
  /// In en, this message translates to:
  /// **'Internal storage'**
  String get scanVolumeInternal;

  /// No description provided for @scanVolumeSdCard.
  ///
  /// In en, this message translates to:
  /// **'SD card'**
  String get scanVolumeSdCard;

  /// No description provided for @scanVolumeUsb.
  ///
  /// In en, this message translates to:
  /// **'USB drive'**
  String get scanVolumeUsb;

  /// No description provided for @scanHomeScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning the library'**
  String get scanHomeScanning;

  /// No description provided for @scanHomeProgress.
  ///
  /// In en, this message translates to:
  /// **'Reading tags and covers · {done} / {total} songs'**
  String scanHomeProgress(int done, int total);

  /// No description provided for @scanHomeAdded.
  ///
  /// In en, this message translates to:
  /// **'{added, plural, =1{Added 1 song} other{Added {added} songs}}'**
  String scanHomeAdded(int added);

  /// No description provided for @scanHomeAddedDetail.
  ///
  /// In en, this message translates to:
  /// **'{albums, plural, =1{1 album} other{{albums} albums}} · {artists, plural, =1{1 artist} other{{artists} artists}}'**
  String scanHomeAddedDetail(int albums, int artists);

  /// No description provided for @scanHomeNoTracks.
  ///
  /// In en, this message translates to:
  /// **'No songs found'**
  String get scanHomeNoTracks;

  /// No description provided for @playbackCover.
  ///
  /// In en, this message translates to:
  /// **'Cover art'**
  String get playbackCover;

  /// No description provided for @playbackNavQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get playbackNavQueue;

  /// No description provided for @playbackPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playbackPlay;

  /// No description provided for @playbackPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get playbackPause;

  /// No description provided for @playbackNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get playbackNext;

  /// No description provided for @playbackPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get playbackPrevious;

  /// No description provided for @playbackShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get playbackShuffle;

  /// No description provided for @playbackRepeatOff.
  ///
  /// In en, this message translates to:
  /// **'Stop at the end'**
  String get playbackRepeatOff;

  /// No description provided for @playbackRepeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeat this song'**
  String get playbackRepeatOne;

  /// No description provided for @playbackRepeatTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Repeat this song 1 more time} other{Repeat this song {count} more times}}'**
  String playbackRepeatTimes(int count);

  /// No description provided for @playbackRepeatAll.
  ///
  /// In en, this message translates to:
  /// **'Repeat the whole queue'**
  String get playbackRepeatAll;

  /// No description provided for @playbackRepeatAllShuffled.
  ///
  /// In en, this message translates to:
  /// **'Repeat the whole queue, reshuffled every pass'**
  String get playbackRepeatAllShuffled;

  /// No description provided for @playbackRepeatFewer.
  ///
  /// In en, this message translates to:
  /// **'One time fewer'**
  String get playbackRepeatFewer;

  /// No description provided for @playbackRepeatMore.
  ///
  /// In en, this message translates to:
  /// **'One time more'**
  String get playbackRepeatMore;

  /// No description provided for @playbackFavoriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get playbackFavoriteAdd;

  /// No description provided for @playbackFavoriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get playbackFavoriteRemove;

  /// No description provided for @playbackSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get playbackSleepTimer;

  /// No description provided for @playbackLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get playbackLyrics;

  /// No description provided for @playbackVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get playbackVolume;

  /// No description provided for @playbackMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get playbackMute;

  /// No description provided for @playbackUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get playbackUnmute;

  /// No description provided for @playbackExpand.
  ///
  /// In en, this message translates to:
  /// **'Open Now Playing'**
  String get playbackExpand;

  /// No description provided for @playbackOpenNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Open Now Playing'**
  String get playbackOpenNowPlaying;

  /// No description provided for @playbackPlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get playbackPlayer;

  /// No description provided for @playbackSeek.
  ///
  /// In en, this message translates to:
  /// **'Playback position'**
  String get playbackSeek;

  /// No description provided for @playbackPositionValue.
  ///
  /// In en, this message translates to:
  /// **'{position} of {duration}'**
  String playbackPositionValue(String position, String duration);

  /// No description provided for @playbackNoticeSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped “{title}”: file is gone'**
  String playbackNoticeSkipped(String title);

  /// No description provided for @playbackNoticeSkippedMany.
  ///
  /// In en, this message translates to:
  /// **'Skipped “{title}” and {others} more: files are gone'**
  String playbackNoticeSkippedMany(String title, String others);

  /// No description provided for @playbackNoticeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not play “{title}”'**
  String playbackNoticeFailed(String title);

  /// No description provided for @playbackNoticeFirstTrack.
  ///
  /// In en, this message translates to:
  /// **'This is the first track'**
  String get playbackNoticeFirstTrack;

  /// No description provided for @playbackNoticeQueueEnd.
  ///
  /// In en, this message translates to:
  /// **'End of the queue'**
  String get playbackNoticeQueueEnd;

  /// No description provided for @playbackNoticeQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'The queue is empty'**
  String get playbackNoticeQueueEmpty;

  /// No description provided for @playbackNoticeFocusDenied.
  ///
  /// In en, this message translates to:
  /// **'Could not play: another app is using the audio'**
  String get playbackNoticeFocusDenied;

  /// No description provided for @playbackSidebarOpen.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get playbackSidebarOpen;

  /// No description provided for @playbackSidebarClose.
  ///
  /// In en, this message translates to:
  /// **'Close menu'**
  String get playbackSidebarClose;

  /// No description provided for @playbackQueueMobileCounts.
  ///
  /// In en, this message translates to:
  /// **'{position}/{total} · {remaining} left'**
  String playbackQueueMobileCounts(int position, int total, String remaining);

  /// No description provided for @playbackRemainingHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String playbackRemainingHoursMinutes(int hours, int minutes);

  /// No description provided for @playbackRemainingMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String playbackRemainingMinutes(int minutes);

  /// No description provided for @playbackRemainingUnderMinute.
  ///
  /// In en, this message translates to:
  /// **'under 1 min'**
  String get playbackRemainingUnderMinute;

  /// No description provided for @playbackMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get playbackMore;

  /// No description provided for @playbackMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimise'**
  String get playbackMinimize;

  /// No description provided for @playbackQueueSelectMany.
  ///
  /// In en, this message translates to:
  /// **'Select several'**
  String get playbackQueueSelectMany;

  /// No description provided for @playbackQueueAddTracks.
  ///
  /// In en, this message translates to:
  /// **'Add tracks'**
  String get playbackQueueAddTracks;

  /// No description provided for @playbackQueueCleanup.
  ///
  /// In en, this message translates to:
  /// **'Clean up'**
  String get playbackQueueCleanup;

  /// No description provided for @playbackQueueSavePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Save as playlist'**
  String get playbackQueueSavePlaylist;

  /// No description provided for @playbackQueueCleanupTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get playbackQueueCleanupTitle;

  /// No description provided for @playbackCleanupDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Duplicate tracks'**
  String get playbackCleanupDuplicates;

  /// No description provided for @playbackCleanupBefore.
  ///
  /// In en, this message translates to:
  /// **'Earlier tracks'**
  String get playbackCleanupBefore;

  /// No description provided for @playbackCleanupAfter.
  ///
  /// In en, this message translates to:
  /// **'Later tracks'**
  String get playbackCleanupAfter;

  /// No description provided for @playbackCleanupAll.
  ///
  /// In en, this message translates to:
  /// **'All except the current track'**
  String get playbackCleanupAll;

  /// No description provided for @playbackQueueLocate.
  ///
  /// In en, this message translates to:
  /// **'Go to current track'**
  String get playbackQueueLocate;

  /// No description provided for @playbackQueueReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get playbackQueueReorder;

  /// No description provided for @playbackQueueRemovedOne.
  ///
  /// In en, this message translates to:
  /// **'Removed “{title}”'**
  String playbackQueueRemovedOne(String title);

  /// No description provided for @playbackQueueRemovedMany.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Removed 1 track} other{Removed {count} tracks}}'**
  String playbackQueueRemovedMany(int count);

  /// No description provided for @playbackUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get playbackUndo;

  /// No description provided for @playbackRowPlay.
  ///
  /// In en, this message translates to:
  /// **'Play this track'**
  String get playbackRowPlay;

  /// No description provided for @playbackRowPlayNext.
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get playbackRowPlayNext;

  /// No description provided for @playbackGoAlbum.
  ///
  /// In en, this message translates to:
  /// **'Go to album'**
  String get playbackGoAlbum;

  /// No description provided for @playbackGoArtist.
  ///
  /// In en, this message translates to:
  /// **'Go to artist'**
  String get playbackGoArtist;

  /// No description provided for @playbackAskAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get playbackAskAi;

  /// No description provided for @playbackRemoveFromQueue.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get playbackRemoveFromQueue;

  /// No description provided for @playbackQueueStale.
  ///
  /// In en, this message translates to:
  /// **'That track is no longer in the queue'**
  String get playbackQueueStale;

  /// No description provided for @playbackPickArtist.
  ///
  /// In en, this message translates to:
  /// **'Choose an artist'**
  String get playbackPickArtist;

  /// No description provided for @playbackSourceSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get playbackSourceSongs;

  /// No description provided for @playbackSourceAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get playbackSourceAlbum;

  /// No description provided for @playbackSourceArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get playbackSourceArtist;

  /// No description provided for @playbackSourceGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get playbackSourceGenre;

  /// No description provided for @playbackSourceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get playbackSourceLanguage;

  /// No description provided for @playbackSourceFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get playbackSourceFolder;

  /// No description provided for @playbackSourceFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get playbackSourceFavorites;

  /// No description provided for @playbackSourceSelection.
  ///
  /// In en, this message translates to:
  /// **'Selection'**
  String get playbackSourceSelection;

  /// No description provided for @playbackSourceQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get playbackSourceQueue;

  /// No description provided for @playbackLyricsCard.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get playbackLyricsCard;

  /// No description provided for @playbackAddToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get playbackAddToPlaylist;

  /// No description provided for @playbackLyricsSource.
  ///
  /// In en, this message translates to:
  /// **'Lyrics source'**
  String get playbackLyricsSource;

  /// No description provided for @playbackTranslateLyrics.
  ///
  /// In en, this message translates to:
  /// **'Translate lyrics…'**
  String get playbackTranslateLyrics;

  /// No description provided for @playbackVisualEffects.
  ///
  /// In en, this message translates to:
  /// **'Visual effects'**
  String get playbackVisualEffects;

  /// No description provided for @playbackTrackInfo.
  ///
  /// In en, this message translates to:
  /// **'Track info'**
  String get playbackTrackInfo;

  /// No description provided for @playbackInfoPlays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 play} other{{count} plays}}'**
  String playbackInfoPlays(int count);

  /// No description provided for @playbackInfoSampleRate.
  ///
  /// In en, this message translates to:
  /// **'{khz} kHz'**
  String playbackInfoSampleRate(String khz);

  /// No description provided for @playbackInfoBitrate.
  ///
  /// In en, this message translates to:
  /// **'{kbps} kbps'**
  String playbackInfoBitrate(int kbps);

  /// No description provided for @playbackToggleCoverColumn.
  ///
  /// In en, this message translates to:
  /// **'Show or hide the cover column'**
  String get playbackToggleCoverColumn;

  /// No description provided for @playbackTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get playbackTranslate;

  /// No description provided for @playbackTabLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get playbackTabLyrics;

  /// No description provided for @playbackLyricsTabSoon.
  ///
  /// In en, this message translates to:
  /// **'Lyrics: coming soon'**
  String get playbackLyricsTabSoon;

  /// No description provided for @playbackPanelClose.
  ///
  /// In en, this message translates to:
  /// **'Close panel'**
  String get playbackPanelClose;

  /// No description provided for @playbackQueuePanelCounts.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, one{1 track} other{{total} tracks}} · {remaining} left'**
  String playbackQueuePanelCounts(int total, String remaining);

  /// No description provided for @playbackQueuePanelShort.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, one{1 track} other{{total} tracks}}'**
  String playbackQueuePanelShort(int total);

  /// No description provided for @playbackQueuePlayingAt.
  ///
  /// In en, this message translates to:
  /// **'Playing track {position}'**
  String playbackQueuePlayingAt(int position);

  /// No description provided for @playbackQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'The queue is empty'**
  String get playbackQueueEmpty;

  /// No description provided for @libraryTabSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get libraryTabSongs;

  /// No description provided for @libraryTabAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get libraryTabAlbums;

  /// No description provided for @libraryTabArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get libraryTabArtists;

  /// No description provided for @libraryTabGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get libraryTabGenres;

  /// No description provided for @libraryTabLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get libraryTabLanguages;

  /// No description provided for @libraryTabFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get libraryTabFolders;

  /// No description provided for @libraryNavFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get libraryNavFavorites;

  /// No description provided for @libraryNavHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get libraryNavHistory;

  /// No description provided for @libraryNavMostPlayed.
  ///
  /// In en, this message translates to:
  /// **'Most played'**
  String get libraryNavMostPlayed;

  /// No description provided for @librarySongCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}}'**
  String librarySongCount(int count);

  /// No description provided for @libraryAlbumCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 album} other{{count} albums}}'**
  String libraryAlbumCount(int count);

  /// No description provided for @libraryArtistCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 artist} other{{count} artists}}'**
  String libraryArtistCount(int count);

  /// No description provided for @libraryGenreCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 genre} other{{count} genres}}'**
  String libraryGenreCount(int count);

  /// No description provided for @libraryLanguageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 language} other{{count} languages}}'**
  String libraryLanguageCount(int count);

  /// No description provided for @libraryFolderCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 folder} other{{count} folders}}'**
  String libraryFolderCount(int count);

  /// No description provided for @libraryCountOf.
  ///
  /// In en, this message translates to:
  /// **'{shown} / {total} {unit}'**
  String libraryCountOf(int shown, int total, String unit);

  /// No description provided for @libraryUnitSongs.
  ///
  /// In en, this message translates to:
  /// **'songs'**
  String get libraryUnitSongs;

  /// No description provided for @libraryUnitAlbums.
  ///
  /// In en, this message translates to:
  /// **'albums'**
  String get libraryUnitAlbums;

  /// No description provided for @libraryUnitArtists.
  ///
  /// In en, this message translates to:
  /// **'artists'**
  String get libraryUnitArtists;

  /// No description provided for @libraryUnitGenres.
  ///
  /// In en, this message translates to:
  /// **'genres'**
  String get libraryUnitGenres;

  /// No description provided for @libraryUnitLanguages.
  ///
  /// In en, this message translates to:
  /// **'languages'**
  String get libraryUnitLanguages;

  /// No description provided for @libraryUnitFolders.
  ///
  /// In en, this message translates to:
  /// **'folders'**
  String get libraryUnitFolders;

  /// No description provided for @libraryPlayAll.
  ///
  /// In en, this message translates to:
  /// **'Play all'**
  String get libraryPlayAll;

  /// No description provided for @libraryShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get libraryShuffle;

  /// No description provided for @libraryPlayAlbum.
  ///
  /// In en, this message translates to:
  /// **'Play album'**
  String get libraryPlayAlbum;

  /// No description provided for @libraryPlayArtist.
  ///
  /// In en, this message translates to:
  /// **'Play all songs'**
  String get libraryPlayArtist;

  /// No description provided for @libraryFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get libraryFilter;

  /// No description provided for @libraryFilterClose.
  ///
  /// In en, this message translates to:
  /// **'Close filter'**
  String get libraryFilterClose;

  /// No description provided for @libraryFilterSongsHint.
  ///
  /// In en, this message translates to:
  /// **'Filter songs'**
  String get libraryFilterSongsHint;

  /// No description provided for @libraryFilterAlbumsHint.
  ///
  /// In en, this message translates to:
  /// **'Filter albums'**
  String get libraryFilterAlbumsHint;

  /// No description provided for @libraryFilterArtistsHint.
  ///
  /// In en, this message translates to:
  /// **'Filter artists'**
  String get libraryFilterArtistsHint;

  /// No description provided for @libraryFilterGenresHint.
  ///
  /// In en, this message translates to:
  /// **'Filter genres'**
  String get libraryFilterGenresHint;

  /// No description provided for @libraryFilterLanguagesHint.
  ///
  /// In en, this message translates to:
  /// **'Filter languages'**
  String get libraryFilterLanguagesHint;

  /// No description provided for @libraryFilterFoldersHint.
  ///
  /// In en, this message translates to:
  /// **'Filter in this folder'**
  String get libraryFilterFoldersHint;

  /// No description provided for @libraryOrderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get libraryOrderTooltip;

  /// No description provided for @libraryOrderAscText.
  ///
  /// In en, this message translates to:
  /// **'A → Z'**
  String get libraryOrderAscText;

  /// No description provided for @libraryOrderDescText.
  ///
  /// In en, this message translates to:
  /// **'Z → A'**
  String get libraryOrderDescText;

  /// No description provided for @libraryOrderAscNumber.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get libraryOrderAscNumber;

  /// No description provided for @libraryOrderDescNumber.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get libraryOrderDescNumber;

  /// No description provided for @librarySortTitle.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get librarySortTitle;

  /// No description provided for @librarySortArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get librarySortArtist;

  /// No description provided for @librarySortAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get librarySortAlbum;

  /// No description provided for @librarySortYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get librarySortYear;

  /// No description provided for @librarySortDateAdded.
  ///
  /// In en, this message translates to:
  /// **'Date added'**
  String get librarySortDateAdded;

  /// No description provided for @librarySortPlayCount.
  ///
  /// In en, this message translates to:
  /// **'Play count'**
  String get librarySortPlayCount;

  /// No description provided for @librarySortDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get librarySortDuration;

  /// No description provided for @librarySortTrackCount.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get librarySortTrackCount;

  /// No description provided for @librarySortAlbumCount.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get librarySortAlbumCount;

  /// No description provided for @librarySortTrackNumber.
  ///
  /// In en, this message translates to:
  /// **'Track number'**
  String get librarySortTrackNumber;

  /// No description provided for @libraryViewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get libraryViewGrid;

  /// No description provided for @libraryViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get libraryViewList;

  /// No description provided for @libraryViewTree.
  ///
  /// In en, this message translates to:
  /// **'Folder tree'**
  String get libraryViewTree;

  /// No description provided for @libraryViewFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat list'**
  String get libraryViewFlat;

  /// No description provided for @libraryScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get libraryScanning;

  /// No description provided for @libraryScanningTags.
  ///
  /// In en, this message translates to:
  /// **'Scanning · {done} / {total} songs'**
  String libraryScanningTags(int done, int total);

  /// No description provided for @libraryScanningTagsCount.
  ///
  /// In en, this message translates to:
  /// **'Scanning · {done} songs'**
  String libraryScanningTagsCount(int done);

  /// No description provided for @libraryScanningCovers.
  ///
  /// In en, this message translates to:
  /// **'Fetching covers · {done} / {total}'**
  String libraryScanningCovers(int done, int total);

  /// No description provided for @libraryScanningCoversStart.
  ///
  /// In en, this message translates to:
  /// **'Fetching covers…'**
  String get libraryScanningCoversStart;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Library is empty'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No songs in the chosen folders.'**
  String get libraryEmptyMessage;

  /// No description provided for @libraryChooseFolders.
  ///
  /// In en, this message translates to:
  /// **'Choose music folders'**
  String get libraryChooseFolders;

  /// No description provided for @libraryPlayFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start playback'**
  String get libraryPlayFailed;

  /// No description provided for @libraryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the list'**
  String get libraryLoadFailed;

  /// No description provided for @libraryNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get libraryNowPlaying;

  /// No description provided for @libraryFavoriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get libraryFavoriteAdd;

  /// No description provided for @libraryFavoriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get libraryFavoriteRemove;

  /// No description provided for @libraryFavoriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change favorites'**
  String get libraryFavoriteFailed;

  /// No description provided for @libraryDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String libraryDurationMinutes(int minutes);

  /// No description provided for @libraryDurationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String libraryDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @libraryAlbumStats.
  ///
  /// In en, this message translates to:
  /// **'{songs, plural, =1{1 song} other{{songs} songs}} • {minutes} min'**
  String libraryAlbumStats(int songs, int minutes);

  /// No description provided for @libraryLanguageUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get libraryLanguageUnknown;

  /// No description provided for @libraryLanguageStatsDetected.
  ///
  /// In en, this message translates to:
  /// **'{songs, plural, =1{1 song} other{{songs} songs}} · {detected} auto-detected'**
  String libraryLanguageStatsDetected(int songs, int detected);

  /// No description provided for @libraryLanguagesNote.
  ///
  /// In en, this message translates to:
  /// **'From the language tag of each song; songs without a tag are detected by Kanaru. Change this in Settings › Library.'**
  String get libraryLanguagesNote;

  /// No description provided for @libraryFoldersAll.
  ///
  /// In en, this message translates to:
  /// **'All folders'**
  String get libraryFoldersAll;

  /// No description provided for @libraryFoldersHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden levels'**
  String get libraryFoldersHidden;

  /// No description provided for @libraryGoToFolder.
  ///
  /// In en, this message translates to:
  /// **'Go to folder'**
  String get libraryGoToFolder;

  /// No description provided for @libraryVolumeInternal.
  ///
  /// In en, this message translates to:
  /// **'Internal storage'**
  String get libraryVolumeInternal;

  /// No description provided for @libraryVolumeSdCard.
  ///
  /// In en, this message translates to:
  /// **'SD card'**
  String get libraryVolumeSdCard;

  /// No description provided for @libraryVolumeUsb.
  ///
  /// In en, this message translates to:
  /// **'USB drive'**
  String get libraryVolumeUsb;

  /// No description provided for @libraryFolderCounts.
  ///
  /// In en, this message translates to:
  /// **'{songs, plural, =1{1 song} other{{songs} songs}} · {folders, plural, =1{1 folder} other{{folders} folders}}'**
  String libraryFolderCounts(int songs, int folders);

  /// No description provided for @libraryFolderSongsHeader.
  ///
  /// In en, this message translates to:
  /// **'Songs in this folder · {count}'**
  String libraryFolderSongsHeader(int count);

  /// No description provided for @libraryFlatSongsHeader.
  ///
  /// In en, this message translates to:
  /// **'{count} songs in this folder (not including subfolders)'**
  String libraryFlatSongsHeader(int count);

  /// No description provided for @libraryRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get libraryRetry;

  /// No description provided for @libraryPermissionMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing permission to read music'**
  String get libraryPermissionMissing;

  /// No description provided for @libraryGrantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get libraryGrantPermission;

  /// No description provided for @libraryNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get libraryNotFoundTitle;

  /// No description provided for @libraryNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This is no longer in your library.'**
  String get libraryNotFoundMessage;

  /// No description provided for @libraryPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get libraryPlay;

  /// No description provided for @libraryAppearsIn.
  ///
  /// In en, this message translates to:
  /// **'Appears on'**
  String get libraryAppearsIn;

  /// No description provided for @libraryAlbumsOf.
  ///
  /// In en, this message translates to:
  /// **'Albums · {name}'**
  String libraryAlbumsOf(String name);

  /// No description provided for @libraryArtistsOf.
  ///
  /// In en, this message translates to:
  /// **'Artists · {name}'**
  String libraryArtistsOf(String name);

  /// No description provided for @libraryAppearsInOf.
  ///
  /// In en, this message translates to:
  /// **'Appears on · {name}'**
  String libraryAppearsInOf(String name);

  /// No description provided for @libraryDetectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} auto-detected'**
  String libraryDetectedCount(int count);

  /// No description provided for @libraryAutoDetectedTag.
  ///
  /// In en, this message translates to:
  /// **'auto-detected'**
  String get libraryAutoDetectedTag;

  /// No description provided for @libraryLanguageDetectedNote.
  ///
  /// In en, this message translates to:
  /// **'Songs labelled “auto-detected” have no language tag; Kanaru guesses it from the title and lyrics.'**
  String get libraryLanguageDetectedNote;

  /// No description provided for @libraryLanguageUnknownNote.
  ///
  /// In en, this message translates to:
  /// **'These songs have no language tag and Kanaru could not detect one (often instrumentals). Add a language tag in Edit info, or change how languages are detected in Settings › Library.'**
  String get libraryLanguageUnknownNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
