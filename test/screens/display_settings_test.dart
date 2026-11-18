import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/screens/settings/state/display_settings.dart';

import '../support/memory_settings_store.dart';

void main() {
  group('text scale decode', () {
    final snaps = <Object, int>{
      79: 80,
      80: 80,
      81: 80,
      95: 90,
      150: 150,
      151: 150,
      10000: 150,
      -5: 80,
      125.0: 125,
    };
    snaps.forEach((raw, expected) {
      test('$raw -> $expected', () {
        expect(textScaleSetting.decode(raw), expected);
      });
    });

    final bad = <String, Object?>{
      'string': 'x',
      'null': null,
      'list': [100],
      'huge double': 1e308,
      'negative infinity': double.negativeInfinity,
      'nan': double.nan,
      '2^53 as double': 9007199254740992.0,
      'fraction': 100.5,
    };
    bad.forEach((name, raw) {
      test('$name throws', () {
        expect(() => textScaleSetting.decode(raw), throwsFormatException);
      });
    });

    test('2^53 as int still snaps to the top step', () {
      expect(textScaleSetting.decode(9007199254740992), 150);
    });
  });

  group('bool decode', () {
    for (final setting in [pureBlackSetting, motionSetting]) {
      test('${setting.key} accepts bool only', () {
        expect(setting.decode(true), isTrue);
        expect(setting.decode(false), isFalse);
        expect(() => setting.decode(1), throwsFormatException);
        expect(() => setting.decode('true'), throwsFormatException);
        expect(() => setting.decode(<Object>[]), throwsFormatException);
      });
    }
  });

  test('providers: defaults, stored values, bad values fall back', () async {
    final store = MemorySettingsStore();
    final c = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    expect(c.read(pureBlackProvider), isFalse);
    expect(c.read(appMotionProvider), isTrue);
    expect(c.read(appTextScaleProvider), 100);

    await c.read(appTextScaleProvider.notifier).set(125);
    expect(store.read('app.text_scale'), 125);
    await store.write('app.text_scale', 'big');
    expect(c.read(appTextScaleProvider), 100);
    await store.write('app.motion', 'off');
    expect(c.read(appMotionProvider), isTrue);
    await store.write('app.pure_black', true);
    expect(c.read(pureBlackProvider), isTrue);
  });
}
