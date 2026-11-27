import 'dart:async';

import 'package:flutter/widgets.dart'
    show BuildContext, Directionality, Locale, TextDirection;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/domain/install/prepare_result.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/screens/plugins/install/install_progress.dart';
import 'package:kanaru/src/screens/plugins/install/package_flow.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

import '../support/install_fixtures.dart';
import '../support/seekbar_fixtures.dart';

void _open(BuildContext context, FakeInstallOps ops) => installFromRepository(
  context,
  ops,
  installId: 'id-demo',
  name: 'Neon',
  kind: PluginKind.seekbar,
);

void main() {
  for (final (name, size) in [('narrow', narrowWindow), ('wide', wideWindow)]) {
    group(name, () {
      testWidgets('the install screen of a seek bar plugin', (tester) async {
        final ops = FakeInstallOps()..onPrepare = () async => Ok(heldSeekbar());
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) => _open(c, ops),
        );
        expect(find.text('Install Neon?'), findsOneWidget);
        expect(
          find.text('Seek bar plugin · version 2 · someone (self-declared)'),
          findsOneWidget,
        );
        expect(find.text('From repository Kanaru Plugins'), findsOneWidget);
        expect(find.text('A glowing bar'), findsOneWidget);

        // Nothing is sent anywhere: one visible line, no host block.
        expect(find.text('Sends data to'), findsOneWidget);
        expect(find.text('Sends no data anywhere.'), findsOneWidget);
        expect(find.text('No fixed address.'), findsNothing);
        expect(find.textContaining('Installing a plugin means'), findsNothing);

        // The static facts of the package.
        expect(find.text('Static facts'), findsOneWidget);
        expect(find.text('Package'), findsOneWidget);
        expect(
          find.textContaining('plugin.json + 1 PNG image · '),
          findsOneWidget,
        );
        expect(find.text('Code'), findsOneWidget);
        expect(
          find.text(
            'None: Kanaru draws it from the declaration, inside the seek bar band',
          ),
          findsOneWidget,
        );
        expect(find.text('Base'), findsOneWidget);
        expect(find.text('Flat bar · can be the ★ style'), findsOneWidget);
        expect(find.text('License'), findsOneWidget);
        expect(find.text('CC0-1.0'), findsOneWidget);

        // There is no code to read, so no AI review.
        expect(find.text('Ask AI about this plugin'), findsNothing);
        expect(find.text('Coming soon'), findsNothing);
      });

      testWidgets('a wave base cannot hold the ★', (tester) async {
        final ops = FakeInstallOps()
          ..onPrepare = () async => Ok(
            heldSeekbar(
              seekbar: {
                'track': {'kind': 'bars'},
              },
            ),
          );
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) => _open(c, ops),
        );
        expect(find.text('Bars'), findsOneWidget);
        expect(find.textContaining('can be the ★ style'), findsNothing);
        expect(find.text('plugin.json · 1 KB'), findsOneWidget);
      });

      testWidgets('Install writes the held package and says so', (
        tester,
      ) async {
        final ops = FakeInstallOps()..onPrepare = () async => Ok(heldSeekbar());
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) => _open(c, ops),
        );
        await tester.tap(find.text('Install'));
        await tester.pumpAndSettle();
        expect(ops.installed, ['token-1']);
        expect(find.text('Installed Neon'), findsOneWidget);
      });

      testWidgets('while loading the line names images, not scripts', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        final gate = Completer<Prepared>();
        ops.onPrepare = () => gate.future;
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          settle: false,
          onTap: (c) => _open(c, ops),
        );
        expect(
          find.text('Checking plugin.json, file names, images'),
          findsOneWidget,
        );
        expect(find.textContaining('script'), findsNothing);
        expect(find.textContaining('0 / 0'), findsNothing);
        gate.complete(Ok(heldSeekbar()));
        await tester.pumpAndSettle();
      });
    });
  }

  group('the progress line', () {
    Future<void> pumpProgress(
      WidgetTester tester,
      PrepareProgress? progress,
      PluginKind? kind,
    ) => tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.ltr,
            child: InstallProgress(progress: progress, kind: kind),
          ),
        ),
      ),
    );

    testWidgets('a seek bar download counts KB and checks images', (
      tester,
    ) async {
      await pumpProgress(
        tester,
        const PrepareProgress(
          PrepareStage.downloading,
          done: 11 * 1024,
          total: 18 * 1024,
        ),
        PluginKind.seekbar,
      );
      expect(
        find.text('11 / 18 KB · checking plugin.json, file names, images'),
        findsOneWidget,
      );
    });

    testWidgets('no script step is shown for a package without scripts', (
      tester,
    ) async {
      await pumpProgress(
        tester,
        const PrepareProgress(PrepareStage.checkingScripts, done: 0, total: 0),
        PluginKind.seekbar,
      );
      expect(find.textContaining('0 / 0'), findsNothing);
      expect(
        find.text('Checking plugin.json, file names, images'),
        findsOneWidget,
      );
    });

    testWidgets('other kinds keep the host and script wording', (tester) async {
      await pumpProgress(
        tester,
        const PrepareProgress(
          PrepareStage.downloading,
          done: 24 * 1024,
          total: 38 * 1024,
        ),
        PluginKind.lyrics,
      );
      expect(
        find.text(
          '24 / 38 KB · checking plugin.json, file names, hosts, scripts',
        ),
        findsOneWidget,
      );
    });
  });
}
