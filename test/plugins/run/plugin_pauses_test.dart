import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/run/plugin_pauses.dart';
import 'package:kanaru/src/plugins/state/plugin_run_provider.dart';

void main() {
  test('a pause is seen until it ends, then it is gone', () async {
    final pauses = PluginPauses();
    addTearDown(pauses.dispose);
    var notified = 0;
    pauses.listen('a', () => notified++);

    expect(pauses.until('a'), isNull);
    pauses.pause('a', const Duration(milliseconds: 60));
    expect(pauses.until('a'), isNotNull);
    expect(pauses.until('b'), isNull);
    expect(notified, 1);

    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(pauses.until('a'), isNull);
    expect(notified, 2, reason: 'listeners hear the end too');
  });

  test('a shorter pause never shortens a running one', () {
    final pauses = PluginPauses();
    addTearDown(pauses.dispose);
    pauses.pause('a', const Duration(minutes: 1));
    final first = pauses.until('a');
    pauses.pause('a', const Duration(seconds: 1));
    expect(pauses.until('a'), first);
  });

  test('dispose stops the timers and forgets the pauses', () {
    final pauses = PluginPauses()
      ..pause('a', const Duration(minutes: 5))
      ..dispose();
    expect(pauses.until('a'), isNull);
    pauses.pause('a', const Duration(minutes: 5));
    expect(pauses.until('a'), isNull);
  });

  test('a stopped listener hears nothing', () {
    final pauses = PluginPauses();
    addTearDown(pauses.dispose);
    var heard = 0;
    final stop = pauses.listen('a', () => heard++);
    stop();
    pauses.pause('a', const Duration(minutes: 1));
    expect(heard, 0);
  });

  test('the provider follows the start and the end of a pause', () async {
    final pauses = PluginPauses();
    final container = ProviderContainer(
      overrides: [pluginPausesProvider.overrideWithValue(pauses)],
    );
    addTearDown(container.dispose);
    addTearDown(pauses.dispose);
    final seen = <DateTime?>[];
    container.listen(
      pluginPauseProvider('a'),
      (_, next) => seen.add(next),
      fireImmediately: true,
    );
    expect(seen, [null]);

    pauses.pause('a', const Duration(milliseconds: 60));
    await Future<void>.delayed(Duration.zero);
    expect(seen.length, 2);
    expect(seen.last, isNotNull);

    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(seen.length, 3);
    expect(seen.last, isNull);
  });
}
