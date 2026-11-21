import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';
import 'package:kanaru/src/library/state/history/local_day_provider.dart';
import 'package:kanaru/src/library/ui/most_played/most_played_page.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';

import '../../history/state/fake_history_store.dart';
import '../history/history_page_harness.dart';

export '../history/history_page_harness.dart' show HistoryHarness, testToday;

/// One ranked song: [id] at rank [rank] with [count] plays.
TopEntry topEntry(
  int rank, {
  int? id,
  int count = 1,
  String? title,
  TrackInfo? track,
}) => TopEntry(
  rank: rank,
  track: track ?? info(id ?? rank, title: title ?? 'Song ${id ?? rank}'),
  count: count,
  lastPlayedAt: DateTime(2026, 11, 19).millisecondsSinceEpoch,
);

/// A scripted [MostPlayed] of [entries] (totals default from them).
MostPlayed topList(List<TopEntry> entries, {int? songs, int? plays}) =>
    MostPlayed(
      entries: entries,
      songs: songs ?? entries.length,
      plays: plays ?? entries.fold(0, (sum, e) => sum + e.count),
    );

/// A song with an album and a year, for the third line.
TrackInfo albumSong(int id, String title, String album, int year) => TrackInfo(
  id: TrackId(id),
  title: title,
  album: album,
  year: year,
  status: TrackAvailability.present,
  relPath: 't$id.flac',
);

/// Pumps the Most played page over a scripted store: [top] is what the list
/// reads, [hasPlays] whether any play exists at all (the range dialog's
/// bounds).
Future<HistoryHarness> pumpMostPlayed(
  WidgetTester tester, {
  MostPlayed? top,
  bool hasPlays = true,
  double width = 400,
  double height = 800,
  double textScale = 1,
  Locale locale = const Locale('vi'),
  FakeHistoryStore? store,
  bool settle = true,
  List<Override> overrides = const [],
}) {
  final fake = store ?? FakeHistoryStore();
  if (top != null) fake.topAnswer = top;
  fake.played = hasPlays
      ? (
          first: DateTime(2026, 1, 5).millisecondsSinceEpoch,
          last: DateTime(2026, 11, 19).millisecondsSinceEpoch,
        )
      : null;
  return pumpHistoryPage(
    tester,
    byYear: const {},
    width: width,
    height: height,
    textScale: textScale,
    locale: locale,
    store: fake,
    settle: settle,
    overrides: [
      historyClockProvider.overrideWithValue(() => testToday),
      ...overrides,
    ],
    page: const MostPlayedPage(),
  );
}

/// The l10n of the pumped Most played page.
AppLocalizations mostPlayedL10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(MostPlayedPage)));
