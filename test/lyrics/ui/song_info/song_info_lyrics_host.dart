import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_facts.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/domain/online/online_lyrics_ref.dart';
import 'package:kanaru/src/lyrics/state/stored_track_lyrics_provider.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/online/online_source_providers.dart';
import 'package:kanaru/src/lyrics/ui/song_info/full_lyrics_lines.dart';
import 'package:kanaru/src/lyrics/ui/song_info/song_info_lyrics_section.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/memory_settings_store.dart';

/// Synced lines "Line 0" ... 4 s apart.
Lyrics synced(int n, {LyricsOrigin origin = LyricsOrigin.tag}) => Lyrics(
  lines: [
    for (var i = 0; i < n; i++) LyricLine(Duration(seconds: i * 4), 'Line $i'),
  ],
  synced: true,
  origin: origin,
);

Lyrics plain(int n) => Lyrics(
  lines: [for (var i = 0; i < n; i++) LyricLine(Duration.zero, 'Plain $i')],
  synced: false,
  origin: LyricsOrigin.lrc,
);

/// Online lyrics of [plugin], kept or found automatically.
Lyrics online(OnlineHow how, {String plugin = 'NetEase', int n = 3}) => Lyrics(
  lines: [
    for (var i = 0; i < n; i++) LyricLine(Duration(seconds: i * 4), 'Line $i'),
  ],
  synced: true,
  origin: LyricsOrigin.online,
  online: OnlineLyricsRef(
    providerId: 'p1',
    providerName: plugin,
    remoteId: 'r',
    how: how,
  ),
);

LyricsFacts facts({String? lrc}) => LyricsFacts(
  trackId: const TrackId(7),
  trackRevision: null,
  lrcLocator: lrc,
  lrcRevision: null,
  off: false,
  title: 'Song',
  artist: 'Artist',
);

/// Pumps [SongInfoLyricsSection] for track 7 with the stored lyrics [state]
/// fed by the test; any other lyrics provider would hit a missing database
/// and fail the test.
class SectionHost {
  SectionHost(this.state, {this.lrc, this.settings});

  TrackLyrics state;
  final String? lrc;
  MemorySettingsStore? settings;

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(1000, 900),
    double textScale = 1,
    bool still = false,
    Widget Function(Widget section)? wrap,
  }) async {
    settings ??= MemorySettingsStore();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final section = SongInfoLyricsSection(trackId: 7);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(settings!),
          storedTrackLyricsProvider.overrideWith((ref, id) => state),
          lyricsFactsProvider.overrideWith(
            (ref, id) => Stream.value(facts(lrc: lrc)),
          ),
          onlineSourceRemovedProvider.overrideWith((ref, id) => false),
        ],
        child: MaterialApp(
          theme: buildKanaruTheme(brightness: Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: still,
            ),
            child: app!,
          ),
          home: Scaffold(
            body: ListView(children: [wrap?.call(section) ?? section]),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }
}

const openLabel = 'See all lyrics ›';
const showStamps = 'Show timestamps';
const hideStamps = 'Hide timestamps';

/// The icon button with [tooltip].
Finder iconButton(String tooltip) => find.byWidgetPredicate(
  (w) => w is KIconButton && w.tooltip == tooltip,
  description: 'KIconButton "$tooltip"',
);

/// A line of the modal's list (the preview under it shows the same words).
Finder modalLine(String text) => find.descendant(
  of: find.byType(FullLyricsLines),
  matching: find.text(text),
);

/// Pumps the section for [lyrics] and opens the full-lyrics modal.
Future<SectionHost> openFull(
  WidgetTester tester,
  Lyrics lyrics, {
  Size size = const Size(1000, 900),
  double textScale = 1,
  bool still = false,
  MemorySettingsStore? settings,
  String? lrc,
}) async {
  final host = SectionHost(LyricsShown(lyrics), lrc: lrc, settings: settings);
  await host.pump(tester, size: size, textScale: textScale, still: still);
  await tester.tap(find.text(openLabel));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return host;
}
