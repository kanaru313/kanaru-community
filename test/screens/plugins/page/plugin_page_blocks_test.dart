import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/install/sweep_and_restore.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';
import 'package:kanaru/src/plugins/domain/install/prepare_result.dart';
import 'package:kanaru/src/plugins/domain/net/fetch_failure.dart';
import 'package:kanaru/src/plugins/state/alerts_provider.dart';
import 'package:kanaru/src/plugins/state/install_ops.dart';
import 'package:kanaru/src/plugins/state/plugin_page_provider.dart';

import '../../../plugins/domain/plugin_test_support.dart';
import '../support/install_fixtures.dart';
import '../support/page_fixtures.dart';
import '../support/plugin_fixtures.dart';

const _update = PluginPageUpdate(
  version: 4,
  needsReview: false,
  newHosts: [],
  repoId: 1,
);

Future<(FakeInstallOps, StoreFixture)> _pump(
  WidgetTester tester,
  PluginPageData data, {
  Size size = const Size(400, 2400),
  FakeInstallOps? ops,
}) async {
  final fake = ops ?? FakeInstallOps();
  final fixture = StoreFixture();
  await pumpPlugins(
    tester,
    fixture,
    location: pagePath,
    size: size,
    overrides: pageOverrides(AsyncData(data), ops: fake),
  );
  return (fake, fixture);
}

void main() {
  group('update band', () {
    testWidgets('Update runs in place and says the new version', (
      tester,
    ) async {
      final (ops, _) = await _pump(tester, pageData(update: _update));
      expect(find.text('New version 4'), findsOneWidget);
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(ops.updateCalls, ['id-demo']);
      expect(find.text('Updated Demo to version 4'), findsOneWidget);
    });

    testWidgets('it waits while the plugin updates anywhere', (tester) async {
      final ops = FakeInstallOps();
      final fixture = StoreFixture();
      final h = await pumpPlugins(
        tester,
        fixture,
        location: pagePath,
        size: const Size(400, 2400),
        overrides: pageOverrides(
          AsyncData(pageData(update: _update)),
          ops: ops,
        ),
      );
      expect(find.text('Update'), findsOneWidget);
      // Another screen starts the update: the spinner replaces the label.
      h.container
          .read(pageHolder.notifier)
          .set(AsyncData(pageData(update: _update, updating: true)));
      await tester.pump();
      expect(find.bySemanticsLabel('Working'), findsOneWidget);
      expect(find.text('Update'), findsNothing);
      expect(ops.updateCalls, isEmpty);
    });

    testWidgets('a version that adds hosts is looked at first', (tester) async {
      final (ops, _) = await _pump(
        tester,
        pageData(
          update: const PluginPageUpdate(
            version: 4,
            needsReview: true,
            newHosts: ['lyric.zmdcdn.me'],
            repoId: 1,
          ),
        ),
      );
      expect(
        find.text(
          'The new version also connects to lyric.zmdcdn.me: look before '
          'you update.',
        ),
        findsOneWidget,
      );
      expect(find.text('Update'), findsNothing);
      await tester.tap(find.text('See the update'));
      await tester.pump();
      expect(ops.prepared, ['update:id-demo']);
      expect(ops.updateCalls, isEmpty);
    });

    testWidgets('a package unlike the list offers to refresh the list', (
      tester,
    ) async {
      final ops = FakeInstallOps()
        ..onUpdate = (_) async =>
            const UpdateRun(InstallRefused(InstallFailure.catalogMismatch));
      final (_, fixture) = await _pump(
        tester,
        pageData(update: _update),
        ops: ops,
      );
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(find.text('Refresh the list'), findsOneWidget);
      expect(find.text('Update'), findsNothing);
      await tester.tap(find.text('Refresh the list'));
      await tester.pumpAndSettle();
      expect(fixture.ops.refreshed, [1]);
      expect(ops.updateCalls, ['id-demo'], reason: 'refresh does not update');
      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('a package defect does not offer a refresh', (tester) async {
      final ops = FakeInstallOps()
        ..onUpdate = (_) async =>
            const UpdateRun(InstallRefused(InstallFailure.hasProblems));
      await _pump(tester, pageData(update: _update), ops: ops);
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(find.text('Refresh the list'), findsNothing);
      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('the refresh offer survives the band being rebuilt', (
      tester,
    ) async {
      final ops = FakeInstallOps()
        ..onUpdate = (_) async =>
            const UpdateRun(InstallRefused(InstallFailure.catalogMismatch));
      final fixture = StoreFixture();
      final h = await pumpPlugins(
        tester,
        fixture,
        location: pagePath,
        size: const Size(400, 2400),
        overrides: pageOverrides(
          AsyncData(pageData(update: _update)),
          ops: ops,
        ),
      );
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(find.text('Refresh the list'), findsOneWidget);
      // The band goes away and comes back (another list read).
      h.container.read(pageHolder.notifier).set(AsyncData(pageData()));
      await tester.pump();
      expect(find.text('Refresh the list'), findsNothing);
      h.container
          .read(pageHolder.notifier)
          .set(AsyncData(pageData(update: _update)));
      await tester.pump();
      expect(find.text('Refresh the list'), findsOneWidget);
    });

    testWidgets('a refresh that fails says so and keeps the offer', (
      tester,
    ) async {
      final ops = FakeInstallOps()
        ..onUpdate = (_) async =>
            const UpdateRun(InstallRefused(InstallFailure.catalogMismatch));
      final (_, fixture) = await _pump(
        tester,
        pageData(update: _update),
        ops: ops,
      );
      fixture.ops.refreshFails = true;
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Refresh the list'));
      await tester.pumpAndSettle();
      expect(find.text('Could not refresh the list'), findsOneWidget);
      expect(find.text('Refresh the list'), findsOneWidget);
    });

    testWidgets('a failed update says why in a SnackBar', (tester) async {
      final ops = FakeInstallOps()
        ..onUpdate = (_) async => const UpdateRun(
          InstallPrepareFailed(
            DownloadFailed(FetchFailure(FetchFailureKind.network)),
          ),
        );
      await _pump(tester, pageData(update: _update), ops: ops);
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Couldn’t update:'), findsOneWidget);
    });

    testWidgets('no band without a newer version (file or link install)', (
      tester,
    ) async {
      await _pump(tester, pageData(row: pageRow(origin: 'file')));
      expect(find.textContaining('New version'), findsNothing);
    });
  });

  group('error band', () {
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

    testWidgets('a missing required setting names it and opens the settings', (
      tester,
    ) async {
      await _pump(
        tester,
        pageData(
          manifest: config,
          alerts: {PluginAlert.missingRequiredConfig},
          missingConfig: ['Token', 'API key'],
        ),
      );
      expect(find.text('Demo needs to be set up'), findsOneWidget);
      expect(
        find.text('The plugin can’t run until it has: Token, API key.'),
        findsOneWidget,
      );
      // The target of the button is visible: the section with its field.
      expect(find.text('The plugin’s settings'), findsOneWidget);
      expect(find.text('Token *'), findsOneWidget);
      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('The plugin’s settings'), findsOneWidget);
    });

    testWidgets('a plugin without settings shows no settings section', (
      tester,
    ) async {
      await _pump(tester, pageData());
      expect(find.text('The plugin’s settings'), findsNothing);
    });

    testWidgets('a missing package of a repository plugin can be reinstalled', (
      tester,
    ) async {
      final (ops, _) = await _pump(
        tester,
        pageData(
          alerts: {PluginAlert.packageMissing},
          missing: RestoreAction.download,
        ),
      );
      expect(find.text('Couldn’t read the plugin’s package'), findsOneWidget);
      await tester.tap(find.text('Reinstall'));
      await tester.pumpAndSettle();
      expect(ops.repairCalls, ['id-demo']);
      expect(find.text('Reinstalled Demo'), findsOneWidget);
    });

    testWidgets('a repair that adds hosts opens the update screen', (
      tester,
    ) async {
      final ops = FakeInstallOps()
        ..onRepair = (_) async => InstallNeedsReview(heldOf());
      await _pump(
        tester,
        pageData(
          alerts: {PluginAlert.packageMissing},
          missing: RestoreAction.download,
        ),
        ops: ops,
      );
      await tester.tap(find.text('Reinstall'));
      await tester.pump();
      await tester.pump();
      expect(ops.prepared, ['update:id-demo']);
    });

    testWidgets('a file install gets the sentence and no button', (
      tester,
    ) async {
      await _pump(
        tester,
        pageData(
          row: pageRow(origin: 'file'),
          alerts: {PluginAlert.reinstallFromFile},
          missing: RestoreAction.pickFile,
        ),
      );
      expect(
        find.textContaining('This plugin was installed from a file: remove it'),
        findsOneWidget,
      );
      expect(find.text('Reinstall'), findsNothing);
    });

    testWidgets('a second music source on Free says it needs Pro', (
      tester,
    ) async {
      await _pump(tester, pageData(alerts: {PluginAlert.proRequired}));
      expect(find.text('Needs Kanaru Pro'), findsOneWidget);
    });

    testWidgets('a healthy plugin has no band', (tester) async {
      await _pump(tester, pageData());
      expect(find.textContaining('needs to be set up'), findsNothing);
      expect(find.text('Reinstall'), findsNothing);
    });
  });
}
