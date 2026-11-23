import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/domain/info/release_date.dart';
import 'package:kanaru/src/library/domain/info/song_details.dart';
import 'package:kanaru/src/library/ui/info/song_info_formats.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/library/ui/info/song_info_groups.dart';
import 'package:kanaru/src/library/ui/info/song_info_notice.dart';
import 'package:kanaru/src/library/ui/info/song_info_spec.dart';

import 'song_info_fixtures.dart';

final _now = DateTime(2026, 11, 23);
final _en = lookupAppLocalizations(const Locale('en'));
final _vi = lookupAppLocalizations(const Locale('vi'));

List<InfoGroupSpec> _groups(
  SongDetails d, {
  AppLocalizations? l10n,
  bool showEmpty = false,
  bool canReveal = true,
  bool desktop = true,
}) => buildSongInfoGroups(
  l10n ?? _en,
  d,
  _now,
  showEmpty: showEmpty,
  canReveal: canReveal,
  desktop: desktop,
);

Map<InfoRowId, InfoRowSpec> _rows(List<InfoGroupSpec> groups) => {
  for (final g in groups)
    for (final r in g.rows) r.id: r,
};

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('vi');
  });

  group('a full song', () {
    late List<InfoGroupSpec> groups;
    late Map<InfoRowId, InfoRowSpec> rows;
    setUp(() {
      groups = _groups(fullDetails());
      rows = _rows(groups);
    });

    test('four groups in order; Lyrics is the next PR\'s slot', () {
      expect(groups.map((g) => g.id), ['tags', 'audio', 'file', 'you']);
    });

    test('tag rows carry their value or their links', () {
      expect(rows[InfoRowId.title]!.value, 'Ngày chưa giông bão');
      expect(rows[InfoRowId.artists]!.links.map((l) => l.text), [
        'Bùi Lan Hương',
        'Phan Mạnh Quỳnh',
      ]);
      expect(
        rows[InfoRowId.artists]!.links.first.location,
        startsWith('/library/artists/'),
      );
      expect(
        rows[InfoRowId.album]!.links.single.location,
        startsWith('/library/albums/'),
      );
      // The album artist shows even when it is also a track artist.
      expect(rows[InfoRowId.albumArtist]!.links.single.text, 'Bùi Lan Hương');
      expect(
        rows[InfoRowId.genre]!.links.single.location,
        LibraryLocations.genre('ballad'),
      );
      expect(rows[InfoRowId.composer]!.value, 'Phan Mạnh Quỳnh');
      expect(rows[InfoRowId.trackNo]!.value, '1/12');
      expect(rows[InfoRowId.disc]!.value, '1/2');
      expect(rows[InfoRowId.comment]!.value, 'Nhạc phim Người bất tử');
      expect(rows[InfoRowId.description]!.value, 'Bài hát chủ đề phim');
    });

    test('language links to its page and says it was detected', () {
      final row = rows[InfoRowId.language]!;
      expect(row.links.single.location, LibraryLocations.language('vi'));
      expect(row.badge, 'detected');
    });

    test('audio rows', () {
      expect(rows[InfoRowId.duration]!.value, '5:10');
      expect(rows[InfoRowId.format]!.value, 'FLAC');
      expect(rows[InfoRowId.bitrate]!.value, '2304 kbps (average)');
      expect(rows[InfoRowId.sampleRate]!.value, '96 kHz');
      expect(rows[InfoRowId.bitDepth]!.value, '24-bit');
      expect(rows[InfoRowId.channels]!.value, 'Stereo');
      expect(rows[InfoRowId.replayGain]!.soon, isTrue);
    });

    test('file rows', () {
      final path = rows[InfoRowId.path]!;
      expect(path.kind, InfoRowKind.path);
      expect(path.value, '/home/u/Music/Blue/01 - Song.flac');
      expect(path.canReveal, isTrue);
      expect(rows[InfoRowId.musicFolder]!.value, '/home/u/Music');
      expect(rows[InfoRowId.size]!.value, '87.2 MB');
      expect(rows[InfoRowId.modified]!.value, contains('2025'));
      expect(rows[InfoRowId.added]!.value, contains('2026'));
    });

    test('yours rows: favorite button, rating soon, counts', () {
      expect(rows[InfoRowId.favorite]!.kind, InfoRowKind.favorite);
      expect(rows[InfoRowId.rating]!.soon, isTrue);
      expect(rows[InfoRowId.plays]!.value, '19 times');
      expect(rows[InfoRowId.skips]!.value, '2 times');
      expect(rows[InfoRowId.firstPlayed]!.value, isNot('Never played'));
    });

    test('nothing is empty', () {
      expect(rows.values.where((r) => r.empty), isEmpty);
    });
  });

  group('empty fields', () {
    final d = bareDetails();

    test('hidden by default, shown with the eye', () {
      final hidden = _rows(_groups(d));
      final shown = _rows(_groups(d, showEmpty: true));
      expect(hidden.containsKey(InfoRowId.composer), isFalse);
      expect(shown[InfoRowId.composer]!.empty, isTrue);
      expect(hidden.containsKey(InfoRowId.title), isTrue);
    });

    test('the count leaves out soon rows, Description and Codec', () {
      final shown = _rows(_groups(d, showEmpty: true));
      expect(shown.containsKey(InfoRowId.description), isFalse);
      expect(shown.containsKey(InfoRowId.codec), isFalse);
      final empties = shown.values
          .where((r) => r.empty)
          .map((r) => r.id)
          .toSet();
      expect(empties, isNot(contains(InfoRowId.replayGain)));
      expect(empties, isNot(contains(InfoRowId.rating)));
      expect(songInfoEmptyCount(_en, d, _now, desktop: true), empties.length);
      // artists, album, album artist, genre, composer, released, track, disc,
      // language, comment, duration, bitrate, rate, depth, channels, size,
      // modified, last played, music folder
      expect(empties, containsAll([InfoRowId.artists, InfoRowId.lastPlayed]));
    });

    test('Description appears only when the tag has one', () {
      expect(
        _rows(_groups(fullDetails())).containsKey(InfoRowId.description),
        isTrue,
      );
      expect(
        _rows(_groups(d, showEmpty: true)).containsKey(InfoRowId.description),
        isFalse,
      );
    });

    test('a song never played says so, not "Unknown"', () {
      final row = _rows(_groups(d))[InfoRowId.firstPlayed]!;
      expect(row.value, 'Never played');
      expect(row.empty, isFalse);
      expect(row.muted, isTrue);
      expect(_rows(_groups(d))[InfoRowId.plays]!.value, '0 times');
    });
  });

  group('codec', () {
    bool differs(String? codec, String? format) =>
        _rows(_groups(fullDetails(codec: codec, format: format)))
            .containsKey(InfoRowId.codec);

    test('is shown only when it says more than the format', () {
      // Same family, any case.
      expect(differs('FLAC', 'FLAC'), isFalse);
      expect(differs('flac', 'FLAC'), isFalse);
      expect(differs('MPEG-1 Layer 3', 'MP3'), isFalse);
      expect(differs('MP3', 'MP3'), isFalse);
      expect(differs('MP4', 'M4A'), isFalse);
      expect(differs('Vorbis', 'OGG'), isFalse);
      expect(differs('WavPack', 'WV'), isFalse);
      expect(differs('AIFF', 'AIF'), isFalse);
      // Different.
      expect(differs('AAC-LC', 'M4A'), isTrue);
      expect(differs('Opus', 'OGG'), isTrue);
      expect(differs('ALAC', 'M4A'), isTrue);
      // No codec: nothing to add. No format: the codec is all we know.
      expect(differs(null, 'FLAC'), isFalse);
      expect(differs('  ', 'FLAC'), isFalse);
      expect(differs('FLAC', null), isTrue);
    });
  });

  group('release date', () {
    String? released(SongDetails d, {AppLocalizations? l10n}) =>
        _rows(_groups(d, l10n: l10n))[InfoRowId.released]?.value;

    test('the full date and how long ago', () {
      expect(released(fullDetails()), '2018-03 · 8 years ago');
      expect(
        _rows(_groups(fullDetails()))[InfoRowId.released]!.copyText,
        '2018-03',
      );
    });

    test('plural: one year, this year, the Vietnamese form', () {
      final one = fullDetails(
        releaseDate: const ReleaseDate(year: 2025),
        year: 2025,
      );
      expect(released(one), '2025 · 1 year ago');
      final now = fullDetails(
        releaseDate: const ReleaseDate(year: 2026, month: 5, day: 9),
        year: 2026,
      );
      expect(released(now), '2026-05-09 · this year');
      expect(released(fullDetails(), l10n: _vi), '2018-03 · 8 năm trước');
    });

    test(
      'a date whose year differs from the year tag falls back to the year',
      () {
        final d = fullDetails(
          releaseDate: const ReleaseDate(year: 2017, month: 3),
          year: 2018,
        );
        expect(released(d), '2018 · 8 years ago');
      },
    );

    test('no date: the year alone; neither: an empty row; a future year has no age', () {
      expect(released(fullDetails(releaseDate: null)), '2018 · 8 years ago');
      final none = fullDetails(releaseDate: null, year: null);
      expect(_rows(_groups(none)).containsKey(InfoRowId.released), isFalse);
      expect(
        _rows(_groups(none, showEmpty: true))[InfoRowId.released]!.empty,
        isTrue,
      );
      expect(released(fullDetails(releaseDate: null, year: 2030)), '2030');
    });
  });

  group('file', () {
    test('a missing file strikes the path out', () {
      final d = fullDetails(status: SongFileStatus.missing, missingSince: 1);
      final path = _rows(_groups(d))[InfoRowId.path]!;
      expect(path.missing, isTrue);
      expect(path.value, isNotNull);
    });

    test('"Show in file manager" only where the platform has one', () {
      final d = fullDetails();
      expect(
        _rows(_groups(d, canReveal: false))[InfoRowId.path]!.canReveal,
        isFalse,
      );
    });

    test('no mounted root: the path row is empty', () {
      final row = _rows(
        _groups(fullDetails(path: null), showEmpty: true),
      )[InfoRowId.path]!;
      expect(row.empty, isTrue);
      expect(row.canReveal, isFalse);
    });

    test(
      'the music folder is the source name on a phone, its root on desktop',
      () {
        expect(
          _rows(
            _groups(fullDetails(), desktop: false),
          )[InfoRowId.musicFolder]!.value,
          'Music',
        );
      },
    );
  });

  group('notice', () {
    test('priority: missing file, tag error, few tags, none', () {
      expect(
        songInfoNoticeKind(
          fullDetails(status: SongFileStatus.missing, scanError: 'x'),
        ),
        SongInfoNoticeKind.fileMissing,
      );
      expect(
        songInfoNoticeKind(fullDetails(scanError: 'bad frame')),
        SongInfoNoticeKind.scanError,
      );
      expect(songInfoNoticeKind(bareDetails()), SongInfoNoticeKind.fewTags);
      expect(songInfoNoticeKind(fullDetails()), isNull);
    });

    test('few tags needs the title to be the file name', () {
      expect(songInfoNoticeKind(bareDetails(title: 'A real title')), isNull);
      expect(songInfoNoticeKind(bareDetails(path: null)), isNull);
      expect(
        songInfoNoticeKind(bareDetails(scanError: ' ')),
        SongInfoNoticeKind.fewTags,
      );
    });
  });

  group('formats', () {
    test('sizes use binary units and the locale', () {
      expect(formatBytes(512), '512 B');
      expect(formatBytes(2048), '2.0 KB');
      expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
      expect(formatBytes(3 * 1024 * 1024 * 1024), '3.0 GB');
      expect(formatBytes(3584 * 1024, 'vi'), '3,5 MB');
      expect(formatBytes(3584 * 1024, 'en'), '3.5 MB');
    });

    test('kHz: no decimal for a round rate', () {
      expect(formatKhz(48000, 'en'), '48');
      expect(formatKhz(44100, 'en'), '44.1');
      expect(formatKhz(44100, 'vi'), '44,1');
    });

    test('durations', () {
      expect(formatInfoDuration(310000), '5:10');
      expect(formatInfoDuration(3723000), '1:02:03');
      expect(formatInfoDuration(0), '0:00');
    });

    test('channels', () {
      expect(channelsText(_en, 1), 'Mono');
      expect(channelsText(_en, 2), 'Stereo');
      expect(channelsText(_en, 6), '6 channels');
      expect(channelsText(_vi, 6), '6 kênh');
    });

    test('release date prints what the tag gave', () {
      expect(formatReleaseDate(const ReleaseDate(year: 2018)), '2018');
      expect(
        formatReleaseDate(const ReleaseDate(year: 2018, month: 3)),
        '2018-03',
      );
      expect(
        formatReleaseDate(const ReleaseDate(year: 2018, month: 3, day: 9)),
        '2018-03-09',
      );
    });

    test('file stem', () {
      expect(fileStem('/a/b/07 - Song.flac'), '07 - Song');
      expect(fileStem('/a/noext'), 'noext');
      expect(fileStem('/a/.hidden'), '.hidden');
    });
  });

  test('Vietnamese labels follow the mockup', () {
    final groups = _groups(fullDetails(), l10n: _vi);
    expect(groups.map((g) => g.title), ['Thẻ', 'Âm thanh', 'Tệp', 'Của bạn']);
    final rows = _rows(groups);
    expect(rows[InfoRowId.artists]!.label, 'Nghệ sĩ');
    expect(rows[InfoRowId.plays]!.value, '19 lần');
    expect(rows[InfoRowId.bitrate]!.value, '2304 kbps (trung bình)');
  });
}
