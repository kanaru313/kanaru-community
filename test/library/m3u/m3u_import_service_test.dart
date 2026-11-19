import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/library/data/m3u/m3u_import_service.dart';
import 'package:kanaru/src/library/data/m3u/m3u_results.dart';
import 'package:kanaru/src/library/data/m3u/m3u_scan_rules.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_parse.dart';
import 'package:kanaru/src/library/data/playlists/playlist_repository.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_import.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_limits.dart';

import '../../database/support/test_db.dart';
import 'support/m3u_env.dart';

/// Removes [victim] right before the first write, as a user removing a music
/// folder between match and write would; later calls fail with [then].
class _RacingRepo extends PlaylistRepository {
  _RacingRepo(this.conn, this.victim, {this.then}) : super(conn);

  final AppDatabase conn;
  final int victim;
  final Object? then;
  int calls = 0;

  @override
  Future<ImportedPlaylist> createImportedPlaylist({
    required String name,
    required List<ImportedEntry> entries,
  }) async {
    if (calls++ == 0) {
      await conn.customStatement(
        'UPDATE sources SET deleted_at = 1 WHERE id = ?',
        [victim],
      );
    } else if (then != null) {
      throw then!;
    }
    return super.createImportedPlaylist(name: name, entries: entries);
  }
}

void main() {
  late M3uEnv env;
  setUp(() async => env = await M3uEnv.open());

  M3uImportResult ok(Result<M3uImportResult, M3uImportError> r) =>
      (r as Ok<M3uImportResult, M3uImportError>).value;
  M3uImportError err(Result<M3uImportResult, M3uImportError> r) =>
      (r as Err<M3uImportResult, M3uImportError>).error;

  test('all lines matched: clean result, no rescan', () async {
    final a = await addTrack(env.db, env.source, locator: 'a.mp3');
    final b = await addTrack(env.db, env.source, locator: 'd/b.mp3');
    env.file('a.mp3');
    env.file('d/b.mp3');
    final r = ok(
      await env.service().importDocument(
        env.list(
          '${env.music}/a.mp3\n${env.music}/d/b.mp3\n',
          name: 'Road.m3u',
        ),
        fallbackName: 'Imported',
      ),
    );
    expect(r.name, 'Road');
    expect(r.added, 2);
    expect(r.notInLibrary, 0);
    expect(r.clean, isTrue);
    expect(env.scans.calls, 0);
    final d = (await env.repo.loadPlaylist(r.playlistUid))!;
    expect(d.entries.map((e) => e.info.id.value), [a, b]);
  });

  test('mixed lines: counts, problems, placeholder, one rescan', () async {
    await addTrack(
      env.db,
      env.source,
      locator: 'gone.mp3',
      status: TrackStatus.missing,
    );
    env.file('new.mp3');
    final outside = env.file('o.mp3', under: '${env.tmp}/lists');
    final text = [
      '#EXTINF:100,Ann - New',
      '${env.music}/new.mp3',
      '${env.music}/gone.mp3',
      '${env.music}/typo.mp3',
      outside,
      'http://x/y.mp3',
    ].join('\n');
    final r = ok(
      await env.service().importDocument(
        env.list(text),
        fallbackName: 'Imported',
      ),
    );
    expect(r.added, 2);
    expect(r.totalLines, 5);
    expect(r.notInLibrary, 2);
    expect(r.outsideFolders, 1);
    expect(r.clean, isFalse);
    expect(r.problems.map((p) => p.kind), [
      M3uProblemKind.unresolved,
      M3uProblemKind.outsideFolders,
      M3uProblemKind.unresolved,
    ]);
    expect(env.scans.calls, 1);
    final row = await (env.db.select(
      env.db.tracks,
    )..where((t) => t.locator.equals('new.mp3'))).getSingle();
    expect(row.artist, 'Ann');
    expect(row.durationMs, 100000);
    expect(row.status, TrackStatus.missing);
  });

  test('nothing usable writes nothing', () async {
    final before = await env.db.select(env.db.tracks).get();
    final r = await env.service().importDocument(
      env.list('${env.music}/typo.mp3\n'),
      fallbackName: 'x',
    );
    expect(err(r), M3uImportError.nothingFound);
    expect(await env.db.select(env.db.playlists).get(), isEmpty);
    expect(await env.db.select(env.db.tracks).get(), before);
    expect(env.scans.calls, 0);
  });

  test('every line outside the music folders', () async {
    final o = env.file('o.mp3', under: '${env.tmp}/lists');
    final r = await env.service().importDocument(
      env.list('$o\n'),
      fallbackName: 'x',
    );
    expect(err(r), M3uImportError.allOutsideFolders);
    expect(await env.db.select(env.db.playlists).get(), isEmpty);
  });

  test('outside files plus URL and typo lines still say all-outside', () async {
    final o = env.file('o.mp3', under: '${env.tmp}/lists');
    final r = await env.service().importDocument(
      env.list('$o\nhttp://x/y.mp3\n${env.music}/typo.mp3\n'),
      fallbackName: 'x',
    );
    expect(err(r), M3uImportError.allOutsideFolders);
  });

  test(
    'an outside file next to a skipped inside file is nothing found',
    () async {
      final o = env.file('o.mp3', under: '${env.tmp}/lists');
      env.file('.hid/a.mp3');
      final r = await env.service().importDocument(
        env.list('$o\n${env.music}/.hid/a.mp3\n'),
        fallbackName: 'x',
      );
      expect(err(r), M3uImportError.nothingFound);
    },
  );

  test(
    'notInLibrary and songsAdded count distinct songs, repeats once',
    () async {
      await addTrack(
        env.db,
        env.source,
        locator: 'gone.mp3',
        status: TrackStatus.missing,
      );
      env.file('new.mp3');
      env.file('gone.mp3');
      final m = env.music;
      final r = ok(
        await env.service().importDocument(
          env.list('$m/new.mp3\n$m/new.mp3\n$m/gone.mp3\n$m/gone.mp3\n'),
          fallbackName: 'x',
        ),
      );
      expect(r.added, 4);
      expect(r.songsAdded, 2);
      expect(r.notInLibrary, 2);
    },
  );

  test('a parse error propagates and nothing is written', () async {
    env.file('a.mp3');
    final svc = M3uImportService(
      env.db,
      env.repo,
      env.picker,
      realPath,
      env.scans,
      const ShortTrackRule.off(),
      androidStorage: false,
      parseFile: _throwingParse,
    );
    await expectLater(
      svc.importDocument(env.list('${env.music}/a.mp3\n'), fallbackName: 'x'),
      throwsStateError,
    );
    expect(await env.db.select(env.db.playlists).get(), isEmpty);
    expect(env.scans.calls, 0);
  });

  test('read failures are typed', () async {
    final svc = env.service();
    expect(
      err(
        await svc.importDocument(
          env.list('x', name: 'a.txt'),
          fallbackName: 'x',
        ),
      ),
      M3uImportError.notAFile,
    );
    final big = env.list('x' * (m3uMaxBytes + 1), name: 'big.m3u');
    expect(
      err(await svc.importDocument(big, fallbackName: 'x')),
      M3uImportError.tooLarge,
    );
    final doc = env.list('x', name: 'gone.m3u');
    env.picker.files.remove(doc.handle);
    expect(
      err(await svc.importDocument(doc, fallbackName: 'x')),
      M3uImportError.unreadable,
    );
  });

  test('a file with more path lines than the limit is truncated', () async {
    await addTrack(env.db, env.source, locator: 'a.mp3');
    env.file('a.mp3');
    final text =
        '${env.music}/a.mp3\n${'http://h/none.mp3\n' * m3uMaxPathLines}';
    final r = ok(
      await env.service().importDocument(env.list(text), fallbackName: 'x'),
    );
    expect(r.truncated, isTrue);
    expect(r.totalLines, m3uMaxPathLines);
    expect(r.clean, isFalse);
  });

  test('name falls back when the file name has no stem', () async {
    env.file('a.mp3');
    await addTrack(env.db, env.source, locator: 'a.mp3');
    final r = ok(
      await env.service().importDocument(
        env.list('${env.music}/a.mp3', name: '.m3u'),
        fallbackName: 'Imported',
      ),
    );
    expect(r.name, 'Imported');
  });

  test('a source removed before the write is retried once', () async {
    final other = await addSource(env.db, uid: 'src-b', root: '${env.tmp}/b');
    await addMount(env.db, other, root: '${env.tmp}/b');
    final keep = await addTrack(env.db, env.source, locator: 'a.mp3');
    env.file('a.mp3');
    final b = env.file('b.mp3', under: '${env.tmp}/b');
    final repo = _RacingRepo(env.db, other);
    final r = ok(
      await env
          .service(store: repo)
          .importDocument(
            env.list('${env.music}/a.mp3\n$b\n'),
            fallbackName: 'x',
          ),
    );
    expect(repo.calls, 2);
    expect(r.added, 1);
    expect(r.outsideFolders, 1);
    final d = (await env.repo.loadPlaylist(r.playlistUid))!;
    expect(d.entries.single.info.id.value, keep);
  });

  test('a failure after the retry propagates', () async {
    final other = await addSource(env.db, uid: 'src-b', root: '${env.tmp}/b');
    await addMount(env.db, other, root: '${env.tmp}/b');
    await addTrack(env.db, env.source, locator: 'a.mp3');
    env.file('a.mp3');
    final b = env.file('b.mp3', under: '${env.tmp}/b');
    final repo = _RacingRepo(env.db, other, then: ArgumentError('again'));
    await expectLater(
      env
          .service(store: repo)
          .importDocument(
            env.list('${env.music}/a.mp3\n$b\n'),
            fallbackName: 'x',
          ),
      throwsArgumentError,
    );
    expect(await env.db.select(env.db.playlists).get(), isEmpty);
  });

  test('other write errors propagate without retry', () async {
    env.file('a.mp3');
    final store = _FailingStore(env.db, ArgumentError('bad'));
    await expectLater(
      env
          .service(store: store)
          .importDocument(env.list('${env.music}/a.mp3\n'), fallbackName: 'x'),
      throwsArgumentError,
    );
    expect(store.calls, 1);
    final db = _FailingStore(env.db, StateError('db'));
    await expectLater(
      env
          .service(store: db)
          .importDocument(env.list('${env.music}/a.mp3\n'), fallbackName: 'x'),
      throwsStateError,
    );
    expect(env.scans.calls, 0);
  });

  test('a failing rescan never fails the import', () async {
    env.file('a.mp3');
    env.scans.failure = StateError('scan down');
    final r = await env.service().importDocument(
      env.list('${env.music}/a.mp3\n'),
      fallbackName: 'x',
    );
    await Future<void>.delayed(Duration.zero);
    expect(r, isA<Ok<M3uImportResult, M3uImportError>>());
    expect(env.scans.calls, 1);
  });

  test('progress: reading, resolving monotonic, end at total', () async {
    for (var i = 0; i < 70; i++) {
      env.file('t$i.mp3');
    }
    final seen = <(int, int?)>[];
    var returned = false;
    final text = [for (var i = 0; i < 70; i++) '${env.music}/t$i.mp3']
        .join('\n');
    await env.service().importDocument(
      env.list(text),
      fallbackName: 'x',
      onProgress: (p) {
        expect(returned, isFalse);
        expect(p.fileName, 'list.m3u');
        seen.add((p.done, p.total));
      },
    );
    returned = true;
    expect(seen.first, (0, null));
    final resolving = seen.skip(1).toList();
    expect(resolving.every((e) => e.$2 == 70), isTrue);
    expect(
      [for (final e in resolving) e.$1],
      [
        ...[for (final e in resolving) e.$1]..sort(),
      ],
    );
    expect(seen.last, (70, 70));
  });
}

/// Top-level: the parser runs on a worker isolate.
M3uParse _throwingParse(Uint8List _) => throw StateError('bad parse');

class _FailingStore extends PlaylistRepository {
  _FailingStore(super.db, this.error);

  final Object error;
  int calls = 0;

  @override
  Future<ImportedPlaylist> createImportedPlaylist({
    required String name,
    required List<ImportedEntry> entries,
  }) async {
    calls++;
    throw error;
  }
}
