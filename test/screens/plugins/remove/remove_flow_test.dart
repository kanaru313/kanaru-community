import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/state/install_ops.dart';
import 'package:kanaru/src/screens/plugins/remove/remove_flow.dart';

import '../support/install_fixtures.dart';

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
        expect(ops.removed, isEmpty, reason: 'nothing before Remove');
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
