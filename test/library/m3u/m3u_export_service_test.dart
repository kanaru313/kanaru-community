import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/library/data/m3u/m3u_export_entries.dart';
import 'package:kanaru/src/library/data/m3u/m3u_export_service.dart';
import 'package:kanaru/src/library/data/m3u/m3u_results.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';

import '../../database/support/test_db.dart';
import 'support/m3u_env.dart';

void main() {
  late M3uEnv env;
  setUp(() async => env = await M3uEnv.open());

  SaveTarget target({String? dir}) {
    final path = '${dir ?? '${env.tmp}/lists'}/out.m3u';
    return SaveTarget(name: 'out.m3u', handle: path, localPath: path);
  }

  M3uExportService service() => M3uExportService(env.db, env.picker, realPath);

  M3uExportResult ok(Result<M3uExportResult, M3uExportError> r) =>
      (r as Ok<M3uExportResult, M3uExportError>).value;

  Future<String> playlist(List<int> ids) => env.repo.createPlaylist(
    name: 'P',
    tracks: [for (final i in ids) TrackId(i)],
  );

  test('order equals loadPlaylist after a move', () async {
    final a = await addTrack(env.db, env.source, locator: 'a.mp3', title: 'A');
    final b = await addTrack(env.db, env.source, locator: 'b.mp3', title: 'B');
    final c = await addTrack(env.db, env.source, locator: 'c.mp3', title: 'C');
    final uid = await playlist([a, b, c]);
    final before = (await env.repo.loadPlaylist(uid))!;
    await env.repo.moveEntry(uid, before.entries.last.uid, afterEntryUid: null);
    final expected = [
      for (final e in (await env.repo.loadPlaylist(uid))!.entries) e.info.title,
    ];
    final entries = (await loadM3uExportEntries(env.db, uid))!;
    expect([for (final e in entries) e.title], expected);
    expect(expected.first, 'C');
  });

  test(
    'absolute and relative text, missing rows keep path and EXTINF',
    () async {
      final a = await addTrack(
        env.db,
        env.source,
        locator: 'd/a.mp3',
        title: 'A',
      );
      final m = await addTrack(
        env.db,
        env.source,
        locator: 'm.mp3',
        title: 'M',
        status: TrackStatus.missing,
      );
      await env.db.customStatement(
        "UPDATE tracks SET artist = 'Ann', duration_ms = 200500 WHERE id = ?",
        [m],
      );
      final uid = await playlist([a, m]);

      expect(
        ok(await service().exportPlaylist(uid, target(), relative: false)),
        isA<M3uExportResult>()
            .having((r) => r.written, 'written', 2)
            .having((r) => r.skipped, 'skipped', 0),
      );
      expect(
        env.picker.lastText,
        '#EXTM3U\n#EXTINF:-1,A\n${env.music}/d/a.mp3\n'
        '#EXTINF:200,Ann - M\n${env.music}/m.mp3\n',
      );

      await service().exportPlaylist(uid, target(), relative: true);
      expect(
        env.picker.lastText,
        '#EXTM3U\n#EXTINF:-1,A\n../music/d/a.mp3\n'
        '#EXTINF:200,Ann - M\n../music/m.mp3\n',
      );
    },
  );

  test('relative paths use the canonical target folder', () async {
    final a = await addTrack(env.db, env.source, locator: 'a.mp3');
    Link('${env.tmp}/lists-link').createSync('${env.tmp}/lists');
    await service().exportPlaylist(
      await playlist([a]),
      target(dir: '${env.tmp}/lists-link'),
      relative: true,
    );
    expect(env.picker.lastText, contains('\n../music/a.mp3\n'));
  });

  test('remote and cue rows are skipped and counted', () async {
    final a = await addTrack(env.db, env.source, locator: 'a.mp3');
    final cue = await addTrack(env.db, env.source, locator: 'c.flac#2');
    final remote = await addSource(env.db, kind: SourceKind.plugin, root: 'p');
    final r = await addTrack(env.db, remote, locator: 'id1');
    final uid = await playlist([a, cue, r]);
    final res = ok(
      await service().exportPlaylist(uid, target(), relative: false),
    );
    expect((res.written, res.skipped), (1, 2));
    expect(env.picker.lastText, isNot(contains('c.flac')));
  });

  test('removed entries are left out, order kept', () async {
    final a = await addTrack(env.db, env.source, locator: 'a.mp3', title: 'A');
    final b = await addTrack(env.db, env.source, locator: 'b.mp3', title: 'B');
    final c = await addTrack(env.db, env.source, locator: 'c.mp3', title: 'C');
    final uid = await playlist([a, b, c]);
    final detail = (await env.repo.loadPlaylist(uid))!;
    await env.repo.removeEntries(uid, [detail.entries[1].uid]);
    final res = ok(
      await service().exportPlaylist(uid, target(), relative: false),
    );
    expect(res.written, 2);
    expect(env.picker.lastText, contains('${env.music}/a.mp3'));
    expect(env.picker.lastText, contains('${env.music}/c.mp3'));
    expect(env.picker.lastText, isNot(contains('b.mp3')));
  });

  test('a thrown write error discards the target and propagates', () async {
    final a = await addTrack(env.db, env.source, locator: 'a.mp3');
    final uid = await playlist([a]);
    final t = target();
    env.picker.writeThrows = StateError('disk');
    await expectLater(
      service().exportPlaylist(uid, t, relative: false),
      throwsStateError,
    );
    expect(env.picker.discarded, [t]);
  });

  test('a tombstoned source still exports through its mount', () async {
    final a = await addTrack(env.db, env.source, locator: 'a.mp3');
    final uid = await playlist([a]);
    await env.db.customStatement('UPDATE sources SET deleted_at = 5');
    final res = ok(
      await service().exportPlaylist(uid, target(), relative: false),
    );
    expect(res.written, 1);
  });

  test(
    'a gone playlist, an unknown folder and a write error are typed',
    () async {
      final a = await addTrack(env.db, env.source, locator: 'a.mp3');
      final uid = await playlist([a]);
      final t = target();
      final gone = await service().exportPlaylist('nope', t, relative: false);
      expect((gone as Err).error, M3uExportError.playlistGone);

      const unknown = SaveTarget(name: 'o.m3u', handle: 'content://x');
      final folder = await service().exportPlaylist(
        uid,
        unknown,
        relative: true,
      );
      expect((folder as Err).error, M3uExportError.folderUnknown);
      // An absolute export does not need the folder.
      expect(
        await service().exportPlaylist(uid, unknown, relative: false),
        isA<Ok<M3uExportResult, M3uExportError>>(),
      );

      env.picker.writeResult = const Err(DocumentError.unwritable);
      final bad = await service().exportPlaylist(uid, t, relative: false);
      expect((bad as Err).error, M3uExportError.writeFailed);
      expect(env.picker.discarded, [t, unknown, t]);
    },
  );

  test('Favorites without a row exports an empty file', () async {
    final res = ok(
      await service().exportPlaylist(
        PlaylistUids.favorites,
        target(),
        relative: false,
      ),
    );
    expect((res.written, res.skipped), (0, 0));
    expect(env.picker.lastText, '#EXTM3U\n');
  });

  for (final relative in [false, true]) {
    test('round trip keeps the track ids (relative: $relative)', () async {
      final ids = [
        for (final n in ['a', 'd/b', 'c']) ...[
          await addTrack(env.db, env.source, locator: '$n.mp3', title: n),
        ],
      ];
      for (final n in ['a', 'd/b', 'c']) {
        env.file('$n.mp3');
      }
      final uid = await playlist([ids[2], ids[0], ids[1], ids[0]]);
      final t = target();
      await service().exportPlaylist(uid, t, relative: relative);
      final doc = PickedDocument(
        name: 'out.m3u',
        handle: t.handle,
        localPath: t.localPath,
      );
      env.picker.put(t.handle, env.picker.lastText!);
      final res = await env.service().importDocument(doc, fallbackName: 'x');
      final done = (res as Ok<M3uImportResult, M3uImportError>).value;
      final back = (await env.repo.loadPlaylist(done.playlistUid))!;
      expect(
        [for (final e in back.entries) e.info.id.value],
        [ids[2], ids[0], ids[1], ids[0]],
      );
    });
  }
}
