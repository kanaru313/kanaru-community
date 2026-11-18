import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/m3u/m3u_results.dart';
import 'package:kanaru/src/library/data/m3u/m3u_scan_rules.dart';
import 'package:kanaru/src/library/data/m3u/m3u_track_matcher.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_import.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/storage/data/m3u/m3u_line_resolver.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_parse.dart';

import '../../database/support/test_db.dart';
import '../scan/support/scan_fixtures.dart';
import 'support/m3u_fixtures.dart';

void main() {
  late AppDatabase db;
  late int src;
  setUp(() async {
    db = openTestDb();
    addTearDown(db.close);
    src = await addSource(db, uid: 'src-a');
    await addMount(db, src, root: '/music');
  });

  Future<M3uMatch> match(
    List<M3uResolvedLine> lines, {
    ShortTrackRule short = const ShortTrackRule.off(),
    bool android = false,
  }) => matchM3uLines(db, lines, short: short, androidStorage: android);

  test('existing row of any status wins, missing candidate included', () async {
    final a = await addTrack(db, src, locator: 'a.mp3');
    final gone = await addTrack(
      db,
      src,
      locator: 'gone.mp3',
      status: TrackStatus.missing,
    );
    final hid = await addTrack(
      db,
      src,
      locator: 'x/h.mp3',
      status: TrackStatus.hidden,
    );
    final m = await match([
      rline('a', path: '/music/a.mp3'),
      rline(
        'g',
        candidate: '/music/gone.mp3',
        reason: M3uUnresolvedReason.notFound,
      ),
      rline('h', path: '/music/x/h.mp3'),
      rline('a', path: '/music/a.mp3'),
    ]);
    expect(m.entries, [
      ImportedTrack(TrackId(a)),
      ImportedTrack(TrackId(gone)),
      ImportedTrack(TrackId(hid)),
      ImportedTrack(TrackId(a)),
    ]);
    expect(m.notPresent, 2);
    expect(m.problems, isEmpty);
  });

  test('no row: placeholder only when the file exists', () async {
    final m = await match([
      rline(
        'new',
        path: '/music/d/new.flac',
        extinf: const M3uExtInf(title: 'T', artist: 'Ann', durationMs: 120000),
      ),
      rline('plain', path: '/music/plain.mp3'),
      rline(
        'typo',
        candidate: '/music/typo.mp3',
        reason: M3uUnresolvedReason.notFound,
      ),
      rline('root', path: '/music'),
    ]);
    expect(m.entries, [
      ImportedMissing(
        sourceId: src,
        locator: 'd/new.flac',
        title: 'T',
        artist: 'Ann',
        durationMs: 120000,
      ),
      ImportedMissing(sourceId: src, locator: 'plain.mp3', title: 'plain'),
    ]);
    expect(m.problems.map((p) => p.kind), [
      M3uProblemKind.unresolved,
      M3uProblemKind.unresolved,
    ]);
  });

  test('outside, no base folder and other reasons are grouped', () async {
    final m = await match([
      rline('o', reason: M3uUnresolvedReason.outsideFolders, line: 3),
      rline('n', reason: M3uUnresolvedReason.noBaseFolder, line: 4),
      rline('u', reason: M3uUnresolvedReason.uri, line: 5),
      rline('p', path: '/elsewhere/p.mp3', line: 6),
    ]);
    expect(m.entries, isEmpty);
    expect(m.outsideFolders, 2);
    expect(m.problems.map((p) => (p.line, p.kind)), [
      (3, M3uProblemKind.outsideFolders),
      (4, M3uProblemKind.noBaseFolder),
      (5, M3uProblemKind.unresolved),
      (6, M3uProblemKind.outsideFolders),
    ]);
  });

  test('a disabled mount is not a root', () async {
    final off = await addSource(db, uid: 'src-off');
    await addMount(db, off, root: '/off', enabled: false);
    final m = await match([rline('x', path: '/off/x.mp3')]);
    expect(m.entries, isEmpty);
    expect(m.outsideFolders, 1);
  });

  test('1500 locators go through one json_each per source', () async {
    final log = StatementLog();
    final logged = openLoggedDb(log);
    addTearDown(logged.close);
    final s = await addSource(logged, uid: 's');
    await addMount(logged, s, root: '/music');
    await addManyTracks(logged, s, 1500);
    log.selects.clear();
    final m = await matchM3uLines(logged, androidStorage: false, [
      for (var i = 0; i < 1500; i++)
        rline('f', path: '/music/f${i.toString().padLeft(5, '0')}.mp3'),
    ]);
    expect(m.entries.whereType<ImportedTrack>(), hasLength(1500));
    expect(log.selects.where((q) => q.contains('json_each')), hasLength(1));
  });

  group('lines the scanner never lists', () {
    test('skipped folders and dot files', () async {
      final m = await match([
        rline('a', path: '/music/.archive/a.mp3'),
        rline('b', path: '/music/@eaDir/x.flac'),
        rline('c', path: '/music/.intro.mp3'),
        rline('d', path: '/music/ok/d.mp3'),
      ]);
      expect(m.notScanned, 3);
      expect(m.entries, hasLength(1));
      expect(
        m.problems.every((p) => p.kind == M3uProblemKind.notScanned),
        isTrue,
      );
    });

    test('Android app data unless the root is there', () async {
      final vol = await addSource(db, uid: 'vol');
      await addMount(db, vol, root: '/storage/emulated/0');
      final app = await addSource(db, uid: 'app');
      await addMount(db, app, root: '/storage/emulated/0/Android/media/app');
      final m = await match(android: true, [
        rline('x', path: '/storage/emulated/0/Android/data/x.ogg'),
        rline('y', path: '/storage/emulated/0/Android/media/app/y.ogg'),
        rline('z', path: '/storage/emulated/0/Music/z.ogg'),
      ]);
      expect(m.notScanned, 1);
      expect(m.entries, [
        ImportedMissing(sourceId: app, locator: 'y.ogg', title: 'y'),
        ImportedMissing(sourceId: vol, locator: 'Music/z.ogg', title: 'z'),
      ]);
    });

    test('the Android rule does not apply on Linux paths', () async {
      final vol = await addSource(db, uid: 'vol');
      await addMount(db, vol, root: '/storage');
      final m = await match([rline('x', path: '/storage/disk1/Android/x.mp3')]);
      expect(m.notScanned, 0);
      expect(m.entries, [
        ImportedMissing(
          sourceId: vol,
          locator: 'disk1/Android/x.mp3',
          title: 'x',
        ),
      ]);
    });

    test('short tracks only when the setting is on', () async {
      final short = rline(
        's',
        path: '/music/s.mp3',
        extinf: const M3uExtInf(durationMs: 20000),
      );
      const on = ShortTrackRule(enabled: true);
      expect((await match([short], short: on)).notScanned, 1);
      expect((await match([short])).entries, hasLength(1));
      final noDuration = rline('n', path: '/music/n.mp3');
      expect((await match([noDuration], short: on)).entries, hasLength(1));
    });
  });

  group('case-insensitive storage', () {
    test('one differently cased row is the track, no placeholder', () async {
      final id = await addTrack(db, src, locator: 'Artist/Song.mp3');
      final m = await match([
        rline('s', path: '/music/artist/song.MP3'),
      ], android: true);
      expect(m.entries, [ImportedTrack(TrackId(id))]);
      expect(m.problems, isEmpty);
    });

    test('an exact row wins over a differently cased one', () async {
      await addTrack(db, src, locator: 'Song.mp3');
      final exact = await addTrack(db, src, locator: 'song.mp3');
      final m = await match([
        rline('s', path: '/music/song.mp3'),
      ], android: true);
      expect(m.entries, [ImportedTrack(TrackId(exact))]);
    });

    test('no folding off Android', () async {
      await addTrack(db, src, locator: 'Artist/Song.mp3');
      final m = await match([rline('s', path: '/music/artist/song.MP3')]);
      expect(m.entries.single, isA<ImportedMissing>());
    });

    test('1500 misses cost one fallback query per source', () async {
      final log = StatementLog();
      final logged = openLoggedDb(log);
      addTearDown(logged.close);
      final s = await addSource(logged, uid: 's');
      await addMount(logged, s, root: '/music');
      log.selects.clear();
      final m = await matchM3uLines(logged, androidStorage: true, [
        for (var i = 0; i < 1500; i++) rline('f', path: '/music/n$i.mp3'),
      ]);
      expect(m.entries, hasLength(1500));
      expect(
        log.selects.where((q) => q.contains('lower(locator)')),
        hasLength(1),
      );
      expect(log.selects.where((q) => q.contains('json_each')), hasLength(2));
    });

    test('several cased rows are not guessed', () async {
      await addTrack(db, src, locator: 'Song.mp3');
      await addTrack(db, src, locator: 'SONG.mp3');
      final m = await match([
        rline('s', path: '/music/song.mp3'),
      ], android: true);
      expect(m.entries, [
        ImportedMissing(sourceId: src, locator: 'song.mp3', title: 'song'),
      ]);
    });
  });

  test('the deepest root wins the locator', () async {
    final jazz = await addSource(db, uid: 'jazz');
    await addMount(db, jazz, root: '/music/jazz');
    final m = await match([rline('a', path: '/music/jazz/a.mp3')]);
    expect(m.entries, [
      ImportedMissing(sourceId: jazz, locator: 'a.mp3', title: 'a'),
    ]);
  });

  test('truncated and total lines are carried', () async {
    final m = await matchM3uLines(
      db,
      [rline('a', path: '/music/a.mp3')],
      truncated: true,
      androidStorage: false,
    );
    expect(m.truncated, isTrue);
    expect(m.totalLines, 1);
  });
}
