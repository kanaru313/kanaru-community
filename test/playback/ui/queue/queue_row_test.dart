import 'dart:async';

import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/media/domain/track_lines.dart';
import 'package:kanaru/src/playback/ui/queue/queue_list.dart';
import 'package:kanaru/src/playback/ui/queue/queue_locate_button.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row_hooks.dart';
import 'package:kanaru/src/playback/ui/track_cover.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/ui_host.dart';
import 'queue_test_support.dart';

const _desktopWindow = Size(1280, 800);

/// One call of the row menu hook.
typedef _MenuCall = ({Offset? at, bool viaKeyboard});

/// The card's own background of [row] (the Material that paints it).
Color? _background(WidgetTester tester, Finder row) {
  final card = find.descendant(of: row, matching: find.byType(KMediaCard));
  final material = tester.widget<Material>(
    find.descendant(of: card, matching: find.byType(Material)).first,
  );
  return material.color;
}

Color _iconColor(WidgetTester tester, Finder icon) =>
    IconTheme.of(tester.element(icon.first)).color!;

void main() {
  final menuCalls = <_MenuCall>[];
  setUp(menuCalls.clear);

  QueueList list(QueueRowSize size, {QueueRowFavorite? favorite}) => QueueList(
    size: size,
    favorite: favorite,
    menu: (context, item, info, at, {viaKeyboard = false}) =>
        menuCalls.add((at: at, viaKeyboard: viaKeyboard)),
  );

  Future<void> pump(
    WidgetTester tester, {
    bool playing = true,
    QueueRowSize size = QueueRowSize.mobile,
    Size? window,
    QueueRowFavorite? favorite,
    ValueNotifier<double>? textScale,
    CountingLoader? loader,
    int rows = 6,
    int current = 2,
  }) => pumpFakeQueue(
    tester,
    list(size, favorite: favorite),
    view: fakeView(rows, current: current),
    playing: playing,
    size: window ?? const Size(400, 800),
    textScale: textScale,
    loader: loader,
  );

  Rect rectIn(WidgetTester tester, Finder row, Finder what) =>
      tester.getRect(find.descendant(of: row, matching: what).first);

  group('layout', () {
    testWidgets('desktop: handle left of the cover, ⋮ visible, flat', (
      tester,
    ) async {
      await pump(tester, size: QueueRowSize.desktop, window: _desktopWindow);
      final row = find.byType(QueueRow).first;
      final handle = rectIn(tester, row, find.byIcon(KIcons.dragHandle));
      final cover = rectIn(tester, row, find.byType(TrackCover));
      final more = rectIn(tester, row, find.byIcon(KIcons.moreVert));
      expect(handle.right, lessThanOrEqualTo(cover.left));
      // The handle slot keeps the default prefix width.
      final slot = find.ancestor(
        of: find.byIcon(KIcons.dragHandle).first,
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == KMediaCard.coverSize,
        ),
      );
      expect(tester.getSize(slot.first).width, KMediaCard.prefixWidth);
      expect(KMediaCard.prefixWidth, 40);
      expect(more.left, greaterThan(cover.right));
      // Visible without hover: not wrapped in a transparent AnimatedOpacity
      // and a pointer at its centre reaches it.
      expect(
        find.descendant(of: row, matching: find.byType(AnimatedOpacity)),
        findsNothing,
      );
      expect(
        find
            .descendant(of: row, matching: find.byIcon(KIcons.moreVert))
            .hitTestable(),
        findsOneWidget,
      );
      expect(find.text('3:20'), findsWidgets);
    });

    testWidgets('desktop: the host favourite widget sits under the duration', (
      tester,
    ) async {
      await pump(
        tester,
        size: QueueRowSize.desktop,
        window: _desktopWindow,
        favorite: (context, item) => IconButton(
          iconSize: 20,
          onPressed: () {},
          icon: const Icon(KIcons.heart),
        ),
      );
      final row = find.byType(QueueRow).first;
      final heart = rectIn(tester, row, find.byIcon(KIcons.heart));
      final time = rectIn(tester, row, find.text('3:20'));
      expect(time.bottom, lessThanOrEqualTo(heart.top + 1));
      expect(heart.center.dx, closeTo(time.center.dx, 30));
    });

    testWidgets('mobile: cover, duration, handle, ⋮ from left to right', (
      tester,
    ) async {
      await pump(tester);
      final row = find.byType(QueueRow).first;
      final cover = rectIn(tester, row, find.byType(TrackCover));
      final time = rectIn(tester, row, find.text('3:20'));
      final handle = rectIn(
        tester,
        row,
        find.byType(ReorderableDragStartListener),
      );
      final more = rectIn(tester, row, find.byIcon(KIcons.moreVert));
      expect(cover.right, lessThan(time.left));
      expect(time.right, lessThanOrEqualTo(handle.left));
      expect(handle.right, lessThanOrEqualTo(more.left));
      expect(handle.size, const Size.square(KLayout.minTarget));
    });

    testWidgets('flat on both shells: no radius, the tint spans the row', (
      tester,
    ) async {
      for (final (size, window) in [
        (QueueRowSize.mobile, const Size(400, 800)),
        (QueueRowSize.desktop, _desktopWindow),
      ]) {
        await pump(tester, size: size, window: window);
        final row = find.byType(QueueRow).at(2);
        final card = find.descendant(
          of: row,
          matching: find.byType(KMediaCard),
        );
        final material = tester.widget<Material>(
          find.descendant(of: card, matching: find.byType(Material)).first,
        );
        expect(
          (material.shape! as RoundedRectangleBorder).borderRadius,
          BorderRadius.zero,
        );
        final tinted = find.descendant(
          of: card,
          matching: find.byWidgetPredicate(
            (w) => w is Material && w.color == material.color,
          ),
        );
        expect(
          tester.getSize(tinted.first).width,
          tester.getSize(row).width,
          reason: '$size',
        );
      }
    });
  });

  group('state', () {
    testWidgets('current row: primaryContainer, equalizer, card ink', (
      tester,
    ) async {
      await pump(tester);
      final scheme = Theme.of(tester.element(find.byType(QueueList)))
          .colorScheme;
      final rows = find.byType(QueueRow);
      expect(_background(tester, rows.at(2)), scheme.primaryContainer);
      expect(_background(tester, rows.at(3)), Colors.transparent);
      expect(
        find.descendant(of: rows.at(2), matching: find.byType(KEqualizerIcon)),
        findsOneWidget,
      );
      expect(find.byType(KEqualizerIcon), findsOneWidget);
      expect(
        tester.widget<KEqualizerIcon>(find.byType(KEqualizerIcon)).playing,
        isTrue,
      );
      final soft = scheme.onPrimaryContainer.withValues(alpha: 0.8);
      final handle = find.descendant(
        of: rows.at(2),
        matching: find.byIcon(KIcons.dragHandle),
      );
      final more = find.descendant(
        of: rows.at(2),
        matching: find.byIcon(KIcons.moreVert),
      );
      expect(_iconColor(tester, handle), soft);
      final button = tester.widget<IconButton>(
        find.ancestor(of: more, matching: find.byType(IconButton)).first,
      );
      expect(
        IconButtonTheme.of(tester.element(more)).style?.foregroundColor
            ?.resolve({}),
        soft,
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('a paused current row shows the pause glyph', (tester) async {
      await pump(tester, playing: false);
      expect(
        tester.widget<KEqualizerIcon>(find.byType(KEqualizerIcon)).playing,
        isFalse,
      );
      expect(find.byIcon(KIcons.pause), findsOneWidget);
    });

    testWidgets('played rows are at half opacity, the others are not', (
      tester,
    ) async {
      await pump(tester);
      double opacityOf(int i) {
        final o = find.descendant(
          of: find.byType(QueueRow).at(i),
          matching: find.byType(Opacity),
        );
        return tester.widget<Opacity>(o.first).opacity;
      }

      expect(opacityOf(0), 0.5);
      expect(opacityOf(1), 0.5);
      expect(opacityOf(2), 1);
      expect(opacityOf(4), 1);
    });

    testWidgets('a row without its info is a skeleton of the same height', (
      tester,
    ) async {
      final never = _NeverLoader();
      await pump(tester, loader: never);
      final card = tester.widget<KMediaCard>(
        find.descendant(
          of: find.byType(QueueRow).first,
          matching: find.byType(KMediaCard),
        ),
      );
      expect(card.loading, isTrue);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(QueueRow).first).height, rowExtent());
    });
  });

  group('handle and menu', () {
    testWidgets('a tap on the handle does not play the row', (tester) async {
      final host = await pumpWithPlayer(tester, list(QueueRowSize.mobile));
      final entries = [for (final i in host.h.c.queueState.items) i.entryId];
      final before = host.h.engine.loads.length;
      await host.tap(
        tester,
        find.descendant(
          of: find.byType(QueueRow).at(3),
          matching: find.byType(ReorderableDragStartListener),
        ),
      );
      expect(host.h.c.queueState.currentItem!.entryId, entries[0]);
      expect(host.h.engine.loads.length, before);
      expect(menuCalls, isEmpty);
    });

    testWidgets('hold the handle, then move: the row drags and reorders', (
      tester,
    ) async {
      final host = await pumpWithPlayer(tester, list(QueueRowSize.mobile));
      final before = [for (final i in host.h.c.queueState.items) i.entryId];
      final handle = find.descendant(
        of: find.byType(QueueRow).at(3),
        matching: find.byType(ReorderableDragStartListener),
      );
      // The drop starts controller work: run it in the real zone.
      await tester.runAsync(() async {
        final g = await tester.startGesture(tester.getCenter(handle));
        await tester.pump(const Duration(milliseconds: 600));
        for (var i = 0; i < 10; i++) {
          await g.moveBy(Offset(0, -rowExtent() / 5));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await g.up();
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await host.h.settle();
      });
      await tester.pump();
      await host.letStreamsArrive(tester);
      expect(menuCalls, isEmpty);
      final after = [for (final i in host.h.c.queueState.items) i.entryId];
      expect(after, [
        before[0],
        before[3],
        before[1],
        before[2],
        before[4],
        before[5],
      ]);
    });

    testWidgets('the mobile row exposes a long-press semantics action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      final node = tester.getSemantics(find.text('Song 3'));
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.longPress),
        isTrue,
      );
      tester.semantics.performAction(
        find.semantics.byPredicate((n) => n.id == node.id),
        SemanticsAction.longPress,
      );
      await tester.pump();
      expect(menuCalls, hasLength(1));
      handle.dispose();
    });

    testWidgets('a long press on the row (mobile) opens the menu', (
      tester,
    ) async {
      await pump(tester);
      await tester.longPress(find.text('Song 3'));
      expect(menuCalls, hasLength(1));
      expect(menuCalls.single.at, isNotNull);
      expect(menuCalls.single.viaKeyboard, isFalse);
    });

    testWidgets('a long press on the handle does not open the menu', (
      tester,
    ) async {
      await pump(tester);
      await tester.longPress(
        find.descendant(
          of: find.byType(QueueRow).at(3),
          matching: find.byType(ReorderableDragStartListener),
        ),
      );
      expect(menuCalls, isEmpty);
    });

    testWidgets('⋮ opens the menu at the button', (tester) async {
      await pump(tester);
      final more = find.descendant(
        of: find.byType(QueueRow).at(3),
        matching: find.byIcon(KIcons.moreVert),
      );
      await tester.tap(more);
      expect(menuCalls.single.viaKeyboard, isFalse);
      expect(menuCalls.single.at, tester.getCenter(more));
    });

    testWidgets('Enter on the focused ⋮ opens the menu with viaKeyboard', (
      tester,
    ) async {
      await pump(tester, size: QueueRowSize.desktop, window: _desktopWindow);
      // Row card, then ⋮.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(menuCalls.single.viaKeyboard, isTrue);
    });
  });

  group('text scale', () {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('row height is the card extent at ×$scale', (tester) async {
        await pump(tester, textScale: ValueNotifier(scale));
        expect(
          tester.getSize(find.byType(QueueRow).first).height,
          rowExtent(scale),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('no overflow at ×2 on a 360 dp wide window', (tester) async {
      await pump(
        tester,
        window: const Size(360, 640),
        textScale: ValueNotifier(2),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a scale change re-anchors the list and loads the window', (
      tester,
    ) async {
      final scale = ValueNotifier<double>(1);
      final loader = CountingLoader();
      await pump(
        tester,
        textScale: scale,
        loader: loader,
        rows: 200,
        current: 100,
      );
      ScrollController controller() => tester
          .widget<ReorderableListView>(find.byType(ReorderableListView))
          .scrollController!;
      expect(controller().offset, queueOffsetFor(100, rowExtent()));
      scale.value = 2;
      await tester.pump();
      await tester.pump();
      expect(controller().offset, queueOffsetFor(100, rowExtent(2)));
      final first = tester.getTopLeft(find.byType(QueueRow).first).dy;
      expect(first, lessThan(rowExtent(2)));
      expect(loader.loaded, contains(const TrackId(100)));
      final ids = [
        for (final e in find.byType(QueueRow).evaluate())
          (e.widget as QueueRow).item.entryId,
      ];
      expect(ids, contains(101));

      // The locate button targets the right row at the new scale.
      controller().jumpTo(0);
      await tester.pump(const Duration(milliseconds: 500));
      final locate = find.descendant(
        of: find.byType(QueueLocateButton),
        matching: find.byType(IconButton),
      );
      expect(locate, findsOneWidget);
      await tester.tap(locate);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(controller().offset, queueOffsetFor(100, rowExtent(2)));
    });
  });

  group('lines', () {
    TrackInfo info({
      List<String> artists = const [],
      String? album,
      int? year,
    }) => TrackInfo(
      id: const TrackId(1),
      title: 't',
      artist: 'Solo',
      artists: artists,
      album: album,
      year: year,
      status: TrackAvailability.present,
      relPath: 'a.mp3',
    );

    test('the artist line joins all artists', () {
      expect(trackArtistLine(info(artists: ['A', 'B', 'C'])), 'A, B, C');
      expect(trackArtistLine(info()), 'Solo');
    });

    test('an empty album gives no leading separator', () {
      expect(trackAlbumLine(info(album: '')), '');
      expect(trackAlbumLine(info(album: 'Al', year: 2020)), 'Al • 2020');
    });
  });
}

/// A loader whose infos never arrive: rows stay in their skeleton.
class _NeverLoader extends CountingLoader {
  @override
  Future<List<TrackInfo>> call(List<TrackId> ids) =>
      Completer<List<TrackInfo>>().future;
}
