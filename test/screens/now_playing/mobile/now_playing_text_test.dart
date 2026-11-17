import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/ui/flight_source.dart';
import 'package:kanaru/src/playback/ui/track_cover.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/now_playing_text_styles.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/queue_strip.dart';
import 'package:material_ui/material_ui.dart';

import '../../../playback/support/ui_host.dart';

void main() {
  late TextTheme text;

  Future<List<TextStyle?>> stripStyles(
    WidgetTester tester,
    double t, {
    double scale = 1.0,
    FlightLook? look,
  }) async {
    final host = await pumpWithPlayer(
      tester,
      Center(
        child: StripText(t: t, look: look),
      ),
      textScale: scale,
      play: false,
    );
    // Give the playing track an artist so the artist line is built.
    await host.run(tester, () async {
      await host.h.db.customStatement(
        "UPDATE tracks SET artist = 'Art' WHERE title = 'T0'",
      );
      await host.h.play();
    });
    await host.letStreamsArrive(tester);
    text = Theme.of(tester.element(find.byType(StripText))).textTheme;
    return [
      for (final w in tester.widgetList<Text>(find.byType(Text))) w.style,
    ];
  }

  // The flight ends are the Now Playing styles (t = 0) and the strip styles
  // (t = 1), both M3 roles; in between the sizes are interpolated.
  testWidgets('strip title at t = 0 is the Now Playing title', (tester) async {
    final styles = await stripStyles(tester, 0);
    expect(styles.first?.fontSize, coverTitleStyle(text)?.fontSize);
    expect(styles.first?.fontSize, text.titleLarge?.fontSize);
    expect(styles.first?.fontWeight, FontWeight.w700);
  });

  testWidgets('strip title at t = 1 is the strip title', (tester) async {
    final styles = await stripStyles(tester, 1);
    expect(styles.first?.fontSize, stripTitleStyle(text)?.fontSize);
    expect(styles.first?.fontSize, text.titleMedium?.fontSize);
    expect(styles.first?.fontWeight, FontWeight.w700);
  });

  testWidgets('strip title at t = 0.5 is halfway', (tester) async {
    final styles = await stripStyles(tester, 0.5);
    final from = text.titleMedium!.fontSize!;
    final to = text.titleLarge!.fontSize!;
    expect(styles.first?.fontSize, closeTo((from + to) / 2, 0.01));
  });

  // The artist line flies from the Now Playing artist (t = 0) to the strip
  // artist (t = 1), both M3 body roles.
  for (final (t, pick) in [
    (0.0, (TextTheme x) => x.bodyLarge!.fontSize!),
    (1.0, (TextTheme x) => x.bodyMedium!.fontSize!),
    (
      0.5,
      (TextTheme x) => (x.bodyLarge!.fontSize! + x.bodyMedium!.fontSize!) / 2,
    ),
  ]) {
    testWidgets('artist font size at t = $t', (tester) async {
      await stripStyles(tester, t);
      final artist = tester.widget<Text>(find.text('Art'));
      expect(artist.style?.fontSize, closeTo(pick(text), 0.01));
    });
  }

  for (final scale in [1.5, 2.0]) {
    for (final t in [0.0, 1.0]) {
      testWidgets('strip text at text scale $scale, t = $t: no overflow', (
        tester,
      ) async {
        await pumpWithPlayer(
          tester,
          SizedBox(width: 240, height: 80, child: StripText(t: t)),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  group('flight from the mini player', () {
    const miniLook = FlightLook(
      title: TextStyle(
        inherit: false,
        fontSize: 15, fontWeight: FontWeight.w600, height: 1.35),
      artist: TextStyle(inherit: false, fontSize: 13, height: 1.35),
      coverRadius: KMediaCard.coverRadius,
    );

    testWidgets('text starts at the mini player size and line height', (
      tester,
    ) async {
      final styles = await stripStyles(tester, 0, look: miniLook);
      expect(styles[0]?.fontSize, 15);
      expect(styles[0]?.height, 1.35);
      expect(styles[1]?.fontSize, 13);
      expect(styles[1]?.height, 1.35);
    });

    testWidgets('text ends in the strip style at t = 1', (tester) async {
      final styles = await stripStyles(tester, 1, look: miniLook);
      expect(styles[0]?.fontSize, stripTitleStyle(text)?.fontSize);
      expect(styles[1]?.fontSize, stripArtistStyle(text)?.fontSize);
    });

    testWidgets('without a look the Now Playing line heights stay', (
      tester,
    ) async {
      final styles = await stripStyles(tester, 0);
      expect(styles[0]?.height, nowPlayingTitleLineHeight);
      expect(styles[1]?.height, nowPlayingArtistLineHeight);
    });

    Future<BorderRadius?> coverRadius(
      WidgetTester tester,
      double t,
      FlightLook? look,
    ) async {
      await pumpWithPlayer(
        tester,
        Center(
          child: StripCover(
            rect: const Rect.fromLTWH(0, 0, 56, 56),
            t: t,
            look: look,
          ),
        ),
      );
      return tester.widget<TrackCover>(find.byType(TrackCover)).radius;
    }

    testWidgets('cover corners start at the source radius', (tester) async {
      expect(await coverRadius(tester, 0, miniLook), KMediaCard.coverRadius);
    });

    testWidgets('Now Playing look starts at its own 12 dp corner', (
      tester,
    ) async {
      expect(
        await coverRadius(tester, 0, const FlightLook(coverRadius: KRadius.sm)),
        KRadius.sm,
      );
    });

    testWidgets('cover corners end at the strip radius', (tester) async {
      expect(
        await coverRadius(tester, 1, miniLook),
        const BorderRadius.all(Radius.circular(8)),
      );
    });
  });
}
