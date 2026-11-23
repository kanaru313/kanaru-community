import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/ui/picker/picker_result_row.dart';
import 'package:kanaru/src/lyrics/ui/picker/search_sources_sheet.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../online/online_ui_overrides.dart';
import 'picker_harness.dart';

List<Override> _sources() => onlineUiOverrides(
  sources: [
    lyricsSource('lrclib', name: 'LRCLIB'),
    lyricsSource('musix', name: 'Musixmatch'),
    lyricsSource('netease', name: 'NetEase', enabled: false),
  ],
);

SearchScript _script() => SearchScript()
  ..enabled = ['lrclib', 'musix']
  ..answers['*'] = {
    'lrclib': results([candidate('lrclib', 'a'), candidate('lrclib', 'b')]),
    // Musixmatch answered with nothing.
  }
  ..disabledAnswers['netease'] = results([
    candidate('netease', 'c', title: 'Off song'),
  ]);

Finder _sourceRow(String name) => find
    .ancestor(of: find.text(name), matching: find.byType(SelectionRow))
    .first;

Future<OpenedPicker> _open(WidgetTester tester, Size size) async {
  final picker = await openPicker(
    tester,
    script: _script(),
    overrides: _sources(),
    size: size,
  );
  await settle(tester);
  await tester.tap(find.widgetWithText(KChip, 'All sources'));
  await tester.pumpAndSettle();
  return picker;
}

void main() {
  for (final (name, size) in [
    ('mobile', const Size(400, 800)),
    ('desktop', desktopSize),
  ]) {
    group(name, () {
      testWidgets('the chip opens "Search sources" with counts, and the off '
          'sources under their own title', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, size);
        expect(find.byType(SearchSourcesSheet), findsOneWidget);
        expect(find.text('Search sources'), findsOneWidget);
        // "All sources" counts every result, LRCLIB its own two.
        expect(find.text('2 results'), findsNWidgets(2));
        expect(find.text('No results'), findsOneWidget);
        expect(
          tester.getSemantics(_sourceRow('All sources')),
          isSemantics(isSelected: true),
        );
        // Musixmatch has nothing to show: its row is not a choice.
        expect(
          tester.getSemantics(_sourceRow('Musixmatch')),
          isSemantics(isEnabled: false),
        );
        expect(find.text('OFF'), findsOneWidget);
        expect(find.text('Searched only when you tap Search.'), findsOneWidget);
        expect(find.text('Not searched'), findsOneWidget);
        handle.dispose();
      });

      testWidgets('choosing a source lists only it and names it on the '
          'chip', (tester) async {
        await _open(tester, size);
        await tester.tap(find.text('LRCLIB').last);
        await tester.pumpAndSettle();
        expect(find.byType(SearchSourcesSheet), findsNothing);
        expect(find.widgetWithText(KChip, 'LRCLIB'), findsOneWidget);
        expect(find.byType(PickerResultRow), findsNWidgets(2));
        // Back to everything.
        await tester.tap(find.widgetWithText(KChip, 'LRCLIB'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('All sources').last);
        await tester.pumpAndSettle();
        expect(find.widgetWithText(KChip, 'All sources'), findsOneWidget);
      });

      testWidgets('Search asks that one source that is off, now', (
        tester,
      ) async {
        final picker = await _open(tester, size);
        expect(picker.script.askedOff, isEmpty);
        await tester.tap(
          find.descendant(
            of: find.byType(SearchSourcesSheet),
            matching: find.widgetWithText(KModalButton, 'Search'),
          ),
        );
        await tester.pump();
        expect(picker.script.askedOff, [
          {'netease'},
        ]);
        expect(find.text('1 result · source is off'), findsOneWidget);
        expect(find.text('Not searched'), findsNothing);
      });

      testWidgets('✕ closes the sheet and keeps the filter', (tester) async {
        await _open(tester, size);
        await tester.tap(
          find.descendant(
            of: find.byType(SearchSourcesSheet),
            matching: find.byWidgetPredicate(
              (w) => w is KIconButton && w.tooltip == 'Close',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SearchSourcesSheet), findsNothing);
        expect(find.widgetWithText(KChip, 'All sources'), findsOneWidget);
      });
    });
  }
}
