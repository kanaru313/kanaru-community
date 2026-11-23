import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/domain/online/lookup_outcome.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_source_button.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../lyrics_ui_host.dart' show syncedLyrics;
import 'online_ui_overrides.dart';
import '../lyrics_spinner_finders.dart';

Future<void> _pump(
  WidgetTester tester,
  TrackLyrics lyrics, {
  bool desktop = false,
  bool disableAnimations = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = desktop
      ? const Size(1400, 900)
      : const Size(400, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playingLyricsProvider.overrideWithValue(
          PlayingLyrics(entryId: 1, trackId: const TrackId(1), lyrics: lyrics),
        ),
        ...onlineUiOverrides(
          sources: [lyricsSource('netease', name: 'NetEase')],
        ),
      ],
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: disableAnimations),
          child: app!,
        ),
        home: Scaffold(
          body: Center(child: LyricsSourceButton(onOpen: () {})),
        ),
      ),
    ),
  );
  await tester.pump();
}

KIconButton _button(WidgetTester tester) =>
    tester.widget<KIconButton>(find.byType(KIconButton));

double? _alpha(WidgetTester tester) => _button(tester).color?.a;

void main() {
  for (final desktop in [false, true]) {
    group(desktop ? 'desktop' : 'mobile', () {
      testWidgets(
        'online lyrics: the plugin icon at 22, named in the tooltip',
        (tester) async {
          final handle = tester.ensureSemantics();
          await _pump(tester, LyricsShown(onlineLyrics()), desktop: desktop);
          final avatar = tester.widget<KSourceAvatar>(
            find.byType(KSourceAvatar),
          );
          expect(avatar.size, 22);
          expect(avatar.removed, isFalse);
          expect(avatar.label, 'NetEase');
          expect(
            _button(tester).tooltip,
            desktop ? 'NetEase · Synced (L)' : 'NetEase · Synced',
          );
          expect(
            tester.getSemantics(find.byType(KIconButton)).label,
            'NetEase · Synced',
          );
          handle.dispose();
        },
      );

      testWidgets('online lyrics of a removed plugin: grey initial', (
        tester,
      ) async {
        await _pump(
          tester,
          LyricsShown(onlineLyrics(id: 'zing', name: 'ZingMP3')),
          desktop: desktop,
        );
        final avatar = tester.widget<KSourceAvatar>(find.byType(KSourceAvatar));
        expect(avatar.removed, isTrue);
        expect(avatar.label, 'ZingMP3');
      });

      testWidgets('instrumental: the plugin icon, "Instrumental" as label', (
        tester,
      ) async {
        await _pump(
          tester,
          LyricsInstrumental(onlineLyrics().online!),
          desktop: desktop,
        );
        expect(find.byType(KSourceAvatar), findsOneWidget);
        expect(
          _button(tester).tooltip,
          desktop ? 'Instrumental (L)' : 'Instrumental',
        );
      });

      testWidgets('the icon of a file\'s lyrics is the lyrics glyph', (
        tester,
      ) async {
        await _pump(tester, LyricsShown(syncedLyrics(2)), desktop: desktop);
        expect(find.byType(KSourceAvatar), findsNothing);
        expect(_button(tester).icon, KIcons.lyrics);
      });

      testWidgets('searching: a ring turns, the label says so', (tester) async {
        await _pump(tester, const LyricsSearching(2), desktop: desktop);
        expect(byLyricsSpinner(), findsOneWidget);
        expect(
          _button(tester).tooltip,
          desktop ? 'Searching… (L)' : 'Searching…',
        );
      });

      testWidgets('searching with animations off: a still arc', (tester) async {
        await _pump(
          tester,
          const LyricsSearching(2),
          desktop: desktop,
          disableAnimations: true,
        );
        expect(byLyricsSpinner(), findsOneWidget);
        await expectStill(tester);
      });

      for (final (name, lyrics, label) in <(String, TrackLyrics, String)>[
        ('no lyrics', const LyricsNone(), 'No lyrics'),
        (
          'failed',
          const LyricsLookupFailed(reason: LookupFailReason.network, asked: 1),
          'Couldn’t find lyrics',
        ),
        ('paused', LyricsLookupPaused(DateTime(2030)), 'Lyrics sources paused'),
        ('not found', const LyricsNotFound(asked: 1, off: 0), 'No lyrics'),
      ]) {
        testWidgets('$name: dimmed to 38 % and named', (tester) async {
          await _pump(tester, lyrics, desktop: desktop);
          expect(_alpha(tester), closeTo(0.38, 1e-6));
          expect(byLyricsSpinner(), findsNothing);
          expect(_button(tester).tooltip, desktop ? '$label (L)' : label);
        });
      }
    });
  }

  testWidgets('desktop online icon sits on a surfaceContainerHigh disc', (
    tester,
  ) async {
    await _pump(tester, LyricsShown(onlineLyrics()), desktop: true);
    final scheme = Theme.of(tester.element(find.byType(KIconButton)))
        .colorScheme;
    final disc = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(KIconButton),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.shape == BoxShape.circle);
    expect(disc.map((d) => d.color), contains(scheme.surfaceContainerHigh));
  });

  testWidgets('mobile online icon has no disc', (tester) async {
    await _pump(tester, LyricsShown(onlineLyrics()));
    final discs = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(KIconButton),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.shape == BoxShape.circle && d.color != null);
    final scheme = Theme.of(tester.element(find.byType(KIconButton)))
        .colorScheme;
    expect(
      discs.map((d) => d.color),
      isNot(contains(scheme.surfaceContainerHigh)),
    );
  });
}
