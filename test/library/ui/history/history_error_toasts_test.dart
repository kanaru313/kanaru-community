import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru/src/library/ui/history/history_hero.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/fake_playback_commands.dart';
import '../../../support/icon_button_finders.dart';
import '../menus/menu_pump.dart';
import '../../history/state/fake_history_store.dart' show info;
import 'history_page_harness.dart';

class _BrokenPlayer extends FakePlaybackCommands {
  @override
  Future<void> playTracks(
    List<TrackId> tracks, {
    int startIndex = 0,
    bool shuffle = false,
    required PlayContext context,
  }) async => throw StateError('no player');
}

Future<void> _openPageMenu(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(HistoryHero),
      matching: byIconButton(l10nOf(tester).libraryMenuMore),
    ),
  );
  await pumpMenu(tester);
}

void main() {
  testWidgets('playing a day that the player refuses says so', (tester) async {
    await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([2, 3]),
      },
      playbackCommands: _BrokenPlayer(),
    );
    final l10n = l10nOf(tester);
    await openDayMenu(tester, l10n.historyDayYesterday);
    await tester.tap(find.text(l10n.historyMenuPlayDay));
    await pumpMenu(tester);
    expect(find.text(l10n.historyPlayFailed), findsOneWidget);
  });

  testWidgets('"Play all" with nothing that can play says so', (tester) async {
    // The store lists no played song, so the page menu has nothing to queue.
    final h = await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([2]),
      },
    );
    h.store.playedTracks = [];
    final l10n = l10nOf(tester);
    await _openPageMenu(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(l10n.libraryPlayAll),
      ),
    );
    await pumpMenu(tester);
    expect(find.text(l10n.historyPlayFailed), findsOneWidget);
    expect(h.playback.calls, isEmpty);
  });

  testWidgets('"Add to playlist" with nothing that can play says so', (
    tester,
  ) async {
    final h = await pumpHistoryPage(
      tester,
      byYear: {
        2026: playsOverDays([2]),
      },
    );
    h.store.playedTracks = [];
    final l10n = l10nOf(tester);
    await _openPageMenu(tester);
    await tester.tap(find.text(l10n.libraryMenuAddToPlaylist));
    await pumpMenu(tester);
    expect(find.text(l10n.historyNothingToAdd), findsOneWidget);
  });

  testWidgets('a play the store cannot remove shows the error toast', (
    tester,
  ) async {
    final gone = info(9, title: 'Gone', status: TrackAvailability.missing);
    final h = await pumpHistoryPage(
      tester,
      byYear: {
        2026: [playAt(1, DateTime(2026, 11, 20, 9), uid: 'p1', track: gone)],
      },
    );
    h.store.removeError = StateError('disk');
    final l10n = l10nOf(tester);
    final row = find.ancestor(
      of: find.text('Gone'),
      matching: find.byType(KMediaCard),
    );
    await tester.tap(
      find.descendant(of: row, matching: byIconButton(l10n.libraryMenuMore)),
    );
    await pumpMenu(tester);
    await tester.tap(find.text(l10n.historyMenuRemovePlay));
    await pumpMenu(tester);
    expect(find.text(l10n.historyRemoveFailed), findsOneWidget);
    expect(find.textContaining('Đã xoá'), findsNothing);
  });
}
