import '../../../foundation/text/text_fold.dart';
import '../browse/list_sort.dart';
import '../browse/natural_compare.dart';
import '../browse/sort_order.dart';
import 'playlist_models.dart';

/// [list] ordered by [sort] (`dateModified` by `updatedAt`, `name` naturally);
/// ties go by name, then uid. Returns a new list.
List<PlaylistSummary> sortPlaylists(
  List<PlaylistSummary> list,
  SortOrder sort,
) {
  final keys = {for (final p in list) p.uid: NaturalKey(p.name)};
  int compare(PlaylistSummary a, PlaylistSummary b) {
    for (final spec in sort.specs) {
      final c = switch (spec.criterion) {
        SortCriterion.dateModified => a.updatedAt.compareTo(b.updatedAt),
        SortCriterion.name => keys[a.uid]!.compareTo(keys[b.uid]!),
        _ => throw ArgumentError.value(
          spec.criterion,
          'sort',
          'not a playlist criterion',
        ),
      };
      if (c != 0) return spec.descending ? -c : c;
    }
    final byName = keys[a.uid]!.compareTo(keys[b.uid]!);
    return byName != 0 ? byName : a.uid.compareTo(b.uid);
  }

  return [...list]..sort(compare);
}

/// [entries] (given in playlist order) ordered by [sort]. `playlistOrder` is
/// the input position; text criteria compare naturally, missing text sorts
/// last in either direction. Stable: ties keep playlist order.
List<PlaylistEntryView> sortPlaylistEntries(
  List<PlaylistEntryView> entries,
  SortOrder sort,
) {
  final textSpecs = sort.specs.where(_isText);
  final keys = <SortCriterion, List<NaturalKey?>>{
    for (final s in textSpecs)
      s.criterion: [
        for (final e in entries)
          switch (_text(s.criterion, e)) {
            final String t => NaturalKey(t),
            null => null,
          },
      ],
  };
  final order = List<int>.generate(entries.length, (i) => i);

  int compare(int a, int b) {
    for (final spec in sort.specs) {
      final c = _compareBy(
        spec.criterion,
        spec.descending,
        a,
        b,
        entries,
        keys,
      );
      if (c != 0) return c;
    }
    return a.compareTo(b);
  }

  order.sort(compare);
  return [for (final i in order) entries[i]];
}

bool _isText(SortSpec s) =>
    s.criterion == SortCriterion.title ||
    s.criterion == SortCriterion.artist ||
    s.criterion == SortCriterion.album;

String? _text(SortCriterion c, PlaylistEntryView e) {
  return switch (c) {
    SortCriterion.title => e.info.title,
    SortCriterion.artist => e.info.artist,
    SortCriterion.album => e.info.album,
    _ => null,
  };
}

int _compareBy(
  SortCriterion c,
  bool desc,
  int a,
  int b,
  List<PlaylistEntryView> entries,
  Map<SortCriterion, List<NaturalKey?>> keys,
) {
  int signed(int v) => desc ? -v : v;
  int nullsLast<T>(T? x, T? y, int Function(T, T) cmp) {
    if (x == null && y == null) return 0;
    if (x == null) return 1;
    if (y == null) return -1;
    return signed(cmp(x, y));
  }

  switch (c) {
    case SortCriterion.playlistOrder:
      return signed(a.compareTo(b));
    case SortCriterion.title:
    case SortCriterion.artist:
    case SortCriterion.album:
      return nullsLast<NaturalKey>(
        keys[c]![a],
        keys[c]![b],
        (x, y) => x.compareTo(y),
      );
    case SortCriterion.duration:
      return nullsLast<int>(
        entries[a].info.durationMs,
        entries[b].info.durationMs,
        (x, y) => x.compareTo(y),
      );
    case SortCriterion.playCount:
      return signed(
        entries[a].info.playCount.compareTo(entries[b].info.playCount),
      );
    default:
      throw ArgumentError.value(c, 'sort', 'not a playlist entry criterion');
  }
}

/// Entries whose title, artist(s) or album contain every word of [query],
/// ignoring case and diacritics. An empty query returns [entries].
List<PlaylistEntryView> filterPlaylistEntries(
  List<PlaylistEntryView> entries,
  String query,
) {
  final matches = foldedMatcher(query);
  if (query.trim().isEmpty) return entries;
  return [
    for (final e in entries)
      if (matches(
        [
          e.info.title,
          e.info.artist,
          ...e.info.artists,
          e.info.album,
        ].whereType<String>().join('\u001f'),
      ))
        e,
  ];
}

/// Playlists whose name or description contain every word of [query].
List<PlaylistSummary> filterPlaylists(
  List<PlaylistSummary> list,
  String query,
) {
  final matches = foldedMatcher(query);
  if (query.trim().isEmpty) return list;
  return [
    for (final p in list)
      if (matches('${p.name}\u001f${p.description}')) p,
  ];
}

/// Whether the user may drag or step entries: only in playlist order,
/// ascending (later criteria never matter after it), with no filter.
bool canReorder(SortOrder sort, String query) =>
    sort.primary.criterion == SortCriterion.playlistOrder &&
    !sort.primary.descending &&
    query.trim().isEmpty;
