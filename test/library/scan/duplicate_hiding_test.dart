import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/scan/scan_pipeline.dart';
import 'package:kanaru/src/library/data/scan/track_row_builder.dart'
    show stemOf;
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/library/domain/scan/scan_rules.dart';
import 'package:kanaru/src/library/state/scan/duplicate_hiding.dart';
import 'package:kanaru/src/library/state/scan/scan_settings.dart';
import 'package:kanaru/src/platform/data/json_settings_store.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/storage/data/local_folder_source.dart';

import '../../database/support/test_db.dart';
import 'support/cover_fixtures.dart';
import 'support/pipeline_fixtures.dart';
import 'support/scan_fixtures.dart';

void main() {
  late AppDatabase db;
  late Directory dir;

  setUp(() async {
    db = openTestDb();
    addTearDown(db.close);
    dir = await Directory.systemTemp.createTemp('dup_hide');
    addTearDown(() => dir.delete(recursive: true));
  });

  /// Same key the scanner writes with each row.
  Future<int> addKeyed(int source, String locator) async {
    final id = await addTrack(db, source, locator: locator);
    await db.customStatement('UPDATE tracks SET name_key = ? WHERE id = ?', [
      groupKey(stemOf(locator)),
      id,
    ]);
    return id;
  }

  Future<int> hiddenCount() async =>
      (await db
              .customSelect(
                'SELECT COUNT(*) AS n FROM tracks WHERE dup_hidden = 1',
              )
              .getSingle())
          .read<int>('n');

  group('setting listener', () {
    late ProviderContainer container;

    setUp(() async {
      final store = await JsonSettingsStore.open(File('${dir.path}/s.json'));
      container = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(store.flush);
      addTearDown(container.dispose);
      final hiding = DuplicateHiding(
        db: db,
        enabled: () => container.read(dedupByFileNameProvider),
      );
      final registered = Provider<void>(
        (ref) => listenDuplicateHiding(ref, hiding),
      );
      container.read(registered);
      final a = await addSource(db, name: 'a');
      final b = await addSource(db, name: 'b');
      await addMount(db, a, root: '/a');
      await addMount(db, b, root: '/b');
      await addKeyed(a, 'Song.flac');
      await addKeyed(b, 'Song.mp3');
    });

    test('is off by default and hides nothing', () async {
      expect(container.read(dedupByFileNameProvider), isFalse);
      expect(await hiddenCount(), 0);
    });

    test('switching on hides the copy at once, off restores it', () async {
      await container.read(dedupByFileNameProvider.notifier).set(true);
      await pumpEventQueue();
      expect(await hiddenCount(), 1);
      await container.read(dedupByFileNameProvider.notifier).set(false);
      await pumpEventQueue();
      expect(await hiddenCount(), 0);
    });
  });

  group('scan pass', () {
    late FakeTagReader reader;

    setUp(() {
      reader = FakeTagReader();
    });

    Future<ScanOutcome> run({
      required bool Function() enabled,
      required MapCatalog catalog,
    }) async {
      final cache = makeCacheDir();
      writeLayoutMarker(cache);
      addTearDown(() => cache.deleteSync(recursive: true));
      final hiding = DuplicateHiding(db: db, enabled: enabled);
      return runScanPass(
        ScanPipelineDeps(
          db: db,
          source: LocalFolderSource(catalog, readMounts: () => {'/'}),
          permissions: FixedPermissions(grantedBoth),
          reader: reader,
          maker: FakeCoverMaker(),
          cacheDir: cache.path,
          rules: ScanRules(minDurationMs: 0),
          now: () => scanNow,
          applyDuplicateHiding: hiding.apply,
        ),
        ScanSession(),
        StatusLog().hooks(),
      );
    }

    Future<MapCatalog> twoFolders() async {
      await addScanFolder(db, uid: 'src-1', root: '/m1');
      await addScanFolder(db, uid: 'src-2', root: '/m2');
      return MapCatalog({
        '/m1': listingOf('/m1', ['Song.flac']),
        '/m2': listingOf('/m2', ['Song.mp3']),
      });
    }

    test('the end of a pass hides copies and counts reflect it', () async {
      final catalog = await twoFolders();
      final out = await run(enabled: () => true, catalog: catalog);
      expect(await hiddenCount(), 1);
      expect(out.counts?.tracks, 1);
    });

    test('a pass with the setting off hides nothing', () async {
      final catalog = await twoFolders();
      final out = await run(enabled: () => false, catalog: catalog);
      expect(await hiddenCount(), 0);
      expect(out.counts?.tracks, 2);
    });

    test('switched off during a pass: the pass end applies "off"', () async {
      final catalog = await twoFolders();
      var on = true;
      reader.onRead = (_) async {
        on = false;
      };
      await run(enabled: () => on, catalog: catalog);
      expect(await hiddenCount(), 0);
    });

    test('switched on during a pass: the pass end applies "on"', () async {
      final catalog = await twoFolders();
      var on = false;
      reader.onRead = (_) async {
        on = true;
      };
      await run(enabled: () => on, catalog: catalog);
      expect(await hiddenCount(), 1);
    });
  });

  test('runs queue up and the last one wins with the newest value', () async {
    final a = await addSource(db, name: 'a');
    final b = await addSource(db, name: 'b');
    await addMount(db, a, root: '/a');
    await addMount(db, b, root: '/b');
    await addKeyed(a, 'Song.flac');
    await addKeyed(b, 'Song.mp3');
    var on = true;
    final hiding = DuplicateHiding(db: db, enabled: () => on);
    final first = hiding.apply();
    on = false;
    final second = hiding.apply();
    await Future.wait([first, second]);
    expect(await hiddenCount(), 0);
  });

  test('a failed run does not block the next one', () async {
    var fail = true;
    final hiding = DuplicateHiding(
      db: db,
      enabled: () {
        if (fail) throw StateError('boom');
        return true;
      },
    );
    await expectLater(hiding.apply(), throwsStateError);
    fail = false;
    await hiding.apply();
  });
}
