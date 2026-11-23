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

  /// No description provided for @lyricsTranslateSoon.
  ///
  /// In en, this message translates to:
  /// **'Translate lyrics · Coming soon'**
  String get lyricsTranslateSoon;

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

  /// No description provided for @lyricsSettingsTrTargetApp.
  ///
  /// In en, this message translates to:
  /// **'Follows the app language'**
  String get lyricsSettingsTrTargetApp;

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
  /// **'Plugin {kind} · version {version} · {author}'**
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
  /// **'Plugin for {kind} · plugin API {api}'**
  String pluginsPageTypeValue(String kind, int api);

  /// No description provided for @pluginsPageTypeValueAi.
  ///
  /// In en, this message translates to:
  /// **'AI plugin for {kind} · plugin API {api}'**
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
