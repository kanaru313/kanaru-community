import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/state/install_ops.dart';
import 'package:kanaru/src/plugins/state/plugin_run_info_provider.dart';
import 'package:kanaru/src/screens/plugins/remove/remove_flow.dart';

import '../support/install_fixtures.dart';
import '../support/run_fixtures.dart';

const _lyricsPreview = RemovePreview(
  installId: 'id-demo',
  name: 'Demo',
  author: 'someone',
  version: 3,
  kind: PluginKind.lyrics,
);

void main() {
  for (final (name, size) in [('narrow', narrowWindow), ('wide', wideWindow)]) {
    group(name, () {
      testWidgets('asks first, naming the plugin and what goes', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) => removePluginFlow(c, ops, 'id-demo'),
        );
        expect(find.text('Remove Demo?'), findsOneWidget);
        expect(find.text('someone · version 3'), findsOneWidget);
        expect(find.text('Will be removed'), findsOneWidget);
        expect(find.text('The plugin’s code'), findsOneWidget);
        expect(find.text('The plugin’s settings'), findsOneWidget);
        expect(find.text('The plugin’s log'), findsOneWidget);
        expect(find.text('Own storage (0 KB)'), findsOneWidget);
        expect(find.text('Kept'), findsNothing, reason: 'not a lyrics plugin');
        expect(ops.removed, isEmpty, reason: 'nothing before Remove');
      });

      testWidgets('names the size of the own storage that goes', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          overrides: RunState(storageBytes: 38 * 1024).overrides,
          onTap: (c) => removePluginFlow(c, ops, 'id-demo'),
        );
        expect(find.text('Own storage (38 KB)'), findsOneWidget);
      });

      testWidgets('a translate plugin lists the saved translations it leaves', (
        tester,
      ) async {
        for (final kind in [PluginKind.translate, PluginKind.aiTranslate]) {
          final ops = FakeInstallOps()
            ..preview = RemovePreview(
              installId: 'id-demo',
              name: 'Demo',
              author: 'someone',
              version: 3,
              kind: kind,
            );
          await pumpFlowHost(
            tester,
            ops: ops,
            size: size,
            onTap: (c) => removePluginFlow(c, ops, 'id-demo'),
          );
          expect(find.text('Kept'), findsOneWidget);
          expect(
            find.text(
              'Saved translations, until you choose “Delete saved translations”',
            ),
            findsOneWidget,
          );
          expect(find.textContaining('lyrics'), findsNothing);
        }
      });

      testWidgets('a lyrics plugin lists the saved lyrics it leaves', (
        tester,
      ) async {
        final ops = FakeInstallOps()..preview = _lyricsPreview;
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          overrides: RunState(
            savedLyrics: const SavedLyricsStats(count: 86, bytes: 5000),
          ).overrides,
          onTap: (c) => removePluginFlow(c, ops, 'id-demo'),
        );
        expect(find.text('Kept'), findsOneWidget);
        expect(
          find.text(
            'Saved lyrics of 86 songs and pinned lyrics from this source',
          ),
          findsOneWidget,
        );
        expect(
          find.text('The .lrc files written next to songs'),
          findsOneWidget,
        );
      });

      testWidgets('a lyrics plugin with nothing saved still keeps pins', (
        tester,
      ) async {
        final ops = FakeInstallOps()..preview = _lyricsPreview;
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          overrides: RunState().overrides,
          onTap: (c) => removePluginFlow(c, ops, 'id-demo'),
        );
        expect(
          find.text('Pinned lyrics from this source (if any)'),
          findsOneWidget,
        );
        expect(find.textContaining('Saved lyrics of'), findsNothing);
      });

      testWidgets('Cancel removes nothing', (tester) async {
        final ops = FakeInstallOps();
        var before = 0;
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) => removePluginFlow(
            c,
            ops,
            'id-demo',
            onBeforeRemove: () => before++,
          ),
        );
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(ops.removed, isEmpty);
        expect(before, 0);
        expect(find.text('Remove Demo?'), findsNothing);
      });

      testWidgets('Remove deletes, hooks the page first, and says so', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        final order = <String>[];
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) async {
            final done = await removePluginFlow(
              c,
              ops,
              'id-demo',
              onBeforeRemove: () => order.add('before:${ops.removed.length}'),
            );
            order.add('done:$done');
          },
        );
        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();
        expect(ops.removed, ['id-demo']);
        expect(order, ['before:0', 'done:true']);
        expect(find.text('Removed Demo'), findsOneWidget);
      });

      testWidgets('a failed delete says it could not remove', (tester) async {
        final ops = FakeInstallOps()..removeResult = RemoveResult.failed;
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) => removePluginFlow(c, ops, 'id-demo'),
        );
        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();
        expect(find.text('Couldn’t remove Demo'), findsOneWidget);
      });

      testWidgets('a plugin that is gone opens no dialog', (tester) async {
        final ops = FakeInstallOps()..preview = null;
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) => removePluginFlow(c, ops, 'id-demo'),
        );
        expect(find.text('Remove Demo?'), findsNothing);
        expect(ops.removed, isEmpty);
      });

      testWidgets('a plugin with no author says so at 200 % text', (
        tester,
      ) async {
        final ops = FakeInstallOps()
          ..preview = const RemovePreview(
            installId: 'id-demo',
            name: 'Demo',
            author: '',
            version: 3,
            kind: null,
          );
        await pumpFlowHost(
          tester,
          ops: ops,
          size: size,
          onTap: (c) => removePluginFlow(c, ops, 'id-demo'),
        );
        expect(find.text('Unknown author · version 3'), findsOneWidget);
      });
    });
  }
}
