import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_failure.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_status.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/state/translation/track_translation_notifier.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_credit_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_providers.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_settings.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_view.dart';
import 'package:kanaru/src/lyrics/ui/translation/modal/translate_body.dart';
import 'package:kanaru/src/lyrics/ui/translation/translate_button.dart';
import 'package:kanaru/src/lyrics/ui/translation/translate_pill.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:kanaru/src/playback/state/sleep_timer_provider.dart';
import 'package:kanaru/src/plugins/state/store_ops.dart'
    show pluginIconProvider;
import 'package:kanaru/src/screens/now_playing/ui/desktop/desktop_now_playing.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/desktop_now_playing_header.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../lyrics/ui/lyrics_ui_host.dart' show syncedLyrics;
import '../../lyrics/ui/translation/modal/translate_modal_host.dart'
    show Box, box;
import '../../playback/support/ui_host.dart';
import '../../playback/ui/sleep_timer/sleep_timer_modal_host.dart';
import '../../shell/support/desktop_now_playing_host.dart';

const _track = TrackId(1);

/// What the entry points are fed with: the translation of the song and who
/// made it, both set by the test.
class _Feed {
  _Feed({this.lyrics = true}) {
    view = box<TranslationView>(TranslationView.idle);
    credit = box<TranslationCredit?>(null);
  }

  final bool lyrics;
  late final NotifierProvider<Box<TranslationView>, TranslationView> view;
  late final NotifierProvider<Box<TranslationCredit?>, TranslationCredit?>
  credit;

  List<Override> get overrides => [
    playingLyricsProvider.overrideWithValue(
      PlayingLyrics(
        entryId: 1,
        trackId: _track,
        lyrics: lyrics ? LyricsShown(syncedLyrics(2)) : const LyricsNone(),
      ),
    ),
    trackLyricsProvider.overrideWith(
      (ref, id) => lyrics ? LyricsShown(syncedLyrics(2)) : const LyricsNone(),
    ),
    trackTranslationProvider.overrideWith2((id) => _FakeTranslation(id, view)),
    translationCreditProvider.overrideWith((ref, id) => ref.watch(credit)),
    effectiveTranslationTargetProvider.overrideWith((ref, id) => 'vi'),
    pluginIconProvider.overrideWith((ref, id) async => null),
    sleepTimerProvider.overrideWith(FakeSleepTimer.new),
    ...sleepEstimates(),
  ];
}

class _FakeTranslation extends TrackTranslation {
  _FakeTranslation(super.trackId, this.source);

  final NotifierProvider<Box<TranslationView>, TranslationView> source;

  @override
  TranslationView build() => ref.watch(source);
}

const _credit = TranslationCredit(plugin: 'Google Translate', target: 'vi');
const _ready = TranslationView(
  status: TranslationStatus.ready(),
  map: {'Line 0': 'Dòng 0'},
  installId: 'google',
);

/// The button and the pill side by side, over the entry providers.
Future<UiHost> _pumpEntries(
  WidgetTester tester,
  _Feed feed, {
  bool on = true,
  List<TrackId>? opened,
}) async {
  final sink = opened ?? <TrackId>[];
  final host = await pumpWithPlayer(
    tester,
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TranslateButton(opener: (_, id) async => sink.add(id)),
        TranslatePill(opener: (_, id) async => sink.add(id)),
      ],
    ),
    overrides: feed.overrides,
    play: false,
  );
  if (on) {
    await host.container.read(translationOnProvider.notifier).set(true);
    await tester.pump();
  }
  return host;
}

void _set(UiHost host, _Feed feed, TranslationView v, [TranslationCredit? c]) {
  host.container.read(feed.view.notifier).set(v);
  host.container.read(feed.credit.notifier).set(c);
}

/// The semantics node of the entry [of]: its outermost button.
SemanticsNode _node(WidgetTester tester, Type of) => tester.getSemantics(
  find
      .descendant(
        of: find.byType(of),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.button == true,
        ),
      )
      .first,
);

/// The spoken label of the entry [of], and whether it is enabled.
String _label(WidgetTester tester, Type of) => _node(tester, of).label;

bool _enabled(WidgetTester tester, Type of) => isSemantics(
  hasEnabledState: true,
  isEnabled: true,
).matches(_node(tester, of), {});

/// Lets the snack bar on screen time out, so the next one shows.
Future<void> _dismissSnackBar(WidgetTester tester) async {
  // Slide in (the timeout starts when it is in), time out, slide out.
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 5));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('entry states', () {
    testWidgets('off: plain label, "Translate" pill, enabled', (tester) async {
      final feed = _Feed();
      await _pumpEntries(tester, feed, on: false);
      final handle = tester.ensureSemantics();
      expect(_label(tester, TranslateButton), 'Translate lyrics · Off');
      expect(_label(tester, TranslatePill), 'Translate lyrics · Off');
      expect(_enabled(tester, TranslateButton), isTrue);
      expect(find.text('Translate'), findsOneWidget);
      expect(find.byType(KAlertDot), findsNothing);
      handle.dispose();
    });

    testWidgets('on and translated: the language names it, no alert', (
      tester,
    ) async {
      final feed = _Feed();
      final host = await _pumpEntries(tester, feed);
      _set(host, feed, _ready, _credit);
      await tester.pump();
      final handle = tester.ensureSemantics();
      const on = 'Translate lyrics · Translating into Vietnamese';
      expect(_label(tester, TranslateButton), on);
      expect(_label(tester, TranslatePill), on);
      expect(find.text('Vietnamese'), findsOneWidget);
      expect(find.text('Translate'), findsNothing);
      expect(find.byType(KAlertDot), findsNothing);
      handle.dispose();
    });

    testWidgets('on without a translation yet: "Translate" stays', (
      tester,
    ) async {
      final feed = _Feed();
      await _pumpEntries(tester, feed);
      final handle = tester.ensureSemantics();
      expect(
        _label(tester, TranslateButton),
        'Translate lyrics · Translating into Vietnamese',
      );
      expect(find.text('Translate'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a run going: ring and "Translating", also for a re-run', (
      tester,
    ) async {
      final feed = _Feed();
      final host = await _pumpEntries(tester, feed);
      _set(
        host,
        feed,
        const TranslationView(status: TranslationStatus.loading(0, 2)),
      );
      await tester.pump();
      final handle = tester.ensureSemantics();
      expect(
        _label(tester, TranslateButton),
        'Translate lyrics · Translating…',
      );
      expect(find.text('Translating'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
      // A "Dịch lại" keeps the old lines on screen and still shows the ring.
      _set(
        host,
        feed,
        TranslationView(
          status: const TranslationStatus.loading(0, 2, background: true),
          map: _ready.map,
          installId: 'google',
        ),
        _credit,
      );
      await tester.pump();
      expect(find.text('Translating'), findsOneWidget);
      handle.dispose();
    });

    for (final (name, failure) in [
      ('network', const TranslationFailure.network()),
      ('no service', const TranslationFailure.noService()),
      ('plugin removed', const TranslationFailure.pluginGone()),
      ('quota', const TranslationFailure.quota()),
    ]) {
      testWidgets('any failure ($name): red dot on both, label says so', (
        tester,
      ) async {
        final feed = _Feed();
        final host = await _pumpEntries(tester, feed);
        _set(
          host,
          feed,
          TranslationView(status: TranslationStatus.failed(failure)),
        );
        await tester.pump();
        final handle = tester.ensureSemantics();
        expect(
          _label(tester, TranslateButton),
          'Translate lyrics · Translation failed',
        );
        expect(find.byType(KAlertDot), findsNWidgets(2));
        expect(_enabled(tester, TranslateButton), isTrue);
        handle.dispose();
      });
    }

    testWidgets('a half-done run: dot, and the pill still names the language', (
      tester,
    ) async {
      final feed = _Feed();
      final host = await _pumpEntries(tester, feed);
      _set(
        host,
        feed,
        TranslationView(
          status: const TranslationStatus.failed(TranslationFailure.network()),
          map: _ready.map,
          installId: 'google',
          linesDone: 1,
          linesTotal: 2,
        ),
        const TranslationCredit(
          plugin: 'Google Translate',
          target: 'vi',
          linesDone: 1,
          linesTotal: 2,
        ),
      );
      await tester.pump();
      expect(find.byType(KAlertDot), findsNWidgets(2));
      expect(find.text('Vietnamese'), findsOneWidget);
    });

    testWidgets('no lyrics: both dimmed and inert, nothing opens', (
      tester,
    ) async {
      final feed = _Feed(lyrics: false);
      final opened = <TrackId>[];
      await _pumpEntries(tester, feed, opened: opened);
      final handle = tester.ensureSemantics();
      const label = 'Translate lyrics · No lyrics to translate';
      for (final of in [TranslateButton, TranslatePill]) {
        expect(_label(tester, of), label);
        expect(_enabled(tester, of), isFalse);
      }
      await tester.tap(find.byType(TranslateButton));
      await tester.tap(find.byType(TranslatePill));
      await tester.pump();
      expect(opened, isEmpty);
      handle.dispose();
    });

    testWidgets('a tap opens the modal for the playing song', (tester) async {
      final feed = _Feed();
      final opened = <TrackId>[];
      await _pumpEntries(tester, feed, opened: opened);
      await tester.tap(find.byType(TranslateButton));
      await tester.tap(find.byType(TranslatePill));
      await tester.pump();
      expect(opened, [_track, _track]);
    });
  });

  group('desktop Now Playing', () {
    Future<DesktopHost> open(WidgetTester tester, {bool lyrics = true}) async {
      final host = await pumpDesktopShell(
        tester,
        overrides: _Feed(lyrics: lyrics).overrides,
      );
      host.container.read(nowPlayingPanelProvider.notifier).open();
      await tester.pump();
      await settleSlide(tester);
      return host;
    }

    Finder pill() => find.descendant(
      of: find.byType(DesktopNowPlayingHeader),
      matching: find.byType(TranslatePill),
    );

    Future<void> key(WidgetTester tester, LogicalKeyboardKey k) async {
      await tester.sendKeyEvent(k);
      await tester.pump();
    }

    /// The toggle writes the setting (real async) before it says so.
    Future<void> keyAndWrite(
      WidgetTester tester,
      DesktopHost host,
      LogicalKeyboardKey k,
    ) async {
      await key(tester, k);
      await host.letStreamsArrive(tester);
    }

    testWidgets('a click on the pill opens "Translate lyrics"', (tester) async {
      await open(tester);
      await tester.tap(pill());
      await tester.pumpAndSettle();
      expect(find.byType(TranslateBody), findsOneWidget);
    });

    testWidgets('right-click and T toggle translation and say so', (
      tester,
    ) async {
      final host = await open(tester);
      bool on() => host.container.read(translationOnProvider);
      expect(on(), isFalse);
      await tester.tap(pill(), buttons: kSecondaryButton);
      await tester.pump();
      expect(on(), isTrue);
      expect(find.text('Translation: Vietnamese'), findsOneWidget);
      await _dismissSnackBar(tester);
      await keyAndWrite(tester, host, LogicalKeyboardKey.keyT);
      expect(on(), isFalse);
      expect(find.text('Translation off'), findsOneWidget);
      await _dismissSnackBar(tester);
      await keyAndWrite(tester, host, LogicalKeyboardKey.keyT);
      expect(on(), isTrue);
      expect(find.text('Translation: Vietnamese'), findsOneWidget);
    });

    testWidgets('T is ignored with a modifier', (tester) async {
      final host = await open(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(host.container.read(translationOnProvider), isFalse);
    });

    testWidgets('T is ignored while a text field has focus', (tester) async {
      final host = await open(tester);
      tester
          .state<ScaffoldState>(
            find
                .descendant(
                  of: find.byType(DesktopNowPlaying),
                  matching: find.byType(Scaffold),
                )
                .first,
          )
          .showBottomSheet((_) => const TextField(autofocus: true));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await key(tester, LogicalKeyboardKey.keyT);
      expect(host.container.read(translationOnProvider), isFalse);
    });

    testWidgets('T and right-click do nothing without lyrics', (tester) async {
      final host = await open(tester, lyrics: false);
      await key(tester, LogicalKeyboardKey.keyT);
      await tester.tap(pill(), buttons: kSecondaryButton);
      await tester.pump();
      expect(host.container.read(translationOnProvider), isFalse);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('the ⋮ item says "Translating into …" or "Off"', (
      tester,
    ) async {
      final host = await open(tester);
      await tester.tap(find.byIcon(KIcons.moreVert));
      await tester.pumpAndSettle();
      expect(find.text('Translate lyrics…'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await host.container.read(translationOnProvider.notifier).set(true);
      await tester.tap(find.byIcon(KIcons.moreVert));
      await tester.pumpAndSettle();
      expect(find.text('Translating into Vietnamese'), findsOneWidget);
    });

    testWidgets('the ⋮ item opens the modal', (tester) async {
      await open(tester);
      await tester.tap(find.byIcon(KIcons.moreVert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Translate lyrics…'));
      await tester.pumpAndSettle();
      expect(find.byType(TranslateBody), findsOneWidget);
    });

    testWidgets('the ⋮ item is disabled without lyrics', (tester) async {
      await open(tester, lyrics: false);
      await tester.tap(find.byIcon(KIcons.moreVert));
      await tester.pumpAndSettle();
      final item = find.ancestor(
        of: find.text('Translate lyrics…'),
        matching: find.byType(MenuItemButton),
      );
      expect(tester.widget<MenuItemButton>(item).onPressed, isNull);
    });
  });
}
