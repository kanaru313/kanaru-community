import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/platform/state/device_id_provider.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/data/play_log_writer.dart';
import 'package:kanaru/src/playback/state/listen_recorder.dart';
import 'package:kanaru/src/playback/state/listen_recorder_provider.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';

import '../../database/support/test_db.dart';
import '../../support/memory_settings_store.dart';

/// Records what the controller does to the recorder it was given.
class _Spy extends ListenRecorder {
  _Spy(PlayLogWriter writer) : super(writer: writer, deviceId: () => 'dev');

  final calls = <String>[];

  @override
  void observe(ListenObservation? o) {
    calls.add(o == null ? 'observe(null)' : 'observe');
    super.observe(o);
  }

  @override
  Future<void> flush() {
    calls.add('flush');
    return super.flush();
  }

  @override
  Future<void> close() {
    calls.add('close');
    return super.close();
  }
}

void main() {
  late AppDatabase db;
  late ProviderContainer c;

  ProviderContainer make([List<Override> extra = const []]) =>
      ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
          deviceIdProvider.overrideWithValue('dev'),
          ...extra,
        ],
      );

  setUp(() => db = openTestDb());
  tearDown(() async {
    c.dispose();
    await pumpEventQueue();
    await db.close();
  });

  test('one recorder for the container', () {
    c = make();
    expect(
      c.read(listenRecorderProvider),
      same(c.read(listenRecorderProvider)),
    );
  });

  test('the container dispose closes it', () async {
    c = make();
    final rec = c.read(listenRecorderProvider);
    expect(await rec.clearHistory(), 0, reason: 'open');
    c.dispose();
    await pumpEventQueue();
    expect(await rec.clearHistory(), isNull, reason: 'closed');
    c = make();
  });

  test('the player uses it, and its dispose flushes without closing', () async {
    final spy = _Spy(PlayLogWriter(db));
    c = make([listenRecorderProvider.overrideWithValue(spy)]);
    c.read(playerControllerProvider);
    c.invalidate(playerControllerProvider);
    c.read(playerControllerProvider);
    await pumpEventQueue();
    final flush = spy.calls.indexOf('flush');
    expect(flush, greaterThan(0));
    expect(spy.calls[flush - 1], 'observe(null)');
    expect(spy.calls, isNot(contains('close')));
    expect(await spy.clearHistory(), 0, reason: 'still open');
  });
}
