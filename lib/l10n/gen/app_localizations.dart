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
  /// **'Folders with music that Android found. Music you just copied to the phone may not be here until Android rescans.'**
  String get scanSetupFolderPickerHint;

  /// No description provided for @scanSetupFolderPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'Every folder with music is already chosen.'**
  String get scanSetupFolderPickerEmpty;

  /// No description provided for @scanSetupFolderSheetLoading.
  ///
  /// In en, this message translates to:
  /// **'Looking for folders with music…'**
  String get scanSetupFolderSheetLoading;

  /// No description provided for @scanSetupNoMusicTitle.
  ///
  /// In en, this message translates to:
  /// **'Android sees no music yet'**
  String get scanSetupNoMusicTitle;

  /// No description provided for @scanSetupNoMusicBody.
  ///
  /// In en, this message translates to:
  /// **'Music you just copied to the phone often does not show up until Android rescans.'**
  String get scanSetupNoMusicBody;

  /// No description provided for @scanSetupNoMusicCard.
  ///
  /// In en, this message translates to:
  /// **'Android sees no music on this phone yet. Music you just copied often does not show up until Android rescans.'**
  String get scanSetupNoMusicCard;

  /// No description provided for @scanSetupRescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get scanSetupRescan;

  /// No description provided for @scanSetupRescanRow.
  ///
  /// In en, this message translates to:
  /// **'Can\'t see your folder? Rescan'**
  String get scanSetupRescanRow;

  /// No description provided for @scanSetupRescanning.
  ///
  /// In en, this message translates to:
  /// **'Rescanning…'**
  String get scanSetupRescanning;

  /// No description provided for @scanSetupRescanningBody.
  ///
  /// In en, this message translates to:
  /// **'Android is looking for music in the folders of internal storage and the SD card (Music and Download first).'**
  String get scanSetupRescanningBody;

  /// No description provided for @scanSetupRescanningSheetNote.
  ///
  /// In en, this message translates to:
  /// **'If you close this sheet, Android keeps scanning.'**
  String get scanSetupRescanningSheetNote;

  /// No description provided for @scanSetupRescanDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Rescanned · Android found 1 song.} other{Rescanned · Android found {count} songs.}}'**
  String scanSetupRescanDone(int count);

  /// No description provided for @scanSetupStillNoMusicTitle.
  ///
  /// In en, this message translates to:
  /// **'Still no music found'**
  String get scanSetupStillNoMusicTitle;

  /// No description provided for @scanSetupStillNoMusicBody.
  ///
  /// In en, this message translates to:
  /// **'Android rescanned but found no music files.'**
  String get scanSetupStillNoMusicBody;

  /// No description provided for @scanSetupStillNoMusicTipShared.
  ///
  /// In en, this message translates to:
  /// **'Music must be in shared storage (for example Music or Download), not inside another app\'s Android › data folder.'**
  String get scanSetupStillNoMusicTipShared;

  /// No description provided for @scanSetupStillNoMusicTipRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart the phone so Android rescans all storage, then reopen Kanaru.'**
  String get scanSetupStillNoMusicTipRestart;

  /// No description provided for @scanSetupStillNoMusicCard.
  ///
  /// In en, this message translates to:
  /// **'Android still sees no music.'**
  String get scanSetupStillNoMusicCard;

  /// No description provided for @scanSetupRescanFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not rescan.'**
  String get scanSetupRescanFailed;

  /// No description provided for @scanSetupFolderListFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load the folder list'**
  String get scanSetupFolderListFailedTitle;

  /// No description provided for @scanSetupFolderListFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Android did not answer in time or reported an error.'**
  String get scanSetupFolderListFailedBody;

  /// No description provided for @scanSetupExclusionSheetLoading.
  ///
  /// In en, this message translates to:
  /// **'Looking for sub-folders…'**
  String get scanSetupExclusionSheetLoading;

  /// No description provided for @scanSetupExclusionListFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the sub-folder list'**
  String get scanSetupExclusionListFailed;

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

  /// No description provided for @scanSetupSheetSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get scanSetupSheetSelectAll;

  /// No description provided for @scanSetupSheetSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / {total} folders'**
  String scanSetupSheetSelectedCount(int count, int total);

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
  /// **'Sub-folders with music that Android has seen, inside the music folders you chose.'**
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

  /// No description provided for @playbackStopAndClear.
  ///
  /// In en, this message translates to:
  /// **'Stop playback'**
  String get playbackStopAndClear;

  /// No description provided for @playbackStoppedAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Playback stopped'**
  String get playbackStoppedAnnouncement;

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

  /// No description provided for @playbackNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get playbackNowPlaying;

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

  /// No description provided for @libraryShelfSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get libraryShelfSeeAll;

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

  /// No description provided for @librarySortDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get librarySortDialogTitle;

  /// No description provided for @librarySortChosen.
  ///
  /// In en, this message translates to:
  /// **'Chosen'**
  String get librarySortChosen;

  /// No description provided for @librarySortNotChosen.
  ///
  /// In en, this message translates to:
  /// **'Not chosen'**
  String get librarySortNotChosen;

  /// No description provided for @librarySortReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get librarySortReset;

  /// No description provided for @librarySortDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get librarySortDone;

  /// No description provided for @libraryOrderReverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse order'**
  String get libraryOrderReverse;

  /// No description provided for @librarySortDragHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder {label}'**
  String librarySortDragHint(String label);

  /// No description provided for @librarySortFlipTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch direction: {word}'**
  String librarySortFlipTooltip(String word);

  /// No description provided for @librarySortFlipSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label}: {word}, tap to switch direction'**
  String librarySortFlipSemantics(String label, String word);

  /// No description provided for @librarySortRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {label}'**
  String librarySortRemove(String label);

  /// No description provided for @librarySortAdd.
  ///
  /// In en, this message translates to:
  /// **'Add {label}'**
  String librarySortAdd(String label);

  /// No description provided for @libraryOrderOldFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get libraryOrderOldFirst;

  /// No description provided for @libraryOrderNewFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get libraryOrderNewFirst;

  /// No description provided for @libraryOrderFirstToLast.
  ///
  /// In en, this message translates to:
  /// **'First → last'**
  String get libraryOrderFirstToLast;

  /// No description provided for @libraryOrderLastToFirst.
  ///
  /// In en, this message translates to:
  /// **'Last → first'**
  String get libraryOrderLastToFirst;

  /// No description provided for @librarySortMore.
  ///
  /// In en, this message translates to:
  /// **'{label} +{count}'**
  String librarySortMore(String label, int count);

  /// No description provided for @librarySortAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced…'**
  String get librarySortAdvanced;

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

  /// No description provided for @librarySortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get librarySortName;

  /// No description provided for @librarySortDateModified.
  ///
  /// In en, this message translates to:
  /// **'Date modified'**
  String get librarySortDateModified;

  /// No description provided for @librarySortPlaylistOrder.
  ///
  /// In en, this message translates to:
  /// **'Playlist order'**
  String get librarySortPlaylistOrder;

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

  /// No description provided for @libraryNothingToPlay.
  ///
  /// In en, this message translates to:
  /// **'Nothing to play'**
  String get libraryNothingToPlay;

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

  /// No description provided for @libraryFavoriteLabel.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get libraryFavoriteLabel;

  /// No description provided for @libraryDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String libraryDurationMinutes(int minutes);

  /// No description provided for @libraryDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String libraryDurationHours(int hours);

  /// No description provided for @librarySelectionGone.
  ///
  /// In en, this message translates to:
  /// **'The selected songs are no longer in the library'**
  String get librarySelectionGone;

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

  /// No description provided for @libraryAppearsInAlbumCount.
  ///
  /// In en, this message translates to:
  /// **'Appears on {count, plural, =1{1 album} other{{count} albums}}'**
  String libraryAppearsInAlbumCount(int count);

  /// No description provided for @libraryLanguageNoTag.
  ///
  /// In en, this message translates to:
  /// **'No language tag'**
  String get libraryLanguageNoTag;

  /// No description provided for @libraryShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get libraryShowMore;

  /// No description provided for @libraryShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get libraryShowLess;

  /// No description provided for @libraryLanguageUnknownNote.
  ///
  /// In en, this message translates to:
  /// **'These songs have no language tag and Kanaru could not detect one (often instrumentals). Add a language tag in Edit info, or change how languages are detected in Settings › Library.'**
  String get libraryLanguageUnknownNote;

  /// No description provided for @libraryMenuGoAlbum.
  ///
  /// In en, this message translates to:
  /// **'Go to album'**
  String get libraryMenuGoAlbum;

  /// No description provided for @libraryMenuGoArtist.
  ///
  /// In en, this message translates to:
  /// **'Go to artist'**
  String get libraryMenuGoArtist;

  /// No description provided for @libraryMenuGoAlbumArtist.
  ///
  /// In en, this message translates to:
  /// **'Go to album artist'**
  String get libraryMenuGoAlbumArtist;

  /// No description provided for @libraryMenuGoGenre.
  ///
  /// In en, this message translates to:
  /// **'Go to genre'**
  String get libraryMenuGoGenre;

  /// No description provided for @libraryMenuGoLanguage.
  ///
  /// In en, this message translates to:
  /// **'Go to language'**
  String get libraryMenuGoLanguage;

  /// No description provided for @libraryMenuGoFolder.
  ///
  /// In en, this message translates to:
  /// **'Go to folder'**
  String get libraryMenuGoFolder;

  /// No description provided for @libraryMenuReveal.
  ///
  /// In en, this message translates to:
  /// **'Show in file manager'**
  String get libraryMenuReveal;

  /// No description provided for @libraryMenuNoAlbum.
  ///
  /// In en, this message translates to:
  /// **'No album'**
  String get libraryMenuNoAlbum;

  /// No description provided for @libraryMenuNoArtist.
  ///
  /// In en, this message translates to:
  /// **'No artist'**
  String get libraryMenuNoArtist;

  /// No description provided for @libraryMenuAppearsCount.
  ///
  /// In en, this message translates to:
  /// **'appears on {count}'**
  String libraryMenuAppearsCount(int count);

  /// No description provided for @libraryMenuSongsInFolders.
  ///
  /// In en, this message translates to:
  /// **'{songs, plural, =1{1 song} other{{songs} songs}} in {folders, plural, =1{1 folder} other{{folders} folders}}'**
  String libraryMenuSongsInFolders(int songs, int folders);

  /// No description provided for @libraryMenuFoldersOf.
  ///
  /// In en, this message translates to:
  /// **'Folders · {name}'**
  String libraryMenuFoldersOf(String name);

  /// No description provided for @libraryMenuFoldersIntroAlbum.
  ///
  /// In en, this message translates to:
  /// **'This album\'s songs are stored in {count} folders. Pick one to open it in Folders.'**
  String libraryMenuFoldersIntroAlbum(int count);

  /// No description provided for @libraryMenuFoldersIntroArtist.
  ///
  /// In en, this message translates to:
  /// **'This artist\'s songs are stored in {count} folders. Pick one to open it in Folders.'**
  String libraryMenuFoldersIntroArtist(int count);

  /// No description provided for @libraryMenuFoldersIntroGenre.
  ///
  /// In en, this message translates to:
  /// **'The songs of this genre are stored in {count} folders. Pick one to open it in Folders.'**
  String libraryMenuFoldersIntroGenre(int count);

  /// No description provided for @libraryMenuFoldersIntroLanguage.
  ///
  /// In en, this message translates to:
  /// **'The songs of this language are stored in {count} folders. Pick one to open it in Folders.'**
  String libraryMenuFoldersIntroLanguage(int count);

  /// No description provided for @libraryMenuAddToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist…'**
  String get libraryMenuAddToPlaylist;

  /// No description provided for @libraryMenuFavoriteAll.
  ///
  /// In en, this message translates to:
  /// **'Add all to favorites'**
  String get libraryMenuFavoriteAll;

  /// No description provided for @libraryMenuEditSong.
  ///
  /// In en, this message translates to:
  /// **'Edit song info'**
  String get libraryMenuEditSong;

  /// No description provided for @libraryMenuEditAlbum.
  ///
  /// In en, this message translates to:
  /// **'Edit album info'**
  String get libraryMenuEditAlbum;

  /// No description provided for @libraryMenuSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get libraryMenuSelect;

  /// No description provided for @libraryMenuDeselect.
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get libraryMenuDeselect;

  /// No description provided for @libraryMenuAskAiSong.
  ///
  /// In en, this message translates to:
  /// **'Ask AI about this song'**
  String get libraryMenuAskAiSong;

  /// No description provided for @libraryMenuAskAiAlbum.
  ///
  /// In en, this message translates to:
  /// **'Ask AI about this album'**
  String get libraryMenuAskAiAlbum;

  /// No description provided for @libraryMenuAskAiArtist.
  ///
  /// In en, this message translates to:
  /// **'Ask AI about this artist'**
  String get libraryMenuAskAiArtist;

  /// No description provided for @libraryMenuAskAiSongs.
  ///
  /// In en, this message translates to:
  /// **'Ask AI about these songs'**
  String get libraryMenuAskAiSongs;

  /// No description provided for @libraryMenuAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get libraryMenuAdvanced;

  /// No description provided for @libraryMenuFindLyrics.
  ///
  /// In en, this message translates to:
  /// **'Find lyrics online…'**
  String get libraryMenuFindLyrics;

  /// No description provided for @libraryMenuHide.
  ///
  /// In en, this message translates to:
  /// **'Remove from library'**
  String get libraryMenuHide;

  /// No description provided for @libraryMenuHideNote.
  ///
  /// In en, this message translates to:
  /// **'Keeps the files; undo in Settings › Library'**
  String get libraryMenuHideNote;

  /// No description provided for @libraryMenuDeleteFiles.
  ///
  /// In en, this message translates to:
  /// **'Delete files from device'**
  String get libraryMenuDeleteFiles;

  /// No description provided for @libraryMenuMoveToTrash.
  ///
  /// In en, this message translates to:
  /// **'Move files to Trash'**
  String get libraryMenuMoveToTrash;

  /// No description provided for @libraryMenuFileCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String libraryMenuFileCount(int count);

  /// No description provided for @libraryMenuSplitArtists.
  ///
  /// In en, this message translates to:
  /// **'Split or merge artists'**
  String get libraryMenuSplitArtists;

  /// No description provided for @libraryMenuSplitArtistsNote.
  ///
  /// In en, this message translates to:
  /// **'Treat one name as two artists, or merge spellings'**
  String get libraryMenuSplitArtistsNote;

  /// No description provided for @libraryMenuSplitGenres.
  ///
  /// In en, this message translates to:
  /// **'Split or merge genres'**
  String get libraryMenuSplitGenres;

  /// No description provided for @libraryMenuSplitGenresNote.
  ///
  /// In en, this message translates to:
  /// **'Split a combined genre tag, or merge spellings'**
  String get libraryMenuSplitGenresNote;

  /// No description provided for @libraryMenuLanguageDetection.
  ///
  /// In en, this message translates to:
  /// **'How languages are detected'**
  String get libraryMenuLanguageDetection;

  /// No description provided for @libraryMenuLanguageDetectionNote.
  ///
  /// In en, this message translates to:
  /// **'Settings › Library'**
  String get libraryMenuLanguageDetectionNote;

  /// No description provided for @libraryMenuCopyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get libraryMenuCopyPath;

  /// No description provided for @libraryMenuExclude.
  ///
  /// In en, this message translates to:
  /// **'Exclude from library'**
  String get libraryMenuExclude;

  /// No description provided for @libraryMenuExcludeNote.
  ///
  /// In en, this message translates to:
  /// **'Keeps the files; undo in Settings › Library › Folders'**
  String get libraryMenuExcludeNote;

  /// No description provided for @libraryMenuIncludesSubfolders.
  ///
  /// In en, this message translates to:
  /// **'Includes subfolders'**
  String get libraryMenuIncludesSubfolders;

  /// No description provided for @libraryMenuPlayDirect.
  ///
  /// In en, this message translates to:
  /// **'Play only songs in this folder'**
  String get libraryMenuPlayDirect;

  /// No description provided for @libraryMenuPlayDirectNote.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}}, without subfolders'**
  String libraryMenuPlayDirectNote(int count);

  /// No description provided for @libraryMenuSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song selected} other{{count} songs selected}}'**
  String libraryMenuSelectionTitle(int count);

  /// No description provided for @libraryMenuMore.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get libraryMenuMore;

  /// No description provided for @libraryMenuBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get libraryMenuBack;

  /// No description provided for @libraryMenuPlayNext.
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get libraryMenuPlayNext;

  /// No description provided for @libraryMenuAddToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get libraryMenuAddToQueue;

  /// No description provided for @libraryMenuPlayingNext.
  ///
  /// In en, this message translates to:
  /// **'Playing next'**
  String get libraryMenuPlayingNext;

  /// No description provided for @libraryMenuQueued.
  ///
  /// In en, this message translates to:
  /// **'Added to queue'**
  String get libraryMenuQueued;

  /// No description provided for @libraryMenuQueueFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change the queue'**
  String get libraryMenuQueueFailed;

  /// No description provided for @libraryMenuExcluded.
  ///
  /// In en, this message translates to:
  /// **'Excluded “{name}” from the library'**
  String libraryMenuExcluded(String name);

  /// No description provided for @libraryMenuUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get libraryMenuUndo;

  /// No description provided for @libraryMenuExcludeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not exclude the folder'**
  String get libraryMenuExcludeFailed;

  /// No description provided for @libraryMenuUndoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not undo'**
  String get libraryMenuUndoFailed;

  /// No description provided for @libraryMenuPathCopied.
  ///
  /// In en, this message translates to:
  /// **'Path copied'**
  String get libraryMenuPathCopied;

  /// No description provided for @libraryMenuRevealFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file manager'**
  String get libraryMenuRevealFailed;

  /// No description provided for @libraryMenuLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the menu'**
  String get libraryMenuLoadFailed;

  /// No description provided for @libraryMenuSongInfo.
  ///
  /// In en, this message translates to:
  /// **'Song info'**
  String get libraryMenuSongInfo;

  /// No description provided for @libraryInfoFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get libraryInfoFormat;

  /// No description provided for @libraryInfoBitrate.
  ///
  /// In en, this message translates to:
  /// **'Bitrate'**
  String get libraryInfoBitrate;

  /// No description provided for @libraryInfoBitrateValue.
  ///
  /// In en, this message translates to:
  /// **'{kbps} kbps'**
  String libraryInfoBitrateValue(int kbps);

  /// No description provided for @libraryInfoSampleRate.
  ///
  /// In en, this message translates to:
  /// **'Sample rate'**
  String get libraryInfoSampleRate;

  /// No description provided for @libraryInfoSampleRateValue.
  ///
  /// In en, this message translates to:
  /// **'{khz} kHz'**
  String libraryInfoSampleRateValue(String khz);

  /// No description provided for @libraryInfoBitDepth.
  ///
  /// In en, this message translates to:
  /// **'Bit depth'**
  String get libraryInfoBitDepth;

  /// No description provided for @libraryInfoBitDepthValue.
  ///
  /// In en, this message translates to:
  /// **'{bits}-bit'**
  String libraryInfoBitDepthValue(int bits);

  /// No description provided for @libraryInfoSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get libraryInfoSize;

  /// No description provided for @libraryInfoPath.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get libraryInfoPath;

  /// No description provided for @libraryInfoPlayCount.
  ///
  /// In en, this message translates to:
  /// **'Plays'**
  String get libraryInfoPlayCount;

  /// No description provided for @libraryInfoUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get libraryInfoUnknown;

  /// No description provided for @libraryPanelLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected songs'**
  String get libraryPanelLabel;

  /// No description provided for @libraryPanelClear.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get libraryPanelClear;

  /// No description provided for @libraryPanelPlayAll.
  ///
  /// In en, this message translates to:
  /// **'Play all selected'**
  String get libraryPanelPlayAll;

  /// No description provided for @libraryPanelEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit info'**
  String get libraryPanelEdit;

  /// No description provided for @libraryPanelAddToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist…'**
  String get libraryPanelAddToPlaylist;

  /// No description provided for @libraryPanelMore.
  ///
  /// In en, this message translates to:
  /// **'Options for the selection'**
  String get libraryPanelMore;

  /// No description provided for @libraryPanelSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all songs on this screen'**
  String get libraryPanelSelectAll;

  /// No description provided for @libraryPanelExpand.
  ///
  /// In en, this message translates to:
  /// **'Show the selected songs'**
  String get libraryPanelExpand;

  /// No description provided for @libraryPanelCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get libraryPanelCollapse;

  /// No description provided for @libraryPanelReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to change the play order'**
  String get libraryPanelReorder;

  /// No description provided for @libraryMenuCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not copy'**
  String get libraryMenuCopyFailed;

  /// No description provided for @libraryActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t complete the action'**
  String get libraryActionFailed;

  /// No description provided for @playlistFavoritesName.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get playlistFavoritesName;

  /// No description provided for @playlistDefaultName.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get playlistDefaultName;

  /// No description provided for @playlistCopyName.
  ///
  /// In en, this message translates to:
  /// **'{name} (copy)'**
  String playlistCopyName(String name);

  /// No description provided for @playlistFavoritesCopyName.
  ///
  /// In en, this message translates to:
  /// **'Favorites ({date})'**
  String playlistFavoritesCopyName(String date);

  /// No description provided for @playlistYours.
  ///
  /// In en, this message translates to:
  /// **'Your playlists'**
  String get playlistYours;

  /// No description provided for @playlistCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 playlist} other{{count} playlists}}'**
  String playlistCount(int count);

  /// No description provided for @playlistTrackCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No songs} =1{1 song} other{{count} songs}}'**
  String playlistTrackCount(int count);

  /// No description provided for @playlistEditedOn.
  ///
  /// In en, this message translates to:
  /// **'Edited {date}'**
  String playlistEditedOn(String date);

  /// No description provided for @playlistFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter playlists'**
  String get playlistFilterHint;

  /// No description provided for @playlistFilterNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No playlists match.'**
  String get playlistFilterNoMatch;

  /// No description provided for @playlistsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get playlistsEmptyTitle;

  /// No description provided for @playlistsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a playlist to keep songs in your own order, or import an M3U file.'**
  String get playlistsEmptyMessage;

  /// No description provided for @playlistCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create playlist'**
  String get playlistCreateAction;

  /// No description provided for @playlistImportM3uAction.
  ///
  /// In en, this message translates to:
  /// **'Import M3U file…'**
  String get playlistImportM3uAction;

  /// No description provided for @playlistHubStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get playlistHubStats;

  /// No description provided for @playlistFabOpen.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get playlistFabOpen;

  /// No description provided for @playlistFabClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get playlistFabClose;

  /// No description provided for @playlistFabNew.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get playlistFabNew;

  /// No description provided for @playlistFabImport.
  ///
  /// In en, this message translates to:
  /// **'Import M3U file'**
  String get playlistFabImport;

  /// No description provided for @playlistFabSmart.
  ///
  /// In en, this message translates to:
  /// **'Smart playlist'**
  String get playlistFabSmart;

  /// No description provided for @playlistFilterSongsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No songs match.'**
  String get playlistFilterSongsNoMatch;

  /// No description provided for @playlistDragHandle.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get playlistDragHandle;

  /// No description provided for @playlistNotInLibrary.
  ///
  /// In en, this message translates to:
  /// **'Not in library'**
  String get playlistNotInLibrary;

  /// No description provided for @playlistUnavailableNote.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song is} other{{count} songs are}} not in your library: dimmed and skipped when playing.'**
  String playlistUnavailableNote(int count);

  /// No description provided for @playlistRemoveUnavailableAction.
  ///
  /// In en, this message translates to:
  /// **'Remove {count}'**
  String playlistRemoveUnavailableAction(int count);

  /// No description provided for @playlistEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'This playlist is empty'**
  String get playlistEmptyTitle;

  /// No description provided for @playlistEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add songs from the menu of any song, album or artist (Add to playlist…), or select several songs and add them at once.'**
  String get playlistEmptyMessage;

  /// No description provided for @playlistFavoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get playlistFavoritesEmptyTitle;

  /// No description provided for @playlistFavoritesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap [icon] on a song to add it here.'**
  String get playlistFavoritesEmptyMessage;

  /// No description provided for @playlistFavoritesEmptyIconLabel.
  ///
  /// In en, this message translates to:
  /// **'favorite'**
  String get playlistFavoritesEmptyIconLabel;

  /// No description provided for @playlistNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Playlist not found'**
  String get playlistNotFoundTitle;

  /// No description provided for @playlistNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted.'**
  String get playlistNotFoundMessage;

  /// No description provided for @playlistSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the playlist'**
  String get playlistSaveFailed;

  /// No description provided for @playlistMenuGoTo.
  ///
  /// In en, this message translates to:
  /// **'Go to playlist'**
  String get playlistMenuGoTo;

  /// No description provided for @playlistMenuGoToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Go to Favorites'**
  String get playlistMenuGoToFavorites;

  /// No description provided for @playlistMenuCopyTo.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist…'**
  String get playlistMenuCopyTo;

  /// No description provided for @playlistMenuCopyToHint.
  ///
  /// In en, this message translates to:
  /// **'Copy {count, plural, =1{1 song} other{{count} songs}} to another playlist.'**
  String playlistMenuCopyToHint(int count);

  /// No description provided for @playlistMenuAskAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI about this playlist'**
  String get playlistMenuAskAi;

  /// No description provided for @playlistMenuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit playlist'**
  String get playlistMenuEdit;

  /// No description provided for @playlistMenuEditHint.
  ///
  /// In en, this message translates to:
  /// **'Change the name, description and cover.'**
  String get playlistMenuEditHint;

  /// No description provided for @playlistMenuChangeCover.
  ///
  /// In en, this message translates to:
  /// **'Change playlist image'**
  String get playlistMenuChangeCover;

  /// No description provided for @playlistMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist'**
  String get playlistMenuDelete;

  /// No description provided for @playlistMenuDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'Music files stay'**
  String get playlistMenuDeleteHint;

  /// No description provided for @playlistMenuDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate playlist'**
  String get playlistMenuDuplicate;

  /// No description provided for @playlistMenuExportM3u.
  ///
  /// In en, this message translates to:
  /// **'Export M3U file…'**
  String get playlistMenuExportM3u;

  /// No description provided for @playlistMenuExportM3uHint.
  ///
  /// In en, this message translates to:
  /// **'Absolute paths'**
  String get playlistMenuExportM3uHint;

  /// No description provided for @playlistMenuExportM3uRelative.
  ///
  /// In en, this message translates to:
  /// **'Export M3U, relative paths…'**
  String get playlistMenuExportM3uRelative;

  /// No description provided for @playlistMenuExportM3uRelativeHint.
  ///
  /// In en, this message translates to:
  /// **'Keep the .m3u8 file next to the music folder: copy the whole folder to another device and it still opens.'**
  String get playlistMenuExportM3uRelativeHint;

  /// No description provided for @playlistMenuRemoveDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Remove duplicates'**
  String get playlistMenuRemoveDuplicates;

  /// No description provided for @playlistMenuRemoveDuplicatesHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 repeated song} other{{count} repeated songs}} · keep the first'**
  String playlistMenuRemoveDuplicatesHint(int count);

  /// No description provided for @playlistMenuRemoveUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Remove missing songs'**
  String get playlistMenuRemoveUnavailable;

  /// No description provided for @playlistMenuRemoveUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}} not in your library'**
  String playlistMenuRemoveUnavailableHint(int count);

  /// No description provided for @playlistMenuSaveAs.
  ///
  /// In en, this message translates to:
  /// **'Save as playlist'**
  String get playlistMenuSaveAs;

  /// No description provided for @playlistMenuClearFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove all from Favorites'**
  String get playlistMenuClearFavorites;

  /// No description provided for @playlistMenuClearFavoritesHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}} · music files stay'**
  String playlistMenuClearFavoritesHint(int count);

  /// No description provided for @playlistMenuMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get playlistMenuMoveUp;

  /// No description provided for @playlistMenuMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get playlistMenuMoveDown;

  /// No description provided for @playlistMenuRemoveEntry.
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist'**
  String get playlistMenuRemoveEntry;

  /// No description provided for @playlistMenuRemoveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get playlistMenuRemoveFavorite;

  /// No description provided for @playlistRemovedEntry.
  ///
  /// In en, this message translates to:
  /// **'Removed “{title}”'**
  String playlistRemovedEntry(String title);

  /// No description provided for @playlistRemovedFavorite.
  ///
  /// In en, this message translates to:
  /// **'Removed “{title}” from Favorites'**
  String playlistRemovedFavorite(String title);

  /// No description provided for @playlistRemovedEntries.
  ///
  /// In en, this message translates to:
  /// **'Removed {count, plural, =1{1 song} other{{count} songs}}'**
  String playlistRemovedEntries(int count);

  /// No description provided for @playlistRemovedDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Removed {count, plural, =1{1 duplicate} other{{count} duplicates}}'**
  String playlistRemovedDuplicates(int count);

  /// No description provided for @playlistRemovedUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Removed {count, plural, =1{1 missing song} other{{count} missing songs}}'**
  String playlistRemovedUnavailable(int count);

  /// No description provided for @playlistClearedFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed everything from Favorites'**
  String get playlistClearedFavorites;

  /// No description provided for @playlistSaved.
  ///
  /// In en, this message translates to:
  /// **'Playlist saved'**
  String get playlistSaved;

  /// No description provided for @playlistCreated.
  ///
  /// In en, this message translates to:
  /// **'Created {name}'**
  String playlistCreated(String name);

  /// No description provided for @playlistDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Created “{name}”'**
  String playlistDuplicated(String name);

  /// No description provided for @playlistFavoritedAll.
  ///
  /// In en, this message translates to:
  /// **'Added {added} to Favorites, skipped {skipped}'**
  String playlistFavoritedAll(int added, int skipped);

  /// No description provided for @playlistCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get playlistCreateTitle;

  /// No description provided for @playlistCreateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get playlistCreateConfirm;

  /// No description provided for @playlistEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit playlist'**
  String get playlistEditTitle;

  /// No description provided for @playlistNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get playlistNameLabel;

  /// No description provided for @playlistDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get playlistDescriptionLabel;

  /// No description provided for @playlistDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a description (optional)'**
  String get playlistDescriptionHint;

  /// No description provided for @playlistNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name can\'t be empty'**
  String get playlistNameEmpty;

  /// No description provided for @playlistNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Too long'**
  String get playlistNameTooLong;

  /// No description provided for @playlistDescriptionTooLong.
  ///
  /// In en, this message translates to:
  /// **'Too long'**
  String get playlistDescriptionTooLong;

  /// No description provided for @playlistCoverChoose.
  ///
  /// In en, this message translates to:
  /// **'Change cover…'**
  String get playlistCoverChoose;

  /// No description provided for @playlistCoverAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic cover'**
  String get playlistCoverAuto;

  /// No description provided for @playlistCoverUsingAuto.
  ///
  /// In en, this message translates to:
  /// **'Using the automatic cover'**
  String get playlistCoverUsingAuto;

  /// No description provided for @playlistCoverAutoHint.
  ///
  /// In en, this message translates to:
  /// **'The automatic cover combines the covers of the first 4 albums in the playlist.'**
  String get playlistCoverAutoHint;

  /// No description provided for @playlistDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String playlistDeleteTitle(String name);

  /// No description provided for @playlistDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The playlist has {count, plural, =1{1 song} other{{count} songs}}. The songs stay in your library.'**
  String playlistDeleteBody(int count);

  /// No description provided for @playlistDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get playlistDeleteConfirm;

  /// No description provided for @playlistClearFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all from Favorites?'**
  String get playlistClearFavoritesTitle;

  /// No description provided for @playlistClearFavoritesBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song leaves} other{{count} songs leave}} Favorites. The songs stay in your library.'**
  String playlistClearFavoritesBody(int count);

  /// No description provided for @playlistClearFavoritesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove all'**
  String get playlistClearFavoritesConfirm;

  /// No description provided for @playlistCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get playlistCancel;

  /// No description provided for @playlistSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get playlistSave;

  /// No description provided for @playlistClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get playlistClose;

  /// No description provided for @playlistConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get playlistConfirm;

  /// No description provided for @playlistPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get playlistPickerTitle;

  /// No description provided for @playlistPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{songs, plural, =1{1 song} other{{songs} songs}} · {source}'**
  String playlistPickerSubtitle(int songs, String source);

  /// No description provided for @playlistPickerFrom.
  ///
  /// In en, this message translates to:
  /// **'from {name}'**
  String playlistPickerFrom(String name);

  /// No description provided for @playlistPickerSelectedSongs.
  ///
  /// In en, this message translates to:
  /// **'{count} selected songs'**
  String playlistPickerSelectedSongs(int count);

  /// No description provided for @playlistPickerFavoritesHint.
  ///
  /// In en, this message translates to:
  /// **'Songs already there are skipped.'**
  String get playlistPickerFavoritesHint;

  /// No description provided for @playlistPickerNew.
  ///
  /// In en, this message translates to:
  /// **'New playlist…'**
  String get playlistPickerNew;

  /// No description provided for @playlistPickerNewConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add to list'**
  String get playlistPickerNewConfirm;

  /// No description provided for @playlistPickerNewBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get playlistPickerNewBadge;

  /// No description provided for @playlistPickerNewHint.
  ///
  /// In en, this message translates to:
  /// **'Created when you press Add'**
  String get playlistPickerNewHint;

  /// No description provided for @playlistPickerHasThis.
  ///
  /// In en, this message translates to:
  /// **'has this song'**
  String get playlistPickerHasThis;

  /// No description provided for @playlistPickerHasSome.
  ///
  /// In en, this message translates to:
  /// **'has {have} / {total}'**
  String playlistPickerHasSome(int have, int total);

  /// No description provided for @playlistPickerNoneSelected.
  ///
  /// In en, this message translates to:
  /// **'Choose one or more playlists'**
  String get playlistPickerNoneSelected;

  /// No description provided for @playlistPickerSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String playlistPickerSelected(int count);

  /// No description provided for @playlistPickerAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get playlistPickerAdd;

  /// No description provided for @playlistPickerAddMany.
  ///
  /// In en, this message translates to:
  /// **'Add to {count, plural, =1{1 playlist} other{{count} playlists}}'**
  String playlistPickerAddMany(int count);

  /// No description provided for @playlistAlreadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Already in the playlist'**
  String get playlistAlreadyTitle;

  /// No description provided for @playlistAlreadySkip.
  ///
  /// In en, this message translates to:
  /// **'Only add new songs'**
  String get playlistAlreadySkip;

  /// No description provided for @playlistAlreadySkipHint.
  ///
  /// In en, this message translates to:
  /// **'Songs already there stay as they are'**
  String get playlistAlreadySkipHint;

  /// No description provided for @playlistAlreadyMove.
  ///
  /// In en, this message translates to:
  /// **'Add all, drop the old copies'**
  String get playlistAlreadyMove;

  /// No description provided for @playlistAlreadyMoveHint.
  ///
  /// In en, this message translates to:
  /// **'Songs already there move to the end'**
  String get playlistAlreadyMoveHint;

  /// No description provided for @playlistAlreadyAll.
  ///
  /// In en, this message translates to:
  /// **'Add all'**
  String get playlistAlreadyAll;

  /// No description provided for @playlistAlreadyAllHint.
  ///
  /// In en, this message translates to:
  /// **'Songs already there appear twice'**
  String get playlistAlreadyAllHint;

  /// No description provided for @playlistAlreadyAppliesToAll.
  ///
  /// In en, this message translates to:
  /// **'The choice applies to all of them.'**
  String get playlistAlreadyAppliesToAll;

  /// No description provided for @playlistAddedSummary.
  ///
  /// In en, this message translates to:
  /// **'Added {songs, plural, =1{1 song} other{{songs} songs}} to {playlists, plural, =1{1 playlist} other{{playlists} playlists}}{newPlaylists, plural, =0{} other{ ({newPlaylists} new)}}{skipped, plural, =0{} other{, skipped {skipped}}}'**
  String playlistAddedSummary(
    int songs,
    int playlists,
    int newPlaylists,
    int skipped,
  );

  /// No description provided for @playlistAddedGone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 playlist was} other{{count} playlists were}} deleted meanwhile'**
  String playlistAddedGone(int count);

  /// No description provided for @playlistAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add to the playlist'**
  String get playlistAddFailed;

  /// No description provided for @playlistProSmartNote.
  ///
  /// In en, this message translates to:
  /// **'Smart playlists are part of Pro'**
  String get playlistProSmartNote;

  /// No description provided for @playlistM3uFileTypes.
  ///
  /// In en, this message translates to:
  /// **'Playlist files'**
  String get playlistM3uFileTypes;

  /// No description provided for @playlistM3uImported.
  ///
  /// In en, this message translates to:
  /// **'Imported {count, plural, =1{1 song} other{{count} songs}} into {name}'**
  String playlistM3uImported(int count, String name);

  /// No description provided for @playlistM3uReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Playlist imported'**
  String get playlistM3uReportTitle;

  /// No description provided for @playlistM3uReportSummary.
  ///
  /// In en, this message translates to:
  /// **'Added {added} / {total} lines of {file} to “{name}”.'**
  String playlistM3uReportSummary(
    int added,
    int total,
    String file,
    String name,
  );

  /// No description provided for @playlistM3uReportNotInLibrary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song is not in your library yet: it appears after the next library scan.} other{{count} songs are not in your library yet: they appear after the next library scan.}}'**
  String playlistM3uReportNotInLibrary(int count);

  /// No description provided for @playlistM3uReportUnresolved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line is} other{{count} lines are}} not music files on this device or are outside your music folders (add that folder in Settings › Library):'**
  String playlistM3uReportUnresolved(int count);

  /// No description provided for @playlistM3uReportSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line is a file} other{{count} lines are files}} the library skips when scanning (in a hidden folder, or shorter than 30 seconds while “Skip short songs” is on in Settings › Library):'**
  String playlistM3uReportSkipped(int count);

  /// No description provided for @playlistM3uReportNoBase.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line uses} other{{count} lines use}} relative paths, but the playlist file is not in internal storage, so their starting folder is unknown. Copy the playlist file next to the music folder and import it again:'**
  String playlistM3uReportNoBase(int count);

  /// No description provided for @playlistM3uAllOutside.
  ///
  /// In en, this message translates to:
  /// **'The songs of this playlist are outside your music folders. Add that folder in Settings › Library, then import again. Nothing was imported.'**
  String get playlistM3uAllOutside;

  /// No description provided for @playlistM3uReportLine.
  ///
  /// In en, this message translates to:
  /// **'Line {line}: {text}'**
  String playlistM3uReportLine(int line, String text);

  /// No description provided for @playlistM3uReportMore.
  ///
  /// In en, this message translates to:
  /// **'and {count, plural, =1{1 more line} other{{count} more lines}}'**
  String playlistM3uReportMore(int count);

  /// No description provided for @playlistM3uOpenPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Open playlist'**
  String get playlistM3uOpenPlaylist;

  /// No description provided for @playlistM3uNothingFound.
  ///
  /// In en, this message translates to:
  /// **'No song of this playlist was found on this device. Nothing was imported.'**
  String get playlistM3uNothingFound;

  /// No description provided for @playlistM3uTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The file is too large to be a playlist.'**
  String get playlistM3uTooLarge;

  /// No description provided for @playlistM3uReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the file.'**
  String get playlistM3uReadFailed;

  /// No description provided for @playlistM3uExported.
  ///
  /// In en, this message translates to:
  /// **'Saved {count, plural, =1{1 song} other{{count} songs}} to {file}'**
  String playlistM3uExported(int count, String file);

  /// No description provided for @playlistM3uReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace {file}?'**
  String playlistM3uReplaceTitle(String file);

  /// No description provided for @playlistM3uExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the file.'**
  String get playlistM3uExportFailed;

  /// No description provided for @plScreensFavoritesLine.
  ///
  /// In en, this message translates to:
  /// **'Songs you tapped'**
  String get plScreensFavoritesLine;

  /// No description provided for @plScreensFavoritesLineSemantics.
  ///
  /// In en, this message translates to:
  /// **'Songs you liked'**
  String get plScreensFavoritesLineSemantics;

  /// No description provided for @plScreensDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted “{name}”'**
  String plScreensDeleted(String name);

  /// No description provided for @plScreensDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the playlist'**
  String get plScreensDeleteFailed;

  /// No description provided for @plScreensCharCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max}'**
  String plScreensCharCount(int count, int max);

  /// No description provided for @plScreensCoverFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change the cover'**
  String get plScreensCoverFailed;

  /// No description provided for @plScreensDuplicateCopyCover.
  ///
  /// In en, this message translates to:
  /// **'Copy the custom cover too'**
  String get plScreensDuplicateCopyCover;

  /// No description provided for @plScreensDuplicateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get plScreensDuplicateConfirm;

  /// No description provided for @plScreensPlay.
  ///
  /// In en, this message translates to:
  /// **'Play playlist'**
  String get plScreensPlay;

  /// No description provided for @plScreensEditList.
  ///
  /// In en, this message translates to:
  /// **'Edit list'**
  String get plScreensEditList;

  /// No description provided for @plScreensEditDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get plScreensEditDone;

  /// No description provided for @plScreensEditBarLead.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}} · Playlist order'**
  String plScreensEditBarLead(int count);

  /// No description provided for @plScreensUnitPlaylists.
  ///
  /// In en, this message translates to:
  /// **'playlists'**
  String get plScreensUnitPlaylists;

  /// Toast suffix: old copies of songs removed when they were moved to the end of a playlist.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{, dropped 1 old copy} other{, dropped {count} old copies}}'**
  String plAddMovedSuffix(int count);

  /// Toast suffix for one target: songs skipped because the playlist already had them.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{, skipped 1} other{, skipped {count}}}'**
  String plAddSkippedSuffix(int count);

  /// Question body: songs the one ticked playlist already holds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song is} other{{count} songs are}} already in “{name}”.'**
  String plAddAlreadyInOne(int count, String name);

  /// Question body: several ticked playlists already hold some songs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Some songs are already in 1 playlist.} other{Some songs are already in {count} playlists.}}'**
  String plAddAlreadyInMany(int count);

  /// Default name of a new playlist when the plain default is taken; the number starts at 2.
  ///
  /// In en, this message translates to:
  /// **'New playlist {count}'**
  String plAddDefaultNameNumbered(int count);

  /// Toast: songs added to one playlist.
  ///
  /// In en, this message translates to:
  /// **'Added {count, plural, =1{1 song} other{{count} songs}} to “{name}”'**
  String plAddAddedToOne(int count, String name);

  /// Toast: nothing was added because the one playlist held every song.
  ///
  /// In en, this message translates to:
  /// **'Every song is already in “{name}”'**
  String plAddNothingNewOne(String name);

  /// Toast: nothing was added because every playlist held every song.
  ///
  /// In en, this message translates to:
  /// **'Every song is already in the {count} playlists'**
  String plAddNothingNewMany(int count);

  /// Source label in the picker header when the songs are the play queue.
  ///
  /// In en, this message translates to:
  /// **'from the queue'**
  String get plAddSourceQueue;

  /// Toast suffix: songs left out because they were removed from the library.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{, 1 song no longer in the library} other{, {count} songs no longer in the library}}'**
  String plAddDroppedSuffix(int count);

  /// Toast: every song was removed from the library before adding.
  ///
  /// In en, this message translates to:
  /// **'These songs are no longer in your library'**
  String get plAddSongsGone;

  /// Toast: reading playlists took too long.
  ///
  /// In en, this message translates to:
  /// **'This is taking too long. Try again.'**
  String get plAddTimedOut;

  /// Toast: the write did not answer in time.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t confirm the songs were added. Check the playlist.'**
  String get plAddNotConfirmed;

  /// Title of the card shown on the playlists page while an M3U file is imported.
  ///
  /// In en, this message translates to:
  /// **'Importing {file}'**
  String m3uImportProgressTitle(String file);

  /// Subtitle of the M3U import card: lines read so far out of all lines.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} lines'**
  String m3uImportProgressLines(int done, int total);

  /// Toast: an M3U import failed for an unexpected reason. Nothing was created.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t import the file.'**
  String get m3uImportFailed;

  /// Note at the end of the M3U import report when the file was cut.
  ///
  /// In en, this message translates to:
  /// **'The file has more lines than the limit, so only the first {max} were read.'**
  String m3uReportTruncated(int max);

  /// Export toast when some songs were left out of the M3U file.
  ///
  /// In en, this message translates to:
  /// **'Saved {count, plural, =1{1 song} other{{count} songs}} to {file}, {skipped, plural, =1{1 skipped (no file on this device)} other{{skipped} skipped (no file on this device)}}'**
  String m3uExportedSkipped(int count, String file, int skipped);

  /// Toast: a relative-path export was refused because the chosen location has no known folder.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t write relative paths: the folder of this file is unknown. Save it in internal storage, or export with absolute paths.'**
  String get m3uExportFolderUnknown;

  /// Confirm button when the chosen M3U file already exists.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get m3uExportReplace;

  /// M3U import report (Android): lines naming files that exist but are not in MediaStore, so no placeholder was created.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line is a file that is on this device but not in Android\'s media index, so the library cannot see it} other{{count} lines are files that are on this device but not in Android\'s media index, so the library cannot see them}}. Go to Settings › Library › Music folders › Add folder, tap “Can\'t see your folder? Rescan”, then import again:'**
  String m3uReportNotIndexed(int count);

  /// Toast: an M3U import created nothing because every usable line is a file Android has not indexed.
  ///
  /// In en, this message translates to:
  /// **'Android\'s media index does not list the music files of this playlist yet, so the library cannot see them. Go to Settings › Library › Music folders › Add folder, tap “Can\'t see your folder? Rescan”, then import again. Nothing was imported.'**
  String get m3uImportNotIndexed;

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

  /// No description provided for @settingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save settings. Changes last until the app closes.'**
  String get settingsSaveFailed;

  /// No description provided for @settingsRootAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsRootAppearance;

  /// No description provided for @settingsRootAppearanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Theme, language, colors, text, seek bar'**
  String get settingsRootAppearanceDesc;

  /// No description provided for @settingsRootLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get settingsRootLibrary;

  /// No description provided for @settingsRootLibraryDesc.
  ///
  /// In en, this message translates to:
  /// **'Music folders, scan, tabs, artist split'**
  String get settingsRootLibraryDesc;

  /// No description provided for @settingsRootLibraryMissingPermission.
  ///
  /// In en, this message translates to:
  /// **' · music permission missing'**
  String get settingsRootLibraryMissingPermission;

  /// No description provided for @settingsRootPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get settingsRootPlayback;

  /// No description provided for @settingsRootPlaybackDesc.
  ///
  /// In en, this message translates to:
  /// **'Gapless, sound, ReplayGain, listening history'**
  String get settingsRootPlaybackDesc;

  /// No description provided for @settingsRootLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get settingsRootLyrics;

  /// No description provided for @settingsRootLyricsDesc.
  ///
  /// In en, this message translates to:
  /// **'Display, search and save, sources, translation'**
  String get settingsRootLyricsDesc;

  /// No description provided for @settingsRootPlugins.
  ///
  /// In en, this message translates to:
  /// **'Plugins'**
  String get settingsRootPlugins;

  /// No description provided for @settingsRootPluginsDesc.
  ///
  /// In en, this message translates to:
  /// **'Installed plugins, plugin store, updates'**
  String get settingsRootPluginsDesc;

  /// No description provided for @settingsRootAi.
  ///
  /// In en, this message translates to:
  /// **'AI chat'**
  String get settingsRootAi;

  /// No description provided for @settingsRootAiDesc.
  ///
  /// In en, this message translates to:
  /// **'AI services, permissions, tools, skills, history'**
  String get settingsRootAiDesc;

  /// No description provided for @settingsRootIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get settingsRootIntegrations;

  /// No description provided for @settingsRootIntegrationsDescDesktop.
  ///
  /// In en, this message translates to:
  /// **'MCP server, web server on the local network'**
  String get settingsRootIntegrationsDescDesktop;

  /// No description provided for @settingsRootIntegrationsDescMobile.
  ///
  /// In en, this message translates to:
  /// **'Web server on the local network'**
  String get settingsRootIntegrationsDescMobile;

  /// No description provided for @settingsRootData.
  ///
  /// In en, this message translates to:
  /// **'Data and storage'**
  String get settingsRootData;

  /// No description provided for @settingsRootDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Cache, backup'**
  String get settingsRootDataDesc;

  /// No description provided for @settingsRootAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsRootAdvanced;

  /// No description provided for @settingsRootAdvancedDesc.
  ///
  /// In en, this message translates to:
  /// **'Logs, privacy, reset'**
  String get settingsRootAdvancedDesc;

  /// No description provided for @settingsRootPro.
  ///
  /// In en, this message translates to:
  /// **'Kanaru Pro'**
  String get settingsRootPro;

  /// No description provided for @settingsRootProFreeDesc.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase · sync, many sources, advanced stats…'**
  String get settingsRootProFreeDesc;

  /// No description provided for @settingsRootProActive.
  ///
  /// In en, this message translates to:
  /// **'Activated · thank you'**
  String get settingsRootProActive;

  /// No description provided for @settingsRootAboutDesc.
  ///
  /// In en, this message translates to:
  /// **'License, native libraries'**
  String get settingsRootAboutDesc;

  /// No description provided for @settingsAppearanceColorMotionTitle.
  ///
  /// In en, this message translates to:
  /// **'Color and motion'**
  String get settingsAppearanceColorMotionTitle;

  /// No description provided for @settingsAppearancePureBlack.
  ///
  /// In en, this message translates to:
  /// **'Pure black'**
  String get settingsAppearancePureBlack;

  /// No description provided for @settingsAppearancePureBlackNeedsDark.
  ///
  /// In en, this message translates to:
  /// **'Dark theme only'**
  String get settingsAppearancePureBlackNeedsDark;

  /// No description provided for @settingsAppearanceMotion.
  ///
  /// In en, this message translates to:
  /// **'Animations'**
  String get settingsAppearanceMotion;

  /// No description provided for @settingsAppearanceTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get settingsAppearanceTextTitle;

  /// No description provided for @settingsAppearanceFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get settingsAppearanceFont;

  /// No description provided for @settingsAppearanceTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingsAppearanceTextSize;

  /// No description provided for @settingsAppearanceDisplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get settingsAppearanceDisplayTitle;

  /// No description provided for @settingsAppearanceSeekBar.
  ///
  /// In en, this message translates to:
  /// **'Seek bar'**
  String get settingsAppearanceSeekBar;

  /// No description provided for @settingsAppearanceWindowFrame.
  ///
  /// In en, this message translates to:
  /// **'System window frame'**
  String get settingsAppearanceWindowFrame;

  /// No description provided for @settingsSeekBarCaption.
  ///
  /// In en, this message translates to:
  /// **'Used in Now Playing and the lyrics screen.'**
  String get settingsSeekBarCaption;

  /// No description provided for @settingsSeekBarWaveform.
  ///
  /// In en, this message translates to:
  /// **'Waveform'**
  String get settingsSeekBarWaveform;

  /// No description provided for @settingsSeekBarWaveformCaption.
  ///
  /// In en, this message translates to:
  /// **'Local files and some plugins. Tracks without a waveform use the flat bar.'**
  String get settingsSeekBarWaveformCaption;

  /// No description provided for @settingsSeekBarFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat bar'**
  String get settingsSeekBarFlat;

  /// No description provided for @settingsSeekBarFlatCaption.
  ///
  /// In en, this message translates to:
  /// **'Every track'**
  String get settingsSeekBarFlatCaption;

  /// No description provided for @settingsAboutEditionFree.
  ///
  /// In en, this message translates to:
  /// **'Free edition'**
  String get settingsAboutEditionFree;

  /// No description provided for @settingsAboutEditionPro.
  ///
  /// In en, this message translates to:
  /// **'Kanaru Pro'**
  String get settingsAboutEditionPro;

  /// No description provided for @settingsAboutLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get settingsAboutLicenses;

  /// No description provided for @settingsPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent} %'**
  String settingsPercent(int percent);

  /// No description provided for @settingsAboutLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get settingsAboutLicense;

  /// No description provided for @settingsPlaybackBlockPlay.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get settingsPlaybackBlockPlay;

  /// No description provided for @settingsPlaybackBlockSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingsPlaybackBlockSound;

  /// No description provided for @settingsPlaybackBlockHistory.
  ///
  /// In en, this message translates to:
  /// **'Listening history'**
  String get settingsPlaybackBlockHistory;

  /// No description provided for @settingsPlaybackGapless.
  ///
  /// In en, this message translates to:
  /// **'Gapless playback'**
  String get settingsPlaybackGapless;

  /// No description provided for @settingsPlaybackGaplessDesc.
  ///
  /// In en, this message translates to:
  /// **'Applies from the next track'**
  String get settingsPlaybackGaplessDesc;

  /// No description provided for @settingsPlaybackFadeIn.
  ///
  /// In en, this message translates to:
  /// **'Fade in when playing'**
  String get settingsPlaybackFadeIn;

  /// No description provided for @settingsPlaybackFadeOut.
  ///
  /// In en, this message translates to:
  /// **'Fade out when pausing'**
  String get settingsPlaybackFadeOut;

  /// No description provided for @settingsPlaybackCrossfade.
  ///
  /// In en, this message translates to:
  /// **'Crossfade'**
  String get settingsPlaybackCrossfade;

  /// No description provided for @settingsPlaybackCrossfadeDesc.
  ///
  /// In en, this message translates to:
  /// **'Crossfade: the old track fades out while the new one fades in.'**
  String get settingsPlaybackCrossfadeDesc;

  /// No description provided for @settingsPlaybackOutputDevice.
  ///
  /// In en, this message translates to:
  /// **'Output device'**
  String get settingsPlaybackOutputDevice;

  /// No description provided for @settingsPlaybackReplayGain.
  ///
  /// In en, this message translates to:
  /// **'ReplayGain'**
  String get settingsPlaybackReplayGain;

  /// No description provided for @settingsPlaybackPreamp.
  ///
  /// In en, this message translates to:
  /// **'Preamp'**
  String get settingsPlaybackPreamp;

  /// No description provided for @settingsPlaybackClipping.
  ///
  /// In en, this message translates to:
  /// **'Prevent clipping'**
  String get settingsPlaybackClipping;

  /// No description provided for @settingsPlaybackClippingDesc.
  ///
  /// In en, this message translates to:
  /// **'Lowers the level when the preamp would distort the sound.'**
  String get settingsPlaybackClippingDesc;

  /// No description provided for @settingsPlaybackOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsPlaybackOff;

  /// No description provided for @settingsPlaybackAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get settingsPlaybackAuto;

  /// No description provided for @settingsPlaybackPreviousButton.
  ///
  /// In en, this message translates to:
  /// **'Previous button'**
  String get settingsPlaybackPreviousButton;

  /// No description provided for @settingsPlaybackPreviousAlways.
  ///
  /// In en, this message translates to:
  /// **'Always go to the previous track'**
  String get settingsPlaybackPreviousAlways;

  /// No description provided for @settingsPlaybackPreviousAlwaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsPlaybackPreviousAlwaysDesc;

  /// No description provided for @settingsPlaybackPreviousRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart after 3 seconds'**
  String get settingsPlaybackPreviousRestart;

  /// No description provided for @settingsPlaybackPreviousRestartDesc.
  ///
  /// In en, this message translates to:
  /// **'Within the first 3 seconds it goes to the previous track.'**
  String get settingsPlaybackPreviousRestartDesc;

  /// No description provided for @settingsPlaybackHistory.
  ///
  /// In en, this message translates to:
  /// **'Record listening history'**
  String get settingsPlaybackHistory;

  /// No description provided for @settingsPlaybackHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Used by History, Most played and Continue listening.'**
  String get settingsPlaybackHistoryDesc;

  /// No description provided for @settingsPlaybackHistoryOff.
  ///
  /// In en, this message translates to:
  /// **'Off · what was recorded stays'**
  String get settingsPlaybackHistoryOff;

  /// No description provided for @settingsPlaybackListenRule.
  ///
  /// In en, this message translates to:
  /// **'Count a listen after'**
  String get settingsPlaybackListenRule;

  /// No description provided for @settingsPlaybackListenCaption.
  ///
  /// In en, this message translates to:
  /// **'A track counts as a listen when it reaches whichever comes first. Default: 4 minutes or 50 %.'**
  String get settingsPlaybackListenCaption;

  /// No description provided for @settingsPlaybackListenNeedsHistory.
  ///
  /// In en, this message translates to:
  /// **'Turn on Record listening history to use this'**
  String get settingsPlaybackListenNeedsHistory;

  /// No description provided for @settingsPlaybackListenNoTime.
  ///
  /// In en, this message translates to:
  /// **'Not used'**
  String get settingsPlaybackListenNoTime;

  /// No description provided for @settingsPlaybackListenEndLabel.
  ///
  /// In en, this message translates to:
  /// **'Whole track'**
  String get settingsPlaybackListenEndLabel;

  /// No description provided for @settingsPlaybackListenTimeLive.
  ///
  /// In en, this message translates to:
  /// **'After {duration} of listening'**
  String settingsPlaybackListenTimeLive(String duration);

  /// No description provided for @settingsPlaybackListenNoTimeLive.
  ///
  /// In en, this message translates to:
  /// **'Not counted by time'**
  String get settingsPlaybackListenNoTimeLive;

  /// No description provided for @settingsPlaybackListenPercentLive.
  ///
  /// In en, this message translates to:
  /// **'or after {percent} % of the track'**
  String settingsPlaybackListenPercentLive(int percent);

  /// No description provided for @settingsPlaybackListenEndLive.
  ///
  /// In en, this message translates to:
  /// **'or after the whole track'**
  String get settingsPlaybackListenEndLive;

  /// No description provided for @settingsPlaybackListenTimeOrPercent.
  ///
  /// In en, this message translates to:
  /// **'{duration} or {percent} %'**
  String settingsPlaybackListenTimeOrPercent(String duration, int percent);

  /// No description provided for @settingsPlaybackListenTimeOrEnd.
  ///
  /// In en, this message translates to:
  /// **'{duration} or the whole track'**
  String settingsPlaybackListenTimeOrEnd(String duration);

  /// No description provided for @settingsPlaybackListenEnd.
  ///
  /// In en, this message translates to:
  /// **'Listen to the end'**
  String get settingsPlaybackListenEnd;

  /// No description provided for @settingsPlaybackListenPercentOnly.
  ///
  /// In en, this message translates to:
  /// **'{percent} % of the track'**
  String settingsPlaybackListenPercentOnly(int percent);

  /// No description provided for @settingsDurationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{1 second} other{{seconds} seconds}}'**
  String settingsDurationSeconds(int seconds);

  /// No description provided for @settingsDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String settingsDurationMinutes(int minutes);

  /// No description provided for @settingsDurationMinutesSeconds.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {seconds} s'**
  String settingsDurationMinutesSeconds(int minutes, int seconds);

  /// No description provided for @settingsPlaybackPreampValue.
  ///
  /// In en, this message translates to:
  /// **'{db} dB'**
  String settingsPlaybackPreampValue(int db);

  /// No description provided for @settingsAppearancePureBlackDesc.
  ///
  /// In en, this message translates to:
  /// **'A fully black background in the Dark theme, good for OLED screens.'**
  String get settingsAppearancePureBlackDesc;

  /// No description provided for @settingsAppearanceMotionDesc.
  ///
  /// In en, this message translates to:
  /// **'Off: pages and sheets appear at once, without sliding.'**
  String get settingsAppearanceMotionDesc;

  /// No description provided for @settingsAppearanceWindowFrameDesc.
  ///
  /// In en, this message translates to:
  /// **'Use the system title bar and window border instead of the Kanaru bar.'**
  String get settingsAppearanceWindowFrameDesc;

  /// No description provided for @settingsAppearanceWindowFrameApply.
  ///
  /// In en, this message translates to:
  /// **'Applies after Kanaru is reopened'**
  String get settingsAppearanceWindowFrameApply;

  /// No description provided for @settingsAppearanceTextSizeDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsAppearanceTextSizeDefault;

  /// No description provided for @settingsPlaybackNeedsReplayGain.
  ///
  /// In en, this message translates to:
  /// **'Turn on ReplayGain to use this'**
  String get settingsPlaybackNeedsReplayGain;
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
