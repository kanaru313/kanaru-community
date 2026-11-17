import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/state/database_providers.dart';
import '../../../foundation/text/text_fold.dart';
import '../../../media/domain/library_keys.dart';
import '../../data/browse/album_artist_queries.dart';
import '../../data/browse/genre_language_queries.dart';
import '../../data/browse/throttled_query.dart';
import '../../domain/browse/browse_items.dart';
import '../../domain/browse/code_point_compare.dart';
import '../../domain/browse/language_names.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/sort_arrange.dart';
import '../../domain/browse/sort_order.dart';
import 'song_list_providers.dart';

/// Sort and text filter applied to one collection.
typedef CollectionViewKey = ({SortOrder sort, String filter});

/// Albums, name order. Reloads at most once per refresh interval; an
/// unchanged result is not re-emitted.
final albumSummariesProvider = StreamProvider.autoDispose<List<AlbumSummary>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return throttledQuery(
    db,
    {db.tracks, db.trackArtists},
    () => albumSummaries(db),
    interval: ref.watch(browseRefreshIntervalProvider),
    equals: sameElements,
  );
});

/// Artists, name order (names folded once per distinct name, not per reload).
final artistSummariesProvider = StreamProvider.autoDispose<List<ArtistSummary>>(
  (ref) {
    final db = ref.watch(appDatabaseProvider);
    return throttledQuery(
      db,
      {db.tracks, db.trackArtists},
      () async {
        final all = await artistSummaries(db);
        return all..sort(
          (a, b) => _byName(sortKeyOf(a.name), sortKeyOf(b.name), a.key, b.key),
        );
      },
      interval: ref.watch(browseRefreshIntervalProvider),
      equals: sameElements,
    );
  },
);

/// Genres, name order.
final genreSummariesProvider = StreamProvider.autoDispose<List<GenreSummary>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return throttledQuery(
    db,
    {db.tracks},
    () => genreSummaries(db),
    interval: ref.watch(browseRefreshIntervalProvider),
    equals: sameElements,
  );
});

/// Languages, name order, tracks without a language last.
final languageSummariesProvider =
    StreamProvider.autoDispose<List<LanguageSummary>>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return throttledQuery(
        db,
        {db.tracks},
        () async => _languagesByName(await languageSummaries(db)),
        interval: ref.watch(browseRefreshIntervalProvider),
        equals: sameElements,
      );
    });

/// Albums sorted and filtered (name or artist contains the text).
final albumListProvider = Provider.autoDispose
    .family<AsyncValue<List<AlbumSummary>>, CollectionViewKey>((ref, key) {
      final match = foldedMatcher(key.filter);
      return ref
          .watch(albumSummariesProvider)
          .mapKeepingValue(
            (all) => arrangeByName(
              [
                for (final a in all)
                  if (match('${a.title} ${a.artist ?? ''}')) a,
              ],
              key.sort,
              (a) => sortKeyOf(a.title),
              (spec) =>
                  (a, b) => switch (spec.criterion) {
                    SortCriterion.artist => _cmpNullable(
                      a.artist == null ? null : sortKeyOf(a.artist!),
                      b.artist == null ? null : sortKeyOf(b.artist!),
                      spec.descending,
                    ),
                    SortCriterion.year => _cmpNullable(
                      a.year,
                      b.year,
                      spec.descending,
                    ),
                    SortCriterion.dateAdded => _cmpNullable(
                      a.addedAt,
                      b.addedAt,
                      spec.descending,
                    ),
                    SortCriterion.trackCount => _cmpNullable(
                      a.trackCount,
                      b.trackCount,
                      spec.descending,
                    ),
                    _ => 0,
                  },
            ),
          );
    });

/// Artists sorted and filtered by name.
final artistListProvider = Provider.autoDispose
    .family<AsyncValue<List<ArtistSummary>>, CollectionViewKey>((ref, key) {
      final match = foldedMatcher(key.filter);
      return ref
          .watch(artistSummariesProvider)
          .mapKeepingValue(
            (all) => arrangeByName(
              [
                for (final a in all)
                  if (match(a.name)) a,
              ],
              key.sort,
              (a) => sortKeyOf(a.name),
              (spec) =>
                  (a, b) => switch (spec.criterion) {
                    SortCriterion.trackCount => _cmpNullable(
                      a.trackCount,
                      b.trackCount,
                      spec.descending,
                    ),
                    SortCriterion.albumCount => _cmpNullable(
                      a.albumCount,
                      b.albumCount,
                      spec.descending,
                    ),
                    _ => 0,
                  },
            ),
          );
    });

/// Genres sorted and filtered by name.
final genreListProvider = Provider.autoDispose
    .family<AsyncValue<List<GenreSummary>>, CollectionViewKey>((ref, key) {
      final match = foldedMatcher(key.filter);
      return ref
          .watch(genreSummariesProvider)
          .mapKeepingValue(
            (all) => arrangeByName(
              [
                for (final g in all)
                  if (match(g.name)) g,
              ],
              key.sort,
              (g) => sortKeyOf(g.name),
              (spec) =>
                  (a, b) => spec.criterion == SortCriterion.trackCount
                  ? _cmpNullable(a.trackCount, b.trackCount, spec.descending)
                  : 0,
            ),
          );
    });

/// Languages sorted and filtered (code or any of its names); "unknown" is
/// always last whatever the order.
final languageListProvider = Provider.autoDispose
    .family<AsyncValue<List<LanguageSummary>>, CollectionViewKey>((ref, key) {
      final match = foldedMatcher(key.filter);
      return ref.watch(languageSummariesProvider).mapKeepingValue((all) {
        final known = [
          for (final l in all)
            if (l.code != null && match(_languageHaystack(l.code!))) l,
        ];
        final sorted = arrangeByName<LanguageSummary>(
          known,
          key.sort,
          (l) => _languageNameKey(l.code!),
          (spec) =>
              (a, b) => spec.criterion == SortCriterion.trackCount
              ? _cmpNullable(a.trackCount, b.trackCount, spec.descending)
              : 0,
        );
        final unknown = all.where((l) => l.code == null);
        // "Chưa rõ" has no name to match; it shows only without a filter.
        return [...sorted, if (key.filter.trim().isEmpty) ...unknown];
      });
    });

String _languageHaystack(String code) {
  final n = languageNameOf(code);
  return n == null ? code : '$code ${n.native} ${n.en} ${n.vi}';
}

String _languageNameKey(String code) =>
    sortKeyOf(languageNameOf(code)?.native ?? code);

List<LanguageSummary> _languagesByName(List<LanguageSummary> all) {
  String nameKey(String code) => _languageNameKey(code);
  final known = all.where((l) => l.code != null).toList()
    ..sort(
      (a, b) => _byName(nameKey(a.code!), nameKey(b.code!), a.code!, b.code!),
    );
  return [...known, ...all.where((l) => l.code == null)];
}

/// Like `whenData`, but a source that has a value keeps it as plain data
/// while it reloads (Riverpod 3 `AsyncLoading(value: previous)`): `whenData`
/// would answer a bare loading, and the page would drop its rows for a
/// skeleton. An error still surfaces as an error.
extension AsyncKeepValue<T> on AsyncValue<T> {
  AsyncValue<R> mapKeepingValue<R>(R Function(T value) cb) {
    if (!hasValue || hasError) return whenData(cb);
    // A throwing callback becomes an error, as `whenData` does.
    try {
      return AsyncData(cb(requireValue));
    } catch (e, st) {
      return AsyncError(e, st);
    }
  }
}

int _cmpNullable<V extends Comparable<Object>>(V? a, V? b, bool desc) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  final c = a.compareTo(b);
  return desc ? -c : c;
}

/// Code point order, as the SQL-ordered lists (albums, genres) have it.
int _byName(String a, String b, String tieA, String tieB) {
  final c = compareCodePoints(a, b);
  return c != 0 ? c : compareCodePoints(tieA, tieB);
}

final Map<String, String> _sortKeys = {};

/// [sortForm] of [text], remembered across reloads so a list of thousands of
/// names is not folded again every time the scanner writes.
String sortKeyOf(String text) {
  final hit = _sortKeys[text];
  if (hit != null) return hit;
  // Bounded: a library rename storm cannot grow the table without limit.
  if (_sortKeys.length > 50000) _sortKeys.clear();
  return _sortKeys[text] = sortForm(text);
}
