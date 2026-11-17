import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/domain/browse/browse_items.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/domain/browse/song_scope.dart';
import 'package:kanaru/src/library/state/browse/collection_providers.dart';
import 'package:kanaru/src/library/state/browse/song_list_providers.dart';
import 'package:kanaru/src/library/state/browse/track_window.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/data/track_info_rows.dart';

import '../../database/support/test_db.dart';
import 'support/library_fixture.dart';
import 'support/query_counter.dart';
import 'support/wait.dart';

const _tick = Duration(milliseconds: 15);

void main() {
  late AppDatabase db;
  late QueryCounter counter;
  late ProviderContainer c;
  late int src;

  setUp(() async {
    counter = QueryCounter();
    db = openCountingDb(counter);
    addTearDown(db.close);
    src = await addSource(db);
    c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        browseRefreshIntervalProvider.overrideWithValue(_tick),
      ],
    );
    addTearDown(c.dispose);
  });

  Future<int> add(
    String name, {
    List<String> artists = const [],
    String? album,
    String? cover,
  }) => addLibraryTrack(
    db,
    source: src,
    locator: '$name.flac',
    title: name,
    artists: artists,
    album: album,
    coverKey: cover,
  );

  SongListKey key({
    SortCriterion by = SortCriterion.title,
    bool desc = false,
    String filter = '',
  }) => (
    scope: const SongScope.all(),
    sort: SortOrder.by(by, descending: desc),
    filter: filter,
  );

  /// Every emitted value of [provider] while the test runs.
  List<T> collect<T>(ProviderListenable<AsyncValue<T>> provider) {
    final seen = <T>[];
    c.listen<AsyncValue<T>>(provider, (_, next) {
      final v = next.value;
      if (v != null) seen.add(v);
    }, fireImmediately: true);
    return seen;
  }

  /// Revisions of the sibling that reloads on the same writes.
  List<int> revisions() => collect(songRowsRevisionProvider);

  test('emits the ids, then the new list after a write', () async {
    final a = await add('a');
    final seen = collect(songIdsProvider(key()));
    await until(() => seen.isNotEmpty);
    expect(seen, [
      [TrackId(a)],
    ]);
    final b = await add('b');
    await until(() => seen.length == 2);
    expect(seen.last, [TrackId(a), TrackId(b)]);
  });

  test('autoDispose releases the provider when nobody listens', () async {
    final k = key();
    final sub = c.listen(songIdsProvider(k), (_, _) {});
    expect(c.read(songIdsProvider(k).exists), isTrue);
    sub.close();
    await until(() => !c.read(songIdsProvider(k).exists));
  });

  test('a result equal to the last one is not emitted again', () async {
    await add('a');
    final seen = collect(songIdsProvider(key()));
    int loads() => counter.loads('SELECT t.id FROM tracks t');
    await until(() => seen.isNotEmpty);
    final before = loads();
    // Touches `tracks` without changing the visible order.
    await db.customUpdate('UPDATE tracks SET rating = 5', updates: {db.tracks});
    await afterLoad(loads, after: before);
    expect(loads(), greaterThan(before));
    expect(seen, hasLength(1));
  });

  test('play counts refresh only lists sorted by them', () async {
    final a = await add('a');
    final b = await add('b');
    final byTitle = collect(songIdsProvider(key()));
    final byPlays = collect(
      songIdsProvider(key(by: SortCriterion.playCount, desc: true)),
    );
    await until(() => byTitle.isNotEmpty && byPlays.isNotEmpty);
    expect(byPlays.single, [TrackId(a), TrackId(b)]);
    await addPlays(db, b, 2);
    await until(() => byPlays.length == 2);
    expect(byPlays.last, [TrackId(b), TrackId(a)]);
    // The by-plays list has reloaded; the by-title list watches no play table.
    expect(byTitle, hasLength(1));
  });

  test('a play reloads a list that has play count as a later key', () async {
    final a = await addLibraryTrack(
      db,
      source: src,
      locator: 'a.flac',
      title: 'a',
      artists: ['Same'],
    );
    final b = await addLibraryTrack(
      db,
      source: src,
      locator: 'b.flac',
      title: 'b',
      artists: ['Same'],
    );
    final seen = collect(
      songIdsProvider((
        scope: const SongScope.all(),
        sort: SortOrder([
          const SortSpec(SortCriterion.artist),
          const SortSpec(SortCriterion.playCount, descending: true),
        ]),
        filter: '',
      )),
    );
    await until(() => seen.isNotEmpty);
    expect(seen.single, [TrackId(a), TrackId(b)]);
    await addPlays(db, b, 2);
    await until(() => seen.length == 2);
    expect(seen.last, [TrackId(b), TrackId(a)]);
  });

  test('the revision ticks on every reload, even when the ids stay', () async {
    await add('a');
    final seen = revisions();
    await until(() => seen.isNotEmpty);
    await db.customUpdate(
      'UPDATE tracks SET cover_key = ?',
      variables: [Variable.withString('c')],
      updates: {db.tracks},
    );
    await until(() => seen.length == 2);
    expect(seen, [1, 2]);
  });

  test(
    'a changed cover reaches a cached row though the order is unchanged',
    () async {
      final a = await add('a');
      var changed = 0;
      late TrackWindow window;
      window = TrackWindow(
        load: (ids) => loadTrackInfos(db, ids),
        onChanged: () => changed++,
      );
      addTearDown(window.dispose);
      final ids = collect(songIdsProvider(key()));
      c.listen(songRowsRevisionProvider, (_, next) {
        if (next.hasValue) window.invalidate();
      }, fireImmediately: true);
      await until(() => ids.isNotEmpty);
      window.setIds(ids.last);
      window.viewport(0, 0);
      await until(() => window.rowAt(0) != null);
      expect(window.rowAt(0)!.coverKey, isNull);
      final before = changed;
      await db.customUpdate(
        'UPDATE tracks SET cover_key = ? WHERE id = ?',
        variables: [Variable.withString('new-cover'), Variable.withInt(a)],
        updates: {db.tracks},
      );
      await until(() => window.rowAt(0)?.coverKey == 'new-cover');
      expect(changed, greaterThan(before));
      // No new ids emission was needed for that.
      expect(ids, hasLength(1));
    },
  );

  test('the unfiltered count ignores the filter and follows writes', () async {
    await add('a');
    final seen = <int>[];
    c.listen(songCountProvider(const SongScope.all()), (_, next) {
      final v = next.value;
      if (v != null) seen.add(v);
    }, fireImmediately: true);
    await until(() => seen.isNotEmpty);
    await add('b');
    await until(() => seen.length == 2);
    expect(seen, [1, 2]);
  });

  group('collections', () {
    test(
      'albums filter on title and artist, sort and keep ties by name',
      () async {
        await add('1', artists: ['Mia'], album: 'Beta');
        await add('2', artists: ['Zed'], album: 'Alpha');
        await add('3', artists: ['Mia'], album: 'Gamma');
        final seen = collect(albumSummariesProvider);
        await until(() => seen.isNotEmpty);
        List<String> titles(CollectionViewKey k) => c
            .read(albumListProvider(k))
            .requireValue
            .map((a) => a.title)
            .toList();
        expect(titles((sort: SortOrder.by(SortCriterion.title), filter: '')), [
          'Alpha',
          'Beta',
          'Gamma',
        ]);
        expect(
          titles((
            sort: SortOrder.by(SortCriterion.title, descending: true),
            filter: '',
          )),
          ['Gamma', 'Beta', 'Alpha'],
        );
        expect(
          titles((sort: SortOrder.by(SortCriterion.artist), filter: 'mia')),
          ['Beta', 'Gamma'],
        );
        expect(
          titles((
            sort: SortOrder.by(SortCriterion.artist, descending: true),
            filter: '',
          )),
          ['Alpha', 'Beta', 'Gamma'],
        );
      },
    );

    test(
      'albums: several criteria chain, equal ones keep name order',
      () async {
        Future<void> album(String title, String artist, int? year) =>
            addLibraryTrack(
              db,
              source: src,
              locator: '$title.flac',
              title: title,
              artists: [artist],
              album: title,
              year: year,
            );
        await album('Delta', 'Mia', 2000);
        await album('Alpha', 'Zed', 1990);
        await album('Beta', 'Mia', 2010);
        await album('Gamma', 'Mia', 2010);
        await album('Omega', 'Abe', null);
        final seen = collect(albumSummariesProvider);
        await until(() => seen.isNotEmpty && seen.last.length == 5);
        List<String> titles(SortOrder s) => c
            .read(albumListProvider((sort: s, filter: '')))
            .requireValue
            .map((a) => a.title)
            .toList();
        final order = SortOrder([
          const SortSpec(SortCriterion.artist),
          const SortSpec(SortCriterion.year, descending: true),
        ]);
        // Mia: 2010 (Beta, Gamma tie: name order), then 2000; Zed last.
        expect(titles(order), ['Omega', 'Beta', 'Gamma', 'Delta', 'Alpha']);
        // Reversed: directions flip; the tied pair still keeps name order.
        expect(titles(order.reversed()), [
          'Alpha',
          'Delta',
          'Beta',
          'Gamma',
          'Omega',
        ]);
        // A title key inside the chain compares by name with its direction.
        expect(
          titles(
            SortOrder([
              const SortSpec(SortCriterion.year, descending: true),
              const SortSpec(SortCriterion.title, descending: true),
            ]),
          ),
          ['Gamma', 'Beta', 'Delta', 'Alpha', 'Omega'],
        );
      },
    );

    test('albums: a later criterion applies between equal titles', () async {
      Future<void> album(String title, String artist) => addLibraryTrack(
        db,
        source: src,
        locator: '$artist$title.flac',
        title: '$artist$title',
        artists: [artist],
        album: title,
      );
      await album('Greatest Hits', 'Abe');
      await album('Greatest Hits', 'Zed');
      await album('Greatest Hits', 'Mia');
      await album('Zeta', 'Abe');
      final seen = collect(albumSummariesProvider);
      await until(() => seen.isNotEmpty && seen.last.length == 4);
      List<String?> artists(SortOrder s) => c
          .read(albumListProvider((sort: s, filter: '')))
          .requireValue
          .map((a) => a.artist)
          .toList();
      final desc = SortOrder([
        const SortSpec(SortCriterion.title),
        const SortSpec(SortCriterion.artist, descending: true),
      ]);
      // Equal titles: artist descending decides, not the name position.
      expect(artists(desc), ['Zed', 'Mia', 'Abe', 'Abe']);
      // Equal on every key (no years): name order, in both directions.
      for (final descending in [false, true]) {
        final order = SortOrder([
          SortSpec(SortCriterion.title, descending: descending),
          const SortSpec(SortCriterion.year),
        ]);
        final hits = [
          for (final a
              in c
                  .read(albumListProvider((sort: order, filter: '')))
                  .requireValue)
            if (a.title == 'Greatest Hits') a.artist,
        ];
        expect(hits, ['Abe', 'Mia', 'Zed'], reason: 'desc: $descending');
      }
    });

    test(
      'languages: unknown last in both directions, hidden by a filter',
      () async {
        await addLibraryTrack(
          db,
          source: src,
          locator: '1.flac',
          language: 'vi',
        );
        await addLibraryTrack(
          db,
          source: src,
          locator: '2.flac',
          language: 'vi',
        );
        await addLibraryTrack(
          db,
          source: src,
          locator: '3.flac',
          language: 'en',
        );
        await addLibraryTrack(db, source: src, locator: '4.flac');
        final seen = collect(languageSummariesProvider);
        await until(() => seen.isNotEmpty);
        List<String?> codes(SortOrder s, [String f = '']) => c
            .read(languageListProvider((sort: s, filter: f)))
            .requireValue
            .map((l) => l.code)
            .toList();
        const count = SortCriterion.trackCount;
        expect(codes(SortOrder.by(count, descending: true)), [
          'vie',
          'eng',
          null,
        ]);
        expect(codes(SortOrder.by(count)), ['eng', 'vie', null]);
        expect(codes(SortOrder.by(SortCriterion.title)), ['eng', 'vie', null]);
        expect(codes(SortOrder.by(count), 'viet'), ['vie']);
      },
    );

    test('artists are in code point order, as the SQL lists are', () async {
      // U+1F600 (a surrogate pair) sorts after U+E000 by code point and
      // before it by UTF-16 unit.
      for (final (i, name) in ['x\u{1F600}', 'x\uE000'].indexed) {
        await addLibraryTrack(
          db,
          source: src,
          locator: '$i.flac',
          artists: [name],
        );
      }
      final artists = collect(artistSummariesProvider);
      await until(() => artists.isNotEmpty && artists.last.length == 2);
      final byName = (sort: SortOrder.by(SortCriterion.title), filter: '');
      expect(
        c.read(artistListProvider(byName)).requireValue.map((a) => a.name),
        ['x\uE000', 'x\u{1F600}'],
      );
    });

    test('artists and genres', () async {
      await addLibraryTrack(
        db,
        source: src,
        locator: '1.flac',
        artists: ['Đen'],
        genre: 'Rap',
      );
      await addLibraryTrack(
        db,
        source: src,
        locator: '2.flac',
        artists: ['Abe', 'Đen'],
        genre: 'Pop',
      );
      final artists = collect(artistSummariesProvider);
      final genres = collect(genreSummariesProvider);
      await until(() => artists.isNotEmpty && genres.isNotEmpty);
      final byName = (sort: SortOrder.by(SortCriterion.title), filter: '');
      expect(
        c.read(artistListProvider(byName)).requireValue.map((a) => a.name),
        ['Abe', 'Đen'],
      );
      final byCount = (
        sort: SortOrder.by(SortCriterion.trackCount, descending: true),
        filter: '',
      );
      expect(
        c.read(artistListProvider(byCount)).requireValue.map((a) => a.name),
        ['Đen', 'Abe'],
      );
      expect(
        c.read(genreListProvider(byName)).requireValue.map((g) => g.name),
        ['Pop', 'Rap'],
      );
      expect(
        c
            .read(genreListProvider((sort: byName.sort, filter: 'ra')))
            .requireValue
            .single,
        isA<GenreSummary>().having((g) => g.name, 'name', 'Rap'),
      );
    });
  });
}
