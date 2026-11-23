import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/ui/picker/picker_preview_page.dart';
import 'package:kanaru/src/lyrics/ui/picker/picker_result_row.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../online/online_ui_overrides.dart';
import 'picker_harness.dart';

List<Override> _sources() =>
    onlineUiOverrides(sources: [lyricsSource('lrclib', name: 'LRCLIB')]);

SearchScript _script() => SearchScript()
  ..answers['*'] = {
    'lrclib': results([
      candidate('lrclib', 'a'),
      candidate('lrclib', 'b', body: plainBody, length: 256),
    ]),
  };

Finder _use() => find.widgetWithText(KModalButton, 'Use these lyrics');

Future<OpenedPicker> _open(
  WidgetTester tester, {
  SearchScript? script,
  Size size = const Size(400, 800),
  double textScale = 1,
}) async {
  final picker = await openPicker(
    tester,
    script: script ?? _script(),
    overrides: _sources(),
    size: size,
    textScale: textScale,
  );
  await settle(tester);
  return picker;
}

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the list has no footer and no chosen result', (tester) async {
    await _open(tester);
    expect(_use(), findsNothing);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('For this song only'), findsNothing);
    expect(find.byType(SelectionRow), findsNothing);
  });

  testWidgets('a tap opens the preview page: source line, whole lyrics with '
      'timestamps, footer', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester);
    await tester.tap(find.text('Song a'));
    await tester.pumpAndSettle();
    expect(find.byType(PickerPreviewPage), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.textContaining('LRCLIB · Synced · 4:12 '), findsOneWidget);
    expect(find.textContaining(' · Singer'), findsWidgets);
    expect(find.text('First line'), findsOneWidget);
    expect(find.text('Second line'), findsOneWidget);
    expect(find.text('0:12'), findsOneWidget);
    expect(find.text('♪'), findsOneWidget);
    expect(find.text('Plain lyrics, no timestamps'), findsNothing);
    expect(find.text('For this song only'), findsOneWidget);
    expect(tester.getSemantics(_use()), isSemantics(isEnabled: true));
    handle.dispose();
  });

  testWidgets('plain lyrics: a note instead of timestamps, the difference '
      'shows on the source line', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Song b'));
    await tester.pumpAndSettle();
    expect(find.text('Plain lyrics, no timestamps'), findsOneWidget);
    expect(find.text('Plain one'), findsOneWidget);
    expect(find.text('0:12'), findsNothing);
    expect(find.textContaining('LRCLIB · Plain · 4:16 '), findsOneWidget);
    expect(find.text('+4 s'), findsWidgets);
  });

  testWidgets('Back: preview, then list, then back to the source modal', (
    tester,
  ) async {
    final picker = await _open(tester);
    await tester.tap(find.text('Song a'));
    await tester.pumpAndSettle();
    await _back(tester);
    expect(find.byType(PickerPreviewPage), findsNothing);
    expect(find.text('Choose lyrics'), findsOneWidget);
    await _back(tester);
    expect(find.text('Choose lyrics'), findsNothing);
    expect(picker.log, ['back']);
    expect(picker.online.calls, isEmpty);
  });

  testWidgets('← of the preview goes back to the list', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Song a'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is KIconButton && w.tooltip == 'Back to the results',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PickerPreviewPage), findsNothing);
    expect(find.text('Choose lyrics'), findsOneWidget);
  });

  testWidgets('without a way back, Back just closes the picker', (
    tester,
  ) async {
    final picker = await openPicker(
      tester,
      script: _script(),
      overrides: _sources(),
      withBack: false,
    );
    await settle(tester);
    await _back(tester);
    expect(find.text('Choose lyrics'), findsNothing);
    expect(picker.log, isEmpty);
  });

  testWidgets('← of the list closes and goes back', (tester) async {
    final picker = await _open(tester);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is KIconButton && w.tooltip == 'Back to Lyrics for this song',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose lyrics'), findsNothing);
    expect(picker.log, ['back']);
  });

  testWidgets('Use these lyrics in the preview closes both pages and keeps '
      'the result', (tester) async {
    final picker = await _open(tester);
    await tester.tap(find.text('Song b'));
    await tester.pumpAndSettle();
    await tester.tap(_use());
    await tester.pumpAndSettle();
    expect(find.byType(PickerPreviewPage), findsNothing);
    expect(find.text('Choose lyrics'), findsNothing);
    expect(picker.online.calls, ['keep:1:lrclib:b:LRCLIB']);
    expect(picker.log, isEmpty);
  });

  testWidgets('a result without lyrics loads them on the page; Use waits', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final script = SearchScript()
      ..answers['*'] = {
        'lrclib': results([candidate('lrclib', 'two', body: null)]),
      }
      ..bodies['two'] = syncedBody
      ..fetchGates['two'] = Completer<void>();
    await _open(tester, script: script);
    expect(script.fetched, isEmpty);
    await tester.tap(find.text('Song two'));
    // Not pumpAndSettle: the loading spinner never settles.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(script.fetched, ['two']);
    expect(find.text('Loading lyrics…'), findsOneWidget);
    expect(tester.getSemantics(_use()), isSemantics(isEnabled: false));
    script.fetchGates['two']!.complete();
    await settle(tester);
    expect(find.text('First line'), findsOneWidget);
    expect(tester.getSemantics(_use()), isSemantics(isEnabled: true));
    handle.dispose();
  });

  testWidgets('a failed lyrics fetch says so on the page and keeps Use off', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final script = SearchScript()
      ..answers['*'] = {
        'lrclib': results([candidate('lrclib', 'two', body: null)]),
      };
    await _open(tester, script: script);
    await tester.tap(find.text('Song two'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not load the lyrics of this result'),
      findsOneWidget,
    );
    expect(tester.getSemantics(_use()), isSemantics(isEnabled: false));
    handle.dispose();
  });

  testWidgets('following the playing song closes the picker over the open '
      'preview too', (tester) async {
    final picker = await _open(tester);
    await tester.tap(find.text('Song a'));
    await tester.pumpAndSettle();
    picker.play(2);
    await tester.pumpAndSettle();
    // The preview is still the current route; closing it lets the picker go.
    await _back(tester);
    expect(find.text('Choose lyrics'), findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long names at 200 % text and a narrow phone: no overflow', (
    tester,
  ) async {
    const long =
        'Một bài hát có cái tên dài dằng dặc đến mức không thể nào vừa trong '
        'một dòng của trang xem trước';
    final script = SearchScript()
      ..answers['*'] = {
        'lrclib': results([
          candidate(
            'lrclib',
            'v',
            title: long,
            artist: 'Nghệ sĩ có tên cũng rất là dài và nhiều chữ',
          ),
        ]),
      };
    await _open(
      tester,
      script: script,
      size: const Size(360, 640),
      textScale: 2,
    );
    // The row is taller than the list at this size: tap its top edge.
    await tester.tapAt(
      tester.getTopLeft(find.byType(PickerResultRow)) + const Offset(60, 12),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PickerPreviewPage), findsOneWidget);
    expect(find.text('First line'), findsOneWidget);
    expect(
      find.widgetWithText(KModalButton, 'Use these lyrics'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
