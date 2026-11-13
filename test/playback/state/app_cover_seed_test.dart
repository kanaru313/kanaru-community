import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/cover_colors.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/state/app_cover_seed.dart';
import 'package:kanaru/src/playback/state/playing_cover_colors.dart';

import '../../support/memory_settings_store.dart';

/// Counts writes on top of the in-memory store.
class _CountingStore extends MemorySettingsStore {
  final writes = <(String, Object?)>[];

  @override
  Future<void> write(String key, Object? value) {
    writes.add((key, value));
    return super.write(key, value);
  }
}

const _red = CoverColors(seed: 0xFFC62828, palette: [0xFFC62828]);
const _blue = CoverColors(seed: 0xFF1E88E5, palette: [0xFF1E88E5]);

void main() {
  late _CountingStore store;
  late ProviderContainer c;

  setUp(() {
    store = _CountingStore();
  });

  /// Runs [syncAppCoverSeed] through a real [WidgetRef].
  Future<void> sync(WidgetTester tester, PlayingCoverColors v) async {
    late WidgetRef ref;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: Consumer(
          builder: (_, r, _) {
            ref = r;
            return const SizedBox();
          },
        ),
      ),
    );
    syncAppCoverSeed(ref, v);
    await tester.pump();
  }

  void make([Map<String, Object?> initial = const {}]) {
    for (final e in initial.entries) {
      store.write(e.key, e.value);
    }
    store.writes.clear();
    c = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
  }

  test('the stored seed is there at the first read', () {
    make({'app.coverSeed': 0xFF112233});
    expect(c.read(appCoverSeedProvider), 0xFF112233);
  });

  test('no stored seed, or an unreadable one, is null', () {
    make();
    expect(c.read(appCoverSeedProvider), isNull);
    c.dispose();
    make({'app.coverSeed': 'red'});
    expect(c.read(appCoverSeedProvider), isNull);
  });

  testWidgets('colours write their seed, once', (tester) async {
    make();
    await sync(tester, const PlayingCoverColorsFound(_red));
    expect(c.read(appCoverSeedProvider), _red.seed);
    expect(store.writes, [('app.coverSeed', _red.seed)]);
    await sync(tester, const PlayingCoverColorsFound(_red));
    expect(store.writes, hasLength(1));
    await sync(tester, const PlayingCoverColorsFound(_blue));
    expect(c.read(appCoverSeedProvider), _blue.seed);
    expect(store.writes, hasLength(2));
  });

  testWidgets('pending writes nothing and keeps the seed', (tester) async {
    make({'app.coverSeed': _red.seed});
    await sync(tester, const PlayingCoverColorsPending());
    expect(c.read(appCoverSeedProvider), _red.seed);
    expect(store.writes, isEmpty);
  });

  testWidgets('none clears a stale seed, and writes nothing when empty', (
    tester,
  ) async {
    make({'app.coverSeed': _red.seed});
    await sync(tester, const PlayingCoverColorsNone());
    expect(c.read(appCoverSeedProvider), isNull);
    expect(store.read('app.coverSeed'), isNull);
    store.writes.clear();
    await sync(tester, const PlayingCoverColorsNone());
    expect(store.writes, isEmpty);
  });
}
