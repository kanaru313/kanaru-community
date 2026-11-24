import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_display_prefs.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_size.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_settings.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_credit_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_view.dart';
import 'package:kanaru/src/lyrics/ui/plain_lyrics_view.dart';
import 'package:kanaru/src/lyrics/ui/translation/translation_placeholder.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../lyrics_ui_host.dart';
import 'translation_ui_host.dart';

const _size = 25.0;
const _plain = _size * KLyricsMetrics.plainScale;

TextStyle _styleOf(WidgetTester tester, String text) =>
    DefaultTextStyle.of(tester.element(find.text(text))).style;

void main() {
  Future<void> open(
    WidgetTester tester, {
    TranslationView? view,
    bool on = true,
    bool replace = false,
    LyricsAlign align = LyricsAlign.start,
    TranslationCredit? credit,
    Lyrics? lyrics,
    TranslationSize size = TranslationSize.medium,
  }) async {
    final host = LyricsUiHost(extra: translationOverrides());
    if (on) await turnTranslationOn(host.container, replace: replace);
    await host.container.read(translationSizeProvider.notifier).set(size);
    host.container.read(viewBox.notifier).set(view ?? TranslationView.idle);
    host.container.read(creditBox.notifier).set(credit);
    await host.pump(
      tester,
      PlainLyricsView(
        lyrics: lyrics ?? plainLyrics(3),
        lineSize: _size,
        sidePadding: 24,
        align: align,
        trackId: trackOne,
      ),
    );
  }

  final map = {for (var i = 0; i < 3; i++) 'Plain $i': 'Bản $i'};

  testWidgets('the translation is 0.8 of the plain text, in the variant '
      'colour', (tester) async {
    await open(tester, view: readyView(map));
    final style = _styleOf(tester, 'Bản 1');
    expect(style.fontSize, closeTo(_plain * 0.8, 1e-9));
    expect(
      style.color,
      buildKanaruTheme(brightness: Brightness.light)
          .colorScheme
          .onSurfaceVariant,
    );
    expect(_styleOf(tester, 'Plain 1').fontSize, closeTo(_plain, 1e-9));
  });

  testWidgets('replace: the translation is the text, the original small', (
    tester,
  ) async {
    await open(tester, view: readyView({'Plain 0': 'Bản 0'}), replace: true);
    expect(_styleOf(tester, 'Bản 0').fontSize, closeTo(_plain, 1e-9));
    expect(_styleOf(tester, 'Plain 0').fontSize, closeTo(_plain * 0.7, 1e-9));
    expect(_styleOf(tester, 'Plain 1').fontSize, closeTo(_plain, 1e-9));
  });

  testWidgets('a blank line between stanzas has no translation or bar', (
    tester,
  ) async {
    await open(
      tester,
      view: pendingView,
      lyrics: Lyrics(
        lines: const [
          LyricLine(Duration.zero, 'Plain 0'),
          LyricLine(Duration.zero, ''),
          LyricLine(Duration.zero, 'Plain 2'),
        ],
        synced: false,
        origin: LyricsOrigin.lrc,
      ),
    );
    expect(find.byKey(translationPlaceholderKey), findsNWidgets(2));
  });

  testWidgets('the credit ends the text and is centred with the lyrics', (
    tester,
  ) async {
    await open(
      tester,
      view: readyView(map),
      align: LyricsAlign.center,
      credit: const TranslationCredit(plugin: 'Google', target: 'vi'),
    );
    final credit = find.text('Translated by Google · Vietnamese');
    expect(credit, findsOneWidget);
    expect(tester.widget<Text>(credit).textAlign, TextAlign.center);
  });

  testWidgets('translation off: plain text, nothing asked for', (tester) async {
    await open(tester, view: readyView(map), on: false);
    expect(find.text('Bản 1'), findsNothing);
    expect(translationAsks, 0);
  });

  testWidgets('a translated line reads as original and translation', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester, view: readyView(map));
    expect(find.bySemanticsLabel('Plain 1, Bản 1'), findsOneWidget);
    handle.dispose();
  });

  for (final (size, under, original) in [
    (TranslationSize.small, 0.672, 0.588),
    (TranslationSize.medium, 0.8, 0.7),
    (TranslationSize.large, 0.968, 0.847),
  ]) {
    testWidgets('size ${size.name}: under is $under, replaced original '
        '$original of the plain text', (tester) async {
      await open(tester, view: readyView(map), size: size);
      expect(_styleOf(tester, 'Bản 0').fontSize, closeTo(_plain * under, 1e-9));
    });

    testWidgets('size ${size.name}: replace shows the original at $original', (
      tester,
    ) async {
      await open(
        tester,
        view: readyView({'Plain 0': 'Bản 0'}),
        replace: true,
        size: size,
      );
      expect(_styleOf(tester, 'Bản 0').fontSize, closeTo(_plain, 1e-9));
      expect(
        _styleOf(tester, 'Plain 0').fontSize,
        closeTo(_plain * original, 1e-9),
      );
    });
  }
}
