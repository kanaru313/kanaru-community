import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/l10n/gen/app_localizations_vi.dart';
import 'package:kanaru/src/playback/state/queue_totals_provider.dart';
import 'package:kanaru/src/playback/ui/queue/queue_header.dart';
import 'package:kanaru/src/screens/now_playing/ui/queue_host.dart';
import 'package:kanaru/src/screens/now_playing/ui/queue_panel.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/ui_host.dart';

void main() {
  test('remaining time reads as hours and minutes', () {
    final en = AppLocalizationsEn();
    final vi = AppLocalizationsVi();
    expect(formatRemaining(vi, const Duration(minutes: 65)), '1 giờ 5 phút');
    expect(formatRemaining(en, const Duration(minutes: 65)), '1 h 5 min');
    expect(formatRemaining(vi, const Duration(minutes: 42)), '42 phút');
    expect(formatRemaining(vi, const Duration(seconds: 20)), 'dưới 1 phút');
  });

  testWidgets('mobile counts: position/total · time left', (tester) async {
    await pumpWithPlayer(tester, const QueueCounts(mobile: true));
    expect(find.textContaining('1/6'), findsOneWidget);
  });

  testWidgets('panel counts: total · time left, position in the tooltip', (
    tester,
  ) async {
    await pumpWithPlayer(tester, const QueueCounts(mobile: false));
    expect(find.textContaining('6 tracks · '), findsOneWidget);
    expect(find.textContaining('playing'), findsNothing);
    expect(find.byTooltip('Playing track 1'), findsOneWidget);
  });

  testWidgets('the panel head fits its line in 420 dp with the longest time', (
    tester,
  ) async {
    await pumpWithPlayer(
      tester,
      const QueuePanel(host: QueueHost.panel),
      size: const Size(420, 700),
      overrides: [
        queueRemainingProvider.overrideWith(
          (ref) => Stream.value(const Duration(hours: 12, minutes: 59)),
        ),
      ],
    );
    expect(find.textContaining('12 h 59 min left'), findsOneWidget);
    // The test font is far wider than the app's, so the width cannot be
    // judged by clipping here. The head gives the line the room the 40 dp
    // buttons leave: 420 - 24 padding - 5 x 40 - 8 divider - 3 x 8 gaps =
    // 164 dp, about 26 characters at 12 sp in the app fonts.
    final room = tester.getSize(find.byType(QueueCounts)).width;
    expect(room, greaterThanOrEqualTo(164 - 1));
    expect(tester.getSize(find.byTooltip('Shuffle')).width, 40);
  });

  testWidgets('the head buttons keep 8 dp between them', (tester) async {
    await pumpWithPlayer(
      tester,
      const QueuePanel(host: QueueHost.panel),
      size: const Size(420, 700),
    );
    final shuffle = tester.getRect(find.byTooltip('Shuffle'));
    final add = tester.getRect(find.byTooltip('Add tracks · Coming soon'));
    expect(add.left - shuffle.right, greaterThanOrEqualTo(8));
  });

  testWidgets('a cut count line shows in full in the tooltip', (tester) async {
    await pumpWithPlayer(
      tester,
      const QueuePanel(host: QueueHost.panel),
      size: const Size(420, 700),
      overrides: [
        queueRemainingProvider.overrideWith(
          (ref) => Stream.value(const Duration(hours: 12, minutes: 59)),
        ),
      ],
    );
    // In the wide test font the line is cut: the tooltip repeats it.
    expect(
      find.byTooltip('6 tracks · 12 h 59 min left\nPlaying track 1'),
      findsOneWidget,
    );
  });

  testWidgets('the time left comes from the database sum, not row infos', (
    tester,
  ) async {
    await pumpWithPlayer(tester, const QueueCounts(mobile: true));
    // Harness tracks have no duration: five upcoming entries add up to zero.
    expect(find.textContaining('left'), findsOneWidget);
    expect(find.textContaining('under 1 min'), findsOneWidget);
  });

  testWidgets('nothing shows for an empty queue', (tester) async {
    await pumpWithPlayer(
      tester,
      const Align(child: QueueCounts(mobile: true)),
      play: false,
    );
    expect(find.textContaining('/'), findsNothing);
  });
}
