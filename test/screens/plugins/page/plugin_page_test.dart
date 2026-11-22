import 'dart:async';

import 'package:flutter/widgets.dart' show ListView, Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/state/alerts_provider.dart';
import 'package:kanaru/src/plugins/state/install_ops.dart';
import 'package:kanaru/src/plugins/state/store_items_provider.dart';
import 'package:kanaru/src/plugins/state/store_view_models.dart';
import 'package:kanaru/src/screens/plugins/page/plugin_page_header.dart';

import '../../../support/icon_button_finders.dart';
import '../../../plugins/domain/plugin_test_support.dart';
import '../support/install_fixtures.dart';
import '../support/page_fixtures.dart';
import '../support/plugin_fixtures.dart';

/// Holds the answer of [remove] until the test lets go.
class _GatedOps extends FakeInstallOps {
  final gate = Completer<void>();

  @override
  Future<RemoveResult> remove(String installId) async {
    removed.add(installId);
    await gate.future;
    return RemoveResult.removed;
  }
}

Finder _inHeader(String text) => find.descendant(
  of: find.byType(PluginPageHeader),
  matching: find.text(text),
);

void main() {
  for (final (shell, size) in [
    ('narrow', const Size(400, 500)),
    ('wide', const Size(1400, 500)),
  ]) {
    group(shell, () {
      testWidgets('a plugin shows its head card and the blocks in order', (
        tester,
      ) async {
        await pumpPlugins(
          tester,
          StoreFixture(),
          location: pagePath,
          size: Size(size.width, 2400),
          overrides: pageOverrides(AsyncData(pageData())),
        );
        expect(_inHeader('Plugin details'), findsOneWidget);
        expect(find.text('Demo'), findsOneWidget);
        expect(
          find.text('kanaru313 (self-declared) · version 3'),
          findsOneWidget,
        );
        expect(byIconButton('Remove Demo'), findsOneWidget);
        final order = [
          'Details',
          'Connection',
          'Data',
        ].map((t) => tester.getTopLeft(find.text(t, skipOffstage: false)).dy);
        expect(order.toList(), orderedEquals([...order]..sort()));
      });

      testWidgets('loading is a blank page that keeps the title', (
        tester,
      ) async {
        await pumpPlugins(
          tester,
          StoreFixture(),
          location: pagePath,
          size: size,
          overrides: pageOverrides(const AsyncLoading()),
        );
        expect(_inHeader('Plugin details'), findsOneWidget);
        expect(find.text('Details'), findsNothing);
        expect(find.textContaining('no longer installed'), findsNothing);
        expect(byIconButton('Remove Demo'), findsNothing);
      });

      testWidgets('an unreadable list says so and Retry builds it again', (
        tester,
      ) async {
        var builds = 0;
        await pumpPlugins(
          tester,
          StoreFixture(),
          location: pagePath,
          size: size,
          overrides: pageOverrides(
            AsyncError('x', StackTrace.empty),
            onBuild: () => builds++,
          ),
        );
        expect(find.text('Couldn’t read the plugin list'), findsOneWidget);
        expect(_inHeader('Plugin details'), findsOneWidget);
        final before = builds;
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(builds, greaterThan(before));
      });

      testWidgets('a plugin that is gone offers the way back to the store', (
        tester,
      ) async {
        await pumpPlugins(
          tester,
          StoreFixture(),
          location: pagePath,
          size: size,
          overrides: pageOverrides(const AsyncData(null)),
        );
        expect(
          find.text('This plugin is no longer installed.'),
          findsOneWidget,
        );
        expect(byIconButton('Remove Demo'), findsNothing);
        await tester.tap(find.text('Back to the plugin store'));
        await tester.pumpAndSettle();
        expect(find.text('Plugin store'), findsWidgets);
        expect(find.text('This plugin is no longer installed.'), findsNothing);
      });

      testWidgets(
        'the header title becomes the name once the card scrolls out',
        (tester) async {
          await pumpPlugins(
            tester,
            StoreFixture(),
            location: pagePath,
            size: size,
            overrides: pageOverrides(AsyncData(pageData())),
          );
          expect(_inHeader('Demo'), findsNothing);
          await tester.drag(find.byType(ListView), const Offset(0, -700));
          await tester.pumpAndSettle();
          expect(_inHeader('Demo'), findsOneWidget);
          expect(_inHeader('Plugin details'), findsNothing);
          await tester.drag(find.byType(ListView), const Offset(0, 1400));
          await tester.pumpAndSettle();
          expect(_inHeader('Plugin details'), findsOneWidget);
          expect(_inHeader('Demo'), findsNothing);
        },
      );

      testWidgets('Open settings scrolls the card away and the title follows', (
        tester,
      ) async {
        final config = parseOk(
          withConfig({
            'token': {
              'title': 'Token',
              'mode': 'input',
              'format': 'text',
              'required': true,
            },
          }),
        );
        await pumpPlugins(
          tester,
          StoreFixture(),
          location: pagePath,
          size: const Size(400, 420),
          overrides: pageOverrides(
            AsyncData(
              pageData(
                manifest: config,
                alerts: {PluginAlert.missingRequiredConfig},
                missingConfig: ['Token'],
              ),
            ),
          ),
        );
        expect(_inHeader('Plugin details'), findsOneWidget);
        await tester.tap(find.text('Open settings'));
        await tester.pumpAndSettle();
        expect(_inHeader('Demo'), findsOneWidget);
        expect(_inHeader('Plugin details'), findsNothing);
      });

      testWidgets('with reduced motion the title changes in the same frame', (
        tester,
      ) async {
        await pumpPlugins(
          tester,
          StoreFixture(),
          location: pagePath,
          size: size,
          reduceMotion: true,
          overrides: pageOverrides(AsyncData(pageData())),
        );
        await tester.drag(find.byType(ListView), const Offset(0, -700));
        await tester.pump();
        await tester.pump();
        expect(_inHeader('Demo'), findsOneWidget);
        expect(_inHeader('Plugin details'), findsNothing);
      });

      testWidgets('removing never flashes "no longer installed", then '
          'returns to the store with the SnackBar', (tester) async {
        final ops = _GatedOps();
        final h = await pumpPlugins(
          tester,
          StoreFixture(),
          location: pagePath,
          size: size,
          overrides: pageOverrides(AsyncData(pageData()), ops: ops),
        );
        await tester.tap(byIconButton('Remove Demo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remove'));
        await tester.pump();
        expect(
          find.text('Details'),
          findsNothing,
          reason: 'blank while deleting',
        );
        // The list already says the plugin is gone while the files go.
        h.container.read(pageHolder.notifier).set(const AsyncData(null));
        await tester.pump();
        expect(find.textContaining('no longer installed'), findsNothing);
        expect(_inHeader('Plugin details'), findsOneWidget);
        ops.gate.complete();
        await tester.pumpAndSettle();
        expect(find.textContaining('no longer installed'), findsNothing);
        expect(find.text('Plugin store'), findsWidgets);
        expect(find.text('Removed Demo'), findsOneWidget);
      });

      testWidgets('removing keeps the name in the header, no fade back', (
        tester,
      ) async {
        final ops = _GatedOps();
        await pumpPlugins(
          tester,
          StoreFixture(),
          location: pagePath,
          size: size,
          overrides: pageOverrides(AsyncData(pageData()), ops: ops),
        );
        await tester.drag(find.byType(ListView), const Offset(0, -700));
        await tester.pumpAndSettle();
        expect(_inHeader('Demo'), findsOneWidget);
        await tester.tap(byIconButton('Remove Demo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();
        expect(_inHeader('Demo'), findsOneWidget);
        expect(_inHeader('Plugin details'), findsNothing);
        ops.gate.complete();
        await tester.pumpAndSettle();
      });

      testWidgets('a failed remove brings the page back', (tester) async {
        final ops = FakeInstallOps()..removeResult = RemoveResult.failed;
        await pumpPlugins(
          tester,
          StoreFixture(),
          location: pagePath,
          size: size,
          overrides: pageOverrides(AsyncData(pageData()), ops: ops),
        );
        await tester.tap(byIconButton('Remove Demo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();
        expect(find.text('Couldn’t remove Demo'), findsOneWidget);
        expect(find.text('Details'), findsOneWidget);
      });
    });
  }

  testWidgets('a row of the store opens the page of that plugin', (
    tester,
  ) async {
    final fixture = StoreFixture(
      items: [itemOf('demo', StoreItemState.installed, name: 'Demo')],
      live: [liveRow('id-demo', name: 'Demo')],
    );
    await pumpPlugins(
      tester,
      fixture,
      overrides: pageOverrides(AsyncData(pageData())),
    );
    await tester.tap(find.text('Demo'));
    await tester.pumpAndSettle();
    expect(find.text('Plugin details'), findsWidgets);
    expect(find.text('Details'), findsOneWidget);
  });

  testWidgets('the SnackBar of a new install opens the page of the plugin', (
    tester,
  ) async {
    final fixture = StoreFixture(
      items: [itemOf('demo', StoreItemState.notInstalled, name: 'Demo')],
      repos: const [
        RepoView(id: 1, name: 'Kho', url: repoAddress, pluginCount: 1),
      ],
    );
    await pumpPlugins(
      tester,
      fixture,
      overrides: pageOverrides(AsyncData(pageData()), ops: FakeInstallOps()),
    );
    await tester.tap(byIconButton('Install Demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Install'));
    await tester.pumpAndSettle();
    expect(find.text('Installed Demo'), findsOneWidget);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Plugin details'), findsWidgets);
    expect(find.text('Details'), findsOneWidget);
  });

  testWidgets('200 % text keeps the page readable and without overflow', (
    tester,
  ) async {
    await pumpPlugins(
      tester,
      StoreFixture(),
      location: pagePath,
      size: const Size(400, 800),
      textScale: 2,
      overrides: pageOverrides(AsyncData(pageData())),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Demo'), findsOneWidget);
  });
}
