import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/state/scan/scan_settings.dart';
import 'package:kanaru/src/library/state/scan/setup_completion.dart';
import 'package:kanaru/src/platform/domain/media_permissions.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/state/cover_providers.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru/src/screens/first_run/state/first_run_gate.dart';
import 'package:kanaru/src/screens/first_run/ui/first_run_page.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../support/app_harness.dart';
import '../../support/memory_settings_store.dart';
import 'support/first_run_host.dart';

class _CountingStore extends MemorySettingsStore {
  int flushes = 0;

  @override
  Future<void> flush() async => flushes++;
}

String _path(ProviderContainer c) =>
    c.read(routerProvider).routeInformationProvider.value.uri.path;

void main() {
  test('the gate is true until library.setup_done is written', () async {
    final store = MemorySettingsStore();
    final c = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    expect(c.read(firstRunRequiredProvider), isTrue);
    await store.write('library.setup_done', true);
    expect(c.read(firstRunRequiredProvider), isFalse);
  });

  test('completing setup turns the gate off', () async {
    final store = MemorySettingsStore();
    final c = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    final seen = <bool>[];
    c.listen(firstRunRequiredProvider, (_, v) => seen.add(v));
    expect(c.read(firstRunRequiredProvider), isTrue);
    await completeSetup(
      setupDone: c.read(setupDoneProvider.notifier),
      scan: NoopScanCommands(),
      store: store,
    );
    await c.pump();
    expect(seen, [false]);
  });

  group('with the real router', () {
    late _CountingStore store;
    late NoopScanCommands scanner;
    late ProviderContainer container;

    Future<void> pump(WidgetTester tester) async {
      store = _CountingStore();
      scanner = NoopScanCommands();
      final catalog = FakeCatalog()..suggestion = '/home/u/Music';
      container = await pumpKanaruApp(
        tester,
        settings: store,
        scanner: scanner,
        // Replaces the harness pin of the gate by an unrelated override, so
        // the real gate body runs.
        firstRunRequired: coverMissesProvider.overrideWith(
          (ref) => CoverMissSink(),
        ),
        overrides: platformOverrides(
          catalog: catalog,
          permissions: FakePermissions(
            const MediaPermissionState.notApplicable(),
          ),
          android: false,
        ),
      );
    }

    testWidgets('every location goes to /welcome while setup is not done', (
      tester,
    ) async {
      await pump(tester);
      expect(_path(container), firstRunPath);
      expect(find.byType(FirstRunPage), findsOneWidget);

      container.read(routerProvider).go('/library');
      await tester.pumpAndSettle();
      expect(_path(container), firstRunPath);
      expect(find.byType(FirstRunPage), findsOneWidget);
    });

    testWidgets('the arrow leaves /welcome for the shell, with one scan and '
        'a flush, and nothing throws when the page goes away', (tester) async {
      await pump(tester);
      await tester.tap(find.byType(SetupNextButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_path(container), '/');
      expect(find.byType(FirstRunPage), findsNothing);
      expect(store.read('library.setup_done'), isTrue);
      expect(scanner.rescans, 1);
      expect(store.flushes, greaterThanOrEqualTo(1));
      expect(container.read(firstRunRequiredProvider), isFalse);
    });

    testWidgets('once done, /welcome is not reachable again', (tester) async {
      await pump(tester);
      await tester.tap(find.byType(SetupNextButton));
      await tester.pumpAndSettle();
      container.read(routerProvider).go(firstRunPath);
      await tester.pumpAndSettle();
      expect(_path(container), '/');
    });
  });
}
