import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/domain/online/lookup_outcome.dart';
import 'package:kanaru/src/lyrics/domain/online/online_lyrics_ref.dart';
import 'package:kanaru/src/lyrics/ui/song_info/lyrics_section_skeleton.dart';
import 'package:kanaru/src/lyrics/ui/song_info/lyrics_preview_block.dart';
import 'package:kanaru/src/playback/domain/playable.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../support/memory_settings_store.dart';

import 'song_info_lyrics_host.dart';

const _ref = OnlineLyricsRef(
  providerId: 'p1',
  providerName: 'LRCLIB',
  remoteId: 'r',
  how: OnlineHow.auto,
);

void main() {
  Future<void> show(
    WidgetTester tester,
    TrackLyrics state, {
    String? lrc,
    double textScale = 1,
    bool still = false,
  }) => SectionHost(
    state,
    lrc: lrc,
  ).pump(tester, textScale: textScale, still: still);

  testWidgets('tag lyrics: source row and the first five lines', (
    tester,
  ) async {
    await show(tester, LyricsShown(synced(8)));
    expect(find.text('Lyrics'), findsOneWidget);
    expect(find.text("In the file's tags"), findsOneWidget);
    expect(find.text('Synced'), findsOneWidget);
    expect(find.text('8 lines'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      expect(find.text('Line $i'), findsOneWidget);
    }
    expect(find.text('Line 5'), findsNothing);
    expect(find.text('0:00'), findsNothing, reason: 'no timestamps');
    expect(find.text('See all lyrics ›'), findsOneWidget);
  });

  testWidgets('one line says "1 line"', (tester) async {
    await show(tester, LyricsShown(plain(1)));
    expect(find.text('1 line'), findsOneWidget);
    expect(find.text('Plain'), findsOneWidget);
  });

  testWidgets('.lrc: the file name is in the source row', (tester) async {
    await show(tester, LyricsShown(plain(3)), lrc: 'sub/01 - Song.lrc');
    expect(
      find.text('.lrc file next to the song · 01 - Song.lrc'),
      findsOneWidget,
    );
  });

  testWidgets('.lrc without a known locator keeps a bare label', (
    tester,
  ) async {
    await show(tester, LyricsShown(plain(3)));
    expect(find.text('.lrc file next to the song'), findsOneWidget);
  });

  testWidgets('kept online copy names its plugin', (tester) async {
    await show(tester, LyricsShown(online(OnlineHow.kept)));
    expect(find.text('Kept online copy · NetEase'), findsOneWidget);
    expect(find.text('See all lyrics ›'), findsOneWidget);
  });

  testWidgets('auto-found online copy uses the lyrics area wording', (
    tester,
  ) async {
    await show(tester, LyricsShown(online(OnlineHow.auto)));
    // `onlineRowSubtitle`: plugin · kind · found automatically.
    expect(find.text('NetEase · Synced · found automatically'), findsOneWidget);
  });

  testWidgets('instrumental: the area wording and no preview', (tester) async {
    await show(tester, const LyricsInstrumental(_ref));
    expect(
      find.text('LRCLIB · Instrumental · found automatically'),
      findsOneWidget,
    );
    expect(find.text('See all lyrics ›'), findsNothing);
  });

  testWidgets('off with nothing available: no preview', (tester) async {
    await show(tester, const LyricsOff(null));
    expect(find.text('Lyrics off'), findsOneWidget);
    expect(find.text('See all lyrics ›'), findsNothing);
  });

  testWidgets('off with lyrics available: still previews them', (tester) async {
    await show(tester, LyricsOff(synced(2)));
    expect(find.text('Lyrics off'), findsOneWidget);
    expect(find.text('See all lyrics ›'), findsOneWidget);
  });

  final empty = <String, TrackLyrics>{
    'none': const LyricsNone(),
    'not playing': const LyricsNone(reason: LyricsNoneReason.notPlaying),
    'searching': const LyricsSearching(2),
    'not found': const LyricsNotFound(asked: 2, off: 0),
    'no source': const LyricsNoSource(),
    'failed': const LyricsLookupFailed(
      reason: LookupFailReason.network,
      asked: 2,
    ),
    'paused': LyricsLookupPaused(DateTime.utc(2026, 11, 24)),
  };
  for (final e in empty.entries) {
    testWidgets('${e.key}: "No lyrics yet" and the way to add some', (
      tester,
    ) async {
      await show(tester, e.value);
      expect(find.text('No lyrics yet'), findsOneWidget);
      expect(
        find.text('Add lyrics from the song menu › Lyrics source'),
        findsOneWidget,
      );
      expect(find.text('See all lyrics ›'), findsNothing);
      // No search button of any kind.
      expect(find.textContaining('Find'), findsNothing);
    });
  }

  testWidgets('unavailable with the eye off draws nothing', (tester) async {
    await show(tester, const LyricsUnavailable(UnplayableReason.missing));
    expect(find.text('Lyrics'), findsNothing);
    expect(find.text('No lyrics yet'), findsNothing);
  });

  testWidgets('unavailable with the eye on says it cannot read them', (
    tester,
  ) async {
    final settings = MemorySettingsStore();
    await settings.write('library.song_info_show_empty', true);
    await SectionHost(
      const LyricsUnavailable(UnplayableReason.missing),
      settings: settings,
    ).pump(tester);
    expect(find.text('Lyrics'), findsOneWidget);
    expect(find.text("Couldn't read the lyrics"), findsOneWidget);
    expect(find.text('No lyrics yet'), findsNothing);
  });

  testWidgets('only the .lrc source row offers to copy', (tester) async {
    await show(tester, LyricsShown(synced(3)));
    final tag = tester.widget<KInfoRow>(find.byType(KInfoRow));
    expect(tag.value, isNull, reason: 'a widget value is never copied');
  });

  testWidgets('the .lrc source row copies its file name', (tester) async {
    await show(tester, LyricsShown(plain(3)), lrc: 'a/Song.lrc');
    final row = tester.widget<KInfoRow>(find.byType(KInfoRow));
    expect(row.copyText, 'Song.lrc');
  });

  // The skeleton is hidden from screen readers, so its type is the proof.
  testWidgets('loading: the group with a skeleton', (tester) async {
    await show(tester, const LyricsLoading());
    expect(find.text('Lyrics'), findsOneWidget);
    expect(find.byType(LyricsSectionSkeleton), findsOneWidget);
    expect(find.text('No lyrics yet'), findsNothing);
  });

  testWidgets('loading with animations off is still', (tester) async {
    await show(tester, const LyricsLoading(), still: true);
    expect(find.byType(LyricsSectionSkeleton), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the preview is one button that says what it opens', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await show(tester, LyricsShown(synced(8)));
    expect(
      tester.getSemantics(find.byType(LyricsPreviewBlock)),
      isSemantics(
        isButton: true,
        label: 'Synced, 8 lines, See all lyrics',
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('text at 200 % does not overflow', (tester) async {
    await show(tester, LyricsShown(synced(8)), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text('See all lyrics ›'), findsOneWidget);
  });
}
