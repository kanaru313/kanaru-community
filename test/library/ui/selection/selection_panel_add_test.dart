import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/add_to_playlist/add_to_playlist.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' show TextField;

import '../../../support/icon_button_finders.dart';
import '../add_to_playlist/support/flow_harness.dart';
import '../add_to_playlist/support/picker_host.dart';
import '../support/library_harness.dart';
import '../support/ui_harness.dart';
import 'selection_support.dart';

const _tooltip = 'Add to playlist…';

/// Ids of the live tracks of the playlist named [name], in playlist order.
Future<List<int>> _held(
  WidgetTester tester,
  LibraryHarness h,
  String name,
) async {
  final rows = (await tester.runAsync(
    () => h.db
        .customSelect(
          'SELECT e.track_id AS id FROM playlist_entries e '
          'JOIN playlists p ON p.id = e.playlist_id '
          'WHERE p.name = ? AND e.deleted_at IS NULL '
          'ORDER BY e.sort_key, e.uid',
          variables: [Variable.withString(name)],
        )
        .get(),
  ))!;
  return [for (final r in rows) r.read<int>('id')];
}

void main() {
  final en = l10nOf('en');
  setUp(() => addTearDown(resetAddToPlaylistGuard));

  testWidgets('the button is enabled and opens the picker for the selection', (
    tester,
  ) async {
    final h = await pumpSelection(tester);
    final ids = await allIds(h);
    h.selection
      ..toggle(ids[3])
      ..toggle(ids[0])
      ..toggle(ids[2]);
    await tester.pump();
    final button = tester.widget<KIconButton>(byIconButton(_tooltip));
    expect(button.onPressed, isNotNull);

    await tester.tap(byIconButton(_tooltip));
    await pumpUntilFound(tester, find.text(en.playlistPickerTitle));
    await tester.pumpAndSettle();
    expect(find.text('3 selected songs'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('Add puts the songs in selection order; the selection stays', (
    tester,
  ) async {
    final h = await pumpSelection(tester);
    final ids = await allIds(h);
    final order = [ids[3], ids[0], ids[2]];
    h.selection
      ..toggle(order[0])
      ..toggle(order[1])
      ..toggle(order[2]);
    await tester.pump();

    await tester.tap(byIconButton(_tooltip));
    await pumpUntilFound(tester, find.text(en.playlistPickerTitle));
    await tester.pumpAndSettle();
    await tick(tester, 'New playlist…');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Mix');
    await tester.tap(find.text(en.playlistPickerNewConfirm));
    await tester.pumpAndSettle();
    await pressAdd(tester);
    await pumpUntil(
      tester,
      () => toast('Added 3 songs to “Mix”'),
      reason: 'the toast',
    );
    await tester.pumpAndSettle();

    expect(await _held(tester, h, 'Mix'), [for (final t in order) t.value]);
    expect(h.selected.ids, order);
    expect(find.byType(KSelectionPanel), findsOneWidget);
    await unmountApp(tester);
  });
}
