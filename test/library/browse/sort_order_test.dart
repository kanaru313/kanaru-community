import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/song_scope.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/state/browse/song_list_providers.dart';

const _artist = SortSpec(SortCriterion.artist);
const _yearDesc = SortSpec(SortCriterion.year, descending: true);
const _album = SortSpec(SortCriterion.album);

List<SortCriterion> _names(SortOrder o) => [
  for (final s in o.specs) s.criterion,
];

void main() {
  group('add', () {
    test('a date criterion goes in descending', () {
      final o = SortOrder.single(_artist).add(SortCriterion.year);
      expect(o.specs, [_artist, _yearDesc]);
      expect(
        SortOrder.single(_artist).add(SortCriterion.dateAdded).specs.last,
        const SortSpec(SortCriterion.dateAdded, descending: true),
      );
    });

    test('a text criterion goes in ascending', () {
      expect(SortOrder.single(_yearDesc).add(SortCriterion.album).specs, [
        _yearDesc,
        _album,
      ]);
    });

    test('track number after two keys is a third key', () {
      final o = SortOrder([_artist, _album]).add(SortCriterion.trackNumber);
      expect(_names(o), [
        SortCriterion.artist,
        SortCriterion.album,
        SortCriterion.trackNumber,
      ]);
    });

    test('an existing criterion is a no-op', () {
      final o = SortOrder([_artist, _yearDesc]);
      expect(o.add(SortCriterion.year), o);
    });
  });

  group('pick', () {
    test('keeps the direction of the first criterion (descending)', () {
      final o = SortOrder([_yearDesc, _artist, _album]);
      expect(o.pick(SortCriterion.title).specs, [
        const SortSpec(SortCriterion.title, descending: true),
      ]);
    });

    test('keeps the direction of the first criterion (ascending)', () {
      final o = SortOrder([_artist, _yearDesc]);
      expect(o.pick(SortCriterion.year).specs, [
        const SortSpec(SortCriterion.year),
      ]);
    });
  });

  group('remove', () {
    test('drops one criterion', () {
      expect(
        SortOrder([_artist, _yearDesc]).remove(SortCriterion.artist).specs,
        [_yearDesc],
      );
    });

    test('the last one stays', () {
      final o = SortOrder.single(_artist);
      expect(o.remove(SortCriterion.artist), o);
    });

    test('an absent criterion is a no-op', () {
      final o = SortOrder([_artist, _album]);
      expect(o.remove(SortCriterion.year), o);
    });
  });

  test('flip toggles one criterion only', () {
    final o = SortOrder([_artist, _yearDesc]).flip(SortCriterion.year);
    expect(o.specs, [_artist, const SortSpec(SortCriterion.year)]);
  });

  test('reversed flips every criterion, twice is identity', () {
    final o = SortOrder([_artist, _yearDesc]);
    expect(o.reversed().specs, [
      const SortSpec(SortCriterion.artist, descending: true),
      const SortSpec(SortCriterion.year),
    ]);
    expect(o.reversed().reversed(), o);
  });

  group('move (to = final index)', () {
    final o = SortOrder([_artist, _album, _yearDesc]);

    test('down', () {
      expect(_names(o.move(0, 1)), [
        SortCriterion.album,
        SortCriterion.artist,
        SortCriterion.year,
      ]);
      expect(_names(o.move(0, 2)), [
        SortCriterion.album,
        SortCriterion.year,
        SortCriterion.artist,
      ]);
    });

    test('up', () {
      expect(_names(o.move(2, 0)), [
        SortCriterion.year,
        SortCriterion.artist,
        SortCriterion.album,
      ]);
    });

    test('same index is a no-op', () {
      expect(o.move(1, 1), o);
    });

    test('keeps directions with their criterion', () {
      expect(o.move(2, 0).primary, _yearDesc);
    });

    test('an index out of range throws', () {
      expect(() => o.move(0, 3), throwsRangeError);
      expect(() => o.move(-1, 0), throwsRangeError);
    });
  });

  group('normalized', () {
    final offered = [
      SortCriterion.title,
      SortCriterion.artist,
      SortCriterion.year,
    ];
    final fallback = SortOrder.by(SortCriterion.title);

    test('drops duplicates (first wins) and criteria not offered', () {
      final o = SortOrder.normalized(
        [
          _artist,
          const SortSpec(SortCriterion.artist, descending: true),
          _album,
          _yearDesc,
        ],
        offered,
        fallback: fallback,
      );
      expect(o.specs, [_artist, _yearDesc]);
    });

    test('empty or nothing offered gives the fallback', () {
      expect(SortOrder.normalized([], offered, fallback: fallback), fallback);
      expect(
        SortOrder.normalized([_album], offered, fallback: fallback),
        fallback,
      );
    });
  });

  group('value semantics', () {
    test('equal orders are equal with equal hash codes', () {
      final a = SortOrder([_artist, _yearDesc]);
      final b = SortOrder([_artist, _yearDesc]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == SortOrder([_yearDesc, _artist]), isFalse);
      expect(a == SortOrder.single(_artist), isFalse);
    });

    test('the list cannot be changed from outside', () {
      final source = [_artist, _album];
      final o = SortOrder(source);
      source.add(_yearDesc);
      expect(o.specs, hasLength(2));
      expect(() => o.specs.add(_yearDesc), throwsUnsupportedError);
    });

    test('primary and extra', () {
      final o = SortOrder([_artist, _album, _yearDesc]);
      expect(o.primary, _artist);
      expect(o.extra, 2);
      expect(o.contains(SortCriterion.year), isTrue);
      expect(o.contains(SortCriterion.title), isFalse);
    });
  });

  test('equal orders in a key give the same provider instance', () {
    final a = songIdsProvider((
      scope: const SongScope.all(),
      sort: SortOrder([_artist, _yearDesc]),
      filter: '',
    ));
    final b = songIdsProvider((
      scope: const SongScope.all(),
      sort: SortOrder([_artist, _yearDesc]),
      filter: '',
    ));
    final c = songIdsProvider((
      scope: const SongScope.all(),
      sort: SortOrder([_yearDesc, _artist]),
      filter: '',
    ));
    expect(a, b);
    expect(a == c, isFalse);
  });
}
