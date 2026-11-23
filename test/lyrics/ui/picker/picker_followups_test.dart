import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/data/online/store_result.dart';
import 'package:kanaru/src/lyrics/domain/online/online_search_state.dart';
import 'package:kanaru/src/lyrics/ui/picker/picker_preview.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../online/online_ui_overrides.dart';
import 'picker_harness.dart';

List<Override> _sources() =>
    onlineUiOverrides(sources: [lyricsSource('lrclib', name: 'LRCLIB')]);

SearchScript _script() => SearchScript()
  ..answers['*'] = {
    'lrclib': results([candidate('lrclib', 'a'), candidate('lrclib', 'b')]),
  };

Finder _use() => find.widgetWithText(KModalButton, 'Use these lyrics');

void main() {
  group('the first search and the typed one', () {
    testWidgets('a search typed while the facts load is not replaced by the '
        'default one', (tester) async {
      final script = _script()..answers['mine'] = {};
      final picker = await openPicker(
        tester,
        script: script,
        overrides: _sources(),
      );
      // Typed at once, before the first frame after opening settled.
      await searchFor(tester, 'mine');
      await settle(tester);
      expect(picker.script.searches.last, 'mine');
      expect(
        picker.script.searches.where((s) => s == 'Song Singer'),
        hasLength(lessThanOrEqualTo(1)),
      );
      expect(find.widgetWithText(TextField, 'mine'), findsOneWidget);
    });

    testWidgets('a failing facts read leaves the loading state', (
      tester,
    ) async {
      await openPicker(
        tester,
        script: _script(),
        overrides: _sources(),
        factsFail: true,
      );
      await settle(tester);
      expect(find.text('Searching for lyrics…'), findsNothing);
      expect(
        find.text('Nothing found in the source that is on'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('typed text survives the window crossing the desktop '
        'breakpoint', (tester) async {
      final script = _script()..answers['mine'] = {};
      await openPicker(tester, script: script, overrides: _sources());
      await settle(tester);
      await searchFor(tester, 'mine');
      await settle(tester);
      tester.view.physicalSize = desktopSize;
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.widgetWithText(TextField, 'mine'), findsOneWidget);
      expect(script.searches, ['Song Singer', 'mine']);
    });
  });

  group('a refused keep is visible', () {
    for (final (name, size, prepare) in [
      ('refused, mobile', const Size(400, 800), false),
      ('failing, desktop', desktopSize, true),
    ]) {
      testWidgets('$name: a snack bar says the lyrics were not saved', (
        tester,
      ) async {
        final picker = await openPicker(
          tester,
          script: _script(),
          overrides: _sources(),
          size: size,
        );
        await settle(tester);
        if (prepare) {
          picker.online.error = StateError('database is gone');
        } else {
          picker.online.keepResult = StoreResult.notStored;
        }
        if (size == desktopSize) {
          await tester.tap(_use());
        } else {
          await tester.tap(find.text('Song a'));
          await tester.pumpAndSettle();
          await tester.tap(_use());
        }
        await tester.pumpAndSettle();
        expect(find.text('Choose lyrics'), findsNothing);
        expect(
          find.text("Couldn't save the lyrics. Try again."),
          findsOneWidget,
        );
      });
    }
  });

  group('lyrics fetch rest', () {
    testWidgets('moving through results starts one fetch, for the one that '
        'stays', (tester) async {
      final script = SearchScript()
        ..answers['*'] = {
          'lrclib': results([
            candidate('lrclib', 'a', body: null),
            candidate('lrclib', 'b', body: null),
            candidate('lrclib', 'c', body: null),
          ]),
        }
        ..bodies['c'] = syncedBody;
      await openPicker(
        tester,
        script: script,
        overrides: _sources(),
        size: desktopSize,
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Song b'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Song c'));
      // The frame that swaps the preview (a real app draws one at once).
      await tester.pump();
      await tester.pump(
        PickerPreview.fetchRest + const Duration(milliseconds: 50),
      );
      await settle(tester);
      expect(script.fetched, ['c']);
    });

    testWidgets('a result that stays is fetched after the rest', (
      tester,
    ) async {
      final script = SearchScript()
        ..answers['*'] = {
          'lrclib': results([candidate('lrclib', 'a', body: null)]),
        }
        ..bodies['a'] = syncedBody;
      await openPicker(
        tester,
        script: script,
        overrides: _sources(),
        size: desktopSize,
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(script.fetched, isEmpty);
      await tester.pump(PickerPreview.fetchRest);
      expect(script.fetched, ['a']);
    });
  });

  group('sources sheet subtitles', () {
    testWidgets('a source still loading and one that failed say so', (
      tester,
    ) async {
      final script = SearchScript()
        ..enabled = ['lrclib', 'netease']
        ..answers['*'] = {
          'netease': const SourceSearch(
            SourceSearchPhase.failed,
            failure: SourceSearchFailure.network,
          ),
        }
        ..gates['Song Singer'] = Completer<void>();
      await openPicker(
        tester,
        script: script,
        overrides: onlineUiOverrides(
          sources: [
            lyricsSource('lrclib', name: 'LRCLIB'),
            lyricsSource('netease', name: 'NetEase'),
          ],
        ),
      );
      await tester.tap(find.widgetWithText(KChip, 'All sources'));
      await tester.pump(const Duration(milliseconds: 400));
      // Both are still loading: the subtitle says it, not "No results".
      expect(find.text('Searching LRCLIB…'), findsWidgets);
      expect(find.text('No results'), findsNothing);
      script.gates['Song Singer']!.complete();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('NetEase: network error or timed out'), findsWidgets);
    });
  });

  testWidgets('← of the preview: short tooltip, long spoken label', (
    tester,
  ) async {
    await openPicker(tester, script: _script(), overrides: _sources());
    await settle(tester);
    await tester.tap(find.text('Song a'));
    await tester.pumpAndSettle();
    final back = tester.widget<KIconButton>(
      find.byWidgetPredicate(
        (w) => w is KIconButton && w.tooltip == 'Back to the list',
      ),
    );
    expect(back.semanticLabel, 'Back to the results');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  });
}
