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
  String get scanSetupPermissionsGranted => 'Đã cấp đủ quyền';

  @override
  String get scanSetupPermissionsGrantedDesc =>
      'Nhạc và âm thanh · Ảnh và video';

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
  String get scanHomeChangeFolders => 'Đổi thư mục';

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
      'Giữ nguyên tệp; bỏ loại trong Cài đặt › Thư viện › Loại trừ';

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
      'Bấm [icon] trên một bài để thêm vào đây.';

  @override
  String get playlistFavoritesEmptyIconLabel => 'yêu thích';

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
  String get playlistAlreadySkipHint => 'Bài đã có giữ nguyên';

  @override
  String get playlistAlreadyMove => 'Thêm tất cả, bỏ bản cũ';

  @override
  String get playlistAlreadyMoveHint => 'Bài đã có chuyển xuống cuối';

  @override
  String get playlistAlreadyAll => 'Thêm tất cả';

  @override
  String get playlistAlreadyAllHint => 'Bài đã có sẽ lặp lại';

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
    return '$count bài chưa có trong thư viện: sẽ hiện ra sau lần quét thư viện tới.';
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
  String get plScreensFavoritesLine => 'Bài bạn bấm';

  @override
  String get plScreensFavoritesLineSemantics => 'Bài bạn bấm yêu thích';

  @override
  String plScreensDeleted(String name) {
    return 'Đã xoá “$name”';
  }

  @override
  String get plScreensDeleteFailed => 'Không xoá được playlist';

  @override
  String plScreensCharCount(int count, int max) {
    return '$count / $max';
  }

  @override
  String get plScreensCoverFailed => 'Không đổi được ảnh bìa';

  @override
  String get plScreensDuplicateCopyCover => 'Chép cả ảnh bìa tự chọn';

  @override
  String get plScreensDuplicateConfirm => 'Nhân bản';

  @override
  String get plScreensPlay => 'Phát playlist';

  @override
  String get plScreensEditList => 'Sửa danh sách';

  @override
  String get plScreensEditDone => 'Xong';

  @override
  String plScreensEditBarLead(int count) {
    return '$count bài · Thứ tự playlist';
  }

  @override
  String get plScreensUnitPlaylists => 'playlist';

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

  @override
  String m3uImportProgressTitle(String file) {
    return 'Đang nhập $file';
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

    return '$doneString / $totalString dòng';
  }

  @override
  String get m3uImportFailed => 'Không nhập được tệp.';

  @override
  String m3uReportTruncated(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Tệp có nhiều dòng hơn giới hạn, nên chỉ đọc $maxString dòng đầu.';
  }

  @override
  String m3uExportedSkipped(int count, String file, int skipped) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat skippedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String skippedString = skippedNumberFormat.format(skipped);

    return 'Đã lưu $countString bài vào $file, bỏ qua $skippedString bài không có tệp trong máy';
  }

  @override
  String get m3uExportFolderUnknown =>
      'Không ghi được đường dẫn tương đối vì không biết thư mục của tệp. Lưu tệp vào bộ nhớ trong, hoặc xuất với đường dẫn tuyệt đối.';

  @override
  String get m3uExportReplace => 'Thay thế';

  @override
  String m3uReportNotIndexed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString dòng là tệp có trong máy nhưng Android chưa đưa vào kho nhạc nên thư viện không thấy. Vào Cài đặt › Thư viện › Thư mục nhạc › Thêm thư mục, bấm “Không thấy thư mục của bạn? Quét lại”, rồi nhập lại:';
  }

  @override
  String get m3uImportNotIndexed =>
      'Android chưa đưa các tệp nhạc của playlist này vào kho nhạc nên thư viện không thấy. Vào Cài đặt › Thư viện › Thư mục nhạc › Thêm thư mục, bấm “Không thấy thư mục của bạn? Quét lại”, rồi nhập lại. Chưa nhập gì.';

  @override
  String get coverDialogTitle => 'Ảnh bìa';

  @override
  String get coverEditAlbumTooltip => 'Sửa ảnh bìa album';

  @override
  String get coverEditArtistTooltip => 'Đặt ảnh nghệ sĩ';

  @override
  String get coverAutoTitle => 'Tự động';

  @override
  String get coverAutoSubtitleAlbum => 'Bìa trong tệp nhạc';

  @override
  String get coverAutoSubtitleArtist => 'Bìa album đầu tiên';

  @override
  String get coverAutoSubtitlePlaylist => 'Ghép bìa 4 album đầu';

  @override
  String get coverCurrentTitle => 'Ảnh đang dùng';

  @override
  String get coverCurrentSubtitle => 'Đã chọn trước đây';

  @override
  String get coverGroupArtistAlbums => 'Bìa album của nghệ sĩ';

  @override
  String get coverGroupPlaylistAlbums => 'Bìa album trong playlist';

  @override
  String coverMoreAlbums(int count) {
    return 'Xem thêm $count album';
  }

  @override
  String get coverAlbumSubtitle => 'Bìa album';

  @override
  String coverAlbumSubtitleYear(int year) {
    return 'Bìa album · $year';
  }

  @override
  String get coverPickMobile => 'Chọn ảnh…';

  @override
  String get coverPickDesktop => 'Chọn ảnh từ máy…';

  @override
  String get coverPickedReading => 'Đang đọc ảnh…';

  @override
  String coverPickedSubtitle(int width, int height) {
    return 'Từ máy · $width × $height';
  }

  @override
  String get coverPickedGeneratedName => 'Ảnh từ máy';

  @override
  String get coverPanHint => 'Kéo ảnh để chọn phần hiện (ảnh được cắt vuông)';

  @override
  String coverSmallImage(int width, int height) {
    return 'Ảnh nhỏ ($width × $height px): có thể bị mờ ở Now Playing và trang chi tiết. Vẫn lưu được.';
  }

  @override
  String get coverHintResetAlbum =>
      'Lưu: bỏ ảnh riêng, dùng lại bìa trong tệp nhạc';

  @override
  String get coverHintResetArtist => 'Lưu: bỏ ảnh riêng, dùng lại ảnh tự động';

  @override
  String get coverHintResetPlaylist =>
      'Lưu: bỏ ảnh riêng, dùng lại bìa tự động';

  @override
  String get coverHintCopied =>
      'Ảnh được chép vào dữ liệu của Kanaru; tệp gốc và tag không đổi';

  @override
  String get coverScopeAlbum => 'Áp dụng cho album ở mọi nơi';

  @override
  String get coverScopeArtist => 'Ảnh của nghệ sĩ ở mọi nơi';

  @override
  String get coverScopePlaylist => 'Chỉ playlist này';

  @override
  String get coverScopeForm =>
      'Lưu cùng các thay đổi khác khi bấm Lưu ở Sửa playlist';

  @override
  String get coverCancel => 'Huỷ';

  @override
  String get coverSave => 'Lưu';

  @override
  String get coverChoose => 'Chọn';

  @override
  String get coverDropHere => 'Thả ảnh vào đây';

  @override
  String get coverChanged => 'Đã đổi ảnh bìa';

  @override
  String get coverResetDone => 'Đã dùng lại bìa tự động';

  @override
  String get coverUndo => 'Hoàn tác';

  @override
  String get coverUndoFailed => 'Không hoàn tác được';

  @override
  String get coverErrorFormat =>
      'Không dùng được ảnh này (chỉ hỗ trợ JPEG, PNG, WebP)';

  @override
  String get coverErrorRead => 'Không đọc được tệp ảnh. Thử lại sau.';

  @override
  String get coverLinuxDialogLabel => 'Ảnh';

  @override
  String get settingsAbout => 'Giới thiệu';

  @override
  String get settingsNativeVersions => 'Thư viện native';

  @override
  String get settingsSaveFailed =>
      'Không lưu được cài đặt. Thay đổi chỉ giữ tới khi đóng app.';

  @override
  String get settingsRootAppearance => 'Giao diện';

  @override
  String get settingsRootAppearanceDesc =>
      'Chủ đề, ngôn ngữ, màu, chữ, thanh tua';

  @override
  String get settingsRootLibrary => 'Thư viện';

  @override
  String get settingsRootLibraryDesc => 'Thư mục nhạc, quét, tab, tách nghệ sĩ';

  @override
  String get settingsRootLibraryMissingPermission => ' · thiếu quyền nhạc';

  @override
  String get settingsRootPlayback => 'Phát nhạc';

  @override
  String get settingsRootPlaybackDesc =>
      'Liền mạch, âm thanh, ReplayGain, lịch sử nghe';

  @override
  String get settingsRootLyrics => 'Lời bài';

  @override
  String get settingsRootLyricsDesc =>
      'Hiển thị lời, tìm và lưu lời, nguồn lời, dịch';

  @override
  String get settingsRootPlugins => 'Plugin';

  @override
  String get settingsRootPluginsDesc => 'Plugin đã cài, kho plugin, cập nhật';

  @override
  String get settingsRootAi => 'Trò chuyện AI';

  @override
  String get settingsRootAiDesc => 'Dịch vụ AI, quyền, công cụ, skill, lịch sử';

  @override
  String get settingsRootIntegrations => 'Tích hợp';

  @override
  String get settingsRootIntegrationsDescDesktop =>
      'Máy chủ MCP, web server trong mạng LAN';

  @override
  String get settingsRootIntegrationsDescMobile => 'Web server trong mạng LAN';

  @override
  String get settingsRootData => 'Dữ liệu và bộ nhớ';

  @override
  String get settingsRootDataDesc => 'Bộ nhớ đệm, sao lưu';

  @override
  String get settingsRootAdvanced => 'Nâng cao';

  @override
  String get settingsRootAdvancedDesc => 'Nhật ký, quyền riêng tư, đặt lại';

  @override
  String get settingsRootPro => 'Kanaru Pro';

  @override
  String get settingsRootProFreeDesc =>
      'Mua một lần · đồng bộ, nhiều nguồn, thống kê nâng cao…';

  @override
  String get settingsRootProActive => 'Đã kích hoạt · cảm ơn bạn';

  @override
  String get settingsRootAboutDesc => 'Giấy phép, thư viện native';

  @override
  String get settingsAppearanceColorMotionTitle => 'Màu và chuyển động';

  @override
  String get settingsAppearancePureBlack => 'Nền đen tuyền';

  @override
  String get settingsAppearancePureBlackNeedsDark => 'Chỉ dùng với chủ đề Tối';

  @override
  String get settingsAppearanceMotion => 'Hiệu ứng chuyển động';

  @override
  String get settingsAppearanceTextTitle => 'Chữ';

  @override
  String get settingsAppearanceFont => 'Phông chữ';

  @override
  String get settingsAppearanceTextSize => 'Cỡ chữ';

  @override
  String get settingsAppearanceDisplayTitle => 'Hiển thị';

  @override
  String get settingsAppearanceSeekBar => 'Thanh tua';

  @override
  String get settingsAppearanceWindowFrame => 'Khung cửa sổ của hệ thống';

  @override
  String get settingsSeekBarCaption => 'Dùng ở Now Playing và màn lời.';

  @override
  String get settingsSeekBarWaveform => 'Dạng sóng';

  @override
  String get settingsSeekBarWaveformCaption =>
      'Tệp trong máy và một số plugin. Bài không có dạng sóng dùng thanh phẳng.';

  @override
  String get settingsSeekBarFlat => 'Thanh phẳng';

  @override
  String get settingsSeekBarFlatCaption => 'Mọi bài';

  @override
  String get settingsAboutEditionFree => 'Bản miễn phí';

  @override
  String get settingsAboutEditionPro => 'Kanaru Pro';

  @override
  String get settingsAboutLicenses => 'Giấy phép mã nguồn mở';

  @override
  String settingsPercent(int percent) {
    return '$percent %';
  }

  @override
  String get settingsAboutLicense => 'Giấy phép';

  @override
  String get settingsPlaybackBlockPlay => 'Phát';

  @override
  String get settingsPlaybackBlockSound => 'Âm thanh';

  @override
  String get settingsPlaybackBlockHistory => 'Lịch sử nghe';

  @override
  String get settingsPlaybackGapless => 'Phát liền mạch';

  @override
  String get settingsPlaybackGaplessDesc => 'Áp dụng từ bài sau';

  @override
  String get settingsPlaybackFadeIn => 'Tăng dần âm lượng khi phát';

  @override
  String get settingsPlaybackFadeOut => 'Giảm dần âm lượng khi tạm dừng';

  @override
  String get settingsPlaybackCrossfade => 'Chuyển bài mờ dần';

  @override
  String get settingsPlaybackCrossfadeDesc =>
      'Crossfade: bài cũ nhỏ dần trong khi bài mới to dần.';

  @override
  String get settingsPlaybackOutputDevice => 'Thiết bị đầu ra';

  @override
  String get settingsPlaybackReplayGain => 'ReplayGain';

  @override
  String get settingsPlaybackPreamp => 'Tăng thêm';

  @override
  String get settingsPlaybackClipping => 'Chống méo tiếng';

  @override
  String get settingsPlaybackClippingDesc =>
      'Giảm mức khi tăng thêm làm vỡ tiếng.';

  @override
  String get settingsPlaybackOff => 'Tắt';

  @override
  String get settingsPlaybackAuto => 'Tự động';

  @override
  String get settingsPlaybackPreviousButton => 'Nút Bài trước';

  @override
  String get settingsPlaybackPreviousAlways => 'Luôn về bài trước';

  @override
  String get settingsPlaybackPreviousAlwaysDesc => 'Mặc định';

  @override
  String get settingsPlaybackPreviousRestart => 'Quá 3 giây thì về đầu bài';

  @override
  String get settingsPlaybackPreviousRestartDesc =>
      'Bấm trong 3 giây đầu bài thì về bài trước';

  @override
  String get settingsPlaybackHistory => 'Ghi lịch sử nghe';

  @override
  String get settingsPlaybackHistoryDesc =>
      'Dùng cho Lịch sử, Phát nhiều nhất, Nghe tiếp.';

  @override
  String get settingsPlaybackHistoryOff => 'Đang tắt · lịch sử đã ghi vẫn giữ';

  @override
  String get settingsPlaybackListenRule => 'Tính một lượt nghe sau';

  @override
  String get settingsPlaybackListenCaption =>
      'Bài được tính một lượt nghe khi tới mốc nào trước. Mặc định 4 phút hoặc 50 %.';

  @override
  String get settingsPlaybackListenNeedsHistory =>
      'Bật Ghi lịch sử nghe để dùng';

  @override
  String get settingsPlaybackListenNoTime => 'Không dùng';

  @override
  String get settingsPlaybackListenEndLabel => 'Hết bài';

  @override
  String settingsPlaybackListenTimeLive(String duration) {
    return 'Sau $duration nghe';
  }

  @override
  String get settingsPlaybackListenNoTimeLive => 'Không tính theo thời gian';

  @override
  String settingsPlaybackListenPercentLive(int percent) {
    return 'hoặc khi nghe $percent % bài';
  }

  @override
  String get settingsPlaybackListenEndLive => 'hoặc khi nghe hết bài';

  @override
  String settingsPlaybackListenTimeOrPercent(String duration, int percent) {
    return '$duration hoặc $percent %';
  }

  @override
  String settingsPlaybackListenTimeOrEnd(String duration) {
    return '$duration hoặc hết bài';
  }

  @override
  String get settingsPlaybackListenEnd => 'Nghe hết bài';

  @override
  String settingsPlaybackListenPercentOnly(int percent) {
    return '$percent % bài';
  }

  @override
  String settingsDurationSeconds(int seconds) {
    return '$seconds giây';
  }

  @override
  String settingsDurationMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String settingsDurationMinutesSeconds(int minutes, int seconds) {
    return '$minutes phút $seconds giây';
  }

  @override
  String settingsPlaybackPreampValue(int db) {
    return '$db dB';
  }

  @override
  String get settingsAppearancePureBlackDesc =>
      'Nền đen hẳn khi chủ đề Tối, hợp với màn OLED.';

  @override
  String get settingsAppearanceMotionDesc =>
      'Tắt thì trang và sheet hiện ngay, không trượt.';

  @override
  String get settingsAppearanceWindowFrameDesc =>
      'Dùng thanh tiêu đề và viền cửa sổ của hệ thống thay cho thanh của Kanaru.';

  @override
  String get settingsAppearanceWindowFrameApply =>
      'Áp dụng sau khi mở lại Kanaru';

  @override
  String get settingsAppearanceTextSizeDefault => 'Mặc định';

  @override
  String get settingsPlaybackNeedsReplayGain => 'Bật ReplayGain để dùng';

  @override
  String settingsSectionHintTooltip(String section) {
    return 'Giải thích $section';
  }

  @override
  String settingsLibraryTracksCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bài',
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
      other: '$countString album',
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
      other: '$countString nghệ sĩ',
    );
    return '$_temp0';
  }

  @override
  String settingsLibraryLastScan(String time, int added) {
    return 'Quét lần cuối $time · thêm $added bài';
  }

  @override
  String get settingsLibraryBlockScan => 'Quét';

  @override
  String get settingsLibraryBlockOrganise => 'Sắp xếp';

  @override
  String get settingsLibraryBlockRemoved => 'Đã loại';

  @override
  String settingsLibraryFoldersEstimate(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Khoảng $countString bài';
  }

  @override
  String get settingsLibraryMinDuration => 'Bỏ qua tệp ngắn hơn';

  @override
  String get settingsLibraryMinDurationCaption =>
      'Nhạc chuông, âm báo, đoạn ghi âm ngắn. Áp dụng ở lần quét sau.';

  @override
  String get settingsLibraryMinSize => 'Bỏ qua tệp nhỏ hơn';

  @override
  String get settingsLibraryMinSizeCaption =>
      'Tính theo dung lượng tệp. Áp dụng ở lần quét sau.';

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
  String get settingsLibraryFormats => 'Định dạng được quét';

  @override
  String get settingsLibraryFormatsCaption =>
      'Bỏ chọn để không quét định dạng đó. Cần giữ ít nhất một.';

  @override
  String get settingsLibraryFormatsKeepOne => 'cần giữ ít nhất một';

  @override
  String get settingsLibraryFormatsAll => 'Tất cả';

  @override
  String get settingsLibraryFormatsSelectAll => 'Chọn tất cả';

  @override
  String settingsCountOfTotal(int n, int total) {
    return '$n / $total';
  }

  @override
  String get settingsLibraryDedupName => 'Gộp bài trùng tên tệp';

  @override
  String get settingsLibraryDedupNameDesc =>
      'Tệp cùng tên ở các thư mục khác nhau chỉ hiện một bài, bản chất lượng cao nhất. Tệp không bị xoá.';

  @override
  String get settingsLibraryNomedia => 'Bỏ qua thư mục có tệp .nomedia';

  @override
  String get settingsLibraryNomediaDesc =>
      'Như Android: thư mục có .nomedia không được quét.';

  @override
  String get settingsLibraryWatch => 'Tự cập nhật khi thư mục thay đổi';

  @override
  String get settingsLibraryWatchDesc =>
      'Thấy tệp mới ngay, không cần quét lại.';

  @override
  String get settingsLibraryRulesApplyLater => 'Áp dụng ở lần quét sau';

  @override
  String get settingsLibraryRescanning => 'Đang quét lại thư viện ở nền';

  @override
  String get settingsLibraryMergeFolders =>
      'Gộp thư mục chỉ có một thư mục con';

  @override
  String get settingsLibraryMergeFoldersDesc =>
      'Tab Thư mục: đi thẳng xuống thư mục con duy nhất.';

  @override
  String get settingsLibraryAlbumGrouping => 'Nhóm album theo';

  @override
  String get settingsLibraryRemoved => 'Đã loại khỏi thư viện';

  @override
  String get settingsLibraryTabsHintMobile =>
      'Bật tab muốn hiện, kéo để sắp xếp. Ít nhất 1 tab. Tab là hàng tab con ở đầu Thư viện.';

  @override
  String get settingsLibraryTabsHintDesktop =>
      'Bật tab muốn hiện, kéo để sắp xếp. Ít nhất 1 tab. Tab là các mục Thư viện ở thanh bên.';

  @override
  String settingsLibraryRemoveFolderTitle(String name) {
    return 'Bỏ thư mục “$name”?';
  }

  @override
  String get settingsLibraryRemoveFolderBody =>
      'Các bài trong thư mục này sẽ rời thư viện (playlist giữ chỗ, đánh dấu mất tệp).\n\nTệp trong máy không bị xoá.';

  @override
  String settingsLibraryRemoveFolderBodyCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString bài trong thư mục này sẽ rời thư viện (playlist giữ chỗ, đánh dấu mất tệp).\n\nTệp trong máy không bị xoá.';
  }

  @override
  String get settingsLibraryRemoveFolderConfirm => 'Bỏ thư mục';

  @override
  String settingsLibraryFolderRemoved(String name) {
    return 'Đã bỏ “$name”';
  }

  @override
  String settingsLibraryFolderRemovedCount(String name, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Đã bỏ “$name” · $countString bài rời thư viện';
  }

  @override
  String get settingsLibraryLastFolderTitle => 'Không bỏ được thư mục cuối';

  @override
  String settingsLibraryLastFolderBody(String name) {
    return 'Thư viện cần ít nhất một thư mục nhạc. Thêm thư mục khác trước, rồi bỏ “$name”.';
  }

  @override
  String get settingsLibraryGotIt => 'Đã hiểu';

  @override
  String settingsLibraryExclusionRemoved(String name) {
    return 'Thôi loại trừ “$name” · đang quét lại';
  }

  @override
  String get settingsLibraryArtistSplit => 'Tách nghệ sĩ';

  @override
  String settingsLibrarySeparatorCount(int count) {
    return '$count dấu tách';
  }

  @override
  String get settingsArtistSplitIntro =>
      'Một bài nhiều nghệ sĩ: Kanaru tách tên theo các dấu này.';

  @override
  String get settingsArtistSplitExample => 'Ví dụ';

  @override
  String get settingsArtistSplitExampleNote =>
      'Danh sách mặc định không có , và & vì nhiều tên nhóm chứa chúng. Muốn tách theo chúng thì thêm vào đây, rồi thêm các tên nhóm đó vào Không tách.';

  @override
  String get settingsArtistSplitSeparators => 'Dấu tách';

  @override
  String get settingsArtistSplitSeparatorsHint =>
      'Dấu cách hiện là ␣. Thay đổi áp dụng ngay, thư viện cập nhật ở nền.';

  @override
  String get settingsArtistSplitKeep => 'Không tách';

  @override
  String get settingsArtistSplitKeepHint =>
      'Tên giữ nguyên là một nghệ sĩ dù có chứa dấu tách.';

  @override
  String get settingsArtistSplitSeparatorInput => 'Thêm dấu tách, vd. “ x ”';

  @override
  String get settingsArtistSplitKeepInput =>
      'Tên nghệ sĩ, vd. “Hồ Ngọc Hà / Noo”';

  @override
  String get settingsArtistSplitAdd => 'Thêm';

  @override
  String settingsArtistSplitRemove(String value) {
    return 'Bỏ $value';
  }

  @override
  String get settingsArtistSplitNoSeparators =>
      'Không có dấu tách nào: tên nghệ sĩ giữ nguyên.';

  @override
  String get settingsArtistSplitErrEmpty => 'Chưa nhập gì';

  @override
  String get settingsArtistSplitErrDuplicate => 'Đã có trong danh sách';

  @override
  String settingsArtistSplitErrTooLong(int max) {
    return 'Tối đa $max ký tự';
  }

  @override
  String settingsArtistSplitErrFull(int max) {
    return 'Tối đa $max mục';
  }

  @override
  String get settingsArtistSplitReset => 'Khôi phục mặc định';

  @override
  String get settingsArtistSplitResetIsDefault => 'Đang là mặc định';

  @override
  String settingsArtistSplitResetTo(int count, String names) {
    return '$count dấu tách, “$names”';
  }

  @override
  String get settingsArtistSplitResetTitle => 'Khôi phục dấu tách mặc định?';

  @override
  String get settingsArtistSplitResetBody =>
      'Danh sách dấu tách và tên không tách về như lúc cài. Thư viện cập nhật ở nền.';

  @override
  String get settingsArtistSplitResetConfirm => 'Khôi phục';

  @override
  String settingsArtistSplitAdded(String value) {
    return 'Đã thêm “$value”';
  }

  @override
  String settingsArtistSplitAddedGroup(String value) {
    return 'Đã thêm “$value” · thêm tên nhóm có dấu này vào Không tách';
  }

  @override
  String settingsArtistSplitRemoved(String value) {
    return 'Đã bỏ “$value”';
  }

  @override
  String get settingsArtistSplitRestored => 'Đã khôi phục mặc định';

  @override
  String get settingsLibraryLanguageSource => 'Nguồn ngôn ngữ';

  @override
  String get settingsLibraryLanguageSourceCaption =>
      'Cách Kanaru biết bài hát thuộc ngôn ngữ nào (tab Ngôn ngữ).';

  @override
  String get settingsLibraryLanguageBoth => 'Tag, rồi tự nhận diện';

  @override
  String get settingsLibraryLanguageBothDesc =>
      'Dùng tag ngôn ngữ nếu tệp có, không có thì đoán từ tên bài và lời';

  @override
  String get settingsLibraryLanguageTag => 'Chỉ tag';

  @override
  String get settingsLibraryLanguageTagDesc => 'Bài không có tag vào “Chưa rõ”';

  @override
  String get settingsLibraryLanguageDetected => 'Chỉ tự nhận diện';

  @override
  String get settingsLibraryLanguageDetectedDesc =>
      'Bỏ qua tag ngôn ngữ của tệp';

  @override
  String get sleepTimerHint => 'Chạm một mục là bắt đầu ngay.';

  @override
  String get sleepTimerCancel => 'Huỷ';

  @override
  String get sleepTimerSectionDuration => 'Sau một khoảng';

  @override
  String get sleepTimerSectionTracks => 'Theo bài';

  @override
  String sleepTimerTileUntil(String time) {
    return 'đến $time';
  }

  @override
  String sleepTimerTileStartLabel(String duration, String time) {
    return 'Bắt đầu $duration, dừng lúc $time';
  }

  @override
  String get sleepTimerCustom => 'Tuỳ chỉnh…';

  @override
  String sleepTimerCustomRange(int min, int max) {
    return '$min–$max phút';
  }

  @override
  String get sleepTimerEndOfTrack => 'Hết bài này';

  @override
  String get sleepTimerEndOfAlbum => 'Hết album này';

  @override
  String get sleepTimerEndOfQueue => 'Hết hàng đợi';

  @override
  String get sleepTimerAfterTracks => 'Sau số bài…';

  @override
  String sleepTimerAfterTracksRange(int min, int max) {
    return '$min–$max bài, tính cả bài này';
  }

  @override
  String get sleepTimerNoAlbum => 'Bài này không có album';

  @override
  String sleepTimerLeftTime(String time) {
    return 'còn $time';
  }

  @override
  String sleepTimerLeftTracks(int count) {
    return 'còn $count bài';
  }

  @override
  String sleepTimerLeftTracksCapped(int count) {
    return 'còn $count+ bài';
  }

  @override
  String sleepTimerLeftTracksDuration(int count, String duration) {
    return 'còn $count bài · $duration';
  }

  @override
  String get sleepTimerRunning => 'Đang chạy';

  @override
  String sleepTimerRunningWith(String status) {
    return 'Đang chạy · $status';
  }

  @override
  String get sleepTimerCustomTitle => 'Tuỳ chỉnh';

  @override
  String get sleepTimerKindLabel => 'Kiểu hẹn giờ';

  @override
  String get sleepTimerKindMinutes => 'Phút';

  @override
  String get sleepTimerKindTracks => 'Số bài';

  @override
  String get sleepTimerFieldMinutes => 'Số phút';

  @override
  String get sleepTimerUnitMinutes => 'phút';

  @override
  String sleepTimerUnitMinutesWords(String words) {
    return 'phút · $words';
  }

  @override
  String sleepTimerUnitTracks(int count) {
    return 'bài';
  }

  @override
  String sleepTimerStopsAt(String time) {
    return 'Dừng lúc $time';
  }

  @override
  String sleepTimerStopsAfterTracks(int count) {
    return 'Tạm dừng sau $count bài, tính cả bài này';
  }

  @override
  String sleepTimerTracksCount(int count) {
    return '$count bài';
  }

  @override
  String get sleepTimerStart => 'Bắt đầu';

  @override
  String sleepTimerMinutes(int count) {
    return '$count phút';
  }

  @override
  String sleepTimerHours(int count) {
    return '$count giờ';
  }

  @override
  String sleepTimerHoursMinutes(int hours, int minutes) {
    return '$hours giờ $minutes phút';
  }

  @override
  String sleepTimerHoursMinutesShort(int hours, int minutes) {
    return '$hours giờ $minutes';
  }

  @override
  String sleepTimerChipMinutes(int minutes) {
    return '$minutes ph';
  }

  @override
  String sleepTimerAddMinutes(int minutes) {
    return 'Thêm $minutes phút';
  }

  @override
  String sleepTimerRemoveMinutes(int minutes) {
    return 'Bớt $minutes phút';
  }

  @override
  String get sleepTimerRemoveOneMinute => 'Bớt 1 phút';

  @override
  String get sleepTimerAddTrack => 'Thêm một bài';

  @override
  String get sleepTimerRemoveTrack => 'Bớt một bài';

  @override
  String sleepTimerChipPlusMinutes(int minutes) {
    return '+$minutes ph';
  }

  @override
  String get sleepTimerChipPlusHour => '+1 giờ';

  @override
  String get sleepTimerAddHour => 'Thêm 1 giờ';

  @override
  String sleepTimerStepMinus(int amount) {
    return '−$amount';
  }

  @override
  String sleepTimerStepPlus(int amount) {
    return '+$amount';
  }

  @override
  String get sleepTimerLabelSleepIn => 'Ngủ sau';

  @override
  String get sleepTimerLabelHeld => 'Tạm dừng đếm';

  @override
  String get sleepTimerLabelPauseAfter => 'Tạm dừng sau';

  @override
  String get sleepTimerLabelPauseAtEnd => 'Tạm dừng khi hết';

  @override
  String get sleepTimerWordTrack => 'bài này';

  @override
  String get sleepTimerWordAlbum => 'album này';

  @override
  String get sleepTimerWordQueue => 'hàng đợi';

  @override
  String get sleepTimerRowHeld => 'Đã tạm dừng đếm';

  @override
  String get sleepTimerRowCurrentCounts => 'Bài đang phát tính là một';

  @override
  String get sleepTimerRowLastTrack => 'bài này là bài cuối';

  @override
  String sleepTimerRowTracksOf(int left, int total) {
    return '$left / $total';
  }

  @override
  String get sleepTimerRowQueueKept => 'hàng đợi vẫn giữ';

  @override
  String get sleepTimerPauseCounting => 'Tạm dừng đếm';

  @override
  String get sleepTimerResumeCounting => 'Tiếp tục đếm';

  @override
  String get sleepTimerTurnOff => 'Tắt hẹn giờ';

  @override
  String get sleepTimerChange => 'Đổi…';

  @override
  String sleepTimerStatusMinutes(String duration) {
    return 'Ngủ sau $duration';
  }

  @override
  String sleepTimerStatusHeld(String duration) {
    return 'Tạm dừng đếm · còn $duration';
  }

  @override
  String sleepTimerStatusTracks(int count) {
    return 'Tạm dừng sau $count bài';
  }

  @override
  String get sleepTimerStatusEndTrack => 'Tạm dừng khi hết bài này';

  @override
  String get sleepTimerStatusEndAlbum => 'Tạm dừng khi hết album này';

  @override
  String get sleepTimerStatusEndQueue => 'Tạm dừng khi hết hàng đợi';

  @override
  String get sleepTimerPillTrack => 'Bài';

  @override
  String get sleepTimerPillAlbum => 'Album';

  @override
  String get sleepTimerPillQueue => 'Hàng đợi';

  @override
  String get sleepTimerEntryEndTrack => 'hết bài này';

  @override
  String get sleepTimerEntryEndAlbum => 'hết album này';

  @override
  String get sleepTimerEntryEndQueue => 'hết hàng đợi';

  @override
  String sleepTimerEntryRunning(String status) {
    return 'Hẹn giờ ngủ: $status';
  }

  @override
  String sleepTimerMenuRunning(String status) {
    return 'Hẹn giờ ngủ · $status';
  }

  @override
  String get sleepTimerHeldSuffix => '(tạm dừng đếm)';

  @override
  String sleepTimerAnnounceStartMinutes(String duration, String time) {
    return 'Đã hẹn giờ ngủ $duration, dừng lúc $time';
  }

  @override
  String sleepTimerAnnounceStartTracks(int count) {
    return 'Đã hẹn giờ ngủ, tạm dừng sau $count bài';
  }

  @override
  String get sleepTimerAnnounceStartEndTrack =>
      'Đã hẹn giờ ngủ, tạm dừng khi hết bài này';

  @override
  String get sleepTimerAnnounceStartEndAlbum =>
      'Đã hẹn giờ ngủ, tạm dừng khi hết album này';

  @override
  String get sleepTimerAnnounceStartEndQueue =>
      'Đã hẹn giờ ngủ, tạm dừng khi hết hàng đợi';

  @override
  String get sleepTimerAnnounceHeld => 'Đã tạm dừng đếm';

  @override
  String get sleepTimerAnnounceResumed => 'Đã tiếp tục đếm';

  @override
  String get sleepTimerAnnounceCancelled => 'Đã tắt hẹn giờ ngủ';

  @override
  String get sleepTimerAnnounceExpired =>
      'Hẹn giờ ngủ đã hết, nhạc đã tạm dừng';
}
