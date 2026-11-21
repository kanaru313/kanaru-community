import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/local_lyrics_pick.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_display_prefs.dart';
import 'package:kanaru/src/lyrics/state/lyrics_settings.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';

import '../../support/memory_settings_store.dart';

void main() {
  late MemorySettingsStore store;
  late ProviderContainer c;
  setUp(() {
    store = MemorySettingsStore();
    c = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
  });
  tearDown(() => c.dispose());

  test('defaults', () {
    expect(c.read(lyricsFontScaleProvider), LyricsFontScale.medium);
    expect(c.read(lyricsAlignProvider), LyricsAlign.start);
    expect(c.read(lyricsAutoReturnProvider), LyricsAutoReturn.off);
    expect(c.read(lyricsDimProvider), LyricsDim.light);
    expect(c.read(lyricsLocalFirstProvider), LocalFirst.tag);
  });

  test('keys', () {
    expect(lyricsFontScaleSetting.key, 'lyrics.font_scale');
    expect(lyricsAlignSetting.key, 'lyrics.align');
    expect(lyricsAutoReturnSetting.key, 'lyrics.auto_return');
    expect(lyricsDimSetting.key, 'lyrics.dim');
    expect(lyricsLocalFirstSetting.key, 'lyrics.local_first');
  });

  test('unknown or mistyped stored values fall back to the default', () async {
    await store.write('lyrics.font_scale', 'huge');
    await store.write('lyrics.align', 3);
    await store.write('lyrics.auto_return', 's99');
    await store.write('lyrics.dim', true);
    await store.write('lyrics.local_first', 'both');
    expect(c.read(lyricsFontScaleProvider), LyricsFontScale.medium);
    expect(c.read(lyricsAlignProvider), LyricsAlign.start);
    expect(c.read(lyricsAutoReturnProvider), LyricsAutoReturn.off);
    expect(c.read(lyricsDimProvider), LyricsDim.light);
    expect(c.read(lyricsLocalFirstProvider), LocalFirst.tag);
  });

  test('values round trip through the store as enum names', () async {
    await c.read(lyricsFontScaleProvider.notifier).set(LyricsFontScale.large);
    await c.read(lyricsAutoReturnProvider.notifier).set(LyricsAutoReturn.s5);
    await c.read(lyricsDimProvider.notifier).set(LyricsDim.strong);
    await c.read(lyricsLocalFirstProvider.notifier).set(LocalFirst.lrc);
    await c.read(lyricsAlignProvider.notifier).set(LyricsAlign.center);
    expect(store.read('lyrics.font_scale'), 'large');
    expect(store.read('lyrics.auto_return'), 's5');
    expect(store.read('lyrics.dim'), 'strong');
    expect(store.read('lyrics.local_first'), 'lrc');
    expect(store.read('lyrics.align'), 'center');
    final again = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(again.dispose);
    expect(again.read(lyricsFontScaleProvider), LyricsFontScale.large);
    expect(again.read(lyricsDimProvider).alpha, 0.20);
    expect(
      again.read(lyricsAutoReturnProvider).delay,
      const Duration(seconds: 5),
    );
  });

  test('enum members carry the documented values', () {
    expect(LyricsFontScale.values.map((e) => e.factor), [0.85, 1.0, 1.2]);
    expect(LyricsDim.values.map((e) => e.alpha), [0.36, 0.20, 1.0]);
    expect(LyricsAutoReturn.values.map((e) => e.delay), [
      null,
      const Duration(seconds: 3),
      const Duration(seconds: 5),
      const Duration(seconds: 10),
    ]);
  });
}
