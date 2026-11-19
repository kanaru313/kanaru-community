import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/data/m3u/m3u_results.dart';
import 'package:kanaru/src/library/state/m3u/m3u_import_progress.dart';
import 'package:kanaru/src/library/ui/m3u/m3u_entry_points.dart';
import 'package:kanaru/src/library/ui/m3u/m3u_import_progress_card.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';
import 'package:kanaru/src/platform/state/document_picker_provider.dart';
import 'package:material_ui/material_ui.dart';

import 'support/m3u_flow_harness.dart';

void main() {
  test('availability is the document picker check', () {
    expect(m3uAvailable, documentPickerSupported);
  });

  testWidgets('importM3u opens the open dialog', (t) async {
    final h = await M3uFlowHarness.pump(t);
    final flow = h.start(t, importM3u);
    await h.untilDone(t, flow);
    expect(h.picker.opens, 1);
    expect(h.picker.openFilter, isA<DocumentFilter>());
  });

  testWidgets('exportM3u opens the save dialog for the playlist', (t) async {
    final h = await M3uFlowHarness.pump(t);
    final uid = (await t.runAsync(
      () => h.env.repo.createPlaylist(name: 'Road', tracks: const []),
    ))!;
    final flow = h.start(t, (c) => exportM3u(c, uid, relative: false));
    await h.untilDone(t, flow);
    expect(h.picker.suggestedName, 'Road.m3u8');
  });

  group('progress sliver', () {
    Future<ProviderContainer> pump(WidgetTester t) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: CustomScrollView(slivers: [M3uImportProgressSliver()]),
            ),
          ),
        ),
      );
      return container;
    }

    testWidgets('draws no card while no import runs', (t) async {
      await pump(t);
      expect(
        find.byType(M3uImportProgressCard, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.textContaining('Importing'), findsNothing);
    });

    testWidgets('shows the card once visible, with N / M, then goes', (
      t,
    ) async {
      final container = await pump(t);
      final n = container.read(m3uImportProgressProvider.notifier)
        ..begin('x.m3u');
      await t.pump();
      expect(find.textContaining('x.m3u'), findsNothing);
      await t.pump(m3uProgressDelay);
      expect(find.textContaining('x.m3u'), findsOneWidget);
      n.update(const M3uImportProgress(fileName: 'x.m3u', done: 3, total: 9));
      await t.pump();
      expect(find.text('3 / 9 lines'), findsOneWidget);
      n.end();
      await t.pump();
      expect(find.textContaining('x.m3u'), findsNothing);
    });
  });
}
