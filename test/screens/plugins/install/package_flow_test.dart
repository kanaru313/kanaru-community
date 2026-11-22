import 'dart:async';

import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';
import 'package:kanaru/src/plugins/domain/install/held_package.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';
import 'package:kanaru/src/plugins/domain/install/prepare_result.dart';
import 'package:kanaru/src/plugins/domain/net/fetch_failure.dart';
import 'package:kanaru/src/screens/plugins/install/package_flow.dart';

import '../support/install_fixtures.dart';

void _open(BuildContext context, FakeInstallOps ops) =>
    installFromRepository(context, ops, installId: 'id-demo', name: 'Demo');

void main() {
  for (final (name, size) in [('narrow', narrowWindow), ('wide', wideWindow)]) {
    group(name, () {
      testWidgets('shows the progress, then the install screen', (
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
        expect(find.text('Loading and checking the package…'), findsOneWidget);
        expect(find.text('Install Demo'), findsNothing);
        gate.complete(Ok(heldOf()));
        await tester.pumpAndSettle();
        expect(find.text('Install Demo?'), findsOneWidget);
        expect(
          find.text('Plugin lyrics · version 3 · someone (self-declared)'),
          findsOneWidget,
        );
        expect(find.text('From repository Kanaru Plugins'), findsOneWidget);
        expect(find.text('Demo plugin'), findsOneWidget);
        expect(find.text('Sends data to'), findsOneWidget);
        expect(find.text('music.example.com'), findsOneWidget);
        expect(
          find.textContaining('Installing a plugin means you agree'),
          findsOneWidget,
        );
        expect(find.text('Static facts'), findsOneWidget);
        expect(find.text('Ask AI about this plugin'), findsOneWidget);
        expect(ops.installed, isEmpty, reason: 'nothing before Install');
      });

      testWidgets('Install writes the held package and says so', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) => _open(c, ops),
        );
        await tester.tap(find.text('Install'));
        await tester.pumpAndSettle();
        expect(ops.installed, ['token-1']);
        expect(find.text('Installed Demo'), findsOneWidget);
        expect(find.text('Install Demo?'), findsNothing);
      });

      testWidgets('closing without installing discards the held package', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) => _open(c, ops),
        );
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(ops.discarded, contains('token-1'));
        expect(ops.installed, isEmpty);
        expect(find.text('Install Demo?'), findsNothing);
      });

      testWidgets('a network error shows the band; Retry prepares again', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        var first = true;
        ops.onPrepare = () async {
          if (!first) return Ok(heldOf());
          first = false;
          return const Err(
            DownloadFailed(FetchFailure(FetchFailureKind.network)),
          );
        };
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) => _open(c, ops),
        );
        expect(
          find.text('Couldn’t download the plugin package: network error'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Check your connection and try again. Nothing has been installed.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(ops.prepared, hasLength(2));
        expect(find.text('Install Demo?'), findsOneWidget);
      });

      testWidgets('the update screen marks new hosts and asks consent', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        ops.onPrepare = () async => Ok(
          heldOf(
            manifest: lyricsManifest(
              version: 4,
              hosts: const ['music.example.com', 'new.example.com'],
            ),
            review: updateReview(newHosts: const ['new.example.com']),
          ),
        );
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) =>
              reviewPluginUpdate(c, ops, installId: 'id-demo', name: 'Demo'),
        );
        expect(find.text('Update Demo'), findsOneWidget);
        expect(find.text('lyrics · someone (self-declared)'), findsOneWidget);
        expect(find.text('NEW'), findsOneWidget);
        expect(find.text('new.example.com'), findsOneWidget);
        expect(find.textContaining('Updating means you agree'), findsOneWidget);
        expect(find.text('Demo plugin'), findsNothing);
        expect(
          find.text('Static facts · compared with the installed version'),
          findsOneWidget,
        );
        expect(find.text('Later'), findsOneWidget);
        await tester.tap(find.text('Update'));
        await tester.pumpAndSettle();
        expect(find.text('Updated Demo to version 4'), findsOneWidget);
      });

      testWidgets('an update without new hosts has no consent line', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        ops.onPrepare = () async => Ok(
          heldOf(manifest: lyricsManifest(version: 4), review: updateReview()),
        );
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) =>
              reviewPluginUpdate(c, ops, installId: 'id-demo', name: 'Demo'),
        );
        expect(find.text('NEW'), findsNothing);
        expect(find.textContaining('you agree'), findsNothing);
      });

      testWidgets('wildcards, typed addresses and no hosts are told', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        ops.onPrepare = () async => Ok(
          heldOf(
            manifest: {
              'metadata': {
                'apiVersion': 1,
                'type': 'streaming',
                'name': 'Tube',
                'version': 1,
                'hosts': ['www.tube.com', '*.cdn.tube.com'],
              },
              'script': {'search': 'search.js', 'stream': 'stream.js'},
              'config': {
                'server': {'title': 'Server', 'mode': 'input', 'format': 'url'},
              },
            },
            extra: const {'src/stream.js': 'x'},
          ),
        );
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) => _open(c, ops),
        );
        expect(find.text('www.tube.com'), findsOneWidget);
        expect(
          find.textContaining('Every subdomain of cdn.tube.com'),
          findsWidgets,
        );
        expect(find.text('Address you enter in Server'), findsOneWidget);
        expect(find.text('No fixed address.'), findsNothing);
      });

      testWidgets('a stale review prepares again with a notice', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        ops.onInstall = (_) async =>
            const InstallRefused(InstallFailure.reviewStale);
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) => _open(c, ops),
        );
        await tester.tap(find.text('Install'));
        await tester.pumpAndSettle();
        expect(ops.prepared, hasLength(2));
        expect(
          find.textContaining('The plugin changed while you were looking'),
          findsOneWidget,
        );
        expect(find.text('Install Demo?'), findsOneWidget);
      });

      testWidgets('a second streaming plugin is locked behind the Pro band', (
        tester,
      ) async {
        final ops = FakeInstallOps()..blocked = true;
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) => _open(c, ops),
        );
        expect(find.text('Needs Kanaru Pro'), findsOneWidget);
        expect(
          find.textContaining('The Free edition installs only one'),
          findsOneWidget,
        );
        await tester.tap(find.text('Install'));
        await tester.pumpAndSettle();
        expect(ops.installed, isEmpty);
      });

      testWidgets('a failed write shows the band and Retry checks again', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        ops.onInstall = (_) async =>
            const InstallRefused(InstallFailure.diskFailed);
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) => _open(c, ops),
        );
        await tester.tap(find.text('Install'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'The plugin could not be saved on this device. Nothing has changed.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(ops.prepared, hasLength(2));
      });

      testWidgets('Install from file reads the picked document', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        ops.onPrepare = () async =>
            Ok(heldOf(source: const FileHeldSource('nhac.zip')));
        const doc = PickedDocument(name: 'nhac.zip', handle: '/x/nhac.zip');
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) => installFromFile(c, ops, FakeZipPicker(doc)),
        );
        expect(ops.prepared, ['file:nhac.zip']);
        expect(find.textContaining('From file nhac.zip'), findsOneWidget);
      });

      testWidgets('a picker that fails says so and opens nothing', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) =>
              installFromFile(c, ops, FakeZipPicker(null, fails: true)),
        );
        expect(find.text('Couldn’t open the file picker.'), findsOneWidget);
        expect(ops.prepared, isEmpty);
      });
    });
  }
}
