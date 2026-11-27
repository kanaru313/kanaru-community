import 'package:flutter/widgets.dart' show BuildContext, Text;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/domain/install/held_package.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';
import 'package:kanaru/src/plugins/domain/install/prepare_result.dart';
import 'package:kanaru/src/plugins/domain/install/script_checker.dart';
import 'package:kanaru/src/plugins/domain/install/update_diff.dart';
import 'package:kanaru/src/plugins/domain/package/image_header.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/screens/plugins/install/package_controller.dart';
import 'package:kanaru/src/screens/plugins/install/package_flow.dart';

import '../support/install_fixtures.dart';

const _file = FileHeldSource('lyrics-lan.zip');

Future<void> _open(
  WidgetTester tester,
  FakeInstallOps ops,
  Prepared Function() result, {
  bool wide = false,
}) async {
  ops.onPrepare = () async => result();
  await pumpFlowHost(
    tester,
    ops: ops,
    size: wide ? wideWindow : narrowWindow,
    onTap: (BuildContext c) => runPackageFlow(
      c,
      ops: ops,
      start: () => ops.prepareFile(
        const PickedDocument(name: 'lyrics-lan.zip', handle: '/x'),
      ),
      subject: const PackageSubject(
        'lyrics-lan.zip',
        isFile: true,
        named: false,
      ),
    ),
  );
}

void main() {
  for (final wide in [false, true]) {
    final shell = wide ? 'wide' : 'narrow';
    group(shell, () {
      testWidgets('an unreadable package lists its reason in the red box', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        await _open(
          tester,
          ops,
          () => const Err(PackageUnreadable(MissingManifest())),
          wide: wide,
        );
        expect(find.text('Can’t install'), findsOneWidget);
        expect(
          find.text('The file lyrics-lan.zip isn’t a valid plugin.'),
          findsOneWidget,
        );
        expect(find.text('Reasons'), findsOneWidget);
        expect(
          find.text('plugin.json not found at the top of the package'),
          findsOneWidget,
        );
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.text('Can’t install'), findsNothing);
      });

      testWidgets('a blocked host names it and says only public names pass', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        await _open(
          tester,
          ops,
          () => const Err(PackageUnreadable(InvalidHost('192.168.1.5'))),
          wide: wide,
        );
        expect(
          find.text('hosts: “192.168.1.5” is not a public domain name'),
          findsOneWidget,
        );
        expect(
          find.text('Plugins may only declare public domain names (https).'),
          findsOneWidget,
        );
      });

      testWidgets('a newer API opens the dialog without a reasons box', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        await _open(
          tester,
          ops,
          () => const Err(PackageUnreadable(NeedsNewerApp('3'))),
          wide: wide,
        );
        expect(find.text('Needs a newer Kanaru'), findsOneWidget);
        expect(find.textContaining('apiVersion 3'), findsOneWidget);
        expect(find.text('Reasons'), findsNothing);
      });

      testWidgets('a script error names the file and the line', (tester) async {
        final ops = FakeInstallOps();
        await _open(
          tester,
          ops,
          () => Ok(
            heldOf(
              source: _file,
              review: const ProblemsReview([
                ScriptSyntaxError(
                  'search.js',
                  ScriptProblem(line: 7, message: 'x'),
                ),
              ]),
            ),
          ),
          wide: wide,
        );
        expect(
          find.text('Script search.js has an error at line 7'),
          findsOneWidget,
        );
        expect(ops.discarded, contains('token-1'));
      });

      testWidgets('another origin says where the plugin came from', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        await _open(
          tester,
          ops,
          () => Ok(
            heldOf(
              source: _file,
              review: const ProblemsReview([
                OtherOrigin(
                  RepoHeldSource(
                    repoUrl: 'https://repo1.example.com/plugins.json',
                    slug: 'demo',
                  ),
                ),
              ]),
            ),
          ),
          wide: wide,
        );
        expect(
          find.textContaining(
            'already installed from repository https://repo1.example.com/plugins.json',
          ),
          findsOneWidget,
        );
      });

      for (final (label, review, text) in [
        (
          'the same version',
          updateReview(order: VersionOrder.same),
          'This package is the same version as the installed one.',
        ),
        (
          'an older version',
          updateReview(order: VersionOrder.older),
          'This package is older than the installed version, so it can’t be used.',
        ),
        (
          'a change of kind',
          updateReview(kind: KindChange.refused),
          'This package is another kind of plugin than the installed one, so it can’t be used. Remove the plugin, then install the new one.',
        ),
      ]) {
        testWidgets('$label of an installed plugin is a problem', (
          tester,
        ) async {
          final ops = FakeInstallOps();
          await _open(
            tester,
            ops,
            () => Ok(heldOf(source: _file, review: review)),
            wide: wide,
          );
          expect(find.text('Can’t install'), findsOneWidget);
          expect(find.text(text), findsOneWidget);
        });
      }

      testWidgets('a repair review is the same-version problem', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        await _open(
          tester,
          ops,
          () => Ok(heldOf(source: _file, review: const RepairReview())),
          wide: wide,
        );
        expect(
          find.text('This package is the same version as the installed one.'),
          findsOneWidget,
        );
      });

      testWidgets('a refused write at install time opens the same dialog', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        ops.onInstall = (_) async =>
            const InstallRefused(InstallFailure.sameVersion);
        await pumpFlowHost(
          tester,
          ops: ops,
          size: wide ? wideWindow : narrowWindow,
          onTap: (c) =>
              installFromRepository(c, ops, installId: 'id-demo', name: 'Demo'),
        );
        await tester.tap(find.text('Install'));
        await tester.pumpAndSettle();
        expect(
          find.text('This package is the same version as the installed one.'),
          findsOneWidget,
        );
      });

      testWidgets('a script check that cannot run refuses the package', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        await _open(
          tester,
          ops,
          () => const Err(ScriptCheckUnavailable()),
          wide: wide,
        );
        expect(find.text('Can’t install'), findsOneWidget);
        expect(
          find.textContaining('can’t check scripts right now'),
          findsOneWidget,
        );
      });

      testWidgets(
        'a package that differs from the list shows the differences and retries',
        (tester) async {
          final ops = FakeInstallOps();
          var first = true;
          ops.onPrepare = () async {
            if (!first) return Ok(heldOf(token: 'token-2'));
            first = false;
            return Ok(
              heldOf(
                review: const ProblemsReview([
                  CatalogDiffers([
                    CatalogMismatch.version,
                    CatalogMismatch.hosts,
                  ]),
                ]),
              ),
            );
          };
          await pumpFlowHost(
            tester,
            ops: ops,
            size: wide ? wideWindow : narrowWindow,
            onTap: (c) => installFromRepository(
              c,
              ops,
              installId: 'id-demo',
              name: 'Demo',
            ),
          );
          expect(find.text('Package doesn’t match the list'), findsOneWidget);
          expect(find.text('Differences'), findsOneWidget);
          expect(
            find.text('The version of the package differs from the list'),
            findsOneWidget,
          );
          expect(
            find.text('The hosts of the package differ from the list'),
            findsOneWidget,
          );
          expect(
            find.textContaining('cache has not caught up'),
            findsOneWidget,
          );
          await tester.tap(find.text('Refresh and try again'));
          await tester.pumpAndSettle();
          expect(ops.prepared.last, 'refresh:token-1');
          expect(find.text('Install Demo?'), findsOneWidget);
        },
      );

      testWidgets('closing a mismatch does not retry', (tester) async {
        final ops = FakeInstallOps();
        ops.onPrepare = () async => Ok(
          heldOf(
            review: const ProblemsReview([
              CatalogDiffers([CatalogMismatch.sha256]),
            ]),
          ),
        );
        await pumpFlowHost(
          tester,
          ops: ops,
          size: wide ? wideWindow : narrowWindow,
          onTap: (c) =>
              installFromRepository(c, ops, installId: 'id-demo', name: 'Demo'),
        );
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(ops.prepared, hasLength(1));
        expect(find.text('Package doesn’t match the list'), findsNothing);
      });

      testWidgets(
        'a seek bar image that is too large names it and the limits',
        (tester) async {
          final ops = FakeInstallOps();
          await _open(
            tester,
            ops,
            () => const Err(
              PackageUnreadable(
                InvalidAsset('assets/cat.png', ImageProblem.size),
              ),
            ),
            wide: wide,
          );
          expect(find.text('Can’t install'), findsOneWidget);
          expect(
            find.text(
              'assets/cat.png: the image is too large, at most 2048 px on each side',
            ),
            findsOneWidget,
          );
          expect(
            find.textContaining('PNG or WebP, not animated, at most 512 KB'),
            findsOneWidget,
          );
        },
      );

      testWidgets('every image refusal has its own line', (tester) async {
        final ops = FakeInstallOps();
        final seen = <String>{};
        for (final reason in [
          ImageProblem.format,
          ImageProblem.animated,
          ImageProblem.extension,
          'frames',
        ]) {
          await _open(
            tester,
            ops,
            () => Err(PackageUnreadable(InvalidAsset('assets/a.png', reason))),
            wide: wide,
          );
          final line = tester
              .widgetList<Text>(find.textContaining('assets/a.png: '))
              .single
              .data!;
          expect(seen.add(line), isTrue, reason: '$reason repeats a line');
          await tester.tap(find.text('Close'));
          await tester.pumpAndSettle();
        }
      });

      testWidgets('a missing image names the file', (tester) async {
        final ops = FakeInstallOps();
        await _open(
          tester,
          ops,
          () => const Err(PackageUnreadable(MissingAsset('assets/t.png'))),
          wide: wide,
        );
        expect(
          find.text('assets/t.png: the package does not contain this file'),
          findsOneWidget,
        );
      });

      testWidgets('a seek bar package with code says it cannot have any', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        await _open(
          tester,
          ops,
          () => const Err(PackageUnreadable(UnsafeEntry('src/main.js'))),
          wide: wide,
        );
        expect(
          find.text('src/main.js: a seek bar plugin cannot contain code'),
          findsOneWidget,
        );
      });

      testWidgets('a path that is unsafe keeps the unsafe-name line', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        await _open(
          tester,
          ops,
          () => const Err(PackageUnreadable(UnsafeEntry('../x'))),
          wide: wide,
        );
        expect(find.textContaining('unsafe entry name'), findsOneWidget);
      });

      testWidgets('a Lottie thumb opens the newer-Kanaru dialog', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        ops.onPrepare = () async => const Err(
          PackageUnreadable(UnsupportedFeature('seekbar.thumb.lottie')),
        );
        await pumpFlowHost(
          tester,
          ops: ops,
          size: wide ? wideWindow : narrowWindow,
          onTap: (c) => installFromRepository(
            c,
            ops,
            installId: 'id-demo',
            name: 'Vinyl',
            kind: PluginKind.seekbar,
          ),
        );
        expect(find.text('Needs a newer Kanaru'), findsOneWidget);
        expect(
          find.text(
            'Vinyl uses an animated Lottie thumb, which this version of Kanaru '
            'does not support yet. Update Kanaru, then install it again.',
          ),
          findsOneWidget,
        );
        expect(find.text('Reasons'), findsNothing);
      });
    });
  }
}
