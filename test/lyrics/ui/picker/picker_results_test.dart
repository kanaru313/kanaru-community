import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/online/online_search_state.dart';
import 'package:kanaru/src/lyrics/ui/picker/picker_result_row.dart';
import 'package:kanaru/src/lyrics/ui/picker/picker_results.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../online/online_ui_overrides.dart';
import '../lyrics_spinner_finders.dart';
import 'picker_harness.dart';

SearchScript _script() => SearchScript()
  ..enabled = ['lrclib', 'netease']
  ..answers['*'] = {
    'lrclib': results([candidate('lrclib', 'a'), candidate('lrclib', 'b')]),
    'netease': results([candidate('netease', 'c', title: 'NetEase song')]),
  };

List<Override> _sources({bool lrclibOn = true, bool neteaseOn = true}) =>
    onlineUiOverrides(
      sources: [
        lyricsSource('lrclib', name: 'LRCLIB', enabled: lrclibOn),
        lyricsSource('netease', name: 'NetEase', enabled: neteaseOn),
      ],
    );

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

const _shells = [('mobile', Size(400, 800)), ('desktop', desktopSize)];

void main() {
  for (final (name, size) in _shells) {
    group(name, () {
      testWidgets('searches "title artist" and groups results by source', (
        tester,
      ) async {
        final picker = await openPicker(
          tester,
          script: _script(),
          overrides: _sources(),
          size: size,
        );
        await settle(tester);
        expect(picker.script.searches, ['Song Singer']);
        expect(find.text('Choose lyrics'), findsOneWidget);
        expect(find.text('LRCLIB · 2'), findsOneWidget);
        expect(find.text('NetEase · 1'), findsOneWidget);
        expect(find.text('Song a'), findsOneWidget);
        expect(find.text('NetEase song'), findsOneWidget);
        expect(find.text('Synced'), findsNWidgets(3));
        expect(find.byType(PickerResultRow), findsNWidgets(3));
        expect(tester.takeException(), isNull);
      });

      testWidgets('the field starts with the song and a plain kind shows '
          '"Plain"', (tester) async {
        final script = SearchScript()
          ..answers['*'] = {
            'lrclib': results([candidate('lrclib', 'p', body: plainBody)]),
          };
        await openPicker(
          tester,
          script: script,
          overrides: _sources(),
          size: size,
        );
        await settle(tester);
        expect(find.widgetWithText(TextField, 'Song Singer'), findsOneWidget);
        expect(find.text('Plain'), findsOneWidget);
        expect(find.text('Synced'), findsNothing);
      });

      testWidgets('loading: every source says it is being searched', (
        tester,
      ) async {
        final script = _script();
        script.gates['Song Singer'] = Completer<void>();
        await openPicker(
          tester,
          script: script,
          overrides: _sources(),
          size: size,
        );
        expect(find.text('Searching LRCLIB…'), findsOneWidget);
        expect(find.text('Searching NetEase…'), findsOneWidget);
        expect(find.byType(PickerResultRow), findsNothing);
        script.gates['Song Singer']!.complete();
        await settle(tester);
        expect(find.text('Searching LRCLIB…'), findsNothing);
        expect(find.byType(PickerResultRow), findsNWidgets(3));
      });

      testWidgets('waits for the plugin list without searching or showing '
          '"nothing found"', (tester) async {
        final script = _script();
        await openPicker(
          tester,
          script: script,
          overrides: onlineUiOverrides(
            sources: [lyricsSource('lrclib')],
            loaded: false,
          ),
          size: size,
        );
        await settle(tester);
        expect(find.text('Searching for lyrics…'), findsOneWidget);
        expect(find.textContaining('Nothing found'), findsNothing);
        expect(find.textContaining('No source is on'), findsNothing);
      });

      testWidgets('one result per source and twenty in one', (tester) async {
        final script = SearchScript()
          ..enabled = ['lrclib', 'netease']
          ..answers['*'] = {
            'lrclib': results([
              for (var i = 0; i < 20; i++) candidate('lrclib', 'r$i'),
            ]),
            'netease': results([candidate('netease', 'n')]),
          };
        await openPicker(
          tester,
          script: script,
          overrides: _sources(),
          size: size,
        );
        await settle(tester);
        expect(find.text('LRCLIB · 20'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Song n'),
          200,
          scrollable: find.descendant(
            of: find.byType(PickerResults),
            matching: find.byType(Scrollable),
          ),
        );
        expect(find.text('NetEase · 1'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('nothing found says how many sources were asked', (
        tester,
      ) async {
        final script = SearchScript();
        await openPicker(
          tester,
          script: script,
          overrides: onlineUiOverrides(sources: [lyricsSource('lrclib')]),
          size: size,
        );
        await settle(tester);
        expect(
          find.text('Nothing found in the source that is on'),
          findsOneWidget,
        );
        expect(find.textContaining('Search'), findsNothing);
      });

      testWidgets('every source off: asking them is a tap, and they are '
          'marked as off', (tester) async {
        final script = SearchScript()
          ..enabled = []
          ..disabledAnswers['lrclib'] = results([candidate('lrclib', 'a')])
          ..disabledAnswers['netease'] = results([candidate('netease', 'c')]);
        await openPicker(
          tester,
          script: script,
          overrides: _sources(lrclibOn: false, neteaseOn: false),
          size: size,
        );
        await settle(tester);
        expect(find.text('No source is on'), findsOneWidget);
        expect(
          find.text(
            '2 sources are off (LRCLIB, NetEase). Searched only when '
            'you tap.',
          ),
          findsOneWidget,
        );
        expect(script.askedOff, isEmpty);
        await tester.tap(find.text('Search 2 sources that are off'));
        await tester.pump();
        expect(script.askedOff, [
          {'lrclib', 'netease'},
        ]);
        expect(find.text('LRCLIB · off · 1'), findsOneWidget);
        expect(find.text('Source is off'), findsNWidgets(2));
      });

      testWidgets('a source that is off is asked only on request, from the '
          'card at the end', (tester) async {
        final script = SearchScript()
          ..answers['*'] = {
            'lrclib': results([candidate('lrclib', 'a')]),
          }
          ..disabledAnswers['netease'] = results([
            candidate('netease', 'c', title: 'Off song'),
          ]);
        await openPicker(
          tester,
          script: script,
          overrides: _sources(neteaseOn: false),
          size: size,
        );
        await settle(tester);
        expect(find.text('Not the lyrics you wanted?'), findsOneWidget);
        expect(
          find.text(
            'One source is off: NetEase. Searched only when you tap, '
            'settings stay as they are.',
          ),
          findsOneWidget,
        );
        expect(find.text('Source is off'), findsNothing);
        expect(script.askedOff, isEmpty);
        await tester.tap(find.widgetWithText(KModalButton, 'Search'));
        await tester.pump();
        expect(script.askedOff, [
          {'netease'},
        ]);
        expect(find.text('Off song'), findsOneWidget);
        expect(find.text('Source is off'), findsOneWidget);
        expect(find.text('Not the lyrics you wanted?'), findsNothing);
        expect(
          find.text(
            'Sources that are off were searched too for this song. '
            'Source settings are unchanged.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('one source failed: its line shows, the others still list', (
        tester,
      ) async {
        final script = _script()
          ..answers['*'] = {
            'lrclib': const SourceSearch(
              SourceSearchPhase.failed,
              failure: SourceSearchFailure.network,
            ),
            'netease': results([candidate('netease', 'c')]),
          };
        await openPicker(
          tester,
          script: script,
          overrides: _sources(),
          size: size,
        );
        await settle(tester);
        expect(find.text('LRCLIB: network error or timed out'), findsOneWidget);
        expect(find.text('NetEase · 1'), findsOneWidget);
      });

      for (final (failure, text) in [
        (SourceSearchFailure.server, 'LRCLIB: the server returned an error'),
        (
          SourceSearchFailure.rateLimited,
          'LRCLIB: the server says too many requests',
        ),
        (SourceSearchFailure.invalid, 'LRCLIB: the answer could not be read'),
      ]) {
        testWidgets('failure ${failure.name} has its own words', (
          tester,
        ) async {
          final script = SearchScript()
            ..answers['*'] = {
              'lrclib': SourceSearch(
                SourceSearchPhase.failed,
                failure: failure,
              ),
            };
          await openPicker(
            tester,
            script: script,
            overrides: _sources(),
            size: size,
          );
          await settle(tester);
          expect(find.text(text), findsOneWidget);
        });
      }

      testWidgets('needs setup: the line opens the plugin page and closes the '
          'picker', (tester) async {
        final script = SearchScript()
          ..answers['*'] = {
            'lrclib': const SourceSearch(SourceSearchPhase.needsConfig),
          };
        final picker = await openPicker(
          tester,
          script: script,
          overrides: _sources(),
          size: size,
        );
        await settle(tester);
        expect(find.text('LRCLIB · Needs setup'), findsOneWidget);
        await tester.tap(find.text('Open plugin page'));
        await tester.pumpAndSettle();
        expect(picker.location, '/settings/plugins/p/lrclib');
        expect(find.text('Choose lyrics'), findsNothing);
      });

      testWidgets('paused (429): says until when', (tester) async {
        final script = SearchScript()
          ..answers['*'] = {
            'lrclib': SourceSearch(
              SourceSearchPhase.paused,
              until: DateTime(2030, 1, 1, 21, 5),
            ),
          };
        await openPicker(
          tester,
          script: script,
          overrides: _sources(),
          size: size,
        );
        await settle(tester);
        expect(find.text('LRCLIB is paused until 9:05 PM'), findsOneWidget);
      });

      testWidgets('a newer search wins whatever order the answers come in', (
        tester,
      ) async {
        final script = SearchScript()
          ..gates['first'] = Completer<void>()
          ..gates['second'] = Completer<void>()
          ..answers['first'] = {
            'lrclib': results([candidate('lrclib', 'old', title: 'Old hit')]),
          }
          ..answers['second'] = {
            'lrclib': results([candidate('lrclib', 'new', title: 'New hit')]),
          }
          ..answers['Song Singer'] = {};
        await openPicker(
          tester,
          script: script,
          overrides: _sources(),
          size: size,
        );
        await settle(tester);
        await searchFor(tester, 'first');
        await searchFor(tester, 'second');
        script.gates['second']!.complete();
        await settle(tester);
        script.gates['first']!.complete();
        await settle(tester);
        expect(script.searches, ['Song Singer', 'first', 'second']);
        expect(find.text('New hit'), findsOneWidget);
        expect(find.text('Old hit'), findsNothing);
      });

      testWidgets('a removed plugin takes its results with it', (tester) async {
        final script = _script();
        await openPicker(
          tester,
          script: script,
          overrides: onlineUiOverrides(
            sources: [lyricsSource('lrclib', name: 'LRCLIB')],
          ),
          size: size,
        );
        await settle(tester);
        expect(find.text('LRCLIB · 2'), findsOneWidget);
        expect(find.textContaining('NetEase'), findsNothing);
      });

      testWidgets('very long Vietnamese names at 200 % text do not overflow', (
        tester,
      ) async {
        const long =
            'Một bài hát có cái tên dài dằng dặc đến mức không thể nào vừa '
            'trong một dòng của danh sách kết quả';
        final script = SearchScript()
          ..answers['*'] = {
            'lrclib': results([
              candidate(
                'lrclib',
                'v',
                title: long,
                artist: 'Nghệ sĩ có tên cũng rất là dài và nhiều chữ',
                album: 'Tuyển tập những bản tình ca bất hủ của thập niên',
              ),
            ]),
          };
        await openPicker(
          tester,
          script: script,
          overrides: _sources(),
          size: size.width > 1000
              ? const Size(1200, 700)
              : const Size(360, 640),
          textScale: 2,
        );
        await settle(tester);
        expect(find.text(long), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('animations off: the spinner is a still arc', (tester) async {
        final script = _script();
        script.gates['Song Singer'] = Completer<void>();
        await openPicker(
          tester,
          script: script,
          overrides: _sources(),
          size: size,
          disableAnimations: true,
        );
        expect(find.text('Searching LRCLIB…'), findsOneWidget);
        // A running spinner would never let the frames settle.
        await expectStill(tester);
      });

      group('length difference', () {
        testWidgets('"match" within 3 s, signed seconds in error beyond, '
            'nothing without a length', (tester) async {
          final script = SearchScript()
            ..answers['*'] = {
              'lrclib': results([
                candidate('lrclib', 'm0', length: 252),
                candidate('lrclib', 'm3', length: 255),
                candidate('lrclib', 'p4', length: 256),
                candidate('lrclib', 'n5', length: 247),
                candidate('lrclib', 'none', length: null),
              ]),
            };
          await openPicker(
            tester,
            script: script,
            overrides: _sources(),
            size: size,
          );
          await settle(tester);
          final scheme = Theme.of(tester.element(find.text('Choose lyrics')))
              .colorScheme;
          expect(find.text('match'), findsNWidgets(2));
          expect(_colorOf(tester, '+4 s'), scheme.error);
          expect(_colorOf(tester, '−5 s'), scheme.error);
          expect(find.text('+3 s'), findsNothing);
          expect(
            tester.widget<Text>(find.text('+4 s')).style?.fontWeight,
            FontWeight.w700,
          );
          expect(
            tester.widget<Text>(find.text('match').first).style?.color,
            scheme.primary,
          );
          expect(
            find.byTooltip(
              '4 seconds longer than the song: may be another version '
              '(live, remix…)',
            ),
            findsOneWidget,
          );
          expect(
            find.byTooltip(
              '5 seconds shorter than the song: may be another version '
              '(live, remix…)',
            ),
            findsOneWidget,
          );
          // Without a length of its own the result shows no difference.
          expect(find.text('Singer · Album'), findsOneWidget);
        });
      });
    });
  }
}
