import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/scan/lrc_match.dart';
import 'package:kanaru/src/library/domain/scan/scan_diff.dart';
import 'package:kanaru/src/storage/domain/local_folder_listing.dart';

const _tags = 2;
const _keys = 3;

ListedFile _f(String locator, {int mtime = 10, int size = 100}) =>
    ListedFile(locator: locator, sizeBytes: size, mtimeMs: mtime);

StoredTrackRow _row(
  int id,
  String locator, {
  String status = 'present',
  int? mtime = 10,
  int? size = 100,
  int tags = _tags,
  int keys = _keys,
  String? lrcLocator,
  String? lrcRevision,
}) => StoredTrackRow(
  id: id,
  locator: locator,
  status: status,
  mtimeMs: mtime,
  sizeBytes: size,
  tagsVersion: tags,
  keysVersion: keys,
  lrcLocator: lrcLocator,
  lrcRevision: lrcRevision,
);

ScanDiff _diff(
  SourceListing listing,
  List<StoredTrackRow> stored, {
  bool full = false,
}) => diffScan(
  listing,
  stored,
  tagsVersion: _tags,
  keysVersion: _keys,
  full: full,
);

List<String> _read(ScanDiff d) => [for (final r in d.toRead) r.file.locator];

void main() {
  test('a new file is read', () {
    final d = _diff(SourceListing(files: [_f('a.mp3')]), const []);
    expect(_read(d), ['a.mp3']);
    expect(d.toRead.single.stored, isNull);
  });

  test('a changed size or mtime is read, an identical file is unchanged', () {
    final stored = [
      _row(1, 'size.mp3'),
      _row(2, 'time.mp3'),
      _row(3, 'same.mp3'),
    ];
    final d = _diff(
      SourceListing(
        files: [
          _f('size.mp3', size: 101),
          _f('time.mp3', mtime: 11),
          _f('same.mp3'),
        ],
      ),
      stored,
    );
    expect(_read(d), ['size.mp3', 'time.mp3']);
    expect(d.unchanged, 1);
    expect(d.toRead.first.stored!.id, 1);
  });

  test('an old tags_version or keys_version is read again', () {
    final d = _diff(
      SourceListing(files: [_f('t.mp3'), _f('k.mp3'), _f('ok.mp3')]),
      [_row(1, 't.mp3', tags: 1), _row(2, 'k.mp3', keys: 2), _row(3, 'ok.mp3')],
    );
    expect(_read(d), ['t.mp3', 'k.mp3']);
  });

  test('a row without mtime (transient error) is read again', () {
    final d = _diff(SourceListing(files: [_f('a.mp3')]), [
      _row(1, 'a.mp3', mtime: null, size: null),
    ]);
    expect(_read(d), ['a.mp3']);
  });

  test('a listed file whose row is missing is read to revive it', () {
    final d = _diff(SourceListing(files: [_f('a.mp3')]), [
      _row(1, 'a.mp3', status: 'missing'),
    ]);
    expect(_read(d), ['a.mp3']);
    expect(d.missingCandidates, isEmpty);
  });

  test('full reads everything', () {
    final d = _diff(SourceListing(files: [_f('a.mp3'), _f('b.mp3')]), [
      _row(1, 'a.mp3'),
      _row(2, 'b.mp3'),
    ], full: true);
    expect(_read(d), ['a.mp3', 'b.mp3']);
    expect(d.unchanged, 0);
  });

  test('a present row that is not listed is a missing candidate', () {
    final d = _diff(SourceListing(files: [_f('keep.mp3')]), [
      _row(1, 'keep.mp3'),
      _row(2, 'gone.mp3'),
      _row(3, 'already.mp3', status: 'missing'),
    ]);
    expect(d.missingCandidates, [2]);
  });

  test('rows under an uncertain prefix are kept', () {
    final d = _diff(
      SourceListing(
        files: [_f('keep.mp3')],
        uncertainPrefixes: const ['usb/', 'locked/'],
      ),
      [
        _row(1, 'keep.mp3'),
        _row(2, 'usb/a.mp3'),
        _row(3, 'locked/deep/b.mp3'),
        _row(4, 'usbx/c.mp3'),
      ],
    );
    expect(d.missingCandidates, [4]);
  });

  test('the empty prefix protects the whole root', () {
    final d = _diff(
      SourceListing(files: [_f('keep.mp3')], uncertainPrefixes: const ['']),
      [_row(1, 'keep.mp3'), _row(2, 'x/gone.mp3')],
    );
    expect(d.missingCandidates, isEmpty);
  });

  test('unstattable locators are kept', () {
    final d = _diff(
      SourceListing(files: [_f('keep.mp3')], unstattable: const {'dead.mp3'}),
      [_row(1, 'keep.mp3'), _row(2, 'dead.mp3'), _row(3, 'gone.mp3')],
    );
    expect(d.missingCandidates, [3]);
  });

  test('an unreachable listing gives an empty diff', () {
    final d = _diff(const SourceListing.unreachable(), [_row(1, 'a.mp3')]);
    expect(d.toRead, isEmpty);
    expect(d.missingCandidates, isEmpty);
    expect(d.rootSuspect, isFalse);
  });

  test('0 files with stored present rows and no filter is suspect', () {
    final d = _diff(const SourceListing(), [
      _row(1, 'a.mp3'),
      _row(2, 'b.mp3'),
    ]);
    expect(d.rootSuspect, isTrue);
    expect(d.missingCandidates, isEmpty);
  });

  test('skippedOut alone does not switch the guard off', () {
    final d = _diff(const SourceListing(skippedOut: 5), [_row(1, 'a.mp3')]);
    expect(d.rootSuspect, isTrue);
    expect(d.missingCandidates, isEmpty);
  });

  test('0 files with a user filter lets the rows go missing', () {
    for (final listing in [
      const SourceListing(excludedOut: 1),
      const SourceListing(shortOut: 1),
    ]) {
      final d = _diff(listing, [_row(1, 'a.mp3'), _row(2, 'b.mp3')]);
      expect(d.rootSuspect, isFalse);
      expect(d.missingCandidates, [1, 2]);
    }
  });

  test('0 files and no stored rows is not suspect', () {
    final d = _diff(const SourceListing(), const []);
    expect(d.rootSuspect, isFalse);
  });

  test('hidden rows are never candidates (not in the stored rows)', () {
    // The stored-row query returns present and missing rows only.
    final d = _diff(SourceListing(files: [_f('a.mp3')]), [_row(1, 'a.mp3')]);
    expect(d.missingCandidates, isEmpty);
  });

  group('lyrics', () {
    ListedLyrics lrc(String locator, {int mtime = 5, int size = 7}) =>
        ListedLyrics(locator: locator, sizeBytes: size, mtimeMs: mtime);

    test('same folder, same stem, any case; other stems are ignored', () {
      final lyrics = {
        '': [lrc('Song.LRC')],
        'a': [lrc('a/other.lrc'), lrc('a/one.lrc')],
      };
      expect(lrcFor('song.mp3', lyrics)!.locator, 'Song.LRC');
      expect(lrcFor('song.mp3', lyrics)!.revision, '5:7');
      expect(lrcFor('a/one.flac', lyrics)!.locator, 'a/one.lrc');
      expect(lrcFor('a/two.mp3', lyrics), isNull);
      expect(lrcFor('b/one.mp3', lyrics), isNull);
      expect(lrcFor('one.mp3', lyrics), isNull);
    });

    test('a sidecar change on an unchanged file is an lrc update', () {
      final listing = SourceListing(
        files: [_f('a.mp3'), _f('b.mp3'), _f('c.mp3'), _f('d.mp3')],
        lyrics: {
          '': [lrc('a.lrc'), lrc('b.lrc', mtime: 6), lrc('d.lrc')],
        },
      );
      final d = _diff(listing, [
        _row(1, 'a.mp3', lrcLocator: 'a.lrc', lrcRevision: '5:7'),
        _row(2, 'b.mp3', lrcLocator: 'b.lrc', lrcRevision: '5:7'),
        _row(3, 'c.mp3', lrcLocator: 'c.lrc', lrcRevision: '5:7'),
        _row(4, 'd.mp3'),
      ]);
      expect(d.toRead, isEmpty);
      expect(
        {for (final u in d.lrcUpdates) u.row.id: u.lrc?.revision},
        {2: '6:7', 3: null, 4: '5:7'},
      );
    });

    test('a file that is read carries its sidecar', () {
      final d = _diff(
        SourceListing(
          files: [_f('a.mp3')],
          lyrics: {
            '': [lrc('a.lrc')],
          },
        ),
        const [],
      );
      expect(d.toRead.single.lrc!.locator, 'a.lrc');
    });
  });
}
