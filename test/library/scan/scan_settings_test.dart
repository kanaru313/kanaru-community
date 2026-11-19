import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/scan/format_groups.dart';
import 'package:kanaru/src/library/domain/scan/scan_rule_values.dart';
import 'package:kanaru/src/library/state/scan/scan_settings.dart';
import 'package:kanaru/src/platform/data/json_settings_store.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('scan_set'));
  tearDown(() => dir.delete(recursive: true));

  Future<ProviderContainer> container([
    Map<String, Object?> seed = const {},
  ]) async {
    final store = await JsonSettingsStore.open(File('${dir.path}/s.json'));
    for (final e in seed.entries) {
      await store.write(e.key, e.value);
    }
    final c = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(store.flush);
    addTearDown(c.dispose);
    return c;
  }

  group('min duration', () {
    final table = <String, (Object?, int)>{
      'absent': (null, 30000),
      'in range': (60000, 60000),
      'snaps to 5 s': (32400, 30000),
      'rounds up to 5 s': (32500, 35000),
      'negative clamps to 0': (-1, 0),
      'huge clamps to 180 s': (9999999, 180000),
      'double throws, default': (1e308, 30000),
      'string throws, default': ('abc', 30000),
      'bool throws, default': (true, 30000),
    };
    table.forEach((name, row) {
      test(name, () async {
        final c = await container({
          if (row.$1 != null) 'library.min_duration_ms': row.$1,
        });
        expect(c.read(minDurationMsProvider), row.$2);
      });
    });

    test('absent key follows the old switch: false is off', () async {
      final c = await container({'library.skip_short_tracks': false});
      expect(c.read(minDurationMsProvider), 0);
    });

    test('absent key follows the old switch: true is 30 s', () async {
      final c = await container({'library.skip_short_tracks': true});
      expect(c.read(minDurationMsProvider), 30000);
    });

    test('the new key wins over the old switch', () async {
      final c = await container({
        'library.skip_short_tracks': false,
        'library.min_duration_ms': 45000,
      });
      expect(c.read(minDurationMsProvider), 45000);
    });

    test('writing keeps the old switch in step and never deletes it', () async {
      final c = await container();
      final store = c.read(settingsStoreProvider);
      await c.read(minDurationMsProvider.notifier).set(0);
      expect(c.read(minDurationMsProvider), 0);
      expect(store.read('library.min_duration_ms'), 0);
      expect(store.read('library.skip_short_tracks'), false);
      await c.read(minDurationMsProvider.notifier).set(61000);
      expect(store.read('library.min_duration_ms'), 60000);
      expect(store.read('library.skip_short_tracks'), true);
      expect(c.read(minDurationMsProvider), 60000);
    });

    test('0 written by the new code survives a reload as off', () async {
      final c = await container();
      await c.read(minDurationMsProvider.notifier).set(0);
      final again = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(
            c.read(settingsStoreProvider),
          ),
        ],
      );
      addTearDown(again.dispose);
      expect(again.read(minDurationMsProvider), 0);
    });
  });

  group('min size', () {
    test('stops are 0, 100 KB..1 MB, 1.5..10 MB', () {
      expect(minSizeStopsBytes.length, 1 + 10 + 18);
      expect(minSizeStopsBytes[1], 100000);
      expect(minSizeStopsBytes[10], 1000000);
      expect(minSizeStopsBytes[11], 1500000);
      expect(minSizeStopsBytes.last, 10000000);
    });

    final table = <String, (Object?, int)>{
      'absent': (null, 0),
      'exact stop': (300000, 300000),
      'nearest stop': (340000, 300000),
      'nearest upper stop': (360000, 400000),
      'between big stops': (1740000, 1500000),
      'above max': (999999999, 10000000),
      'negative': (-5, 0),
      'double throws, default': (1e308, 0),
      'string throws, default': ('1000', 0),
    };
    table.forEach((name, row) {
      test(name, () async {
        final c = await container({
          if (row.$1 != null) 'library.min_size_bytes': row.$1,
        });
        expect(c.read(minSizeBytesProvider), row.$2);
      });
    });
  });

  group('format groups', () {
    final table = <String, (Object?, List<String>)>{
      'absent': (null, allFormatGroupIds),
      'empty list': (<Object?>[], allFormatGroupIds),
      'only unknown ids': (['x', 'y'], allFormatGroupIds),
      'not a list': ('flac', allFormatGroupIds),
      'a number': (3, allFormatGroupIds),
      'subset in list order': (['wav', 'flac'], ['flac', 'wav']),
      'unknown ids dropped': (['flac', 'zzz', 4], ['flac']),
      'duplicates collapse': (['mp3', 'mp3'], ['mp3']),
    };
    table.forEach((name, row) {
      test(name, () async {
        final c = await container({
          if (row.$1 != null) 'library.format_groups': row.$1,
        });
        expect(c.read(formatGroupsProvider), row.$2);
      });
    });
  });

  test('respect_nomedia defaults to off and ignores a non-bool', () async {
    final c = await container({'library.respect_nomedia': 'yes'});
    expect(c.read(respectNomediaProvider), false);
  });

  test('currentScanRulesProvider follows the settings', () async {
    final c = await container({
      'library.min_duration_ms': 90000,
      'library.min_size_bytes': 500000,
      'library.format_groups': ['mp3', 'flac'],
      'library.respect_nomedia': true,
    });
    final r = c.read(currentScanRulesProvider);
    expect(r.minDurationMs, 90000);
    expect(r.minSizeBytes, 500000);
    expect(r.allowedExtensions, {'mp3', 'flac'});
    expect(r.respectNomedia, isTrue);
    await c.read(minDurationMsProvider.notifier).set(0);
    expect(c.read(currentScanRulesProvider).minDurationMs, 0);
  });

  test('an empty format list in the session scans every format', () async {
    final c = await container();
    await c.read(formatGroupsProvider.notifier).set(<String>[]);
    expect(
      c.read(currentScanRulesProvider).allowedExtensions,
      allGroupExtensions,
    );
  });

  test('default rules match the old behaviour', () async {
    final c = await container();
    final r = c.read(currentScanRulesProvider);
    expect(r.minDurationMs, 30000);
    expect(r.minSizeBytes, 0);
    expect(r.allowedExtensions, allGroupExtensions);
    expect(r.respectNomedia, isFalse);
  });
}
