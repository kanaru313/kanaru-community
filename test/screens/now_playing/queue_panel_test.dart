import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/ui/queue/queue_header.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row.dart';
import 'package:kanaru/src/library/state/favorites_providers.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/screens/now_playing/ui/queue_host.dart';
import 'package:kanaru/src/screens/now_playing/ui/queue_panel.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../playback/support/ui_host.dart';
import '../../playback/ui/queue/queue_test_support.dart' show rowExtent;

class _FailingFavorites implements FavoritesController {
  @override
  Future<void> setFavorite(List<TrackId> tracks, bool favorite) async =>
      throw StateError('write failed');

  @override
  Future<void> toggle(TrackId track) async => throw StateError('write failed');
}

Future<void> _toggleHeart(WidgetTester tester, UiHost host) async {
  expect(find.byTooltip('Remove from favorites'), findsNothing);
  await host.tap(tester, find.byTooltip('Add to favorites').first);
  expect(find.byTooltip('Remove from favorites'), findsOneWidget);
  await host.tap(tester, find.byTooltip('Remove from favorites'));
  expect(find.byTooltip('Remove from favorites'), findsNothing);
}

Future<void> _failingToggle(
  WidgetTester tester,
  QueueHost hostKind,
  Size size,
) async {
  final host = await pumpWithPlayer(
    tester,
    QueuePanel(host: hostKind),
    size: size,
    overrides: [
      favoritesControllerProvider.overrideWithValue(_FailingFavorites()),
    ],
  );
  await host.tap(tester, find.byTooltip('Add to favorites').first);
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.text('Could not change favorites'), findsOneWidget);
}

void main() {
  group('sheet host', () {
    testWidgets('head: title and counts, Save (soon), more, close', (
      tester,
    ) async {
      var closed = 0;
      await pumpWithPlayer(
        tester,
        QueuePanel(host: QueueHost.sheet, onClose: () => closed++),
      );
      expect(find.text('Queue'), findsOneWidget);
      expect(find.textContaining('1/6'), findsOneWidget);
      final save = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('Save as playlist · Coming soon'),
          matching: find.byType(IconButton),
        ),
      );
      expect(save.onPressed, isNull);
      // Rows carry a ⋮ with the same tooltip: look inside the head menu only.
      expect(
        find.descendant(
          of: find.byType(QueueMoreMenu),
          matching: find.byTooltip('More'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(KIcons.collapse));
      expect(closed, 1);
    });

    testWidgets('footer holds Shuffle, Add tracks and Clean up only', (
      tester,
    ) async {
      await pumpWithPlayer(tester, const QueuePanel(host: QueueHost.sheet));
      expect(find.byIcon(KIcons.shuffle), findsOneWidget);
      expect(find.byIcon(KIcons.libraryAdd), findsOneWidget);
      expect(find.byIcon(KIcons.cleaning), findsOneWidget);
      // Save is in the head, once.
      expect(find.byIcon(KIcons.playlistAdd), findsOneWidget);
      final shuffle = tester.getTopLeft(find.byIcon(KIcons.shuffle)).dy;
      final firstRow = tester.getTopLeft(find.byType(QueueRow).first).dy;
      expect(shuffle, greaterThan(firstRow));
    });

    testWidgets('rows are mobile rows with the library ♥', (tester) async {
      await pumpWithPlayer(tester, const QueuePanel(host: QueueHost.sheet));
      expect(tester.getSize(find.byType(QueueRow).first).height, rowExtent());
      expect(find.byType(SongFavoriteButton), findsWidgets);
    });

    testWidgets('the ♥ toggles the favorite', (tester) async {
      final host = await pumpWithPlayer(
        tester,
        const QueuePanel(host: QueueHost.sheet),
      );
      await _toggleHeart(tester, host);
    });

    testWidgets('a failing toggle shows the toast', (tester) async {
      await _failingToggle(tester, QueueHost.sheet, const Size(400, 800));
    });
  });

  group('panel host', () {
    Future<UiHost> pump(WidgetTester tester) async {
      final host = await pumpWithPlayer(
        tester,
        const QueuePanel(host: QueueHost.panel),
        size: const Size(900, 800),
        play: false,
      );
      // Durations first, so the rows load them with their infos.
      await host.run(tester, () async {
        await host.h.db.customStatement(
          'UPDATE tracks SET duration_ms = 200000',
        );
        await host.h.play();
      });
      await host.letStreamsArrive(tester);
      return host;
    }

    testWidgets('head: counts left, four actions and more on the right', (
      tester,
    ) async {
      await pump(tester);
      expect(find.textContaining('6 tracks · '), findsOneWidget);
      for (final icon in [
        KIcons.shuffle,
        KIcons.libraryAdd,
        KIcons.cleaning,
        KIcons.playlistAdd,
        KIcons.moreVert,
      ]) {
        expect(find.byIcon(icon), findsWidgets, reason: '$icon');
      }
      final counts = tester.getTopLeft(find.textContaining('6 tracks')).dx;
      final shuffle = tester.getTopLeft(find.byIcon(KIcons.shuffle)).dx;
      expect(counts, lessThan(shuffle));
      expect(find.byIcon(KIcons.collapse), findsNothing);
    });

    testWidgets('rows are desktop rows with duration over ♥ and a menu', (
      tester,
    ) async {
      await pump(tester);
      expect(tester.getSize(find.byType(QueueRow).first).height, rowExtent());
      expect(find.byType(SongFavoriteButton), findsWidgets);
      final row = find.byType(QueueRow).first;
      final time = tester.getRect(
        find.descendant(
          of: row,
          matching: find.byWidgetPredicate(
            (w) => w is Text && RegExp(r'^\d+:\d\d$').hasMatch(w.data ?? ''),
          ),
        ),
      );
      final heart = tester.getRect(
        find.descendant(of: row, matching: find.byIcon(KIcons.heart)),
      );
      expect(time.bottom, lessThanOrEqualTo(heart.top + 1));
      expect(
        find.descendant(of: row, matching: find.byIcon(KIcons.moreVert)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.byIcon(KIcons.dragHandle)),
        findsOneWidget,
      );
    });

    testWidgets('the ♥ toggles the favorite', (tester) async {
      await _toggleHeart(tester, await pump(tester));
    });

    testWidgets('a failing toggle shows the toast', (tester) async {
      await _failingToggle(tester, QueueHost.panel, const Size(900, 800));
    });

    testWidgets('the cleanup dropdown opens downward', (tester) async {
      await pump(tester);
      final button = tester.getRect(find.byTooltip('Clean up'));
      await tester.tap(find.byTooltip('Clean up'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.getTopLeft(find.text('Remove from queue').first).dy,
        greaterThanOrEqualTo(button.bottom - 1),
      );
    });
  });
}
