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
      'Các thư mục có nhạc mà Android tìm thấy.';

  @override
  String get scanSetupFolderPickerEmpty => 'Đã chọn mọi thư mục có nhạc.';

  @override
  String get scanSetupSheetAdd => 'Thêm';

  @override
  String scanSetupSheetAddCount(int count) {
    return 'Thêm $count';
  }

  @override
  String get scanSetupSheetCancel => 'Huỷ';

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
      'Thư mục con trong các thư mục nhạc đã chọn.';

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
  String get playbackCover => 'Ảnh bìa';

  @override
  String get playbackNavQueue => 'Hàng đợi';

  @override
  String get libraryTabSongs => 'Bài hát';

  @override
  String get libraryTabAlbums => 'Album';

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
}
