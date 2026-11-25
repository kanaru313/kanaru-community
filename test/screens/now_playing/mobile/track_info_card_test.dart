import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/track_info_card.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

const _base = TrackInfo(
  id: TrackId(1),
  title: 'Song',
  status: TrackAvailability.present,
  relPath: 'song.flac',
);

/// Album, artist and every technical part, with a 200-character album.
final _full = TrackInfo(
  id: _base.id,
  title: _base.title,
  status: _base.status,
  relPath: _base.relPath,
  artist: 'Art',
  album: 'A' * 200,
  format: 'FLAC',
  sampleRate: 44100,
  bitrate: 900,
  playCount: 3,
);

Future<void> _pump(
  WidgetTester tester,
  TrackInfo? info, {
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildKanaruTheme(brightness: brightness),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: TrackInfoCard(info: info),
        ),
      ),
    ),
  );
}

double _height(WidgetTester tester) =>
    tester.getSize(find.byType(TrackInfoCard)).height;

Finder _inCard(Finder f) =>
    find.descendant(of: find.byType(TrackInfoCard), matching: f);

void main() {
  testWidgets('shows album · artist, then the technical line', (tester) async {
    await _pump(tester, _full);
    expect(find.text('${'A' * 200} · Art'), findsOneWidget);
    expect(find.textContaining('FLAC · 44.1 kHz · 900 kbps'), findsOneWidget);
  });

  testWidgets('a 200-character album stays on one line', (tester) async {
    await _pump(tester, _full);
    // One line of text, ellipsized, not a wrapped block.
    final album = find.textContaining('A' * 200);
    expect(
      tester.renderObject<RenderParagraph>(album).didExceedMaxLines,
      isTrue,
    );
    final long = _height(tester);
    await _pump(tester, _base);
    expect(_height(tester), long);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('same height with tags, without and while unknown '
        '(text ×$scale)', (tester) async {
      await _pump(tester, _full, textScale: scale);
      final full = _height(tester);
      await _pump(tester, _base, textScale: scale);
      expect(_height(tester), full);
      await _pump(tester, null, textScale: scale);
      expect(_height(tester), full);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a larger text scale gives a taller card', (tester) async {
    await _pump(tester, _full);
    final normal = _height(tester);
    await _pump(tester, _full, textScale: 2);
    expect(_height(tester), greaterThan(normal));
  });

  testWidgets('a missing album and artist keeps an empty first line', (
    tester,
  ) async {
    await _pump(tester, _base);
    // Only the plays count is known on the technical line.
    expect(find.textContaining('play'), findsOneWidget);
    expect(_inCard(find.text('')), findsOneWidget);
  });

  testWidgets('unknown info shows skeleton lines, hidden from screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _full);
    final loaded = _height(tester);
    await _pump(tester, null);
    expect(_inCard(find.byType(KSkeletonLine)), findsNWidgets(2));
    expect(_height(tester), loaded);
    expect(_inCard(find.byType(Text)), findsNothing);
    expect(_inCard(find.bySemanticsLabel(RegExp('.'))), findsNothing);
    await _pump(tester, _full);
    expect(_inCard(find.bySemanticsLabel(RegExp('FLAC'))), findsOneWidget);
    semantics.dispose();
  });

  for (final brightness in Brightness.values) {
    testWidgets('lays out in the ${brightness.name} theme', (tester) async {
      await _pump(tester, null, brightness: brightness);
      final skeleton = _height(tester);
      await _pump(tester, _full, brightness: brightness);
      expect(_height(tester), skeleton);
      expect(tester.takeException(), isNull);
    });
  }
}
