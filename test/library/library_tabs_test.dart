import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/library_tabs.dart';
import 'package:kanaru/src/library/state/library_tabs_providers.dart';
import 'package:kanaru/src/platform/data/json_settings_store.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';

void main() {
  late Directory dir;
  late JsonSettingsStore store;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('library_tabs_test');
    store = await JsonSettingsStore.open(File('${dir.path}/settings.json'));
  });
  tearDown(() async {
    await store.flush();
    await dir.delete(recursive: true);
  });

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('defaults: every tab on in declaration order', () {
    final c = container();
    expect(c.read(libraryTabsProvider).visible, LibraryTab.values);
  });

  test('reorder moves a tab to the target index and persists', () async {
    final c = container();
    await c.read(libraryTabsProvider.notifier).reorder(5, 0);
    expect(c.read(libraryTabsProvider).order.first, LibraryTab.folders);
    final again = container();
    expect(again.read(libraryTabsProvider).order.first, LibraryTab.folders);
    await expectLater(
      c.read(libraryTabsProvider.notifier).reorder(0, 6),
      throwsRangeError,
    );
  });

  test(
    'disabling hides the tab; the last enabled tab cannot be disabled',
    () async {
      final c = container();
      final n = c.read(libraryTabsProvider.notifier);
      for (final t in LibraryTab.values.skip(1)) {
        await n.setEnabled(t, false);
      }
      expect(c.read(libraryTabsProvider).visible, [LibraryTab.songs]);
      await expectLater(
        n.setEnabled(LibraryTab.songs, false),
        throwsStateError,
      );
      expect(c.read(libraryTabsProvider).visible, [LibraryTab.songs]);
      await n.setEnabled(LibraryTab.albums, true);
      expect(c.read(libraryTabsProvider).visible, [
        LibraryTab.songs,
        LibraryTab.albums,
      ]);
    },
  );

  test(
    'decode drops unknown names and appends missing tabs in default order',
    () {
      final config = LibraryTabsConfig.fromJson({
        'order': ['folders', 'podcasts', 'albums', 'folders'],
        'enabled': ['albums', 'nope'],
      });
      expect(config.order, [
        LibraryTab.folders,
        LibraryTab.albums,
        LibraryTab.songs,
        LibraryTab.artists,
        LibraryTab.genres,
        LibraryTab.languages,
      ]);
      expect(config.visible, [LibraryTab.albums]);
    },
  );

  test('persists disabled names; a tab added later starts enabled', () async {
    final c = container();
    await c
        .read(libraryTabsProvider.notifier)
        .setEnabled(LibraryTab.genres, false);
    expect(store.read('library.tabs'), containsPair('disabled', ['genres']));
    final future = LibraryTabsConfig.fromJson({
      'order': ['songs', 'albums', 'artists', 'genres', 'languages'],
      'disabled': ['genres'],
    });
    expect(future.visible, contains(LibraryTab.folders));
    expect(future.visible, isNot(contains(LibraryTab.genres)));
  });

  test('decode: empty or absent enabled enables all; non-map is rejected', () {
    expect(
      LibraryTabsConfig.fromJson({
        'order': [],
        'enabled': ['x'],
      }).visible,
      LibraryTab.values,
    );
    expect(LibraryTabsConfig.fromJson(const {}).visible, LibraryTab.values);
    expect(() => LibraryTabsConfig.fromJson('x'), throwsFormatException);
  });

  test('a bad stored value falls back to the defaults', () async {
    await store.write('library.tabs', 42);
    expect(container().read(libraryTabsProvider), LibraryTabsConfig.defaults);
  });

  test('constructor rejects a partial order and an empty enabled set', () {
    expect(
      () => LibraryTabsConfig([LibraryTab.songs], {LibraryTab.songs}),
      throwsArgumentError,
    );
    expect(() => LibraryTabsConfig(LibraryTab.values, {}), throwsArgumentError);
  });
}
