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
  String get libraryPlayAll => 'Phát';

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
  String get sleepTimerRepeatOneStops => 'Đang lặp một bài · dừng sau bài này';

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

  @override
  String get historyTitle => 'Lịch sử';

  @override
  String historyHeroPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lượt nghe',
    );
    return '$_temp0';
  }

  @override
  String historyHeroSongsSince(int songs, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      songs,
      locale: localeName,
      other: '$songs bài',
    );
    return '$_temp0 · từ $date';
  }

  @override
  String historyBarCount(String year, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lượt nghe',
    );
    return '$year · $_temp0';
  }

  @override
  String get historyJumpToDay => 'Nhảy tới ngày';

  @override
  String get historyYearsLabel => 'Năm';

  @override
  String get historyDayToday => 'Hôm nay';

  @override
  String get historyDayYesterday => 'Hôm qua';

  @override
  String historyDayPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lượt',
    );
    return '$_temp0';
  }

  @override
  String historyDayMenuLabel(String day) {
    return 'Thêm: $day';
  }

  @override
  String historyRowOrdinal(String time, int n) {
    return '$time · lần thứ $n';
  }

  @override
  String historyRowMissing(String time) {
    return '$time · không phát được';
  }

  @override
  String get historyMissingTap => 'Không phát được bài này';

  @override
  String historyRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã xoá $count lượt nghe',
    );
    return '$_temp0';
  }

  @override
  String get historyRemoveFailed => 'Không xoá được lượt nghe';

  @override
  String get historyWriteFailed => 'Không lưu được thay đổi';

  @override
  String get historyEmptyMessage => 'Bài hát bạn đã phát sẽ hiện ở đây.';

  @override
  String get historyRecordingOff =>
      'Đang tắt ghi lịch sử nghe. Những gì đã ghi vẫn còn.';

  @override
  String get historyRecordingOn => 'Bật';

  @override
  String get historyRecordingOnLabel => 'Bật ghi lịch sử nghe';

  @override
  String get historyRecordingEnabled => 'Đã bật ghi lịch sử nghe';

  @override
  String historyYearFooter(String year) {
    return 'Xem năm $year';
  }

  @override
  String get historyPlayFailed => 'Không phát được lịch sử';

  @override
  String get historyMenuMostPlayed => 'Phát nhiều nhất';

  @override
  String get historyMenuClear => 'Xoá lịch sử…';

  @override
  String get historyMenuPlayDay => 'Phát cả ngày';

  @override
  String get historyMenuDeleteDay => 'Xoá ngày khỏi lịch sử';

  @override
  String get historyMenuTrackHistory => 'Lịch sử bài này';

  @override
  String get historyMenuRemovePlay => 'Xoá khỏi lịch sử';

  @override
  String get historyNothingToAdd => 'Không có bài phát được để thêm';

  @override
  String get historyMenuExportM3u => 'Xuất M3U…';

  @override
  String get historyNothingToExport => 'Không có bài nào để xuất';

  @override
  String get historyClearTitle => 'Xoá lịch sử?';

  @override
  String get historyClearHour => 'Giờ qua';

  @override
  String get historyClearToday => 'Hôm nay';

  @override
  String get historyClearWeek => '7 ngày qua';

  @override
  String get historyClearAll => 'Toàn bộ';

  @override
  String get historyClearConfirm => 'Xoá';

  @override
  String get historyClearCountFailed => 'Không đếm được số lượt nghe';

  @override
  String get historyClearRetry => 'Thử lại';

  @override
  String get historyClearFailed => 'Không xoá được lịch sử';

  @override
  String historyCleared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã xoá $count lượt nghe',
    );
    return '$_temp0';
  }

  @override
  String get historyDeleteDayTitle => 'Xoá ngày này khỏi lịch sử?';

  @override
  String historyDeleteDayBody(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lượt nghe',
    );
    return '$_temp0 của ngày $date sẽ bị xoá. Không thể hoàn tác.';
  }

  @override
  String historyFilterHint(String year) {
    return 'Lọc trong $year';
  }

  @override
  String historyFilterMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lượt khớp',
    );
    return '$_temp0 · không chia theo ngày';
  }

  @override
  String historyFilterCapped(int max) {
    return 'Chỉ hiện $max lượt đầu. Thu hẹp từ khoá để thấy thêm.';
  }

  @override
  String historyFilterEmpty(String query) {
    return 'Không có lượt nghe nào khớp “$query”.';
  }

  @override
  String get historyMenuMissing => 'Không phát được';

  @override
  String get historyTrackEmpty => 'Chưa có lượt nghe nào';

  @override
  String get historyTrackColDay => 'Ngày';

  @override
  String get historyTrackColTime => 'Giờ';

  @override
  String get historyTrackColListened => 'Đã nghe';

  @override
  String historyTrackListHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lượt nghe, mới nhất trước',
    );
    return '$_temp0';
  }

  @override
  String historyTrackRemovePlayLabel(String time, String date) {
    return 'Xoá lượt nghe lúc $time, $date';
  }

  @override
  String historyTrackSummaryLast(String when) {
    return 'Lần cuối: $when';
  }

  @override
  String historyTrackSummaryFirst(String date) {
    return 'Lần đầu: $date';
  }

  @override
  String historyTrackSummaryTotal(String duration) {
    return 'Đã nghe tổng: $duration';
  }

  @override
  String historyTrackListened(String duration) {
    return 'đã nghe $duration';
  }

  @override
  String historyTrackWhen(String day, String time) {
    return '$day $time';
  }

  @override
  String get historyRangeDialogCaption => 'Khoảng tuỳ chọn';

  @override
  String get historyRangePickStart => 'Chọn ngày bắt đầu';

  @override
  String get historyRangePickEnd => 'Chọn ngày kết thúc';

  @override
  String historyRangeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày',
    );
    return '$_temp0';
  }

  @override
  String get historyRangeDayHasListens => 'Có lượt nghe';

  @override
  String get historyRangeStartPlaceholder => 'Ngày bắt đầu';

  @override
  String get historyRangeEndPlaceholder => 'Ngày kết thúc';

  @override
  String get historyRangeSave => 'Lưu';

  @override
  String get historyMostPlayedRange1Day => '1 ngày';

  @override
  String get historyMostPlayedRange7Days => '7 ngày';

  @override
  String get historyMostPlayedRange30Days => '30 ngày';

  @override
  String get historyMostPlayedRange6Months => '6 tháng';

  @override
  String get historyMostPlayedRange1Year => '1 năm';

  @override
  String get historyMostPlayedRangeAll => 'Tất cả';

  @override
  String get historyMostPlayedRangeCustom => 'Tuỳ chọn…';

  @override
  String get historyMostPlayedRangesLabel => 'Khoảng thời gian';

  @override
  String get historyMostPlayedPrevious => 'Kỳ trước';

  @override
  String get historyMostPlayedNext => 'Kỳ sau';

  @override
  String historyMostPlayedTop(int count) {
    return 'Top $count';
  }

  @override
  String get historyMostPlayedTopLabel => 'Số bài hiển thị';

  @override
  String get historyMostPlayedLimitCustom => 'Tuỳ chọn…';

  @override
  String get historyMostPlayedLimitHint => 'Từ 1 đến 1000 bài';

  @override
  String historyMostPlayedLimitCustomValue(int count) {
    return 'Top $count · từ 1 đến 1000 bài';
  }

  @override
  String get historyMostPlayedLimitTitle => 'Số bài xếp hạng';

  @override
  String get historyMostPlayedLimitField => 'Số bài';

  @override
  String get historyMostPlayedLimitError => 'Chỉ nhận số từ 1 đến 1000';

  @override
  String historyMostPlayedHeroTotals(int songs, int plays) {
    String _temp0 = intl.Intl.pluralLogic(
      songs,
      locale: localeName,
      other: '$songs bài',
    );
    String _temp1 = intl.Intl.pluralLogic(
      plays,
      locale: localeName,
      other: '$plays lượt nghe',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String historyMostPlayedPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lượt',
    );
    return '$_temp0';
  }

  @override
  String historyMostPlayedRowMissing(String plays) {
    return '$plays · không phát được';
  }

  @override
  String get historyMostPlayedEmpty => 'Không có lượt nghe trong khoảng này.';

  @override
  String get historyMostPlayedPlayFailed => 'Không phát được danh sách';

  @override
  String get historyMostPlayedMenuPlay => 'Phát (theo thứ hạng)';

  @override
  String historyMostPlayedPlaylistName(String range) {
    return 'Nghe nhiều nhất · $range';
  }

  @override
  String get historyMostPlayedOpenDay => 'Mở trong Phát nhiều nhất';

  @override
  String get historyMostPlayedFavoriteFailed => 'Không thêm được vào Yêu thích';

  @override
  String get savedQueueExplain =>
      'Khi bạn phát thứ khác, hàng đợi bị thay được giữ ở đây (tối đa 20, cũ nhất bị bỏ).';

  @override
  String get savedQueueEmpty =>
      'Chưa có hàng đợi nào được lưu. Khi bạn phát thứ khác, hàng đợi bị thay sẽ được giữ ở đây.';

  @override
  String savedQueueName(String day, String time) {
    return '$day · $time';
  }

  @override
  String savedQueueExportName(String date) {
    return 'Hàng đợi $date';
  }

  @override
  String savedQueueMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài không còn',
    );
    return '$_temp0';
  }

  @override
  String savedQueueFromAlbum(String name) {
    return 'Từ album $name';
  }

  @override
  String savedQueueFromArtist(String name) {
    return 'Từ nghệ sĩ $name';
  }

  @override
  String savedQueueFromGenre(String name) {
    return 'Từ thể loại $name';
  }

  @override
  String savedQueueFromLanguage(String name) {
    return 'Từ ngôn ngữ $name';
  }

  @override
  String savedQueueFromFolder(String name) {
    return 'Từ thư mục $name';
  }

  @override
  String savedQueueFromPlaylist(String name) {
    return 'Từ playlist $name';
  }

  @override
  String get savedQueueFromFavorites => 'Từ Yêu thích';

  @override
  String get savedQueueFromSongs => 'Từ Bài hát';

  @override
  String get savedQueueFromSelection => 'Từ các bài đã chọn';

  @override
  String savedQueueFromList(String name) {
    return 'Từ $name';
  }

  @override
  String get savedQueueNoSongs => 'Hàng đợi này không còn bài nào.';

  @override
  String get savedQueuePlayRow => 'Phát hàng đợi này';

  @override
  String savedQueueBar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài, theo thứ tự đã phát',
    );
    return '$_temp0';
  }

  @override
  String savedQueuePlaying(String name, int count) {
    return 'Đang phát hàng đợi $name ($count bài). Hàng đợi cũ đã được lưu.';
  }

  @override
  String get savedQueueNotFoundTitle => 'Không tìm thấy hàng đợi';

  @override
  String get savedQueueNotFoundMessage =>
      'Hàng đợi này đã bị xoá, hoặc bị bỏ khi có hơn 20 hàng đợi.';

  @override
  String get savedQueueMenuPlay => 'Phát (thay hàng đợi hiện tại)';

  @override
  String get savedQueueMenuAppend => 'Thêm vào cuối hàng đợi';

  @override
  String get savedQueueMenuSaveAsPlaylist => 'Lưu thành playlist…';

  @override
  String get savedQueueMenuRemoveMissing => 'Bỏ các bài không còn';

  @override
  String get savedQueueMenuDelete => 'Xoá hàng đợi này';

  @override
  String get savedQueueDeleteTitle => 'Xoá hàng đợi này?';

  @override
  String get savedQueueDeleteBody => 'Các bài vẫn còn trong thư viện.';

  @override
  String get savedQueueDeleted => 'Đã xoá hàng đợi';

  @override
  String get savedQueueDeleteFailed => 'Không xoá được hàng đợi';

  @override
  String savedQueueRemovedMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã bỏ $count bài',
    );
    return '$_temp0';
  }

  @override
  String get savedQueueRemoveFailed => 'Không bỏ được các bài không còn';

  @override
  String get lyricsLabelTagSynced => 'Lời trong tag · Đồng bộ';

  @override
  String get lyricsLabelTagPlain => 'Lời trong tag · Thường';

  @override
  String get lyricsLabelLrcSynced => 'Tệp .lrc · Đồng bộ';

  @override
  String get lyricsLabelLrcPlain => 'Tệp .lrc · Thường';

  @override
  String get lyricsLabelOff => 'Tắt lời';

  @override
  String get lyricsLabelNone => 'Không có lời';

  @override
  String get lyricsLabelShortTag => 'Trong tag';

  @override
  String get lyricsLabelShortLrc => 'Tệp .lrc';

  @override
  String get lyricsLabelShortOff => 'Tắt';

  @override
  String get lyricsPlainNote =>
      'Lời thường, không có mốc thời gian: không tự cuộn.';

  @override
  String get lyricsNoneTitle => 'Không có lời';

  @override
  String get lyricsNoneMessage =>
      'Không có lời trong tệp hay tệp .lrc cạnh bài.';

  @override
  String get lyricsOffTitle => 'Lời đang tắt cho bài này';

  @override
  String get lyricsOffMessageDesktop => 'Chuột phải nút lời để bật lại nhanh.';

  @override
  String get lyricsOffMessageMobile =>
      'Bạn chọn “Không hiện lời” trong Lời cho bài này.';

  @override
  String get lyricsOffOpenChoice => 'Lời cho bài này';

  @override
  String get lyricsBackToLine => 'Về dòng đang hát';

  @override
  String lyricsSeekHint(String time) {
    return 'Tua tới $time';
  }

  @override
  String get lyricsGapLabel => 'Khoảng nhạc không lời';

  @override
  String get lyricsCardNone => 'Không có lời cho bài này';

  @override
  String get lyricsCardOff => 'Lời đang tắt cho bài này';

  @override
  String get lyricsCardOpenHint => 'Mở màn lời';

  @override
  String lyricsCardLabel(String title, String source) {
    return '$title · $source';
  }

  @override
  String get lyricsTranslateSoon => 'Dịch lời · Sắp có';

  @override
  String get lyricsForTrackTitle => 'Lời cho bài này';

  @override
  String get lyricsModalClose => 'Đóng';

  @override
  String get lyricsModalNoneOnDevice => 'Không có lời trên máy';

  @override
  String get lyricsChoiceFile => 'Lời trong file';

  @override
  String get lyricsChoiceFileNone => 'Không có lời trong file';

  @override
  String get lyricsChoiceOff => 'Không hiện lời';

  @override
  String get lyricsChoiceSubTagSynced => 'Trong tag · Đồng bộ';

  @override
  String get lyricsChoiceSubTagPlain => 'Trong tag · Thường';

  @override
  String get lyricsChoiceSubLrcSynced => 'Tệp .lrc · Đồng bộ';

  @override
  String get lyricsChoiceSubLrcPlain => 'Tệp .lrc · Thường';

  @override
  String get lyricsFindOnline => 'Tìm lời trực tuyến…';

  @override
  String get lyricsFromAudio => 'Tạo lời từ âm thanh…';

  @override
  String get lyricsFromAudioSub => 'Groq Whisper';

  @override
  String get lyricsSaveLyrics => 'Lưu lời…';

  @override
  String lyricsSourceTooltipDesktop(String label) {
    return '$label (L)';
  }

  @override
  String get lyricsSourceToggleHint => 'Chuột phải: bật/tắt lời bài này';

  @override
  String get lyricsSettingsModalSettings => 'Cài đặt lời bài';

  @override
  String get lyricsSettingsDefault => 'Mặc định';

  @override
  String get lyricsSettingsDisplay => 'Hiển thị lời';

  @override
  String get lyricsSettingsFind => 'Tìm và lưu lời';

  @override
  String get lyricsSettingsSources => 'Nguồn lời trực tuyến';

  @override
  String get lyricsSettingsWhere => 'Nơi hiện lời';

  @override
  String get lyricsSettingsTranslation => 'Dịch lời';

  @override
  String get lyricsSettingsSpeech => 'Tạo lời từ âm thanh';

  @override
  String get lyricsSettingsSpeechHint =>
      'Plugin chuyển giọng nói thành chữ, dùng cho “Tạo lời từ âm thanh…” trong Lời cho bài này.';

  @override
  String get lyricsSettingsFontSize => 'Cỡ chữ lời';

  @override
  String get lyricsSettingsFontSizeCaption =>
      'Áp cho màn lời, tab Lời bài và thẻ lời.';

  @override
  String get lyricsSettingsSizeSmall => 'Nhỏ';

  @override
  String get lyricsSettingsSizeMedium => 'Vừa';

  @override
  String get lyricsSettingsSizeLarge => 'Lớn';

  @override
  String get lyricsSettingsAlign => 'Căn lời';

  @override
  String get lyricsSettingsAlignStart => 'Trái';

  @override
  String get lyricsSettingsAlignCenter => 'Giữa';

  @override
  String get lyricsSettingsAutoReturn => 'Tự về dòng đang hát';

  @override
  String get lyricsSettingsAutoReturnCaption =>
      'Sau khi bạn cuộn lời bằng tay. Tắt thì lời đứng yên tới khi bạn bấm “Về dòng đang hát”.';

  @override
  String get lyricsSettingsAutoReturnOff => 'Tắt';

  @override
  String get lyricsSettingsAutoReturn3 => '3 giây';

  @override
  String get lyricsSettingsAutoReturn5 => '5 giây';

  @override
  String get lyricsSettingsAutoReturn10 => '10 giây';

  @override
  String get lyricsSettingsDim => 'Làm mờ dòng không hát';

  @override
  String get lyricsSettingsDimLight => 'Mờ nhẹ';

  @override
  String get lyricsSettingsDimStrong => 'Mờ nhiều';

  @override
  String get lyricsSettingsDimOff => 'Tắt';

  @override
  String get lyricsSettingsRomanize => 'Phiên âm';

  @override
  String get lyricsSettingsRomanizeDesc =>
      'Romaji, Pinyin, Furigana dưới lời tiếng Nhật, Trung, Hàn.';

  @override
  String get lyricsSettingsKeepAwake => 'Giữ màn hình sáng';

  @override
  String get lyricsSettingsKeepAwakeDesc =>
      'Màn hình không tắt khi đang mở màn lời.';

  @override
  String get lyricsSettingsAutoFind => 'Tự tìm lời khi bài không có lời';

  @override
  String get lyricsSettingsAutoFindDesc =>
      'Tìm ở các nguồn lời đang bật khi bài không có lời trong máy.';

  @override
  String get lyricsSettingsLocalFirst => 'Lời trong máy';

  @override
  String get lyricsSettingsLocalFirstCaption =>
      'Lời đồng bộ luôn được chọn trước lời thường.';

  @override
  String get lyricsSettingsLocalTag => 'Lời trong tệp nhạc trước';

  @override
  String get lyricsSettingsLocalTagSub => 'Rồi tới tệp .lrc';

  @override
  String get lyricsSettingsLocalLrc => 'Tệp .lrc trước';

  @override
  String get lyricsSettingsLocalLrcSub => 'Rồi tới lời trong tệp nhạc';

  @override
  String get lyricsSettingsAutoSave => 'Tự lưu lời tìm được thành .lrc';

  @override
  String get lyricsSettingsAutoSaveDesc =>
      'Ghi tệp .lrc cạnh bài khi tìm được lời trực tuyến.';

  @override
  String get lyricsSettingsAddSource => 'Thêm nguồn lời trực tuyến';

  @override
  String get lyricsSettingsFloating => 'Lời nổi trên màn hình';

  @override
  String get lyricsSettingsFloatingDesc =>
      'Cửa sổ lời nhỏ luôn nằm trên các cửa sổ khác.';

  @override
  String get lyricsSettingsLockScreen => 'Lời trên màn khoá và thông báo';

  @override
  String get lyricsSettingsLockScreenDesc =>
      'Dòng đang hát hiện trong thông báo phát nhạc và trên màn khoá.';

  @override
  String get lyricsSettingsTrService => 'Dịch vụ dịch mặc định';

  @override
  String get lyricsSettingsTrServiceNone => 'Chưa chọn';

  @override
  String get lyricsSettingsTrTarget => 'Ngôn ngữ dịch mặc định';

  @override
  String get lyricsSettingsTrTargetApp => 'Theo ngôn ngữ ứng dụng';

  @override
  String get lyricsSettingsTrAhead => 'Dịch trước';

  @override
  String get lyricsSettingsTrAheadNow => 'Chỉ bài đang phát';

  @override
  String get lyricsSettingsAddTrService => 'Thêm dịch vụ dịch';

  @override
  String get lyricsSettingsAddSpeech => 'Thêm plugin chuyển giọng nói';

  @override
  String get lyricsSearchingTitle => 'Đang tìm lời…';

  @override
  String lyricsSearchingMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Bài này chưa có lời trong máy · đang tìm ở $count nguồn đang bật.',
    );
    return '$_temp0';
  }

  @override
  String get lyricsNoneAutoOffMessage =>
      'Không có lời trong tệp hay tệp .lrc cạnh bài. Tự tìm đang tắt.';

  @override
  String get lyricsFindManually => 'Tìm thủ công…';

  @override
  String get lyricsNotFoundTitle => 'Không tìm thấy lời';

  @override
  String lyricsNotFoundAsked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã tìm ở $count nguồn đang bật.',
    );
    return '$_temp0';
  }

  @override
  String lyricsNotFoundOff(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nguồn khác đang tắt.',
    );
    return '$_temp0';
  }

  @override
  String get lyricsNotFoundAllOff =>
      'Không có lời trong máy · mọi nguồn lời trực tuyến đang tắt.';

  @override
  String get lyricsNoSourceMessage =>
      'Bài này không có lời trong máy và chưa có nguồn lời trực tuyến.';

  @override
  String get lyricsAddSource => 'Thêm nguồn lời trực tuyến';

  @override
  String get lyricsInstrumentalTitle => 'Nhạc không lời';

  @override
  String get lyricsInstrumentalMessage =>
      'Nguồn lời ghi bài này là nhạc không lời.';

  @override
  String get lyricsInstrumentalFindOnline => 'Không phải? Tìm lời trực tuyến…';

  @override
  String get lyricsFailedTitle => 'Chưa tìm được lời';

  @override
  String lyricsFailNetwork(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lỗi mạng khi tìm ở $count nguồn đang bật',
    );
    return '$_temp0';
  }

  @override
  String get lyricsFailNeedsConfig => 'Các nguồn cần cấu hình';

  @override
  String get lyricsFailNoAnswer => 'Nguồn lời không trả lời';

  @override
  String lyricsFailedMessage(String reason) {
    return '$reason.';
  }

  @override
  String lyricsFailedMessageRetry(String reason, String time) {
    return '$reason · tự thử lại lúc $time.';
  }

  @override
  String get lyricsPausedTitle => 'Nguồn lời đang tạm dừng';

  @override
  String lyricsPausedMessage(String time) {
    return 'Các nguồn lời đang tạm dừng tới $time: máy chủ báo quá nhiều yêu cầu. Tới giờ đó Kanaru tự tìm lại.';
  }

  @override
  String get lyricsKindSynced => 'Đồng bộ';

  @override
  String get lyricsKindPlain => 'Thường';

  @override
  String lyricsOnlineLabel(String plugin, String kind) {
    return '$plugin · $kind';
  }

  @override
  String get lyricsLabelSearching => 'Đang tìm…';

  @override
  String get lyricsLabelFailed => 'Chưa tìm được lời';

  @override
  String get lyricsLabelPaused => 'Nguồn lời tạm dừng';

  @override
  String lyricsCardFailedRetry(String time) {
    return 'Chưa tìm được lời · thử lại lúc $time';
  }

  @override
  String lyricsCardPaused(String time) {
    return 'Nguồn lời tạm dừng tới $time';
  }

  @override
  String get lyricsChoiceOnline => 'Bản trực tuyến';

  @override
  String get lyricsOnlineAuto => 'tự tìm';

  @override
  String get lyricsOnlineRemoved => 'plugin đã gỡ';

  @override
  String get lyricsOnlineInstrumental => 'Nhạc không lời';

  @override
  String lyricsStatusSearching(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Không có lời trên máy · đang tìm ở $count nguồn đang bật',
    );
    return '$_temp0';
  }

  @override
  String lyricsStatusNotFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Không tìm thấy lời, kể cả ở $count nguồn đang bật',
    );
    return '$_temp0';
  }

  @override
  String get lyricsStatusAutoOff => 'Không có lời trên máy · tự tìm đang tắt';

  @override
  String get lyricsStatusNoSource =>
      'Không có lời trên máy · chưa có nguồn trực tuyến';

  @override
  String get lyricsStatusAllOff =>
      'Không có lời trên máy · mọi nguồn trực tuyến đang tắt';

  @override
  String lyricsStatusFailed(String reason) {
    return 'Chưa tìm được lời · $reason';
  }

  @override
  String lyricsStatusFailedRetry(String reason, String time) {
    return 'Chưa tìm được lời · $reason · thử lại lúc $time';
  }

  @override
  String get lyricsFailShortNetwork => 'lỗi mạng';

  @override
  String get lyricsFailShortNeedsConfig => 'cần cấu hình';

  @override
  String get lyricsFailShortNoAnswer => 'nguồn không trả lời';

  @override
  String lyricsStatusPaused(String time) {
    return 'Các nguồn lời đang tạm dừng tới $time (máy chủ báo quá nhiều yêu cầu)';
  }

  @override
  String lyricsFindOnlineSub(int on, int off) {
    return '$on nguồn đang bật · $off đang tắt';
  }

  @override
  String lyricsFindOnlineSubAllOff(int off) {
    return 'Mọi nguồn đang tắt ($off) · chỉ tìm khi bạn bấm';
  }

  @override
  String get lyricsAddSourceSub => 'Chưa cài plugin lời nào · mở kho plugin';

  @override
  String lyricsBarAutoTitle(String plugin) {
    return 'Tự tìm thấy trên $plugin';
  }

  @override
  String get lyricsBarAutoSub => 'Giữ để lần sau không tìm lại';

  @override
  String get lyricsBarKeptTitle => 'Đang dùng bản đã giữ';

  @override
  String get lyricsBarKeptSub => 'Chỉ cho bài này';

  @override
  String get lyricsBarReject => 'Không đúng bài';

  @override
  String get lyricsBarKeep => 'Giữ bản này';

  @override
  String get lyricsStatusEnableAuto => 'Bật tự tìm';

  @override
  String get lyricsPickerTitle => 'Chọn lời';

  @override
  String get lyricsPickerBack => 'Về Lời cho bài này';

  @override
  String get lyricsPickerSearchHint => 'Tên bài hát, nghệ sĩ';

  @override
  String get lyricsPickerFilterAll => 'Tất cả nguồn';

  @override
  String lyricsPickerGroup(String name, int count) {
    return '$name · $count';
  }

  @override
  String lyricsPickerGroupOff(String name, int count) {
    return '$name · đang tắt · $count';
  }

  @override
  String get lyricsPickerBadgeOff => 'Nguồn đang tắt';

  @override
  String get lyricsPickerDeltaMatch => 'khớp';

  @override
  String get lyricsPickerDeltaMatchTip => 'Thời lượng khớp với bài';

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
    return 'Dài hơn bài $seconds giây: có thể là bản khác (live, remix…)';
  }

  @override
  String lyricsPickerDeltaShorterTip(int seconds) {
    return 'Ngắn hơn bài $seconds giây: có thể là bản khác (live, remix…)';
  }

  @override
  String lyricsPickerSearching(String name) {
    return 'Đang tìm trong $name…';
  }

  @override
  String lyricsPickerFailNetwork(String name) {
    return '$name: lỗi mạng hoặc hết thời gian chờ';
  }

  @override
  String lyricsPickerFailServer(String name) {
    return '$name: máy chủ trả lỗi';
  }

  @override
  String lyricsPickerFailRateLimited(String name) {
    return '$name: máy chủ báo quá nhiều yêu cầu';
  }

  @override
  String lyricsPickerFailInvalid(String name) {
    return '$name: câu trả lời không đọc được';
  }

  @override
  String lyricsPickerNeedsConfig(String name) {
    return '$name · Cần cấu hình';
  }

  @override
  String get lyricsPickerOpenPlugin => 'Mở trang plugin';

  @override
  String lyricsPickerPaused(String name, String time) {
    return '$name tạm dừng tới $time';
  }

  @override
  String get lyricsPickerMoreTitle => 'Chưa thấy lời ưng ý?';

  @override
  String lyricsPickerMoreBody(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Còn $count nguồn đang tắt: $names. Chỉ tìm khi bạn bấm, cài đặt không đổi.',
    );
    return '$_temp0';
  }

  @override
  String get lyricsPickerMoreAction => 'Tìm';

  @override
  String get lyricsPickerEmptyNone => 'Chưa có nguồn nào đang bật';

  @override
  String lyricsPickerEmptyNotFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Không tìm thấy trong $count nguồn đang bật',
    );
    return '$_temp0';
  }

  @override
  String lyricsPickerEmptyOff(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Còn $count nguồn đang tắt ($names). Chỉ tìm khi bạn bấm.',
    );
    return '$_temp0';
  }

  @override
  String lyricsPickerEmptyAction(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tìm trong $count nguồn đang tắt',
    );
    return '$_temp0';
  }

  @override
  String get lyricsPickerAllAsked =>
      'Đã tìm cả nguồn đang tắt cho bài này. Cài đặt nguồn không đổi.';

  @override
  String get lyricsPickerPreview => 'Xem trước';

  @override
  String lyricsPickerPreviewFrom(String name) {
    return 'Xem trước · $name';
  }

  @override
  String get lyricsPickerPickOne => 'Chọn một kết quả';

  @override
  String get lyricsPickerPreviewBack => 'Về danh sách';

  @override
  String get lyricsPickerPreviewBackLabel => 'Về danh sách kết quả';

  @override
  String get lyricsPickerPlainNote => 'Lời thường, không có mốc thời gian';

  @override
  String get lyricsPickerPreviewLoading => 'Đang tải lời…';

  @override
  String get lyricsPickerPreviewFailed => 'Không tải được lời của kết quả này';

  @override
  String get lyricsPickerPreviewMissing => 'Kết quả này không có lời';

  @override
  String get lyricsPickerPreviewInstrumental => 'Bài không lời';

  @override
  String get lyricsPickerFootNote => 'Chỉ áp dụng cho bài này';

  @override
  String get lyricsPickerCancel => 'Huỷ';

  @override
  String get lyricsPickerUse => 'Dùng lời này';

  @override
  String get lyricsPickerSourcesTitle => 'Nguồn tìm kiếm';

  @override
  String get lyricsPickerSourcesAll => 'Tất cả nguồn';

  @override
  String lyricsPickerSourcesResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kết quả',
    );
    return '$_temp0';
  }

  @override
  String get lyricsPickerSourcesNone => 'Không có kết quả';

  @override
  String get lyricsPickerSourcesOff => 'ĐANG TẮT';

  @override
  String get lyricsPickerSourcesOffCaption => 'Chỉ được tìm khi bạn bấm Tìm.';

  @override
  String lyricsPickerSourcesOffResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kết quả · nguồn đang tắt',
    );
    return '$_temp0';
  }

  @override
  String get lyricsPickerSourcesNotAsked => 'Chưa tìm';

  @override
  String get lyricsPickerClearSearch => 'Xoá chữ trong ô tìm';

  @override
  String get pluginsStoreTitle => 'Kho plugin';

  @override
  String get pluginsFilterTooltip => 'Lọc';

  @override
  String pluginsFilterActiveLabel(int count) {
    return '$count đang bật';
  }

  @override
  String get pluginsMenuTooltip => 'Tùy chọn khác';

  @override
  String get pluginsMenuInstallFile => 'Cài từ tệp…';

  @override
  String get pluginsMenuInstallLink => 'Cài từ đường dẫn…';

  @override
  String pluginsMenuRepositories(int count) {
    return 'Repository ($count)';
  }

  @override
  String get pluginsMenuRefreshAll => 'Làm mới tất cả';

  @override
  String get pluginsMenuLogsDesktop => 'Mở thư mục nhật ký';

  @override
  String get pluginsMenuLogsMobile => 'Chia sẻ nhật ký plugin…';

  @override
  String get pluginsSearchHint => 'Tìm tên, tác giả, repository, host, #loại';

  @override
  String get pluginsSearchClear => 'Xoá';

  @override
  String pluginsSectionUpdates(int count) {
    return 'Cập nhật ($count)';
  }

  @override
  String pluginsSectionInstalled(int count) {
    return 'Đã cài ($count)';
  }

  @override
  String pluginsSectionAvailable(int count) {
    return 'Chưa cài ($count)';
  }

  @override
  String get pluginsUpdatesHint =>
      '“Cập nhật tất cả” bỏ qua bản có host hoặc quyền mới: các bản “Cần xem” bạn mở từng bản, như lúc cài.';

  @override
  String get pluginsUpdatesHintTooltip => 'Giải thích về cập nhật';

  @override
  String pluginsUpdateAll(int count) {
    return 'Cập nhật tất cả ($count)';
  }

  @override
  String get pluginsUpdate => 'Cập nhật';

  @override
  String pluginsUpdateTooltip(String name) {
    return 'Cập nhật $name';
  }

  @override
  String pluginsReviewTooltip(String name) {
    return 'Xem bản cập nhật $name';
  }

  @override
  String get pluginsPageSettingsTitle => 'Cài đặt của plugin';

  @override
  String get pluginsPageRefreshFailed => 'Không làm mới được danh sách';

  @override
  String pluginsInstallTooltip(String name) {
    return 'Cài $name';
  }

  @override
  String pluginsRemoveTooltip(String name) {
    return 'Xoá $name';
  }

  @override
  String get pluginsAlertLabel => 'Có lỗi';

  @override
  String get pluginsFreeStreamingLimit =>
      'Bản Free chỉ cài được một plugin nguồn nhạc. Gỡ plugin hiện có để cài plugin này.';

  @override
  String get pluginsKindLyrics => 'Lời bài';

  @override
  String get pluginsKindTranslate => 'Dịch';

  @override
  String get pluginsKindStreaming => 'Nguồn nhạc';

  @override
  String get pluginsKindHelpLyrics =>
      'Tìm lời cho bài đang nghe, có lời chạy theo dòng.';

  @override
  String get pluginsKindHelpTranslate => 'Dịch lời bài sang ngôn ngữ bạn chọn.';

  @override
  String get pluginsKindHelpStreaming =>
      'Tìm và phát nhạc từ một dịch vụ trực tuyến.';

  @override
  String get pluginsAuthorUnknown => 'Không rõ tác giả';

  @override
  String pluginsFooterNewer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plugin cần Kanaru mới hơn',
    );
    return '$_temp0';
  }

  @override
  String get pluginsSandboxNote =>
      'Plugin chạy trong hộp cát và chỉ kết nối được tới các địa chỉ đã khai lúc cài.';

  @override
  String get pluginsNoMatch => 'Không có plugin khớp.';

  @override
  String get pluginsClearFilters => 'Xoá bộ lọc';

  @override
  String get pluginsLoadFailed => 'Không đọc được danh sách plugin.';

  @override
  String get pluginsNoRepoTitle => 'Chưa có repository nào';

  @override
  String get pluginsNoRepoBody =>
      'Kanaru không có sẵn repository nào. Repository là một danh sách plugin (tệp plugins.json) do người viết plugin đăng.';

  @override
  String get pluginsNoRepoStep1 =>
      'Tìm địa chỉ tệp plugins.json của repository bạn tin, thường ghi trong trang giới thiệu (README) của người viết plugin. Địa chỉ bắt đầu bằng https://.';

  @override
  String get pluginsNoRepoStep2 =>
      'Bấm Thêm repository, dán địa chỉ, rồi bấm Thêm.';

  @override
  String get pluginsNoRepoStep3 =>
      'Plugin của repository hiện ở đây; bấm Cài để xem host và dữ kiện trước khi cài.';

  @override
  String get pluginsAddRepository => 'Thêm repository';

  @override
  String pluginsRepoFailedOne(String name, String reason) {
    return 'Không tải được $name: $reason';
  }

  @override
  String pluginsRepoFailedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repository không tải được',
    );
    return '$_temp0';
  }

  @override
  String pluginsRepoShowingSaved(String time) {
    return 'Đang hiện danh sách lưu lúc $time.';
  }

  @override
  String get pluginsRetry => 'Thử lại';

  @override
  String get pluginsOfflineTitle => 'Không có kết nối mạng';

  @override
  String get pluginsOfflineBody =>
      'Đang hiện danh sách lưu lần trước. Cài và cập nhật cần mạng.';

  @override
  String get pluginsLoadReasonNetwork => 'lỗi mạng';

  @override
  String get pluginsLoadReasonNotFound => 'không tìm thấy file';

  @override
  String get pluginsLoadReasonTooLarge => 'file quá lớn';

  @override
  String get pluginsLoadReasonInvalid => 'không phải danh sách plugin hợp lệ';

  @override
  String get pluginsLoadReasonBlocked => 'địa chỉ bị chặn';

  @override
  String get pluginsLoadReasonStorage => 'không lưu được';

  @override
  String get pluginsFilterTitle => 'Lọc';

  @override
  String get pluginsFilterGroupKind => 'Loại plugin';

  @override
  String get pluginsFilterGroupState => 'Trạng thái';

  @override
  String get pluginsFilterGroupLanguage => 'Ngôn ngữ';

  @override
  String get pluginsFilterGroupAuthor => 'Tác giả';

  @override
  String get pluginsFilterGroupRepository => 'Repository';

  @override
  String get pluginsStateInstalled => 'Đã cài';

  @override
  String get pluginsStateNotInstalled => 'Chưa cài';

  @override
  String get pluginsStateUpdatable => 'Có bản cập nhật';

  @override
  String pluginsFilterShowing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hiện $count plugin',
    );
    return '$_temp0';
  }

  @override
  String get pluginsFilterClearAll => 'Xoá hết';

  @override
  String get pluginsFilterDone => 'Xong';

  @override
  String get pluginsReposTitle => 'Repository';

  @override
  String get pluginsReposRefreshAll => 'Làm mới tất cả';

  @override
  String pluginsRepoPluginCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plugin',
    );
    return '$_temp0';
  }

  @override
  String pluginsRepoLastError(String reason) {
    return 'Lần tải gần nhất bị lỗi: $reason';
  }

  @override
  String pluginsRepoRemoveTooltip(String name) {
    return 'Gỡ repository $name';
  }

  @override
  String get pluginsReposEmpty => 'Chưa có repository nào.';

  @override
  String get pluginsReposFooter =>
      'Gỡ một repository thì plugin đã cài từ đó vẫn giữ, nhưng không nhận cập nhật nữa.';

  @override
  String get pluginsAddDialogUrlLabel => 'URL';

  @override
  String get pluginsAddDialogUrlHint => 'https://…/plugins.json';

  @override
  String get pluginsAddDialogHelper =>
      'Địa chỉ tệp plugins.json. Phải là https, trừ máy trong mạng nhà (localhost, 192.168.x…).';

  @override
  String get pluginsAddDialogConfirm => 'Thêm';

  @override
  String get pluginsAddDialogLoading => 'Đang tải…';

  @override
  String get pluginsCancel => 'Huỷ';

  @override
  String pluginsAddedRepo(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã thêm $name · $count plugin',
    );
    return '$_temp0';
  }

  @override
  String get pluginsAddErrNeedsHttps => 'Địa chỉ công khai cần https';

  @override
  String get pluginsAddErrInvalidUrl => 'URL không hợp lệ';

  @override
  String get pluginsAddErrDuplicate => 'Repository này đã được thêm';

  @override
  String get pluginsAddErrNetwork => 'Không tải được danh sách: lỗi mạng';

  @override
  String get pluginsAddErrNotFound =>
      'Không thấy danh sách plugin ở địa chỉ này';

  @override
  String get pluginsAddErrBadFormat =>
      'File không phải danh sách plugin hợp lệ';

  @override
  String get pluginsAddErrBlocked => 'Địa chỉ này bị chặn';

  @override
  String pluginsAddErrBlockedReason(String reason) {
    return 'Địa chỉ này bị chặn: $reason';
  }

  @override
  String get pluginsAddErrStorage => 'Không lưu được repository';

  @override
  String get pluginsAddressUserInfo =>
      'địa chỉ không được chứa tên người dùng hay mật khẩu';

  @override
  String get pluginsAddressLocalFromPublic =>
      'repository công khai không được trỏ tới địa chỉ cục bộ';

  @override
  String get pluginsAddressRefused => 'địa chỉ này không được phép truy cập';

  @override
  String get pluginsAddressMixed =>
      'tên miền trỏ tới cả địa chỉ cục bộ và công khai';

  @override
  String get pluginsAddressLocalNamePublic =>
      'tên trông như cục bộ lại trỏ tới địa chỉ công khai';

  @override
  String pluginsRemoveRepoTitle(String name) {
    return 'Gỡ $name?';
  }

  @override
  String get pluginsRemoveRepoBody =>
      'Plugin đã cài từ repository này vẫn được giữ, nhưng sẽ không còn nhận cập nhật.';

  @override
  String get pluginsRemoveRepoConfirm => 'Gỡ';

  @override
  String pluginsRemoveRepoFailed(String name) {
    return 'Không gỡ được $name';
  }

  @override
  String get pluginsRootAlertLabel => 'Có plugin lỗi hoặc bản cập nhật cần xem';

  @override
  String get pluginsPkgClose => 'Đóng';

  @override
  String get pluginsPkgLoading => 'Đang tải và kiểm gói…';

  @override
  String pluginsPkgProgress(int done, int total) {
    return '$done / $total KB · kiểm plugin.json, tên tệp, host, script';
  }

  @override
  String pluginsPkgProgressUnknown(int done) {
    return '$done KB · kiểm plugin.json, tên tệp, host, script';
  }

  @override
  String get pluginsPkgChecking => 'Kiểm plugin.json, tên tệp, host, script';

  @override
  String pluginsPkgInstallTitle(String name) {
    return 'Cài $name?';
  }

  @override
  String pluginsPkgUpdateTitle(String name) {
    return 'Cập nhật $name';
  }

  @override
  String pluginsPkgInstallSubtitle(String kind, int version, String author) {
    return 'Plugin $kind · bản $version · $author';
  }

  @override
  String pluginsPkgUpdateSubtitle(String kind, String author) {
    return '$kind · $author';
  }

  @override
  String pluginsPkgAuthorDeclared(String author) {
    return '$author (tự khai báo)';
  }

  @override
  String pluginsPkgFromRepo(String name) {
    return 'Từ repository $name';
  }

  @override
  String pluginsPkgFromFile(String name, String size) {
    return 'Từ tệp $name · $size';
  }

  @override
  String get pluginsPkgFromLink => 'Từ đường dẫn';

  @override
  String get pluginsPkgSendTo => 'Gửi dữ liệu tới';

  @override
  String pluginsPkgWildcard(String labels) {
    return '$labels: chỉ plugin nguồn nhạc được khai kiểu này (tối đa 10).';
  }

  @override
  String pluginsPkgWildcardHost(String domain) {
    return 'Mọi tên miền con của $domain';
  }

  @override
  String pluginsPkgUserEndpoint(String field) {
    return 'Địa chỉ bạn nhập ở ô $field';
  }

  @override
  String get pluginsPkgNoHosts => 'Không có địa chỉ cố định.';

  @override
  String get pluginsPkgNewBadge => 'MỚI';

  @override
  String get pluginsPkgConsentInstall =>
      'Cài plugin là bạn đồng ý cho nó gửi dữ liệu tới các địa chỉ này. Kanaru không hỏi thêm khi plugin chạy.';

  @override
  String get pluginsPkgConsentUpdate =>
      'Cập nhật là bạn đồng ý cho plugin gửi dữ liệu tới cả các địa chỉ mới. Kanaru không hỏi thêm khi plugin chạy.';

  @override
  String get pluginsPkgFacts => 'Dữ kiện tĩnh';

  @override
  String get pluginsPkgFactsUpdate => 'Dữ kiện tĩnh · so với bản đang cài';

  @override
  String get pluginsPkgAskAi => 'Hỏi AI về plugin này';

  @override
  String get pluginsPkgAskAiUpdate => 'Hỏi AI xem bản mới đổi gì';

  @override
  String get pluginsPkgLater => 'Để sau';

  @override
  String get pluginsPkgInstall => 'Cài';

  @override
  String get pluginsPkgUpdate => 'Cập nhật';

  @override
  String get pluginsPkgInstalling => 'Đang cài…';

  @override
  String get pluginsPkgUpdating => 'Đang cập nhật…';

  @override
  String pluginsPkgInstalled(String name) {
    return 'Đã cài $name';
  }

  @override
  String pluginsPkgUpdated(String name, int version) {
    return 'Đã cập nhật $name lên bản $version';
  }

  @override
  String pluginsPkgErrDownload(String reason) {
    return 'Không tải được gói plugin: $reason';
  }

  @override
  String pluginsPkgErrFile(String reason) {
    return 'Không đọc được tệp: $reason';
  }

  @override
  String get pluginsPkgNothingNetwork =>
      'Kiểm tra kết nối rồi thử lại. Chưa có gì được cài.';

  @override
  String get pluginsPkgNothing => 'Chưa có gì được cài.';

  @override
  String get pluginsPkgReasonNetwork => 'lỗi mạng';

  @override
  String get pluginsPkgReasonTimeout => 'quá thời gian chờ';

  @override
  String pluginsPkgReasonStatus(int status) {
    return 'máy chủ trả lời $status';
  }

  @override
  String get pluginsPkgReasonTooLarge => 'gói quá lớn';

  @override
  String get pluginsPkgReasonBlocked => 'địa chỉ bị chặn';

  @override
  String get pluginsPkgReasonInvalidUrl => 'URL không hợp lệ';

  @override
  String get pluginsPkgReasonCancelled => 'đã huỷ';

  @override
  String get pluginsPkgReasonNotZip => 'không phải tệp .zip';

  @override
  String get pluginsPkgReasonFileLarge => 'tệp quá lớn';

  @override
  String get pluginsPkgReasonUnreadable => 'không đọc được';

  @override
  String get pluginsPkgReasonFileSlow => 'nơi lưu tệp không trả lời kịp';

  @override
  String get pluginsPkgErrGone =>
      'Plugin này không còn trong danh sách của repository.';

  @override
  String get pluginsPkgErrUnexpected =>
      'Có lỗi khi kiểm gói. Chưa có gì được cài.';

  @override
  String get pluginsPkgErrWrite =>
      'Không ghi được plugin vào máy. Chưa có gì thay đổi.';

  @override
  String get pluginsPkgNoticeStale =>
      'Plugin đã thay đổi trong lúc bạn xem. Kanaru đã kiểm lại gói: hãy xem lại trước khi cài.';

  @override
  String get pluginsPkgNoticeExpired =>
      'Gói chờ quá lâu nên Kanaru đã kiểm lại.';

  @override
  String get pluginsPkgProTitle => 'Cần Kanaru Pro';

  @override
  String get pluginsPkgFilePickerFailed => 'Không mở được hộp chọn tệp.';

  @override
  String get pluginsProblemTitle => 'Không cài được';

  @override
  String pluginsProblemFileBody(String name) {
    return 'Tệp $name không phải plugin hợp lệ.';
  }

  @override
  String pluginsProblemPluginBody(String name) {
    return 'Không cài được $name.';
  }

  @override
  String get pluginsProblemReasons => 'Lý do';

  @override
  String get pluginsProblemHostsNote =>
      'Plugin chỉ được khai tên miền công khai (https).';

  @override
  String get pluginsProblemNewerTitle => 'Cần Kanaru mới hơn';

  @override
  String pluginsProblemNewerBody(String name) {
    return '$name dùng API plugin mới hơn bản Kanaru này hỗ trợ. Hãy cập nhật Kanaru rồi cài lại.';
  }

  @override
  String pluginsProblemNewerBodyVersion(String name, String version, int max) {
    return '$name dùng API plugin mới hơn bản Kanaru này hỗ trợ (apiVersion $version, bản này hỗ trợ tới $max). Hãy cập nhật Kanaru rồi cài lại.';
  }

  @override
  String get pluginsReasonTooLarge => 'Gói, hoặc một mục trong gói, quá lớn';

  @override
  String get pluginsReasonNotZip => 'File không phải gói zip đọc được';

  @override
  String pluginsReasonUnsafeEntry(String detail) {
    return 'Gói có tên mục không an toàn ($detail)';
  }

  @override
  String get pluginsReasonTooManyEntries => 'Gói có quá nhiều file';

  @override
  String get pluginsReasonMissingManifest => 'Không thấy plugin.json ở đầu gói';

  @override
  String pluginsReasonInvalidManifest(String detail) {
    return 'Mục “$detail” trong plugin.json không hợp lệ';
  }

  @override
  String get pluginsReasonInvalidManifestPlain => 'plugin.json không hợp lệ';

  @override
  String pluginsReasonUnknownFormat(String detail) {
    return '$detail: kiểu ô này không được hỗ trợ';
  }

  @override
  String get pluginsReasonNeedsNewerApp =>
      'Cần Kanaru mới hơn: plugin dùng API plugin mới hơn bản này hỗ trợ';

  @override
  String get pluginsReasonUnsupportedKind =>
      'plugin.json: type không phải loại plugin Kanaru này chạy được';

  @override
  String pluginsReasonBadHost(String detail) {
    return 'hosts: “$detail” không phải tên miền công khai';
  }

  @override
  String pluginsReasonBadWildcard(String detail) {
    return 'hosts: “$detail” không phải wildcard hợp lệ: hãy viết *. rồi một tên miền công khai';
  }

  @override
  String pluginsReasonWildcardNotAllowed(String detail) {
    return 'hosts: “$detail”: chỉ plugin nguồn nhạc mới được dùng host wildcard';
  }

  @override
  String pluginsReasonSharedHosting(String detail) {
    return 'hosts: “$detail” bao cả một tên miền hosting dùng chung, nơi ai cũng lấy được tên miền con';
  }

  @override
  String pluginsReasonTooManyWildcards(String detail, int max) {
    return 'hosts: “$detail” vượt giới hạn $max host wildcard';
  }

  @override
  String pluginsReasonMissingScript(String detail) {
    return 'Không thấy src/$detail trong gói';
  }

  @override
  String pluginsReasonScriptNotUtf8(String detail) {
    return 'Script $detail không phải UTF-8';
  }

  @override
  String pluginsReasonScriptError(String detail) {
    return 'Script $detail bị lỗi';
  }

  @override
  String pluginsReasonScriptErrorLine(String detail, int line) {
    return 'Script $detail bị lỗi ở dòng $line';
  }

  @override
  String get pluginsReasonCheckUnavailable =>
      'Kanaru chưa kiểm tra được script lúc này (thành phần chạy plugin không tải được) nên chưa biết gói có hợp lệ không';

  @override
  String get pluginsReasonSameVersion =>
      'Gói này cùng phiên bản với bản đã cài.';

  @override
  String get pluginsReasonOlderVersion =>
      'Gói này cũ hơn bản đã cài nên không được dùng.';

  @override
  String get pluginsReasonKindChange =>
      'Gói này thuộc loại plugin khác với bản đã cài nên không được dùng. Hãy xoá plugin rồi cài bản mới.';

  @override
  String pluginsReasonOtherOrigin(String source) {
    return 'Plugin này đã được cài từ $source. Gói từ nơi khác không thay được nó: hãy xoá plugin đã cài rồi cài lại.';
  }

  @override
  String pluginsOriginRepo(String url) {
    return 'repository $url';
  }

  @override
  String pluginsOriginFile(String name) {
    return 'tệp $name';
  }

  @override
  String get pluginsOriginLink => 'một đường dẫn';

  @override
  String get pluginsOriginOther => 'một nguồn khác';

  @override
  String get pluginsMismatchTitle => 'Gói không khớp danh sách';

  @override
  String pluginsMismatchBody(String name, String repo) {
    return '$name · Repository: $repo';
  }

  @override
  String get pluginsMismatchDiffs => 'Điểm khác biệt';

  @override
  String get pluginsMismatchKind => 'Loại plugin của gói khác với danh sách';

  @override
  String get pluginsMismatchVersion => 'Phiên bản của gói khác với danh sách';

  @override
  String get pluginsMismatchHosts => 'Host của gói khác với danh sách';

  @override
  String get pluginsMismatchSha => 'Mã sha256 của gói khác với danh sách';

  @override
  String get pluginsMismatchSize => 'Kích thước của gói khác với danh sách';

  @override
  String get pluginsMismatchHint =>
      'Thường do repository vừa được cập nhật và cache chưa kịp đổi. Hãy làm mới danh sách rồi thử lại sau vài phút. Nếu vẫn khác, hãy báo cho chủ repository.';

  @override
  String get pluginsMismatchRetry => 'Làm mới rồi thử lại';

  @override
  String get pluginsLinkTitle => 'Cài từ đường dẫn';

  @override
  String get pluginsLinkLabel => 'Đường dẫn tới gói .zip';

  @override
  String get pluginsLinkHint => 'https://…/plugin.zip';

  @override
  String get pluginsLinkHelper =>
      'Kanaru tải gói, kiểm rồi hiện màn cài; chưa cài gì cho tới khi bạn bấm Cài.';

  @override
  String get pluginsLinkHelperCatalog =>
      'Đây là danh sách plugin (plugins.json), không phải gói. Thêm nó làm repository?';

  @override
  String get pluginsLinkErrInvalid => 'URL không hợp lệ';

  @override
  String get pluginsLinkContinue => 'Tiếp tục';

  @override
  String get pluginsLinkAddRepo => 'Thêm repository';

  @override
  String pluginsUpdateAllRunning(int done, int total) {
    return 'Đang cập nhật $done / $total…';
  }

  @override
  String pluginsUpdateFailedLine(String reason) {
    return 'Không cập nhật được: $reason';
  }

  @override
  String get pluginsUpdateReasonProblems => 'gói mới không hợp lệ';

  @override
  String get pluginsUpdateReasonGone => 'plugin hoặc repository không còn';

  @override
  String get pluginsUpdateReasonNoNewer => 'chưa có bản mới hơn';

  @override
  String get pluginsUpdateReasonStorage => 'không ghi được vào máy';

  @override
  String get pluginsUpdateReasonPro => 'cần Kanaru Pro';

  @override
  String get pluginsUpdateReasonOther => 'có lỗi xảy ra';

  @override
  String pluginsUpdateNeedsReview(String name) {
    return 'Bản mới của $name thêm host hoặc quyền mới: bấm Xem để duyệt.';
  }

  @override
  String pluginsUpdateAllUpdated(int count) {
    return 'Đã cập nhật $count plugin';
  }

  @override
  String pluginsUpdateAllReview(int count) {
    return '$count bản cần xem (host hoặc quyền mới): mở từng bản';
  }

  @override
  String pluginsUpdateAllFailed(int count) {
    return '$count bản không cập nhật được';
  }

  @override
  String pluginsRemoveTitle(String name) {
    return 'Xoá $name?';
  }

  @override
  String pluginsRemoveBy(String author, int version) {
    return '$author · bản $version';
  }

  @override
  String get pluginsRemoveWillDelete => 'Sẽ bị xoá';

  @override
  String get pluginsRemoveCode => 'Code của plugin';

  @override
  String get pluginsRemoveSettings => 'Cài đặt của plugin';

  @override
  String get pluginsRemoveConfirm => 'Xoá';

  @override
  String pluginsRemoved(String name) {
    return 'Đã xoá $name';
  }

  @override
  String pluginsRemoveFailed(String name) {
    return 'Không xoá được $name';
  }

  @override
  String get pluginsPkgLoadingTitle => 'Cài plugin';

  @override
  String pluginsUpdatedNoVersion(String name) {
    return 'Đã cập nhật $name';
  }

  @override
  String get pluginsPageTitle => 'Chi tiết plugin';

  @override
  String get pluginsPageLoadFailed => 'Không đọc được danh sách plugin';

  @override
  String get pluginsPageGone => 'Plugin này không còn được cài.';

  @override
  String get pluginsPageToStore => 'Về Kho plugin';

  @override
  String pluginsPageByline(String author, int version) {
    return '$author · bản $version';
  }

  @override
  String pluginsPageUpdateTitle(int version) {
    return 'Có bản mới bản $version';
  }

  @override
  String get pluginsPageUpdateBusy => 'Đang xử lý';

  @override
  String pluginsPageReviewBody(String hosts) {
    return 'Bản mới kết nối thêm tới $hosts: xem trước khi cập nhật.';
  }

  @override
  String get pluginsPageReviewBodyAny =>
      'Bản mới thêm host hoặc quyền mới: xem trước khi cập nhật.';

  @override
  String get pluginsPageReviewButton => 'Xem bản cập nhật';

  @override
  String get pluginsPageRefreshList => 'Làm mới danh sách';

  @override
  String pluginsPageNeedsConfigTitle(String name) {
    return '$name cần được cấu hình';
  }

  @override
  String pluginsPageNeedsConfigBody(String fields) {
    return 'Plugin chưa chạy được tới khi có: $fields.';
  }

  @override
  String get pluginsPageOpenConfig => 'Mở cấu hình';

  @override
  String get pluginsPageBrokenTitle => 'Không đọc được gói của plugin';

  @override
  String get pluginsPageBrokenBody =>
      'Thư mục của plugin bị thiếu hoặc hỏng nên plugin không chạy. Cài lại giữ nguyên cài đặt và dữ liệu.';

  @override
  String get pluginsPageBrokenBodyFile =>
      'Thư mục của plugin bị thiếu hoặc hỏng nên plugin không chạy. Plugin này cài từ file: hãy xoá rồi cài file mới.';

  @override
  String get pluginsPageReinstall => 'Cài lại';

  @override
  String pluginsPageReinstalled(String name) {
    return 'Đã cài lại $name';
  }

  @override
  String pluginsPageReinstallFailed(String reason) {
    return 'Không cài lại được: $reason';
  }

  @override
  String get pluginsPageDetails => 'Chi tiết';

  @override
  String get pluginsPageFrom => 'Cài từ';

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
    return 'Đường dẫn: $name';
  }

  @override
  String get pluginsPageNoUpdatesFile =>
      'Plugin này cài từ file nên không có cập nhật. Hãy xoá rồi cài file mới.';

  @override
  String get pluginsPageNoUpdatesLink =>
      'Plugin này cài từ đường dẫn nên không có cập nhật. Hãy xoá rồi cài bản mới.';

  @override
  String pluginsPageWildcardLine(String label, String host) {
    return '$label ($host)';
  }

  @override
  String get pluginsPageNotEntered => '(chưa nhập)';

  @override
  String pluginsPageEndpointLine(String field, String hosts) {
    return 'Địa chỉ bạn nhập ở ô $field: $hosts';
  }

  @override
  String get pluginsPageInstalledAt => 'Cài lúc';

  @override
  String pluginsPageInstalledDates(String installed, String updated) {
    return '$installed · cập nhật $updated';
  }

  @override
  String get pluginsPageDescription => 'Mô tả';

  @override
  String get pluginsPageType => 'Loại';

  @override
  String pluginsPageTypeValue(String kind, int api) {
    return 'Plugin $kind · API plugin $api';
  }

  @override
  String pluginsPageTypeValueAi(String kind, int api) {
    return 'Plugin $kind · AI · API plugin $api';
  }

  @override
  String get pluginsPageSourceCode => 'Mã nguồn';

  @override
  String get pluginsPageUseLyrics => 'Tự tìm lời';

  @override
  String get pluginsPageUseTranslate => 'Dịch vụ dịch mặc định';

  @override
  String get pluginsPageConnection => 'Kết nối';

  @override
  String get pluginsPageData => 'Dữ liệu';

  @override
  String get pluginsPageOwnStorage => 'Bộ nhớ riêng của plugin';

  @override
  String get pluginsPageSavedLyrics => 'Lời đã lưu từ nguồn này';

  @override
  String get pluginsPageTrackCache => 'Cache bài và ảnh bìa';

  @override
  String get pluginsPageLog => 'Nhật ký';

  @override
  String get pluginsPageOpen => 'Mở';

  @override
  String get pluginsPageBadgeAi => 'AI';

  @override
  String get pluginsRepoAddressCopied => 'Đã chép địa chỉ repository';

  @override
  String get pluginsRepoCopyAddress => 'Chép địa chỉ';

  @override
  String get pluginsCfgReadFailed => 'Không đọc được cài đặt của plugin';

  @override
  String get pluginsCfgRequired => 'Cài đặt này là bắt buộc';

  @override
  String get pluginsCfgNotNumber => 'Nhập một số';

  @override
  String get pluginsCfgNotInteger => 'Nhập một số nguyên';

  @override
  String pluginsCfgMin(String min) {
    return 'Phải từ $min trở lên';
  }

  @override
  String pluginsCfgMax(String max) {
    return 'Phải từ $max trở xuống';
  }

  @override
  String pluginsCfgMinLength(String n) {
    return 'Nhập ít nhất $n ký tự';
  }

  @override
  String pluginsCfgMaxLength(String n) {
    return 'Nhập tối đa $n ký tự';
  }

  @override
  String get pluginsCfgBadUrl => 'Nhập địa chỉ https';

  @override
  String pluginsCfgTooFew(String n) {
    return 'Chọn hoặc thêm ít nhất $n mục';
  }

  @override
  String pluginsCfgTooMany(String n) {
    return 'Chỉ được tối đa $n mục';
  }

  @override
  String get pluginsCfgBadItem => 'Một trong các mục không hợp lệ';

  @override
  String get pluginsCfgBadName =>
      'Nhập tên dài 1 đến 100 ký tự, không có khoảng trắng ở hai đầu';

  @override
  String get pluginsCfgDuplicateName => 'Một dòng khác đã dùng tên này';

  @override
  String get pluginsCfgRefusedValue => 'Cài đặt này không nhận giá trị đó.';

  @override
  String get pluginsCfgRefusedTooLarge =>
      'Cài đặt của plugin quá lớn, không lưu được.';

  @override
  String get pluginsCfgRefusedGone =>
      'Cài đặt này không còn nữa. Plugin có thể đã bị gỡ hoặc đổi.';

  @override
  String get pluginsCfgRefusedOther => 'Không lưu được cài đặt (thử lại sau)';

  @override
  String get pluginsCfgNotChosen => 'Chưa chọn';

  @override
  String get pluginsCfgNoModel => 'Chưa có model';

  @override
  String get pluginsCfgOwnTag => 'Tự thêm';

  @override
  String get pluginsCfgRemoveModel => 'Xoá model này';

  @override
  String get pluginsCfgAddModel => 'Thêm model…';

  @override
  String get pluginsCfgAddModelTitle => 'Thêm model';

  @override
  String get pluginsCfgModelNameHint => 'Tên model, đúng như máy chủ yêu cầu';

  @override
  String get pluginsCfgModelNoteHint =>
      'Ghi chú (tuỳ chọn), ví dụ: Ollama máy nhà';

  @override
  String get pluginsCfgAddAndChoose => 'Thêm và chọn';

  @override
  String pluginsCfgMaxChosen(String n) {
    return 'Tối đa $n';
  }

  @override
  String get pluginsCfgAddRow => 'Thêm';

  @override
  String get pluginsCfgRemoveRow => 'Xoá';

  @override
  String get pluginsCfgNameLabel => 'Tên';

  @override
  String get pluginsCfgValueLabel => 'Giá trị';

  @override
  String pluginsCfgStepDown(String step) {
    return 'Giảm $step';
  }

  @override
  String pluginsCfgStepUp(String step) {
    return 'Tăng $step';
  }

  @override
  String pluginsPageUseLyricsOn(int position, int total) {
    return 'Đang dùng · thứ $position / $total · đổi ở Cài đặt › Lời bài › Nguồn lời';
  }

  @override
  String get pluginsPageUseLyricsOff =>
      'Tắt: chỉ tìm khi bạn bấm “Tìm lời trực tuyến…” · đổi ở Cài đặt › Lời bài › Nguồn lời';

  @override
  String pluginsDataStorageValue(int used, int quota) {
    return '$used KB / $quota KB';
  }

  @override
  String get pluginsDataClear => 'Xoá';

  @override
  String get pluginsDataClearStorageTitle => 'Xoá bộ nhớ riêng của plugin?';

  @override
  String get pluginsDataClearStorageBody =>
      'Plugin có thể phải đăng nhập hoặc thiết lập lại.';

  @override
  String get pluginsDataStorageCleared => 'Đã xoá bộ nhớ riêng';

  @override
  String pluginsDataSavedLyricsValue(int count, String size) {
    return '$count bài · $size';
  }

  @override
  String get pluginsDataSavedLyricsNone => 'Chưa có';

  @override
  String get pluginsDataClearLyricsTitle => 'Xoá lời đã lưu từ nguồn này?';

  @override
  String get pluginsDataClearLyricsBody =>
      'Lời đã lưu từ nguồn này sẽ bị xoá. Lời đã ghim và file .lrc vẫn giữ.';

  @override
  String get pluginsDataLyricsCleared => 'Đã xoá lời đã lưu';

  @override
  String get pluginsDataClearFailed => 'Không xoá được dữ liệu';

  @override
  String pluginsDataLogSummary(int errors, int total) {
    return '$errors lỗi hôm nay · $total mục';
  }

  @override
  String get pluginsDataLogNoErrors => 'Không có lỗi';

  @override
  String pluginsPausedTitle(int minutes) {
    return 'Tạm dừng $minutes phút: máy chủ báo quá nhiều yêu cầu (429)';
  }

  @override
  String pluginsPausedBody(String time) {
    return 'Kanaru hỏi lại nguồn này sau $time. Các nguồn khác vẫn tìm bình thường.';
  }

  @override
  String get pluginsLogsTitle => 'Nhật ký';

  @override
  String get pluginsLogsFilterLabel => 'Lọc nhật ký';

  @override
  String get pluginsLogsAll => 'Tất cả';

  @override
  String get pluginsLogsErrors => 'Lỗi';

  @override
  String get pluginsLogsCaption =>
      'Mỗi lần plugin chạy lỗi hoặc ghi ra console. Kanaru che giá trị cài đặt, bộ nhớ riêng và token mà nó biết. Plugin vẫn có thể tự ghi thông tin khác: xem lại trước khi chia sẻ.';

  @override
  String pluginsLogsFooter(String path) {
    return 'Giữ 7 ngày gần nhất (tối đa 1 MB mỗi plugin). Tệp: $path';
  }

  @override
  String get pluginsLogsEmpty => 'Chưa có mục nào';

  @override
  String get pluginsLogsLoadFailed => 'Không đọc được nhật ký';

  @override
  String get pluginsLogsOpenFolder => 'Mở thư mục log';

  @override
  String get pluginsLogsOpenFailed => 'Không mở được thư mục log';

  @override
  String pluginsLogsShareSoon(String soon) {
    return 'Chia sẻ · $soon';
  }

  @override
  String get pluginsLogsClear => 'Xoá nhật ký';

  @override
  String get pluginsLogsClearTitle => 'Xoá nhật ký của plugin?';

  @override
  String pluginsLogsClearBody(String name) {
    return 'Các mục nhật ký của $name bị xoá. Không ảnh hưởng tới plugin.';
  }

  @override
  String get pluginsLogsCleared => 'Đã xoá nhật ký';

  @override
  String pluginsLogsJobTarget(String job, String target) {
    return '$job · $target';
  }

  @override
  String get pluginsLogsResultOk => 'Chỉ ghi ra console';

  @override
  String pluginsLogsResultError(String reason) {
    return 'Lỗi: $reason';
  }

  @override
  String pluginsLogsResultErrorWith(String reason, String message) {
    return 'Lỗi: $reason · $message';
  }

  @override
  String get pluginsLogsKindRateLimited => 'quá nhiều yêu cầu (429)';

  @override
  String get pluginsLogsKindInvalidResponse => 'dữ liệu trả về không hợp lệ';

  @override
  String get pluginsLogsKindServer => 'máy chủ lỗi';

  @override
  String get pluginsLogsKindAuth => 'cần đăng nhập hoặc key sai';

  @override
  String get pluginsLogsKindQuota => 'hết hạn mức';

  @override
  String get pluginsLogsKindTimeout => 'hết thời gian chờ';

  @override
  String get pluginsLogsKindMemory => 'hết bộ nhớ';

  @override
  String get pluginsLogsKindStack => 'mã lặp quá sâu';

  @override
  String get pluginsLogsKindOutputTooLarge => 'kết quả quá lớn';

  @override
  String get pluginsLogsKindInternal => 'lỗi nội bộ';

  @override
  String pluginsLogsKindOther(String kind) {
    return '$kind';
  }

  @override
  String pluginsRemoveStorage(int size) {
    return 'Bộ nhớ riêng ($size KB)';
  }

  @override
  String get pluginsRemoveLog => 'Nhật ký của plugin';

  @override
  String pluginsRemoveKeepLyrics(int count) {
    return 'Lời đã lưu của $count bài và lời đã ghim từ nguồn này';
  }

  @override
  String get pluginsRemoveKeepPinned => 'Lời đã ghim từ nguồn này (nếu có)';

  @override
  String get pluginsRemoveKeepLrc => 'File .lrc đã ghi cạnh bài';

  @override
  String get pluginsRemoveKeep => 'Vẫn giữ';

  @override
  String get pluginsPageConnectionRow => 'Yêu cầu cùng lúc, giãn cách';

  @override
  String get fontsBuiltInTitle => 'Có sẵn';

  @override
  String get fontsBuiltInHint =>
      'Chữ Hán, Hàn, Nhật và emoji luôn dùng phông của hệ thống.';

  @override
  String get fontsDefaultSuffix => ' · mặc định';

  @override
  String get fontsSystemFont => 'Phông của hệ thống';

  @override
  String get fontsChanged => 'Đã đổi phông';

  @override
  String fontsUseFailed(String name) {
    return 'Không dùng được phông $name.';
  }

  @override
  String get fontsCatalogTitle => 'Kho phông trực tuyến';

  @override
  String get fontsCatalogHint => 'Tải một lần, sau đó dùng không cần mạng.';

  @override
  String fontsDownloadTooltip(String name) {
    return 'Tải $name';
  }

  @override
  String fontsDeleteTooltip(String name) {
    return 'Xoá $name';
  }

  @override
  String get fontsDownloaded => 'Đã tải phông';

  @override
  String get fontsDeleted => 'Đã xoá phông (tải lại được)';

  @override
  String fontsDownloadFailed(String name) {
    return 'Không tải được phông $name. Kiểm tra mạng rồi thử lại.';
  }

  @override
  String get fontsCustomTitle => 'Tuỳ chỉnh';

  @override
  String get fontsCustomHint => 'Phông bạn nhập từ tệp .ttf hoặc .otf.';

  @override
  String get fontsImportRow => 'Nhập phông';

  @override
  String get fontsImportRowDialog => 'Nhập phông…';

  @override
  String get fontsImportTitle => 'Nhập phông';

  @override
  String get fontsImportBody =>
      'Chỉ nhập phông bạn có quyền dùng. Kanaru chép tệp .ttf / .otf vào thư mục dữ liệu của app.';

  @override
  String get fontsImportPick => 'Chọn tệp…';

  @override
  String fontsImported(String name) {
    return 'Đã nhập “$name” · bấm để dùng';
  }

  @override
  String get fontsImportTooLarge => 'Tệp phông quá lớn (tối đa 20 MB).';

  @override
  String get fontsImportInvalid => 'Tệp này không phải phông .ttf hoặc .otf.';

  @override
  String get fontsImportFileTypes => 'Phông chữ';

  @override
  String fontsDownloading(String name) {
    return 'Đang tải $name';
  }

  @override
  String fontsRemoveTitle(String name) {
    return 'Xoá phông “$name”?';
  }

  @override
  String get fontsRemoveBody =>
      'Tệp phông đã nhập bị xoá khỏi Kanaru. Muốn dùng lại phải nhập lại.';

  @override
  String get fontsRemoveConfirm => 'Xoá';

  @override
  String get fontsRemoved => 'Đã xoá phông';
}
