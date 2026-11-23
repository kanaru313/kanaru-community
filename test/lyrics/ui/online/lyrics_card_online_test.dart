import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/domain/online/lookup_outcome.dart';
import 'package:kanaru/src/lyrics/domain/online/online_lyrics_ref.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_card.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../lyrics_ui_host.dart';
import 'online_ui_overrides.dart';
import '../lyrics_spinner_finders.dart';

Future<LyricsUiHost> _pump(
  WidgetTester tester,
  TrackLyrics lyrics, {
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  final host = LyricsUiHost(
    lyrics: lyrics,
    extra: onlineUiOverrides(
      sources: [lyricsSource('netease', name: 'NetEase')],
    ),
  );
  await host.pump(
    tester,
    const Padding(padding: EdgeInsets.all(16), child: LyricsCard(onOpen: null)),
    textScale: textScale,
    disableAnimations: disableAnimations,
  );
  return host;
}

void main() {
  testWidgets('online lyrics: the plugin icon and its name beside the title', (
    tester,
  ) async {
    await _pump(tester, LyricsShown(onlineLyrics()));
    expect(find.text('NetEase'), findsOneWidget);
    final avatar = tester.widget<KSourceAvatar>(find.byType(KSourceAvatar));
    expect(avatar.size, 16);
    expect(avatar.removed, isFalse);
    expect(find.text('Line 0'), findsNothing);
    expect(find.text('La la'), findsWidgets);
  });

  testWidgets('online lyrics of a removed plugin: grey initial, same name', (
    tester,
  ) async {
    await _pump(tester, LyricsShown(onlineLyrics(id: 'zing', name: 'ZingMP3')));
    expect(find.text('ZingMP3'), findsOneWidget);
    expect(
      tester.widget<KSourceAvatar>(find.byType(KSourceAvatar)).removed,
      isTrue,
    );
  });

  testWidgets('online lyrics: the card is named by title and plugin', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, LyricsShown(onlineLyrics()));
    expect(
      tester.getSemantics(find.byType(LyricsCard)).label,
      'Lyrics · NetEase',
    );
    handle.dispose();
  });

  testWidgets('local lyrics show no plugin icon', (tester) async {
    await _pump(tester, LyricsShown(syncedLyrics(3)));
    expect(find.byType(KSourceAvatar), findsNothing);
    expect(find.text('In tag'), findsOneWidget);
  });

  testWidgets('searching: a spinner and "Searching for lyrics…"', (
    tester,
  ) async {
    await _pump(tester, const LyricsSearching(2));
    expect(find.text('Searching for lyrics…'), findsOneWidget);
    expect(byLyricsSpinner(), findsOneWidget);
    expect(find.byType(KSourceAvatar), findsNothing);
  });

  testWidgets('searching with animations off: a still arc', (tester) async {
    await _pump(tester, const LyricsSearching(2), disableAnimations: true);
    expect(byLyricsSpinner(), findsOneWidget);
    await expectStill(tester);
  });

  testWidgets('failed: one line with the retry time, no spinner', (
    tester,
  ) async {
    await _pump(
      tester,
      LyricsLookupFailed(
        reason: LookupFailReason.network,
        asked: 1,
        retryAt: DateTime(2030, 1, 1, 21, 5),
      ),
    );
    expect(
      find.text('Couldn’t find lyrics · trying again at 9:05 PM'),
      findsOneWidget,
    );
    expect(byLyricsSpinner(), findsNothing);
  });

  testWidgets('failed with nothing scheduled: no time', (tester) async {
    await _pump(
      tester,
      const LyricsLookupFailed(reason: LookupFailReason.needsConfig, asked: 1),
    );
    expect(find.text('Couldn’t find lyrics'), findsOneWidget);
  });

  testWidgets('paused: until when', (tester) async {
    await _pump(tester, LyricsLookupPaused(DateTime(2030, 1, 1, 21, 5)));
    expect(find.text('Lyrics sources paused until 9:05 PM'), findsOneWidget);
  });

  for (final (lyrics, text) in <(TrackLyrics, String)>[
    (const LyricsNotFound(asked: 1, off: 0), 'Lyrics not found'),
    (
      const LyricsInstrumental(
        OnlineLyricsRef(
          providerId: 'netease',
          providerName: 'NetEase',
          remoteId: 'r',
          how: OnlineHow.auto,
        ),
      ),
      'Instrumental',
    ),
    (const LyricsNoSource(), 'No lyrics for this song'),
  ]) {
    testWidgets('${lyrics.runtimeType}: one status line', (tester) async {
      await _pump(tester, lyrics);
      expect(find.text(text), findsOneWidget);
    });
  }

  testWidgets('200 % text with a long plugin name does not overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      LyricsShown(
        onlineLyrics(name: 'Một nguồn lời có cái tên rất dài để thử cắt chữ'),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
