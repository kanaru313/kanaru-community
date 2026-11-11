import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row.dart';
import 'package:kanaru/src/screens/now_playing/ui/favorite_button.dart';
import 'package:kanaru/src/screens/now_playing/ui/queue_host.dart';
import 'package:kanaru/src/screens/now_playing/ui/queue_panel.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../playback/support/ui_host.dart';

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
      expect(find.byTooltip('More'), findsOneWidget);
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

    testWidgets('rows are mobile rows without ♥ or trailing', (tester) async {
      await pumpWithPlayer(tester, const QueuePanel(host: QueueHost.sheet));
      expect(tester.getSize(find.byType(QueueRow).first).height, 60);
      expect(find.byType(FavoriteButton), findsNothing);
    });
  });

  group('panel host', () {
    Future<void> pump(WidgetTester tester) => pumpWithPlayer(
      tester,
      const QueuePanel(host: QueueHost.panel),
      size: const Size(900, 800),
    );

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
      expect(tester.getSize(find.byType(QueueRow).first).height, 72);
      expect(find.byType(FavoriteButton), findsWidgets);
      final row = find.byType(QueueRow).first;
      expect(
        find.descendant(of: row, matching: find.byIcon(KIcons.moreVert)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.byIcon(KIcons.dragHandle)),
        findsOneWidget,
      );
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
