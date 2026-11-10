import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/scan/scan_settings.dart';
import 'package:kanaru/src/library/state/scan/setup_completion.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';

import '../../support/memory_settings_store.dart';

class _Store extends MemorySettingsStore {
  int flushes = 0;
  final List<String> log = [];

  @override
  Future<void> write(String key, Object? value) {
    log.add('write $key');
    return super.write(key, value);
  }

  @override
  Future<void> flush() async {
    log.add('flush');
    flushes++;
  }
}

class _Scan implements LibraryScanCommands {
  _Scan(this.store);

  final _Store store;
  final List<bool?> setupDoneAtRequest = [];
  @override
  Future<void> rescan({bool full = false}) async {
    setupDoneAtRequest.add(store.read('library.setup_done') as bool?);
    store.log.add('rescan');
  }
}

void main() {
  late _Store store;
  late ProviderContainer container;

  setUp(() {
    store = _Store();
    container = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
  });

  test(
    'marks setup done, asks for one scan that sees it, then flushes',
    () async {
      final scan = _Scan(store);
      expect(container.read(setupDoneProvider), isFalse);
      await completeSetup(
        setupDone: container.read(setupDoneProvider.notifier),
        scan: scan,
        store: store,
      );
      expect(container.read(setupDoneProvider), isTrue);
      expect(store.read('library.setup_done'), isTrue);
      expect(scan.setupDoneAtRequest, [true]);
      expect(store.log, ['write library.setup_done', 'rescan', 'flush']);
    },
  );

  test('a store that cannot write fails the call, not silently', () async {
    final failing = _FailingStore();
    final c = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(failing)],
    );
    addTearDown(c.dispose);
    await expectLater(
      completeSetup(
        setupDone: c.read(setupDoneProvider.notifier),
        scan: _Scan(store),
        store: failing,
      ),
      throwsA(isA<StateError>()),
    );
  });
}

class _FailingStore extends _Store {
  @override
  Future<void> write(String key, Object? value) async =>
      throw StateError('disk full');
}
