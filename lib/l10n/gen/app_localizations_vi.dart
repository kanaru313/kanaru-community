// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navLibrary => 'Thư viện';

  @override
  String get navPlaylists => 'Playlist';

  @override
  String get navSearch => 'Tìm kiếm';

  @override
  String get navOnline => 'Trực tuyến';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get emptyHome => 'Chưa có gì ở đây. Nhạc của bạn sẽ hiện ở đây.';

  @override
  String get emptyLibrary => 'Thư viện đang trống.';

  @override
  String get emptyPlaylists => 'Chưa có playlist nào.';

  @override
  String get emptySearch => 'Tìm trong nhạc của bạn.';

  @override
  String get emptyOnline => 'Chưa có nguồn trực tuyến nào.';

  @override
  String get settingsAbout => 'Giới thiệu';

  @override
  String get settingsNativeVersions => 'Thư viện native';

  @override
  String get settingsNoSections => 'Chưa có cài đặt nào khác.';

  @override
  String get proBadge => 'Pro';

  @override
  String get tooltipToggleSidebar => 'Hiện hoặc ẩn thanh bên';

  @override
  String get tooltipBack => 'Quay lại';

  @override
  String get tooltipForward => 'Tiến tới';

  @override
  String get tooltipHome => 'Trang chủ';

  @override
  String get appComingSoon => 'Sắp có';

  @override
  String get appKeymap => 'Phím tắt';

  @override
  String get appAiChat => 'Trò chuyện AI';

  @override
  String get appSearch => 'Tìm kiếm';

  @override
  String get appRescan => 'Quét lại thư viện';

  @override
  String get scanSetupWelcomeTitle => 'Chào mừng đến Kanaru';

  @override
  String get scanSetupWelcomeSubtitle =>
      'Thiết lập vài thứ cơ bản. Đổi lại được trong Cài đặt bất cứ lúc nào.';

  @override
  String get scanSetupPermissionsTitle => 'Quyền truy cập';

  @override
  String get scanSetupPermissionAudioTitle => 'Nhạc và âm thanh';

  @override
  String get scanSetupPermissionAudioSubtitle =>
      'Tìm và phát bài trong máy, đọc lời .lrc';

  @override
  String get scanSetupPermissionImagesTitle => 'Ảnh và video';

  @override
  String get scanSetupPermissionImagesSubtitle =>
      'Chỉ để đọc ảnh bìa (cover.jpg) trong thư mục nhạc. Kanaru không xem ảnh hay video của bạn.';

  @override
  String get scanSetupPermissionAllowedLabel => 'Đã cấp';

  @override
  String get scanSetupPermissionMissingLabel => 'Chưa cấp';

  @override
  String get scanSetupPermissionsGranted =>
      'Đã cấp đủ quyền · Nhạc và âm thanh · Ảnh và video';

  @override
  String get scanSetupGrant => 'Cấp quyền';

  @override
  String get scanSetupGrantMissing => 'Cấp quyền còn thiếu';

  @override
  String get scanSetupOpenAppSettings => 'Mở cài đặt ứng dụng';

  @override
  String get scanSetupPermissionNote =>
      'Cần cả hai quyền để tiếp tục. Kanaru không xin quyền “Truy cập mọi tệp”.';

  @override
  String get scanSetupPermissionBlockedNote =>
      'Quyền đã bị từ chối nhiều lần nên Android không hỏi lại. Bật cả hai quyền trong Cài đặt › Ứng dụng › Kanaru › Quyền, rồi quay lại đây.';

  @override
  String get scanSetupAudioDenied => 'Cần quyền nhạc để tìm bài trong máy.';

  @override
  String get scanSetupImagesDenied =>
      'Cần quyền ảnh để đọc ảnh bìa trong thư mục.';

  @override
  String get scanSetupImagesLimited =>
      'Chọn một phần ảnh không đọc được cover.jpg: cần “Cho phép tất cả”.';

  @override
  String get scanSetupAppearanceTitle => 'Giao diện';

  @override
  String get scanSetupThemeLabel => 'Chủ đề';

  @override
  String get scanSetupLanguageLabel => 'Ngôn ngữ';

  @override
  String get scanSetupThemeSystem => 'Theo hệ thống';

  @override
  String get scanSetupThemeDark => 'Tối';

  @override
  String get scanSetupThemeLight => 'Sáng';

  @override
  String get scanSetupLanguageVietnamese => 'Tiếng Việt';

  @override
  String get scanSetupLanguageEnglish => 'English';

  @override
  String get scanSetupTabsTitle => 'Tab trong Thư viện';

  @override
  String get scanSetupTabsHint =>
      'Bật tab muốn hiện, kéo để sắp xếp. Ít nhất 1 tab.';

  @override
  String scanSetupTabShow(String tab) {
    return 'Hiện tab $tab';
  }

  @override
  String get scanSetupTabDrag => 'Kéo để sắp xếp';

  @override
  String get scanSetupTabLocked => 'Phải còn ít nhất một tab';

  @override
  String get scanSetupFoldersTitle => 'Thư mục nhạc';

  @override
  String get scanSetupFoldersHint =>
      'Kanaru quét các thư mục này và mọi thư mục con.';

  @override
  String scanSetupFoldersHintCount(int count) {
    return 'Kanaru quét các thư mục này · khoảng $count bài';
  }

  @override
  String get scanSetupFoldersNeedPermission =>
      'Cấp quyền nhạc để thấy các thư mục có nhạc.';

  @override
  String get scanSetupFoldersEmpty => 'Chưa chọn thư mục nào.';

  @override
  String get scanSetupFoldersNoSystemMusic =>
      'Không tìm thấy thư mục Nhạc của hệ thống. Thêm thư mục chứa nhạc của bạn.';

  @override
  String get scanSetupAddFolder => 'Thêm thư mục';

  @override
  String get scanSetupAddFolderDialog => 'Thêm thư mục…';

  @override
  String get scanSetupFolderSuggested => 'Gợi ý';

  @override
  String scanSetupFolderRemove(String name) {
    return 'Bỏ $name';
  }

  @override
  String scanSetupFolderSongs(int count) {
    return '$count bài';
  }

  @override
  String get scanSetupFolderPickerTitle => 'Thêm thư mục nhạc';

  @override
  String get scanSetupFolderPickerHint =>
      'Các thư mục có nhạc mà Android tìm thấy. Nhạc vừa chép vào máy có thể chưa có ở đây cho tới khi Android quét lại.';

  @override
  String get scanSetupFolderPickerEmpty => 'Đã chọn mọi thư mục có nhạc.';

  @override
  String get scanSetupFolderSheetLoading => 'Đang tìm thư mục có nhạc…';

  @override
  String get scanSetupNoMusicTitle => 'Android chưa thấy bài nhạc nào';

  @override
  String get scanSetupNoMusicBody =>
      'Nhạc vừa chép vào máy thường chưa hiện cho tới khi Android quét lại.';

  @override
  String get scanSetupNoMusicCard =>
      'Android chưa thấy bài nhạc nào trong máy. Nhạc vừa chép vào thường chưa hiện cho tới khi Android quét lại.';

  @override
  String get scanSetupRescan => 'Quét lại';

  @override
  String get scanSetupRescanRow => 'Không thấy thư mục của bạn? Quét lại';

  @override
  String get scanSetupRescanning => 'Đang quét lại…';

  @override
  String get scanSetupRescanningBody =>
      'Android đang tìm nhạc trong các thư mục của bộ nhớ trong và thẻ nhớ (Music, Download trước).';

  @override
  String get scanSetupRescanningSheetNote =>
      'Đóng sheet thì Android vẫn quét tiếp.';

  @override
  String scanSetupRescanDone(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Đã quét lại · Android thấy $countString bài.';
  }

  @override
  String get scanSetupStillNoMusicTitle => 'Vẫn chưa thấy bài nhạc nào';

  @override
  String get scanSetupStillNoMusicBody =>
      'Android đã quét lại nhưng không thấy tệp nhạc.';

  @override
  String get scanSetupStillNoMusicTipShared =>
      'Nhạc phải nằm trong bộ nhớ chung (ví dụ Music, Download), không nằm trong Android › data của ứng dụng khác.';

  @override
  String get scanSetupStillNoMusicTipRestart =>
      'Khởi động lại điện thoại để Android quét lại toàn bộ bộ nhớ, rồi mở lại Kanaru.';

  @override
  String get scanSetupStillNoMusicCard => 'Android vẫn chưa thấy bài nhạc nào.';

  @override
  String get scanSetupRescanFailed => 'Không quét lại được.';

  @override
  String get scanSetupFolderListFailedTitle =>
      'Không tải được danh sách thư mục';

  @override
  String get scanSetupFolderListFailedBody =>
      'Android không trả lời kịp hoặc báo lỗi.';

  @override
  String get scanSetupExclusionSheetLoading => 'Đang tìm thư mục con…';

  @override
  String get scanSetupExclusionListFailed =>
      'Không tải được danh sách thư mục con';

  @override
  String get scanSetupSheetAdd => 'Thêm';

  @override
  String scanSetupSheetAddCount(int count) {
    return 'Thêm $count';
  }

  @override
  String get scanSetupSheetCancel => 'Huỷ';

  @override
  String get scanSetupSheetSelectAll => 'Chọn tất cả';

  @override
  String scanSetupSheetSelectedCount(int count, int total) {
    return '$count / $total thư mục';
  }

  @override
  String get scanSetupExclusionsTitle => 'Loại trừ';

  @override
  String get scanSetupExclusionsHint =>
      'Bỏ qua các thư mục con này khi quét (nhạc chuông, ghi âm…).';

  @override
  String get scanSetupExclusionsEmpty => 'Không loại trừ thư mục nào.';

  @override
  String get scanSetupAddExclusion => 'Thêm thư mục loại trừ';

  @override
  String get scanSetupAddExclusionDialog => 'Thêm thư mục loại trừ…';

  @override
  String get scanSetupExclusionPickerTitle => 'Loại trừ thư mục';

  @override
  String get scanSetupExclusionPickerHint =>
      'Thư mục con có nhạc mà Android đã thấy, trong các thư mục nhạc đã chọn.';

  @override
  String get scanSetupExclusionPickerEmpty =>
      'Không có thư mục con nào để loại trừ.';

  @override
  String scanSetupRefusedAlreadyChosen(String folder) {
    return '“$folder” đã được chọn.';
  }

  @override
  String scanSetupRefusedInside(String folder, String root) {
    return '“$folder” đã nằm trong “$root”.';
  }

  @override
  String scanSetupRefusedContains(String folder, String root) {
    return '“$folder” chứa “$root” đã chọn.';
  }

  @override
  String scanSetupRefusedTooBroad(String folder) {
    return '“$folder” quá rộng để quét.';
  }

  @override
  String scanSetupRefusedNotFolder(String folder) {
    return '“$folder” không phải thư mục.';
  }

  @override
  String scanSetupRefusedOutside(String folder) {
    return '“$folder” không nằm trong thư mục nhạc nào.';
  }

  @override
  String scanSetupRefusedAlreadyExcluded(String folder) {
    return '“$folder” đã được loại trừ.';
  }

  @override
  String get scanSetupWriteFailed => 'Không lưu được thay đổi này. Thử lại.';

  @override
  String get scanSetupNext => 'Tiếp tục';

  @override
  String get scanSetupNextDisabled => 'Thêm ít nhất một thư mục nhạc';

  @override
  String get scanSetupLoadFailed => 'Không tải được mục này.';

  @override
  String get scanSetupRetry => 'Thử lại';

  @override
  String get scanVolumeInternal => 'Bộ nhớ trong';

  @override
  String get scanVolumeSdCard => 'Thẻ nhớ';

  @override
  String get scanVolumeUsb => 'USB';

  @override
  String get scanHomeScanning => 'Đang quét thư viện';

  @override
  String scanHomeProgress(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Đọc tag và ảnh bìa · $doneString / $totalString bài';
  }

  @override
  String scanHomeAdded(int added) {
    final intl.NumberFormat addedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String addedString = addedNumberFormat.format(added);

    return 'Đã thêm $addedString bài';
  }

  @override
  String scanHomeAddedDetail(int albums, int artists) {
    final intl.NumberFormat albumsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String albumsString = albumsNumberFormat.format(albums);
    final intl.NumberFormat artistsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String artistsString = artistsNumberFormat.format(artists);

    return '$albumsString album · $artistsString nghệ sĩ';
  }

  @override
  String get scanHomeNoTracks => 'Không tìm thấy bài nào';

  @override
  String get playbackCover => 'Ảnh bìa';

  @override
  String get playbackNavQueue => 'Hàng đợi';

  @override
  String get playbackPlay => 'Phát';

  @override
  String get playbackPause => 'Tạm dừng';

  @override
  String get playbackNext => 'Bài tiếp';

  @override
  String get playbackPrevious => 'Bài trước';

  @override
  String get playbackShuffle => 'Trộn bài';

  @override
  String get playbackRepeatOff => 'Dừng ở cuối';

  @override
  String get playbackRepeatOne => 'Lặp bài này';

  @override
  String playbackRepeatTimes(int count) {
    return 'Lặp bài này thêm $count lần';
  }

  @override
  String get playbackRepeatAll => 'Lặp cả hàng đợi';

  @override
  String get playbackRepeatAllShuffled => 'Lặp cả hàng đợi, trộn lại mỗi lượt';

  @override
  String get playbackRepeatFewer => 'Bớt một lần';

  @override
  String get playbackRepeatMore => 'Thêm một lần';

  @override
  String get playbackFavoriteAdd => 'Thêm vào yêu thích';

  @override
  String get playbackFavoriteRemove => 'Bỏ khỏi yêu thích';

  @override
  String get playbackSleepTimer => 'Hẹn giờ ngủ';

  @override
  String get playbackLyrics => 'Lời bài';

  @override
  String get playbackVolume => 'Âm lượng';

  @override
  String get playbackMute => 'Tắt tiếng';

  @override
  String get playbackUnmute => 'Bật tiếng';

  @override
  String get playbackExpand => 'Mở Now Playing';

  @override
  String get playbackOpenNowPlaying => 'Mở Now Playing';

  @override
  String get playbackPlayer => 'Trình phát';

  @override
  String get playbackSeek => 'Vị trí phát';

  @override
  String playbackPositionValue(String position, String duration) {
    return '$position trên $duration';
  }

  @override
  String playbackNoticeSkipped(String title) {
    return 'Bỏ qua “$title”: tệp không còn';
  }

  @override
  String playbackNoticeSkippedMany(String title, String others) {
    return 'Bỏ qua “$title” và $others bài nữa: tệp không còn';
  }

  @override
  String playbackNoticeFailed(String title) {
    return 'Không phát được “$title”';
  }

  @override
  String get playbackStopAndClear => 'Dừng phát';

  @override
  String get playbackStoppedAnnouncement => 'Đã dừng phát';

  @override
  String get playbackNoticeFirstTrack => 'Đây là bài đầu';

  @override
  String get playbackNoticeQueueEnd => 'Hết hàng đợi';

  @override
  String get playbackNoticeQueueEmpty => 'Hàng đợi trống';

  @override
  String get playbackNoticeFocusDenied =>
      'Không phát được: ứng dụng khác đang dùng âm thanh';

  @override
  String get playbackSidebarOpen => 'Menu';

  @override
  String get playbackSidebarClose => 'Đóng menu';

  @override
  String playbackQueueMobileCounts(int position, int total, String remaining) {
    return '$position/$total · còn $remaining';
  }

  @override
  String playbackRemainingHoursMinutes(int hours, int minutes) {
    return '$hours giờ $minutes phút';
  }

  @override
  String playbackRemainingMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String get playbackRemainingUnderMinute => 'dưới 1 phút';

  @override
  String get playbackMore => 'Thêm';

  @override
  String get playbackNowPlaying => 'Đang phát';

  @override
  String get playbackMinimize => 'Thu nhỏ';

  @override
  String get playbackQueueSelectMany => 'Chọn nhiều';

  @override
  String get playbackQueueAddTracks => 'Thêm bài';

  @override
  String get playbackQueueCleanup => 'Dọn dẹp';

  @override
  String get playbackQueueSavePlaylist => 'Lưu thành playlist';

  @override
  String get playbackQueueCleanupTitle => 'Bỏ khỏi hàng đợi';

  @override
  String get playbackCleanupDuplicates => 'Bài hát trùng lặp';

  @override
  String get playbackCleanupBefore => 'Bài trước đó';

  @override
  String get playbackCleanupAfter => 'Bài sau đó';

  @override
  String get playbackCleanupAll => 'Tất cả (trừ bài đang phát)';

  @override
  String get playbackQueueLocate => 'Về bài đang phát';

  @override
  String get playbackQueueReorder => 'Kéo để đổi thứ tự';

  @override
  String playbackQueueRemovedOne(String title) {
    return 'Đã bỏ “$title”';
  }

  @override
  String playbackQueueRemovedMany(int count) {
    return 'Đã bỏ $count bài';
  }

  @override
  String get playbackUndo => 'Hoàn tác';

  @override
  String get playbackRowPlay => 'Phát bài này';

  @override
  String get playbackRowPlayNext => 'Phát tiếp theo';

  @override
  String get playbackGoAlbum => 'Đến album';

  @override
  String get playbackGoArtist => 'Đến nghệ sĩ';

  @override
  String get playbackAskAi => 'Hỏi AI';

  @override
  String get playbackRemoveFromQueue => 'Bỏ khỏi hàng đợi';

  @override
  String get playbackQueueStale => 'Bài này không còn trong hàng đợi';

  @override
  String get playbackPickArtist => 'Chọn nghệ sĩ';

  @override
  String get playbackLyricsCard => 'Lời bài hát';

  @override
  String get playbackAddToPlaylist => 'Thêm vào playlist';

  @override
  String get playbackLyricsSource => 'Nguồn lời bài';

  @override
  String get playbackTranslateLyrics => 'Dịch lời…';

  @override
  String get playbackVisualEffects => 'Hiệu ứng hình ảnh';

  @override
  String get playbackTrackInfo => 'Thông tin bài';

  @override
  String playbackInfoPlays(int count) {
    return '$count lượt nghe';
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
  String get playbackToggleCoverColumn => 'Ẩn/hiện cột bìa';

  @override
  String get playbackTranslate => 'Dịch';

  @override
  String get playbackTabLyrics => 'Lời bài';

  @override
  String get playbackLyricsTabSoon => 'Lời bài: sắp có';

  @override
  String get playbackPanelClose => 'Đóng khung';

  @override
  String playbackQueuePanelCounts(int total, String remaining) {
    return '$total bài · còn $remaining';
  }

  @override
  String playbackQueuePanelShort(int total) {
    return '$total bài';
  }

  @override
  String playbackQueuePlayingAt(int position) {
    return 'Đang phát bài $position';
  }

  @override
  String get playbackQueueEmpty => 'Hàng đợi trống';

  @override
  String get libraryTabSongs => 'Bài hát';

  @override
  String get libraryTabAlbums => 'Album';

  @override
  String get libraryShelfSeeAll => 'Xem tất cả';

  @override
  String get libraryTabArtists => 'Nghệ sĩ';

  @override
  String get libraryTabGenres => 'Thể loại';

  @override
  String get libraryTabLanguages => 'Ngôn ngữ';

  @override
  String get libraryTabFolders => 'Thư mục';

  @override
  String get libraryNavFavorites => 'Yêu thích';

  @override
  String get libraryNavHistory => 'Lịch sử';

  @override
  String get libraryNavMostPlayed => 'Phát nhiều nhất';

  @override
  String librarySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài',
    );
    return '$_temp0';
  }

  @override
  String libraryAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count album',
    );
    return '$_temp0';
  }

  @override
  String libraryArtistCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nghệ sĩ',
    );
    return '$_temp0';
  }

  @override
  String libraryGenreCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thể loại',
    );
    return '$_temp0';
  }

  @override
  String libraryLanguageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngôn ngữ',
    );
    return '$_temp0';
  }

  @override
  String libraryFolderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thư mục',
    );
    return '$_temp0';
  }

  @override
  String libraryCountOf(int shown, int total, String unit) {
    return '$shown / $total $unit';
  }

  @override
  String get libraryUnitSongs => 'bài';

  @override
  String get libraryUnitAlbums => 'album';

  @override
  String get libraryUnitArtists => 'nghệ sĩ';

  @override
  String get libraryUnitGenres => 'thể loại';

  @override
  String get libraryUnitLanguages => 'ngôn ngữ';

  @override
  String get libraryUnitFolders => 'thư mục';

  @override
  String get libraryPlayAll => 'Phát tất cả';

  @override
  String get libraryShuffle => 'Phát ngẫu nhiên';

  @override
  String get libraryPlayAlbum => 'Phát cả album';

  @override
  String get libraryPlayArtist => 'Phát mọi bài';

  @override
  String get libraryFilter => 'Lọc';

  @override
  String get libraryFilterClose => 'Đóng ô lọc';

  @override
  String get libraryFilterSongsHint => 'Lọc bài hát';

  @override
  String get libraryFilterAlbumsHint => 'Lọc album';

  @override
  String get libraryFilterArtistsHint => 'Lọc nghệ sĩ';

  @override
  String get libraryFilterGenresHint => 'Lọc thể loại';

  @override
  String get libraryFilterLanguagesHint => 'Lọc ngôn ngữ';

  @override
  String get libraryFilterFoldersHint => 'Lọc trong thư mục này';

  @override
  String get libraryOrderTooltip => 'Sắp xếp';

  @override
  String get libraryOrderAscText => 'A → Z';

  @override
  String get libraryOrderDescText => 'Z → A';

  @override
  String get libraryOrderAscNumber => 'Tăng dần';

  @override
  String get libraryOrderDescNumber => 'Giảm dần';

  @override
  String get librarySortDialogTitle => 'Sắp xếp theo';

  @override
  String get librarySortChosen => 'Đã chọn';

  @override
  String get librarySortNotChosen => 'Chưa chọn';

  @override
  String get librarySortReset => 'Đặt lại';

  @override
  String get librarySortDone => 'Xong';

  @override
  String get libraryOrderReverse => 'Đảo thứ tự';

  @override
  String librarySortDragHint(String label) {
    return 'Kéo để đổi thứ tự $label';
  }

  @override
  String librarySortFlipTooltip(String word) {
    return 'Đổi chiều: $word';
  }

  @override
  String librarySortFlipSemantics(String label, String word) {
    return '$label: $word, bấm để đổi chiều';
  }

  @override
  String librarySortRemove(String label) {
    return 'Bỏ $label';
  }

  @override
  String librarySortAdd(String label) {
    return 'Thêm $label';
  }

  @override
  String get libraryOrderOldFirst => 'Cũ trước';

  @override
  String get libraryOrderNewFirst => 'Mới trước';

  @override
  String get libraryOrderFirstToLast => 'Đầu → cuối';

  @override
  String get libraryOrderLastToFirst => 'Cuối → đầu';

  @override
  String librarySortMore(String label, int count) {
    return '$label +$count';
  }

  @override
  String get librarySortAdvanced => 'Nâng cao…';

  @override
  String get librarySortTitle => 'Tên';

  @override
  String get librarySortArtist => 'Nghệ sĩ';

  @override
  String get librarySortAlbum => 'Album';

  @override
  String get librarySortYear => 'Năm';

  @override
  String get librarySortDateAdded => 'Ngày thêm';

  @override
  String get librarySortPlayCount => 'Lượt nghe';

  @override
  String get librarySortDuration => 'Thời lượng';

  @override
  String get librarySortTrackCount => 'Số bài';

  @override
  String get librarySortAlbumCount => 'Số album';

  @override
  String get librarySortTrackNumber => 'Số thứ tự';

  @override
  String get librarySortName => 'Tên';

  @override
  String get librarySortDateModified => 'Ngày sửa';

  @override
  String get librarySortPlaylistOrder => 'Thứ tự playlist';

  @override
  String get libraryViewGrid => 'Chế độ lưới';

  @override
  String get libraryViewList => 'Chế độ danh sách';

  @override
  String get libraryViewTree => 'Chế độ cây thư mục';

  @override
  String get libraryViewFlat => 'Chế độ liệt kê';

  @override
  String get libraryScanning => 'Đang quét…';

  @override
  String libraryScanningTags(int done, int total) {
    return 'Đang quét · $done / $total bài';
  }

  @override
  String libraryScanningTagsCount(int done) {
    return 'Đang quét · $done bài';
  }

  @override
  String libraryScanningCovers(int done, int total) {
    return 'Đang lấy ảnh bìa · $done / $total';
  }

  @override
  String get libraryScanningCoversStart => 'Đang lấy ảnh bìa…';

  @override
  String get libraryEmptyTitle => 'Thư viện trống';

  @override
  String get libraryEmptyMessage =>
      'Không có bài nào trong các thư mục đã chọn.';

  @override
  String get libraryChooseFolders => 'Chọn thư mục nhạc';

  @override
  String get libraryPlayFailed => 'Không phát được';

  @override
  String get libraryNothingToPlay => 'Không có bài để phát';

  @override
  String get libraryLoadFailed => 'Không tải được danh sách';

  @override
  String get libraryNowPlaying => 'Đang phát';

  @override
  String get libraryFavoriteAdd => 'Thêm vào Yêu thích';

  @override
  String get libraryFavoriteRemove => 'Bỏ khỏi Yêu thích';

  @override
  String get libraryFavoriteFailed => 'Không đổi được Yêu thích';

  @override
  String get libraryFavoriteLabel => 'Yêu thích';

  @override
  String libraryDurationMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String libraryDurationHours(int hours) {
    return '$hours giờ';
  }

  @override
  String get librarySelectionGone => 'Các bài đã chọn không còn trong thư viện';

  @override
  String libraryDurationHoursMinutes(int hours, int minutes) {
    return '$hours giờ $minutes phút';
  }

  @override
  String libraryAlbumStats(int songs, int minutes) {
    return '$songs bài • $minutes phút';
  }

  @override
  String get libraryLanguageUnknown => 'Chưa rõ';

  @override
  String get libraryLanguagesNote =>
      'Lấy từ tag ngôn ngữ của bài; bài không có tag thì Kanaru tự nhận diện. Đổi trong Cài đặt › Thư viện.';

  @override
  String get libraryFoldersAll => 'Tất cả thư mục';

  @override
  String get libraryFoldersHidden => 'Các cấp bị ẩn';

  @override
  String get libraryGoToFolder => 'Đi tới thư mục';

  @override
  String get libraryVolumeInternal => 'Bộ nhớ trong';

  @override
  String get libraryVolumeSdCard => 'Thẻ SD';

  @override
  String get libraryVolumeUsb => 'Ổ USB';

  @override
  String libraryFolderCounts(int songs, int folders) {
    return '$songs bài · $folders thư mục';
  }

  @override
  String libraryFolderSongsHeader(int count) {
    return 'Bài trong thư mục này · $count';
  }

  @override
  String libraryFlatSongsHeader(int count) {
    return '$count bài trong thư mục này (không gồm thư mục con)';
  }

  @override
  String get libraryRetry => 'Thử lại';

  @override
  String get libraryPermissionMissing => 'Thiếu quyền đọc nhạc';

  @override
  String get libraryGrantPermission => 'Cấp quyền';

  @override
  String get libraryNotFoundTitle => 'Không tìm thấy';

  @override
  String get libraryNotFoundMessage => 'Mục này không còn trong thư viện.';

  @override
  String get libraryPlay => 'Phát';

  @override
  String get libraryAppearsIn => 'Xuất hiện trong';

  @override
  String libraryAlbumsOf(String name) {
    return 'Album · $name';
  }

  @override
  String libraryArtistsOf(String name) {
    return 'Nghệ sĩ · $name';
  }

  @override
  String libraryAppearsInOf(String name) {
    return 'Xuất hiện trong · $name';
  }

  @override
  String libraryAppearsInAlbumCount(int count) {
    return 'Xuất hiện trong $count album';
  }

  @override
  String get libraryLanguageNoTag => 'Không có tag ngôn ngữ';

  @override
  String get libraryShowMore => 'Xem thêm';

  @override
  String get libraryShowLess => 'Thu gọn';

  @override
  String get libraryLanguageUnknownNote =>
      'Các bài này không có tag ngôn ngữ và Kanaru không nhận diện được (thường là nhạc không lời). Thêm tag ngôn ngữ trong Sửa thông tin bài, hoặc đổi cách nhận diện trong Cài đặt › Thư viện.';

  @override
  String get libraryMenuGoAlbum => 'Đi tới album';

  @override
  String get libraryMenuGoArtist => 'Đi tới nghệ sĩ';

  @override
  String get libraryMenuGoAlbumArtist => 'Đi tới nghệ sĩ album';

  @override
  String get libraryMenuGoGenre => 'Đi tới thể loại';

  @override
  String get libraryMenuGoLanguage => 'Đi tới ngôn ngữ';

  @override
  String get libraryMenuGoFolder => 'Đi tới thư mục';

  @override
  String get libraryMenuReveal => 'Mở trong trình quản lý tệp';

  @override
  String get libraryMenuNoAlbum => 'Không có album';

  @override
  String get libraryMenuNoArtist => 'Không có nghệ sĩ';

  @override
  String libraryMenuAppearsCount(int count) {
    return 'xuất hiện trong $count';
  }

  @override
  String libraryMenuSongsInFolders(int songs, int folders) {
    return '$songs bài trong $folders thư mục';
  }

  @override
  String libraryMenuFoldersOf(String name) {
    return 'Thư mục · $name';
  }

  @override
  String libraryMenuFoldersIntroAlbum(int count) {
    return 'Các bài của album này được lưu trong $count thư mục. Chọn một thư mục để mở trong mục Thư mục.';
  }

  @override
  String libraryMenuFoldersIntroArtist(int count) {
    return 'Các bài của nghệ sĩ này được lưu trong $count thư mục. Chọn một thư mục để mở trong mục Thư mục.';
  }

  @override
  String libraryMenuFoldersIntroGenre(int count) {
    return 'Các bài hát thuộc thể loại này được lưu trong $count thư mục. Chọn một thư mục để mở trong mục Thư mục.';
  }

  @override
  String libraryMenuFoldersIntroLanguage(int count) {
    return 'Các bài của ngôn ngữ này được lưu trong $count thư mục. Chọn một thư mục để mở trong mục Thư mục.';
  }

  @override
  String get libraryMenuAddToPlaylist => 'Thêm vào playlist…';

  @override
  String get libraryMenuFavoriteAll => 'Thêm tất cả vào Yêu thích';

  @override
  String get libraryMenuEditSong => 'Sửa thông tin bài';

  @override
  String get libraryMenuEditAlbum => 'Sửa thông tin album';

  @override
  String get libraryMenuSelect => 'Chọn';

  @override
  String get libraryMenuDeselect => 'Bỏ chọn';

  @override
  String get libraryMenuAskAiSong => 'Hỏi AI về bài này';

  @override
  String get libraryMenuAskAiAlbum => 'Hỏi AI về album này';

  @override
  String get libraryMenuAskAiArtist => 'Hỏi AI về nghệ sĩ này';

  @override
  String get libraryMenuAskAiSongs => 'Hỏi AI về các bài này';

  @override
  String get libraryMenuAdvanced => 'Nâng cao';

  @override
  String get libraryMenuFindLyrics => 'Tìm lời online…';

  @override
  String get libraryMenuHide => 'Loại khỏi thư viện';

  @override
  String get libraryMenuHideNote =>
      'Giữ nguyên tệp; bỏ loại trong Cài đặt › Thư viện';

  @override
  String get libraryMenuDeleteFiles => 'Xoá tệp khỏi thiết bị';

  @override
  String get libraryMenuMoveToTrash => 'Chuyển tệp vào Thùng rác';

  @override
  String libraryMenuFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp',
    );
    return '$_temp0';
  }

  @override
  String get libraryMenuSplitArtists => 'Tách hoặc gộp nghệ sĩ';

  @override
  String get libraryMenuSplitArtistsNote =>
      'Coi một tên là hai nghệ sĩ, hoặc gộp các cách viết';

  @override
  String get libraryMenuSplitGenres => 'Tách hoặc gộp thể loại';

  @override
  String get libraryMenuSplitGenresNote =>
      'Tách thể loại ghép trong tag, hoặc gộp các cách viết';

  @override
  String get libraryMenuLanguageDetection => 'Cách nhận diện ngôn ngữ';

  @override
  String get libraryMenuLanguageDetectionNote => 'Cài đặt › Thư viện';

  @override
  String get libraryMenuCopyPath => 'Sao chép đường dẫn';

  @override
  String get libraryMenuExclude => 'Loại trừ khỏi thư viện';

  @override
  String get libraryMenuExcludeNote =>
      'Giữ nguyên tệp; bỏ loại trong Cài đặt › Thư viện › Thư mục';

  @override
  String get libraryMenuIncludesSubfolders => 'Gồm thư mục con';

  @override
  String get libraryMenuPlayDirect => 'Chỉ phát bài trong thư mục này';

  @override
  String libraryMenuPlayDirectNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài',
    );
    return '$_temp0, không gồm thư mục con';
  }

  @override
  String libraryMenuSelectionTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài đã chọn',
    );
    return '$_temp0';
  }

  @override
  String get libraryMenuMore => 'Tùy chọn khác';

  @override
  String get libraryMenuBack => 'Quay lại';

  @override
  String get libraryMenuPlayNext => 'Phát tiếp theo';

  @override
  String get libraryMenuAddToQueue => 'Thêm vào hàng đợi';

  @override
  String get libraryMenuPlayingNext => 'Sẽ phát tiếp theo';

  @override
  String get libraryMenuQueued => 'Đã thêm vào hàng đợi';

  @override
  String get libraryMenuQueueFailed => 'Không đổi được hàng đợi';

  @override
  String libraryMenuExcluded(String name) {
    return 'Đã loại trừ “$name” khỏi thư viện';
  }

  @override
  String get libraryMenuUndo => 'Hoàn tác';

  @override
  String get libraryMenuExcludeFailed => 'Không loại trừ được thư mục';

  @override
  String get libraryMenuUndoFailed => 'Không hoàn tác được';

  @override
  String get libraryMenuPathCopied => 'Đã chép đường dẫn';

  @override
  String get libraryMenuRevealFailed => 'Không mở được trình quản lý tệp';

  @override
  String get libraryMenuLoadFailed => 'Không mở được menu';

  @override
  String get libraryMenuSongInfo => 'Thông tin bài';

  @override
  String get libraryInfoFormat => 'Định dạng';

  @override
  String get libraryInfoBitrate => 'Bitrate';

  @override
  String libraryInfoBitrateValue(int kbps) {
    return '$kbps kbps';
  }

  @override
  String get libraryInfoSampleRate => 'Tần số lấy mẫu';

  @override
  String libraryInfoSampleRateValue(String khz) {
    return '$khz kHz';
  }

  @override
  String get libraryInfoBitDepth => 'Độ sâu bit';

  @override
  String libraryInfoBitDepthValue(int bits) {
    return '$bits-bit';
  }

  @override
  String get libraryInfoSize => 'Kích thước';

  @override
  String get libraryInfoPath => 'Tệp';

  @override
  String get libraryInfoPlayCount => 'Số lần nghe';

  @override
  String get libraryInfoUnknown => 'Không rõ';

  @override
  String get libraryPanelLabel => 'Các bài đã chọn';

  @override
  String get libraryPanelClear => 'Bỏ chọn tất cả';

  @override
  String get libraryPanelPlayAll => 'Phát tất cả bài đã chọn';

  @override
  String get libraryPanelEdit => 'Sửa thông tin';

  @override
  String get libraryPanelAddToPlaylist => 'Thêm vào playlist…';

  @override
  String get libraryPanelMore => 'Tùy chọn cho các bài đã chọn';

  @override
  String get libraryPanelSelectAll => 'Chọn tất cả bài ở màn này';

  @override
  String get libraryPanelExpand => 'Mở danh sách đã chọn';

  @override
  String get libraryPanelCollapse => 'Thu gọn';

  @override
  String get libraryPanelReorder => 'Kéo để đổi thứ tự phát';

  @override
  String get libraryMenuCopyFailed => 'Không sao chép được';

  @override
  String get libraryActionFailed => 'Không thực hiện được thao tác';

  @override
  String get playlistFavoritesName => 'Yêu thích';

  @override
  String get playlistDefaultName => 'Playlist mới';

  @override
  String playlistCopyName(String name) {
    return '$name (bản sao)';
  }

  @override
  String playlistFavoritesCopyName(String date) {
    return 'Yêu thích ($date)';
  }

  @override
  String get playlistYours => 'Playlist của bạn';

  @override
  String playlistCount(int count) {
    return '$count playlist';
  }

  @override
  String playlistTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài',
      zero: 'Trống',
    );
    return '$_temp0';
  }

  @override
  String playlistEditedOn(String date) {
    return 'Sửa $date';
  }

  @override
  String get playlistFilterHint => 'Lọc playlist';

  @override
  String get playlistFilterNoMatch => 'Không có playlist nào khớp.';

  @override
  String get playlistsEmptyTitle => 'Chưa có playlist';

  @override
  String get playlistsEmptyMessage =>
      'Tạo playlist để giữ bài theo thứ tự của riêng bạn, hoặc nhập một tệp M3U.';

  @override
  String get playlistCreateAction => 'Tạo playlist';

  @override
  String get playlistImportM3uAction => 'Nhập tệp M3U…';

  @override
  String get playlistFavoritesSubtitle => 'Bài bạn bấm ♥';

  @override
  String get playlistHubStats => 'Thống kê';

  @override
  String get playlistFabOpen => 'Tạo';

  @override
  String get playlistFabClose => 'Đóng';

  @override
  String get playlistFabNew => 'Playlist mới';

  @override
  String get playlistFabImport => 'Nhập tệp M3U';

  @override
  String get playlistFabSmart => 'Smart playlist';

  @override
  String get playlistFilterSongsNoMatch => 'Không có bài nào khớp.';

  @override
  String get playlistDragHandle => 'Kéo để đổi thứ tự';

  @override
  String get playlistNotInLibrary => 'Không có trong thư viện';

  @override
  String playlistUnavailableNote(int count) {
    return '$count bài không có trong thư viện: hiện mờ và được bỏ qua khi phát.';
  }

  @override
  String playlistRemoveUnavailableAction(int count) {
    return 'Bỏ $count bài';
  }

  @override
  String get playlistEmptyTitle => 'Playlist trống';

  @override
  String get playlistEmptyMessage =>
      'Thêm bài từ menu của bất kỳ bài, album hay nghệ sĩ nào (Thêm vào playlist…), hoặc chọn nhiều bài rồi thêm một lần.';

  @override
  String get playlistFavoritesEmptyTitle => 'Chưa có bài yêu thích';

  @override
  String get playlistFavoritesEmptyMessage =>
      'Bấm ♥ trên một bài để thêm vào đây.';

  @override
  String get playlistNotFoundTitle => 'Không tìm thấy playlist';

  @override
  String get playlistNotFoundMessage => 'Có thể nó đã bị xoá.';

  @override
  String get playlistSaveFailed => 'Không lưu được playlist';

  @override
  String get playlistMenuGoTo => 'Đi tới playlist';

  @override
  String get playlistMenuGoToFavorites => 'Đi tới Yêu thích';

  @override
  String get playlistMenuCopyTo => 'Thêm vào playlist…';

  @override
  String playlistMenuCopyToHint(int count) {
    return 'Chép $count bài sang playlist khác.';
  }

  @override
  String get playlistMenuAskAi => 'Hỏi AI về playlist này';

  @override
  String get playlistMenuEdit => 'Sửa playlist';

  @override
  String get playlistMenuEditHint => 'Đổi tên, mô tả và ảnh bìa.';

  @override
  String get playlistMenuChangeCover => 'Đổi ảnh playlist';

  @override
  String get playlistMenuDelete => 'Xoá playlist';

  @override
  String get playlistMenuDeleteHint => 'Tệp nhạc giữ nguyên';

  @override
  String get playlistMenuDuplicate => 'Nhân bản playlist';

  @override
  String get playlistMenuExportM3u => 'Xuất tệp M3U…';

  @override
  String get playlistMenuExportM3uHint => 'Đường dẫn tuyệt đối';

  @override
  String get playlistMenuExportM3uRelative => 'Xuất M3U, đường dẫn tương đối…';

  @override
  String get playlistMenuExportM3uRelativeHint =>
      'Để tệp .m3u8 cạnh thư mục nhạc: chép cả thư mục sang máy khác vẫn mở được.';

  @override
  String get playlistMenuRemoveDuplicates => 'Bỏ bài trùng';

  @override
  String playlistMenuRemoveDuplicatesHint(int count) {
    return '$count bài lặp lại · giữ lần đầu';
  }

  @override
  String get playlistMenuRemoveUnavailable => 'Bỏ bài không còn tệp';

  @override
  String playlistMenuRemoveUnavailableHint(int count) {
    return '$count bài không có trong thư viện';
  }

  @override
  String get playlistMenuSaveAs => 'Lưu thành playlist';

  @override
  String get playlistMenuClearFavorites => 'Bỏ hết khỏi Yêu thích';

  @override
  String playlistMenuClearFavoritesHint(int count) {
    return '$count bài · tệp nhạc giữ nguyên';
  }

  @override
  String get playlistMenuMoveUp => 'Lên một bậc';

  @override
  String get playlistMenuMoveDown => 'Xuống một bậc';

  @override
  String get playlistMenuRemoveEntry => 'Bỏ khỏi playlist';

  @override
  String get playlistMenuRemoveFavorite => 'Bỏ khỏi Yêu thích';

  @override
  String playlistRemovedEntry(String title) {
    return 'Đã bỏ “$title”';
  }

  @override
  String playlistRemovedFavorite(String title) {
    return 'Đã bỏ “$title” khỏi Yêu thích';
  }

  @override
  String playlistRemovedEntries(int count) {
    return 'Đã bỏ $count bài';
  }

  @override
  String playlistRemovedDuplicates(int count) {
    return 'Đã bỏ $count bài trùng';
  }

  @override
  String playlistRemovedUnavailable(int count) {
    return 'Đã bỏ $count bài không còn tệp';
  }

  @override
  String get playlistClearedFavorites => 'Đã bỏ hết khỏi Yêu thích';

  @override
  String get playlistSaved => 'Đã lưu playlist';

  @override
  String playlistCreated(String name) {
    return 'Đã tạo $name';
  }

  @override
  String playlistDuplicated(String name) {
    return 'Đã tạo “$name”';
  }

  @override
  String playlistFavoritedAll(int added, int skipped) {
    return 'Đã thêm $added bài vào Yêu thích, bỏ qua $skipped';
  }

  @override
  String get playlistCreateTitle => 'Playlist mới';

  @override
  String get playlistCreateConfirm => 'Tạo';

  @override
  String get playlistEditTitle => 'Sửa playlist';

  @override
  String get playlistNameLabel => 'Tên';

  @override
  String get playlistDescriptionLabel => 'Mô tả';

  @override
  String get playlistDescriptionHint => 'Thêm mô tả (không bắt buộc)';

  @override
  String get playlistNameEmpty => 'Tên không được để trống';

  @override
  String get playlistNameTooLong => 'Quá dài';

  @override
  String get playlistDescriptionTooLong => 'Quá dài';

  @override
  String get playlistCoverChoose => 'Đổi ảnh bìa…';

  @override
  String get playlistCoverAuto => 'Bìa tự động';

  @override
  String get playlistCoverUsingAuto => 'Đang dùng bìa tự động';

  @override
  String get playlistCoverAutoHint =>
      'Bìa tự động ghép bìa của 4 album đầu trong playlist.';

  @override
  String playlistDeleteTitle(String name) {
    return 'Xoá “$name”?';
  }

  @override
  String playlistDeleteBody(int count) {
    return 'Playlist có $count bài. Các bài vẫn ở trong thư viện.';
  }

  @override
  String get playlistDeleteConfirm => 'Xoá';

  @override
  String get playlistClearFavoritesTitle => 'Bỏ hết khỏi Yêu thích?';

  @override
  String playlistClearFavoritesBody(int count) {
    return '$count bài sẽ bỏ khỏi Yêu thích. Các bài vẫn ở trong thư viện.';
  }

  @override
  String get playlistClearFavoritesConfirm => 'Bỏ hết';

  @override
  String get playlistCancel => 'Huỷ';

  @override
  String get playlistSave => 'Lưu';

  @override
  String get playlistClose => 'Đóng';

  @override
  String get playlistConfirm => 'Xác nhận';

  @override
  String get playlistPickerTitle => 'Thêm vào playlist';

  @override
  String playlistPickerSubtitle(int songs, String source) {
    return '$songs bài · $source';
  }

  @override
  String playlistPickerFrom(String name) {
    return 'từ $name';
  }

  @override
  String playlistPickerSelectedSongs(int count) {
    return '$count bài đã chọn';
  }

  @override
  String get playlistPickerFavoritesHint => 'Bài đã có được bỏ qua.';

  @override
  String get playlistPickerNew => 'Playlist mới…';

  @override
  String get playlistPickerNewMessage =>
      'Playlist được thêm vào danh sách, đã chọn sẵn, và chỉ được tạo khi bấm Thêm.';

  @override
  String get playlistPickerNewConfirm => 'Thêm vào danh sách';

  @override
  String get playlistPickerNewBadge => 'Mới';

  @override
  String get playlistPickerNewHint => 'Tạo khi bấm Thêm';

  @override
  String get playlistPickerHasThis => 'đã có bài này';

  @override
  String playlistPickerHasSome(int have, int total) {
    return 'đã có $have / $total bài';
  }

  @override
  String get playlistPickerNoneSelected => 'Chọn một hoặc nhiều playlist';

  @override
  String playlistPickerSelected(int count) {
    return '$count đã chọn';
  }

  @override
  String get playlistPickerAdd => 'Thêm';

  @override
  String playlistPickerAddMany(int count) {
    return 'Thêm vào $count playlist';
  }

  @override
  String get playlistAlreadyTitle => 'Đã có trong playlist';

  @override
  String get playlistAlreadySkip => 'Chỉ thêm bài chưa có';

  @override
  String playlistAlreadySkipHint(int count) {
    return 'Bỏ qua $count bài đã có';
  }

  @override
  String get playlistAlreadyMove => 'Thêm tất cả, bỏ bản cũ';

  @override
  String get playlistAlreadyMoveHint => 'Các bài trùng chuyển xuống cuối';

  @override
  String get playlistAlreadyAll => 'Thêm tất cả';

  @override
  String playlistAlreadyAllHint(int count) {
    return '$count bài sẽ có hai lần';
  }

  @override
  String get playlistAlreadyAppliesToAll => 'Lựa chọn áp dụng cho tất cả.';

  @override
  String playlistAddedSummary(
    int songs,
    int playlists,
    int newPlaylists,
    int skipped,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      newPlaylists,
      locale: localeName,
      other: ' ($newPlaylists mới)',
      zero: '',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: ', bỏ qua $skipped',
      zero: '',
    );
    return 'Đã thêm $songs bài vào $playlists playlist$_temp0$_temp1';
  }

  @override
  String playlistAddedGone(int count) {
    return '$count playlist đã bị xoá trong lúc đó';
  }

  @override
  String get playlistAddFailed => 'Không thêm được vào playlist';

  @override
  String get playlistProSmartNote => 'Smart playlist có trong bản Pro';

  @override
  String get playlistM3uFileTypes => 'Tệp playlist';

  @override
  String playlistM3uImported(int count, String name) {
    return 'Đã nhập $count bài vào $name';
  }

  @override
  String get playlistM3uReportTitle => 'Đã nhập playlist';

  @override
  String playlistM3uReportSummary(
    int added,
    int total,
    String file,
    String name,
  ) {
    return 'Đã thêm $added / $total dòng của $file vào playlist “$name”.';
  }

  @override
  String playlistM3uReportNotInLibrary(int count) {
    return '$count bài chưa có trong thư viện: hiện ra khi thư mục của chúng được thêm.';
  }

  @override
  String playlistM3uReportUnresolved(int count) {
    return '$count dòng không phải tệp nhạc trong máy hoặc nằm ngoài các thư mục nhạc (thêm thư mục đó trong Cài đặt › Thư viện):';
  }

  @override
  String playlistM3uReportSkipped(int count) {
    return '$count dòng là tệp mà thư viện bỏ qua khi quét (nằm trong thư mục ẩn, hoặc ngắn hơn 30 giây khi bật “Bỏ qua bài ngắn” trong Cài đặt › Thư viện):';
  }

  @override
  String playlistM3uReportNoBase(int count) {
    return '$count dòng dùng đường dẫn tương đối, nhưng tệp playlist không nằm trong bộ nhớ trong nên không biết chúng bắt đầu từ thư mục nào. Chép tệp playlist vào cạnh thư mục nhạc rồi nhập lại:';
  }

  @override
  String get playlistM3uAllOutside =>
      'Các bài của playlist này nằm ngoài các thư mục nhạc. Thêm thư mục đó trong Cài đặt › Thư viện rồi nhập lại. Chưa nhập gì.';

  @override
  String playlistM3uReportLine(int line, String text) {
    return 'Dòng $line: $text';
  }

  @override
  String playlistM3uReportMore(int count) {
    return 'và $count dòng nữa';
  }

  @override
  String get playlistM3uOpenPlaylist => 'Mở playlist';

  @override
  String get playlistM3uNothingFound =>
      'Không tìm thấy tệp nhạc nào của playlist này trong máy. Chưa nhập gì.';

  @override
  String get playlistM3uTooLarge => 'Tệp quá lớn, không phải playlist.';

  @override
  String get playlistM3uReadFailed => 'Không đọc được tệp.';

  @override
  String playlistM3uExported(int count, String file) {
    return 'Đã lưu $count bài vào $file';
  }

  @override
  String playlistM3uReplaceTitle(String file) {
    return 'Thay tệp $file?';
  }

  @override
  String get playlistM3uExportFailed => 'Không lưu được tệp.';

  @override
  String plAddMovedSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ', bỏ $count bản cũ',
    );
    return '$_temp0';
  }

  @override
  String plAddSkippedSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ', bỏ qua $count',
    );
    return '$_temp0';
  }

  @override
  String plAddAlreadyInOne(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài đã có trong “$name”.',
    );
    return '$_temp0';
  }

  @override
  String plAddAlreadyInMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Một số bài đã có trong $count playlist.',
    );
    return '$_temp0';
  }

  @override
  String plAddDefaultNameNumbered(int count) {
    return 'Playlist mới $count';
  }

  @override
  String plAddAddedToOne(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài',
    );
    return 'Đã thêm $_temp0 vào “$name”';
  }

  @override
  String plAddNothingNewOne(String name) {
    return 'Mọi bài đã có trong “$name”';
  }

  @override
  String plAddNothingNewMany(int count) {
    return 'Mọi bài đã có trong $count playlist';
  }

  @override
  String get plAddSourceQueue => 'từ hàng đợi';

  @override
  String plAddDroppedSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ', $count bài không còn trong thư viện',
    );
    return '$_temp0';
  }

  @override
  String get plAddSongsGone => 'Các bài này không còn trong thư viện';

  @override
  String get plAddTimedOut => 'Mất quá nhiều thời gian. Thử lại.';

  @override
  String get plAddNotConfirmed =>
      'Chưa xác nhận được việc thêm bài. Hãy xem lại playlist.';
}
