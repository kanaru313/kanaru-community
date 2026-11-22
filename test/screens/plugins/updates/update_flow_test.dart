import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';
import 'package:kanaru/src/plugins/domain/install/prepare_result.dart';
import 'package:kanaru/src/plugins/domain/net/fetch_failure.dart';
import 'package:kanaru/src/plugins/state/install_ops.dart';
import 'package:kanaru/src/plugins/state/store_items_provider.dart';
import 'package:kanaru/src/plugins/state/updates_provider.dart';

import '../support/install_fixtures.dart';
import '../support/plugin_fixtures.dart';

StoreFixture _store({List<String> reviewIds = const []}) => StoreFixture(
  items: [
    itemOf('upd', StoreItemState.updateAvailable, name: 'Updatable'),
    itemOf('upd2', StoreItemState.updateAvailable, name: 'Other'),
  ],
  live: [
    liveRow('id-upd', name: 'Updatable'),
    liveRow('id-upd2', name: 'Other'),
  ],
  updateAllCount: 1,
  reviewIds: reviewIds,
);

/// The icon button that updates the plugin [name], found by its label.
Finder _updateOf(String name) => find.bySemanticsLabel('Update $name');

void main() {
  for (final (name, size) in [
    ('narrow', const Size(400, 1000)),
    ('wide', const Size(1400, 1000)),
  ]) {
    group(name, () {
      testWidgets('Update runs in place and says the new version', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        await pumpPlugins(
          tester,
          _store(),
          size: size,
          overrides: [installOpsProvider.overrideWithValue(ops)],
        );
        await tester.tap(_updateOf('Updatable'));
        await tester.pumpAndSettle();
        expect(ops.updateCalls, ['id-upd']);
        expect(find.text('Updated Updatable to version 4'), findsOneWidget);
        expect(find.textContaining('Couldn’t update'), findsNothing);
      });

      testWidgets('a failed update puts the red line on its row and a toast', (
        tester,
      ) async {
        final ops = FakeInstallOps()
          ..onUpdate = (_) async => const UpdateRun(
            InstallPrepareFailed(
              DownloadFailed(FetchFailure(FetchFailureKind.network)),
            ),
          );
        await pumpPlugins(
          tester,
          _store(),
          size: size,
          overrides: [installOpsProvider.overrideWithValue(ops)],
        );
        await tester.tap(_updateOf('Updatable'));
        await tester.pumpAndSettle();
        // The row line and the SnackBar say the same sentence.
        expect(find.text('Couldn’t update: network error'), findsNWidgets(2));
      });

      testWidgets('a retry clears the red line when it works', (tester) async {
        var fail = true;
        final ops = FakeInstallOps()
          ..onUpdate = (_) async => fail
              ? const UpdateRun(InstallRefused(InstallFailure.diskFailed))
              : const UpdateRun(
                  Installed('id-upd', InstallOutcome.updated),
                  version: 5,
                );
        await pumpPlugins(
          tester,
          _store(),
          size: size,
          overrides: [installOpsProvider.overrideWithValue(ops)],
        );
        await tester.tap(_updateOf('Updatable'));
        await tester.pumpAndSettle();
        expect(
          find.text('Couldn’t update: it could not be saved on this device'),
          findsNWidgets(2),
        );
        fail = false;
        await tester.pump(const Duration(seconds: 5));
        await tester.tap(_updateOf('Updatable'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Couldn’t update'), findsNothing);
        expect(find.text('Updated Updatable to version 5'), findsOneWidget);
      });

      testWidgets('a version that adds hosts turns the toast into a hint', (
        tester,
      ) async {
        final ops = FakeInstallOps()
          ..onUpdate = (_) async =>
              const UpdateRun(InstallRefused(InstallFailure.needsReview));
        await pumpPlugins(
          tester,
          _store(),
          size: size,
          overrides: [installOpsProvider.overrideWithValue(ops)],
        );
        await tester.tap(_updateOf('Updatable'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'The new version of Updatable adds hosts or permissions: tap Review.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Couldn’t update'), findsNothing);
      });

      testWidgets('Review opens the update screen for that plugin', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        ops.onPrepare = () async => Ok(heldOf(review: updateReview()));
        await pumpPlugins(
          tester,
          _store(reviewIds: const ['id-upd']),
          size: size,
          overrides: [installOpsProvider.overrideWithValue(ops)],
        );
        await tester.tap(
          find.bySemanticsLabel('Review the update of Updatable'),
        );
        await tester.pumpAndSettle();
        expect(ops.prepared, ['update:id-upd']);
        expect(find.text('Update Demo'), findsOneWidget);
      });

      testWidgets('Update all runs once and counts what happened', (
        tester,
      ) async {
        final ops = FakeInstallOps()
          ..onUpdateAll = () async => const UpdateAllState(
            total: 4,
            done: 4,
            outcomes: [
              UpdateOutcome('a', 'A', Installed('a', InstallOutcome.updated)),
              UpdateOutcome(
                'b',
                'B',
                InstallRefused(InstallFailure.needsReview),
              ),
              UpdateOutcome(
                'c',
                'C',
                InstallRefused(InstallFailure.needsReview),
              ),
              UpdateOutcome(
                'd',
                'D',
                InstallRefused(InstallFailure.databaseFailed),
              ),
            ],
          );
        await pumpPlugins(
          tester,
          _store(),
          size: size,
          overrides: [installOpsProvider.overrideWithValue(ops)],
        );
        await tester.tap(find.text('Update all (1)'));
        await tester.pumpAndSettle();
        expect(ops.updateAllCalls, 1);
        expect(
          find.text(
            'Updated 1 plugin · 2 versions to review (new hosts or permissions): open each one · 1 could not be updated',
          ),
          findsOneWidget,
        );
      });

      testWidgets('while it runs the header button shows the progress', (
        tester,
      ) async {
        final ops = FakeInstallOps();
        await pumpPlugins(
          tester,
          _store(),
          size: size,
          overrides: [
            installOpsProvider.overrideWithValue(ops),
            updateAllStateProvider.overrideWithValue(
              const UpdateAllState(running: true, done: 1, total: 3),
            ),
          ],
        );
        expect(find.text('Updating 2 / 3…'), findsOneWidget);
        expect(find.textContaining('Update all'), findsNothing);
        await tester.tap(find.text('Updating 2 / 3…'));
        await tester.pump();
        expect(ops.updateAllCalls, 0);
      });
    });
  }
}
