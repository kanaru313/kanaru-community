import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/language_names.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/library_tabs.dart';

/// Name of a library list (sub-tab, sidebar item, desktop page title).
String libraryTabLabel(AppLocalizations l10n, LibraryTab tab) => switch (tab) {
  LibraryTab.songs => l10n.libraryTabSongs,
  LibraryTab.albums => l10n.libraryTabAlbums,
  LibraryTab.artists => l10n.libraryTabArtists,
  LibraryTab.genres => l10n.libraryTabGenres,
  LibraryTab.languages => l10n.libraryTabLanguages,
  LibraryTab.folders => l10n.libraryTabFolders,
};

/// Name of a sort criterion in the sort popover and on the bar chip.
String sortCriterionLabel(AppLocalizations l10n, SortCriterion c) =>
    switch (c) {
      SortCriterion.title => l10n.librarySortTitle,
      SortCriterion.artist => l10n.librarySortArtist,
      SortCriterion.album => l10n.librarySortAlbum,
      SortCriterion.year => l10n.librarySortYear,
      SortCriterion.dateAdded => l10n.librarySortDateAdded,
      SortCriterion.playCount => l10n.librarySortPlayCount,
      SortCriterion.duration => l10n.librarySortDuration,
      SortCriterion.trackCount => l10n.librarySortTrackCount,
      SortCriterion.albumCount => l10n.librarySortAlbumCount,
      SortCriterion.trackNumber => l10n.librarySortTrackNumber,
    };

/// Icon of a sort criterion in the sort popover.
IconData sortCriterionIcon(SortCriterion c) => switch (c) {
  SortCriterion.title => KIcons.songs,
  SortCriterion.artist => KIcons.artists,
  SortCriterion.album => KIcons.albums,
  SortCriterion.year => KIcons.year,
  SortCriterion.dateAdded => KIcons.dateAdded,
  SortCriterion.playCount => KIcons.playCount,
  SortCriterion.duration => KIcons.duration,
  SortCriterion.trackCount => KIcons.count,
  SortCriterion.albumCount => KIcons.albums,
  SortCriterion.trackNumber => KIcons.trackNumber,
};

/// `m:ss`, or `h:mm:ss` from one hour up.
String formatClock(int milliseconds) {
  final total = milliseconds < 0 ? 0 : milliseconds ~/ 1000;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

/// Whole minutes of a length, at least 1 for a non-empty one.
int minutesOf(int milliseconds) {
  if (milliseconds <= 0) return 0;
  final m = (milliseconds / 60000).round();
  return m < 1 ? 1 : m;
}

/// `12 min`, `2 h` (whole hours) or `2 h 5 min`.
String formatTotalDuration(AppLocalizations l10n, int milliseconds) {
  final minutes = minutesOf(milliseconds);
  if (minutes < 60) return l10n.libraryDurationMinutes(minutes);
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return l10n.libraryDurationHours(hours);
  return l10n.libraryDurationHoursMinutes(hours, rest);
}

/// Name of a language for a list row or page: its own name, plus the name in
/// the app language when that differs (`日本語 · Tiếng Nhật`). A code the table
/// does not know shows as the code; null is the group without a language.
String languageDisplayName(AppLocalizations l10n, String? code) {
  if (code == null) return l10n.libraryLanguageUnknown;
  final names = languageNameOf(code);
  if (names == null) return code;
  final localized = l10n.localeName == 'vi' ? names.vi : names.en;
  return localized == names.native
      ? names.native
      : '${names.native} · $localized';
}
