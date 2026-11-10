import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/scan/track_row_builder.dart';
import 'package:kanaru/src/library/domain/scan/lrc_match.dart';
import 'package:kanaru/src/library/domain/scan/native_failure.dart';
import 'package:kanaru/src/library/domain/scan/scan_diff.dart';
import 'package:kanaru/src/library/domain/scan/scan_folder.dart';
import 'package:kanaru/src/library/domain/scan/scan_versions.dart';
import 'package:kanaru/src/library/domain/scan/tag_read.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/storage/domain/local_folder_listing.dart';

const _folder = ScanFolder(sourceId: 7, sourceUid: 'src-7', root: '/music');
const _file = ListedFile(
  locator: 'Album/01 Hà Nội.mp3',
  sizeBytes: 123,
  mtimeMs: 456,
);

TagRead _ok(TagFields f) => TagRead(path: '/music/${_file.locator}', fields: f);

TagRead _err(String kind, bool transient) => TagRead(
  path: '/music/${_file.locator}',
  error: NativeFailure(kind: kind, transient: transient),
);

BuiltTrack _build(
  TagRead read, {
  StoredTrackRow? stored,
  LrcMatch? lrc,
  ListedFile file = _file,
}) => buildTrackRow(
  folder: _folder,
  file: file,
  read: read,
  now: 9000,
  stored: stored,
  lrc: lrc,
);

T _v<T>(Value<T> v) => v.value;

void main() {
  test(
    'stored-column rule: every derived column comes from the key functions',
    () {
      final b = _build(
        _ok(
          const TagFields(
            title: 'Hà Nội',
            artists: ['Hà Anh Tuấn; Đen Vâu'],
            album: 'Album Tên',
            albumArtists: ['Various'],
            genres: ['Pop', 'Rock'],
            composer: 'Nhạc sĩ',
            titleSort: 'Ha Noi',
            artistSort: 'Tuan, Ha Anh',
            albumSort: 'Album Ten',
            year: 2020,
            trackNo: 1,
            trackTotal: 12,
            discNo: 1,
            discTotal: 2,
            durationMs: 200000,
            bitrate: 320,
            sampleRate: 44100,
            bitDepth: 16,
            channels: 2,
            codec: 'MP3',
          ),
        ),
      );
      final r = b.row;
      expect(_v(r.title), 'Hà Nội');
      expect(_v(r.titleSearch), searchForm('Hà Nội'));
      expect(_v(r.titleSearch), 'ha noi');
      expect(_v(r.titleSort), sortForm('Ha Noi'));
      expect(_v(r.artist), 'Hà Anh Tuấn; Đen Vâu');
      expect(_v(r.artistSearch), searchForm('Hà Anh Tuấn Đen Vâu'));
      expect(_v(r.album), 'Album Tên');
      expect(_v(r.albumSearch), searchForm('Album Tên'));
      expect(_v(r.albumArtist), 'Various');
      expect(_v(r.albumArtistSearch), searchForm('Various'));
      final key = albumKeyFor(
        album: 'Album Tên',
        albumArtist: 'Various',
        artists: ['Hà Anh Tuấn', 'Đen Vâu'],
      )!;
      expect(_v(r.albumArtistKey), key.artistKey);
      expect(_v(r.albumTitleKey), key.titleKey);
      expect(_v(r.genre), 'Pop; Rock');
      expect(_v(r.genreKey), groupKey('Pop; Rock'));
      expect(_v(r.genreSearch), searchForm('Pop; Rock'));
      expect(_v(r.songKey), songKey(title: 'Hà Nội', artists: ['Hà Anh Tuấn']));
      expect(_v(r.artistSort), sortForm('Tuan, Ha Anh'));
      expect(_v(r.albumSort), sortForm('Album Ten'));
      expect(_v(r.composer), 'Nhạc sĩ');
      expect(_v(r.codec), 'MP3');
      expect(_v(r.year), 2020);
      expect(_v(r.durationMs), 200000);
      expect(_v(r.trackNo), 1);
      expect(_v(r.discTotal), 2);
      expect(_v(r.scanError), isNull);
      expect([for (final a in b.artists) a.name], ['Hà Anh Tuấn', 'Đen Vâu']);
      expect(b.artists.first.key, groupKey('Hà Anh Tuấn'));
    },
  );

  test('identity and file columns', () {
    final b = _build(_ok(const TagFields(title: 'T')));
    final r = b.row;
    expect(_v(r.uid), trackUid('src-7', _file.locator));
    expect(_v(r.sourceId), 7);
    expect(_v(r.locator), _file.locator);
    expect(_v(r.relPath), _file.locator);
    expect(_v(r.mtimeMs), 456);
    expect(_v(r.sizeBytes), 123);
    expect(_v(r.revision), '456:123');
    expect(_v(r.addedAt), 9000);
    expect(_v(r.updatedAt), 9000);
    expect(_v(r.tagsVersion), tagsPassVersion);
    expect(_v(r.keysVersion), libraryKeysVersion);
    expect(_v(r.coverScanVersion), 0);
    expect(r.status.present, isFalse);
  });

  test('an empty album stores both keys and the album as NULL', () {
    final b = _build(_ok(const TagFields(title: 'T', album: '  ')));
    expect(_v(b.row.album), isNull);
    expect(_v(b.row.albumArtistKey), isNull);
    expect(_v(b.row.albumTitleKey), isNull);
    expect(_v(b.row.albumSearch), isNull);
  });

  test('the album artist key falls back to the first split artist', () {
    final b = _build(
      _ok(const TagFields(title: 'T', album: 'X', artists: ['A feat. B'])),
    );
    expect(_v(b.row.albumArtistKey), 'a');
    expect(_v(b.row.albumArtistSearch), 'a');
  });

  test('a row without genre writes genre and genre_key as explicit NULL', () {
    final b = _build(_ok(const TagFields(title: 'T')));
    expect(b.row.genre.present, isTrue);
    expect(_v(b.row.genre), isNull);
    expect(b.row.genreKey.present, isTrue);
    expect(_v(b.row.genreKey), isNull);
  });

  test('a blank title falls back to the file stem', () {
    final b = _build(_ok(const TagFields(title: '  ')));
    expect(_v(b.row.title), '01 Hà Nội');
    expect(_v(b.row.titleSearch), searchForm('01 Hà Nội'));
    expect(_v(b.row.titleSort), searchForm('01 Hà Nội'));
  });

  test('language: tag vi gives vie, detection is only a fallback', () {
    final tagged = _build(
      _ok(
        const TagFields(title: 'T', languageTag: 'vi', detectedLanguage: 'eng'),
      ),
    );
    expect(_v(tagged.row.language), 'vie');
    expect(_v(tagged.row.languageDetected), 0);

    final detected = _build(
      _ok(const TagFields(title: 'T', detectedLanguage: 'zho')),
    );
    expect(_v(detected.row.language), 'zho');
    expect(_v(detected.row.languageDetected), 1);

    final none = _build(_ok(const TagFields(title: 'T', languageTag: 'und')));
    expect(_v(none.row.language), isNull);
    expect(_v(none.row.languageDetected), 0);
  });

  group('cover_scan_version', () {
    final stored = StoredTrackRow(
      id: 1,
      locator: _file.locator,
      status: 'present',
      revision: '456:123',
    );

    test('reset for a new row', () {
      expect(
        _v(_build(_ok(const TagFields(title: 'T'))).row.coverScanVersion),
        0,
      );
    });

    test('reset when the revision changed', () {
      final b = _build(
        _ok(const TagFields(title: 'T')),
        stored: StoredTrackRow(
          id: 1,
          locator: _file.locator,
          status: 'present',
          revision: '1:1',
        ),
      );
      expect(_v(b.row.coverScanVersion), 0);
    });

    test('kept by a keys-only re-read', () {
      final b = _build(_ok(const TagFields(title: 'T')), stored: stored);
      expect(b.row.coverScanVersion.present, isFalse);
    });
  });

  group('errors', () {
    test(
      'a permanent error gives a filename-only row with current versions',
      () {
        final b = _build(_err('corrupt', false));
        final r = b.row;
        expect(_v(r.title), '01 Hà Nội');
        expect(_v(r.scanError), 'corrupt');
        expect(_v(r.tagsVersion), tagsPassVersion);
        expect(_v(r.mtimeMs), 456);
        expect(_v(r.sizeBytes), 123);
        expect(_v(r.revision), '456:123');
        expect(_v(r.artist), isNull);
        expect(b.artists, isEmpty);
      },
    );

    test(
      'a transient error on a new file leaves version 0 and no file columns',
      () {
        final b = _build(_err('timeout', true));
        final r = b.row;
        expect(_v(r.title), '01 Hà Nội');
        expect(_v(r.scanError), 'timeout');
        expect(_v(r.tagsVersion), 0);
        expect(r.mtimeMs.present, isTrue);
        expect(_v(r.mtimeMs), isNull);
        expect(_v(r.sizeBytes), isNull);
        expect(_v(r.revision), isNull);
        expect(_v(r.keysVersion), libraryKeysVersion);
      },
    );

    test('a transient error on an existing row is never built', () {
      final stored = StoredTrackRow(
        id: 1,
        locator: _file.locator,
        status: 'present',
      );
      expect(
        () => _build(_err('io', true), stored: stored),
        throwsArgumentError,
      );
    });

    test('a permanent error on an existing row rewrites it filename-only', () {
      final stored = StoredTrackRow(
        id: 1,
        locator: _file.locator,
        status: 'present',
        revision: '1:1',
      );
      final b = _build(_err('unsupported', false), stored: stored);
      expect(_v(b.row.tagsVersion), tagsPassVersion);
      expect(_v(b.row.revision), '456:123');
      expect(_v(b.row.coverScanVersion), 0);
    });
  });

  group('details', () {
    test('none without a comment or sidecar', () {
      expect(_build(_ok(const TagFields(title: 'T'))).details, isNull);
    });

    test('sidecar and comment are written together', () {
      final b = _build(
        _ok(const TagFields(title: 'T', comment: 'hi')),
        lrc: const LrcMatch(locator: 'Album/01 Hà Nội.lrc', revision: '1:2'),
      );
      expect(_v(b.details!.comment), 'hi');
      expect(b.details!.lrcLocator, 'Album/01 Hà Nội.lrc');
      expect(b.details!.lrcRevision, '1:2');
    });

    test('an existing details row is cleared when the sidecar is gone', () {
      final b = _build(
        _ok(const TagFields(title: 'T')),
        stored: StoredTrackRow(
          id: 1,
          locator: _file.locator,
          status: 'present',
          revision: '456:123',
          hasDetails: true,
        ),
      );
      expect(b.details!.lrcLocator, isNull);
      expect(_v(b.details!.comment), isNull);
    });
  });

  test('the companion passes the snapshot helper pairing checks', () {
    // Every pair is written together, with and without values.
    for (final f in const [
      TagFields(),
      TagFields(title: 'T', album: 'A', genres: ['G']),
      TagFields(album: '\u0001'),
    ]) {
      final cols = _build(_ok(f)).row.toColumns(false);
      expect(cols.containsKey('title'), cols.containsKey('title_search'));
      expect(cols.containsKey('genre'), cols.containsKey('genre_key'));
      expect(cols.containsKey('album'), cols.containsKey('album_title_key'));
      expect(cols.containsKey('album'), cols.containsKey('album_artist_key'));
    }
  });
}
