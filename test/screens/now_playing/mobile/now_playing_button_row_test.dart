import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/state/playback_settings_providers.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/now_playing_button_row.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../playback/support/ui_host.dart';

void main() {
  // Tile i of the row: four equal tiles, 8 dp apart, the row's full height.
  Rect tile(WidgetTester tester, int i) {
    final row = tester.getRect(find.byType(NowPlayingButtonRow));
    final w = (row.width - 3 * 8) / 4;
    return Rect.fromLTWH(row.left + i * (w + 8), row.top, w, row.height);
  }

  Future<UiHost> open(WidgetTester tester, VoidCallback onQueue) =>
      pumpWithPlayer(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: NowPlayingButtonRow(onQueue: onQueue),
          ),
        ),
      );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(KMotion.press);
  }

  testWidgets('the whole tile is the button, corners and edges included', (
    tester,
  ) async {
    var queue = 0;
    await open(tester, () => queue++);
    final t = tile(tester, 3);
    expect(tester.getSize(find.byType(KIconButton).last), t.size);
    for (final p in [
      t.topLeft + const Offset(2, 2),
      t.topRight + const Offset(-2, 2),
      t.bottomLeft + const Offset(2, -2),
      t.bottomRight + const Offset(-2, -2),
      t.centerLeft + const Offset(2, 0),
      t.topCenter + const Offset(0, 2),
    ]) {
      await tester.tapAt(p);
      await settle(tester);
    }
    expect(queue, 6);
  });

  testWidgets('shuffle fires from the tile corners, one tooltip', (
    tester,
  ) async {
    final host = await open(tester, () {});
    final t = tile(tester, 0);
    expect(host.container.read(shuffleSettingProvider), isFalse);
    // The controller's work needs real time: tap in the real zone.
    Future<void> tapReal(Offset p) async {
      await tester.runAsync(() async {
        await tester.tapAt(p);
        await host.h.settle();
      });
      await tester.pump();
      await host.letStreamsArrive(tester);
      await settle(tester);
    }

    await tapReal(t.topLeft + const Offset(2, 2));
    expect(host.container.read(shuffleSettingProvider), isTrue);
    await tapReal(t.bottomRight + const Offset(-2, -2));
    expect(host.container.read(shuffleSettingProvider), isFalse);
    expect(
      find.byWidgetPredicate((w) => w is Tooltip && w.message == 'Shuffle'),
      findsOneWidget,
    );
  });

  testWidgets('repeat opens its menu from a tile corner', (tester) async {
    await open(tester, () {});
    await tester.tapAt(tile(tester, 1).bottomLeft + const Offset(2, -2));
    await tester.pumpAndSettle();
    expect(find.text('Repeat the whole queue'), findsOneWidget);
  });

  testWidgets('Ask AI stays inert over the whole tile', (tester) async {
    var queue = 0;
    await open(tester, () => queue++);
    final t = tile(tester, 2);
    expect(tester.getSize(find.byType(KIconButton).at(2)), t.size);
    await tester.tapAt(t.center);
    await tester.tapAt(t.topLeft + const Offset(2, 2));
    await tester.pump();
    expect(queue, 0);
  });
}
