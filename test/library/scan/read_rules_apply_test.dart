import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/scan/scan_pipeline.dart';
import 'package:kanaru/src/library/domain/scan/read_rules.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';
import 'package:kanaru/src/library/state/scan/read_rules_settings.dart';

import '../../database/support/test_db.dart';
import 'support/cover_fixtures.dart';
import 'support/pipeline_fixtures.dart';
import 'support/scan_fixtures.dart';

/// How a changed read rule reaches rows already in the library: a folder last
/// read with other rules is read in full, and its entry is written only when
/// its tag pass finished.
void main() {
  late AppDatabase db;
  late Directory cache;
  late FakeTagReader reader;
  late FakeCoverMaker maker;
  late ScanSession session;
  late StatusLog log;
  // What the controller would keep in `library.read_rules_applied`.
  late Map<String, String> applied;

  final changed = LibraryReadRules(
    separators: [...defaultArtistSeparators, ','],
  );

  setUp(() {
    db = openTestDb();
    addTearDown(db.close);
    cache = makeCacheDir();
    writeLayoutMarker(cache);
    addTearDown(() => cache.deleteSync(recursive: true));
    reader = FakeTagReader();
    maker = FakeCoverMaker();
    session = ScanSession();
    log = StatusLog();
    applied = {};
  });

  Future<ScanOutcome> run(
    MapCatalog catalog,
    LibraryReadRules rules, {
    bool Function()? stop,
  }) => runScanPass(
    pipelineDeps(
      db,
      catalog: catalog,
      reader: reader,
      maker: maker,
      cache: cache,
      readRules: rules,
      // Read once when the pass starts, like the controller does.
      readRulesApplied: Map.of(applied),
      onReadRulesApplied: (uid, fp) async => applied[uid] = fp,
    ),
    session,
    log.hooks(stop: stop),
  );

  MapCatalog twoFolders() => MapCatalog({
    '/a': listingOf('/a', ['x.mp3']),
    '/b': listingOf('/b', ['y.mp3']),
  });

  test('default rules and no entry: no full pass after the first', () async {
    await addScanFolder(db, uid: 'src-a', root: '/a');
    await addScanFolder(db, uid: 'src-b', root: '/b');
    final catalog = twoFolders();
    await run(catalog, LibraryReadRules.defaults);
    reader.calls.clear();
    await run(catalog, LibraryReadRules.defaults);
    expect(reader.readCount, 0);
  });

  test('a change reads each folder in full once and records it', () async {
    await addScanFolder(db, uid: 'src-a', root: '/a');
    await addScanFolder(db, uid: 'src-b', root: '/b');
    final catalog = twoFolders();
    await run(catalog, LibraryReadRules.defaults);
    reader.calls.clear();

    await run(catalog, changed);
    expect(reader.readCount, 2);
    expect(applied, {
      'src-a': changed.fingerprint,
      'src-b': changed.fingerprint,
    });

    reader.calls.clear();
    await run(catalog, changed);
    expect(reader.readCount, 0);
  });

  test('an unreachable folder keeps its entry and is read when back', () async {
    await addScanFolder(db, uid: 'src-a', root: '/a');
    await addScanFolder(db, uid: 'src-b', root: '/b');
    await run(twoFolders(), LibraryReadRules.defaults);
    reader.calls.clear();

    await run(
      MapCatalog({
        '/a': listingOf('/a', ['x.mp3']),
      }),
      changed,
    );
    expect(applied, {
      'src-a': changed.fingerprint,
      // b was not reachable: its entry is still the old one.
      'src-b': LibraryReadRules.defaults.fingerprint,
    });

    reader.calls.clear();
    await run(twoFolders(), changed);
    // Only b, whose entry was still the old one, is read again.
    expect(reader.readCount, 1);
    expect(reader.calls.single.single, endsWith('/b/y.mp3'));
    expect(applied['src-b'], changed.fingerprint);
  });

  test('a stopped pass records nothing and the next pass re-reads', () async {
    await addScanFolder(db, uid: 'src-a', root: '/a');
    await addScanFolder(db, uid: 'src-b', root: '/b');
    final catalog = twoFolders();
    await run(catalog, LibraryReadRules.defaults);

    final out = await run(catalog, changed, stop: () => true);
    expect(out.stopped, isTrue);
    expect(applied.values.toSet(), {LibraryReadRules.defaults.fingerprint});

    reader.calls.clear();
    await run(catalog, changed);
    expect(reader.readCount, 2);
  });

  group('a folder with rows kept unread records nothing', () {
    // One session, one folder: `changed` is run against a folder that is
    // not healthy, then against the healthy folder.
    Future<void> expectFullAndRecordedWhenHealthy(
      MapCatalog healthy,
      int rows,
    ) async {
      expect(applied['src-a'], LibraryReadRules.defaults.fingerprint);
      reader.calls.clear();
      await run(healthy, changed);
      expect(reader.readCount, rows);
      expect(applied['src-a'], changed.fingerprint);
      reader.calls.clear();
      await run(healthy, changed);
      expect(reader.readCount, 0);
    }

    test('an empty listing over rows (suspect root)', () async {
      await addScanFolder(db, uid: 'src-a', root: '/a');
      final healthy = MapCatalog({
        '/a': listingOf('/a', ['x.mp3', 'y.mp3']),
      });
      await run(healthy, LibraryReadRules.defaults);

      await run(MapCatalog({'/a': const AudioListing()}), changed);
      await expectFullAndRecordedWhenHealthy(healthy, 2);
    });

    test('a subfolder that could not be listed', () async {
      await addScanFolder(db, uid: 'src-a', root: '/a');
      final healthy = MapCatalog({
        '/a': listingOf('/a', ['x.mp3', 'sub/z.mp3']),
      });
      await run(healthy, LibraryReadRules.defaults);

      await run(
        MapCatalog({
          '/a': AudioListing(
            audio: listingOf('/a', ['x.mp3']).audio,
            unreadableDirs: const ['/a/sub'],
          ),
        }),
        changed,
      );
      await expectFullAndRecordedWhenHealthy(healthy, 2);
    });

    test('a file with a read error', () async {
      await addScanFolder(db, uid: 'src-a', root: '/a');
      final healthy = MapCatalog({
        '/a': listingOf('/a', ['x.mp3', 'y.mp3']),
      });
      await run(healthy, LibraryReadRules.defaults);

      reader.byName['y.mp3'] = failed('io', transient: true);
      await run(healthy, changed);
      reader.byName.clear();
      await expectFullAndRecordedWhenHealthy(healthy, 2);
    });
  });

  test('a rules change made while a pass runs is read by the next', () async {
    await addScanFolder(db, uid: 'src-a', root: '/a');
    final catalog = MapCatalog({
      '/a': listingOf('/a', ['x.mp3']),
    });
    await run(catalog, LibraryReadRules.defaults);
    final started = LibraryReadRules(
      separators: [...defaultArtistSeparators, '&'],
    );
    var current = started;
    // The user changes the setting while the pass reads its files.
    reader.onRead = (_) async => current = changed;
    await run(catalog, started);
    reader.onRead = null;
    expect(applied['src-a'], started.fingerprint);
    expect(current.fingerprint, isNot(started.fingerprint));

    // The next pass takes the current rules and reads the folder in full.
    reader.calls.clear();
    await run(catalog, current);
    expect(reader.readCount, 1);
    expect(applied['src-a'], changed.fingerprint);
  });

  test('the fingerprint recorded is the one the pass started with', () async {
    await addScanFolder(db, uid: 'src-a', root: '/a');
    final catalog = MapCatalog({
      '/a': listingOf('/a', ['x.mp3']),
    });
    await run(catalog, LibraryReadRules.defaults);
    // The settings change while the pass runs: the pass keeps its own rules.
    await run(catalog, changed);
    expect(applied['src-a'], changed.fingerprint);
    // A pass started with the older rules would not hide the change.
    await run(catalog, LibraryReadRules.defaults);
    expect(applied['src-a'], LibraryReadRules.defaults.fingerprint);
    reader.calls.clear();
    await run(catalog, changed);
    expect(reader.readCount, 1);
  });

  test('a failed write of the entry does not fail the pass', () async {
    await addScanFolder(db, uid: 'src-a', root: '/a');
    final out = await runScanPass(
      pipelineDeps(
        db,
        catalog: MapCatalog({
          '/a': listingOf('/a', ['x.mp3']),
        }),
        reader: reader,
        maker: maker,
        cache: cache,
        readRules: changed,
        onReadRulesApplied: (_, _) async => throw StateError('disk'),
      ),
      session,
      log.hooks(),
    );
    expect(out.failureKind, isNull);
    expect(out.counts?.tracks, 1);
  });

  test('a damaged applied map counts as the default rules', () {
    expect(decodeReadRulesApplied({'a': 'x', 'b': 3}), {'a': 'x'});
    expect(() => decodeReadRulesApplied('nope'), throwsFormatException);
  });
}
