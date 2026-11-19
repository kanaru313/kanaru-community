import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/library/data/m3u/m3u_results.dart';
import 'package:kanaru/src/library/data/m3u/m3u_scan_rules.dart';
import 'package:kanaru/src/platform/data/local_files/audio_tree_walk.dart';
import 'package:kanaru/src/library/data/scan/scan_pipeline.dart';

import '../scan/support/cover_fixtures.dart';
import '../scan/support/pipeline_fixtures.dart';
import '../scan/support/scan_fixtures.dart';
import 'support/m3u_env.dart';

void main() {
  late M3uEnv env;
  late Directory cache;
  setUp(() async {
    env = await M3uEnv.open();
    cache = makeCacheDir();
    writeLayoutMarker(cache);
    addTearDown(() => cache.deleteSync(recursive: true));
  });

  Future<void> scan({bool realWalk = false}) async {
    final out = await runScanPass(
      pipelineDeps(
        env.db,
        catalog: MapCatalog({
          env.music: listingOf(env.music, ['a.mp3']),
        }),
        reader: FakeTagReader(),
        maker: FakeCoverMaker(),
        cache: cache,
      ),
      ScanSession(),
      StatusLog().hooks(),
    );
    expect(out.failureKind, isNull);
  }

  Future<void> rejoins(String line, {bool realWalk = false}) async {
    env.file('a.mp3');
    final r = await env.service().importDocument(
      env.list('$line\n'),
      fallbackName: 'x',
    );
    final done = (r as Ok<M3uImportResult, M3uImportError>).value;
    expect(done.notInLibrary, 1);
    final placeholder = await trackAt(env.db, env.source, 'a.mp3');
    expect(placeholder.status, TrackStatus.missing);

    await scan(realWalk: realWalk);

    final after = await trackAt(env.db, env.source, 'a.mp3');
    expect(after.id, placeholder.id);
    expect(after.status, TrackStatus.present);
    final d = (await env.repo.loadPlaylist(done.playlistUid))!;
    expect(d.entries.single.info.id.value, placeholder.id);
    expect(d.unavailableCount, 0);
  }

  test('a file added after the last scan joins the entry on scan', () async {
    await rejoins('${env.music}/a.mp3');
  });

  test('the same through the real Linux tree walk', () async {
    await rejoins('${env.music}/a.mp3', realWalk: true);
  });

  test('the import filter lists what the real walk lists', () async {
    const names = [
      '.archive/a.mp3',
      '@eaDir/x.flac',
      '.intro.mp3',
      'ok/d.mp3',
      'ok/.hidden.mp3',
      r'$RECYCLE.BIN/r.mp3',
      'top.mp3',
      'ok/deep/.git/z.mp3',
    ];
    for (final n in names) {
      env.file(n);
    }
    final walked = {
      for (final f in walkAudioTree(WalkRequest(root: env.music)).audio)
        f.path.substring(env.music.length + 1),
    };
    final accepted = {
      for (final n in names)
        if (scannerWouldList(
          root: env.music,
          locator: n,
          durationMs: null,
          short: const ShortTrackRule.off(),
        ))
          n,
    };
    expect(accepted, walked);
    expect(walked, {'ok/d.mp3', 'top.mp3'});
  });

  test('the same through a symlinked folder', () async {
    Link('${env.tmp}/link').createSync(env.music);
    await rejoins('${env.tmp}/link/a.mp3');
  });
}
