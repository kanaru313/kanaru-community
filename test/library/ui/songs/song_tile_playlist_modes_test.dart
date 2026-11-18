import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/state/favorites_providers.dart';
import 'package:kanaru/src/library/ui/menus/more_button.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/fake_playback_commands.dart';
import '../../../support/icon_button_finders.dart';
import '../menus/menu_fixtures.dart';

const _remove = 'Remove from playlist';

/// Waits for a menu that was asked for to have loaded. The test has no
/// database, so an attempt ends in the load-failed toast: its absence proves
/// no menu was asked for.
Future<void> _settleMenuAttempt(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

final _menuAttempted = find.text(AppLocalizationsEn().libraryMenuLoadFailed);

/// Focuses the row (it takes focus on click in edit mode) and presses the two
/// keyboard ways to open a context menu.
Future<void> _pressMenuKeys(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.f10);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
}

/// Counts removals; [result] is what the removal answers.
class _Removals {
  int calls = 0;
  bool result = true;
  Future<bool> call() async {
    calls++;
    return result;
  }
}

class _Harness {
  _Harness(this.container, this.playback);
  final ProviderContainer container;
  final FakePlaybackCommands playback;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required ValueNotifier<SongTileEdit?> edit,
  bool unavailable = false,
  VoidCallback? onRemove,
  Future<void> Function({required bool viaKeyboard})? onMenu,
  double width = 400,
  bool playing = false,
  bool markCurrent = true,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final playback = FakePlaybackCommands();
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playbackCommandsProvider.overrideWithValue(playback),
        favoriteTrackIdsProvider.overrideWith((ref) => Stream.value(const {})),
        isCurrentTrackProvider.overrideWith((ref, id) => playing),
      ],
      child: Builder(
        builder: (context) {
          container = ProviderScope.containerOf(context);
          return MaterialApp(
            theme: buildKanaruTheme(brightness: Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ValueListenableBuilder<SongTileEdit?>(
                valueListenable: edit,
                builder: (_, mode, _) => SongTile(
                  info: trackInfo(),
                  index: 0,
                  ids: [trackInfo().id],
                  playContext: const PlayContext(PlayContextKind.songs),
                  edit: mode,
                  unavailable: unavailable,
                  onRemove: onRemove,
                  onMenu: onMenu,
                  markCurrent: markCurrent,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.pump();
  return _Harness(container, playback);
}

SongTileEdit _edit(_Removals removals) => SongTileEdit(
  handle: const SizedBox(key: ValueKey('handle'), width: 24, height: 24),
  removeLabel: _remove,
  onRemove: removals.call,
);

KMediaCard _card(WidgetTester tester) =>
    tester.widget<KMediaCard>(find.byType(KMediaCard));

void main() {
  testWidgets('an ordinary row keeps heart, menu button, tap and selection', (
    tester,
  ) async {
    final h = await _pump(tester, edit: ValueNotifier(null));
    expect(find.byType(SongFavoriteButton), findsOneWidget);
    expect(find.byType(LibraryMoreButton), findsOneWidget);
    expect(_card(tester).missing, isFalse);
    expect(_card(tester).editing, isFalse);

    await tester.tap(find.byType(KMediaCard));
    await tester.pump();
    expect(h.playback.calls, hasLength(1));
  });

  group('edit mode', () {
    testWidgets('mobile: handle, no heart, menu, tap, long press, ✕', (
      tester,
    ) async {
      final removals = _Removals();
      final h = await _pump(tester, edit: ValueNotifier(_edit(removals)));
      expect(find.byKey(const ValueKey('handle')), findsOneWidget);
      expect(find.byType(SongFavoriteButton), findsNothing);
      expect(find.byType(LibraryMoreButton), findsNothing);
      expect(byIconButton(_remove), findsNothing);
      expect(_card(tester).editing, isTrue);

      await tester.tap(find.byType(KMediaCard));
      await tester.longPress(find.byType(KMediaCard));
      await tester.pump();
      expect(h.playback.calls, isEmpty);
      expect(h.container.read(librarySelectionProvider).isEmpty, isTrue);
      expect(removals.calls, 0);
    });

    testWidgets('a swipe either way past 70 % removes; less springs back', (
      tester,
    ) async {
      final removals = _Removals();
      await _pump(tester, edit: ValueNotifier(_edit(removals)));
      final card = find.byType(KMediaCard);
      final home = tester.getTopLeft(card);

      await tester.drag(card, const Offset(-120, 0));
      await tester.pumpAndSettle();
      expect(removals.calls, 0);
      expect(tester.getTopLeft(card), home);

      await tester.drag(card, const Offset(-340, 0));
      await tester.pumpAndSettle();
      expect(removals.calls, 1);
    });

    testWidgets('a swipe right removes too; a false answer springs back', (
      tester,
    ) async {
      final removals = _Removals()..result = false;
      await _pump(tester, edit: ValueNotifier(_edit(removals)));
      final card = find.byType(KMediaCard);
      final home = tester.getTopLeft(card);

      await tester.drag(card, const Offset(340, 0));
      await tester.pumpAndSettle();
      expect(removals.calls, 1);
      expect(tester.getTopLeft(card), home);
    });

    testWidgets('the remove action is exposed to screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, edit: ValueNotifier(_edit(_Removals())));
      final labels = [
        for (final id
            in tester
                    .getSemantics(find.byType(KMediaCard))
                    .getSemanticsData()
                    .customSemanticsActionIds ??
                const <int>[])
          CustomSemanticsAction.getAction(id)?.label,
      ];
      expect(labels, contains(_remove));
      handle.dispose();
    });

    testWidgets('desktop: ✕ with a tooltip and the Delete key remove', (
      tester,
    ) async {
      final removals = _Removals();
      await _pump(tester, edit: ValueNotifier(_edit(removals)), width: 1400);
      expect(find.byKey(const ValueKey('handle')), findsOneWidget);
      await tester.tap(byIconButton(_remove));
      await tester.pump();
      expect(removals.calls, 1);

      // Click focuses the row (it has no tap action), Delete removes.
      await tester.tap(find.byType(KMediaCard));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(removals.calls, 2);
    });

    for (final width in [400.0, 1400.0]) {
      testWidgets('right click, Menu key and Shift+F10 do nothing at width '
          '$width, even with a menu override', (tester) async {
        var opened = 0;
        await _pump(
          tester,
          edit: ValueNotifier(_edit(_Removals())),
          onMenu: ({required viaKeyboard}) async => opened++,
          width: width,
        );
        await tester.tap(find.byType(KMediaCard), buttons: kSecondaryButton);
        await tester.pump();
        await tester.tap(find.byType(KMediaCard));
        await tester.pump();
        await _pressMenuKeys(tester);
        expect(opened, 0);
      });

      testWidgets('no song menu is asked for in edit mode at width $width', (
        tester,
      ) async {
        await _pump(
          tester,
          edit: ValueNotifier(_edit(_Removals())),
          width: width,
        );
        await tester.tap(find.byType(KMediaCard), buttons: kSecondaryButton);
        await tester.tap(find.byType(KMediaCard));
        await tester.pump();
        await _pressMenuKeys(tester);
        await _settleMenuAttempt(tester);
        expect(_menuAttempted, findsNothing);
      });
    }

    testWidgets('control: an ordinary row does ask for the menu', (
      tester,
    ) async {
      await _pump(tester, edit: ValueNotifier(null), width: 1400);
      await tester.tap(find.byType(KMediaCard), buttons: kSecondaryButton);
      await _settleMenuAttempt(tester);
      expect(_menuAttempted, findsOneWidget);
    });

    testWidgets('a held Delete removes once', (tester) async {
      final gate = Completer<bool>();
      var calls = 0;
      final edit = SongTileEdit(
        handle: const SizedBox(),
        removeLabel: _remove,
        onRemove: () {
          calls++;
          return gate.future;
        },
      );
      await _pump(tester, edit: ValueNotifier(edit), width: 1400);
      await tester.tap(find.byType(KMediaCard));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.delete);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.delete);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.delete);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(calls, 1);
      gate.complete(true);
    });

    testWidgets('a double tap on ✕ removes once while it runs, and again '
        'after it ended', (tester) async {
      var gate = Completer<bool>();
      var calls = 0;
      final edit = SongTileEdit(
        handle: const SizedBox(),
        removeLabel: _remove,
        onRemove: () {
          calls++;
          return gate.future;
        },
      );
      await _pump(tester, edit: ValueNotifier(edit), width: 1400);
      await tester.tap(byIconButton(_remove));
      await tester.tap(byIconButton(_remove));
      await tester.pump();
      expect(calls, 1);

      gate.complete(false);
      await tester.pump();
      gate = Completer<bool>();
      await tester.tap(byIconButton(_remove));
      await tester.pump();
      expect(calls, 2);
      gate.complete(true);
    });

    testWidgets('a removal that throws is contained', (tester) async {
      final edit = SongTileEdit(
        handle: const SizedBox(),
        removeLabel: _remove,
        onRemove: () async => throw StateError('disk'),
      );
      await _pump(tester, edit: ValueNotifier(edit), width: 1400);
      await tester.tap(byIconButton(_remove));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('toggling edit mode keeps the row state (no remount)', (
      tester,
    ) async {
      final mode = ValueNotifier<SongTileEdit?>(null);
      await _pump(tester, edit: mode);
      final swipe = tester.state(find.byType(KSwipeActions));
      final card = tester.state(find.byType(KMediaCard));

      mode.value = _edit(_Removals());
      await tester.pump();
      expect(tester.state(find.byType(KSwipeActions)), same(swipe));
      expect(tester.state(find.byType(KMediaCard)), same(card));

      mode.value = null;
      await tester.pump();
      expect(tester.state(find.byType(KSwipeActions)), same(swipe));
      expect(tester.state(find.byType(KMediaCard)), same(card));
    });
  });

  group('markCurrent', () {
    testWidgets('the playing track is marked by default', (tester) async {
      await _pump(tester, edit: ValueNotifier(null), playing: true);
      expect(_card(tester).current, isTrue);
    });

    testWidgets('false: never the playing row', (tester) async {
      await _pump(
        tester,
        edit: ValueNotifier(null),
        playing: true,
        markCurrent: false,
      );
      expect(_card(tester).current, isFalse);
    });

    testWidgets('a missing row is never the playing row', (tester) async {
      await _pump(
        tester,
        edit: ValueNotifier(null),
        playing: true,
        unavailable: true,
      );
      expect(_card(tester).current, isFalse);
    });
  });

  group('missing row', () {
    testWidgets('mobile: not playable, no heart or menu, one ✕', (
      tester,
    ) async {
      var removed = 0;
      final h = await _pump(
        tester,
        edit: ValueNotifier(null),
        unavailable: true,
        onRemove: () => removed++,
      );
      expect(_card(tester).missing, isTrue);
      expect(find.text('Not in library'), findsOneWidget);
      expect(find.byType(SongFavoriteButton), findsNothing);
      expect(find.byType(LibraryMoreButton), findsNothing);

      await tester.tap(find.byType(KMediaCard));
      await tester.pump();
      expect(h.playback.calls, isEmpty);

      await tester.tap(byIconButton(_remove));
      await tester.pump();
      expect(removed, 1);
    });

    testWidgets('right click runs the menu override', (tester) async {
      var opened = 0;
      await _pump(
        tester,
        edit: ValueNotifier(null),
        unavailable: true,
        onMenu: ({required viaKeyboard}) async => opened++,
        width: 1400,
      );
      await tester.tap(find.byType(KMediaCard), buttons: kSecondaryButton);
      await tester.pump();
      expect(opened, 1);
    });

    testWidgets('no menu without an override: right click and swipes do '
        'nothing', (tester) async {
      final h = await _pump(
        tester,
        edit: ValueNotifier(null),
        unavailable: true,
        width: 1400,
      );
      await tester.tap(find.byType(KMediaCard), buttons: kSecondaryButton);
      await tester.drag(find.byType(KMediaCard), const Offset(-1300, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(KMediaCard), const Offset(1300, 0));
      await tester.pumpAndSettle();
      await _settleMenuAttempt(tester);
      expect(h.playback.calls, isEmpty);
      expect(_menuAttempted, findsNothing);
    });

    for (final width in [400.0, 1400.0]) {
      testWidgets('with edit mode: a single ✕, handle, width $width', (
        tester,
      ) async {
        final removals = _Removals();
        await _pump(
          tester,
          edit: ValueNotifier(_edit(removals)),
          unavailable: true,
          width: width,
        );
        expect(byIconButton(_remove), findsOneWidget);
        expect(find.byKey(const ValueKey('handle')), findsOneWidget);
        expect(_card(tester).missing, isTrue);
        expect(_card(tester).editing, isTrue);

        await tester.tap(byIconButton(_remove));
        await tester.pump();
        expect(removals.calls, 1);

        await tester.drag(find.byType(KMediaCard), Offset(-width * 0.9, 0));
        await tester.pumpAndSettle();
        expect(removals.calls, 2);
      });
    }
  });
}
