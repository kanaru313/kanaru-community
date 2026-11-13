import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/detail/detail_header.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/media/domain/cover_colors.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/playback/state/cover_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/detail_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

const _red = Color(0xFFCC3322);
const _green = Color(0xFF22AA44);

Override _colorsOf(Map<String, int> byKey) => coverColorsProvider.overrideWith(
  (ref, key) => Stream.value(
    byKey[key] == null
        ? null
        : CoverColors(seed: byKey[key]!, palette: [byKey[key]!]),
  ),
);

Future<LibraryHarness> _open(
  WidgetTester tester,
  String location, {
  required Future<void> Function(LibraryHarness h) fixture,
  List<Override> overrides = const [],
  double width = 390,
}) async {
  final h = await pumpLibrary(
    tester,
    initial: '/library/songs',
    width: width,
    overrides: overrides,
  );
  await fixture(h);
  await h.settle(tester);
  h.router.push(location);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await h.settle(tester);
  return h;
}

CoverTintBackground _tint(WidgetTester tester) =>
    tester.widget<CoverTintBackground>(find.byType(CoverTintBackground));

LinearGradient? _gradient(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(CoverTintBackground),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((d) => d.decoration)
    .whereType<BoxDecoration>()
    .map((d) => d.gradient)
    .whereType<LinearGradient>()
    .firstOrNull;

double _luminance(Color c) => c.computeLuminance();

double _contrast(Color a, Color b) {
  final hi = math.max(_luminance(a), _luminance(b));
  final lo = math.min(_luminance(a), _luminance(b));
  return (hi + 0.05) / (lo + 0.05);
}

Color _over(Color top, Color base) => Color.alphaBlend(top, base);

void main() {
  final albumLocation = LibraryLocations.album(
    AlbumKey.decode(albumId('Blue', 'Zed'))!,
  );

  testWidgets('the album page tint covers the whole page, header band too', (
    tester,
  ) async {
    await _open(
      tester,
      albumLocation,
      overrides: [
        _colorsOf({'aaaaaaaaaaaaaaaa': _red.toARGB32()}),
      ],
      fixture: (h) => addAlbum(h, 'Blue', 'Zed', coverKey: 'aaaaaaaaaaaaaaaa'),
    );
    expect(_tint(tester).palette, [_red]);
    expect(_tint(tester).strength, 0.5);
    expect(_tint(tester).fadeIn, isTrue);
    expect(
      find.descendant(
        of: find.byType(CoverTintBackground),
        matching: find.byType(PageHeader),
      ),
      findsOneWidget,
    );
    expect(_gradient(tester), isNotNull);
    await unmountApp(tester);
  });

  testWidgets('an album without a cover is not tinted', (tester) async {
    await _open(
      tester,
      albumLocation,
      fixture: (h) => addAlbum(h, 'Blue', 'Zed'),
    );
    expect(_tint(tester).palette, isNull);
    expect(_tint(tester).loading, isFalse);
    expect(_gradient(tester), isNull);
    await unmountApp(tester);
  });

  testWidgets('a cover without colours leaves the page untinted', (
    tester,
  ) async {
    await _open(
      tester,
      albumLocation,
      overrides: [_colorsOf({})],
      fixture: (h) => addAlbum(h, 'Blue', 'Zed', coverKey: 'aaaaaaaaaaaaaaaa'),
    );
    expect(_tint(tester).palette, isNull);
    expect(_tint(tester).loading, isFalse);
    expect(_gradient(tester), isNull);
    await unmountApp(tester);
  });

  testWidgets('nothing is drawn while the colours are still being read', (
    tester,
  ) async {
    final never = StreamController<CoverColors?>();
    addTearDown(never.close);
    await _open(
      tester,
      albumLocation,
      overrides: [coverColorsProvider.overrideWith((ref, key) => never.stream)],
      fixture: (h) => addAlbum(h, 'Blue', 'Zed', coverKey: 'aaaaaaaaaaaaaaaa'),
    );
    expect(_tint(tester).palette, isNull);
    expect(_tint(tester).loading, isTrue);
    expect(_gradient(tester), isNull);
    await unmountApp(tester);
  });

  testWidgets('the artist page is tinted by the artist photo', (tester) async {
    await _open(
      tester,
      LibraryLocations.artist(ArtistKey('zed')),
      overrides: [
        _colorsOf({'aaaaaaaaaaaaaaaa': _red.toARGB32()}),
      ],
      fixture: (h) => addAlbum(h, 'Blue', 'Zed', coverKey: 'aaaaaaaaaaaaaaaa'),
    );
    expect(_tint(tester).palette, [_red]);
    expect(_gradient(tester), isNotNull);
    await unmountApp(tester);
  });

  testWidgets('an artist with no songs takes the cover of its first own '
      'album', (tester) async {
    await _open(
      tester,
      LibraryLocations.artist(ArtistKey('zed')),
      overrides: [
        _colorsOf({'bbbbbbbbbbbbbbbb': _green.toARGB32()}),
      ],
      fixture: (h) => addAlbum(
        h,
        'Blue',
        'Zed',
        trackArtists: ['Guest'],
        albumArtist: 'Zed',
        coverKey: 'bbbbbbbbbbbbbbbb',
      ),
    );
    expect(_tint(tester).palette, [_green]);
    await unmountApp(tester);
  });

  testWidgets('an artist without any cover is not tinted', (tester) async {
    await _open(
      tester,
      LibraryLocations.artist(ArtistKey('zed')),
      fixture: (h) => addAlbum(h, 'Blue', 'Zed'),
    );
    expect(_tint(tester).palette, isNull);
    expect(_gradient(tester), isNull);
    await unmountApp(tester);
  });

  testWidgets('a black cover keeps the title and secondary text readable', (
    tester,
  ) async {
    await _open(
      tester,
      albumLocation,
      overrides: [
        _colorsOf({'aaaaaaaaaaaaaaaa': 0xFF000000}),
      ],
      fixture: (h) => addAlbum(h, 'Blue', 'Zed', coverKey: 'aaaaaaaaaaaaaaaa'),
    );
    await tester.pump(const Duration(milliseconds: 400));
    final scheme = Theme.of(tester.element(find.byType(DetailFrame)))
        .colorScheme;
    final gradient = _gradient(tester)!;
    for (final stop in gradient.colors) {
      final page = _over(stop, scheme.surface);
      expect(_contrast(scheme.onSurface, page), greaterThanOrEqualTo(4.5));
      expect(
        _contrast(scheme.onSurfaceVariant, page),
        greaterThanOrEqualTo(4.5),
      );
    }
    await unmountApp(tester);
  });

  for (final brightness in Brightness.values) {
    testWidgets('a black cover tint at page strength is readable '
        '(${brightness.name} theme)', (tester) async {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF3366CC),
        brightness: brightness,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: scheme),
          home: const CoverTintBackground(
            palette: [Color(0xFF000000)],
            strength: 0.5,
            fadeIn: true,
            child: SizedBox.expand(),
          ),
        ),
      );
      await tester.pump(coverTintTransition);
      for (final stop in _gradient(tester)!.colors) {
        final page = _over(stop, scheme.surface);
        expect(_contrast(scheme.onSurface, page), greaterThanOrEqualTo(4.5));
        expect(
          _contrast(scheme.onSurfaceVariant, page),
          greaterThanOrEqualTo(4.5),
        );
      }
    });
  }
}
