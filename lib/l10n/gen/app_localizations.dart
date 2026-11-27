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
  /// **'All permissions allowed'**
  String get scanSetupPermissionsGranted;

  /// No description provided for @scanSetupPermissionsGrantedDesc.
  ///
  /// In en, this message translates to:
  /// **'Music and audio · Photos and videos'**
  String get scanSetupPermissionsGrantedDesc;

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

  /// No description provided for @scanHomeChangeFolders.
  ///
  /// In en, this message translates to:
  /// **'Change folders'**
  String get scanHomeChangeFolders;

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

  /// No description provided for @playbackSeekCancel.
  ///
  /// In en, this message translates to:
  /// **'Release to cancel'**
  String get playbackSeekCancel;

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

  /// No description provided for @playbackNoticeRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get playbackNoticeRetry;

  /// No description provided for @playbackNoticeOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get playbackNoticeOpenSettings;

  /// No description provided for @playbackNoticeFailedLink.
  ///
  /// In en, this message translates to:
  /// **'Could not play “{title}”: {source} returned no stream link ({code})'**
  String playbackNoticeFailedLink(String title, String source, String code);

  /// No description provided for @playbackNoticeFailedFormat.
  ///
  /// In en, this message translates to:
  /// **'Could not play “{title}”: Kanaru cannot play {source}\'s format yet'**
  String playbackNoticeFailedFormat(String title, String source);

  /// No description provided for @playbackNoticeFailedGone.
  ///
  /// In en, this message translates to:
  /// **'Skipped “{title}”: no longer on {source}'**
  String playbackNoticeFailedGone(String title, String source);

  /// No description provided for @playbackNoticeFailedCode.
  ///
  /// In en, this message translates to:
  /// **'Could not play “{title}” ({code})'**
  String playbackNoticeFailedCode(String title, String code);

  /// No description provided for @playbackNoticePausedOffline.
  ///
  /// In en, this message translates to:
  /// **'No network: online tracks cannot play'**
  String get playbackNoticePausedOffline;

  /// No description provided for @playbackNoticePausedRateLimited.
  ///
  /// In en, this message translates to:
  /// **'{source} paused for {length} (429). Playback can resume in {time}.'**
  String playbackNoticePausedRateLimited(
    String source,
    String length,
    String time,
  );

  /// No description provided for @playbackNoticePauseEnded.
  ///
  /// In en, this message translates to:
  /// **'{source} is no longer paused.'**
  String playbackNoticePauseEnded(String source);

  /// No description provided for @playbackNoticePauseMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 minute} other{{n} minutes}}'**
  String playbackNoticePauseMinutes(int n);

  /// No description provided for @playbackNoticePauseSeconds.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 second} other{{n} seconds}}'**
  String playbackNoticePauseSeconds(int n);

  /// No description provided for @playbackNoticePausedNeedsConfig.
  ///
  /// In en, this message translates to:
  /// **'{source} needs setting up before it can play.'**
  String playbackNoticePausedNeedsConfig(String source);

  /// No description provided for @playbackNoticePausedBusy.
  ///
  /// In en, this message translates to:
  /// **'{source} is not answering: paused at this track.'**
  String playbackNoticePausedBusy(String source);

  /// No description provided for @playbackNoticeSkippedRemoved.
  ///
  /// In en, this message translates to:
  /// **'Skipped “{title}”: its plugin was removed'**
  String playbackNoticeSkippedRemoved(String title);

  /// No description provided for @playbackNoticeSkippedRemovedMany.
  ///
  /// In en, this message translates to:
  /// **'Skipped “{title}” and {others} more: their plugin was removed'**
  String playbackNoticeSkippedRemovedMany(String title, String others);

  /// No description provided for @playbackNoticeSkippedLocked.
  ///
  /// In en, this message translates to:
  /// **'Skipped “{title}”: needs Kanaru Pro'**
  String playbackNoticeSkippedLocked(String title);

  /// No description provided for @playbackNoticeSkippedLockedMany.
  ///
  /// In en, this message translates to:
  /// **'Skipped “{title}” and {others} more: need Kanaru Pro'**
  String playbackNoticeSkippedLockedMany(String title, String others);

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
  /// **'Play'**
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
  /// **'Keeps the files; undo in Settings › Library › Exclusions'**
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
  /// **'Path'**
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

  /// No description provided for @libraryInfoGroupTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get libraryInfoGroupTags;

  /// No description provided for @libraryInfoGroupAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get libraryInfoGroupAudio;

  /// No description provided for @libraryInfoGroupFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get libraryInfoGroupFile;

  /// No description provided for @libraryInfoGroupYou.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get libraryInfoGroupYou;

  /// No description provided for @libraryInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get libraryInfoTitle;

  /// No description provided for @libraryInfoArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get libraryInfoArtist;

  /// No description provided for @libraryInfoAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get libraryInfoAlbum;

  /// No description provided for @libraryInfoAlbumArtist.
  ///
  /// In en, this message translates to:
  /// **'Album artist'**
  String get libraryInfoAlbumArtist;

  /// No description provided for @libraryInfoGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get libraryInfoGenre;

  /// No description provided for @libraryInfoComposer.
  ///
  /// In en, this message translates to:
  /// **'Composer'**
  String get libraryInfoComposer;

  /// No description provided for @libraryInfoReleased.
  ///
  /// In en, this message translates to:
  /// **'Release date'**
  String get libraryInfoReleased;

  /// No description provided for @libraryInfoTrackNo.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get libraryInfoTrackNo;

  /// No description provided for @libraryInfoDisc.
  ///
  /// In en, this message translates to:
  /// **'Disc'**
  String get libraryInfoDisc;

  /// No description provided for @libraryInfoLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get libraryInfoLanguage;

  /// No description provided for @libraryInfoComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get libraryInfoComment;

  /// No description provided for @libraryInfoDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get libraryInfoDescription;

  /// No description provided for @libraryInfoDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get libraryInfoDuration;

  /// No description provided for @libraryInfoCodec.
  ///
  /// In en, this message translates to:
  /// **'Codec'**
  String get libraryInfoCodec;

  /// No description provided for @libraryInfoChannels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get libraryInfoChannels;

  /// No description provided for @libraryInfoReplayGain.
  ///
  /// In en, this message translates to:
  /// **'ReplayGain'**
  String get libraryInfoReplayGain;

  /// No description provided for @libraryInfoMusicFolder.
  ///
  /// In en, this message translates to:
  /// **'Music folder'**
  String get libraryInfoMusicFolder;

  /// No description provided for @libraryInfoModified.
  ///
  /// In en, this message translates to:
  /// **'File modified'**
  String get libraryInfoModified;

  /// No description provided for @libraryInfoAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get libraryInfoAdded;

  /// No description provided for @libraryInfoFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get libraryInfoFavorite;

  /// No description provided for @libraryInfoRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get libraryInfoRating;

  /// No description provided for @libraryInfoSkips.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get libraryInfoSkips;

  /// No description provided for @libraryInfoFirstPlayed.
  ///
  /// In en, this message translates to:
  /// **'First played'**
  String get libraryInfoFirstPlayed;

  /// No description provided for @libraryInfoLastPlayed.
  ///
  /// In en, this message translates to:
  /// **'Last played'**
  String get libraryInfoLastPlayed;

  /// No description provided for @libraryInfoNeverPlayed.
  ///
  /// In en, this message translates to:
  /// **'Never played'**
  String get libraryInfoNeverPlayed;

  /// No description provided for @libraryInfoFavoriteOn.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get libraryInfoFavoriteOn;

  /// No description provided for @libraryInfoFavoriteOff.
  ///
  /// In en, this message translates to:
  /// **'Not a favorite'**
  String get libraryInfoFavoriteOff;

  /// No description provided for @libraryInfoUnknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown artist'**
  String get libraryInfoUnknownArtist;

  /// No description provided for @libraryInfoAutoDetected.
  ///
  /// In en, this message translates to:
  /// **'detected'**
  String get libraryInfoAutoDetected;

  /// No description provided for @libraryInfoThisYear.
  ///
  /// In en, this message translates to:
  /// **'this year'**
  String get libraryInfoThisYear;

  /// No description provided for @libraryInfoMono.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get libraryInfoMono;

  /// No description provided for @libraryInfoStereo.
  ///
  /// In en, this message translates to:
  /// **'Stereo'**
  String get libraryInfoStereo;

  /// No description provided for @libraryInfoYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year ago} other{{count} years ago}}'**
  String libraryInfoYearsAgo(int count);

  /// No description provided for @libraryInfoChannelCount.
  ///
  /// In en, this message translates to:
  /// **'{count} channels'**
  String libraryInfoChannelCount(int count);

  /// No description provided for @libraryInfoTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time} other{{count} times}}'**
  String libraryInfoTimes(int count);

  /// No description provided for @libraryInfoBitrateAverage.
  ///
  /// In en, this message translates to:
  /// **'{kbps} kbps (average)'**
  String libraryInfoBitrateAverage(int kbps);

  /// No description provided for @libraryInfoDateWithAge.
  ///
  /// In en, this message translates to:
  /// **'{date} · {age}'**
  String libraryInfoDateWithAge(String date, String age);

  /// No description provided for @libraryInfoShowEmpty.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Show 1 empty field} other{Show {count} empty fields}}'**
  String libraryInfoShowEmpty(int count);

  /// No description provided for @libraryInfoHideEmpty.
  ///
  /// In en, this message translates to:
  /// **'Hide empty fields'**
  String get libraryInfoHideEmpty;

  /// No description provided for @libraryInfoNoEmpty.
  ///
  /// In en, this message translates to:
  /// **'No empty fields'**
  String get libraryInfoNoEmpty;

  /// No description provided for @libraryInfoEmptyBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 empty field} other{{count} empty fields}}'**
  String libraryInfoEmptyBadge(int count);

  /// No description provided for @libraryInfoMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get libraryInfoMissingTitle;

  /// No description provided for @libraryInfoMissingBody.
  ///
  /// In en, this message translates to:
  /// **'Missing since {date}. The song stays in the library with what was read last; it returns when the file is back and scanned again.'**
  String libraryInfoMissingBody(String date);

  /// No description provided for @libraryInfoMissingBodyNoDate.
  ///
  /// In en, this message translates to:
  /// **'The song stays in the library with what was read last; it returns when the file is back and scanned again.'**
  String get libraryInfoMissingBodyNoDate;

  /// No description provided for @libraryInfoScanErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags could not be read'**
  String get libraryInfoScanErrorTitle;

  /// No description provided for @libraryInfoScanErrorBody.
  ///
  /// In en, this message translates to:
  /// **'The file is damaged or in a format Kanaru cannot read tags from.'**
  String get libraryInfoScanErrorBody;

  /// No description provided for @libraryInfoTaglessTitle.
  ///
  /// In en, this message translates to:
  /// **'This file has almost no tags'**
  String get libraryInfoTaglessTitle;

  /// No description provided for @libraryInfoTaglessBody.
  ///
  /// In en, this message translates to:
  /// **'No artist, album, genre or year. The title comes from the file name. Edit tags in the song menu › Edit song info.'**
  String get libraryInfoTaglessBody;

  /// No description provided for @libraryInfoCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied: {value}'**
  String libraryInfoCopied(String value);

  /// No description provided for @libraryInfoGoArtist.
  ///
  /// In en, this message translates to:
  /// **'Open artist page {name}'**
  String libraryInfoGoArtist(String name);

  /// No description provided for @libraryInfoGoAlbum.
  ///
  /// In en, this message translates to:
  /// **'Open album page {name}'**
  String libraryInfoGoAlbum(String name);

  /// No description provided for @libraryInfoGoGenre.
  ///
  /// In en, this message translates to:
  /// **'Open genre page {name}'**
  String libraryInfoGoGenre(String name);

  /// No description provided for @libraryInfoGoLanguage.
  ///
  /// In en, this message translates to:
  /// **'Open language page {name}'**
  String libraryInfoGoLanguage(String name);

  /// No description provided for @libraryInfoMore.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get libraryInfoMore;

  /// No description provided for @libraryInfoClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get libraryInfoClose;

  /// No description provided for @libraryInfoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the song info'**
  String get libraryInfoLoadFailed;

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

  /// Title of the cover dialog (album, artist, playlist).
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get coverDialogTitle;

  /// Tooltip of the cover button in an album menu header.
  ///
  /// In en, this message translates to:
  /// **'Edit album cover'**
  String get coverEditAlbumTooltip;

  /// Tooltip of the cover button in an artist menu header.
  ///
  /// In en, this message translates to:
  /// **'Set artist image'**
  String get coverEditArtistTooltip;

  /// Row that picks the automatic cover.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get coverAutoTitle;

  /// Subtitle of the automatic cover row (album).
  ///
  /// In en, this message translates to:
  /// **'Cover in the music file'**
  String get coverAutoSubtitleAlbum;

  /// Subtitle of the automatic cover row (artist).
  ///
  /// In en, this message translates to:
  /// **'First album cover'**
  String get coverAutoSubtitleArtist;

  /// Subtitle of the automatic cover row (playlist).
  ///
  /// In en, this message translates to:
  /// **'Made from the first 4 album covers'**
  String get coverAutoSubtitlePlaylist;

  /// Row of the custom cover the item has now.
  ///
  /// In en, this message translates to:
  /// **'Current image'**
  String get coverCurrentTitle;

  /// Subtitle of the current custom cover row.
  ///
  /// In en, this message translates to:
  /// **'Chosen earlier'**
  String get coverCurrentSubtitle;

  /// Group title of the album suggestions for an artist.
  ///
  /// In en, this message translates to:
  /// **'Covers of the artist\'s albums'**
  String get coverGroupArtistAlbums;

  /// Group title of the album suggestions for a playlist.
  ///
  /// In en, this message translates to:
  /// **'Album covers in the playlist'**
  String get coverGroupPlaylistAlbums;

  /// Row that shows the remaining album suggestions.
  ///
  /// In en, this message translates to:
  /// **'Show {count} more albums'**
  String coverMoreAlbums(int count);

  /// Subtitle of an album suggestion without a year.
  ///
  /// In en, this message translates to:
  /// **'Album cover'**
  String get coverAlbumSubtitle;

  /// Subtitle of an album suggestion.
  ///
  /// In en, this message translates to:
  /// **'Album cover · {year}'**
  String coverAlbumSubtitleYear(int year);

  /// Action row that opens the photo picker (mobile).
  ///
  /// In en, this message translates to:
  /// **'Choose image…'**
  String get coverPickMobile;

  /// Action row that opens the file dialog (desktop).
  ///
  /// In en, this message translates to:
  /// **'Choose image from device…'**
  String get coverPickDesktop;

  /// Subtitle of the picked-image row while its preview is prepared.
  ///
  /// In en, this message translates to:
  /// **'Reading image…'**
  String get coverPickedReading;

  /// Subtitle of the picked-image row; size of the upright original.
  ///
  /// In en, this message translates to:
  /// **'From device · {width} × {height}'**
  String coverPickedSubtitle(int width, int height);

  /// Title of the picked-image row when the picker gave no real file name.
  ///
  /// In en, this message translates to:
  /// **'Image from device'**
  String get coverPickedGeneratedName;

  /// Hint under the preview of a non-square picked image.
  ///
  /// In en, this message translates to:
  /// **'Drag the image to choose the visible part (the image is cropped square)'**
  String get coverPanHint;

  /// Warning card for a picked image with a short side under 500 px.
  ///
  /// In en, this message translates to:
  /// **'Small image ({width} × {height} px): it may look blurry in Now Playing and on the detail page. You can still save it.'**
  String coverSmallImage(int width, int height);

  /// Hint under the preview: automatic chosen while a custom cover exists (album).
  ///
  /// In en, this message translates to:
  /// **'Save: drops your image and uses the cover in the music file again'**
  String get coverHintResetAlbum;

  /// Hint under the preview: automatic chosen while a custom cover exists (artist).
  ///
  /// In en, this message translates to:
  /// **'Save: drops your image and uses the automatic image again'**
  String get coverHintResetArtist;

  /// Hint under the preview: automatic chosen while a custom cover exists (playlist).
  ///
  /// In en, this message translates to:
  /// **'Save: drops your image and uses the automatic cover again'**
  String get coverHintResetPlaylist;

  /// Hint under the preview when an image is chosen.
  ///
  /// In en, this message translates to:
  /// **'The image is copied into Kanaru\'s data; the original file and tags are unchanged'**
  String get coverHintCopied;

  /// Footer scope of the album cover dialog.
  ///
  /// In en, this message translates to:
  /// **'Applies to the album everywhere'**
  String get coverScopeAlbum;

  /// Footer scope of the artist cover dialog.
  ///
  /// In en, this message translates to:
  /// **'The artist\'s image everywhere'**
  String get coverScopeArtist;

  /// Footer scope of the playlist cover dialog.
  ///
  /// In en, this message translates to:
  /// **'This playlist only'**
  String get coverScopePlaylist;

  /// Footer scope when the dialog is opened from the playlist edit form.
  ///
  /// In en, this message translates to:
  /// **'Saved with the other changes when you tap Save in Edit playlist'**
  String get coverScopeForm;

  /// Cancel button of the cover dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get coverCancel;

  /// Save button of the cover dialog.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get coverSave;

  /// Confirm button of the cover dialog opened from the playlist edit form.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get coverChoose;

  /// Overlay on the preview while a file is dragged over it (desktop).
  ///
  /// In en, this message translates to:
  /// **'Drop the image here'**
  String get coverDropHere;

  /// Snack bar after a custom cover was saved.
  ///
  /// In en, this message translates to:
  /// **'Cover changed'**
  String get coverChanged;

  /// Snack bar after the custom cover was removed.
  ///
  /// In en, this message translates to:
  /// **'Automatic cover restored'**
  String get coverResetDone;

  /// Action of the cover snack bar.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get coverUndo;

  /// Snack bar when undoing a cover change failed or is no longer possible.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t undo'**
  String get coverUndoFailed;

  /// Error: the image is undecodable or an unsupported format.
  ///
  /// In en, this message translates to:
  /// **'This image can\'t be used (only JPEG, PNG and WebP are supported)'**
  String get coverErrorFormat;

  /// Error: read/write problem, timeout or any other failure.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the image file. Try again later.'**
  String get coverErrorRead;

  /// Filter label of the Linux file dialog.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get coverLinuxDialogLabel;

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
  /// **'AI services, permissions, tools, prompts, history'**
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

  /// No description provided for @settingsSeekBarStyleBars.
  ///
  /// In en, this message translates to:
  /// **'Bars'**
  String get settingsSeekBarStyleBars;

  /// No description provided for @settingsSeekBarStyleDots.
  ///
  /// In en, this message translates to:
  /// **'Dots'**
  String get settingsSeekBarStyleDots;

  /// No description provided for @settingsSeekBarStyleLine.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get settingsSeekBarStyleLine;

  /// No description provided for @settingsSeekBarStyleMirror.
  ///
  /// In en, this message translates to:
  /// **'Mirror'**
  String get settingsSeekBarStyleMirror;

  /// No description provided for @settingsSeekBarStyleSquiggle.
  ///
  /// In en, this message translates to:
  /// **'Squiggle'**
  String get settingsSeekBarStyleSquiggle;

  /// No description provided for @settingsSeekBarFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat bar'**
  String get settingsSeekBarFlat;

  /// No description provided for @settingsSeekBarStyleBarsCaption.
  ///
  /// In en, this message translates to:
  /// **'Default, compact and easy to read'**
  String get settingsSeekBarStyleBarsCaption;

  /// No description provided for @settingsSeekBarStyleDotsCaption.
  ///
  /// In en, this message translates to:
  /// **'A column of dots like an LED meter'**
  String get settingsSeekBarStyleDotsCaption;

  /// No description provided for @settingsSeekBarStyleLineCaption.
  ///
  /// In en, this message translates to:
  /// **'A continuous wave outline, filled in'**
  String get settingsSeekBarStyleLineCaption;

  /// No description provided for @settingsSeekBarStyleMirrorCaption.
  ///
  /// In en, this message translates to:
  /// **'Wave on top, a faint reflection below'**
  String get settingsSeekBarStyleMirrorCaption;

  /// No description provided for @settingsSeekBarStyleSquiggleCaption.
  ///
  /// In en, this message translates to:
  /// **'A wavy line that drifts while playing, flat when paused'**
  String get settingsSeekBarStyleSquiggleCaption;

  /// No description provided for @settingsSeekBarFlatCaption.
  ///
  /// In en, this message translates to:
  /// **'Every track, no waveform needed'**
  String get settingsSeekBarFlatCaption;

  /// No description provided for @settingsSeekBarPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Tap or drag to try seeking · drag up to cancel'**
  String get settingsSeekBarPreviewHint;

  /// No description provided for @settingsSeekBarStylesTitle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get settingsSeekBarStylesTitle;

  /// No description provided for @settingsSeekBarStylesHint.
  ///
  /// In en, this message translates to:
  /// **'Used in Now Playing and the lyrics screen. The mini player and the player bar keep the flat bar.\n\n★ on Squiggle or Flat bar: the style shown while a track has no waveform yet (being computed, or the source has none), with that style\'s options. The wave grows in place when it arrives. Only one style has the ★.'**
  String get settingsSeekBarStylesHint;

  /// No description provided for @settingsSeekBarFallbackUse.
  ///
  /// In en, this message translates to:
  /// **'Use {style} while a track has no waveform'**
  String settingsSeekBarFallbackUse(String style);

  /// No description provided for @settingsSeekBarFallbackActive.
  ///
  /// In en, this message translates to:
  /// **'Shown while a track has no waveform'**
  String get settingsSeekBarFallbackActive;

  /// No description provided for @settingsSeekBarCustomise.
  ///
  /// In en, this message translates to:
  /// **'Customise'**
  String get settingsSeekBarCustomise;

  /// No description provided for @settingsSeekBarCustomiseTitle.
  ///
  /// In en, this message translates to:
  /// **'Customise · {style}'**
  String settingsSeekBarCustomiseTitle(String style);

  /// No description provided for @settingsSeekBarCustomiseClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get settingsSeekBarCustomiseClose;

  /// No description provided for @settingsSeekBarReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get settingsSeekBarReset;

  /// No description provided for @settingsSeekBarDriftNote.
  ///
  /// In en, this message translates to:
  /// **'A track with no waveform drifts steadily.'**
  String get settingsSeekBarDriftNote;

  /// No description provided for @settingsSeekBarRowDensity.
  ///
  /// In en, this message translates to:
  /// **'Density'**
  String get settingsSeekBarRowDensity;

  /// No description provided for @settingsSeekBarRowPlayed.
  ///
  /// In en, this message translates to:
  /// **'Played colour'**
  String get settingsSeekBarRowPlayed;

  /// No description provided for @settingsSeekBarRowRest.
  ///
  /// In en, this message translates to:
  /// **'Unplayed part'**
  String get settingsSeekBarRowRest;

  /// No description provided for @settingsSeekBarRowFeedback.
  ///
  /// In en, this message translates to:
  /// **'Seek feedback'**
  String get settingsSeekBarRowFeedback;

  /// No description provided for @settingsSeekBarRowAmplitude.
  ///
  /// In en, this message translates to:
  /// **'Wave height'**
  String get settingsSeekBarRowAmplitude;

  /// No description provided for @settingsSeekBarRowWavelength.
  ///
  /// In en, this message translates to:
  /// **'Wave length'**
  String get settingsSeekBarRowWavelength;

  /// No description provided for @settingsSeekBarRowMotion.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get settingsSeekBarRowMotion;

  /// No description provided for @settingsSeekBarRowThumb.
  ///
  /// In en, this message translates to:
  /// **'Thumb'**
  String get settingsSeekBarRowThumb;

  /// No description provided for @settingsSeekBarRowThickness.
  ///
  /// In en, this message translates to:
  /// **'Thickness'**
  String get settingsSeekBarRowThickness;

  /// No description provided for @settingsSeekBarRowEffect.
  ///
  /// In en, this message translates to:
  /// **'Effect while playing'**
  String get settingsSeekBarRowEffect;

  /// No description provided for @settingsSeekBarOptLoose.
  ///
  /// In en, this message translates to:
  /// **'Loose'**
  String get settingsSeekBarOptLoose;

  /// No description provided for @settingsSeekBarOptMid.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get settingsSeekBarOptMid;

  /// No description provided for @settingsSeekBarOptThick.
  ///
  /// In en, this message translates to:
  /// **'Thick'**
  String get settingsSeekBarOptThick;

  /// No description provided for @settingsSeekBarOptDense.
  ///
  /// In en, this message translates to:
  /// **'Dense'**
  String get settingsSeekBarOptDense;

  /// No description provided for @settingsSeekBarOptLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get settingsSeekBarOptLow;

  /// No description provided for @settingsSeekBarOptHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get settingsSeekBarOptHigh;

  /// No description provided for @settingsSeekBarOptShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get settingsSeekBarOptShort;

  /// No description provided for @settingsSeekBarOptLong.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get settingsSeekBarOptLong;

  /// No description provided for @settingsSeekBarOptThin.
  ///
  /// In en, this message translates to:
  /// **'Thin'**
  String get settingsSeekBarOptThin;

  /// No description provided for @settingsSeekBarOptSingle.
  ///
  /// In en, this message translates to:
  /// **'One colour'**
  String get settingsSeekBarOptSingle;

  /// No description provided for @settingsSeekBarOptGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get settingsSeekBarOptGradient;

  /// No description provided for @settingsSeekBarOptByHeight.
  ///
  /// In en, this message translates to:
  /// **'By height'**
  String get settingsSeekBarOptByHeight;

  /// No description provided for @settingsSeekBarOptDim.
  ///
  /// In en, this message translates to:
  /// **'Faded'**
  String get settingsSeekBarOptDim;

  /// No description provided for @settingsSeekBarOptOutline.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get settingsSeekBarOptOutline;

  /// No description provided for @settingsSeekBarOptHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get settingsSeekBarOptHidden;

  /// No description provided for @settingsSeekBarOptJelly.
  ///
  /// In en, this message translates to:
  /// **'Jelly'**
  String get settingsSeekBarOptJelly;

  /// No description provided for @settingsSeekBarOptLens.
  ///
  /// In en, this message translates to:
  /// **'Magnify'**
  String get settingsSeekBarOptLens;

  /// No description provided for @settingsSeekBarOptOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsSeekBarOptOff;

  /// No description provided for @settingsSeekBarOptDrift.
  ///
  /// In en, this message translates to:
  /// **'Drift'**
  String get settingsSeekBarOptDrift;

  /// No description provided for @settingsSeekBarOptMusic.
  ///
  /// In en, this message translates to:
  /// **'Follow music'**
  String get settingsSeekBarOptMusic;

  /// No description provided for @settingsSeekBarOptStill.
  ///
  /// In en, this message translates to:
  /// **'Still'**
  String get settingsSeekBarOptStill;

  /// No description provided for @settingsSeekBarOptThumbBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get settingsSeekBarOptThumbBar;

  /// No description provided for @settingsSeekBarOptThumbDot.
  ///
  /// In en, this message translates to:
  /// **'Dot'**
  String get settingsSeekBarOptThumbDot;

  /// No description provided for @settingsSeekBarOptThumbNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get settingsSeekBarOptThumbNone;

  /// No description provided for @settingsSeekBarOptShine.
  ///
  /// In en, this message translates to:
  /// **'Shine'**
  String get settingsSeekBarOptShine;

  /// No description provided for @settingsSeekBarOptComet.
  ///
  /// In en, this message translates to:
  /// **'Comet'**
  String get settingsSeekBarOptComet;

  /// No description provided for @settingsSeekBarOptSparks.
  ///
  /// In en, this message translates to:
  /// **'Sparks'**
  String get settingsSeekBarOptSparks;

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

  /// No description provided for @settingsSectionHintTooltip.
  ///
  /// In en, this message translates to:
  /// **'About {section}'**
  String settingsSectionHintTooltip(String section);

  /// No description provided for @settingsLibraryTracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}}'**
  String settingsLibraryTracksCount(int count);

  /// No description provided for @settingsLibraryAlbumsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 album} other{{count} albums}}'**
  String settingsLibraryAlbumsCount(int count);

  /// No description provided for @settingsLibraryArtistsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 artist} other{{count} artists}}'**
  String settingsLibraryArtistsCount(int count);

  /// No description provided for @settingsLibraryLastScan.
  ///
  /// In en, this message translates to:
  /// **'Last scan {time} · {added, plural, =1{1 song added} other{{added} songs added}}'**
  String settingsLibraryLastScan(String time, int added);

  /// No description provided for @settingsLibraryBlockScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get settingsLibraryBlockScan;

  /// No description provided for @settingsLibraryBlockOrganise.
  ///
  /// In en, this message translates to:
  /// **'Organise'**
  String get settingsLibraryBlockOrganise;

  /// No description provided for @settingsLibraryBlockRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get settingsLibraryBlockRemoved;

  /// No description provided for @settingsLibraryFoldersEstimate.
  ///
  /// In en, this message translates to:
  /// **'About {count, plural, =1{1 song} other{{count} songs}}'**
  String settingsLibraryFoldersEstimate(int count);

  /// No description provided for @settingsLibraryMinDuration.
  ///
  /// In en, this message translates to:
  /// **'Skip files shorter than'**
  String get settingsLibraryMinDuration;

  /// No description provided for @settingsLibraryMinDurationCaption.
  ///
  /// In en, this message translates to:
  /// **'Ringtones, alerts and short recordings. Applies at the next scan.'**
  String get settingsLibraryMinDurationCaption;

  /// No description provided for @settingsLibraryMinSize.
  ///
  /// In en, this message translates to:
  /// **'Skip files smaller than'**
  String get settingsLibraryMinSize;

  /// No description provided for @settingsLibraryMinSizeCaption.
  ///
  /// In en, this message translates to:
  /// **'Measured by file size. Applies at the next scan.'**
  String get settingsLibraryMinSizeCaption;

  /// No description provided for @settingsLibrarySizeKb.
  ///
  /// In en, this message translates to:
  /// **'{kb} KB'**
  String settingsLibrarySizeKb(int kb);

  /// No description provided for @settingsLibrarySizeMb.
  ///
  /// In en, this message translates to:
  /// **'{mb} MB'**
  String settingsLibrarySizeMb(double mb);

  /// No description provided for @settingsLibraryFormats.
  ///
  /// In en, this message translates to:
  /// **'Scanned formats'**
  String get settingsLibraryFormats;

  /// No description provided for @settingsLibraryFormatsCaption.
  ///
  /// In en, this message translates to:
  /// **'Untick a format to skip it when scanning. Keep at least one.'**
  String get settingsLibraryFormatsCaption;

  /// No description provided for @settingsLibraryFormatsKeepOne.
  ///
  /// In en, this message translates to:
  /// **'keep at least one'**
  String get settingsLibraryFormatsKeepOne;

  /// No description provided for @settingsLibraryFormatsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get settingsLibraryFormatsAll;

  /// No description provided for @settingsLibraryFormatsSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get settingsLibraryFormatsSelectAll;

  /// No description provided for @settingsCountOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{n} / {total}'**
  String settingsCountOfTotal(int n, int total);

  /// No description provided for @settingsLibraryDedupName.
  ///
  /// In en, this message translates to:
  /// **'Merge tracks with the same file name'**
  String get settingsLibraryDedupName;

  /// No description provided for @settingsLibraryDedupNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Files with the same name in different folders show as one track, the highest quality copy. Files are not deleted.'**
  String get settingsLibraryDedupNameDesc;

  /// No description provided for @settingsLibraryNomedia.
  ///
  /// In en, this message translates to:
  /// **'Skip folders with a .nomedia file'**
  String get settingsLibraryNomedia;

  /// No description provided for @settingsLibraryNomediaDesc.
  ///
  /// In en, this message translates to:
  /// **'Like Android: a folder with .nomedia is not scanned.'**
  String get settingsLibraryNomediaDesc;

  /// No description provided for @settingsLibraryWatch.
  ///
  /// In en, this message translates to:
  /// **'Update when folders change'**
  String get settingsLibraryWatch;

  /// No description provided for @settingsLibraryWatchDesc.
  ///
  /// In en, this message translates to:
  /// **'See new files at once, no rescan needed.'**
  String get settingsLibraryWatchDesc;

  /// No description provided for @settingsLibraryRulesApplyLater.
  ///
  /// In en, this message translates to:
  /// **'Applies at the next scan'**
  String get settingsLibraryRulesApplyLater;

  /// No description provided for @settingsLibraryRescanning.
  ///
  /// In en, this message translates to:
  /// **'Rescanning the library in the background'**
  String get settingsLibraryRescanning;

  /// No description provided for @settingsLibraryMergeFolders.
  ///
  /// In en, this message translates to:
  /// **'Merge folders with a single subfolder'**
  String get settingsLibraryMergeFolders;

  /// No description provided for @settingsLibraryMergeFoldersDesc.
  ///
  /// In en, this message translates to:
  /// **'Folders tab: go straight into the only subfolder.'**
  String get settingsLibraryMergeFoldersDesc;

  /// No description provided for @settingsLibraryAlbumGrouping.
  ///
  /// In en, this message translates to:
  /// **'Group albums by'**
  String get settingsLibraryAlbumGrouping;

  /// No description provided for @settingsLibraryRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from library'**
  String get settingsLibraryRemoved;

  /// No description provided for @settingsLibraryTabsHintMobile.
  ///
  /// In en, this message translates to:
  /// **'Turn on the tabs you want, drag to reorder. At least one tab stays on. Tabs are the sub-tab row at the top of Library.'**
  String get settingsLibraryTabsHintMobile;

  /// No description provided for @settingsLibraryTabsHintDesktop.
  ///
  /// In en, this message translates to:
  /// **'Turn on the tabs you want, drag to reorder. At least one tab stays on. Tabs are the Library items in the sidebar.'**
  String get settingsLibraryTabsHintDesktop;

  /// No description provided for @settingsLibraryRemoveFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove “{name}”?'**
  String settingsLibraryRemoveFolderTitle(String name);

  /// No description provided for @settingsLibraryRemoveFolderBody.
  ///
  /// In en, this message translates to:
  /// **'The songs in this folder leave the library (playlists keep their place and mark them as missing).\n\nFiles on your device are not deleted.'**
  String get settingsLibraryRemoveFolderBody;

  /// No description provided for @settingsLibraryRemoveFolderBodyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}} in this folder leave the library (playlists keep their place and mark them as missing).\n\nFiles on your device are not deleted.'**
  String settingsLibraryRemoveFolderBodyCount(int count);

  /// No description provided for @settingsLibraryRemoveFolderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove folder'**
  String get settingsLibraryRemoveFolderConfirm;

  /// No description provided for @settingsLibraryFolderRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed “{name}”'**
  String settingsLibraryFolderRemoved(String name);

  /// No description provided for @settingsLibraryFolderRemovedCount.
  ///
  /// In en, this message translates to:
  /// **'Removed “{name}” · {count, plural, =1{1 song} other{{count} songs}} left the library'**
  String settingsLibraryFolderRemovedCount(String name, int count);

  /// No description provided for @settingsLibraryLastFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot remove the last folder'**
  String get settingsLibraryLastFolderTitle;

  /// No description provided for @settingsLibraryLastFolderBody.
  ///
  /// In en, this message translates to:
  /// **'The library needs at least one music folder. Add another folder first, then remove “{name}”.'**
  String settingsLibraryLastFolderBody(String name);

  /// No description provided for @settingsLibraryGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get settingsLibraryGotIt;

  /// No description provided for @settingsLibraryExclusionRemoved.
  ///
  /// In en, this message translates to:
  /// **'“{name}” is no longer excluded · rescanning'**
  String settingsLibraryExclusionRemoved(String name);

  /// No description provided for @settingsLibraryArtistSplit.
  ///
  /// In en, this message translates to:
  /// **'Split artists'**
  String get settingsLibraryArtistSplit;

  /// No description provided for @settingsLibrarySeparatorCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 separator} other{{count} separators}}'**
  String settingsLibrarySeparatorCount(int count);

  /// No description provided for @settingsArtistSplitIntro.
  ///
  /// In en, this message translates to:
  /// **'One song, several artists: Kanaru splits the names at these marks.'**
  String get settingsArtistSplitIntro;

  /// No description provided for @settingsArtistSplitExample.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get settingsArtistSplitExample;

  /// No description provided for @settingsArtistSplitExampleNote.
  ///
  /// In en, this message translates to:
  /// **'The default list has no , or & because many band names contain them. To split on them, add them here, then add those band names to Keep whole.'**
  String get settingsArtistSplitExampleNote;

  /// No description provided for @settingsArtistSplitSeparators.
  ///
  /// In en, this message translates to:
  /// **'Separators'**
  String get settingsArtistSplitSeparators;

  /// No description provided for @settingsArtistSplitSeparatorsHint.
  ///
  /// In en, this message translates to:
  /// **'A space shows as ␣. Changes apply now; the library updates in the background.'**
  String get settingsArtistSplitSeparatorsHint;

  /// No description provided for @settingsArtistSplitKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep whole'**
  String get settingsArtistSplitKeep;

  /// No description provided for @settingsArtistSplitKeepHint.
  ///
  /// In en, this message translates to:
  /// **'Names that stay one artist even when they contain a separator.'**
  String get settingsArtistSplitKeepHint;

  /// No description provided for @settingsArtistSplitSeparatorInput.
  ///
  /// In en, this message translates to:
  /// **'Add a separator, e.g. “ x ”'**
  String get settingsArtistSplitSeparatorInput;

  /// No description provided for @settingsArtistSplitKeepInput.
  ///
  /// In en, this message translates to:
  /// **'Artist name, e.g. “Hồ Ngọc Hà / Noo”'**
  String get settingsArtistSplitKeepInput;

  /// No description provided for @settingsArtistSplitAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get settingsArtistSplitAdd;

  /// No description provided for @settingsArtistSplitRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {value}'**
  String settingsArtistSplitRemove(String value);

  /// No description provided for @settingsArtistSplitNoSeparators.
  ///
  /// In en, this message translates to:
  /// **'No separators: artist names stay as they are.'**
  String get settingsArtistSplitNoSeparators;

  /// No description provided for @settingsArtistSplitErrEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing typed'**
  String get settingsArtistSplitErrEmpty;

  /// No description provided for @settingsArtistSplitErrDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Already in the list'**
  String get settingsArtistSplitErrDuplicate;

  /// No description provided for @settingsArtistSplitErrTooLong.
  ///
  /// In en, this message translates to:
  /// **'At most {max} characters'**
  String settingsArtistSplitErrTooLong(int max);

  /// No description provided for @settingsArtistSplitErrFull.
  ///
  /// In en, this message translates to:
  /// **'At most {max} entries'**
  String settingsArtistSplitErrFull(int max);

  /// No description provided for @settingsArtistSplitReset.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults'**
  String get settingsArtistSplitReset;

  /// No description provided for @settingsArtistSplitResetIsDefault.
  ///
  /// In en, this message translates to:
  /// **'Already the default'**
  String get settingsArtistSplitResetIsDefault;

  /// No description provided for @settingsArtistSplitResetTo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 separator} other{{count} separators}}, “{names}”'**
  String settingsArtistSplitResetTo(int count, String names);

  /// No description provided for @settingsArtistSplitResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore the default separators?'**
  String get settingsArtistSplitResetTitle;

  /// No description provided for @settingsArtistSplitResetBody.
  ///
  /// In en, this message translates to:
  /// **'The separators and the kept names go back to how they were at install. The library updates in the background.'**
  String get settingsArtistSplitResetBody;

  /// No description provided for @settingsArtistSplitResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get settingsArtistSplitResetConfirm;

  /// No description provided for @settingsArtistSplitAdded.
  ///
  /// In en, this message translates to:
  /// **'Added “{value}”'**
  String settingsArtistSplitAdded(String value);

  /// No description provided for @settingsArtistSplitAddedGroup.
  ///
  /// In en, this message translates to:
  /// **'Added “{value}” · add band names that contain it to Keep whole'**
  String settingsArtistSplitAddedGroup(String value);

  /// No description provided for @settingsArtistSplitRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed “{value}”'**
  String settingsArtistSplitRemoved(String value);

  /// No description provided for @settingsArtistSplitRestored.
  ///
  /// In en, this message translates to:
  /// **'Defaults restored'**
  String get settingsArtistSplitRestored;

  /// No description provided for @settingsLibraryLanguageSource.
  ///
  /// In en, this message translates to:
  /// **'Language source'**
  String get settingsLibraryLanguageSource;

  /// No description provided for @settingsLibraryLanguageSourceCaption.
  ///
  /// In en, this message translates to:
  /// **'How Kanaru decides which language a song is in (Language tab).'**
  String get settingsLibraryLanguageSourceCaption;

  /// No description provided for @settingsLibraryLanguageBoth.
  ///
  /// In en, this message translates to:
  /// **'Tag, then detection'**
  String get settingsLibraryLanguageBoth;

  /// No description provided for @settingsLibraryLanguageBothDesc.
  ///
  /// In en, this message translates to:
  /// **'Use the file\'s language tag, else guess from the title and lyrics'**
  String get settingsLibraryLanguageBothDesc;

  /// No description provided for @settingsLibraryLanguageTag.
  ///
  /// In en, this message translates to:
  /// **'Tag only'**
  String get settingsLibraryLanguageTag;

  /// No description provided for @settingsLibraryLanguageTagDesc.
  ///
  /// In en, this message translates to:
  /// **'Songs with no tag go to “Unknown”'**
  String get settingsLibraryLanguageTagDesc;

  /// No description provided for @settingsLibraryLanguageDetected.
  ///
  /// In en, this message translates to:
  /// **'Detection only'**
  String get settingsLibraryLanguageDetected;

  /// No description provided for @settingsLibraryLanguageDetectedDesc.
  ///
  /// In en, this message translates to:
  /// **'Ignore the file\'s language tag'**
  String get settingsLibraryLanguageDetectedDesc;

  /// No description provided for @sleepTimerHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an item to start right away.'**
  String get sleepTimerHint;

  /// No description provided for @sleepTimerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get sleepTimerCancel;

  /// No description provided for @sleepTimerSectionDuration.
  ///
  /// In en, this message translates to:
  /// **'After a while'**
  String get sleepTimerSectionDuration;

  /// No description provided for @sleepTimerSectionTracks.
  ///
  /// In en, this message translates to:
  /// **'By track'**
  String get sleepTimerSectionTracks;

  /// No description provided for @sleepTimerTileUntil.
  ///
  /// In en, this message translates to:
  /// **'until {time}'**
  String sleepTimerTileUntil(String time);

  /// No description provided for @sleepTimerTileStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start {duration}, stops at {time}'**
  String sleepTimerTileStartLabel(String duration, String time);

  /// No description provided for @sleepTimerCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get sleepTimerCustom;

  /// No description provided for @sleepTimerCustomRange.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} minutes'**
  String sleepTimerCustomRange(int min, int max);

  /// No description provided for @sleepTimerEndOfTrack.
  ///
  /// In en, this message translates to:
  /// **'End of this track'**
  String get sleepTimerEndOfTrack;

  /// No description provided for @sleepTimerEndOfAlbum.
  ///
  /// In en, this message translates to:
  /// **'End of this album'**
  String get sleepTimerEndOfAlbum;

  /// No description provided for @sleepTimerEndOfQueue.
  ///
  /// In en, this message translates to:
  /// **'End of the queue'**
  String get sleepTimerEndOfQueue;

  /// No description provided for @sleepTimerAfterTracks.
  ///
  /// In en, this message translates to:
  /// **'After a number of tracks…'**
  String get sleepTimerAfterTracks;

  /// No description provided for @sleepTimerAfterTracksRange.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} tracks, this one included'**
  String sleepTimerAfterTracksRange(int min, int max);

  /// No description provided for @sleepTimerNoAlbum.
  ///
  /// In en, this message translates to:
  /// **'This track has no album'**
  String get sleepTimerNoAlbum;

  /// No description provided for @sleepTimerLeftTime.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String sleepTimerLeftTime(String time);

  /// No description provided for @sleepTimerLeftTracks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 track left} other{{count} tracks left}}'**
  String sleepTimerLeftTracks(int count);

  /// No description provided for @sleepTimerRepeatOneStops.
  ///
  /// In en, this message translates to:
  /// **'Repeating one track · stops after this one'**
  String get sleepTimerRepeatOneStops;

  /// No description provided for @sleepTimerLeftTracksCapped.
  ///
  /// In en, this message translates to:
  /// **'{count}+ tracks left'**
  String sleepTimerLeftTracksCapped(int count);

  /// No description provided for @sleepTimerLeftTracksDuration.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 track left} other{{count} tracks left}} · {duration}'**
  String sleepTimerLeftTracksDuration(int count, String duration);

  /// No description provided for @sleepTimerRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get sleepTimerRunning;

  /// No description provided for @sleepTimerRunningWith.
  ///
  /// In en, this message translates to:
  /// **'Running · {status}'**
  String sleepTimerRunningWith(String status);

  /// No description provided for @sleepTimerCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get sleepTimerCustomTitle;

  /// No description provided for @sleepTimerKindLabel.
  ///
  /// In en, this message translates to:
  /// **'Timer type'**
  String get sleepTimerKindLabel;

  /// No description provided for @sleepTimerKindMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get sleepTimerKindMinutes;

  /// No description provided for @sleepTimerKindTracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get sleepTimerKindTracks;

  /// No description provided for @sleepTimerFieldMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get sleepTimerFieldMinutes;

  /// No description provided for @sleepTimerUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get sleepTimerUnitMinutes;

  /// No description provided for @sleepTimerUnitMinutesWords.
  ///
  /// In en, this message translates to:
  /// **'minutes · {words}'**
  String sleepTimerUnitMinutesWords(String words);

  /// No description provided for @sleepTimerUnitTracks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{track} other{tracks}}'**
  String sleepTimerUnitTracks(int count);

  /// No description provided for @sleepTimerStopsAt.
  ///
  /// In en, this message translates to:
  /// **'Stops at {time}'**
  String sleepTimerStopsAt(String time);

  /// No description provided for @sleepTimerStopsAfterTracks.
  ///
  /// In en, this message translates to:
  /// **'Pauses after {count, plural, one{1 track} other{{count} tracks}}, this one included'**
  String sleepTimerStopsAfterTracks(int count);

  /// No description provided for @sleepTimerTracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 track} other{{count} tracks}}'**
  String sleepTimerTracksCount(int count);

  /// No description provided for @sleepTimerStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get sleepTimerStart;

  /// No description provided for @sleepTimerMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} minute} other{{count} minutes}}'**
  String sleepTimerMinutes(int count);

  /// No description provided for @sleepTimerHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} hour} other{{count} hours}}'**
  String sleepTimerHours(int count);

  /// No description provided for @sleepTimerHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String sleepTimerHoursMinutes(int hours, int minutes);

  /// No description provided for @sleepTimerHoursMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes}'**
  String sleepTimerHoursMinutesShort(int hours, int minutes);

  /// No description provided for @sleepTimerChipMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String sleepTimerChipMinutes(int minutes);

  /// No description provided for @sleepTimerAddMinutes.
  ///
  /// In en, this message translates to:
  /// **'Add {minutes} minutes'**
  String sleepTimerAddMinutes(int minutes);

  /// No description provided for @sleepTimerRemoveMinutes.
  ///
  /// In en, this message translates to:
  /// **'Take off {minutes} minutes'**
  String sleepTimerRemoveMinutes(int minutes);

  /// No description provided for @sleepTimerRemoveOneMinute.
  ///
  /// In en, this message translates to:
  /// **'Take off 1 minute'**
  String get sleepTimerRemoveOneMinute;

  /// No description provided for @sleepTimerAddTrack.
  ///
  /// In en, this message translates to:
  /// **'Add one track'**
  String get sleepTimerAddTrack;

  /// No description provided for @sleepTimerRemoveTrack.
  ///
  /// In en, this message translates to:
  /// **'Remove one track'**
  String get sleepTimerRemoveTrack;

  /// No description provided for @sleepTimerChipPlusMinutes.
  ///
  /// In en, this message translates to:
  /// **'+{minutes} min'**
  String sleepTimerChipPlusMinutes(int minutes);

  /// No description provided for @sleepTimerChipPlusHour.
  ///
  /// In en, this message translates to:
  /// **'+1 h'**
  String get sleepTimerChipPlusHour;

  /// No description provided for @sleepTimerAddHour.
  ///
  /// In en, this message translates to:
  /// **'Add 1 hour'**
  String get sleepTimerAddHour;

  /// No description provided for @sleepTimerStepMinus.
  ///
  /// In en, this message translates to:
  /// **'−{amount}'**
  String sleepTimerStepMinus(int amount);

  /// No description provided for @sleepTimerStepPlus.
  ///
  /// In en, this message translates to:
  /// **'+{amount}'**
  String sleepTimerStepPlus(int amount);

  /// No description provided for @sleepTimerLabelSleepIn.
  ///
  /// In en, this message translates to:
  /// **'Sleep in'**
  String get sleepTimerLabelSleepIn;

  /// No description provided for @sleepTimerLabelHeld.
  ///
  /// In en, this message translates to:
  /// **'Counting paused'**
  String get sleepTimerLabelHeld;

  /// No description provided for @sleepTimerLabelPauseAfter.
  ///
  /// In en, this message translates to:
  /// **'Pause after'**
  String get sleepTimerLabelPauseAfter;

  /// No description provided for @sleepTimerLabelPauseAtEnd.
  ///
  /// In en, this message translates to:
  /// **'Pause at the end of'**
  String get sleepTimerLabelPauseAtEnd;

  /// No description provided for @sleepTimerWordTrack.
  ///
  /// In en, this message translates to:
  /// **'this track'**
  String get sleepTimerWordTrack;

  /// No description provided for @sleepTimerWordAlbum.
  ///
  /// In en, this message translates to:
  /// **'this album'**
  String get sleepTimerWordAlbum;

  /// No description provided for @sleepTimerWordQueue.
  ///
  /// In en, this message translates to:
  /// **'the queue'**
  String get sleepTimerWordQueue;

  /// No description provided for @sleepTimerRowHeld.
  ///
  /// In en, this message translates to:
  /// **'Counting paused'**
  String get sleepTimerRowHeld;

  /// No description provided for @sleepTimerRowCurrentCounts.
  ///
  /// In en, this message translates to:
  /// **'The current track counts as one'**
  String get sleepTimerRowCurrentCounts;

  /// No description provided for @sleepTimerRowLastTrack.
  ///
  /// In en, this message translates to:
  /// **'this is the last track'**
  String get sleepTimerRowLastTrack;

  /// No description provided for @sleepTimerRowTracksOf.
  ///
  /// In en, this message translates to:
  /// **'{left} / {total}'**
  String sleepTimerRowTracksOf(int left, int total);

  /// No description provided for @sleepTimerRowQueueKept.
  ///
  /// In en, this message translates to:
  /// **'the queue stays'**
  String get sleepTimerRowQueueKept;

  /// No description provided for @sleepTimerPauseCounting.
  ///
  /// In en, this message translates to:
  /// **'Pause counting'**
  String get sleepTimerPauseCounting;

  /// No description provided for @sleepTimerResumeCounting.
  ///
  /// In en, this message translates to:
  /// **'Resume counting'**
  String get sleepTimerResumeCounting;

  /// No description provided for @sleepTimerTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off timer'**
  String get sleepTimerTurnOff;

  /// No description provided for @sleepTimerChange.
  ///
  /// In en, this message translates to:
  /// **'Change…'**
  String get sleepTimerChange;

  /// No description provided for @sleepTimerStatusMinutes.
  ///
  /// In en, this message translates to:
  /// **'Sleep in {duration}'**
  String sleepTimerStatusMinutes(String duration);

  /// No description provided for @sleepTimerStatusHeld.
  ///
  /// In en, this message translates to:
  /// **'Counting paused · {duration} left'**
  String sleepTimerStatusHeld(String duration);

  /// No description provided for @sleepTimerStatusTracks.
  ///
  /// In en, this message translates to:
  /// **'Pause after {count, plural, one{1 track} other{{count} tracks}}'**
  String sleepTimerStatusTracks(int count);

  /// No description provided for @sleepTimerStatusEndTrack.
  ///
  /// In en, this message translates to:
  /// **'Pause at the end of this track'**
  String get sleepTimerStatusEndTrack;

  /// No description provided for @sleepTimerStatusEndAlbum.
  ///
  /// In en, this message translates to:
  /// **'Pause at the end of this album'**
  String get sleepTimerStatusEndAlbum;

  /// No description provided for @sleepTimerStatusEndQueue.
  ///
  /// In en, this message translates to:
  /// **'Pause at the end of the queue'**
  String get sleepTimerStatusEndQueue;

  /// No description provided for @sleepTimerPillTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get sleepTimerPillTrack;

  /// No description provided for @sleepTimerPillAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get sleepTimerPillAlbum;

  /// No description provided for @sleepTimerPillQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get sleepTimerPillQueue;

  /// No description provided for @sleepTimerEntryEndTrack.
  ///
  /// In en, this message translates to:
  /// **'end of this track'**
  String get sleepTimerEntryEndTrack;

  /// No description provided for @sleepTimerEntryEndAlbum.
  ///
  /// In en, this message translates to:
  /// **'end of this album'**
  String get sleepTimerEntryEndAlbum;

  /// No description provided for @sleepTimerEntryEndQueue.
  ///
  /// In en, this message translates to:
  /// **'end of the queue'**
  String get sleepTimerEntryEndQueue;

  /// No description provided for @sleepTimerEntryRunning.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer: {status}'**
  String sleepTimerEntryRunning(String status);

  /// No description provided for @sleepTimerMenuRunning.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer · {status}'**
  String sleepTimerMenuRunning(String status);

  /// No description provided for @sleepTimerHeldSuffix.
  ///
  /// In en, this message translates to:
  /// **'(counting paused)'**
  String get sleepTimerHeldSuffix;

  /// No description provided for @sleepTimerAnnounceStartMinutes.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer set for {duration}, stops at {time}'**
  String sleepTimerAnnounceStartMinutes(String duration, String time);

  /// No description provided for @sleepTimerAnnounceStartTracks.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer set, pausing after {count, plural, one{1 track} other{{count} tracks}}'**
  String sleepTimerAnnounceStartTracks(int count);

  /// No description provided for @sleepTimerAnnounceStartEndTrack.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer set, pausing at the end of this track'**
  String get sleepTimerAnnounceStartEndTrack;

  /// No description provided for @sleepTimerAnnounceStartEndAlbum.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer set, pausing at the end of this album'**
  String get sleepTimerAnnounceStartEndAlbum;

  /// No description provided for @sleepTimerAnnounceStartEndQueue.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer set, pausing at the end of the queue'**
  String get sleepTimerAnnounceStartEndQueue;

  /// No description provided for @sleepTimerAnnounceHeld.
  ///
  /// In en, this message translates to:
  /// **'Counting paused'**
  String get sleepTimerAnnounceHeld;

  /// No description provided for @sleepTimerAnnounceResumed.
  ///
  /// In en, this message translates to:
  /// **'Counting resumed'**
  String get sleepTimerAnnounceResumed;

  /// No description provided for @sleepTimerAnnounceCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer turned off'**
  String get sleepTimerAnnounceCancelled;

  /// No description provided for @sleepTimerAnnounceExpired.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer ended, playback paused'**
  String get sleepTimerAnnounceExpired;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyHeroPlays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 play} other{{count} plays}}'**
  String historyHeroPlays(int count);

  /// No description provided for @historyHeroSongsSince.
  ///
  /// In en, this message translates to:
  /// **'{songs, plural, =1{1 song} other{{songs} songs}} · since {date}'**
  String historyHeroSongsSince(int songs, String date);

  /// No description provided for @historyBarCount.
  ///
  /// In en, this message translates to:
  /// **'{year} · {count, plural, =1{1 play} other{{count} plays}}'**
  String historyBarCount(String year, int count);

  /// No description provided for @historyJumpToDay.
  ///
  /// In en, this message translates to:
  /// **'Jump to date'**
  String get historyJumpToDay;

  /// No description provided for @historyYearsLabel.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get historyYearsLabel;

  /// No description provided for @historyDayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get historyDayToday;

  /// No description provided for @historyDayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get historyDayYesterday;

  /// No description provided for @historyDayPlays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 play} other{{count} plays}}'**
  String historyDayPlays(int count);

  /// No description provided for @historyDayMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'More options for {day}'**
  String historyDayMenuLabel(String day);

  /// No description provided for @historyRowOrdinal.
  ///
  /// In en, this message translates to:
  /// **'{time} · play #{n}'**
  String historyRowOrdinal(String time, int n);

  /// No description provided for @historyRowMissing.
  ///
  /// In en, this message translates to:
  /// **'{time} · can\'t play'**
  String historyRowMissing(String time);

  /// No description provided for @historyMissingTap.
  ///
  /// In en, this message translates to:
  /// **'Can\'t play this song'**
  String get historyMissingTap;

  /// No description provided for @historyRemoved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Removed 1 play} other{Removed {count} plays}}'**
  String historyRemoved(int count);

  /// No description provided for @historyRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the play'**
  String get historyRemoveFailed;

  /// No description provided for @historyWriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the change'**
  String get historyWriteFailed;

  /// No description provided for @historyEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'The songs you play will show up here.'**
  String get historyEmptyMessage;

  /// No description provided for @historyRecordingOff.
  ///
  /// In en, this message translates to:
  /// **'Listening history is off. What was recorded stays.'**
  String get historyRecordingOff;

  /// No description provided for @historyRecordingOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get historyRecordingOn;

  /// No description provided for @historyRecordingOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Turn on recording listening history'**
  String get historyRecordingOnLabel;

  /// No description provided for @historyRecordingEnabled.
  ///
  /// In en, this message translates to:
  /// **'Listening history is on'**
  String get historyRecordingEnabled;

  /// No description provided for @historyYearFooter.
  ///
  /// In en, this message translates to:
  /// **'See {year}'**
  String historyYearFooter(String year);

  /// No description provided for @historyPlayFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not play the history'**
  String get historyPlayFailed;

  /// No description provided for @historyMenuMostPlayed.
  ///
  /// In en, this message translates to:
  /// **'Most played'**
  String get historyMenuMostPlayed;

  /// No description provided for @historyMenuClear.
  ///
  /// In en, this message translates to:
  /// **'Clear history…'**
  String get historyMenuClear;

  /// No description provided for @historyMenuPlayDay.
  ///
  /// In en, this message translates to:
  /// **'Play the day'**
  String get historyMenuPlayDay;

  /// No description provided for @historyMenuDeleteDay.
  ///
  /// In en, this message translates to:
  /// **'Remove the day from history'**
  String get historyMenuDeleteDay;

  /// No description provided for @historyMenuTrackHistory.
  ///
  /// In en, this message translates to:
  /// **'History of this song'**
  String get historyMenuTrackHistory;

  /// No description provided for @historyMenuRemovePlay.
  ///
  /// In en, this message translates to:
  /// **'Remove from history'**
  String get historyMenuRemovePlay;

  /// No description provided for @historyNothingToAdd.
  ///
  /// In en, this message translates to:
  /// **'No playable songs to add'**
  String get historyNothingToAdd;

  /// No description provided for @historyMenuExportM3u.
  ///
  /// In en, this message translates to:
  /// **'Export M3U…'**
  String get historyMenuExportM3u;

  /// No description provided for @historyNothingToExport.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export'**
  String get historyNothingToExport;

  /// No description provided for @historyClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear history?'**
  String get historyClearTitle;

  /// No description provided for @historyClearHour.
  ///
  /// In en, this message translates to:
  /// **'Last hour'**
  String get historyClearHour;

  /// No description provided for @historyClearToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get historyClearToday;

  /// No description provided for @historyClearWeek.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get historyClearWeek;

  /// No description provided for @historyClearAll.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get historyClearAll;

  /// No description provided for @historyClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get historyClearConfirm;

  /// No description provided for @historyClearCountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not count the plays'**
  String get historyClearCountFailed;

  /// No description provided for @historyClearRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get historyClearRetry;

  /// No description provided for @historyClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not clear the history'**
  String get historyClearFailed;

  /// No description provided for @historyCleared.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Removed 1 play} other{Removed {count} plays}}'**
  String historyCleared(int count);

  /// No description provided for @historyDeleteDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this day from history?'**
  String get historyDeleteDayTitle;

  /// No description provided for @historyDeleteDayBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 play} other{{count} plays}} on {date} will be removed. This cannot be undone.'**
  String historyDeleteDayBody(int count, String date);

  /// No description provided for @historyFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter in {year}'**
  String historyFilterHint(String year);

  /// No description provided for @historyFilterMatches.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 play matches} other{{count} plays match}} · not split by day'**
  String historyFilterMatches(int count);

  /// No description provided for @historyFilterCapped.
  ///
  /// In en, this message translates to:
  /// **'Showing the first {max} plays. Narrow the filter to see more.'**
  String historyFilterCapped(int max);

  /// No description provided for @historyFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plays match “{query}”.'**
  String historyFilterEmpty(String query);

  /// No description provided for @historyMenuMissing.
  ///
  /// In en, this message translates to:
  /// **'Can\'t play'**
  String get historyMenuMissing;

  /// No description provided for @historyTrackEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plays yet'**
  String get historyTrackEmpty;

  /// No description provided for @historyTrackColDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get historyTrackColDay;

  /// No description provided for @historyTrackColTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get historyTrackColTime;

  /// No description provided for @historyTrackColListened.
  ///
  /// In en, this message translates to:
  /// **'Listened'**
  String get historyTrackColListened;

  /// No description provided for @historyTrackListHeader.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} play, newest first} other{{count} plays, newest first}}'**
  String historyTrackListHeader(int count);

  /// No description provided for @historyTrackRemovePlayLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove the play at {time}, {date}'**
  String historyTrackRemovePlayLabel(String time, String date);

  /// No description provided for @historyTrackSummaryLast.
  ///
  /// In en, this message translates to:
  /// **'Last played: {when}'**
  String historyTrackSummaryLast(String when);

  /// No description provided for @historyTrackSummaryFirst.
  ///
  /// In en, this message translates to:
  /// **'First played: {date}'**
  String historyTrackSummaryFirst(String date);

  /// No description provided for @historyTrackSummaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Listened in total: {duration}'**
  String historyTrackSummaryTotal(String duration);

  /// No description provided for @historyTrackListened.
  ///
  /// In en, this message translates to:
  /// **'listened {duration}'**
  String historyTrackListened(String duration);

  /// No description provided for @historyTrackWhen.
  ///
  /// In en, this message translates to:
  /// **'{day} {time}'**
  String historyTrackWhen(String day, String time);

  /// Caption above the header block of the custom range dialog
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get historyRangeDialogCaption;

  /// Hint in the custom range dialog before the first day is picked
  ///
  /// In en, this message translates to:
  /// **'Pick the start date'**
  String get historyRangePickStart;

  /// Hint in the custom range dialog after the first day is picked
  ///
  /// In en, this message translates to:
  /// **'Pick the end date'**
  String get historyRangePickEnd;

  /// Days picked, shown as the second line of the custom range dialog header
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String historyRangeDays(int count);

  /// Screen reader cue on a day of the custom range calendar that holds plays
  ///
  /// In en, this message translates to:
  /// **'Has listens'**
  String get historyRangeDayHasListens;

  /// Shown in the custom range dialog header until the first day is picked
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get historyRangeStartPlaceholder;

  /// Shown in the custom range dialog header until the last day is picked
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get historyRangeEndPlaceholder;

  /// Save button of the custom range dialog
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get historyRangeSave;

  /// No description provided for @historyMostPlayedRange1Day.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get historyMostPlayedRange1Day;

  /// No description provided for @historyMostPlayedRange7Days.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get historyMostPlayedRange7Days;

  /// No description provided for @historyMostPlayedRange30Days.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get historyMostPlayedRange30Days;

  /// No description provided for @historyMostPlayedRange6Months.
  ///
  /// In en, this message translates to:
  /// **'6 months'**
  String get historyMostPlayedRange6Months;

  /// No description provided for @historyMostPlayedRange1Year.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get historyMostPlayedRange1Year;

  /// No description provided for @historyMostPlayedRangeAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get historyMostPlayedRangeAll;

  /// No description provided for @historyMostPlayedRangeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get historyMostPlayedRangeCustom;

  /// No description provided for @historyMostPlayedRangesLabel.
  ///
  /// In en, this message translates to:
  /// **'Time range'**
  String get historyMostPlayedRangesLabel;

  /// No description provided for @historyMostPlayedPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get historyMostPlayedPrevious;

  /// No description provided for @historyMostPlayedNext.
  ///
  /// In en, this message translates to:
  /// **'Next period'**
  String get historyMostPlayedNext;

  /// No description provided for @historyMostPlayedTop.
  ///
  /// In en, this message translates to:
  /// **'Top {count}'**
  String historyMostPlayedTop(int count);

  /// No description provided for @historyMostPlayedTopLabel.
  ///
  /// In en, this message translates to:
  /// **'Songs shown'**
  String get historyMostPlayedTopLabel;

  /// No description provided for @historyMostPlayedLimitCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get historyMostPlayedLimitCustom;

  /// No description provided for @historyMostPlayedLimitHint.
  ///
  /// In en, this message translates to:
  /// **'From 1 to 1000 songs'**
  String get historyMostPlayedLimitHint;

  /// No description provided for @historyMostPlayedLimitCustomValue.
  ///
  /// In en, this message translates to:
  /// **'Top {count} · from 1 to 1000 songs'**
  String historyMostPlayedLimitCustomValue(int count);

  /// No description provided for @historyMostPlayedLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Ranked songs'**
  String get historyMostPlayedLimitTitle;

  /// No description provided for @historyMostPlayedLimitField.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get historyMostPlayedLimitField;

  /// No description provided for @historyMostPlayedLimitError.
  ///
  /// In en, this message translates to:
  /// **'Only numbers from 1 to 1000'**
  String get historyMostPlayedLimitError;

  /// No description provided for @historyMostPlayedHeroTotals.
  ///
  /// In en, this message translates to:
  /// **'{songs, plural, =1{1 song} other{{songs} songs}} · {plays, plural, =1{1 play} other{{plays} plays}}'**
  String historyMostPlayedHeroTotals(int songs, int plays);

  /// No description provided for @historyMostPlayedPlays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 play} other{{count} plays}}'**
  String historyMostPlayedPlays(int count);

  /// No description provided for @historyMostPlayedRowMissing.
  ///
  /// In en, this message translates to:
  /// **'{plays} · can\'t play'**
  String historyMostPlayedRowMissing(String plays);

  /// No description provided for @historyMostPlayedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plays in this range.'**
  String get historyMostPlayedEmpty;

  /// No description provided for @historyMostPlayedPlayFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t play the list'**
  String get historyMostPlayedPlayFailed;

  /// No description provided for @historyMostPlayedMenuPlay.
  ///
  /// In en, this message translates to:
  /// **'Play (by rank)'**
  String get historyMostPlayedMenuPlay;

  /// No description provided for @historyMostPlayedPlaylistName.
  ///
  /// In en, this message translates to:
  /// **'Most played · {range}'**
  String historyMostPlayedPlaylistName(String range);

  /// No description provided for @historyMostPlayedOpenDay.
  ///
  /// In en, this message translates to:
  /// **'Open in Most played'**
  String get historyMostPlayedOpenDay;

  /// No description provided for @historyMostPlayedFavoriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add to Favorites'**
  String get historyMostPlayedFavoriteFailed;

  /// No description provided for @savedQueueExplain.
  ///
  /// In en, this message translates to:
  /// **'When you play something else, the queue it replaces is kept here (up to 20, the oldest is dropped).'**
  String get savedQueueExplain;

  /// No description provided for @savedQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved queues yet. When you play something else, the queue it replaces is kept here.'**
  String get savedQueueEmpty;

  /// No description provided for @savedQueueName.
  ///
  /// In en, this message translates to:
  /// **'{day} · {time}'**
  String savedQueueName(String day, String time);

  /// No description provided for @savedQueueExportName.
  ///
  /// In en, this message translates to:
  /// **'Queue {date}'**
  String savedQueueExportName(String date);

  /// No description provided for @savedQueueMissing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song gone} other{{count} songs gone}}'**
  String savedQueueMissing(int count);

  /// No description provided for @savedQueueFromAlbum.
  ///
  /// In en, this message translates to:
  /// **'From album {name}'**
  String savedQueueFromAlbum(String name);

  /// No description provided for @savedQueueFromArtist.
  ///
  /// In en, this message translates to:
  /// **'From artist {name}'**
  String savedQueueFromArtist(String name);

  /// No description provided for @savedQueueFromGenre.
  ///
  /// In en, this message translates to:
  /// **'From genre {name}'**
  String savedQueueFromGenre(String name);

  /// No description provided for @savedQueueFromLanguage.
  ///
  /// In en, this message translates to:
  /// **'From language {name}'**
  String savedQueueFromLanguage(String name);

  /// No description provided for @savedQueueFromFolder.
  ///
  /// In en, this message translates to:
  /// **'From folder {name}'**
  String savedQueueFromFolder(String name);

  /// No description provided for @savedQueueFromPlaylist.
  ///
  /// In en, this message translates to:
  /// **'From playlist {name}'**
  String savedQueueFromPlaylist(String name);

  /// No description provided for @savedQueueFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'From Favorites'**
  String get savedQueueFromFavorites;

  /// No description provided for @savedQueueFromSongs.
  ///
  /// In en, this message translates to:
  /// **'From Songs'**
  String get savedQueueFromSongs;

  /// No description provided for @savedQueueFromSelection.
  ///
  /// In en, this message translates to:
  /// **'From the selected songs'**
  String get savedQueueFromSelection;

  /// No description provided for @savedQueueFromList.
  ///
  /// In en, this message translates to:
  /// **'From {name}'**
  String savedQueueFromList(String name);

  /// No description provided for @savedQueueNoSongs.
  ///
  /// In en, this message translates to:
  /// **'This queue has no songs left.'**
  String get savedQueueNoSongs;

  /// No description provided for @savedQueuePlayRow.
  ///
  /// In en, this message translates to:
  /// **'Play this queue'**
  String get savedQueuePlayRow;

  /// No description provided for @savedQueueBar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song, in played order} other{{count} songs, in played order}}'**
  String savedQueueBar(int count);

  /// No description provided for @savedQueuePlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing queue {name} ({count, plural, =1{1 song} other{{count} songs}}). The previous queue was saved.'**
  String savedQueuePlaying(String name, int count);

  /// No description provided for @savedQueueNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue not found'**
  String get savedQueueNotFoundTitle;

  /// No description provided for @savedQueueNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This queue was deleted, or dropped when there were more than 20.'**
  String get savedQueueNotFoundMessage;

  /// No description provided for @savedQueueMenuPlay.
  ///
  /// In en, this message translates to:
  /// **'Play (replace the current queue)'**
  String get savedQueueMenuPlay;

  /// No description provided for @savedQueueMenuAppend.
  ///
  /// In en, this message translates to:
  /// **'Add to the end of the queue'**
  String get savedQueueMenuAppend;

  /// No description provided for @savedQueueMenuSaveAsPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Save as playlist…'**
  String get savedQueueMenuSaveAsPlaylist;

  /// No description provided for @savedQueueMenuRemoveMissing.
  ///
  /// In en, this message translates to:
  /// **'Remove songs that are gone'**
  String get savedQueueMenuRemoveMissing;

  /// No description provided for @savedQueueMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this queue'**
  String get savedQueueMenuDelete;

  /// No description provided for @savedQueueDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this queue?'**
  String get savedQueueDeleteTitle;

  /// No description provided for @savedQueueDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The songs stay in your library.'**
  String get savedQueueDeleteBody;

  /// No description provided for @savedQueueDeleted.
  ///
  /// In en, this message translates to:
  /// **'Queue deleted'**
  String get savedQueueDeleted;

  /// No description provided for @savedQueueDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the queue'**
  String get savedQueueDeleteFailed;

  /// No description provided for @savedQueueRemovedMissing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Removed 1 song} other{Removed {count} songs}}'**
  String savedQueueRemovedMissing(int count);

  /// No description provided for @savedQueueRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove the missing songs'**
  String get savedQueueRemoveFailed;

  /// No description provided for @lyricsLabelTagSynced.
  ///
  /// In en, this message translates to:
  /// **'Lyrics in tag · Synced'**
  String get lyricsLabelTagSynced;

  /// No description provided for @lyricsLabelTagPlain.
  ///
  /// In en, this message translates to:
  /// **'Lyrics in tag · Plain'**
  String get lyricsLabelTagPlain;

  /// No description provided for @lyricsLabelLrcSynced.
  ///
  /// In en, this message translates to:
  /// **'LRC file · Synced'**
  String get lyricsLabelLrcSynced;

  /// No description provided for @lyricsLabelLrcPlain.
  ///
  /// In en, this message translates to:
  /// **'LRC file · Plain'**
  String get lyricsLabelLrcPlain;

  /// No description provided for @lyricsLabelOff.
  ///
  /// In en, this message translates to:
  /// **'Lyrics off'**
  String get lyricsLabelOff;

  /// No description provided for @lyricsLabelNone.
  ///
  /// In en, this message translates to:
  /// **'No lyrics'**
  String get lyricsLabelNone;

  /// No description provided for @lyricsLabelShortTag.
  ///
  /// In en, this message translates to:
  /// **'In tag'**
  String get lyricsLabelShortTag;

  /// No description provided for @lyricsLabelShortLrc.
  ///
  /// In en, this message translates to:
  /// **'LRC file'**
  String get lyricsLabelShortLrc;

  /// No description provided for @lyricsLabelShortOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get lyricsLabelShortOff;

  /// No description provided for @lyricsPlainNote.
  ///
  /// In en, this message translates to:
  /// **'Plain lyrics, no time marks: they do not scroll by themselves.'**
  String get lyricsPlainNote;

  /// No description provided for @lyricsNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'No lyrics'**
  String get lyricsNoneTitle;

  /// No description provided for @lyricsNoneMessage.
  ///
  /// In en, this message translates to:
  /// **'No lyrics in the file or in an .lrc file next to the song.'**
  String get lyricsNoneMessage;

  /// No description provided for @lyricsOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Lyrics are off for this song'**
  String get lyricsOffTitle;

  /// No description provided for @lyricsOffMessageDesktop.
  ///
  /// In en, this message translates to:
  /// **'Right-click the lyrics button to turn them back on.'**
  String get lyricsOffMessageDesktop;

  /// No description provided for @lyricsOffMessageMobile.
  ///
  /// In en, this message translates to:
  /// **'You chose “Don’t show lyrics” in Lyrics for this song.'**
  String get lyricsOffMessageMobile;

  /// No description provided for @lyricsOffOpenChoice.
  ///
  /// In en, this message translates to:
  /// **'Lyrics for this song'**
  String get lyricsOffOpenChoice;

  /// No description provided for @lyricsBackToLine.
  ///
  /// In en, this message translates to:
  /// **'Back to current line'**
  String get lyricsBackToLine;

  /// No description provided for @lyricsSeekHint.
  ///
  /// In en, this message translates to:
  /// **'Seek to {time}'**
  String lyricsSeekHint(String time);

  /// No description provided for @lyricsGapLabel.
  ///
  /// In en, this message translates to:
  /// **'Instrumental break'**
  String get lyricsGapLabel;

  /// No description provided for @lyricsCardNone.
  ///
  /// In en, this message translates to:
  /// **'No lyrics for this song'**
  String get lyricsCardNone;

  /// No description provided for @lyricsCardOff.
  ///
  /// In en, this message translates to:
  /// **'Lyrics are off for this song'**
  String get lyricsCardOff;

  /// No description provided for @lyricsCardOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Open the lyrics screen'**
  String get lyricsCardOpenHint;

  /// No description provided for @lyricsCardLabel.
  ///
  /// In en, this message translates to:
  /// **'{title} · {source}'**
  String lyricsCardLabel(String title, String source);

  /// No description provided for @lyricsForTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Lyrics for this song'**
  String get lyricsForTrackTitle;

  /// No description provided for @lyricsModalClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get lyricsModalClose;

  /// No description provided for @lyricsModalNoneOnDevice.
  ///
  /// In en, this message translates to:
  /// **'No lyrics on this device'**
  String get lyricsModalNoneOnDevice;

  /// No description provided for @lyricsChoiceFile.
  ///
  /// In en, this message translates to:
  /// **'Lyrics in file'**
  String get lyricsChoiceFile;

  /// No description provided for @lyricsChoiceFileNone.
  ///
  /// In en, this message translates to:
  /// **'No lyrics in the file'**
  String get lyricsChoiceFileNone;

  /// No description provided for @lyricsChoiceOff.
  ///
  /// In en, this message translates to:
  /// **'Don’t show lyrics'**
  String get lyricsChoiceOff;

  /// No description provided for @lyricsChoiceSubTagSynced.
  ///
  /// In en, this message translates to:
  /// **'In tag · Synced'**
  String get lyricsChoiceSubTagSynced;

  /// No description provided for @lyricsChoiceSubTagPlain.
  ///
  /// In en, this message translates to:
  /// **'In tag · Plain'**
  String get lyricsChoiceSubTagPlain;

  /// No description provided for @lyricsChoiceSubLrcSynced.
  ///
  /// In en, this message translates to:
  /// **'LRC file · Synced'**
  String get lyricsChoiceSubLrcSynced;

  /// No description provided for @lyricsChoiceSubLrcPlain.
  ///
  /// In en, this message translates to:
  /// **'LRC file · Plain'**
  String get lyricsChoiceSubLrcPlain;

  /// No description provided for @lyricsFindOnline.
  ///
  /// In en, this message translates to:
  /// **'Find lyrics online…'**
  String get lyricsFindOnline;

  /// No description provided for @lyricsFromAudio.
  ///
  /// In en, this message translates to:
  /// **'Create lyrics from audio…'**
  String get lyricsFromAudio;

  /// No description provided for @lyricsFromAudioSub.
  ///
  /// In en, this message translates to:
  /// **'Groq Whisper'**
  String get lyricsFromAudioSub;

  /// No description provided for @lyricsSaveLyrics.
  ///
  /// In en, this message translates to:
  /// **'Save lyrics…'**
  String get lyricsSaveLyrics;

  /// No description provided for @lyricsSourceTooltipDesktop.
  ///
  /// In en, this message translates to:
  /// **'{label} (L)'**
  String lyricsSourceTooltipDesktop(String label);

  /// No description provided for @lyricsSourceToggleHint.
  ///
  /// In en, this message translates to:
  /// **'Right-click: turn this song’s lyrics on or off'**
  String get lyricsSourceToggleHint;

  /// No description provided for @lyricsSettingsModalSettings.
  ///
  /// In en, this message translates to:
  /// **'Lyrics settings'**
  String get lyricsSettingsModalSettings;

  /// No description provided for @lyricsSettingsDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get lyricsSettingsDefault;

  /// No description provided for @lyricsSettingsDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get lyricsSettingsDisplay;

  /// No description provided for @lyricsSettingsFind.
  ///
  /// In en, this message translates to:
  /// **'Find and save'**
  String get lyricsSettingsFind;

  /// No description provided for @lyricsSettingsSources.
  ///
  /// In en, this message translates to:
  /// **'Online sources'**
  String get lyricsSettingsSources;

  /// No description provided for @lyricsSettingsWhere.
  ///
  /// In en, this message translates to:
  /// **'Where lyrics show'**
  String get lyricsSettingsWhere;

  /// No description provided for @lyricsSettingsTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get lyricsSettingsTranslation;

  /// No description provided for @lyricsSettingsSpeech.
  ///
  /// In en, this message translates to:
  /// **'Create lyrics from audio'**
  String get lyricsSettingsSpeech;

  /// No description provided for @lyricsSettingsSpeechHint.
  ///
  /// In en, this message translates to:
  /// **'Speech-to-text plugins, used by “Create lyrics from audio…” in Lyrics for this song.'**
  String get lyricsSettingsSpeechHint;

  /// No description provided for @lyricsSettingsFontSize.
  ///
  /// In en, this message translates to:
  /// **'Lyrics text size'**
  String get lyricsSettingsFontSize;

  /// No description provided for @lyricsSettingsFontSizeCaption.
  ///
  /// In en, this message translates to:
  /// **'Applies to the lyrics screen, the Lyrics tab and the lyrics card.'**
  String get lyricsSettingsFontSizeCaption;

  /// No description provided for @lyricsSettingsSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get lyricsSettingsSizeSmall;

  /// No description provided for @lyricsSettingsSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get lyricsSettingsSizeMedium;

  /// No description provided for @lyricsSettingsSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get lyricsSettingsSizeLarge;

  /// No description provided for @lyricsSettingsAlign.
  ///
  /// In en, this message translates to:
  /// **'Lyrics alignment'**
  String get lyricsSettingsAlign;

  /// No description provided for @lyricsSettingsAlignStart.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get lyricsSettingsAlignStart;

  /// No description provided for @lyricsSettingsAlignCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get lyricsSettingsAlignCenter;

  /// No description provided for @lyricsSettingsAutoReturn.
  ///
  /// In en, this message translates to:
  /// **'Return to the current line'**
  String get lyricsSettingsAutoReturn;

  /// No description provided for @lyricsSettingsAutoReturnCaption.
  ///
  /// In en, this message translates to:
  /// **'After you scroll the lyrics by hand. Off keeps the lyrics still until you tap “Back to current line”.'**
  String get lyricsSettingsAutoReturnCaption;

  /// No description provided for @lyricsSettingsAutoReturnOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get lyricsSettingsAutoReturnOff;

  /// No description provided for @lyricsSettingsAutoReturn3.
  ///
  /// In en, this message translates to:
  /// **'3 seconds'**
  String get lyricsSettingsAutoReturn3;

  /// No description provided for @lyricsSettingsAutoReturn5.
  ///
  /// In en, this message translates to:
  /// **'5 seconds'**
  String get lyricsSettingsAutoReturn5;

  /// No description provided for @lyricsSettingsAutoReturn10.
  ///
  /// In en, this message translates to:
  /// **'10 seconds'**
  String get lyricsSettingsAutoReturn10;

  /// No description provided for @lyricsSettingsDim.
  ///
  /// In en, this message translates to:
  /// **'Dim the lines not being sung'**
  String get lyricsSettingsDim;

  /// No description provided for @lyricsSettingsDimLight.
  ///
  /// In en, this message translates to:
  /// **'Slightly dimmed'**
  String get lyricsSettingsDimLight;

  /// No description provided for @lyricsSettingsDimStrong.
  ///
  /// In en, this message translates to:
  /// **'Strongly dimmed'**
  String get lyricsSettingsDimStrong;

  /// No description provided for @lyricsSettingsDimOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get lyricsSettingsDimOff;

  /// No description provided for @lyricsSettingsRomanize.
  ///
  /// In en, this message translates to:
  /// **'Transliteration'**
  String get lyricsSettingsRomanize;

  /// No description provided for @lyricsSettingsRomanizeDesc.
  ///
  /// In en, this message translates to:
  /// **'Romaji, Pinyin, Furigana under Japanese, Chinese and Korean lyrics.'**
  String get lyricsSettingsRomanizeDesc;

  /// No description provided for @lyricsSettingsKeepAwake.
  ///
  /// In en, this message translates to:
  /// **'Keep the screen on'**
  String get lyricsSettingsKeepAwake;

  /// No description provided for @lyricsSettingsKeepAwakeDesc.
  ///
  /// In en, this message translates to:
  /// **'The screen stays on while the lyrics screen is open.'**
  String get lyricsSettingsKeepAwakeDesc;

  /// No description provided for @lyricsSettingsAutoFind.
  ///
  /// In en, this message translates to:
  /// **'Find lyrics for songs without any'**
  String get lyricsSettingsAutoFind;

  /// No description provided for @lyricsSettingsAutoFindDesc.
  ///
  /// In en, this message translates to:
  /// **'Searches the enabled lyrics sources when a song has no lyrics on this device.'**
  String get lyricsSettingsAutoFindDesc;

  /// No description provided for @lyricsSettingsLocalFirst.
  ///
  /// In en, this message translates to:
  /// **'Lyrics on this device'**
  String get lyricsSettingsLocalFirst;

  /// No description provided for @lyricsSettingsLocalFirstCaption.
  ///
  /// In en, this message translates to:
  /// **'Synced lyrics always win over plain ones.'**
  String get lyricsSettingsLocalFirstCaption;

  /// No description provided for @lyricsSettingsLocalTag.
  ///
  /// In en, this message translates to:
  /// **'Lyrics in the music file first'**
  String get lyricsSettingsLocalTag;

  /// No description provided for @lyricsSettingsLocalTagSub.
  ///
  /// In en, this message translates to:
  /// **'Then the .lrc file'**
  String get lyricsSettingsLocalTagSub;

  /// No description provided for @lyricsSettingsLocalLrc.
  ///
  /// In en, this message translates to:
  /// **'.lrc file first'**
  String get lyricsSettingsLocalLrc;

  /// No description provided for @lyricsSettingsLocalLrcSub.
  ///
  /// In en, this message translates to:
  /// **'Then the lyrics in the music file'**
  String get lyricsSettingsLocalLrcSub;

  /// No description provided for @lyricsSettingsAutoSave.
  ///
  /// In en, this message translates to:
  /// **'Save found lyrics as .lrc'**
  String get lyricsSettingsAutoSave;

  /// No description provided for @lyricsSettingsAutoSaveDesc.
  ///
  /// In en, this message translates to:
  /// **'Writes an .lrc file next to the song when online lyrics are found.'**
  String get lyricsSettingsAutoSaveDesc;

  /// No description provided for @lyricsSettingsAddSource.
  ///
  /// In en, this message translates to:
  /// **'Add an online lyrics source'**
  String get lyricsSettingsAddSource;

  /// No description provided for @lyricsSettingsFloating.
  ///
  /// In en, this message translates to:
  /// **'Floating lyrics'**
  String get lyricsSettingsFloating;

  /// No description provided for @lyricsSettingsFloatingDesc.
  ///
  /// In en, this message translates to:
  /// **'A small lyrics window that stays above other windows.'**
  String get lyricsSettingsFloatingDesc;

  /// No description provided for @lyricsSettingsLockScreen.
  ///
  /// In en, this message translates to:
  /// **'Lyrics on the lock screen and notification'**
  String get lyricsSettingsLockScreen;

  /// No description provided for @lyricsSettingsLockScreenDesc.
  ///
  /// In en, this message translates to:
  /// **'The line being sung shows in the playback notification and on the lock screen.'**
  String get lyricsSettingsLockScreenDesc;

  /// No description provided for @lyricsSettingsTrService.
  ///
  /// In en, this message translates to:
  /// **'Default translation service'**
  String get lyricsSettingsTrService;

  /// No description provided for @lyricsSettingsTrServiceNone.
  ///
  /// In en, this message translates to:
  /// **'Not chosen'**
  String get lyricsSettingsTrServiceNone;

  /// No description provided for @lyricsSettingsTrTarget.
  ///
  /// In en, this message translates to:
  /// **'Default translation language'**
  String get lyricsSettingsTrTarget;

  /// No description provided for @lyricsSettingsTrAhead.
  ///
  /// In en, this message translates to:
  /// **'Translate ahead'**
  String get lyricsSettingsTrAhead;

  /// No description provided for @lyricsSettingsTrAheadNow.
  ///
  /// In en, this message translates to:
  /// **'Current song only'**
  String get lyricsSettingsTrAheadNow;

  /// No description provided for @lyricsSettingsAddTrService.
  ///
  /// In en, this message translates to:
  /// **'Add a translation service'**
  String get lyricsSettingsAddTrService;

  /// No description provided for @lyricsSettingsTrTargetAppNamed.
  ///
  /// In en, this message translates to:
  /// **'Follows the app language ({name})'**
  String lyricsSettingsTrTargetAppNamed(String name);

  /// No description provided for @lyricsSettingsTrTargetCaption.
  ///
  /// In en, this message translates to:
  /// **'Used for songs that have no language of their own.'**
  String get lyricsSettingsTrTargetCaption;

  /// No description provided for @lyricsSettingsTrSize.
  ///
  /// In en, this message translates to:
  /// **'Translation text size'**
  String get lyricsSettingsTrSize;

  /// No description provided for @lyricsSettingsTrSizeCaption.
  ///
  /// In en, this message translates to:
  /// **'The translation line under the lyrics, or the small original line when the translation replaces it. Applies to the lyrics screen, the Lyrics tab and the lyrics card.'**
  String get lyricsSettingsTrSizeCaption;

  /// No description provided for @lyricsSettingsTrServiceNeedsConfig.
  ///
  /// In en, this message translates to:
  /// **'Needs setup: {fields}'**
  String lyricsSettingsTrServiceNeedsConfig(String fields);

  /// No description provided for @lyricsSettingsAddSpeech.
  ///
  /// In en, this message translates to:
  /// **'Add a speech-to-text plugin'**
  String get lyricsSettingsAddSpeech;

  /// No description provided for @lyricsSearchingTitle.
  ///
  /// In en, this message translates to:
  /// **'Searching for lyrics…'**
  String get lyricsSearchingTitle;

  /// No description provided for @lyricsSearchingMessage.
  ///
  /// In en, this message translates to:
  /// **'No lyrics on this device yet · searching {count, plural, =1{1 enabled source} other{{count} enabled sources}}.'**
  String lyricsSearchingMessage(int count);

  /// No description provided for @lyricsNoneAutoOffMessage.
  ///
  /// In en, this message translates to:
  /// **'No lyrics in the file or in an .lrc file next to the song. Automatic search is off.'**
  String get lyricsNoneAutoOffMessage;

  /// No description provided for @lyricsFindManually.
  ///
  /// In en, this message translates to:
  /// **'Search manually…'**
  String get lyricsFindManually;

  /// No description provided for @lyricsNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Lyrics not found'**
  String get lyricsNotFoundTitle;

  /// No description provided for @lyricsNotFoundAsked.
  ///
  /// In en, this message translates to:
  /// **'Searched {count, plural, =1{1 enabled source} other{{count} enabled sources}}.'**
  String lyricsNotFoundAsked(int count);

  /// No description provided for @lyricsNotFoundOff.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 other source is off.} other{{count} other sources are off.}}'**
  String lyricsNotFoundOff(int count);

  /// No description provided for @lyricsNotFoundAllOff.
  ///
  /// In en, this message translates to:
  /// **'No lyrics on this device · every online lyrics source is off.'**
  String get lyricsNotFoundAllOff;

  /// No description provided for @lyricsNoSourceMessage.
  ///
  /// In en, this message translates to:
  /// **'No lyrics on this device and no online lyrics source yet.'**
  String get lyricsNoSourceMessage;

  /// No description provided for @lyricsAddSource.
  ///
  /// In en, this message translates to:
  /// **'Add an online lyrics source'**
  String get lyricsAddSource;

  /// No description provided for @lyricsInstrumentalTitle.
  ///
  /// In en, this message translates to:
  /// **'Instrumental'**
  String get lyricsInstrumentalTitle;

  /// No description provided for @lyricsInstrumentalMessage.
  ///
  /// In en, this message translates to:
  /// **'The lyrics source says this song is instrumental.'**
  String get lyricsInstrumentalMessage;

  /// No description provided for @lyricsInstrumentalFindOnline.
  ///
  /// In en, this message translates to:
  /// **'Not right? Find lyrics online…'**
  String get lyricsInstrumentalFindOnline;

  /// No description provided for @lyricsFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t find lyrics'**
  String get lyricsFailedTitle;

  /// No description provided for @lyricsFailNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error searching {count, plural, =1{1 enabled source} other{{count} enabled sources}}'**
  String lyricsFailNetwork(int count);

  /// No description provided for @lyricsFailNeedsConfig.
  ///
  /// In en, this message translates to:
  /// **'The sources need setting up'**
  String get lyricsFailNeedsConfig;

  /// No description provided for @lyricsFailNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'The lyrics sources did not answer'**
  String get lyricsFailNoAnswer;

  /// No description provided for @lyricsFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'{reason}.'**
  String lyricsFailedMessage(String reason);

  /// No description provided for @lyricsFailedMessageRetry.
  ///
  /// In en, this message translates to:
  /// **'{reason} · trying again at {time}.'**
  String lyricsFailedMessageRetry(String reason, String time);

  /// No description provided for @lyricsPausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Lyrics sources are paused'**
  String get lyricsPausedTitle;

  /// No description provided for @lyricsPausedMessage.
  ///
  /// In en, this message translates to:
  /// **'The lyrics sources are paused until {time}: the server reported too many requests. Kanaru searches again then.'**
  String lyricsPausedMessage(String time);

  /// No description provided for @lyricsKindSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get lyricsKindSynced;

  /// No description provided for @lyricsKindPlain.
  ///
  /// In en, this message translates to:
  /// **'Plain'**
  String get lyricsKindPlain;

  /// No description provided for @lyricsOnlineLabel.
  ///
  /// In en, this message translates to:
  /// **'{plugin} · {kind}'**
  String lyricsOnlineLabel(String plugin, String kind);

  /// No description provided for @lyricsLabelSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get lyricsLabelSearching;

  /// No description provided for @lyricsLabelFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t find lyrics'**
  String get lyricsLabelFailed;

  /// No description provided for @lyricsLabelPaused.
  ///
  /// In en, this message translates to:
  /// **'Lyrics sources paused'**
  String get lyricsLabelPaused;

  /// No description provided for @lyricsCardFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t find lyrics · trying again at {time}'**
  String lyricsCardFailedRetry(String time);

  /// No description provided for @lyricsCardPaused.
  ///
  /// In en, this message translates to:
  /// **'Lyrics sources paused until {time}'**
  String lyricsCardPaused(String time);

  /// No description provided for @lyricsChoiceOnline.
  ///
  /// In en, this message translates to:
  /// **'Online lyrics'**
  String get lyricsChoiceOnline;

  /// No description provided for @lyricsOnlineAuto.
  ///
  /// In en, this message translates to:
  /// **'found automatically'**
  String get lyricsOnlineAuto;

  /// No description provided for @lyricsOnlineRemoved.
  ///
  /// In en, this message translates to:
  /// **'plugin removed'**
  String get lyricsOnlineRemoved;

  /// No description provided for @lyricsOnlineInstrumental.
  ///
  /// In en, this message translates to:
  /// **'Instrumental'**
  String get lyricsOnlineInstrumental;

  /// No description provided for @lyricsStatusSearching.
  ///
  /// In en, this message translates to:
  /// **'No lyrics on this device · searching {count, plural, =1{1 enabled source} other{{count} enabled sources}}'**
  String lyricsStatusSearching(int count);

  /// No description provided for @lyricsStatusNotFound.
  ///
  /// In en, this message translates to:
  /// **'No lyrics found, even in {count, plural, =1{1 enabled source} other{{count} enabled sources}}'**
  String lyricsStatusNotFound(int count);

  /// No description provided for @lyricsStatusAutoOff.
  ///
  /// In en, this message translates to:
  /// **'No lyrics on this device · automatic search is off'**
  String get lyricsStatusAutoOff;

  /// No description provided for @lyricsStatusNoSource.
  ///
  /// In en, this message translates to:
  /// **'No lyrics on this device · no online source yet'**
  String get lyricsStatusNoSource;

  /// No description provided for @lyricsStatusAllOff.
  ///
  /// In en, this message translates to:
  /// **'No lyrics on this device · every online source is off'**
  String get lyricsStatusAllOff;

  /// No description provided for @lyricsStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t find lyrics · {reason}'**
  String lyricsStatusFailed(String reason);

  /// No description provided for @lyricsStatusFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t find lyrics · {reason} · trying again at {time}'**
  String lyricsStatusFailedRetry(String reason, String time);

  /// No description provided for @lyricsFailShortNetwork.
  ///
  /// In en, this message translates to:
  /// **'network error'**
  String get lyricsFailShortNetwork;

  /// No description provided for @lyricsFailShortNeedsConfig.
  ///
  /// In en, this message translates to:
  /// **'needs setting up'**
  String get lyricsFailShortNeedsConfig;

  /// No description provided for @lyricsFailShortNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'no answer'**
  String get lyricsFailShortNoAnswer;

  /// No description provided for @lyricsStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'The lyrics sources are paused until {time} (the server reported too many requests)'**
  String lyricsStatusPaused(String time);

  /// No description provided for @lyricsFindOnlineSub.
  ///
  /// In en, this message translates to:
  /// **'{on} on · {off} off'**
  String lyricsFindOnlineSub(int on, int off);

  /// No description provided for @lyricsFindOnlineSubAllOff.
  ///
  /// In en, this message translates to:
  /// **'Every source is off ({off}) · searches only when you tap'**
  String lyricsFindOnlineSubAllOff(int off);

  /// No description provided for @lyricsAddSourceSub.
  ///
  /// In en, this message translates to:
  /// **'No lyrics plugin installed · open the plugin store'**
  String get lyricsAddSourceSub;

  /// No description provided for @lyricsBarAutoTitle.
  ///
  /// In en, this message translates to:
  /// **'Found automatically on {plugin}'**
  String lyricsBarAutoTitle(String plugin);

  /// No description provided for @lyricsBarAutoSub.
  ///
  /// In en, this message translates to:
  /// **'Keep it so Kanaru does not search again'**
  String get lyricsBarAutoSub;

  /// No description provided for @lyricsBarKeptTitle.
  ///
  /// In en, this message translates to:
  /// **'Using the kept copy'**
  String get lyricsBarKeptTitle;

  /// No description provided for @lyricsBarKeptSub.
  ///
  /// In en, this message translates to:
  /// **'For this song only'**
  String get lyricsBarKeptSub;

  /// No description provided for @lyricsBarReject.
  ///
  /// In en, this message translates to:
  /// **'Wrong song'**
  String get lyricsBarReject;

  /// No description provided for @lyricsBarKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep this copy'**
  String get lyricsBarKeep;

  /// No description provided for @lyricsStatusEnableAuto.
  ///
  /// In en, this message translates to:
  /// **'Turn on auto search'**
  String get lyricsStatusEnableAuto;

  /// No description provided for @lyricsPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose lyrics'**
  String get lyricsPickerTitle;

  /// No description provided for @lyricsPickerBack.
  ///
  /// In en, this message translates to:
  /// **'Back to Lyrics for this song'**
  String get lyricsPickerBack;

  /// No description provided for @lyricsPickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Song, artist'**
  String get lyricsPickerSearchHint;

  /// No description provided for @lyricsPickerFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get lyricsPickerFilterAll;

  /// No description provided for @lyricsPickerGroup.
  ///
  /// In en, this message translates to:
  /// **'{name} · {count}'**
  String lyricsPickerGroup(String name, int count);

  /// No description provided for @lyricsPickerGroupOff.
  ///
  /// In en, this message translates to:
  /// **'{name} · off · {count}'**
  String lyricsPickerGroupOff(String name, int count);

  /// No description provided for @lyricsPickerBadgeOff.
  ///
  /// In en, this message translates to:
  /// **'Source is off'**
  String get lyricsPickerBadgeOff;

  /// No description provided for @lyricsPickerDeltaMatch.
  ///
  /// In en, this message translates to:
  /// **'match'**
  String get lyricsPickerDeltaMatch;

  /// No description provided for @lyricsPickerDeltaMatchTip.
  ///
  /// In en, this message translates to:
  /// **'Length matches the song'**
  String get lyricsPickerDeltaMatchTip;

  /// No description provided for @lyricsPickerDeltaLonger.
  ///
  /// In en, this message translates to:
  /// **'+{seconds} s'**
  String lyricsPickerDeltaLonger(int seconds);

  /// No description provided for @lyricsPickerDeltaShorter.
  ///
  /// In en, this message translates to:
  /// **'−{seconds} s'**
  String lyricsPickerDeltaShorter(int seconds);

  /// No description provided for @lyricsPickerDeltaLongerTip.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds longer than the song: may be another version (live, remix…)'**
  String lyricsPickerDeltaLongerTip(int seconds);

  /// No description provided for @lyricsPickerDeltaShorterTip.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds shorter than the song: may be another version (live, remix…)'**
  String lyricsPickerDeltaShorterTip(int seconds);

  /// No description provided for @lyricsPickerSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching {name}…'**
  String lyricsPickerSearching(String name);

  /// No description provided for @lyricsPickerFailNetwork.
  ///
  /// In en, this message translates to:
  /// **'{name}: network error or timed out'**
  String lyricsPickerFailNetwork(String name);

  /// No description provided for @lyricsPickerFailServer.
  ///
  /// In en, this message translates to:
  /// **'{name}: the server returned an error'**
  String lyricsPickerFailServer(String name);

  /// No description provided for @lyricsPickerFailRateLimited.
  ///
  /// In en, this message translates to:
  /// **'{name}: the server says too many requests'**
  String lyricsPickerFailRateLimited(String name);

  /// No description provided for @lyricsPickerFailInvalid.
  ///
  /// In en, this message translates to:
  /// **'{name}: the answer could not be read'**
  String lyricsPickerFailInvalid(String name);

  /// No description provided for @lyricsPickerNeedsConfig.
  ///
  /// In en, this message translates to:
  /// **'{name} · Needs setup'**
  String lyricsPickerNeedsConfig(String name);

  /// No description provided for @lyricsPickerOpenPlugin.
  ///
  /// In en, this message translates to:
  /// **'Open plugin page'**
  String get lyricsPickerOpenPlugin;

  /// No description provided for @lyricsPickerPaused.
  ///
  /// In en, this message translates to:
  /// **'{name} is paused until {time}'**
  String lyricsPickerPaused(String name, String time);

  /// No description provided for @lyricsPickerMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Not the lyrics you wanted?'**
  String get lyricsPickerMoreTitle;

  /// No description provided for @lyricsPickerMoreBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One source is off: {names}. Searched only when you tap, settings stay as they are.} other{{count} sources are off: {names}. Searched only when you tap, settings stay as they are.}}'**
  String lyricsPickerMoreBody(int count, String names);

  /// No description provided for @lyricsPickerMoreAction.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get lyricsPickerMoreAction;

  /// No description provided for @lyricsPickerEmptyNone.
  ///
  /// In en, this message translates to:
  /// **'No source is on'**
  String get lyricsPickerEmptyNone;

  /// No description provided for @lyricsPickerEmptyNotFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Nothing found in the source that is on} other{Nothing found in {count} sources that are on}}'**
  String lyricsPickerEmptyNotFound(int count);

  /// No description provided for @lyricsPickerEmptyOff.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One source is off ({names}). Searched only when you tap.} other{{count} sources are off ({names}). Searched only when you tap.}}'**
  String lyricsPickerEmptyOff(int count, String names);

  /// No description provided for @lyricsPickerEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Search the source that is off} other{Search {count} sources that are off}}'**
  String lyricsPickerEmptyAction(int count);

  /// No description provided for @lyricsPickerAllAsked.
  ///
  /// In en, this message translates to:
  /// **'Sources that are off were searched too for this song. Source settings are unchanged.'**
  String get lyricsPickerAllAsked;

  /// No description provided for @lyricsPickerPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get lyricsPickerPreview;

  /// No description provided for @lyricsPickerPreviewFrom.
  ///
  /// In en, this message translates to:
  /// **'Preview · {name}'**
  String lyricsPickerPreviewFrom(String name);

  /// No description provided for @lyricsPickerPickOne.
  ///
  /// In en, this message translates to:
  /// **'Choose a result'**
  String get lyricsPickerPickOne;

  /// No description provided for @lyricsPickerPreviewBack.
  ///
  /// In en, this message translates to:
  /// **'Back to the list'**
  String get lyricsPickerPreviewBack;

  /// No description provided for @lyricsPickerPreviewBackLabel.
  ///
  /// In en, this message translates to:
  /// **'Back to the results'**
  String get lyricsPickerPreviewBackLabel;

  /// No description provided for @lyricsPickerPlainNote.
  ///
  /// In en, this message translates to:
  /// **'Plain lyrics, no timestamps'**
  String get lyricsPickerPlainNote;

  /// No description provided for @lyricsPickerPreviewLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading lyrics…'**
  String get lyricsPickerPreviewLoading;

  /// No description provided for @lyricsPickerPreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the lyrics of this result'**
  String get lyricsPickerPreviewFailed;

  /// No description provided for @lyricsPickerPreviewMissing.
  ///
  /// In en, this message translates to:
  /// **'This result has no lyrics'**
  String get lyricsPickerPreviewMissing;

  /// No description provided for @lyricsPickerPreviewInstrumental.
  ///
  /// In en, this message translates to:
  /// **'Instrumental'**
  String get lyricsPickerPreviewInstrumental;

  /// No description provided for @lyricsPickerFootNote.
  ///
  /// In en, this message translates to:
  /// **'For this song only'**
  String get lyricsPickerFootNote;

  /// No description provided for @lyricsPickerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get lyricsPickerCancel;

  /// No description provided for @lyricsPickerUse.
  ///
  /// In en, this message translates to:
  /// **'Use these lyrics'**
  String get lyricsPickerUse;

  /// No description provided for @lyricsPickerSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Search sources'**
  String get lyricsPickerSourcesTitle;

  /// No description provided for @lyricsPickerSourcesAll.
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get lyricsPickerSourcesAll;

  /// No description provided for @lyricsPickerSourcesResults.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}}'**
  String lyricsPickerSourcesResults(int count);

  /// No description provided for @lyricsPickerSourcesNone.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get lyricsPickerSourcesNone;

  /// No description provided for @lyricsPickerSourcesOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get lyricsPickerSourcesOff;

  /// No description provided for @lyricsPickerSourcesOffCaption.
  ///
  /// In en, this message translates to:
  /// **'Searched only when you tap Search.'**
  String get lyricsPickerSourcesOffCaption;

  /// No description provided for @lyricsPickerSourcesOffResults.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result · source is off} other{{count} results · source is off}}'**
  String lyricsPickerSourcesOffResults(int count);

  /// No description provided for @lyricsPickerSourcesNotAsked.
  ///
  /// In en, this message translates to:
  /// **'Not searched'**
  String get lyricsPickerSourcesNotAsked;

  /// No description provided for @lyricsPickerClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear the search text'**
  String get lyricsPickerClearSearch;

  /// No description provided for @lyricsKeepFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the lyrics. Try again.'**
  String get lyricsKeepFailed;

  /// No description provided for @lyricsToastKept.
  ///
  /// In en, this message translates to:
  /// **'Kept the {plugin} copy for this song'**
  String lyricsToastKept(String plugin);

  /// No description provided for @lyricsToastRefusedAuto.
  ///
  /// In en, this message translates to:
  /// **'Dropped this copy, searching again…'**
  String get lyricsToastRefusedAuto;

  /// No description provided for @lyricsToastRefusedKept.
  ///
  /// In en, this message translates to:
  /// **'Dropped the kept copy'**
  String get lyricsToastRefusedKept;

  /// No description provided for @lyricsToastChosen.
  ///
  /// In en, this message translates to:
  /// **'Chose the lyrics from {plugin} for this song'**
  String lyricsToastChosen(String plugin);

  /// No description provided for @lyricsSettingsAutoFindNone.
  ///
  /// In en, this message translates to:
  /// **'No lyrics source is on · turn one on below'**
  String get lyricsSettingsAutoFindNone;

  /// No description provided for @lyricsSettingsSourcesCount.
  ///
  /// In en, this message translates to:
  /// **'{on} / {total} sources on'**
  String lyricsSettingsSourcesCount(int on, int total);

  /// No description provided for @lyricsSettingsSourcesHint.
  ///
  /// In en, this message translates to:
  /// **'Order of the search when it runs by itself: drag to sort. A source that is off is only searched when you tap “Search online lyrics…”. A plugin installed from a repository starts on and goes to the end of the list. A plugin installed from a file or a link starts off (searched only when you tap) until you turn it on.'**
  String get lyricsSettingsSourcesHint;

  /// No description provided for @lyricsSettingsSourceRepo.
  ///
  /// In en, this message translates to:
  /// **'Plugin · v{version}'**
  String lyricsSettingsSourceRepo(int version);

  /// No description provided for @lyricsSettingsSourceFile.
  ///
  /// In en, this message translates to:
  /// **'Installed from a file · v{version}'**
  String lyricsSettingsSourceFile(int version);

  /// No description provided for @lyricsSettingsSourceLink.
  ///
  /// In en, this message translates to:
  /// **'Installed from a link · v{version}'**
  String lyricsSettingsSourceLink(int version);

  /// No description provided for @lyricsSettingsSourceOff.
  ///
  /// In en, this message translates to:
  /// **'{line} · only searched when you tap'**
  String lyricsSettingsSourceOff(String line);

  /// No description provided for @lyricsSettingsSourceNeedsConfig.
  ///
  /// In en, this message translates to:
  /// **'Needs setup · open the plugin page to fill it in'**
  String get lyricsSettingsSourceNeedsConfig;

  /// No description provided for @lyricsSettingsSourcePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused until {time}'**
  String lyricsSettingsSourcePaused(String time);

  /// No description provided for @lyricsSettingsSourceBroken.
  ///
  /// In en, this message translates to:
  /// **'Broken package · open the plugin page'**
  String get lyricsSettingsSourceBroken;

  /// No description provided for @lyricsSettingsSourceSwitch.
  ///
  /// In en, this message translates to:
  /// **'{name}: use for automatic search'**
  String lyricsSettingsSourceSwitch(String name);

  /// No description provided for @lyricsSettingsSourceDrag.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get lyricsSettingsSourceDrag;

  /// No description provided for @lyricsSettingsSourceOnToast.
  ///
  /// In en, this message translates to:
  /// **'{name}: on for automatic search'**
  String lyricsSettingsSourceOnToast(String name);

  /// No description provided for @lyricsSettingsSourceOffToast.
  ///
  /// In en, this message translates to:
  /// **'{name}: off · only searched when you tap'**
  String lyricsSettingsSourceOffToast(String name);

  /// No description provided for @lyricsInfoGroup.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyricsInfoGroup;

  /// No description provided for @lyricsInfoSourceRow.
  ///
  /// In en, this message translates to:
  /// **'Lyrics source'**
  String get lyricsInfoSourceRow;

  /// No description provided for @lyricsInfoSourceTag.
  ///
  /// In en, this message translates to:
  /// **'In the file\'s tags'**
  String get lyricsInfoSourceTag;

  /// No description provided for @lyricsInfoSourceLrc.
  ///
  /// In en, this message translates to:
  /// **'.lrc file next to the song · {name}'**
  String lyricsInfoSourceLrc(String name);

  /// No description provided for @lyricsInfoSourceLrcBare.
  ///
  /// In en, this message translates to:
  /// **'.lrc file next to the song'**
  String get lyricsInfoSourceLrcBare;

  /// No description provided for @lyricsInfoSourceKept.
  ///
  /// In en, this message translates to:
  /// **'Kept online copy · {plugin}'**
  String lyricsInfoSourceKept(String plugin);

  /// No description provided for @lyricsInfoNone.
  ///
  /// In en, this message translates to:
  /// **'No lyrics yet'**
  String get lyricsInfoNone;

  /// No description provided for @lyricsInfoNoneHint.
  ///
  /// In en, this message translates to:
  /// **'Add lyrics from the song menu › Lyrics source'**
  String get lyricsInfoNoneHint;

  /// No description provided for @lyricsInfoLines.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line} other{{count} lines}}'**
  String lyricsInfoLines(int count);

  /// No description provided for @lyricsInfoSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all lyrics'**
  String get lyricsInfoSeeAll;

  /// No description provided for @lyricsInfoCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy lyrics'**
  String get lyricsInfoCopy;

  /// No description provided for @lyricsInfoCopied.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Lyrics copied (1 line)} other{Lyrics copied ({count} lines)}}'**
  String lyricsInfoCopied(int count);

  /// No description provided for @lyricsInfoShowStamps.
  ///
  /// In en, this message translates to:
  /// **'Show timestamps'**
  String get lyricsInfoShowStamps;

  /// No description provided for @lyricsInfoHideStamps.
  ///
  /// In en, this message translates to:
  /// **'Hide timestamps'**
  String get lyricsInfoHideStamps;

  /// No description provided for @lyricsInfoUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the lyrics'**
  String get lyricsInfoUnreadable;

  /// No description provided for @lyricsTranslationCredit.
  ///
  /// In en, this message translates to:
  /// **'Translated by {by} · {language}'**
  String lyricsTranslationCredit(String by, String language);

  /// No description provided for @lyricsTranslationCreditPartial.
  ///
  /// In en, this message translates to:
  /// **'Translated by {by} · {language} · partial {done}/{total} lines'**
  String lyricsTranslationCreditPartial(
    String by,
    String language,
    int done,
    int total,
  );

  /// No description provided for @lyricsTranslationCreditOther.
  ///
  /// In en, this message translates to:
  /// **'Existing translation from {plugin}'**
  String lyricsTranslationCreditOther(String plugin);

  /// No description provided for @lyricsLangVi.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get lyricsLangVi;

  /// No description provided for @lyricsLangEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get lyricsLangEn;

  /// No description provided for @lyricsLangJa.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get lyricsLangJa;

  /// No description provided for @lyricsLangKo.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get lyricsLangKo;

  /// No description provided for @lyricsLangZhHans.
  ///
  /// In en, this message translates to:
  /// **'Chinese (Simplified)'**
  String get lyricsLangZhHans;

  /// No description provided for @lyricsLangZhHant.
  ///
  /// In en, this message translates to:
  /// **'Chinese (Traditional)'**
  String get lyricsLangZhHant;

  /// No description provided for @lyricsLangFr.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get lyricsLangFr;

  /// No description provided for @lyricsLangDe.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get lyricsLangDe;

  /// No description provided for @lyricsLangEs.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get lyricsLangEs;

  /// No description provided for @lyricsLangIt.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get lyricsLangIt;

  /// No description provided for @lyricsLangRu.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get lyricsLangRu;

  /// No description provided for @lyricsLangPt.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get lyricsLangPt;

  /// No description provided for @lyricsLangTh.
  ///
  /// In en, this message translates to:
  /// **'Thai'**
  String get lyricsLangTh;

  /// No description provided for @lyricsLangId.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get lyricsLangId;

  /// No description provided for @lyricsLangHi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get lyricsLangHi;

  /// No description provided for @lyricsLangAr.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get lyricsLangAr;

  /// No description provided for @lyricsLangNl.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get lyricsLangNl;

  /// No description provided for @lyricsLangSv.
  ///
  /// In en, this message translates to:
  /// **'Swedish'**
  String get lyricsLangSv;

  /// No description provided for @lyricsLangPl.
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get lyricsLangPl;

  /// No description provided for @lyricsLangTr.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get lyricsLangTr;

  /// No description provided for @lyricsLangUk.
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get lyricsLangUk;

  /// No description provided for @lyricsLangCs.
  ///
  /// In en, this message translates to:
  /// **'Czech'**
  String get lyricsLangCs;

  /// No description provided for @lyricsLangEl.
  ///
  /// In en, this message translates to:
  /// **'Greek'**
  String get lyricsLangEl;

  /// No description provided for @lyricsLangFa.
  ///
  /// In en, this message translates to:
  /// **'Persian'**
  String get lyricsLangFa;

  /// No description provided for @lyricsLangRo.
  ///
  /// In en, this message translates to:
  /// **'Romanian'**
  String get lyricsLangRo;

  /// No description provided for @lyricsLangMs.
  ///
  /// In en, this message translates to:
  /// **'Malay'**
  String get lyricsLangMs;

  /// No description provided for @lyricsLangHe.
  ///
  /// In en, this message translates to:
  /// **'Hebrew'**
  String get lyricsLangHe;

  /// No description provided for @lyricsLangFi.
  ///
  /// In en, this message translates to:
  /// **'Finnish'**
  String get lyricsLangFi;

  /// No description provided for @lyricsLangDa.
  ///
  /// In en, this message translates to:
  /// **'Danish'**
  String get lyricsLangDa;

  /// No description provided for @lyricsLangNo.
  ///
  /// In en, this message translates to:
  /// **'Norwegian'**
  String get lyricsLangNo;

  /// No description provided for @lyricsLangHu.
  ///
  /// In en, this message translates to:
  /// **'Hungarian'**
  String get lyricsLangHu;

  /// No description provided for @lyricsLangCy.
  ///
  /// In en, this message translates to:
  /// **'Welsh'**
  String get lyricsLangCy;

  /// No description provided for @lyricsLangSk.
  ///
  /// In en, this message translates to:
  /// **'Slovak'**
  String get lyricsLangSk;

  /// No description provided for @lyricsLangSq.
  ///
  /// In en, this message translates to:
  /// **'Albanian'**
  String get lyricsLangSq;

  /// No description provided for @lyricsLangHy.
  ///
  /// In en, this message translates to:
  /// **'Armenian'**
  String get lyricsLangHy;

  /// No description provided for @lyricsLangEu.
  ///
  /// In en, this message translates to:
  /// **'Basque'**
  String get lyricsLangEu;

  /// No description provided for @lyricsLangMy.
  ///
  /// In en, this message translates to:
  /// **'Burmese'**
  String get lyricsLangMy;

  /// No description provided for @lyricsLangKa.
  ///
  /// In en, this message translates to:
  /// **'Georgian'**
  String get lyricsLangKa;

  /// No description provided for @lyricsLangIs.
  ///
  /// In en, this message translates to:
  /// **'Icelandic'**
  String get lyricsLangIs;

  /// No description provided for @lyricsLangMk.
  ///
  /// In en, this message translates to:
  /// **'Macedonian'**
  String get lyricsLangMk;

  /// No description provided for @lyricsLangMi.
  ///
  /// In en, this message translates to:
  /// **'Māori'**
  String get lyricsLangMi;

  /// No description provided for @lyricsTranslateTitle.
  ///
  /// In en, this message translates to:
  /// **'Translate lyrics'**
  String get lyricsTranslateTitle;

  /// No description provided for @lyricsTranslateSettings.
  ///
  /// In en, this message translates to:
  /// **'Translation settings'**
  String get lyricsTranslateSettings;

  /// No description provided for @lyricsTranslatePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get lyricsTranslatePreview;

  /// No description provided for @lyricsTranslateDisplay.
  ///
  /// In en, this message translates to:
  /// **'How the translation shows'**
  String get lyricsTranslateDisplay;

  /// No description provided for @lyricsTranslateDisplayUnder.
  ///
  /// In en, this message translates to:
  /// **'Below line'**
  String get lyricsTranslateDisplayUnder;

  /// No description provided for @lyricsTranslateDisplayReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace line'**
  String get lyricsTranslateDisplayReplace;

  /// No description provided for @lyricsTranslateBy.
  ///
  /// In en, this message translates to:
  /// **'Translated by {by}'**
  String lyricsTranslateBy(String by);

  /// No description provided for @lyricsTranslateByPartial.
  ///
  /// In en, this message translates to:
  /// **'Translated by {by} · {done}/{total} lines only'**
  String lyricsTranslateByPartial(String by, int done, int total);

  /// No description provided for @lyricsTranslateRedoing.
  ///
  /// In en, this message translates to:
  /// **'Translating again, the old translation stays'**
  String get lyricsTranslateRedoing;

  /// No description provided for @lyricsTranslateRetranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate again'**
  String get lyricsTranslateRetranslate;

  /// No description provided for @lyricsTranslateSection.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get lyricsTranslateSection;

  /// No description provided for @lyricsTranslateSourceAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect'**
  String get lyricsTranslateSourceAuto;

  /// No description provided for @lyricsTranslateSourceDetected.
  ///
  /// In en, this message translates to:
  /// **'{language} · detected'**
  String lyricsTranslateSourceDetected(String language);

  /// No description provided for @lyricsTranslateSourceHint.
  ///
  /// In en, this message translates to:
  /// **'Language of the lyrics, detected by the translation service'**
  String get lyricsTranslateSourceHint;

  /// No description provided for @lyricsTranslateSwitch.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get lyricsTranslateSwitch;

  /// No description provided for @lyricsTranslateTarget.
  ///
  /// In en, this message translates to:
  /// **'Translate into {language}'**
  String lyricsTranslateTarget(String language);

  /// No description provided for @lyricsTranslateNoPluginTitle.
  ///
  /// In en, this message translates to:
  /// **'No translation plugin yet'**
  String get lyricsTranslateNoPluginTitle;

  /// No description provided for @lyricsTranslateNoPluginBody.
  ///
  /// In en, this message translates to:
  /// **'Install a translation plugin (Google, DeepL, Gemini…) from the plugin store to translate lyrics.'**
  String get lyricsTranslateNoPluginBody;

  /// No description provided for @lyricsTranslateOpenStore.
  ///
  /// In en, this message translates to:
  /// **'Open plugin store'**
  String get lyricsTranslateOpenStore;

  /// No description provided for @lyricsTranslateServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get lyricsTranslateServiceTitle;

  /// No description provided for @lyricsTranslateServiceUnset.
  ///
  /// In en, this message translates to:
  /// **'No service chosen'**
  String get lyricsTranslateServiceUnset;

  /// No description provided for @lyricsTranslateServiceGone.
  ///
  /// In en, this message translates to:
  /// **'The default service was removed, choose another'**
  String get lyricsTranslateServiceGone;

  /// No description provided for @lyricsTranslateServiceScope.
  ///
  /// In en, this message translates to:
  /// **'Default for every song'**
  String get lyricsTranslateServiceScope;

  /// No description provided for @lyricsTranslateAiTag.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get lyricsTranslateAiTag;

  /// No description provided for @lyricsTranslateTuneTitle.
  ///
  /// In en, this message translates to:
  /// **'AI tuning'**
  String get lyricsTranslateTuneTitle;

  /// No description provided for @lyricsTranslatePhoneticSection.
  ///
  /// In en, this message translates to:
  /// **'Transliteration'**
  String get lyricsTranslatePhoneticSection;

  /// No description provided for @lyricsTranslatePhoneticTitle.
  ///
  /// In en, this message translates to:
  /// **'Furigana, Romaji'**
  String get lyricsTranslatePhoneticTitle;

  /// No description provided for @lyricsTranslatePhoneticDesc.
  ///
  /// In en, this message translates to:
  /// **'Transliteration of Japanese, Chinese and Korean lyrics'**
  String get lyricsTranslatePhoneticDesc;

  /// No description provided for @lyricsTranslateSoonTag.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get lyricsTranslateSoonTag;

  /// No description provided for @lyricsTranslateWorking.
  ///
  /// In en, this message translates to:
  /// **'Translating…'**
  String get lyricsTranslateWorking;

  /// No description provided for @lyricsTranslateWorkingCount.
  ///
  /// In en, this message translates to:
  /// **'Translating… {done}/{total} lines'**
  String lyricsTranslateWorkingCount(int done, int total);

  /// No description provided for @lyricsTranslateWorkingAgain.
  ///
  /// In en, this message translates to:
  /// **'Translating again…'**
  String get lyricsTranslateWorkingAgain;

  /// No description provided for @lyricsTranslateWorkingAgainCount.
  ///
  /// In en, this message translates to:
  /// **'Translating again… {done}/{total} lines'**
  String lyricsTranslateWorkingAgainCount(int done, int total);

  /// No description provided for @lyricsTranslateCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get lyricsTranslateCancel;

  /// No description provided for @lyricsTranslateSame.
  ///
  /// In en, this message translates to:
  /// **'The lyrics already are in {language} (per {service})'**
  String lyricsTranslateSame(String language, String service);

  /// No description provided for @lyricsTranslatePartialTitle.
  ///
  /// In en, this message translates to:
  /// **'Only {done}/{total} lines translated'**
  String lyricsTranslatePartialTitle(int done, int total);

  /// No description provided for @lyricsTranslatePartialLine.
  ///
  /// In en, this message translates to:
  /// **'The rest failed: {reason}'**
  String lyricsTranslatePartialLine(String reason);

  /// No description provided for @lyricsTranslatePausedTitle.
  ///
  /// In en, this message translates to:
  /// **'{service} is paused'**
  String lyricsTranslatePausedTitle(String service);

  /// No description provided for @lyricsTranslatePausedLine.
  ///
  /// In en, this message translates to:
  /// **'The server reports too many requests (429) · Kanaru translates again after {time}'**
  String lyricsTranslatePausedLine(String time);

  /// No description provided for @lyricsTranslateNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach {service}'**
  String lyricsTranslateNetworkTitle(String service);

  /// No description provided for @lyricsTranslateNetworkLine.
  ///
  /// In en, this message translates to:
  /// **'Network error or timeout'**
  String get lyricsTranslateNetworkLine;

  /// No description provided for @lyricsTranslateServerTitle.
  ///
  /// In en, this message translates to:
  /// **'{service} has an error'**
  String lyricsTranslateServerTitle(String service);

  /// No description provided for @lyricsTranslateServerLine.
  ///
  /// In en, this message translates to:
  /// **'The service\'s server returned an error'**
  String get lyricsTranslateServerLine;

  /// No description provided for @lyricsTranslateQuotaTitle.
  ///
  /// In en, this message translates to:
  /// **'{service} is out of quota'**
  String lyricsTranslateQuotaTitle(String service);

  /// No description provided for @lyricsTranslateQuotaLine.
  ///
  /// In en, this message translates to:
  /// **'This API key has no translations left · wait for the next period or change service'**
  String get lyricsTranslateQuotaLine;

  /// No description provided for @lyricsTranslateBadKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'{service} reports an error'**
  String lyricsTranslateBadKeyTitle(String service);

  /// No description provided for @lyricsTranslateBadKeyLine.
  ///
  /// In en, this message translates to:
  /// **'The API key is invalid or expired'**
  String get lyricsTranslateBadKeyLine;

  /// No description provided for @lyricsTranslateConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'{service} needs to be set up'**
  String lyricsTranslateConfigTitle(String service);

  /// No description provided for @lyricsTranslateConfigLine.
  ///
  /// In en, this message translates to:
  /// **'Missing: {fields}'**
  String lyricsTranslateConfigLine(String fields);

  /// No description provided for @lyricsTranslateInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'The translation has the wrong number of lines'**
  String get lyricsTranslateInvalidTitle;

  /// No description provided for @lyricsTranslateInvalidLine.
  ///
  /// In en, this message translates to:
  /// **'{service} returned a different number of lines than the lyrics'**
  String lyricsTranslateInvalidLine(String service);

  /// No description provided for @lyricsTranslateTooLongTitle.
  ///
  /// In en, this message translates to:
  /// **'The lyrics are too long to translate'**
  String get lyricsTranslateTooLongTitle;

  /// No description provided for @lyricsTranslateTooLongLine.
  ///
  /// In en, this message translates to:
  /// **'The lyrics exceed what {service} translates in one run'**
  String lyricsTranslateTooLongLine(String service);

  /// No description provided for @lyricsTranslateUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'{service} does not translate into {language}'**
  String lyricsTranslateUnsupportedTitle(String service, String language);

  /// No description provided for @lyricsTranslateUnsupportedLine.
  ///
  /// In en, this message translates to:
  /// **'Choose another language or change service'**
  String get lyricsTranslateUnsupportedLine;

  /// No description provided for @lyricsTranslateGoneTitle.
  ///
  /// In en, this message translates to:
  /// **'The translation service was removed'**
  String get lyricsTranslateGoneTitle;

  /// No description provided for @lyricsTranslateGoneLine.
  ///
  /// In en, this message translates to:
  /// **'Choose another service to keep translating'**
  String get lyricsTranslateGoneLine;

  /// No description provided for @lyricsTranslateUnsetTitle.
  ///
  /// In en, this message translates to:
  /// **'No translation service chosen'**
  String get lyricsTranslateUnsetTitle;

  /// No description provided for @lyricsTranslateUnsetLine.
  ///
  /// In en, this message translates to:
  /// **'The lyrics are sent only after you choose'**
  String get lyricsTranslateUnsetLine;

  /// No description provided for @lyricsTranslateReasonPaused.
  ///
  /// In en, this message translates to:
  /// **'{service} is paused'**
  String lyricsTranslateReasonPaused(String service);

  /// No description provided for @lyricsTranslateReasonNetwork.
  ///
  /// In en, this message translates to:
  /// **'cannot reach {service}'**
  String lyricsTranslateReasonNetwork(String service);

  /// No description provided for @lyricsTranslateReasonServer.
  ///
  /// In en, this message translates to:
  /// **'{service} has an error'**
  String lyricsTranslateReasonServer(String service);

  /// No description provided for @lyricsTranslateReasonQuota.
  ///
  /// In en, this message translates to:
  /// **'{service} is out of quota'**
  String lyricsTranslateReasonQuota(String service);

  /// No description provided for @lyricsTranslateReasonBadKey.
  ///
  /// In en, this message translates to:
  /// **'the API key is invalid or expired'**
  String get lyricsTranslateReasonBadKey;

  /// No description provided for @lyricsTranslateReasonConfig.
  ///
  /// In en, this message translates to:
  /// **'{service} needs to be set up'**
  String lyricsTranslateReasonConfig(String service);

  /// No description provided for @lyricsTranslateReasonInvalid.
  ///
  /// In en, this message translates to:
  /// **'the translation had the wrong number of lines'**
  String get lyricsTranslateReasonInvalid;

  /// No description provided for @lyricsTranslateReasonTooLong.
  ///
  /// In en, this message translates to:
  /// **'the lyrics are too long to translate'**
  String get lyricsTranslateReasonTooLong;

  /// No description provided for @lyricsTranslateReasonUnsupported.
  ///
  /// In en, this message translates to:
  /// **'{service} does not translate into {language}'**
  String lyricsTranslateReasonUnsupported(String service, String language);

  /// No description provided for @lyricsTranslateReasonGone.
  ///
  /// In en, this message translates to:
  /// **'the service was removed'**
  String get lyricsTranslateReasonGone;

  /// No description provided for @lyricsTranslateReasonNoService.
  ///
  /// In en, this message translates to:
  /// **'no service chosen'**
  String get lyricsTranslateReasonNoService;

  /// No description provided for @lyricsTranslateRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get lyricsTranslateRetry;

  /// No description provided for @lyricsTranslateConfigure.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get lyricsTranslateConfigure;

  /// No description provided for @lyricsTranslateChangeService.
  ///
  /// In en, this message translates to:
  /// **'Change service'**
  String get lyricsTranslateChangeService;

  /// No description provided for @lyricsTranslateChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get lyricsTranslateChoose;

  /// No description provided for @lyricsTranslateBarOtherLine.
  ///
  /// In en, this message translates to:
  /// **'Translate again with {service}'**
  String lyricsTranslateBarOtherLine(String service);

  /// No description provided for @lyricsTranslateBarDiffTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings differ from the translation shown'**
  String get lyricsTranslateBarDiffTitle;

  /// No description provided for @lyricsTranslateDiffNote.
  ///
  /// In en, this message translates to:
  /// **'instruction changed'**
  String get lyricsTranslateDiffNote;

  /// No description provided for @lyricsTranslateDiffVersion.
  ///
  /// In en, this message translates to:
  /// **'plugin updated'**
  String get lyricsTranslateDiffVersion;

  /// No description provided for @lyricsTranslateRetranslated.
  ///
  /// In en, this message translates to:
  /// **'Translated again · {name}'**
  String lyricsTranslateRetranslated(String name);

  /// No description provided for @lyricsTranslateServicePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Translation service'**
  String get lyricsTranslateServicePageTitle;

  /// No description provided for @lyricsTranslateServiceSent.
  ///
  /// In en, this message translates to:
  /// **'Lyrics, song title and artist are sent to the plugin when translating.'**
  String get lyricsTranslateServiceSent;

  /// No description provided for @lyricsTranslateScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply to'**
  String get lyricsTranslateScopeTitle;

  /// No description provided for @lyricsTranslateScopeSong.
  ///
  /// In en, this message translates to:
  /// **'This song'**
  String get lyricsTranslateScopeSong;

  /// No description provided for @lyricsTranslateScopeQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get lyricsTranslateScopeQueue;

  /// No description provided for @lyricsTranslateScopeAll.
  ///
  /// In en, this message translates to:
  /// **'Every song'**
  String get lyricsTranslateScopeAll;

  /// No description provided for @lyricsTranslateScopePro.
  ///
  /// In en, this message translates to:
  /// **'A service of its own for a song or the queue: a Pro feature'**
  String get lyricsTranslateScopePro;

  /// No description provided for @lyricsTranslateServiceSection.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get lyricsTranslateServiceSection;

  /// No description provided for @lyricsTranslateMoreServices.
  ///
  /// In en, this message translates to:
  /// **'Get more translation plugins'**
  String get lyricsTranslateMoreServices;

  /// No description provided for @lyricsTranslateMoreServicesSub.
  ///
  /// In en, this message translates to:
  /// **'Open plugin store'**
  String get lyricsTranslateMoreServicesSub;

  /// No description provided for @lyricsTranslateTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Translate into'**
  String get lyricsTranslateTargetTitle;

  /// No description provided for @lyricsTranslateTargetApp.
  ///
  /// In en, this message translates to:
  /// **'Follows the app language'**
  String get lyricsTranslateTargetApp;

  /// No description provided for @lyricsTranslateTargetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the language'**
  String get lyricsTranslateTargetFailed;

  /// No description provided for @lyricsTranslateModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get lyricsTranslateModelTitle;

  /// No description provided for @lyricsTranslateStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get lyricsTranslateStyleTitle;

  /// No description provided for @lyricsTranslateStylePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Translation style'**
  String get lyricsTranslateStylePickerTitle;

  /// No description provided for @lyricsTranslateNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Extra instructions'**
  String get lyricsTranslateNoteTitle;

  /// No description provided for @lyricsTranslateNoteHelper.
  ///
  /// In en, this message translates to:
  /// **'Extra instructions for every song (saved in the settings of {plugin}).'**
  String lyricsTranslateNoteHelper(String plugin);

  /// No description provided for @lyricsTranslateSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search {count} items'**
  String lyricsTranslateSearchHint(int count);

  /// No description provided for @lyricsTranslateDefaultTag.
  ///
  /// In en, this message translates to:
  /// **'default'**
  String get lyricsTranslateDefaultTag;

  /// No description provided for @lyricsTranslateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get lyricsTranslateLater;

  /// No description provided for @lyricsTranslateDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get lyricsTranslateDone;

  /// No description provided for @lyricsTranslateWriteInvalid.
  ///
  /// In en, this message translates to:
  /// **'The value is not valid'**
  String get lyricsTranslateWriteInvalid;

  /// No description provided for @lyricsTranslateWriteTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The instructions are too long'**
  String get lyricsTranslateWriteTooLarge;

  /// No description provided for @lyricsTranslateWriteUnknown.
  ///
  /// In en, this message translates to:
  /// **'This plugin has no such setting'**
  String get lyricsTranslateWriteUnknown;

  /// No description provided for @lyricsTranslateWriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the setting'**
  String get lyricsTranslateWriteFailed;

  /// No description provided for @lyricsTranslateMenuOn.
  ///
  /// In en, this message translates to:
  /// **'Translating into {language}'**
  String lyricsTranslateMenuOn(String language);

  /// No description provided for @lyricsTranslateMenuOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get lyricsTranslateMenuOff;

  /// No description provided for @lyricsTranslateEntryFailed.
  ///
  /// In en, this message translates to:
  /// **'Translation failed'**
  String get lyricsTranslateEntryFailed;

  /// No description provided for @lyricsTranslateEntryNoLyrics.
  ///
  /// In en, this message translates to:
  /// **'No lyrics to translate'**
  String get lyricsTranslateEntryNoLyrics;

  /// No description provided for @lyricsTranslatePillWorking.
  ///
  /// In en, this message translates to:
  /// **'Translating'**
  String get lyricsTranslatePillWorking;

  /// No description provided for @lyricsTranslateToastOn.
  ///
  /// In en, this message translates to:
  /// **'Translation: {language}'**
  String lyricsTranslateToastOn(String language);

  /// No description provided for @lyricsTranslateToastOff.
  ///
  /// In en, this message translates to:
  /// **'Translation off'**
  String get lyricsTranslateToastOff;

  /// No description provided for @lyricsTranslateEntryHintDesktop.
  ///
  /// In en, this message translates to:
  /// **'Right-click or T: turn translation on or off'**
  String get lyricsTranslateEntryHintDesktop;

  /// No description provided for @pluginsStoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Plugin store'**
  String get pluginsStoreTitle;

  /// No description provided for @pluginsFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get pluginsFilterTooltip;

  /// No description provided for @pluginsFilterActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} on'**
  String pluginsFilterActiveLabel(int count);

  /// No description provided for @pluginsMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get pluginsMenuTooltip;

  /// No description provided for @pluginsMenuInstallFile.
  ///
  /// In en, this message translates to:
  /// **'Install from file…'**
  String get pluginsMenuInstallFile;

  /// No description provided for @pluginsMenuInstallLink.
  ///
  /// In en, this message translates to:
  /// **'Install from link…'**
  String get pluginsMenuInstallLink;

  /// No description provided for @pluginsMenuRepositories.
  ///
  /// In en, this message translates to:
  /// **'Repositories ({count})'**
  String pluginsMenuRepositories(int count);

  /// No description provided for @pluginsMenuRefreshAll.
  ///
  /// In en, this message translates to:
  /// **'Refresh all'**
  String get pluginsMenuRefreshAll;

  /// No description provided for @pluginsMenuLogsDesktop.
  ///
  /// In en, this message translates to:
  /// **'Open log folder'**
  String get pluginsMenuLogsDesktop;

  /// No description provided for @pluginsMenuLogsMobile.
  ///
  /// In en, this message translates to:
  /// **'Share plugin logs…'**
  String get pluginsMenuLogsMobile;

  /// No description provided for @pluginsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, author, repository, host, #type'**
  String get pluginsSearchHint;

  /// No description provided for @pluginsSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get pluginsSearchClear;

  /// No description provided for @pluginsSectionUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates ({count})'**
  String pluginsSectionUpdates(int count);

  /// No description provided for @pluginsSectionInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed ({count})'**
  String pluginsSectionInstalled(int count);

  /// No description provided for @pluginsSectionAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not installed ({count})'**
  String pluginsSectionAvailable(int count);

  /// No description provided for @pluginsUpdatesHint.
  ///
  /// In en, this message translates to:
  /// **'“Update all” skips updates with new hosts or permissions: you open those one by one, as when installing.'**
  String get pluginsUpdatesHint;

  /// No description provided for @pluginsUpdatesHintTooltip.
  ///
  /// In en, this message translates to:
  /// **'About updates'**
  String get pluginsUpdatesHintTooltip;

  /// No description provided for @pluginsUpdateAll.
  ///
  /// In en, this message translates to:
  /// **'Update all ({count})'**
  String pluginsUpdateAll(int count);

  /// No description provided for @pluginsUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get pluginsUpdate;

  /// No description provided for @pluginsUpdateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Update {name}'**
  String pluginsUpdateTooltip(String name);

  /// No description provided for @pluginsReviewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Review the update of {name}'**
  String pluginsReviewTooltip(String name);

  /// No description provided for @pluginsPageSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'The plugin’s settings'**
  String get pluginsPageSettingsTitle;

  /// No description provided for @pluginsPageRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh the list'**
  String get pluginsPageRefreshFailed;

  /// No description provided for @pluginsInstallTooltip.
  ///
  /// In en, this message translates to:
  /// **'Install {name}'**
  String pluginsInstallTooltip(String name);

  /// No description provided for @pluginsRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String pluginsRemoveTooltip(String name);

  /// No description provided for @pluginsAlertLabel.
  ///
  /// In en, this message translates to:
  /// **'Has a problem'**
  String get pluginsAlertLabel;

  /// No description provided for @pluginsFreeStreamingLimit.
  ///
  /// In en, this message translates to:
  /// **'The Free edition installs only one music source plugin. Remove the current one to install this.'**
  String get pluginsFreeStreamingLimit;

  /// No description provided for @pluginsKindLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get pluginsKindLyrics;

  /// No description provided for @pluginsKindTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get pluginsKindTranslate;

  /// No description provided for @pluginsKindStreaming.
  ///
  /// In en, this message translates to:
  /// **'Music source'**
  String get pluginsKindStreaming;

  /// No description provided for @pluginsKindNounLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics plugin'**
  String get pluginsKindNounLyrics;

  /// No description provided for @pluginsKindNounTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translation plugin'**
  String get pluginsKindNounTranslate;

  /// No description provided for @pluginsKindNounStreaming.
  ///
  /// In en, this message translates to:
  /// **'Music source plugin'**
  String get pluginsKindNounStreaming;

  /// No description provided for @pluginsKindNounAiChat.
  ///
  /// In en, this message translates to:
  /// **'AI plugin'**
  String get pluginsKindNounAiChat;

  /// No description provided for @pluginsKindHelpLyrics.
  ///
  /// In en, this message translates to:
  /// **'Finds lyrics for the song playing, with lines that follow the song.'**
  String get pluginsKindHelpLyrics;

  /// No description provided for @pluginsKindHelpTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translates lyrics into the language you choose.'**
  String get pluginsKindHelpTranslate;

  /// No description provided for @pluginsKindHelpStreaming.
  ///
  /// In en, this message translates to:
  /// **'Searches and plays music from an online service.'**
  String get pluginsKindHelpStreaming;

  /// No description provided for @pluginsKindAiChat.
  ///
  /// In en, this message translates to:
  /// **'AI chat'**
  String get pluginsKindAiChat;

  /// No description provided for @pluginsKindHelpAiChat.
  ///
  /// In en, this message translates to:
  /// **'Connects an AI service you can chat with.'**
  String get pluginsKindHelpAiChat;

  /// No description provided for @pluginsAuthorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown author'**
  String get pluginsAuthorUnknown;

  /// No description provided for @pluginsFooterNewer.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 plugin needs a newer Kanaru} other{{count} plugins need a newer Kanaru}}'**
  String pluginsFooterNewer(int count);

  /// No description provided for @pluginsSandboxNote.
  ///
  /// In en, this message translates to:
  /// **'Plugins run in a sandbox and can only connect to the addresses declared when installed.'**
  String get pluginsSandboxNote;

  /// No description provided for @pluginsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching plugins.'**
  String get pluginsNoMatch;

  /// No description provided for @pluginsClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get pluginsClearFilters;

  /// No description provided for @pluginsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the plugin list.'**
  String get pluginsLoadFailed;

  /// No description provided for @pluginsNoRepoTitle.
  ///
  /// In en, this message translates to:
  /// **'No repository yet'**
  String get pluginsNoRepoTitle;

  /// No description provided for @pluginsNoRepoBody.
  ///
  /// In en, this message translates to:
  /// **'Kanaru has no built-in repository. A repository is a list of plugins (a plugins.json file) published by plugin authors.'**
  String get pluginsNoRepoBody;

  /// No description provided for @pluginsNoRepoStep1.
  ///
  /// In en, this message translates to:
  /// **'Find the address of the plugins.json file of a repository you trust, usually in the author\'s README. It starts with https://.'**
  String get pluginsNoRepoStep1;

  /// No description provided for @pluginsNoRepoStep2.
  ///
  /// In en, this message translates to:
  /// **'Press Add repository, paste the address, then press Add.'**
  String get pluginsNoRepoStep2;

  /// No description provided for @pluginsNoRepoStep3.
  ///
  /// In en, this message translates to:
  /// **'The repository\'s plugins appear here; press Install to see hosts and facts before installing.'**
  String get pluginsNoRepoStep3;

  /// No description provided for @pluginsAddRepository.
  ///
  /// In en, this message translates to:
  /// **'Add repository'**
  String get pluginsAddRepository;

  /// No description provided for @pluginsRepoFailedOne.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load {name}: {reason}'**
  String pluginsRepoFailedOne(String name, String reason);

  /// No description provided for @pluginsRepoFailedMany.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} repositories couldn\'t load}}'**
  String pluginsRepoFailedMany(int count);

  /// No description provided for @pluginsRepoShowingSaved.
  ///
  /// In en, this message translates to:
  /// **'Showing the list saved at {time}.'**
  String pluginsRepoShowingSaved(String time);

  /// No description provided for @pluginsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get pluginsRetry;

  /// No description provided for @pluginsOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'No network connection'**
  String get pluginsOfflineTitle;

  /// No description provided for @pluginsOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Showing the list saved last time. Installing and updating need a network.'**
  String get pluginsOfflineBody;

  /// No description provided for @pluginsLoadReasonNetwork.
  ///
  /// In en, this message translates to:
  /// **'network error'**
  String get pluginsLoadReasonNetwork;

  /// No description provided for @pluginsLoadReasonNotFound.
  ///
  /// In en, this message translates to:
  /// **'file not found'**
  String get pluginsLoadReasonNotFound;

  /// No description provided for @pluginsLoadReasonTooLarge.
  ///
  /// In en, this message translates to:
  /// **'file too large'**
  String get pluginsLoadReasonTooLarge;

  /// No description provided for @pluginsLoadReasonInvalid.
  ///
  /// In en, this message translates to:
  /// **'not a valid plugin list'**
  String get pluginsLoadReasonInvalid;

  /// No description provided for @pluginsLoadReasonBlocked.
  ///
  /// In en, this message translates to:
  /// **'address blocked'**
  String get pluginsLoadReasonBlocked;

  /// No description provided for @pluginsLoadReasonStorage.
  ///
  /// In en, this message translates to:
  /// **'could not be saved'**
  String get pluginsLoadReasonStorage;

  /// No description provided for @pluginsFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get pluginsFilterTitle;

  /// No description provided for @pluginsFilterGroupKind.
  ///
  /// In en, this message translates to:
  /// **'Plugin type'**
  String get pluginsFilterGroupKind;

  /// No description provided for @pluginsFilterGroupState.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get pluginsFilterGroupState;

  /// No description provided for @pluginsFilterGroupLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get pluginsFilterGroupLanguage;

  /// No description provided for @pluginsFilterGroupAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get pluginsFilterGroupAuthor;

  /// No description provided for @pluginsFilterGroupRepository.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get pluginsFilterGroupRepository;

  /// No description provided for @pluginsStateInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get pluginsStateInstalled;

  /// No description provided for @pluginsStateNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get pluginsStateNotInstalled;

  /// No description provided for @pluginsStateUpdatable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get pluginsStateUpdatable;

  /// No description provided for @pluginsFilterShowing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Showing 1 plugin} other{Showing {count} plugins}}'**
  String pluginsFilterShowing(int count);

  /// No description provided for @pluginsFilterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get pluginsFilterClearAll;

  /// No description provided for @pluginsFilterDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get pluginsFilterDone;

  /// No description provided for @pluginsReposTitle.
  ///
  /// In en, this message translates to:
  /// **'Repositories'**
  String get pluginsReposTitle;

  /// No description provided for @pluginsReposRefreshAll.
  ///
  /// In en, this message translates to:
  /// **'Refresh all'**
  String get pluginsReposRefreshAll;

  /// No description provided for @pluginsRepoPluginCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 plugin} other{{count} plugins}}'**
  String pluginsRepoPluginCount(int count);

  /// No description provided for @pluginsRepoLastError.
  ///
  /// In en, this message translates to:
  /// **'Last load failed: {reason}'**
  String pluginsRepoLastError(String reason);

  /// No description provided for @pluginsRepoRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove repository {name}'**
  String pluginsRepoRemoveTooltip(String name);

  /// No description provided for @pluginsReposEmpty.
  ///
  /// In en, this message translates to:
  /// **'No repository yet.'**
  String get pluginsReposEmpty;

  /// No description provided for @pluginsReposFooter.
  ///
  /// In en, this message translates to:
  /// **'Removing a repository keeps the plugins installed from it, but they no longer get updates.'**
  String get pluginsReposFooter;

  /// No description provided for @pluginsAddDialogUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get pluginsAddDialogUrlLabel;

  /// No description provided for @pluginsAddDialogUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://…/plugins.json'**
  String get pluginsAddDialogUrlHint;

  /// No description provided for @pluginsAddDialogHelper.
  ///
  /// In en, this message translates to:
  /// **'The address of the plugins.json file. Must be https, except for machines on your home network (localhost, 192.168.x…).'**
  String get pluginsAddDialogHelper;

  /// No description provided for @pluginsAddDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get pluginsAddDialogConfirm;

  /// No description provided for @pluginsAddDialogLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get pluginsAddDialogLoading;

  /// No description provided for @pluginsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get pluginsCancel;

  /// No description provided for @pluginsAddedRepo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Added {name} · 1 plugin} other{Added {name} · {count} plugins}}'**
  String pluginsAddedRepo(int count, String name);

  /// No description provided for @pluginsAddErrNeedsHttps.
  ///
  /// In en, this message translates to:
  /// **'Public addresses need https'**
  String get pluginsAddErrNeedsHttps;

  /// No description provided for @pluginsAddErrInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get pluginsAddErrInvalidUrl;

  /// No description provided for @pluginsAddErrDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This repository is already added'**
  String get pluginsAddErrDuplicate;

  /// No description provided for @pluginsAddErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the list: network error'**
  String get pluginsAddErrNetwork;

  /// No description provided for @pluginsAddErrNotFound.
  ///
  /// In en, this message translates to:
  /// **'No plugin list found at this address'**
  String get pluginsAddErrNotFound;

  /// No description provided for @pluginsAddErrBadFormat.
  ///
  /// In en, this message translates to:
  /// **'The file is not a valid plugin list'**
  String get pluginsAddErrBadFormat;

  /// No description provided for @pluginsAddErrBlocked.
  ///
  /// In en, this message translates to:
  /// **'This address is blocked'**
  String get pluginsAddErrBlocked;

  /// No description provided for @pluginsAddErrBlockedReason.
  ///
  /// In en, this message translates to:
  /// **'This address is blocked: {reason}'**
  String pluginsAddErrBlockedReason(String reason);

  /// No description provided for @pluginsAddErrStorage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the repository'**
  String get pluginsAddErrStorage;

  /// No description provided for @pluginsAddressUserInfo.
  ///
  /// In en, this message translates to:
  /// **'the address must not contain a user name or password'**
  String get pluginsAddressUserInfo;

  /// No description provided for @pluginsAddressLocalFromPublic.
  ///
  /// In en, this message translates to:
  /// **'a public repository must not point to a local address'**
  String get pluginsAddressLocalFromPublic;

  /// No description provided for @pluginsAddressRefused.
  ///
  /// In en, this message translates to:
  /// **'this address is not allowed'**
  String get pluginsAddressRefused;

  /// No description provided for @pluginsAddressMixed.
  ///
  /// In en, this message translates to:
  /// **'the domain points to both local and public addresses'**
  String get pluginsAddressMixed;

  /// No description provided for @pluginsAddressLocalNamePublic.
  ///
  /// In en, this message translates to:
  /// **'a local-looking name points to a public address'**
  String get pluginsAddressLocalNamePublic;

  /// No description provided for @pluginsRemoveRepoTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String pluginsRemoveRepoTitle(String name);

  /// No description provided for @pluginsRemoveRepoBody.
  ///
  /// In en, this message translates to:
  /// **'Plugins already installed from this repository are kept, but they will no longer get updates.'**
  String get pluginsRemoveRepoBody;

  /// No description provided for @pluginsRemoveRepoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get pluginsRemoveRepoConfirm;

  /// No description provided for @pluginsRemoveRepoFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove {name}'**
  String pluginsRemoveRepoFailed(String name);

  /// No description provided for @pluginsRootAlertLabel.
  ///
  /// In en, this message translates to:
  /// **'A plugin has a problem or an update needs review'**
  String get pluginsRootAlertLabel;

  /// No description provided for @pluginsPkgClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get pluginsPkgClose;

  /// No description provided for @pluginsPkgLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading and checking the package…'**
  String get pluginsPkgLoading;

  /// No description provided for @pluginsPkgProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} KB · checking plugin.json, file names, hosts, scripts'**
  String pluginsPkgProgress(int done, int total);

  /// No description provided for @pluginsPkgProgressUnknown.
  ///
  /// In en, this message translates to:
  /// **'{done} KB · checking plugin.json, file names, hosts, scripts'**
  String pluginsPkgProgressUnknown(int done);

  /// No description provided for @pluginsPkgChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking plugin.json, file names, hosts, scripts'**
  String get pluginsPkgChecking;

  /// No description provided for @pluginsPkgInstallTitle.
  ///
  /// In en, this message translates to:
  /// **'Install {name}?'**
  String pluginsPkgInstallTitle(String name);

  /// No description provided for @pluginsPkgUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update {name}'**
  String pluginsPkgUpdateTitle(String name);

  /// No description provided for @pluginsPkgInstallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{kind} · version {version} · {author}'**
  String pluginsPkgInstallSubtitle(String kind, int version, String author);

  /// No description provided for @pluginsPkgUpdateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{kind} · {author}'**
  String pluginsPkgUpdateSubtitle(String kind, String author);

  /// No description provided for @pluginsPkgAuthorDeclared.
  ///
  /// In en, this message translates to:
  /// **'{author} (self-declared)'**
  String pluginsPkgAuthorDeclared(String author);

  /// No description provided for @pluginsPkgFromRepo.
  ///
  /// In en, this message translates to:
  /// **'From repository {name}'**
  String pluginsPkgFromRepo(String name);

  /// No description provided for @pluginsPkgFromFile.
  ///
  /// In en, this message translates to:
  /// **'From file {name} · {size}'**
  String pluginsPkgFromFile(String name, String size);

  /// No description provided for @pluginsPkgFromLink.
  ///
  /// In en, this message translates to:
  /// **'From link'**
  String get pluginsPkgFromLink;

  /// No description provided for @pluginsPkgSendTo.
  ///
  /// In en, this message translates to:
  /// **'Sends data to'**
  String get pluginsPkgSendTo;

  /// No description provided for @pluginsPkgWildcard.
  ///
  /// In en, this message translates to:
  /// **'{labels}: only music source plugins may declare this (up to 10).'**
  String pluginsPkgWildcard(String labels);

  /// No description provided for @pluginsPkgWildcardHost.
  ///
  /// In en, this message translates to:
  /// **'Every subdomain of {domain}'**
  String pluginsPkgWildcardHost(String domain);

  /// No description provided for @pluginsPkgUserEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Address you enter in {field}'**
  String pluginsPkgUserEndpoint(String field);

  /// No description provided for @pluginsPkgNoHosts.
  ///
  /// In en, this message translates to:
  /// **'No fixed address.'**
  String get pluginsPkgNoHosts;

  /// No description provided for @pluginsPkgNewBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get pluginsPkgNewBadge;

  /// No description provided for @pluginsPkgConsentInstall.
  ///
  /// In en, this message translates to:
  /// **'Installing a plugin means you agree to let it send data to these addresses. Kanaru does not ask again when the plugin runs.'**
  String get pluginsPkgConsentInstall;

  /// No description provided for @pluginsPkgConsentUpdate.
  ///
  /// In en, this message translates to:
  /// **'Updating means you agree to let the plugin send data to the new addresses too. Kanaru does not ask again when the plugin runs.'**
  String get pluginsPkgConsentUpdate;

  /// No description provided for @pluginsPkgFacts.
  ///
  /// In en, this message translates to:
  /// **'Static facts'**
  String get pluginsPkgFacts;

  /// No description provided for @pluginsPkgFactsUpdate.
  ///
  /// In en, this message translates to:
  /// **'Static facts · compared with the installed version'**
  String get pluginsPkgFactsUpdate;

  /// No description provided for @pluginsPkgAskAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI about this plugin'**
  String get pluginsPkgAskAi;

  /// No description provided for @pluginsPkgAskAiUpdate.
  ///
  /// In en, this message translates to:
  /// **'Ask AI what the new version changes'**
  String get pluginsPkgAskAiUpdate;

  /// No description provided for @pluginsPkgLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get pluginsPkgLater;

  /// No description provided for @pluginsPkgInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get pluginsPkgInstall;

  /// No description provided for @pluginsPkgUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get pluginsPkgUpdate;

  /// No description provided for @pluginsPkgInstalling.
  ///
  /// In en, this message translates to:
  /// **'Installing…'**
  String get pluginsPkgInstalling;

  /// No description provided for @pluginsPkgUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get pluginsPkgUpdating;

  /// No description provided for @pluginsPkgInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed {name}'**
  String pluginsPkgInstalled(String name);

  /// No description provided for @pluginsPkgUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {name} to version {version}'**
  String pluginsPkgUpdated(String name, int version);

  /// No description provided for @pluginsPkgErrDownload.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t download the plugin package: {reason}'**
  String pluginsPkgErrDownload(String reason);

  /// No description provided for @pluginsPkgErrFile.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read the file: {reason}'**
  String pluginsPkgErrFile(String reason);

  /// No description provided for @pluginsPkgNothingNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again. Nothing has been installed.'**
  String get pluginsPkgNothingNetwork;

  /// No description provided for @pluginsPkgNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been installed.'**
  String get pluginsPkgNothing;

  /// No description provided for @pluginsPkgReasonNetwork.
  ///
  /// In en, this message translates to:
  /// **'network error'**
  String get pluginsPkgReasonNetwork;

  /// No description provided for @pluginsPkgReasonTimeout.
  ///
  /// In en, this message translates to:
  /// **'timed out'**
  String get pluginsPkgReasonTimeout;

  /// No description provided for @pluginsPkgReasonStatus.
  ///
  /// In en, this message translates to:
  /// **'the server answered {status}'**
  String pluginsPkgReasonStatus(int status);

  /// No description provided for @pluginsPkgReasonTooLarge.
  ///
  /// In en, this message translates to:
  /// **'the package is too large'**
  String get pluginsPkgReasonTooLarge;

  /// No description provided for @pluginsPkgReasonBlocked.
  ///
  /// In en, this message translates to:
  /// **'the address is blocked'**
  String get pluginsPkgReasonBlocked;

  /// No description provided for @pluginsPkgReasonInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'invalid URL'**
  String get pluginsPkgReasonInvalidUrl;

  /// No description provided for @pluginsPkgReasonCancelled.
  ///
  /// In en, this message translates to:
  /// **'cancelled'**
  String get pluginsPkgReasonCancelled;

  /// No description provided for @pluginsPkgReasonNotZip.
  ///
  /// In en, this message translates to:
  /// **'not a .zip file'**
  String get pluginsPkgReasonNotZip;

  /// No description provided for @pluginsPkgReasonFileLarge.
  ///
  /// In en, this message translates to:
  /// **'the file is too large'**
  String get pluginsPkgReasonFileLarge;

  /// No description provided for @pluginsPkgReasonUnreadable.
  ///
  /// In en, this message translates to:
  /// **'it can’t be read'**
  String get pluginsPkgReasonUnreadable;

  /// No description provided for @pluginsPkgReasonFileSlow.
  ///
  /// In en, this message translates to:
  /// **'the file provider did not answer in time'**
  String get pluginsPkgReasonFileSlow;

  /// No description provided for @pluginsPkgErrGone.
  ///
  /// In en, this message translates to:
  /// **'This plugin is no longer in its repository’s list.'**
  String get pluginsPkgErrGone;

  /// No description provided for @pluginsPkgErrUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while checking the package. Nothing has been installed.'**
  String get pluginsPkgErrUnexpected;

  /// No description provided for @pluginsPkgErrWrite.
  ///
  /// In en, this message translates to:
  /// **'The plugin could not be saved on this device. Nothing has changed.'**
  String get pluginsPkgErrWrite;

  /// No description provided for @pluginsPkgNoticeStale.
  ///
  /// In en, this message translates to:
  /// **'The plugin changed while you were looking. Kanaru checked the package again: review it before installing.'**
  String get pluginsPkgNoticeStale;

  /// No description provided for @pluginsPkgNoticeExpired.
  ///
  /// In en, this message translates to:
  /// **'The package waited too long, so Kanaru checked it again.'**
  String get pluginsPkgNoticeExpired;

  /// No description provided for @pluginsPkgProTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs Kanaru Pro'**
  String get pluginsPkgProTitle;

  /// No description provided for @pluginsPkgFilePickerFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open the file picker.'**
  String get pluginsPkgFilePickerFailed;

  /// No description provided for @pluginsProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'Can’t install'**
  String get pluginsProblemTitle;

  /// No description provided for @pluginsProblemFileBody.
  ///
  /// In en, this message translates to:
  /// **'The file {name} isn’t a valid plugin.'**
  String pluginsProblemFileBody(String name);

  /// No description provided for @pluginsProblemPluginBody.
  ///
  /// In en, this message translates to:
  /// **'{name} can’t be installed.'**
  String pluginsProblemPluginBody(String name);

  /// No description provided for @pluginsProblemReasons.
  ///
  /// In en, this message translates to:
  /// **'Reasons'**
  String get pluginsProblemReasons;

  /// No description provided for @pluginsProblemHostsNote.
  ///
  /// In en, this message translates to:
  /// **'Plugins may only declare public domain names (https).'**
  String get pluginsProblemHostsNote;

  /// No description provided for @pluginsProblemNewerTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs a newer Kanaru'**
  String get pluginsProblemNewerTitle;

  /// No description provided for @pluginsProblemNewerBody.
  ///
  /// In en, this message translates to:
  /// **'{name} uses a newer plugin API than this Kanaru supports. Update Kanaru, then install it again.'**
  String pluginsProblemNewerBody(String name);

  /// No description provided for @pluginsProblemNewerBodyVersion.
  ///
  /// In en, this message translates to:
  /// **'{name} uses a newer plugin API than this Kanaru supports (apiVersion {version}, this version supports up to {max}). Update Kanaru, then install it again.'**
  String pluginsProblemNewerBodyVersion(String name, String version, int max);

  /// No description provided for @pluginsReasonTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The package, or an entry in it, is too large'**
  String get pluginsReasonTooLarge;

  /// No description provided for @pluginsReasonNotZip.
  ///
  /// In en, this message translates to:
  /// **'The file isn’t a readable zip package'**
  String get pluginsReasonNotZip;

  /// No description provided for @pluginsReasonUnsafeEntry.
  ///
  /// In en, this message translates to:
  /// **'The package has an unsafe entry name ({detail})'**
  String pluginsReasonUnsafeEntry(String detail);

  /// No description provided for @pluginsReasonTooManyEntries.
  ///
  /// In en, this message translates to:
  /// **'The package has too many files'**
  String get pluginsReasonTooManyEntries;

  /// No description provided for @pluginsReasonMissingManifest.
  ///
  /// In en, this message translates to:
  /// **'plugin.json not found at the top of the package'**
  String get pluginsReasonMissingManifest;

  /// No description provided for @pluginsReasonInvalidManifest.
  ///
  /// In en, this message translates to:
  /// **'“{detail}” in plugin.json is not valid'**
  String pluginsReasonInvalidManifest(String detail);

  /// No description provided for @pluginsReasonInvalidManifestPlain.
  ///
  /// In en, this message translates to:
  /// **'plugin.json is not valid'**
  String get pluginsReasonInvalidManifestPlain;

  /// No description provided for @pluginsReasonUnknownFormat.
  ///
  /// In en, this message translates to:
  /// **'{detail}: this kind of field is not supported'**
  String pluginsReasonUnknownFormat(String detail);

  /// No description provided for @pluginsReasonNeedsNewerApp.
  ///
  /// In en, this message translates to:
  /// **'Needs a newer Kanaru: the plugin uses a newer plugin API than this version supports'**
  String get pluginsReasonNeedsNewerApp;

  /// No description provided for @pluginsReasonUnsupportedKind.
  ///
  /// In en, this message translates to:
  /// **'plugin.json: type is not a kind of plugin this Kanaru runs'**
  String get pluginsReasonUnsupportedKind;

  /// No description provided for @pluginsReasonBadHost.
  ///
  /// In en, this message translates to:
  /// **'hosts: “{detail}” is not a public domain name'**
  String pluginsReasonBadHost(String detail);

  /// No description provided for @pluginsReasonBadWildcard.
  ///
  /// In en, this message translates to:
  /// **'hosts: “{detail}” is not a valid wildcard: write *. and then a public domain name'**
  String pluginsReasonBadWildcard(String detail);

  /// No description provided for @pluginsReasonWildcardNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'hosts: “{detail}”: only music source plugins may use a wildcard host'**
  String pluginsReasonWildcardNotAllowed(String detail);

  /// No description provided for @pluginsReasonSharedHosting.
  ///
  /// In en, this message translates to:
  /// **'hosts: “{detail}” covers a shared-hosting domain, where anyone can get a subdomain'**
  String pluginsReasonSharedHosting(String detail);

  /// No description provided for @pluginsReasonTooManyWildcards.
  ///
  /// In en, this message translates to:
  /// **'hosts: “{detail}” is over the limit of {max} wildcard hosts'**
  String pluginsReasonTooManyWildcards(String detail, int max);

  /// No description provided for @pluginsReasonMissingScript.
  ///
  /// In en, this message translates to:
  /// **'src/{detail} not found in the package'**
  String pluginsReasonMissingScript(String detail);

  /// No description provided for @pluginsReasonScriptNotUtf8.
  ///
  /// In en, this message translates to:
  /// **'Script {detail} is not valid UTF-8'**
  String pluginsReasonScriptNotUtf8(String detail);

  /// No description provided for @pluginsReasonScriptError.
  ///
  /// In en, this message translates to:
  /// **'Script {detail} has an error'**
  String pluginsReasonScriptError(String detail);

  /// No description provided for @pluginsReasonScriptErrorLine.
  ///
  /// In en, this message translates to:
  /// **'Script {detail} has an error at line {line}'**
  String pluginsReasonScriptErrorLine(String detail, int line);

  /// No description provided for @pluginsReasonCheckUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Kanaru can’t check scripts right now (the plugin runtime did not load), so it can’t tell whether the package is valid'**
  String get pluginsReasonCheckUnavailable;

  /// No description provided for @pluginsReasonSameVersion.
  ///
  /// In en, this message translates to:
  /// **'This package is the same version as the installed one.'**
  String get pluginsReasonSameVersion;

  /// No description provided for @pluginsReasonOlderVersion.
  ///
  /// In en, this message translates to:
  /// **'This package is older than the installed version, so it can’t be used.'**
  String get pluginsReasonOlderVersion;

  /// No description provided for @pluginsReasonKindChange.
  ///
  /// In en, this message translates to:
  /// **'This package is another kind of plugin than the installed one, so it can’t be used. Remove the plugin, then install the new one.'**
  String get pluginsReasonKindChange;

  /// No description provided for @pluginsReasonOtherOrigin.
  ///
  /// In en, this message translates to:
  /// **'This plugin is already installed from {source}. A package from another place can’t replace it: remove the installed plugin, then install again.'**
  String pluginsReasonOtherOrigin(String source);

  /// No description provided for @pluginsOriginRepo.
  ///
  /// In en, this message translates to:
  /// **'repository {url}'**
  String pluginsOriginRepo(String url);

  /// No description provided for @pluginsOriginFile.
  ///
  /// In en, this message translates to:
  /// **'file {name}'**
  String pluginsOriginFile(String name);

  /// No description provided for @pluginsOriginLink.
  ///
  /// In en, this message translates to:
  /// **'a link'**
  String get pluginsOriginLink;

  /// No description provided for @pluginsOriginOther.
  ///
  /// In en, this message translates to:
  /// **'another source'**
  String get pluginsOriginOther;

  /// No description provided for @pluginsMismatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Package doesn’t match the list'**
  String get pluginsMismatchTitle;

  /// No description provided for @pluginsMismatchBody.
  ///
  /// In en, this message translates to:
  /// **'{name} · Repository: {repo}'**
  String pluginsMismatchBody(String name, String repo);

  /// No description provided for @pluginsMismatchDiffs.
  ///
  /// In en, this message translates to:
  /// **'Differences'**
  String get pluginsMismatchDiffs;

  /// No description provided for @pluginsMismatchKind.
  ///
  /// In en, this message translates to:
  /// **'The plugin type of the package differs from the list'**
  String get pluginsMismatchKind;

  /// No description provided for @pluginsMismatchVersion.
  ///
  /// In en, this message translates to:
  /// **'The version of the package differs from the list'**
  String get pluginsMismatchVersion;

  /// No description provided for @pluginsMismatchHosts.
  ///
  /// In en, this message translates to:
  /// **'The hosts of the package differ from the list'**
  String get pluginsMismatchHosts;

  /// No description provided for @pluginsMismatchSha.
  ///
  /// In en, this message translates to:
  /// **'The checksum (sha256) of the package differs from the list'**
  String get pluginsMismatchSha;

  /// No description provided for @pluginsMismatchSize.
  ///
  /// In en, this message translates to:
  /// **'The size of the package differs from the list'**
  String get pluginsMismatchSize;

  /// No description provided for @pluginsMismatchHint.
  ///
  /// In en, this message translates to:
  /// **'This usually happens when the repository was just updated and its cache has not caught up. Refresh the list and try again in a few minutes. If it still differs, tell the repository owner.'**
  String get pluginsMismatchHint;

  /// No description provided for @pluginsMismatchRetry.
  ///
  /// In en, this message translates to:
  /// **'Refresh and try again'**
  String get pluginsMismatchRetry;

  /// No description provided for @pluginsLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Install from link'**
  String get pluginsLinkTitle;

  /// No description provided for @pluginsLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Link to the .zip package'**
  String get pluginsLinkLabel;

  /// No description provided for @pluginsLinkHint.
  ///
  /// In en, this message translates to:
  /// **'https://…/plugin.zip'**
  String get pluginsLinkHint;

  /// No description provided for @pluginsLinkHelper.
  ///
  /// In en, this message translates to:
  /// **'Kanaru downloads the package and checks it, then shows the install screen. Nothing is installed until you tap Install.'**
  String get pluginsLinkHelper;

  /// No description provided for @pluginsLinkHelperCatalog.
  ///
  /// In en, this message translates to:
  /// **'This is a plugin list (plugins.json), not a package. Add it as a repository?'**
  String get pluginsLinkHelperCatalog;

  /// No description provided for @pluginsLinkErrInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get pluginsLinkErrInvalid;

  /// No description provided for @pluginsLinkContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get pluginsLinkContinue;

  /// No description provided for @pluginsLinkAddRepo.
  ///
  /// In en, this message translates to:
  /// **'Add repository'**
  String get pluginsLinkAddRepo;

  /// No description provided for @pluginsUpdateAllRunning.
  ///
  /// In en, this message translates to:
  /// **'Updating {done} / {total}…'**
  String pluginsUpdateAllRunning(int done, int total);

  /// No description provided for @pluginsUpdateFailedLine.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t update: {reason}'**
  String pluginsUpdateFailedLine(String reason);

  /// No description provided for @pluginsUpdateReasonProblems.
  ///
  /// In en, this message translates to:
  /// **'the new package is not valid'**
  String get pluginsUpdateReasonProblems;

  /// No description provided for @pluginsUpdateReasonGone.
  ///
  /// In en, this message translates to:
  /// **'the plugin or its repository is gone'**
  String get pluginsUpdateReasonGone;

  /// No description provided for @pluginsUpdateReasonNoNewer.
  ///
  /// In en, this message translates to:
  /// **'no newer version'**
  String get pluginsUpdateReasonNoNewer;

  /// No description provided for @pluginsUpdateReasonStorage.
  ///
  /// In en, this message translates to:
  /// **'it could not be saved on this device'**
  String get pluginsUpdateReasonStorage;

  /// No description provided for @pluginsUpdateReasonPro.
  ///
  /// In en, this message translates to:
  /// **'needs Kanaru Pro'**
  String get pluginsUpdateReasonPro;

  /// No description provided for @pluginsUpdateReasonOther.
  ///
  /// In en, this message translates to:
  /// **'something went wrong'**
  String get pluginsUpdateReasonOther;

  /// No description provided for @pluginsUpdateNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'The new version of {name} adds hosts or permissions: tap Review.'**
  String pluginsUpdateNeedsReview(String name);

  /// No description provided for @pluginsUpdateAllUpdated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Updated 1 plugin} other{Updated {count} plugins}}'**
  String pluginsUpdateAllUpdated(int count);

  /// No description provided for @pluginsUpdateAllReview.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 version to review (new hosts or permissions): open it} other{{count} versions to review (new hosts or permissions): open each one}}'**
  String pluginsUpdateAllReview(int count);

  /// No description provided for @pluginsUpdateAllFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 could not be updated} other{{count} could not be updated}}'**
  String pluginsUpdateAllFailed(int count);

  /// No description provided for @pluginsRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String pluginsRemoveTitle(String name);

  /// No description provided for @pluginsRemoveBy.
  ///
  /// In en, this message translates to:
  /// **'{author} · version {version}'**
  String pluginsRemoveBy(String author, int version);

  /// No description provided for @pluginsRemoveWillDelete.
  ///
  /// In en, this message translates to:
  /// **'Will be removed'**
  String get pluginsRemoveWillDelete;

  /// No description provided for @pluginsRemoveCode.
  ///
  /// In en, this message translates to:
  /// **'The plugin’s code'**
  String get pluginsRemoveCode;

  /// No description provided for @pluginsRemoveSettings.
  ///
  /// In en, this message translates to:
  /// **'The plugin’s settings'**
  String get pluginsRemoveSettings;

  /// No description provided for @pluginsRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get pluginsRemoveConfirm;

  /// No description provided for @pluginsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {name}'**
  String pluginsRemoved(String name);

  /// No description provided for @pluginsRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t remove {name}'**
  String pluginsRemoveFailed(String name);

  /// No description provided for @pluginsPkgLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Install plugin'**
  String get pluginsPkgLoadingTitle;

  /// No description provided for @pluginsUpdatedNoVersion.
  ///
  /// In en, this message translates to:
  /// **'Updated {name}'**
  String pluginsUpdatedNoVersion(String name);

  /// No description provided for @pluginsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Plugin details'**
  String get pluginsPageTitle;

  /// No description provided for @pluginsPageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read the plugin list'**
  String get pluginsPageLoadFailed;

  /// No description provided for @pluginsPageGone.
  ///
  /// In en, this message translates to:
  /// **'This plugin is no longer installed.'**
  String get pluginsPageGone;

  /// No description provided for @pluginsPageToStore.
  ///
  /// In en, this message translates to:
  /// **'Back to the plugin store'**
  String get pluginsPageToStore;

  /// No description provided for @pluginsPageByline.
  ///
  /// In en, this message translates to:
  /// **'{author} · version {version}'**
  String pluginsPageByline(String author, int version);

  /// No description provided for @pluginsPageUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'New version {version}'**
  String pluginsPageUpdateTitle(int version);

  /// No description provided for @pluginsPageUpdateBusy.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get pluginsPageUpdateBusy;

  /// No description provided for @pluginsPageReviewBody.
  ///
  /// In en, this message translates to:
  /// **'The new version also connects to {hosts}: look before you update.'**
  String pluginsPageReviewBody(String hosts);

  /// No description provided for @pluginsPageReviewBodyAny.
  ///
  /// In en, this message translates to:
  /// **'The new version adds hosts or permissions: look before you update.'**
  String get pluginsPageReviewBodyAny;

  /// No description provided for @pluginsPageReviewButton.
  ///
  /// In en, this message translates to:
  /// **'See the update'**
  String get pluginsPageReviewButton;

  /// No description provided for @pluginsPageRefreshList.
  ///
  /// In en, this message translates to:
  /// **'Refresh the list'**
  String get pluginsPageRefreshList;

  /// No description provided for @pluginsPageNeedsConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} needs to be set up'**
  String pluginsPageNeedsConfigTitle(String name);

  /// No description provided for @pluginsPageNeedsConfigBody.
  ///
  /// In en, this message translates to:
  /// **'The plugin can’t run until it has: {fields}.'**
  String pluginsPageNeedsConfigBody(String fields);

  /// No description provided for @pluginsPageOpenConfig.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get pluginsPageOpenConfig;

  /// No description provided for @pluginsPageBrokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read the plugin’s package'**
  String get pluginsPageBrokenTitle;

  /// No description provided for @pluginsPageBrokenBody.
  ///
  /// In en, this message translates to:
  /// **'The plugin’s folder is missing or damaged, so it doesn’t run. Reinstalling keeps its settings and data.'**
  String get pluginsPageBrokenBody;

  /// No description provided for @pluginsPageBrokenBodyFile.
  ///
  /// In en, this message translates to:
  /// **'The plugin’s folder is missing or damaged, so it doesn’t run. This plugin was installed from a file: remove it and install the file again.'**
  String get pluginsPageBrokenBodyFile;

  /// No description provided for @pluginsPageReinstall.
  ///
  /// In en, this message translates to:
  /// **'Reinstall'**
  String get pluginsPageReinstall;

  /// No description provided for @pluginsPageReinstalled.
  ///
  /// In en, this message translates to:
  /// **'Reinstalled {name}'**
  String pluginsPageReinstalled(String name);

  /// No description provided for @pluginsPageReinstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reinstall: {reason}'**
  String pluginsPageReinstallFailed(String reason);

  /// No description provided for @pluginsPageDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get pluginsPageDetails;

  /// No description provided for @pluginsPageFrom.
  ///
  /// In en, this message translates to:
  /// **'Installed from'**
  String get pluginsPageFrom;

  /// No description provided for @pluginsPageFromRepo.
  ///
  /// In en, this message translates to:
  /// **'Repo: {name}'**
  String pluginsPageFromRepo(String name);

  /// No description provided for @pluginsPageFromFile.
  ///
  /// In en, this message translates to:
  /// **'File: {name}'**
  String pluginsPageFromFile(String name);

  /// No description provided for @pluginsPageFromLink.
  ///
  /// In en, this message translates to:
  /// **'Link: {name}'**
  String pluginsPageFromLink(String name);

  /// No description provided for @pluginsPageNoUpdatesFile.
  ///
  /// In en, this message translates to:
  /// **'This plugin was installed from a file, so it gets no updates. Remove it and install the new file.'**
  String get pluginsPageNoUpdatesFile;

  /// No description provided for @pluginsPageNoUpdatesLink.
  ///
  /// In en, this message translates to:
  /// **'This plugin was installed from a link, so it gets no updates. Remove it and install the new version.'**
  String get pluginsPageNoUpdatesLink;

  /// No description provided for @pluginsPageWildcardLine.
  ///
  /// In en, this message translates to:
  /// **'{label} ({host})'**
  String pluginsPageWildcardLine(String label, String host);

  /// No description provided for @pluginsPageNotEntered.
  ///
  /// In en, this message translates to:
  /// **'(not entered)'**
  String get pluginsPageNotEntered;

  /// No description provided for @pluginsPageEndpointLine.
  ///
  /// In en, this message translates to:
  /// **'Address you enter in {field}: {hosts}'**
  String pluginsPageEndpointLine(String field, String hosts);

  /// No description provided for @pluginsPageInstalledAt.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get pluginsPageInstalledAt;

  /// No description provided for @pluginsPageInstalledDates.
  ///
  /// In en, this message translates to:
  /// **'{installed} · updated {updated}'**
  String pluginsPageInstalledDates(String installed, String updated);

  /// No description provided for @pluginsPageDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get pluginsPageDescription;

  /// No description provided for @pluginsPageType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get pluginsPageType;

  /// No description provided for @pluginsPageTypeValue.
  ///
  /// In en, this message translates to:
  /// **'{kind} · plugin API {api}'**
  String pluginsPageTypeValue(String kind, int api);

  /// No description provided for @pluginsPageTypeValueAi.
  ///
  /// In en, this message translates to:
  /// **'{kind} · AI · plugin API {api}'**
  String pluginsPageTypeValueAi(String kind, int api);

  /// No description provided for @pluginsPageSourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get pluginsPageSourceCode;

  /// No description provided for @pluginsPageUseLyrics.
  ///
  /// In en, this message translates to:
  /// **'Find lyrics automatically'**
  String get pluginsPageUseLyrics;

  /// No description provided for @pluginsPageUseTranslate.
  ///
  /// In en, this message translates to:
  /// **'Default translation service'**
  String get pluginsPageUseTranslate;

  /// No description provided for @pluginsPageUseTranslateAt.
  ///
  /// In en, this message translates to:
  /// **'Change in Settings › Lyrics › Translation'**
  String get pluginsPageUseTranslateAt;

  /// No description provided for @pluginsPageUseTranslateHint.
  ///
  /// In en, this message translates to:
  /// **'Songs with no service of their own use the default service.'**
  String get pluginsPageUseTranslateHint;

  /// No description provided for @pluginsPageUseTranslateIs.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get pluginsPageUseTranslateIs;

  /// No description provided for @pluginsPageUseTranslateSet.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get pluginsPageUseTranslateSet;

  /// No description provided for @pluginsRemoveKeepTranslations.
  ///
  /// In en, this message translates to:
  /// **'Saved translations, until you choose “Delete saved translations”'**
  String get pluginsRemoveKeepTranslations;

  /// No description provided for @pluginsPageConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get pluginsPageConnection;

  /// No description provided for @pluginsPageData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get pluginsPageData;

  /// No description provided for @pluginsPageOwnStorage.
  ///
  /// In en, this message translates to:
  /// **'Plugin’s own storage'**
  String get pluginsPageOwnStorage;

  /// No description provided for @pluginsPageSavedLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics saved from this source'**
  String get pluginsPageSavedLyrics;

  /// No description provided for @pluginsPageTrackCache.
  ///
  /// In en, this message translates to:
  /// **'Track and cover cache'**
  String get pluginsPageTrackCache;

  /// No description provided for @pluginsPageLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get pluginsPageLog;

  /// No description provided for @pluginsPageOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get pluginsPageOpen;

  /// No description provided for @pluginsPageBadgeAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get pluginsPageBadgeAi;

  /// No description provided for @pluginsRepoAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Repository address copied'**
  String get pluginsRepoAddressCopied;

  /// No description provided for @pluginsRepoCopyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get pluginsRepoCopyAddress;

  /// No description provided for @pluginsCfgReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read the plugin’s settings'**
  String get pluginsCfgReadFailed;

  /// No description provided for @pluginsCfgRequired.
  ///
  /// In en, this message translates to:
  /// **'This setting is required'**
  String get pluginsCfgRequired;

  /// No description provided for @pluginsCfgNotNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get pluginsCfgNotNumber;

  /// No description provided for @pluginsCfgNotInteger.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number'**
  String get pluginsCfgNotInteger;

  /// No description provided for @pluginsCfgMin.
  ///
  /// In en, this message translates to:
  /// **'Must be {min} or more'**
  String pluginsCfgMin(String min);

  /// No description provided for @pluginsCfgMax.
  ///
  /// In en, this message translates to:
  /// **'Must be {max} or less'**
  String pluginsCfgMax(String max);

  /// No description provided for @pluginsCfgMinLength.
  ///
  /// In en, this message translates to:
  /// **'Enter at least {n} characters'**
  String pluginsCfgMinLength(String n);

  /// No description provided for @pluginsCfgMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Enter at most {n} characters'**
  String pluginsCfgMaxLength(String n);

  /// No description provided for @pluginsCfgBadUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter an https address'**
  String get pluginsCfgBadUrl;

  /// No description provided for @pluginsCfgTooFew.
  ///
  /// In en, this message translates to:
  /// **'Choose or add at least {n} items'**
  String pluginsCfgTooFew(String n);

  /// No description provided for @pluginsCfgTooMany.
  ///
  /// In en, this message translates to:
  /// **'At most {n} items'**
  String pluginsCfgTooMany(String n);

  /// No description provided for @pluginsCfgBadItem.
  ///
  /// In en, this message translates to:
  /// **'One of the items is not valid'**
  String get pluginsCfgBadItem;

  /// No description provided for @pluginsCfgBadName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name of 1 to 100 characters with no space at either end'**
  String get pluginsCfgBadName;

  /// No description provided for @pluginsCfgDuplicateName.
  ///
  /// In en, this message translates to:
  /// **'Another row already uses this name'**
  String get pluginsCfgDuplicateName;

  /// No description provided for @pluginsCfgRefusedValue.
  ///
  /// In en, this message translates to:
  /// **'This setting doesn’t accept that value.'**
  String get pluginsCfgRefusedValue;

  /// No description provided for @pluginsCfgRefusedTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The plugin’s settings are too large to save.'**
  String get pluginsCfgRefusedTooLarge;

  /// No description provided for @pluginsCfgRefusedGone.
  ///
  /// In en, this message translates to:
  /// **'This setting no longer exists. The plugin may have been removed or changed.'**
  String get pluginsCfgRefusedGone;

  /// No description provided for @pluginsCfgRefusedOther.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save the setting (try again later)'**
  String get pluginsCfgRefusedOther;

  /// No description provided for @pluginsCfgNotChosen.
  ///
  /// In en, this message translates to:
  /// **'Not chosen'**
  String get pluginsCfgNotChosen;

  /// No description provided for @pluginsCfgNoModel.
  ///
  /// In en, this message translates to:
  /// **'No model'**
  String get pluginsCfgNoModel;

  /// No description provided for @pluginsCfgOwnTag.
  ///
  /// In en, this message translates to:
  /// **'Added by you'**
  String get pluginsCfgOwnTag;

  /// No description provided for @pluginsCfgRemoveModel.
  ///
  /// In en, this message translates to:
  /// **'Remove this model'**
  String get pluginsCfgRemoveModel;

  /// No description provided for @pluginsCfgAddModel.
  ///
  /// In en, this message translates to:
  /// **'Add model…'**
  String get pluginsCfgAddModel;

  /// No description provided for @pluginsCfgAddModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Add model'**
  String get pluginsCfgAddModelTitle;

  /// No description provided for @pluginsCfgModelNameHint.
  ///
  /// In en, this message translates to:
  /// **'Model name, exactly as the server expects it'**
  String get pluginsCfgModelNameHint;

  /// No description provided for @pluginsCfgModelNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Note (optional), for example: Ollama at home'**
  String get pluginsCfgModelNoteHint;

  /// No description provided for @pluginsCfgAddAndChoose.
  ///
  /// In en, this message translates to:
  /// **'Add and choose'**
  String get pluginsCfgAddAndChoose;

  /// No description provided for @pluginsCfgMaxChosen.
  ///
  /// In en, this message translates to:
  /// **'At most {n}'**
  String pluginsCfgMaxChosen(String n);

  /// No description provided for @pluginsCfgAddRow.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get pluginsCfgAddRow;

  /// No description provided for @pluginsCfgRemoveRow.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get pluginsCfgRemoveRow;

  /// No description provided for @pluginsCfgNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get pluginsCfgNameLabel;

  /// No description provided for @pluginsCfgValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get pluginsCfgValueLabel;

  /// No description provided for @pluginsCfgStepDown.
  ///
  /// In en, this message translates to:
  /// **'Decrease by {step}'**
  String pluginsCfgStepDown(String step);

  /// No description provided for @pluginsCfgStepUp.
  ///
  /// In en, this message translates to:
  /// **'Increase by {step}'**
  String pluginsCfgStepUp(String step);

  /// No description provided for @pluginsPageUseLyricsOn.
  ///
  /// In en, this message translates to:
  /// **'In use · {position} of {total} · change in Settings › Lyrics › Sources'**
  String pluginsPageUseLyricsOn(int position, int total);

  /// No description provided for @pluginsPageUseLyricsOff.
  ///
  /// In en, this message translates to:
  /// **'Off: searches only when you tap “Find lyrics online…” · change in Settings › Lyrics › Sources'**
  String get pluginsPageUseLyricsOff;

  /// No description provided for @pluginsDataStorageValue.
  ///
  /// In en, this message translates to:
  /// **'{used} KB / {quota} KB'**
  String pluginsDataStorageValue(int used, int quota);

  /// No description provided for @pluginsDataClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get pluginsDataClear;

  /// No description provided for @pluginsDataClearStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear the plugin’s own storage?'**
  String get pluginsDataClearStorageTitle;

  /// No description provided for @pluginsDataClearStorageBody.
  ///
  /// In en, this message translates to:
  /// **'The plugin may need to sign in or be set up again.'**
  String get pluginsDataClearStorageBody;

  /// No description provided for @pluginsDataStorageCleared.
  ///
  /// In en, this message translates to:
  /// **'Own storage cleared'**
  String get pluginsDataStorageCleared;

  /// No description provided for @pluginsDataSavedLyricsValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}} · {size}'**
  String pluginsDataSavedLyricsValue(int count, String size);

  /// No description provided for @pluginsDataSavedLyricsNone.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get pluginsDataSavedLyricsNone;

  /// No description provided for @pluginsDataClearLyricsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear the lyrics saved from this source?'**
  String get pluginsDataClearLyricsTitle;

  /// No description provided for @pluginsDataClearLyricsBody.
  ///
  /// In en, this message translates to:
  /// **'Lyrics saved from this source will be deleted. Pinned lyrics and .lrc files are kept.'**
  String get pluginsDataClearLyricsBody;

  /// No description provided for @pluginsDataLyricsCleared.
  ///
  /// In en, this message translates to:
  /// **'Saved lyrics cleared'**
  String get pluginsDataLyricsCleared;

  /// No description provided for @pluginsDataClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t clear the data'**
  String get pluginsDataClearFailed;

  /// No description provided for @pluginsDataLogSummary.
  ///
  /// In en, this message translates to:
  /// **'{errors, plural, =1{1 error today} other{{errors} errors today}} · {total, plural, =1{1 entry} other{{total} entries}}'**
  String pluginsDataLogSummary(int errors, int total);

  /// No description provided for @pluginsDataLogNoErrors.
  ///
  /// In en, this message translates to:
  /// **'No errors'**
  String get pluginsDataLogNoErrors;

  /// No description provided for @pluginsPausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Paused for {minutes, plural, =1{1 minute} other{{minutes} minutes}}: the server says too many requests (429)'**
  String pluginsPausedTitle(int minutes);

  /// No description provided for @pluginsPausedBody.
  ///
  /// In en, this message translates to:
  /// **'Kanaru asks this source again after {time}. Other sources still search as usual.'**
  String pluginsPausedBody(String time);

  /// No description provided for @pluginsLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get pluginsLogsTitle;

  /// No description provided for @pluginsLogsFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter the log'**
  String get pluginsLogsFilterLabel;

  /// No description provided for @pluginsLogsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get pluginsLogsAll;

  /// No description provided for @pluginsLogsErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get pluginsLogsErrors;

  /// No description provided for @pluginsLogsCaption.
  ///
  /// In en, this message translates to:
  /// **'Every time the plugin fails or writes to the console. Kanaru hides the settings values, own storage and tokens it knows of. A plugin can still write other information: look before you share.'**
  String get pluginsLogsCaption;

  /// No description provided for @pluginsLogsFooter.
  ///
  /// In en, this message translates to:
  /// **'Kept for the last 7 days (at most 1 MB per plugin). File: {path}'**
  String pluginsLogsFooter(String path);

  /// No description provided for @pluginsLogsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get pluginsLogsEmpty;

  /// No description provided for @pluginsLogsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read the log'**
  String get pluginsLogsLoadFailed;

  /// No description provided for @pluginsLogsOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Open the log folder'**
  String get pluginsLogsOpenFolder;

  /// No description provided for @pluginsLogsOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open the log folder'**
  String get pluginsLogsOpenFailed;

  /// No description provided for @pluginsLogsShareSoon.
  ///
  /// In en, this message translates to:
  /// **'Share · {soon}'**
  String pluginsLogsShareSoon(String soon);

  /// No description provided for @pluginsLogsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear the log'**
  String get pluginsLogsClear;

  /// No description provided for @pluginsLogsClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear the plugin’s log?'**
  String get pluginsLogsClearTitle;

  /// No description provided for @pluginsLogsClearBody.
  ///
  /// In en, this message translates to:
  /// **'The log entries of {name} will be deleted. The plugin is not affected.'**
  String pluginsLogsClearBody(String name);

  /// No description provided for @pluginsLogsCleared.
  ///
  /// In en, this message translates to:
  /// **'Log cleared'**
  String get pluginsLogsCleared;

  /// No description provided for @pluginsLogsJobTarget.
  ///
  /// In en, this message translates to:
  /// **'{job} · {target}'**
  String pluginsLogsJobTarget(String job, String target);

  /// No description provided for @pluginsLogsResultOk.
  ///
  /// In en, this message translates to:
  /// **'Console output only'**
  String get pluginsLogsResultOk;

  /// No description provided for @pluginsLogsResultError.
  ///
  /// In en, this message translates to:
  /// **'Error: {reason}'**
  String pluginsLogsResultError(String reason);

  /// No description provided for @pluginsLogsResultErrorWith.
  ///
  /// In en, this message translates to:
  /// **'Error: {reason} · {message}'**
  String pluginsLogsResultErrorWith(String reason, String message);

  /// No description provided for @pluginsLogsKindRateLimited.
  ///
  /// In en, this message translates to:
  /// **'too many requests (429)'**
  String get pluginsLogsKindRateLimited;

  /// No description provided for @pluginsLogsKindInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'invalid response'**
  String get pluginsLogsKindInvalidResponse;

  /// No description provided for @pluginsLogsKindServer.
  ///
  /// In en, this message translates to:
  /// **'server error'**
  String get pluginsLogsKindServer;

  /// No description provided for @pluginsLogsKindAuth.
  ///
  /// In en, this message translates to:
  /// **'sign-in needed or wrong key'**
  String get pluginsLogsKindAuth;

  /// No description provided for @pluginsLogsKindQuota.
  ///
  /// In en, this message translates to:
  /// **'quota used up'**
  String get pluginsLogsKindQuota;

  /// No description provided for @pluginsLogsKindTimeout.
  ///
  /// In en, this message translates to:
  /// **'timed out'**
  String get pluginsLogsKindTimeout;

  /// No description provided for @pluginsLogsKindMemory.
  ///
  /// In en, this message translates to:
  /// **'out of memory'**
  String get pluginsLogsKindMemory;

  /// No description provided for @pluginsLogsKindStack.
  ///
  /// In en, this message translates to:
  /// **'code nested too deep'**
  String get pluginsLogsKindStack;

  /// No description provided for @pluginsLogsKindOutputTooLarge.
  ///
  /// In en, this message translates to:
  /// **'result too large'**
  String get pluginsLogsKindOutputTooLarge;

  /// No description provided for @pluginsLogsKindInternal.
  ///
  /// In en, this message translates to:
  /// **'internal error'**
  String get pluginsLogsKindInternal;

  /// No description provided for @pluginsLogsKindNetwork.
  ///
  /// In en, this message translates to:
  /// **'network error'**
  String get pluginsLogsKindNetwork;

  /// No description provided for @pluginsLogsKindUnavailable.
  ///
  /// In en, this message translates to:
  /// **'no longer on the source'**
  String get pluginsLogsKindUnavailable;

  /// No description provided for @pluginsLogsKindUnsupported.
  ///
  /// In en, this message translates to:
  /// **'not supported'**
  String get pluginsLogsKindUnsupported;

  /// No description provided for @pluginsLogsKindOther.
  ///
  /// In en, this message translates to:
  /// **'{kind}'**
  String pluginsLogsKindOther(String kind);

  /// No description provided for @pluginsRemoveStorage.
  ///
  /// In en, this message translates to:
  /// **'Own storage ({size} KB)'**
  String pluginsRemoveStorage(int size);

  /// No description provided for @pluginsRemoveLog.
  ///
  /// In en, this message translates to:
  /// **'The plugin’s log'**
  String get pluginsRemoveLog;

  /// No description provided for @pluginsRemoveKeepLyrics.
  ///
  /// In en, this message translates to:
  /// **'Saved lyrics of {count, plural, =1{1 song} other{{count} songs}} and pinned lyrics from this source'**
  String pluginsRemoveKeepLyrics(int count);

  /// No description provided for @pluginsRemoveKeepPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned lyrics from this source (if any)'**
  String get pluginsRemoveKeepPinned;

  /// No description provided for @pluginsRemoveKeepLrc.
  ///
  /// In en, this message translates to:
  /// **'The .lrc files written next to songs'**
  String get pluginsRemoveKeepLrc;

  /// No description provided for @pluginsRemoveKeep.
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get pluginsRemoveKeep;

  /// No description provided for @pluginsPageConnectionRow.
  ///
  /// In en, this message translates to:
  /// **'Requests at once, spacing'**
  String get pluginsPageConnectionRow;

  /// Title of the block of fonts shipped with the app.
  ///
  /// In en, this message translates to:
  /// **'Built in'**
  String get fontsBuiltInTitle;

  /// Note about the whole Built in block, shown behind the info icon.
  ///
  /// In en, this message translates to:
  /// **'Chinese, Korean and Japanese characters and emoji always use the system font.'**
  String get fontsBuiltInHint;

  /// Soft suffix after the name of the default font.
  ///
  /// In en, this message translates to:
  /// **' · default'**
  String get fontsDefaultSuffix;

  /// Name of the font entry that follows the operating system font.
  ///
  /// In en, this message translates to:
  /// **'System font'**
  String get fontsSystemFont;

  /// Snack bar after the font was switched.
  ///
  /// In en, this message translates to:
  /// **'Font changed'**
  String get fontsChanged;

  /// Snack bar when a chosen font could not be loaded; the old font stays.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t use the font {name}.'**
  String fontsUseFailed(String name);

  /// Title of the block of fonts that can be downloaded.
  ///
  /// In en, this message translates to:
  /// **'Online fonts'**
  String get fontsCatalogTitle;

  /// Note about the whole online fonts block, shown behind the info icon.
  ///
  /// In en, this message translates to:
  /// **'Download once, then use without a connection.'**
  String get fontsCatalogHint;

  /// Label of the button that downloads a font.
  ///
  /// In en, this message translates to:
  /// **'Download {name}'**
  String fontsDownloadTooltip(String name);

  /// Label of the button that deletes a downloaded font.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String fontsDeleteTooltip(String name);

  /// Snack bar after a font finished downloading; it is not applied.
  ///
  /// In en, this message translates to:
  /// **'Font downloaded'**
  String get fontsDownloaded;

  /// Snack bar after a downloaded font was deleted.
  ///
  /// In en, this message translates to:
  /// **'Font deleted (you can download it again)'**
  String get fontsDeleted;

  /// Snack bar when a font download failed; nothing was installed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download the font {name}. Check your connection and try again.'**
  String fontsDownloadFailed(String name);

  /// Title of the block of fonts the user imported.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get fontsCustomTitle;

  /// Note about the whole custom fonts block, shown behind the info icon.
  ///
  /// In en, this message translates to:
  /// **'Fonts you import from a .ttf or .otf file.'**
  String get fontsCustomHint;

  /// Row that starts importing a font (mobile).
  ///
  /// In en, this message translates to:
  /// **'Import font'**
  String get fontsImportRow;

  /// Row that starts importing a font (desktop, opens a file dialog).
  ///
  /// In en, this message translates to:
  /// **'Import font…'**
  String get fontsImportRowDialog;

  /// Title of the dialog before the file picker.
  ///
  /// In en, this message translates to:
  /// **'Import font'**
  String get fontsImportTitle;

  /// Body of the import dialog.
  ///
  /// In en, this message translates to:
  /// **'Only import fonts you have the right to use. Kanaru copies the .ttf / .otf file into the app\'s data folder.'**
  String get fontsImportBody;

  /// Button of the import dialog that opens the file picker.
  ///
  /// In en, this message translates to:
  /// **'Choose file…'**
  String get fontsImportPick;

  /// Snack bar after a font was imported; it is not applied.
  ///
  /// In en, this message translates to:
  /// **'Imported “{name}” · tap to use'**
  String fontsImported(String name);

  /// Snack bar when the picked font file is over the size limit.
  ///
  /// In en, this message translates to:
  /// **'The font file is too large (20 MB at most).'**
  String get fontsImportTooLarge;

  /// Snack bar when the picked file is not a usable font or cannot be read.
  ///
  /// In en, this message translates to:
  /// **'This file is not a .ttf or .otf font.'**
  String get fontsImportInvalid;

  /// Name of the file type in the system dialog that picks a font.
  ///
  /// In en, this message translates to:
  /// **'Fonts'**
  String get fontsImportFileTypes;

  /// Screen-reader label of the progress spinner on a font that is downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading {name}'**
  String fontsDownloading(String name);

  /// Title of the confirmation before deleting an imported font.
  ///
  /// In en, this message translates to:
  /// **'Delete the font “{name}”?'**
  String fontsRemoveTitle(String name);

  /// Body of the delete confirmation.
  ///
  /// In en, this message translates to:
  /// **'The imported font file is deleted from Kanaru. To use it again you have to import it again.'**
  String get fontsRemoveBody;

  /// Destructive button of the delete confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get fontsRemoveConfirm;

  /// Snack bar after an imported font was deleted.
  ///
  /// In en, this message translates to:
  /// **'Font deleted'**
  String get fontsRemoved;

  /// Name of the play context when the AI assistant starts a queue.
  ///
  /// In en, this message translates to:
  /// **'AI assistant'**
  String get aiChatPlayContextLabel;

  /// Title of a conversation that has no name yet, and the menu row that starts one.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get aiChatNewTitle;

  /// Tooltip of the ⋮ button of the chat header.
  ///
  /// In en, this message translates to:
  /// **'Chat options'**
  String get aiChatMenuTooltip;

  /// Menu row that opens the list of past conversations.
  ///
  /// In en, this message translates to:
  /// **'Chat history'**
  String get aiChatMenuHistory;

  /// Menu row that renames the open conversation; also the tooltip of its title.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get aiChatMenuRename;

  /// Menu row that deletes the open conversation.
  ///
  /// In en, this message translates to:
  /// **'Delete this conversation'**
  String get aiChatMenuDelete;

  /// Menu row that opens the AI settings page.
  ///
  /// In en, this message translates to:
  /// **'AI settings'**
  String get aiChatMenuSettings;

  /// Label of the name field while renaming.
  ///
  /// In en, this message translates to:
  /// **'Conversation name'**
  String get aiChatRenameField;

  /// Tooltip of the button that saves the new name.
  ///
  /// In en, this message translates to:
  /// **'Save name'**
  String get aiChatRenameSave;

  /// Tooltip of the button that closes the chat page on the phone.
  ///
  /// In en, this message translates to:
  /// **'Close chat'**
  String get aiChatCloseMobile;

  /// Tooltip of the button that closes the chat panel on desktop.
  ///
  /// In en, this message translates to:
  /// **'Close panel (Ctrl+J)'**
  String get aiChatClosePanel;

  /// Title of the confirm dialog before a conversation is deleted.
  ///
  /// In en, this message translates to:
  /// **'Delete this conversation?'**
  String get aiChatDeleteTitle;

  /// Body of the confirm dialog before a conversation is deleted.
  ///
  /// In en, this message translates to:
  /// **'Its messages and attached images are removed from this device. This cannot be undone.'**
  String get aiChatDeleteBody;

  /// Confirm button of the delete dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get aiChatDeleteConfirm;

  /// Toast shown after a conversation was deleted.
  ///
  /// In en, this message translates to:
  /// **'Conversation deleted'**
  String get aiChatDeleted;

  /// Greeting of an empty conversation.
  ///
  /// In en, this message translates to:
  /// **'What do you want to ask about your music?'**
  String get aiChatEmptyTitle;

  /// Line under the greeting of an empty conversation.
  ///
  /// In en, this message translates to:
  /// **'The AI can read your library, the playing song, lyrics and the queue through the tools you turn on in Settings.'**
  String get aiChatEmptyBody;

  /// Heading shown when no AI chat plugin is installed.
  ///
  /// In en, this message translates to:
  /// **'Choose an AI service'**
  String get aiChatGuideTitle;

  /// Line under the heading shown when no AI chat plugin is installed.
  ///
  /// In en, this message translates to:
  /// **'Kanaru has no AI server of its own. You use your own service; data goes straight to it.'**
  String get aiChatGuideBody;

  /// Title of the cloud option of the no-plugin guide.
  ///
  /// In en, this message translates to:
  /// **'Cloud service'**
  String get aiChatGuideCloudTitle;

  /// Description of the cloud option of the no-plugin guide.
  ///
  /// In en, this message translates to:
  /// **'Claude, Gemini, OpenAI… Install a plugin, then enter your API key (kept in the plugin\'s settings).'**
  String get aiChatGuideCloudBody;

  /// Button that opens the plugin store on the AI chat plugins.
  ///
  /// In en, this message translates to:
  /// **'Open the AI plugin store'**
  String get aiChatGuideCloudAction;

  /// Consent line at the foot of the no-plugin guide.
  ///
  /// In en, this message translates to:
  /// **'Installing a plugin lets it send data to the addresses it declares. The chat does not ask again.'**
  String get aiChatGuideFoot;

  /// Tooltip of the copy button under a message.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get aiChatCopy;

  /// Line under an answer that was stopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get aiChatStopped;

  /// Screen-reader status of the three dots shown while an answer streams.
  ///
  /// In en, this message translates to:
  /// **'Answering'**
  String get aiChatAnswering;

  /// Title of a tool card while the tool runs. {name} is the tool's name.
  ///
  /// In en, this message translates to:
  /// **'Running: {name}'**
  String aiChatToolRunning(String name);

  /// Heading of the arguments in an open tool card.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get aiChatToolParams;

  /// Heading of the result in an open tool card.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get aiChatToolResult;

  /// Divider written when the conversation moves to another plugin and model.
  ///
  /// In en, this message translates to:
  /// **'From here on: {plugin} · {model}'**
  String aiChatPluginSwitch(String plugin, String model);

  /// Divider written when the conversation moves to another plugin and no model is known.
  ///
  /// In en, this message translates to:
  /// **'From here on: {plugin}'**
  String aiChatPluginSwitchNoModel(String plugin);

  /// Tooltip of the round button that scrolls the chat to the newest message.
  ///
  /// In en, this message translates to:
  /// **'Jump to the end'**
  String get aiChatJumpToEnd;

  /// Notice shown in place of the messages when reading them failed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this conversation.'**
  String get aiChatMessagesError;

  /// Action of the notice shown when the messages could not be read.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get aiChatMessagesRetry;

  /// Tooltip of the ⋮ button of a song row in an answer.
  ///
  /// In en, this message translates to:
  /// **'Song menu'**
  String get aiChatTrackMenu;

  /// Name of the play_tracks tool on a tool card.
  ///
  /// In en, this message translates to:
  /// **'Play songs'**
  String get aiChatToolPlayTracks;

  /// Name of the queue_tracks tool on a tool card.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get aiChatToolQueueTracks;

  /// Name of the remove_from_queue tool on a tool card.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get aiChatToolRemoveFromQueue;

  /// Name of the list_playlists tool on a tool card.
  ///
  /// In en, this message translates to:
  /// **'List playlists'**
  String get aiChatToolListPlaylists;

  /// Name of the get_playlist_tracks tool on a tool card.
  ///
  /// In en, this message translates to:
  /// **'Playlist songs'**
  String get aiChatToolGetPlaylistTracks;

  /// Name of the get_lyrics tool on a tool card.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get aiChatToolGetLyrics;

  /// Name of the get_listening_stats tool on a tool card.
  ///
  /// In en, this message translates to:
  /// **'Listening stats'**
  String get aiChatToolGetListeningStats;

  /// Name of the create_playlist tool on a tool card.
  ///
  /// In en, this message translates to:
  /// **'Create playlist'**
  String get aiChatToolCreatePlaylist;

  /// Name of the add_to_playlist tool on a tool card.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get aiChatToolAddToPlaylist;

  /// Name of the remove_from_playlist tool on a tool card.
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist'**
  String get aiChatToolRemoveFromPlaylist;

  /// Name of the get_now_playing tool on a tool card.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get aiChatToolGetNowPlaying;

  /// Name of the get_queue tool on a tool card.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get aiChatToolGetQueue;

  /// Name of the search_library tool on a tool card.
  ///
  /// In en, this message translates to:
  /// **'Search the library'**
  String get aiChatToolSearchLibrary;

  /// Name of the get_track_info tool on a tool card.
  ///
  /// In en, this message translates to:
  /// **'Song info'**
  String get aiChatToolGetTrackInfo;

  /// Screen-reader label of the message field.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get aiChatComposerLabel;

  /// Placeholder of the message field.
  ///
  /// In en, this message translates to:
  /// **'Ask about your music…'**
  String get aiChatComposerHint;

  /// Placeholder of the message field while the chat's plugin is gone.
  ///
  /// In en, this message translates to:
  /// **'Choose a plugin to continue…'**
  String get aiChatComposerHintLocked;

  /// Tooltip and label of the send button.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get aiChatSend;

  /// Tooltip and label of the stop button while the model answers.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get aiChatStop;

  /// Tooltip of the stop button while a tool runs.
  ///
  /// In en, this message translates to:
  /// **'Stop (the running tool finishes, later ones do not run)'**
  String get aiChatStopTools;

  /// Tooltip and label of the plugin button.
  ///
  /// In en, this message translates to:
  /// **'AI service: {plugin}'**
  String aiChatPluginTooltip(String plugin);

  /// Tooltip of the plugin button when the chat's plugin was uninstalled.
  ///
  /// In en, this message translates to:
  /// **'Plugin removed · choose another'**
  String get aiChatPluginGone;

  /// Tooltip of the icon-only permission button.
  ///
  /// In en, this message translates to:
  /// **'Permission: {mode} · {description}'**
  String aiChatPermissionTooltip(String mode, String description);

  /// Screen-reader label of the permission button.
  ///
  /// In en, this message translates to:
  /// **'Permission: {mode}'**
  String aiChatPermissionLabel(String mode);

  /// Name of the read-only permission.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get aiChatPermissionReadOnly;

  /// Name of the ask-first permission.
  ///
  /// In en, this message translates to:
  /// **'Ask first'**
  String get aiChatPermissionAsk;

  /// Name of the automatic permission.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get aiChatPermissionAuto;

  /// Description of the read-only permission.
  ///
  /// In en, this message translates to:
  /// **'Reads and suggests, never changes data'**
  String get aiChatPermissionReadOnlyHint;

  /// Description of the ask-first permission.
  ///
  /// In en, this message translates to:
  /// **'Asks before changing anything'**
  String get aiChatPermissionAskHint;

  /// Description of the automatic permission.
  ///
  /// In en, this message translates to:
  /// **'Makes changes without asking'**
  String get aiChatPermissionAutoHint;

  /// Caption under the permission picker.
  ///
  /// In en, this message translates to:
  /// **'For this conversation only.'**
  String get aiChatPermissionPickerCaption;

  /// Text of the model button while no model is chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose a model'**
  String get aiChatModelNeeded;

  /// Screen-reader label of the model button.
  ///
  /// In en, this message translates to:
  /// **'Model: {model}'**
  String aiChatModelLabel(String model);

  /// Tag of a model the user added.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get aiChatModelCustom;

  /// Capability tag: the model reads images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get aiChatCapVision;

  /// Capability tag: the model can use tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get aiChatCapTools;

  /// Spoken form of a capability the model lacks.
  ///
  /// In en, this message translates to:
  /// **'{cap}: unavailable'**
  String aiChatCapUnavailable(String cap);

  /// Title of the plugin picker in the composer.
  ///
  /// In en, this message translates to:
  /// **'AI service'**
  String get aiChatPluginPickerTitle;

  /// Title of the model picker in the composer. {plugin} is the plugin's name.
  ///
  /// In en, this message translates to:
  /// **'Model · {plugin}'**
  String aiChatModelPickerTitle(String plugin);

  /// Caption under the model picker title.
  ///
  /// In en, this message translates to:
  /// **'Applies from the next message.'**
  String get aiChatModelPickerCaption;

  /// Title of the permission picker in the composer.
  ///
  /// In en, this message translates to:
  /// **'Permission in this chat'**
  String get aiChatPermissionPickerTitle;

  /// Caption under the plugin picker.
  ///
  /// In en, this message translates to:
  /// **'Applies from the next message. History stays as it is.'**
  String get aiChatPluginPickerCaption;

  /// Footer button of the plugin picker; opens the plugin store.
  ///
  /// In en, this message translates to:
  /// **'Add an AI service…'**
  String get aiChatPluginPickerAdd;

  /// State line of a ready plugin that uses an API key.
  ///
  /// In en, this message translates to:
  /// **'API key set'**
  String get aiChatPluginHasKey;

  /// State line of a ready plugin without an API key.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get aiChatPluginReady;

  /// State line of a plugin with no API key.
  ///
  /// In en, this message translates to:
  /// **'Needs an API key'**
  String get aiChatPluginNeedsKey;

  /// State line of a plugin with no model.
  ///
  /// In en, this message translates to:
  /// **'No model chosen'**
  String get aiChatPluginNeedsModel;

  /// State line of a plugin with required settings empty.
  ///
  /// In en, this message translates to:
  /// **'Needs setup'**
  String get aiChatPluginNeedsConfig;

  /// Label of the × of a note above the message field.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get aiChatNoticeDismiss;

  /// Button of a note: opens the plugin's settings page.
  ///
  /// In en, this message translates to:
  /// **'Open plugin settings'**
  String get aiChatActionOpenPluginSettings;

  /// Button of a note: opens the model picker.
  ///
  /// In en, this message translates to:
  /// **'Choose a model'**
  String get aiChatActionPickModel;

  /// Button of a note: opens the plugin picker.
  ///
  /// In en, this message translates to:
  /// **'Choose a plugin'**
  String get aiChatActionPickPlugin;

  /// Button of a note: opens the lyrics search for the playing song.
  ///
  /// In en, this message translates to:
  /// **'Find lyrics for this song'**
  String get aiChatActionFindLyrics;

  /// Button of a note: drops the pending send.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get aiChatActionCancel;

  /// Button of a note: sends the shortened values.
  ///
  /// In en, this message translates to:
  /// **'Send the short version'**
  String get aiChatActionSendShort;

  /// Button of a note: removes the attached chip.
  ///
  /// In en, this message translates to:
  /// **'Remove chip'**
  String get aiChatActionDropChip;

  /// Button of a note: opens the AI settings page.
  ///
  /// In en, this message translates to:
  /// **'AI settings'**
  String get aiChatActionAiSettings;

  /// Note when the chat's plugin has no API key.
  ///
  /// In en, this message translates to:
  /// **'{plugin} needs an API key before it can send.'**
  String aiChatNoticeNeedsKey(String plugin);

  /// Note when no model is chosen.
  ///
  /// In en, this message translates to:
  /// **'{plugin} has no model. Choose a model before sending.'**
  String aiChatNoticeNeedsModel(String plugin);

  /// Note when required settings of the plugin are empty; {fields} are their names.
  ///
  /// In en, this message translates to:
  /// **'{plugin} needs setup: {fields}.'**
  String aiChatNoticeNeedsConfig(String plugin, String fields);

  /// Note when the chat's plugin was uninstalled.
  ///
  /// In en, this message translates to:
  /// **'This chat\'s plugin was removed. Choose another plugin to continue.'**
  String get aiChatNoticeRemoved;

  /// Note when the chat's plugin was uninstalled and its name is known.
  ///
  /// In en, this message translates to:
  /// **'Plugin “{plugin}” was removed. Choose another plugin to continue.'**
  String aiChatNoticeRemovedNamed(String plugin);

  /// Note when the chat's plugin was removed and installed again.
  ///
  /// In en, this message translates to:
  /// **'Plugin “{plugin}” was removed and installed again. Choose a plugin to continue this chat.'**
  String aiChatNoticeReinstalled(String plugin);

  /// Note when an attached chip needs a tool group that is off.
  ///
  /// In en, this message translates to:
  /// **'The “{group}” tool is off, so this chip cannot be sent.'**
  String aiChatNoticeStruckChip(String group);

  /// Note when a variable needs lyrics the song does not have.
  ///
  /// In en, this message translates to:
  /// **'The playing song has no lyrics, so {variable} cannot be filled. Nothing was sent; your text is still here.'**
  String aiChatNoticeMissingLyrics(String variable);

  /// Note when a variable needs a playing song and none plays.
  ///
  /// In en, this message translates to:
  /// **'Nothing is playing, so {variable} cannot be filled. Nothing was sent; your text is still here.'**
  String aiChatNoticeMissingPlaying(String variable);

  /// Note when the queue variable has no queue.
  ///
  /// In en, this message translates to:
  /// **'The queue is empty, so {variable} cannot be filled. Nothing was sent; your text is still here.'**
  String aiChatNoticeMissingQueue(String variable);

  /// Note when a variable's tool group is off.
  ///
  /// In en, this message translates to:
  /// **'The “{group}” tool is off, so {variable} cannot be filled. Nothing was sent.'**
  String aiChatNoticeGroupOff(String group, String variable);

  /// Note when the input blank of a prompt was left in the message.
  ///
  /// In en, this message translates to:
  /// **'{variable} is still in the message: type your text in its place, then send. Nothing was sent.'**
  String aiChatNoticeLeftoverInput(String variable);

  /// Note when an attached chip has no data now.
  ///
  /// In en, this message translates to:
  /// **'Could not read the data of the chip “{chip}”. Nothing was sent.'**
  String aiChatNoticeChipUnavailable(String chip);

  /// Note when a filled value is over the model's limit.
  ///
  /// In en, this message translates to:
  /// **'{variables} is too large to send to {model}.'**
  String aiChatNoticeOversize(String variables, String model);

  /// Note when the queue is over the model's limit; {count} is the number of songs in it.
  ///
  /// In en, this message translates to:
  /// **'{variable} has {count} songs, over the limit {model} accepts.'**
  String aiChatNoticeOversizeQueue(String variable, int count, String model);

  /// Button of a note: sends the queue shortened to {count} songs around the playing one.
  ///
  /// In en, this message translates to:
  /// **'Send the short version: {count} songs around the playing one'**
  String aiChatActionSendShortQueue(int count);

  /// Note when storing the message failed.
  ///
  /// In en, this message translates to:
  /// **'The message could not be saved. Your text is still here; try again.'**
  String get aiChatNoticeSendFailed;

  /// Gentle note when the model gets no tools.
  ///
  /// In en, this message translates to:
  /// **'{model} does not use tools: the AI only sees variables and chips you attach, it does not read the library itself.'**
  String aiChatNoticeNoTools(String model);

  /// Context chip: the playing song.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get aiChatChipNowPlaying;

  /// Context chip: the playing song, with its title.
  ///
  /// In en, this message translates to:
  /// **'Now playing: {title}'**
  String aiChatChipNowPlayingNamed(String title);

  /// Context chip of a song without a name.
  ///
  /// In en, this message translates to:
  /// **'Song'**
  String get aiChatChipSong;

  /// Context chip: several songs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} song} other{{count} songs}}'**
  String aiChatChipSongs(int count);

  /// Context chip: an album.
  ///
  /// In en, this message translates to:
  /// **'Album: {label}'**
  String aiChatChipAlbum(String label);

  /// Context chip: an artist.
  ///
  /// In en, this message translates to:
  /// **'Artist: {label}'**
  String aiChatChipArtist(String label);

  /// Context chip: a genre.
  ///
  /// In en, this message translates to:
  /// **'Genre: {label}'**
  String aiChatChipGenre(String label);

  /// Context chip: a language.
  ///
  /// In en, this message translates to:
  /// **'Language: {label}'**
  String aiChatChipLanguage(String label);

  /// Context chip: a playlist.
  ///
  /// In en, this message translates to:
  /// **'Playlist: {label}'**
  String aiChatChipPlaylist(String label);

  /// Tooltip and label of the × of a chip.
  ///
  /// In en, this message translates to:
  /// **'Remove chip {label}'**
  String aiChatChipRemove(String label);

  /// Screen-reader hint of a chip that cannot be sent.
  ///
  /// In en, this message translates to:
  /// **'This chip\'s tool is off'**
  String get aiChatChipStruckHint;

  /// Name of the now-playing tool group in a note.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get aiChatGroupNowPlaying;

  /// Name of the song-info tool group in a note.
  ///
  /// In en, this message translates to:
  /// **'Song info'**
  String get aiChatGroupTrackInfo;

  /// Name of the playlists tool group in a note.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get aiChatGroupPlaylists;

  /// Name of the lyrics tool group in a note.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get aiChatGroupLyrics;

  /// Name of the queue tool group in a note.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get aiChatGroupQueue;

  /// Screen-reader label of the variable list.
  ///
  /// In en, this message translates to:
  /// **'Insert a variable'**
  String get aiChatVarListLabel;

  /// Heading of the variable list shown after typing {{.
  ///
  /// In en, this message translates to:
  /// **'Insert a variable · the app fills it when you send'**
  String get aiChatVarListTitle;

  /// Screen-reader label of the group of prompt chips.
  ///
  /// In en, this message translates to:
  /// **'Saved prompts'**
  String get aiChatPromptsLabel;

  /// Reason under a prompt chip that needs a playing song.
  ///
  /// In en, this message translates to:
  /// **'Nothing is playing'**
  String get aiChatPromptNoPlaying;

  /// Reason under a prompt chip that needs the queue.
  ///
  /// In en, this message translates to:
  /// **'The queue is empty'**
  String get aiChatPromptEmptyQueue;

  /// Button of a confirmation card.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get aiChatCardAllow;

  /// Button of a confirmation card.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get aiChatCardDeny;

  /// Button of a done card: opens the playlist.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get aiChatCardView;

  /// Button of a done card.
  ///
  /// In en, this message translates to:
  /// **'Open queue'**
  String get aiChatCardOpenQueue;

  /// Button of a done card whose call replaced the queue.
  ///
  /// In en, this message translates to:
  /// **'Play the old queue again'**
  String get aiChatCardReplayQueue;

  /// Locked retry button, under a minute left.
  ///
  /// In en, this message translates to:
  /// **'Try again in {seconds, plural, =1{1 second} other{{seconds} seconds}}'**
  String aiChatCardRetryIn(int seconds);

  /// Locked retry button, whole minutes left.
  ///
  /// In en, this message translates to:
  /// **'Try again in {minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String aiChatCardRetryInMinutes(int minutes);

  /// Locked retry button, minutes and seconds left.
  ///
  /// In en, this message translates to:
  /// **'Try again in {minutes} min {seconds} s'**
  String aiChatCardRetryInMinutesSeconds(int minutes, int seconds);

  /// Locked retry button, an hour or more left; {time} is the clock time.
  ///
  /// In en, this message translates to:
  /// **'Try again at {time}'**
  String aiChatCardRetryAt(String time);

  /// Said once to screen readers when the retry countdown ends.
  ///
  /// In en, this message translates to:
  /// **'You can try again now'**
  String get aiChatCardCanRetry;

  /// Fold row of the songs a done card added.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}} added'**
  String aiChatCardAddedFold(int count);

  /// Fold row of the songs a done card removed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}} removed'**
  String aiChatCardRemovedFold(int count);

  /// Fold row of the queue a play call replaced.
  ///
  /// In en, this message translates to:
  /// **'Old queue · {count, plural, =1{1 song} other{{count} songs}}'**
  String aiChatCardOldQueueFold(int count);

  /// Button that shows the rest of a short song list.
  ///
  /// In en, this message translates to:
  /// **'+{count, plural, =1{1 song} other{{count} songs}}'**
  String aiChatCardMoreTracks(int count);

  /// Accessible name of a song list in a card.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}}'**
  String aiChatCardTrackList(int count);

  /// Second line of a song row whose song is gone.
  ///
  /// In en, this message translates to:
  /// **'No longer in the library'**
  String get aiChatCardTrackGone;

  /// What a create_playlist call does.
  ///
  /// In en, this message translates to:
  /// **'create playlist “{name}” · {count, plural, =1{1 song} other{{count} songs}}'**
  String aiChatActCreatePlaylist(String name, int count);

  /// What an add_to_playlist call does, playlist name unknown.
  ///
  /// In en, this message translates to:
  /// **'add {count, plural, =1{1 song} other{{count} songs}} to a playlist'**
  String aiChatActAddToPlaylist(int count);

  /// What an add_to_playlist call does.
  ///
  /// In en, this message translates to:
  /// **'add {count, plural, =1{1 song} other{{count} songs}} to playlist “{name}”'**
  String aiChatActAddToPlaylistNamed(String name, int count);

  /// What a remove_from_playlist call does, playlist name unknown.
  ///
  /// In en, this message translates to:
  /// **'remove {count, plural, =1{1 song} other{{count} songs}} from a playlist'**
  String aiChatActRemoveFromPlaylist(int count);

  /// What a remove_from_playlist call does.
  ///
  /// In en, this message translates to:
  /// **'remove {count, plural, =1{1 song} other{{count} songs}} from playlist “{name}”'**
  String aiChatActRemoveFromPlaylistNamed(String name, int count);

  /// What a play_tracks call does.
  ///
  /// In en, this message translates to:
  /// **'play {count, plural, =1{1 song} other{{count} songs}}'**
  String aiChatActPlay(int count);

  /// What a queue_tracks call does.
  ///
  /// In en, this message translates to:
  /// **'add {count, plural, =1{1 song} other{{count} songs}} to the queue'**
  String aiChatActQueue(int count);

  /// What a remove_from_queue call does.
  ///
  /// In en, this message translates to:
  /// **'remove {count, plural, =1{1 song} other{{count} songs}} from the queue'**
  String aiChatActRemoveFromQueue(int count);

  /// Tool group shown in a done card.
  ///
  /// In en, this message translates to:
  /// **'Playback control'**
  String get aiChatGroupPlay;

  /// Tool group shown in a done card.
  ///
  /// In en, this message translates to:
  /// **'Queue edits'**
  String get aiChatGroupQueueEdit;

  /// Tool group shown in a done card.
  ///
  /// In en, this message translates to:
  /// **'Playlist creation'**
  String get aiChatGroupPlaylistCreate;

  /// Tool group shown in a done card.
  ///
  /// In en, this message translates to:
  /// **'Playlist edits'**
  String get aiChatGroupPlaylistEdit;

  /// Second line of a confirmation card.
  ///
  /// In en, this message translates to:
  /// **'{tool} · needs your OK'**
  String aiChatCardNeedsAllow(String tool);

  /// Start of the second line of a done card after a confirmation.
  ///
  /// In en, this message translates to:
  /// **'You allowed it'**
  String get aiChatCardAllowedByUser;

  /// Start of the second line of a done card made in Auto mode.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get aiChatCardAutomatic;

  /// Title of a done card.
  ///
  /// In en, this message translates to:
  /// **'Done: {action}'**
  String aiChatCardDoneTitle(String action);

  /// Part of a done card's second line after play_tracks.
  ///
  /// In en, this message translates to:
  /// **'the old queue was replaced'**
  String get aiChatCardOldQueueReplaced;

  /// Part of a done card's second line after a removal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}} already gone from the queue'**
  String aiChatCardGoneFromQueue(int count);

  /// Part of a done card's second line after a removal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}} already gone from the playlist'**
  String aiChatCardGoneFromPlaylist(int count);

  /// Part of a done card's second line when ids were not songs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}} not in the library'**
  String aiChatCardNotInLibrary(int count);

  /// Title of a card the user declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get aiChatCardDenied;

  /// Title of a card left open when the user wrote again.
  ///
  /// In en, this message translates to:
  /// **'Declined (you sent another message)'**
  String get aiChatCardDeniedByNewMessage;

  /// Title of a card Kanaru refused to run after the user allowed it.
  ///
  /// In en, this message translates to:
  /// **'Declined: no longer allowed'**
  String get aiChatCardDeniedNotAllowed;

  /// Title of a confirmation card that waited too long.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get aiChatCardExpired;

  /// Title of a call that did not run after Stop.
  ///
  /// In en, this message translates to:
  /// **'Not run: you stopped it'**
  String get aiChatCardSkippedStopped;

  /// Title of a call that did not run.
  ///
  /// In en, this message translates to:
  /// **'Not run'**
  String get aiChatCardSkipped;

  /// Second line of a card whose call did not run.
  ///
  /// In en, this message translates to:
  /// **'{action} · nothing changed'**
  String aiChatCardNothingChanged(String action);

  /// Reason line of an expired card.
  ///
  /// In en, this message translates to:
  /// **'The card waited over 24 hours. Ask the AI again if you still want it.'**
  String get aiChatCardExpiredWhy;

  /// Reason line of a card refused after the user allowed it.
  ///
  /// In en, this message translates to:
  /// **'You switched this chat to Read-only before this ran.'**
  String get aiChatCardWhyReadOnly;

  /// Reason line of a card refused after the user allowed it.
  ///
  /// In en, this message translates to:
  /// **'You turned this tool group off before this ran.'**
  String get aiChatCardWhyGroupOff;

  /// Reason line of a card refused after the user allowed it.
  ///
  /// In en, this message translates to:
  /// **'This chat\'s plugin changed before this ran.'**
  String get aiChatCardWhyPluginChanged;

  /// Reason line of a card refused after the user allowed it.
  ///
  /// In en, this message translates to:
  /// **'This chat\'s model changed before this ran.'**
  String get aiChatCardWhyModelChanged;

  /// Reason line of a card refused after the user allowed it.
  ///
  /// In en, this message translates to:
  /// **'This changed after you allowed it, so Kanaru did not run it.'**
  String get aiChatCardWhyChangedAfterAllow;

  /// Reason line of a card refused after the user allowed it.
  ///
  /// In en, this message translates to:
  /// **'This is no longer allowed to run.'**
  String get aiChatCardWhyNotAllowed;

  /// Reason line of a call skipped because the chat grew too large.
  ///
  /// In en, this message translates to:
  /// **'This chat grew too long to send.'**
  String get aiChatCardWhyTooLarge;

  /// Reason line of a call skipped because of the item limit.
  ///
  /// In en, this message translates to:
  /// **'The AI reached its change limit for this message.'**
  String get aiChatCardWhyLimit;

  /// Title of a card whose write was cut off.
  ///
  /// In en, this message translates to:
  /// **'Result unknown: {action}'**
  String aiChatCardUnknownTitle(String action);

  /// First sentence of the unknown-result card.
  ///
  /// In en, this message translates to:
  /// **'Kanaru was closed while this was running, so it is not known whether it finished.'**
  String get aiChatCardUnknownClosed;

  /// First sentence of the unknown-result card.
  ///
  /// In en, this message translates to:
  /// **'This took too long, so it is not known whether it finished.'**
  String get aiChatCardUnknownTimedOut;

  /// Last sentence of the unknown-result card for a queue change.
  ///
  /// In en, this message translates to:
  /// **'Check the queue before asking the AI to do it again.'**
  String get aiChatCardLookQueue;

  /// Last sentence of the unknown-result card for a playlist change.
  ///
  /// In en, this message translates to:
  /// **'Check the playlist before asking the AI to do it again.'**
  String get aiChatCardLookPlaylist;

  /// Title of the item-cap card.
  ///
  /// In en, this message translates to:
  /// **'The AI reached its change limit for this message'**
  String get aiChatCardLimitTitle;

  /// Body of the item-cap card.
  ///
  /// In en, this message translates to:
  /// **'One message may remove at most {removed, plural, =1{1 song} other{{removed} songs}} and add at most {added, plural, =1{1 song} other{{added} songs}}. Send a new message to continue.'**
  String aiChatCardLimitBody(int removed, int added);

  /// Body of the item-cap card naming the call that did not run.
  ///
  /// In en, this message translates to:
  /// **'One message may remove at most {removed, plural, =1{1 song} other{{removed} songs}} and add at most {added, plural, =1{1 song} other{{added} songs}}. “{action}” did not run. Send a new message to continue.'**
  String aiChatCardLimitBodyAction(int removed, int added, String action);

  /// Name used when the chat's plugin is not installed any more.
  ///
  /// In en, this message translates to:
  /// **'Plugin'**
  String get aiChatErrPluginFallback;

  /// Title of the network error card.
  ///
  /// In en, this message translates to:
  /// **'Could not reach {host}'**
  String aiChatErrNetworkTitle(String host);

  /// Title of the network error card when the host is not known.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server'**
  String get aiChatErrNetworkTitleNoHost;

  /// No description provided for @aiChatErrNetworkBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again. Your message is still here.'**
  String get aiChatErrNetworkBody;

  /// Title of the rate-limit card.
  ///
  /// In en, this message translates to:
  /// **'{plugin} is limiting requests'**
  String aiChatErrRateTitle(String plugin);

  /// No description provided for @aiChatErrRateBody.
  ///
  /// In en, this message translates to:
  /// **'The plugin reported error 429 (too many requests). When the countdown ends, tap Try again; Kanaru never resends on its own.'**
  String get aiChatErrRateBody;

  /// No description provided for @aiChatErrRateBodyNoClock.
  ///
  /// In en, this message translates to:
  /// **'The plugin reported error 429 (too many requests). Wait a moment, then tap Try again; Kanaru never resends on its own.'**
  String get aiChatErrRateBodyNoClock;

  /// No description provided for @aiChatErrBusyTitle.
  ///
  /// In en, this message translates to:
  /// **'The previous turn has not stopped yet'**
  String get aiChatErrBusyTitle;

  /// No description provided for @aiChatErrBusyBody.
  ///
  /// In en, this message translates to:
  /// **'Kanaru is still finishing the previous answer. Try again in a moment.'**
  String get aiChatErrBusyBody;

  /// No description provided for @aiChatErrBusyStuckTitle.
  ///
  /// In en, this message translates to:
  /// **'The previous turn still has not stopped'**
  String get aiChatErrBusyStuckTitle;

  /// No description provided for @aiChatErrBusyStuckBody.
  ///
  /// In en, this message translates to:
  /// **'Tried 3 times and the previous turn has not ended. Restart Kanaru and try again.'**
  String get aiChatErrBusyStuckBody;

  /// No description provided for @aiChatErrKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'{plugin} did not accept the API key'**
  String aiChatErrKeyTitle(String plugin);

  /// No description provided for @aiChatErrKeyBody.
  ///
  /// In en, this message translates to:
  /// **'The API key is wrong or was revoked. Fix it in the plugin\'s settings, then try again.'**
  String get aiChatErrKeyBody;

  /// No description provided for @aiChatErrQuotaTitle.
  ///
  /// In en, this message translates to:
  /// **'The {plugin} account is out of quota'**
  String aiChatErrQuotaTitle(String plugin);

  /// No description provided for @aiChatErrQuotaBody.
  ///
  /// In en, this message translates to:
  /// **'Top up or change your plan on the provider\'s site, then try again.'**
  String get aiChatErrQuotaBody;

  /// No description provided for @aiChatErrConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'The settings of {plugin} are incomplete'**
  String aiChatErrConfigTitle(String plugin);

  /// No description provided for @aiChatErrConfigBody.
  ///
  /// In en, this message translates to:
  /// **'The plugin says a setting is missing. Open its settings, fill it in and try again.'**
  String get aiChatErrConfigBody;

  /// No description provided for @aiChatErrModelGoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Model no longer available: {model}'**
  String aiChatErrModelGoneTitle(String model);

  /// No description provided for @aiChatErrModelGoneTitleNoModel.
  ///
  /// In en, this message translates to:
  /// **'Model no longer available'**
  String get aiChatErrModelGoneTitleNoModel;

  /// No description provided for @aiChatErrModelGoneBody.
  ///
  /// In en, this message translates to:
  /// **'{plugin} no longer has this model. Pick another model, then try again.'**
  String aiChatErrModelGoneBody(String plugin);

  /// No description provided for @aiChatErrContextTitle.
  ///
  /// In en, this message translates to:
  /// **'This conversation is too long for this model'**
  String get aiChatErrContextTitle;

  /// No description provided for @aiChatErrContextBody.
  ///
  /// In en, this message translates to:
  /// **'{model} cannot take more. Start a new conversation to go on; this one stays readable.'**
  String aiChatErrContextBody(String model);

  /// No description provided for @aiChatErrTooLargeTitle.
  ///
  /// In en, this message translates to:
  /// **'This conversation is too long to send'**
  String get aiChatErrTooLargeTitle;

  /// No description provided for @aiChatErrTooLargeBody.
  ///
  /// In en, this message translates to:
  /// **'Kanaru shortened the older turns and it is still over the send limit. Start a new conversation, or send a shorter message.'**
  String get aiChatErrTooLargeBody;

  /// No description provided for @aiChatErrBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'The model will not answer this request'**
  String get aiChatErrBlockedTitle;

  /// No description provided for @aiChatErrBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'{model} refused (the provider\'s reason). Rephrase it, or change the model in the input box.'**
  String aiChatErrBlockedBody(String model);

  /// No description provided for @aiChatErrEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'The model gave no answer'**
  String get aiChatErrEmptyTitle;

  /// No description provided for @aiChatErrEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'{model} returned an empty answer. Try again, or change the model in the input box.'**
  String aiChatErrEmptyBody(String model);

  /// No description provided for @aiChatErrGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'{plugin} ran into an error'**
  String aiChatErrGenericTitle(String plugin);

  /// No description provided for @aiChatErrGenericBody.
  ///
  /// In en, this message translates to:
  /// **'The service reported an error (code: {code}). Try again in a few minutes.'**
  String aiChatErrGenericBody(String code);

  /// No description provided for @aiChatErrHostTitle.
  ///
  /// In en, this message translates to:
  /// **'The plugin is not allowed to call {host}'**
  String aiChatErrHostTitle(String host);

  /// No description provided for @aiChatErrHostTitleNoHost.
  ///
  /// In en, this message translates to:
  /// **'The plugin is not allowed to call this address'**
  String get aiChatErrHostTitleNoHost;

  /// No description provided for @aiChatErrHostBody.
  ///
  /// In en, this message translates to:
  /// **'This address is not in the list the plugin declared at install, so Kanaru blocks it.'**
  String get aiChatErrHostBody;

  /// No description provided for @aiChatErrUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'The plugin was just updated'**
  String get aiChatErrUpdatedTitle;

  /// No description provided for @aiChatErrUpdatedBody.
  ///
  /// In en, this message translates to:
  /// **'{plugin} was updated during the answer, so this turn stopped. What was received stays above.'**
  String aiChatErrUpdatedBody(String plugin);

  /// No description provided for @aiChatErrRemovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Plugin removed'**
  String get aiChatErrRemovedTitle;

  /// No description provided for @aiChatErrRemovedBody.
  ///
  /// In en, this message translates to:
  /// **'{plugin} was removed during the answer. Pick another plugin to go on.'**
  String aiChatErrRemovedBody(String plugin);

  /// No description provided for @aiChatErrBrokenTitle.
  ///
  /// In en, this message translates to:
  /// **'The plugin is broken and needs reinstalling'**
  String get aiChatErrBrokenTitle;

  /// No description provided for @aiChatErrBrokenBody.
  ///
  /// In en, this message translates to:
  /// **'The package of {plugin} cannot be read. Open the plugin page to reinstall it.'**
  String aiChatErrBrokenBody(String plugin);

  /// No description provided for @aiChatErrTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Timed out'**
  String get aiChatErrTimeoutTitle;

  /// No description provided for @aiChatErrTimeoutBody.
  ///
  /// In en, this message translates to:
  /// **'{plugin} sent nothing more, so this turn stopped. What was received stays above.'**
  String aiChatErrTimeoutBody(String plugin);

  /// No description provided for @aiChatErrCrashTitle.
  ///
  /// In en, this message translates to:
  /// **'The plugin ran into an error'**
  String get aiChatErrCrashTitle;

  /// No description provided for @aiChatErrCrashBody.
  ///
  /// In en, this message translates to:
  /// **'{plugin} stopped midway because of an error inside the plugin. Try again; if it repeats, check the plugin\'s log.'**
  String aiChatErrCrashBody(String plugin);

  /// No description provided for @aiChatErrCutOffTitle.
  ///
  /// In en, this message translates to:
  /// **'The answer was cut off when Kanaru closed'**
  String get aiChatErrCutOffTitle;

  /// No description provided for @aiChatErrCutOffBody.
  ///
  /// In en, this message translates to:
  /// **'What was received stays above. Kanaru does not resend when it opens; tap Try again to let the AI go on.'**
  String get aiChatErrCutOffBody;

  /// Button of the broken-plugin error card.
  ///
  /// In en, this message translates to:
  /// **'Open plugin'**
  String get aiChatActionOpenPlugin;

  /// Button of the model-not-found error card: opens the model picker.
  ///
  /// In en, this message translates to:
  /// **'Change model'**
  String get aiChatActionChangeModel;

  /// Title of the history page.
  ///
  /// In en, this message translates to:
  /// **'Chat history'**
  String get aiChatHistoryTitle;

  /// Tooltip of the back button of the history page in the desktop panel.
  ///
  /// In en, this message translates to:
  /// **'Back to the open conversation'**
  String get aiChatHistoryBackPanel;

  /// Tooltip of the back button of the history page on the phone.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get aiChatHistoryBackPage;

  /// Hint and label of the search field of the history page.
  ///
  /// In en, this message translates to:
  /// **'Search conversations'**
  String get aiChatHistorySearch;

  /// Group heading of the history list.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get aiChatHistoryToday;

  /// Group heading of the history list.
  ///
  /// In en, this message translates to:
  /// **'Past 7 days'**
  String get aiChatHistoryWeek;

  /// Group heading of the history list.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get aiChatHistoryOlder;

  /// Shown in the error colour on a history row whose plugin is no longer installed.
  ///
  /// In en, this message translates to:
  /// **'plugin removed'**
  String get aiChatHistoryPluginRemoved;

  /// Shown when the history search finds nothing.
  ///
  /// In en, this message translates to:
  /// **'No conversation matches “{query}”.'**
  String aiChatHistoryNoMatch(String query);

  /// Tooltip of the ⋮ button of a history row.
  ///
  /// In en, this message translates to:
  /// **'Options for {title}'**
  String aiChatHistoryRowOptions(String title);

  /// No description provided for @aiSetServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'AI services'**
  String get aiSetServicesTitle;

  /// No description provided for @aiSetServicesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a service to open its plugin settings (API key, default model). New chats use the service you picked last in the chat.'**
  String get aiSetServicesHint;

  /// No description provided for @aiSetServicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No AI service installed. AI chat needs an AI plugin (for example Gemini or OpenAI-compatible) and your own API key.'**
  String get aiSetServicesEmpty;

  /// No description provided for @aiSetServiceAdd.
  ///
  /// In en, this message translates to:
  /// **'Add AI service'**
  String get aiSetServiceAdd;

  /// No description provided for @aiSetServiceModelLastUsed.
  ///
  /// In en, this message translates to:
  /// **'{model} · last used'**
  String aiSetServiceModelLastUsed(String model);

  /// No description provided for @aiSetServiceLastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get aiSetServiceLastUsed;

  /// No description provided for @aiSetServiceNeedsKey.
  ///
  /// In en, this message translates to:
  /// **'Needs API key'**
  String get aiSetServiceNeedsKey;

  /// No description provided for @aiSetServiceNeedsConfig.
  ///
  /// In en, this message translates to:
  /// **'Needs setup: {fields}'**
  String aiSetServiceNeedsConfig(String fields);

  /// No description provided for @aiSetServicesGone.
  ///
  /// In en, this message translates to:
  /// **'The service you used last ({removed}) was removed. New chats use {next} until you pick another service in the chat.'**
  String aiSetServicesGone(String removed, String next);

  /// No description provided for @aiSetPermTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get aiSetPermTitle;

  /// No description provided for @aiSetPermRow.
  ///
  /// In en, this message translates to:
  /// **'Default permission for new chats'**
  String get aiSetPermRow;

  /// No description provided for @aiSetPermCaption.
  ///
  /// In en, this message translates to:
  /// **'Each chat keeps its own permission and you can change it at once in the input box.'**
  String get aiSetPermCaption;

  /// No description provided for @aiSetPermReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get aiSetPermReadOnly;

  /// No description provided for @aiSetPermReadOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Reads and suggests, never changes data'**
  String get aiSetPermReadOnlyDesc;

  /// No description provided for @aiSetPermAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask first'**
  String get aiSetPermAsk;

  /// No description provided for @aiSetPermAskDesc.
  ///
  /// In en, this message translates to:
  /// **'Asks before changing anything · default'**
  String get aiSetPermAskDesc;

  /// No description provided for @aiSetPermAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get aiSetPermAuto;

  /// No description provided for @aiSetPermAutoDesc.
  ///
  /// In en, this message translates to:
  /// **'Makes changes without asking'**
  String get aiSetPermAutoDesc;

  /// No description provided for @aiSetInstructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'General instructions'**
  String get aiSetInstructionsTitle;

  /// No description provided for @aiSetInstructionsHint.
  ///
  /// In en, this message translates to:
  /// **'Sent with every chat, to every AI service.'**
  String get aiSetInstructionsHint;

  /// No description provided for @aiSetInstructionsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'For example: answer in English, keep it short'**
  String get aiSetInstructionsPlaceholder;

  /// No description provided for @aiSetToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get aiSetToolsTitle;

  /// No description provided for @aiSetToolsHint.
  ///
  /// In en, this message translates to:
  /// **'The AI fetches data through the tools that are on. With a tool off, it does not fetch that data by itself.'**
  String get aiSetToolsHint;

  /// No description provided for @aiSetToolsGroupRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get aiSetToolsGroupRead;

  /// No description provided for @aiSetToolsGroupWrite.
  ///
  /// In en, this message translates to:
  /// **'Changes · follow the chat permission'**
  String get aiSetToolsGroupWrite;

  /// No description provided for @aiSetToolsStatsLocked.
  ///
  /// In en, this message translates to:
  /// **'Turn on “Record listening history” in Playback first'**
  String get aiSetToolsStatsLocked;

  /// No description provided for @aiSetToolNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get aiSetToolNowPlaying;

  /// No description provided for @aiSetToolNowPlayingDesc.
  ///
  /// In en, this message translates to:
  /// **'Title, artist, album · variables {variables}'**
  String aiSetToolNowPlayingDesc(String variables);

  /// No description provided for @aiSetToolQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get aiSetToolQueue;

  /// No description provided for @aiSetToolQueueDesc.
  ///
  /// In en, this message translates to:
  /// **'Up to 50 songs around the playing one · variable {variables}'**
  String aiSetToolQueueDesc(String variables);

  /// No description provided for @aiSetToolLibrarySearch.
  ///
  /// In en, this message translates to:
  /// **'Search the library'**
  String get aiSetToolLibrarySearch;

  /// No description provided for @aiSetToolLibrarySearchDesc.
  ///
  /// In en, this message translates to:
  /// **'Up to 50 results at a time, the AI can ask for more'**
  String get aiSetToolLibrarySearchDesc;

  /// No description provided for @aiSetToolLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get aiSetToolLyrics;

  /// No description provided for @aiSetToolLyricsDesc.
  ///
  /// In en, this message translates to:
  /// **'Plain text, no timestamps · variable {variables}'**
  String aiSetToolLyricsDesc(String variables);

  /// No description provided for @aiSetToolTrackInfo.
  ///
  /// In en, this message translates to:
  /// **'Song info'**
  String get aiSetToolTrackInfo;

  /// No description provided for @aiSetToolTrackInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'Song tags, album, the selected songs · Album and N selected songs cards'**
  String get aiSetToolTrackInfoDesc;

  /// No description provided for @aiSetToolListeningStats.
  ///
  /// In en, this message translates to:
  /// **'Listening stats'**
  String get aiSetToolListeningStats;

  /// No description provided for @aiSetToolListeningStatsDesc.
  ///
  /// In en, this message translates to:
  /// **'History, most played'**
  String get aiSetToolListeningStatsDesc;

  /// No description provided for @aiSetToolPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlist list'**
  String get aiSetToolPlaylists;

  /// No description provided for @aiSetToolPlaylistsDesc.
  ///
  /// In en, this message translates to:
  /// **'Names, song counts and the songs in each playlist'**
  String get aiSetToolPlaylistsDesc;

  /// No description provided for @aiSetToolPlayControl.
  ///
  /// In en, this message translates to:
  /// **'Playback control'**
  String get aiSetToolPlayControl;

  /// No description provided for @aiSetToolPlayControlDesc.
  ///
  /// In en, this message translates to:
  /// **'Play a song'**
  String get aiSetToolPlayControlDesc;

  /// No description provided for @aiSetToolQueueEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit queue'**
  String get aiSetToolQueueEdit;

  /// No description provided for @aiSetToolQueueEditDesc.
  ///
  /// In en, this message translates to:
  /// **'Add, remove'**
  String get aiSetToolQueueEditDesc;

  /// No description provided for @aiSetToolPlaylistCreate.
  ///
  /// In en, this message translates to:
  /// **'Create playlist'**
  String get aiSetToolPlaylistCreate;

  /// No description provided for @aiSetToolPlaylistEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit playlist'**
  String get aiSetToolPlaylistEdit;

  /// No description provided for @aiSetToolPlaylistEditDesc.
  ///
  /// In en, this message translates to:
  /// **'Add, remove songs'**
  String get aiSetToolPlaylistEditDesc;

  /// No description provided for @aiSetVarBypassTitle.
  ///
  /// In en, this message translates to:
  /// **'Send variables even when a tool is off'**
  String get aiSetVarBypassTitle;

  /// No description provided for @aiSetVarBypassDesc.
  ///
  /// In en, this message translates to:
  /// **'Variables and context cards you send yourself still insert data (lyrics, queue, now playing…) even if its tool is off. A tool that is off then only stops the AI from fetching the data by itself.'**
  String get aiSetVarBypassDesc;

  /// No description provided for @aiSetAutoTitleDefault.
  ///
  /// In en, this message translates to:
  /// **'Turn on Automatic for new chats?'**
  String get aiSetAutoTitleDefault;

  /// No description provided for @aiSetAutoTitleConversation.
  ///
  /// In en, this message translates to:
  /// **'Turn on Automatic for this chat?'**
  String get aiSetAutoTitleConversation;

  /// No description provided for @aiSetAutoBody.
  ///
  /// In en, this message translates to:
  /// **'The AI will create and edit playlists, edit the queue and control playback without asking again. Every change still shows as a “Done” card. There is no undo.'**
  String get aiSetAutoBody;

  /// No description provided for @aiSetAutoShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Show this again next time'**
  String get aiSetAutoShowAgain;

  /// No description provided for @aiSetAutoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Turn on Automatic'**
  String get aiSetAutoConfirm;

  /// No description provided for @aiSetAutoToastDefault.
  ///
  /// In en, this message translates to:
  /// **'New chats: Automatic'**
  String get aiSetAutoToastDefault;

  /// No description provided for @aiSetAutoToastConversation.
  ///
  /// In en, this message translates to:
  /// **'This chat: Automatic'**
  String get aiSetAutoToastConversation;

  /// No description provided for @aiSetAutoToastDefaultQuiet.
  ///
  /// In en, this message translates to:
  /// **'New chats: Automatic · will not ask next time (turn it back on in the Confirmation box block)'**
  String get aiSetAutoToastDefaultQuiet;

  /// No description provided for @aiSetAutoToastConversationQuiet.
  ///
  /// In en, this message translates to:
  /// **'This chat: Automatic · will not ask next time (turn it back on in Settings › AI chat)'**
  String get aiSetAutoToastConversationQuiet;

  /// No description provided for @aiSetTemplateExplainLyricsLabel.
  ///
  /// In en, this message translates to:
  /// **'Explain the lyrics'**
  String get aiSetTemplateExplainLyricsLabel;

  /// No description provided for @aiSetTemplateExplainLyricsBody.
  ///
  /// In en, this message translates to:
  /// **'Explain the lyrics of {nowPlaying}: {lyrics}'**
  String aiSetTemplateExplainLyricsBody(String lyrics, String nowPlaying);

  /// No description provided for @aiSetTemplateSimilarSongsLabel.
  ///
  /// In en, this message translates to:
  /// **'Similar songs in my library'**
  String get aiSetTemplateSimilarSongsLabel;

  /// No description provided for @aiSetTemplateSimilarSongsBody.
  ///
  /// In en, this message translates to:
  /// **'Find songs in my library like {nowPlaying}'**
  String aiSetTemplateSimilarSongsBody(String nowPlaying);

  /// No description provided for @aiSetTemplateMoodPlaylistLabel.
  ///
  /// In en, this message translates to:
  /// **'Playlist for a mood'**
  String get aiSetTemplateMoodPlaylistLabel;

  /// No description provided for @aiSetTemplateMoodPlaylistBody.
  ///
  /// In en, this message translates to:
  /// **'Create a playlist for this mood: {input}'**
  String aiSetTemplateMoodPlaylistBody(String input);

  /// No description provided for @aiSetTemplateSongStoryLabel.
  ///
  /// In en, this message translates to:
  /// **'About this song'**
  String get aiSetTemplateSongStoryLabel;

  /// No description provided for @aiSetTemplateSongStoryBody.
  ///
  /// In en, this message translates to:
  /// **'Tell me about {nowPlaying}'**
  String aiSetTemplateSongStoryBody(String nowPlaying);

  /// No description provided for @aiSetTemplateTranslateLyricsLabel.
  ///
  /// In en, this message translates to:
  /// **'Translate the lyrics'**
  String get aiSetTemplateTranslateLyricsLabel;

  /// No description provided for @aiSetTemplateTranslateLyricsBody.
  ///
  /// In en, this message translates to:
  /// **'Translate the lyrics of {nowPlaying} into English: {lyrics}'**
  String aiSetTemplateTranslateLyricsBody(String lyrics, String nowPlaying);

  /// No description provided for @aiSetTemplateTasteSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Summarise my listening'**
  String get aiSetTemplateTasteSummaryLabel;

  /// No description provided for @aiSetTemplateTasteSummaryBody.
  ///
  /// In en, this message translates to:
  /// **'Summarise my listening habits this month'**
  String get aiSetTemplateTasteSummaryBody;

  /// No description provided for @aiSetVarNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing: title and artist'**
  String get aiSetVarNowPlaying;

  /// No description provided for @aiSetVarTitle.
  ///
  /// In en, this message translates to:
  /// **'Title of the playing song'**
  String get aiSetVarTitle;

  /// No description provided for @aiSetVarArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist of the playing song'**
  String get aiSetVarArtist;

  /// No description provided for @aiSetVarAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album of the playing song'**
  String get aiSetVarAlbum;

  /// No description provided for @aiSetVarLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics of the playing song, plain text'**
  String get aiSetVarLyrics;

  /// No description provided for @aiSetVarQueue.
  ///
  /// In en, this message translates to:
  /// **'The queue, up to 50 songs around the playing one'**
  String get aiSetVarQueue;

  /// No description provided for @aiSetVarInput.
  ///
  /// In en, this message translates to:
  /// **'Where you type next: tapping the chip only fills the prompt into the box, with the cursor here'**
  String get aiSetVarInput;

  /// No description provided for @aiSetPromptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Prompt templates'**
  String get aiSetPromptsTitle;

  /// No description provided for @aiSetPromptsHint.
  ///
  /// In en, this message translates to:
  /// **'Shown as chips on the input, in this order. Tap a row to edit.'**
  String get aiSetPromptsHint;

  /// No description provided for @aiSetPromptDrag.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get aiSetPromptDrag;

  /// No description provided for @aiSetPromptSwitch.
  ///
  /// In en, this message translates to:
  /// **'Show “{label}” on the input'**
  String aiSetPromptSwitch(String label);

  /// No description provided for @aiSetPromptTap.
  ///
  /// In en, this message translates to:
  /// **'{label}, open to edit'**
  String aiSetPromptTap(String label);

  /// No description provided for @aiSetPromptBad.
  ///
  /// In en, this message translates to:
  /// **'Broken variable'**
  String get aiSetPromptBad;

  /// No description provided for @aiSetPromptBadLine.
  ///
  /// In en, this message translates to:
  /// **'Variable {variable} no longer exists · tap to edit'**
  String aiSetPromptBadLine(String variable);

  /// No description provided for @aiSetPromptsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No prompts yet: the chat input has no prompt chips. Add a prompt, or restore the built-in ones.'**
  String get aiSetPromptsEmpty;

  /// No description provided for @aiSetPromptAdd.
  ///
  /// In en, this message translates to:
  /// **'Add prompt'**
  String get aiSetPromptAdd;

  /// No description provided for @aiSetPromptRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore default prompts'**
  String get aiSetPromptRestore;

  /// No description provided for @aiSetPromptRestoreDesc.
  ///
  /// In en, this message translates to:
  /// **'Only adds back built-in prompts you deleted; edited and your own prompts stay'**
  String get aiSetPromptRestoreDesc;

  /// No description provided for @aiSetPromptRestored.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Added back {count} built-in prompt} other{Added back {count} built-in prompts}}'**
  String aiSetPromptRestored(int count);

  /// No description provided for @aiSetPromptRestoredNone.
  ///
  /// In en, this message translates to:
  /// **'No built-in prompt was deleted'**
  String get aiSetPromptRestoredNone;

  /// No description provided for @aiSetHistTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat history'**
  String get aiSetHistTitle;

  /// No description provided for @aiSetHistLoading.
  ///
  /// In en, this message translates to:
  /// **'Reading chat history…'**
  String get aiSetHistLoading;

  /// No description provided for @aiSetHistErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not read chat history'**
  String get aiSetHistErrorTitle;

  /// No description provided for @aiSetHistErrorDesc.
  ///
  /// In en, this message translates to:
  /// **'The count and size are not available. Delete all still works.'**
  String get aiSetHistErrorDesc;

  /// No description provided for @aiSetHistRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get aiSetHistRetry;

  /// No description provided for @aiSetHistCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} conversation · {size} MB} other{{count} conversations · {size} MB}}'**
  String aiSetHistCount(int count, String size);

  /// No description provided for @aiSetHistNone.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get aiSetHistNone;

  /// No description provided for @aiSetHistWhere.
  ///
  /// In en, this message translates to:
  /// **'Stored on this device'**
  String get aiSetHistWhere;

  /// No description provided for @aiSetHistClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all conversations'**
  String get aiSetHistClearTitle;

  /// No description provided for @aiSetHistClearDesc.
  ///
  /// In en, this message translates to:
  /// **'Prompt templates and settings stay. Cannot be undone'**
  String get aiSetHistClearDesc;

  /// No description provided for @aiSetHistClearButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get aiSetHistClearButton;

  /// No description provided for @aiSetHistDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all conversations?'**
  String get aiSetHistDialogTitle;

  /// No description provided for @aiSetHistDialogWhat.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} AI conversation} other{{count} AI conversations}}'**
  String aiSetHistDialogWhat(int count);

  /// No description provided for @aiSetHistDialogWhatAll.
  ///
  /// In en, this message translates to:
  /// **'Every AI conversation'**
  String get aiSetHistDialogWhatAll;

  /// No description provided for @aiSetHistDialogRemoved.
  ///
  /// In en, this message translates to:
  /// **'{what} will be deleted from this device.'**
  String aiSetHistDialogRemoved(String what);

  /// No description provided for @aiSetHistDialogStop.
  ///
  /// In en, this message translates to:
  /// **'The answer in progress will stop.'**
  String get aiSetHistDialogStop;

  /// No description provided for @aiSetHistDialogLogs.
  ///
  /// In en, this message translates to:
  /// **'The run logs of the AI services are deleted too. Prompt templates and settings stay.'**
  String get aiSetHistDialogLogs;

  /// No description provided for @aiSetHistDialogUndo.
  ///
  /// In en, this message translates to:
  /// **'Cannot be undone.'**
  String get aiSetHistDialogUndo;

  /// No description provided for @aiSetHistDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get aiSetHistDialogConfirm;

  /// No description provided for @aiSetHistCleared.
  ///
  /// In en, this message translates to:
  /// **'All conversations deleted'**
  String get aiSetHistCleared;

  /// No description provided for @aiSetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation box'**
  String get aiSetConfirmTitle;

  /// No description provided for @aiSetConfirmRow.
  ///
  /// In en, this message translates to:
  /// **'Ask before turning on Automatic'**
  String get aiSetConfirmRow;

  /// No description provided for @aiSetConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'You turned this box off in the chat: choosing Automatic turns it on at once, without asking. Turn it back on to be asked every time.'**
  String get aiSetConfirmDesc;

  /// No description provided for @aiSetConfirmOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get aiSetConfirmOn;

  /// No description provided for @aiSetConfirmToast.
  ///
  /// In en, this message translates to:
  /// **'Choosing Automatic in the chat will ask again'**
  String get aiSetConfirmToast;

  /// No description provided for @aiSetPluginUse.
  ///
  /// In en, this message translates to:
  /// **'Use in AI chat'**
  String get aiSetPluginUse;

  /// No description provided for @aiSetPluginUseDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick it in the chat input; new chats use the service picked last.'**
  String get aiSetPluginUseDesc;

  /// No description provided for @aiSetPluginUseAt.
  ///
  /// In en, this message translates to:
  /// **'Change in Settings › AI chat'**
  String get aiSetPluginUseAt;

  /// No description provided for @aiSetRemoveKeepChats.
  ///
  /// In en, this message translates to:
  /// **'Chats that used this plugin (readable; pick another plugin to continue)'**
  String get aiSetRemoveKeepChats;

  /// No description provided for @aiSetEdTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit prompt'**
  String get aiSetEdTitleEdit;

  /// No description provided for @aiSetEdTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New prompt'**
  String get aiSetEdTitleNew;

  /// No description provided for @aiSetEdLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get aiSetEdLabel;

  /// No description provided for @aiSetEdLabelPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Explain the lyrics'**
  String get aiSetEdLabelPlaceholder;

  /// No description provided for @aiSetEdLabelHelp.
  ///
  /// In en, this message translates to:
  /// **'Text on the chip in the chat input'**
  String get aiSetEdLabelHelp;

  /// No description provided for @aiSetEdBodyTitle.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get aiSetEdBodyTitle;

  /// No description provided for @aiSetEdBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Kanaru fills in variables when sending; with no data it sends nothing and the text stays in the box. {input} is where you type next: tapping a chip with {input} only fills the prompt into the box, with the cursor there. There are no custom variables.'**
  String aiSetEdBodyHint(String input);

  /// No description provided for @aiSetEdBodyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Explain the lyrics of {nowPlaying}: {lyrics}'**
  String aiSetEdBodyPlaceholder(String nowPlaying, String lyrics);

  /// No description provided for @aiSetEdBodyHelp.
  ///
  /// In en, this message translates to:
  /// **'Sent as your own message when you tap the chip in the chat input.'**
  String get aiSetEdBodyHelp;

  /// No description provided for @aiSetEdVars.
  ///
  /// In en, this message translates to:
  /// **'Insert variable'**
  String get aiSetEdVars;

  /// No description provided for @aiSetEdUnknown.
  ///
  /// In en, this message translates to:
  /// **'Variable {names} does not exist. You can use: {allowed}'**
  String aiSetEdUnknown(String names, String allowed);

  /// No description provided for @aiSetEdGroupOff.
  ///
  /// In en, this message translates to:
  /// **'{names} needs the {groups} tool, which is off. You can still save; tapping the chip will not send it until the tool is back on, or turn on “{setting}”.'**
  String aiSetEdGroupOff(String names, String groups, String setting);

  /// No description provided for @aiSetEdGroupOffBypass.
  ///
  /// In en, this message translates to:
  /// **'{names}: the {groups} tool is off, but the variable is still sent because “{setting}” is on.'**
  String aiSetEdGroupOffBypass(String names, String groups, String setting);

  /// No description provided for @aiSetEdPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get aiSetEdPreviewTitle;

  /// No description provided for @aiSetEdPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Filled with sample data (the song Blinding Lights), not the playing song. When you tap the chip, Kanaru fills in the real data when sending.'**
  String get aiSetEdPreviewHint;

  /// No description provided for @aiSetEdPreviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Type the prompt above to preview it.'**
  String get aiSetEdPreviewEmpty;

  /// No description provided for @aiSetEdPreviewUnknown.
  ///
  /// In en, this message translates to:
  /// **'No such variable'**
  String get aiSetEdPreviewUnknown;

  /// No description provided for @aiSetEdPreviewOff.
  ///
  /// In en, this message translates to:
  /// **'{variable} · the “{group}” tool is off'**
  String aiSetEdPreviewOff(String variable, String group);

  /// No description provided for @aiSetEdSampleNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Blinding Lights · The Weeknd'**
  String get aiSetEdSampleNowPlaying;

  /// No description provided for @aiSetEdSampleTitle.
  ///
  /// In en, this message translates to:
  /// **'Blinding Lights'**
  String get aiSetEdSampleTitle;

  /// No description provided for @aiSetEdSampleArtist.
  ///
  /// In en, this message translates to:
  /// **'The Weeknd'**
  String get aiSetEdSampleArtist;

  /// No description provided for @aiSetEdSampleAlbum.
  ///
  /// In en, this message translates to:
  /// **'After Hours'**
  String get aiSetEdSampleAlbum;

  /// No description provided for @aiSetEdSampleLyrics.
  ///
  /// In en, this message translates to:
  /// **'‹lyrics of Blinding Lights · 42 lines›'**
  String get aiSetEdSampleLyrics;

  /// No description provided for @aiSetEdSampleQueue.
  ///
  /// In en, this message translates to:
  /// **'‹queue · 12 songs›'**
  String get aiSetEdSampleQueue;

  /// No description provided for @aiSetEdSampleInput.
  ///
  /// In en, this message translates to:
  /// **'‹what you type›'**
  String get aiSetEdSampleInput;

  /// No description provided for @aiSetEdDeleteRow.
  ///
  /// In en, this message translates to:
  /// **'Delete prompt'**
  String get aiSetEdDeleteRow;

  /// No description provided for @aiSetEdDeleteBuiltinDesc.
  ///
  /// In en, this message translates to:
  /// **'Built-in prompt: “{restore}” adds the original back'**
  String aiSetEdDeleteBuiltinDesc(String restore);

  /// No description provided for @aiSetEdDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the prompt “{label}”?'**
  String aiSetEdDeleteTitle(String label);

  /// No description provided for @aiSetEdDeleteBodyBuiltin.
  ///
  /// In en, this message translates to:
  /// **'This is a built-in prompt: “{restore}” adds the original back, but your edits are lost.'**
  String aiSetEdDeleteBodyBuiltin(String restore);

  /// No description provided for @aiSetEdDeleteBodyCustom.
  ///
  /// In en, this message translates to:
  /// **'The chip of this prompt disappears from the chat input. This cannot be undone.'**
  String get aiSetEdDeleteBodyCustom;

  /// No description provided for @aiSetEdDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get aiSetEdDeleteConfirm;

  /// No description provided for @aiSetEdDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted “{label}”'**
  String aiSetEdDeleted(String label);

  /// No description provided for @aiSetEdSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved “{label}”'**
  String aiSetEdSaved(String label);

  /// No description provided for @aiSetEdCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get aiSetEdCancel;

  /// No description provided for @aiSetEdSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get aiSetEdSave;

  /// No description provided for @aiSetEdDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get aiSetEdDiscardTitle;

  /// No description provided for @aiSetEdDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'The changes to this prompt are not saved.'**
  String get aiSetEdDiscardBody;

  /// No description provided for @aiSetEdDiscardKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get aiSetEdDiscardKeep;

  /// No description provided for @aiSetEdDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get aiSetEdDiscardConfirm;

  /// No description provided for @onlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineTitle;

  /// No description provided for @onlineSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search {source} or paste a link'**
  String onlineSearchTooltip(String source);

  /// No description provided for @onlineNoSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'No online sources yet.'**
  String get onlineNoSourceTitle;

  /// No description provided for @onlineNoSourceMessage.
  ///
  /// In en, this message translates to:
  /// **'Install a music source plugin (Audius, ZingMP3, Radio Browser…) to search and play music online.'**
  String get onlineNoSourceMessage;

  /// No description provided for @onlineAddSource.
  ///
  /// In en, this message translates to:
  /// **'Add a music source'**
  String get onlineAddSource;

  /// No description provided for @onlineOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'No network.'**
  String get onlineOfflineTitle;

  /// No description provided for @onlineOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'Online needs a network. Music on this device still plays from Library.'**
  String get onlineOfflineMessage;

  /// No description provided for @onlineRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get onlineRetry;

  /// No description provided for @onlineRetryIn.
  ///
  /// In en, this message translates to:
  /// **'Retry in {time}'**
  String onlineRetryIn(String time);

  /// No description provided for @onlineServerDownTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not reach {source}.'**
  String onlineServerDownTitle(String source);

  /// No description provided for @onlineServerDownMessage.
  ///
  /// In en, this message translates to:
  /// **'The source\'s server is not answering. Try again in a few minutes.'**
  String get onlineServerDownMessage;

  /// No description provided for @onlineNeedsConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs setting up: {field}'**
  String onlineNeedsConfigTitle(String field);

  /// No description provided for @onlineNeedsConfigMessage.
  ///
  /// In en, this message translates to:
  /// **'{source} needs this field before it can load anything.'**
  String onlineNeedsConfigMessage(String source);

  /// No description provided for @onlineOpenPluginSettings.
  ///
  /// In en, this message translates to:
  /// **'Open plugin settings'**
  String get onlineOpenPluginSettings;

  /// No description provided for @onlineRateLimitedTitle.
  ///
  /// In en, this message translates to:
  /// **'Paused for {length}: the server reported too many requests (429)'**
  String onlineRateLimitedTitle(String length);

  /// No description provided for @onlineRateLimitedMessage.
  ///
  /// In en, this message translates to:
  /// **'Showing what was loaded before.'**
  String get onlineRateLimitedMessage;

  /// No description provided for @onlineInvalidDataTitle.
  ///
  /// In en, this message translates to:
  /// **'{source} returned data Kanaru cannot read'**
  String onlineInvalidDataTitle(String source);

  /// No description provided for @onlineInvalidDataMessage.
  ///
  /// In en, this message translates to:
  /// **'The source\'s site may have changed. A plugin update usually fixes this.'**
  String get onlineInvalidDataMessage;

  /// No description provided for @onlineCheckUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get onlineCheckUpdates;
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
