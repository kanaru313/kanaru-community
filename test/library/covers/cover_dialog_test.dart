import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/domain/covers/cover_choice.dart';
import 'package:kanaru/src/library/state/covers/cover_dialog_options.dart';
import 'package:kanaru/src/library/state/covers/cover_draft.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
import 'package:kanaru/src/library/ui/covers/cover_dialog.dart';
import 'package:kanaru/src/library/ui/covers/cover_preview_frame.dart';
import 'package:kanaru/src/library/ui/covers/pick_custom_cover.dart';
import 'package:kanaru/src/platform/state/image_file_picker_provider.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'cover_test_support.dart';

void main() {
  late Directory dir;
  late FakeCoverController cover;
  late FakePicker picker;
  CoverDraft? formResult;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kanaru_dlgui_');
    cover = FakeCoverController(dir);
    picker = FakePicker();
    formResult = null;
  });
  tearDown(() => dir.deleteSync(recursive: true));

  CoverSuggestion suggestion(String name, {int? year}) => CoverSuggestion(
    albumKey: name,
    title: name,
    year: year,
    thumb: File('${dir.path}/$name-thumb.jpg'),
    full: File('${dir.path}/$name-full.jpg'),
  );

  CoverDialogOptions options({
    bool current = false,
    List<CoverSuggestion>? suggestions,
  }) => CoverDialogOptions(
    itemName: 'Mix',
    automaticCoverKeys: const [],
    current: current
        ? (
            thumb: File('${dir.path}/cur-thumb.jpg'),
            full: File('${dir.path}/cur-full.jpg'),
          )
        : null,
    suggestions: suggestions ?? [suggestion('Alpha', year: 1999)],
  );

  /// Opens the dialog from a button and waits for it.
  Future<void> open(
    WidgetTester tester, {
    CoverDialogOptions? opts,
    CustomCoverKind kind = CustomCoverKind.playlist,
    Size size = const Size(360, 800),
    double textScale = 1,
    Brightness brightness = Brightness.light,
    bool animations = true,
    bool form = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coverDialogOptionsProvider.overrideWith(
            (ref, i) async => opts ?? options(),
          ),
          customCoverControllerProvider.overrideWithValue(cover),
          imageFilePickerProvider.overrideWithValue(picker),
        ],
        child: MaterialApp(
          theme: buildKanaruTheme(brightness: brightness),
          locale: const Locale('vi'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: !animations,
            ),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  if (form) {
                    formResult = await pickCoverForForm(context, kind, 'pl');
                  } else {
                    await pickCustomCover(context, kind, 'pl');
                  }
                },
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

  Finder row(String title) => find.widgetWithText(SelectionRow, title);
  Finder button(String label) => find.widgetWithText(FilledButton, label);

  bool selected(WidgetTester tester, String title) =>
      isSemantics(isSelected: true)
          .matches(tester.getSemantics(row(title)), {});

  bool enabled(WidgetTester tester, Finder f) =>
      isSemantics(isEnabled: true).matches(tester.getSemantics(f), {});

  /// Lets real file operations finish: they ignore the fake clock, and each
  /// continuation after them waits for a pump.
  Future<void> flushIo(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  /// The pick row says "Chọn ảnh…" on mobile and "Chọn ảnh từ máy…" on desktop.
  Future<void> tapPickRow(WidgetTester tester) async {
    final f = find.textContaining('Chọn ảnh');
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.tap(f);
  }

  Future<void> pickImage(
    WidgetTester tester, {
    String name = 'IMG_2041.jpg',
    ({int w, int h}) size = (w: 3024, h: 4032),
  }) async {
    final image = pickedFile(dir, name);
    cover.sizes[image.file.path] = size;
    picker.next = image;
    await tapPickRow(tester);
    await tester.pump();
    await flushIo(tester);
  }

  Future<void> tapSave(WidgetTester tester, [String label = 'Lưu']) async {
    await tester.tap(button(label));
    await tester.pump();
    await flushIo(tester);
  }

  group('choices', () {
    testWidgets('opens on the current custom image, else on Tự động', (
      tester,
    ) async {
      await open(tester, opts: options(current: true));
      expect(selected(tester, 'Ảnh đang dùng'), isTrue);
      expect(selected(tester, 'Tự động'), isFalse);
      expect(enabled(tester, button('Lưu')), isFalse);
    });

    testWidgets('Lưu is off until the choice changes', (tester) async {
      await open(tester);
      expect(selected(tester, 'Tự động'), isTrue);
      expect(enabled(tester, button('Lưu')), isFalse);
      await tester.tap(row('Alpha'));
      await tester.pumpAndSettle();
      expect(selected(tester, 'Alpha'), isTrue);
      expect(enabled(tester, button('Lưu')), isTrue);
      await tester.tap(row('Tự động'));
      await tester.pumpAndSettle();
      expect(enabled(tester, button('Lưu')), isFalse);
    });

    testWidgets('a picked image is read first, then selected', (tester) async {
      cover.previewGate = Completer<void>();
      await open(tester);
      final image = pickedFile(dir, 'IMG_2041.jpg');
      picker.next = image;
      await tapPickRow(tester);
      await tester.pump();
      await tester.pump();
      expect(find.text('Đang đọc ảnh…'), findsOneWidget);
      expect(enabled(tester, button('Lưu')), isFalse);
      cover.previewGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Từ máy · 3024 × 4032'), findsOneWidget);
      expect(selected(tester, 'IMG_2041.jpg'), isTrue);
      expect(enabled(tester, button('Lưu')), isTrue);
      expect(
        find.text('Kéo ảnh để chọn phần hiện (ảnh được cắt vuông)'),
        findsOneWidget,
      );
    });

    testWidgets('album has no suggestion group, artist has one', (
      tester,
    ) async {
      await open(
        tester,
        kind: CustomCoverKind.album,
        opts: options(suggestions: const []),
      );
      expect(find.text('Bìa album trong playlist'), findsNothing);
      expect(find.text('Bìa album của nghệ sĩ'), findsNothing);
      expect(find.text('Bìa trong tệp nhạc'), findsOneWidget);
    });

    testWidgets('artist suggestions show title and year', (tester) async {
      await open(tester, kind: CustomCoverKind.artist);
      expect(find.text('Bìa album của nghệ sĩ'), findsOneWidget);
      expect(find.text('Bìa album · 1999'), findsOneWidget);
    });

    testWidgets('has no help icon', (tester) async {
      await open(tester);
      expect(find.byType(KHelpIcon), findsNothing);
    });
  });

  group('picked image', () {
    testWidgets('a small image shows the warning card', (tester) async {
      await open(tester);
      await pickImage(tester, size: (w: 240, h: 240));
      expect(find.textContaining('Ảnh nhỏ (240 × 240 px)'), findsOneWidget);
    });

    testWidgets('a big image shows no warning', (tester) async {
      await open(tester);
      await pickImage(tester);
      expect(find.textContaining('Ảnh nhỏ'), findsNothing);
    });

    CoverCrop? savedCrop() => (cover.changes.single.choice as FileCover).crop;

    testWidgets('saves the centre cut by default', (tester) async {
      await open(tester);
      await pickImage(tester);
      await tapSave(tester, 'Lưu');
      expect(savedCrop(), const CoverCrop(left: 0, top: 504, side: 3024));
    });

    testWidgets('dragging pans and clamps at the edges', (tester) async {
      await open(tester);
      await pickImage(tester);
      await tester.drag(find.byType(CoverPreviewFrame), const Offset(0, -2000));
      await tester.pump();
      await tapSave(tester, 'Lưu');
      expect(savedCrop(), const CoverCrop(left: 0, top: 1008, side: 3024));
    });

    testWidgets('arrow keys move 5 % while the frame has focus', (
      tester,
    ) async {
      await open(tester);
      await pickImage(tester);
      await tester.tap(find.byType(CoverPreviewFrame));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tapSave(tester, 'Lưu');
      expect(savedCrop(), const CoverCrop(left: 0, top: 554, side: 3024));
    });

    testWidgets('a square image has no crop and no pan hint', (tester) async {
      await open(tester);
      await pickImage(tester, size: (w: 1000, h: 1000));
      expect(find.textContaining('Kéo ảnh'), findsNothing);
      await tapSave(tester, 'Lưu');
      expect(savedCrop(), isNull);
    });
  });

  group('save', () {
    testWidgets('writes once, closes, shows Hoàn tác that undoes', (
      tester,
    ) async {
      await open(tester, opts: options(current: true));
      await tester.tap(row('Tự động'));
      await tester.pumpAndSettle();
      await tapSave(tester, 'Lưu');
      expect(cover.changes, hasLength(1));
      expect(cover.changes.single.choice, isA<AutomaticCover>());
      expect(find.byType(CoverDialog), findsNothing);
      expect(find.text('Đã dùng lại bìa tự động'), findsOneWidget);
      await tester.tap(find.text('Hoàn tác'));
      await tester.pump();
      expect(cover.change.undos, 1);
      expect(cover.change.releases, 0);
    });

    testWidgets('an undo that cannot be done says so', (tester) async {
      cover.change.undoResult = false;
      await open(tester, opts: options(current: true));
      await tester.tap(row('Tự động'));
      await tester.pumpAndSettle();
      await tapSave(tester, 'Lưu');
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(find.text('Không hoàn tác được'), findsOneWidget);
    });

    testWidgets('a snack bar that closes releases the change', (tester) async {
      await open(tester, opts: options(current: true));
      await tester.tap(row('Tự động'));
      await tester.pumpAndSettle();
      await tapSave(tester, 'Lưu');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(cover.change.releases, 1);
      expect(cover.change.undos, 0);
    });

    testWidgets('closing while it saves does not stop it', (tester) async {
      cover.gate = Completer<void>();
      await open(tester);
      final image = pickedFile(dir, 'big.jpg');
      picker.next = image;
      await tapPickRow(tester);
      await tester.pump();
      await flushIo(tester);
      await tester.tap(button('Lưu'));
      await tester.pump();
      // Rows are locked while it saves.
      await tester.tap(row('Tự động'));
      await tester.pump();
      expect(selected(tester, 'big.jpg'), isTrue);
      // Scrim tap closes the sheet; the job goes on.
      await tester.tapAt(const Offset(180, 10));
      await tester.pumpAndSettle();
      expect(find.byType(CoverDialog), findsNothing);
      expect(cover.changes, isEmpty);
      cover.gate!.complete();
      await tester.pump();
      await flushIo(tester);
      expect(cover.changes, hasLength(1));
      expect(find.text('Đã đổi ảnh bìa'), findsOneWidget);
      expect(image.file.existsSync(), isFalse);
      expect(cover.previews.every((f) => !f.existsSync()), isTrue);
    });

    testWidgets('a failed save shows the error and keeps the dialog', (
      tester,
    ) async {
      cover.changeError = const FormatException('bad');
      await open(tester);
      await tester.tap(row('Alpha'));
      await tester.pumpAndSettle();
      await tapSave(tester, 'Lưu');
      expect(
        find.text('Không dùng được ảnh này (chỉ hỗ trợ JPEG, PNG, WebP)'),
        findsOneWidget,
      );
      expect(find.byType(CoverDialog), findsOneWidget);
      expect(enabled(tester, button('Lưu')), isTrue);
    });
  });

  group('errors and cancel', () {
    testWidgets('a bad image shows the format text and leaves no row', (
      tester,
    ) async {
      cover.previewError = const FormatException('x');
      await open(tester);
      await pickImage(tester);
      expect(
        find.text('Không dùng được ảnh này (chỉ hỗ trợ JPEG, PNG, WebP)'),
        findsOneWidget,
      );
      expect(find.text('IMG_2041.jpg'), findsNothing);
      expect(selected(tester, 'Tự động'), isTrue);
    });

    testWidgets('an unreadable file shows the read text', (tester) async {
      cover.previewError = const FileSystemException('x');
      await open(tester);
      await pickImage(tester);
      expect(find.text('Không đọc được tệp ảnh. Thử lại sau.'), findsOneWidget);
      expect(find.byType(CoverDialog), findsOneWidget);
    });

    testWidgets('Huỷ writes nothing and deletes the temp files', (
      tester,
    ) async {
      await open(tester);
      final image = pickedFile(dir, 'tmp.jpg');
      picker.next = image;
      await tapPickRow(tester);
      await tester.pump();
      await flushIo(tester);
      expect(cover.previews, hasLength(1));
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
      await flushIo(tester);
      expect(cover.changes, isEmpty);
      expect(image.file.existsSync(), isFalse);
      expect(cover.previews.single.existsSync(), isFalse);
    });
  });

  group('form mode', () {
    testWidgets('Chọn returns a draft, writes nothing, keeps the files', (
      tester,
    ) async {
      await open(tester, form: true);
      expect(
        find.text('Lưu cùng các thay đổi khác khi bấm Lưu ở Sửa playlist'),
        findsOneWidget,
      );
      final image = pickedFile(dir, 'form.jpg');
      picker.next = image;
      await tapPickRow(tester);
      await tester.pump();
      await flushIo(tester);
      await tapSave(tester, 'Chọn');
      await flushIo(tester);
      final draft = formResult!;
      expect(draft.choice, isA<FileCover>());
      expect(cover.changes, isEmpty);
      expect(image.file.existsSync(), isTrue);
      expect(cover.previews.single.existsSync(), isTrue);
    });
  });

  group('errors above the dialog', () {
    const formatText = 'Không dùng được ảnh này (chỉ hỗ trợ JPEG, PNG, WebP)';
    final shells = <String, Size>{
      'mobile sheet': const Size(360, 800),
      'desktop dialog': const Size(1280, 800),
    };
    for (final MapEntry(key: name, value: size) in shells.entries) {
      testWidgets('a bad image error is inside the dialog: $name', (
        tester,
      ) async {
        cover.previewError = const FormatException('x');
        await open(tester, size: size);
        await pickImage(tester);
        // Inside the dialog's own messenger, so above the modal.
        expect(
          find.descendant(
            of: find.byType(CoverDialog),
            matching: find.text(formatText),
          ),
          findsOneWidget,
        );
      });

      testWidgets('a failed save error is inside the dialog: $name', (
        tester,
      ) async {
        cover.changeError = const FormatException('bad');
        await open(tester, size: size);
        await tester.tap(row('Alpha'));
        await tester.pumpAndSettle();
        await tapSave(tester, 'Lưu');
        expect(
          find.descendant(
            of: find.byType(CoverDialog),
            matching: find.text(formatText),
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('the success snack bar stays on the root messenger', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(row('Alpha'));
      await tester.pumpAndSettle();
      await tapSave(tester, 'Lưu');
      expect(find.text('Đã đổi ảnh bìa'), findsOneWidget);
      expect(find.byType(CoverDialog), findsNothing);
    });
  });

  group('accessibility', () {
    testWidgets('the pannable frame has a label and takes focus', (
      tester,
    ) async {
      await open(tester);
      await pickImage(tester);
      final frame = find.byType(CoverPreviewFrame);
      expect(
        tester.getSemantics(
          find.descendant(
            of: frame,
            matching: find.bySemanticsLabel(RegExp('Kéo ảnh')),
          ),
        ),
        isSemantics(isFocusable: true),
      );
      await tester.tap(frame);
      await tester.pump();
      expect(
        tester.getSemantics(
          find.descendant(
            of: frame,
            matching: find.bySemanticsLabel(RegExp('Kéo ảnh')),
          ),
        ),
        isSemantics(isFocused: true),
      );
    });

    testWidgets('a square image gives the frame no focus stop', (tester) async {
      await open(tester);
      await pickImage(tester, size: (w: 1000, h: 1000));
      expect(
        find.descendant(
          of: find.byType(CoverPreviewFrame),
          matching: find.byType(Focus),
        ),
        findsNothing,
      );
    });

    testWidgets('the small-image card is a live region', (tester) async {
      await open(tester);
      await pickImage(tester, size: (w: 240, h: 240));
      expect(
        tester.getSemantics(find.textContaining('Ảnh nhỏ (240 × 240 px)')),
        isSemantics(isLiveRegion: true),
      );
    });

    testWidgets('tapping a row while it saves changes nothing', (tester) async {
      cover.gate = Completer<void>();
      await open(tester);
      await tester.tap(row('Alpha'));
      await tester.pumpAndSettle();
      await tester.tap(button('Lưu'));
      await tester.pump();
      await tester.tap(row('Tự động'));
      await tester.pump();
      expect(selected(tester, 'Alpha'), isTrue);
      // Rows expose no disabled state in semantics; the tap is ignored.
      expect(selected(tester, 'Tự động'), isFalse);
      cover.gate!.complete();
      await tester.pump();
      await flushIo(tester);
    });

    testWidgets('Tab goes frame, rows, Chọn ảnh, Huỷ, Lưu', (tester) async {
      await open(tester);
      await pickImage(tester);
      await tester.tap(find.byType(CoverPreviewFrame));
      await tester.pump();
      String? focusedText() {
        final ctx = FocusManager.instance.primaryFocus?.context;
        if (ctx == null) return null;
        String? found;
        void visit(Element e) {
          if (found != null) return;
          final w = e.widget;
          if (w is Text && w.data != null) {
            found = w.data;
            return;
          }
          e.visitChildren(visit);
        }

        (ctx as Element).visitChildren(visit);
        return found;
      }

      final stops = <String?>[];
      for (var i = 0; i < 40 && !stops.contains('Lưu'); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        stops.add(focusedText());
      }
      final pick = stops.indexWhere((t) => t?.startsWith('Chọn ảnh') ?? false);
      final cancel = stops.indexOf('Huỷ');
      final save = stops.indexOf('Lưu');
      expect(pick, greaterThan(0));
      expect(cancel, greaterThan(pick));
      expect(save, greaterThan(cancel));
    });
  });

  group('layout', () {
    final cases = <(String, Size, double, Brightness, bool)>[
      ('360x800', const Size(360, 800), 1, Brightness.light, true),
      ('800x1280', const Size(800, 1280), 1, Brightness.light, true),
      ('1280x800', const Size(1280, 800), 1, Brightness.light, true),
      ('200% text', const Size(360, 800), 2, Brightness.light, true),
      ('200% text desktop', const Size(1280, 800), 2, Brightness.light, true),
      ('dark', const Size(360, 800), 1, Brightness.dark, true),
      ('animations off', const Size(1280, 800), 1, Brightness.light, false),
    ];
    for (final (name, size, scale, brightness, animations) in cases) {
      testWidgets('no overflow: $name', (tester) async {
        final long = 'Một tên album rất dài ' * 6;
        await open(
          tester,
          size: size,
          textScale: scale,
          brightness: brightness,
          animations: animations,
          opts: options(
            current: true,
            suggestions: [
              for (var i = 0; i < 6; i++) suggestion('$long$i', year: 2000 + i),
            ],
          ),
        );
        await pickImage(
          tester,
          name: '${'tệp dài ' * 20}.jpg',
          size: (w: 240, h: 320),
        );
        expect(tester.takeException(), isNull);
        if (size.width >= 1200) {
          expect(
            tester.getSize(find.byType(CoverDialog)).width,
            lessThanOrEqualTo(KLayout.dialog),
          );
        }
      });
    }
  });
}
