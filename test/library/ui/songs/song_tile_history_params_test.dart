import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/ui/menus/more_button.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../menus/menu_fixtures.dart';
import '../support/library_harness.dart';

/// One [SongTile] of a real harness container (database, player fakes).
Future<void> _pump(
  WidgetTester tester, {
  TrackInfo? info,
  String? detailLine,
  int? rank,
  bool showNumber = false,
  VoidCallback? onDelete,
  bool unavailable = false,
  VoidCallback? onUnavailableTap,
  Future<void> Function({required bool viaKeyboard})? onMenu,
}) async {
  final h = await pumpLibrary(
    tester,
    initial: '/library/songs',
    width: 1400,
    height: 800,
  );
  final track = info ?? trackInfo();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SongTile(
            info: track,
            index: 0,
            ids: [track.id],
            playContext: const PlayContext(PlayContextKind.songs),
            showNumber: showNumber,
            detailLine: detailLine,
            rank: rank,
            onDelete: onDelete,
            unavailable: unavailable,
            onUnavailableTap: onUnavailableTap,
            onMenu: onMenu,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Fill colour of the number / rank badge.
Color? _badgeFill(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byKey(songTileBadgeKey),
      matching: find.byType(DecoratedBox),
    ),
  );
  return (box.decoration as BoxDecoration).color;
}

void main() {
  group('detailLine', () {
    testWidgets('replaces the album line', (tester) async {
      await _pump(tester, detailLine: '21:42 · play #6');
      expect(find.text('21:42 · play #6'), findsOneWidget);
      expect(find.textContaining('Blue'), findsNothing);
    });

    testWidgets('without it the album line stays', (tester) async {
      await _pump(tester);
      expect(find.textContaining('Blue'), findsOneWidget);
    });

    testWidgets('replaces "not in library" on a missing row', (tester) async {
      await _pump(tester, unavailable: true, detailLine: '21:42 · gone');
      expect(find.text('21:42 · gone'), findsOneWidget);
    });
  });

  group('rank', () {
    testWidgets('shows a badge; the top three are emphasised', (tester) async {
      await _pump(tester, rank: 3);
      expect(
        find.descendant(
          of: find.byKey(songTileBadgeKey),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      final scheme = Theme.of(tester.element(find.byType(SongTile)))
          .colorScheme;
      expect(_badgeFill(tester), scheme.primary);
    });

    testWidgets('an unavailable row keeps its rank badge', (tester) async {
      await _pump(tester, rank: 2, unavailable: true);
      expect(
        find.descendant(
          of: find.byKey(songTileBadgeKey),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a lower rank has the quiet badge', (tester) async {
      await _pump(tester, rank: 4);
      final scheme = Theme.of(tester.element(find.byType(SongTile)))
          .colorScheme;
      expect(_badgeFill(tester), isNot(scheme.primary));
      expect(
        find.descendant(
          of: find.byKey(songTileBadgeKey),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('replaces the track number badge', (tester) async {
      await _pump(
        tester,
        info: TrackInfo(
          id: trackInfo().id,
          title: 'So What',
          status: TrackAvailability.present,
          relPath: 'a.flac',
          trackNo: 9,
        ),
        showNumber: true,
        rank: 1,
      );
      expect(find.byKey(songTileBadgeKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(songTileBadgeKey),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(songTileBadgeKey),
          matching: find.text('9'),
        ),
        findsNothing,
      );
    });

    testWidgets('no rank, no number: no badge', (tester) async {
      await _pump(tester);
      expect(find.byKey(songTileBadgeKey), findsNothing);
    });
  });

  group('onDelete', () {
    testWidgets('the Delete key on the focused row calls it once', (
      tester,
    ) async {
      var calls = 0;
      await _pump(tester, onDelete: () => calls++);
      Focus.of(tester.element(find.text('So What'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      expect(calls, 1);
    });

    testWidgets('without it the key does nothing', (tester) async {
      await _pump(tester);
      Focus.of(tester.element(find.text('So What'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      expect(tester.takeException(), isNull);
    });
  });

  group('onUnavailableTap', () {
    testWidgets('a tap on a missing row calls it', (tester) async {
      var taps = 0;
      await _pump(tester, unavailable: true, onUnavailableTap: () => taps++);
      await tester.tap(find.text('So What'));
      expect(taps, 1);
    });

    testWidgets('with a menu of its own the missing row has a ⋮', (
      tester,
    ) async {
      await _pump(
        tester,
        unavailable: true,
        onUnavailableTap: () {},
        onMenu: ({required viaKeyboard}) async {},
      );
      expect(find.byType(LibraryMoreButton), findsOneWidget);
    });

    testWidgets('without a menu the missing row has none', (tester) async {
      await _pump(tester, unavailable: true, onUnavailableTap: () {});
      expect(find.byType(LibraryMoreButton), findsNothing);
    });

    testWidgets('a missing row that answers nothing stays inert', (
      tester,
    ) async {
      await _pump(
        tester,
        unavailable: true,
        onMenu: ({required viaKeyboard}) async {},
      );
      expect(find.byType(LibraryMoreButton), findsNothing);
    });
  });
}
