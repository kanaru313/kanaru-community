import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/state/covers/cover_dialog_options.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
import 'package:kanaru/src/library/ui/covers/cover_dialog.dart';
import 'package:kanaru/src/library/ui/covers/cover_frame_art.dart';
import 'package:kanaru/src/library/ui/covers/cover_preview_frame.dart';
import 'package:kanaru/src/library/ui/covers/pick_custom_cover.dart';
import 'package:kanaru/src/platform/state/image_file_picker_provider.dart';
import 'package:kanaru/src/playback/ui/track_cover.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'cover_test_support.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// Switching rows frame by frame: the tint only fades its alpha and the
/// preview frame is never blank, and the desktop dialog insets its content.
void main() {
  late Directory dir;
  late FakeCoverController cover;
  late FakePicker picker;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kanaru_dlg_switch_');
    cover = FakeCoverController(dir);
    picker = FakePicker();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> open(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Real (1 x 1) images, so the frame really decodes and paints them.
    for (final n in ['Alpha', 'Beta']) {
      File('${dir.path}/$n-thumb.jpg').writeAsBytesSync(_png);
    }
    final options = CoverDialogOptions(
      itemName: 'Mix',
      automaticCoverKeys: const [],
      current: null,
      suggestions: [
        for (final n in ['Alpha', 'Beta'])
          CoverSuggestion(
            albumKey: n,
            title: n,
            year: null,
            thumb: File('${dir.path}/$n-thumb.jpg'),
            full: File('${dir.path}/$n-full.jpg'),
          ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coverDialogOptionsProvider.overrideWith((ref, i) async => options),
          customCoverControllerProvider.overrideWithValue(cover),
          imageFilePickerProvider.overrideWithValue(picker),
        ],
        child: MaterialApp(
          theme: buildKanaruTheme(brightness: Brightness.light),
          locale: const Locale('vi'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    pickCustomCover(context, CustomCoverKind.artist, 'pl'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  final scroller = find
      .descendant(
        of: find.byType(CoverDialog),
        matching: find.byType(Scrollable),
      )
      .first;

  Finder row(String title) => find.widgetWithText(SelectionRow, title);

  /// The media card inside a row: its box is the visible tint.
  Finder card(String title) =>
      find.descendant(of: row(title), matching: find.byType(KMediaCard));

  Future<void> pickImage(WidgetTester tester) async {
    final image = pickedFile(dir, 'IMG.jpg');
    cover.sizes[image.file.path] = (w: 3024, h: 4032);
    picker.next = image;
    final f = find.textContaining('Chọn ảnh');
    await tester.scrollUntilVisible(f, 200, scrollable: scroller);
    await tester.tap(f);
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  /// The fill painted behind [title]'s row.
  Color tint(WidgetTester tester, String title) {
    // The media row's frame is a Material whose colour is the tint.
    for (final m in tester.widgetList<Material>(
      find.descendant(of: row(title), matching: find.byType(Material)),
    )) {
      final c = m.color;
      if (c != null && c != Colors.transparent) return c;
    }
    fail('no tint under $title');
  }

  /// Taps [to] and samples every row's tint each 16 ms for 400 ms. A tint
  /// only fades alpha: its RGB stays the container colour, so it can never
  /// pass through grey or black, on the row losing the choice or the row
  /// gaining it.
  Future<void> expectCleanSwitch(
    WidgetTester tester,
    String to,
    List<String> rows,
  ) async {
    final container = Theme.of(tester.element(find.byType(Scaffold).first))
        .colorScheme
        .secondaryContainer;
    await tester.tap(row(to));
    for (var t = 0; t <= 400; t += 16) {
      for (final r in rows) {
        final c = tint(tester, r);
        final drift =
            (c.r - container.r).abs() +
            (c.g - container.g).abs() +
            (c.b - container.b).abs();
        expect(drift, lessThan(0.01), reason: '$r at ${t}ms drifted to grey');
      }
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('row switches never grey either row (auto, picked, album)', (
    tester,
  ) async {
    await open(tester, size: const Size(360, 800));
    await pickImage(tester);
    final rows = ['Tự động', 'IMG.jpg', 'Alpha'];
    var switches = 0;
    for (final to in ['Tự động', 'IMG.jpg', 'Alpha', 'IMG.jpg', 'Tự động']) {
      // The picked row is named after the file; scroll so all are built.
      await tester.drag(scroller, const Offset(0, 100));
      await tester.pump();
      if (row(to).evaluate().isEmpty) continue;
      switches++;
      await expectCleanSwitch(tester, to, [
        for (final r in rows)
          if (row(r).evaluate().isNotEmpty) r,
      ]);
    }
    expect(switches, 5, reason: 'every switch was sampled');
  });

  /// The picture layer of the preview frame and what is painted by it.
  ({RawImage? raw, double opacity}) frameImage(WidgetTester tester) {
    final raws = find.descendant(
      of: find.byType(CoverFrameArt),
      matching: find.byType(RawImage),
    );
    if (raws.evaluate().isEmpty) return (raw: null, opacity: 0);
    final fade = tester.widget<AnimatedOpacity>(
      find
          .ancestor(of: raws.first, matching: find.byType(AnimatedOpacity))
          .first,
    );
    return (raw: tester.widget<RawImage>(raws.first), opacity: fade.opacity);
  }

  /// Lets the real image decode (it ignores the fake clock), then a frame.
  Future<void> decode(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }

  testWidgets('switching between two images keeps one painted, undimmed', (
    tester,
  ) async {
    await open(tester, size: const Size(360, 800));
    await tester.tap(row('Alpha'));
    // First picture: wait until it has decoded and finished its one fade-in.
    for (var i = 0; i < 40; i++) {
      await decode(tester);
    }
    expect(frameImage(tester).raw?.image, isNotNull, reason: 'Alpha painted');
    expect(frameImage(tester).opacity, 1);

    await tester.tap(row('Beta'));
    for (var t = 0; t < 20; t++) {
      final f = frameImage(tester);
      expect(f.raw?.image, isNotNull, reason: 'no image at frame $t');
      expect(f.opacity, 1, reason: 'dimmed at frame $t');
      await decode(tester);
    }
    expect(frameImage(tester).raw?.image, isNotNull);
  });

  testWidgets('a cached first image then an uncached one never dims', (
    tester,
  ) async {
    await open(tester, size: const Size(360, 800));
    // Warm the image cache with Alpha, then drop back to the automatic cover.
    await tester.tap(row('Alpha'));
    for (var i = 0; i < 40; i++) {
      await decode(tester);
    }
    await tester.tap(row('Tự động'));
    await tester.pumpAndSettle();
    // Alpha again: now it loads synchronously from the cache.
    await tester.tap(row('Alpha'));
    await tester.pump();
    expect(frameImage(tester).raw?.image, isNotNull, reason: 'cached: sync');
    expect(frameImage(tester).opacity, 1);

    await tester.tap(row('Beta'));
    for (var t = 0; t < 20; t++) {
      final f = frameImage(tester);
      expect(f.raw?.image, isNotNull, reason: 'no image at frame $t');
      expect(f.opacity, 1, reason: 'dimmed at frame $t');
      await decode(tester);
    }
  });

  testWidgets('a suggestion shows centred, not at the picked image pan', (
    tester,
  ) async {
    await open(tester, size: const Size(360, 800));
    final image = pickedFile(dir, 'wide.jpg');
    cover.sizes[image.file.path] = (w: 4000, h: 2000);
    picker.next = image;
    await tester.scrollUntilVisible(
      find.textContaining('Chọn ảnh'),
      200,
      scrollable: scroller,
    );
    await tester.tap(find.textContaining('Chọn ảnh'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CoverPreviewFrame), const Offset(-120, 0));
    await tester.pumpAndSettle();
    Alignment alignment() => tester
        .widget<Image>(
          find.descendant(
            of: find.byType(CoverFrameArt),
            matching: find.byType(Image),
          ),
        )
        .alignment
        .resolve(TextDirection.ltr);
    expect(alignment().x, isNot(0), reason: 'the picked image was panned');

    await tester.drag(scroller, const Offset(0, 400));
    await tester.pump();
    await tester.tap(row('Alpha'));
    await tester.pumpAndSettle();
    expect(alignment(), Alignment.center);
  });

  testWidgets('desktop dialog insets rows and footer by 8, mobile does not', (
    tester,
  ) async {
    await open(tester, size: const Size(1280, 800));
    final dialog = tester.getRect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(ScaffoldMessenger),
      ),
    );
    expect(
      tester.getRect(card('Tự động')).left - dialog.left,
      KSpace.x2,
      reason: 'rows are inset so the tint clears the dialog edge',
    );
    expect(dialog.right - tester.getRect(card('Tự động')).right, KSpace.x2);
    // The library row's own 8 dp side padding sits inside the 8 dp inset
    // (the cover is 16 dp from the edge, not 24: same row as the library).
    expect(
      tester
              .getRect(
                find.descendant(
                  of: row('Tự động'),
                  matching: find.byType(TrackCover),
                ),
              )
              .left -
          dialog.left,
      KSpace.x2 + KMediaCard.sidePadding,
    );
    expect(
      tester.getRect(find.text('Ảnh của nghệ sĩ ở mọi nơi')).left - dialog.left,
      greaterThanOrEqualTo(KSpace.x6),
    );
  });

  testWidgets('mobile sheet rows run to the screen edges', (tester) async {
    await open(tester, size: const Size(360, 800));
    final r = tester.getRect(card('Tự động'));
    expect((r.left, r.right), (0, 360));
  });
}
