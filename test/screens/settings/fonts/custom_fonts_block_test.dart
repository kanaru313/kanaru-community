import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/fonts/data/custom_font_store.dart';
import 'package:kanaru/src/fonts/data/font_registrar.dart';
import 'package:kanaru/src/fonts/data/font_storage.dart';
import 'package:kanaru/src/fonts/domain/custom_font.dart';
import 'package:kanaru/src/fonts/state/custom_fonts.dart';
import 'package:kanaru/src/fonts/state/font_providers.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';
import 'package:kanaru/src/platform/state/document_picker_provider.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru/src/screens/settings/ui/appearance/fonts/font_choice_row.dart';
import 'package:material_ui/material_ui.dart';

import '../../../fonts/support/font_bytes.dart';
import '../../../support/icon_button_finders.dart';
import '../support/settings_host.dart';

class _Paths implements AppPaths {
  _Paths(this.dataDir);
  @override
  final Directory dataDir;
  @override
  Directory get cacheDir => dataDir;
  @override
  Directory get configDir => dataDir;
}

/// A picker that returns what the test sets and counts its calls.
class _Picker implements DocumentPicker {
  PickedDocument? doc;
  Result<Uint8List, DocumentError> content = const Err(
    DocumentError.unreadable,
  );
  Object? failure;
  int opened = 0;

  @override
  Future<PickedDocument?> openDocument(DocumentFilter filter) async {
    opened++;
    final f = failure;
    if (f != null) throw f;
    return doc;
  }

  @override
  Future<Result<Uint8List, DocumentError>> read(
    PickedDocument doc, {
    required int maxBytes,
  }) async => content;

  @override
  Future<SaveTarget?> createDocument({
    required String suggestedName,
    DocumentFilter? filter,
  }) async => null;
  @override
  Future<Result<void, DocumentError>> write(SaveTarget t, Uint8List b) async =>
      const Ok(null);
  @override
  Future<void> discard(SaveTarget target) async {}
}

PickedDocument _doc(String name) =>
    PickedDocument(name: name, handle: '/x/$name', localPath: '/x/$name');

void main() {
  late Directory tmp;
  late FontStorage storage;
  late _Picker picker;
  late List<String> registered;
  late Map<String, Completer<void>> gates;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('custom_fonts_block');
    storage = FontStorage(_Paths(tmp));
    picker = _Picker();
    registered = [];
    gates = {};
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  /// Real file IO needs real time: let it run, then settle the frames.
  Future<void> settle(WidgetTester tester) async {
    // Every file step finishes in real time and then needs a frame to go on.
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 15)),
      );
      await tester.pumpAndSettle();
    }
  }

  Future<List<CustomFont>> seed(WidgetTester tester, List<String> names) async {
    final fonts = <CustomFont>[];
    await tester.runAsync(() async {
      final store = CustomFontStore(storage);
      for (final n in names) {
        fonts.add(
          await store.importBytes(
            '$n.ttf',
            ttf([(platform: 3, id: 1, text: n)]),
          ),
        );
      }
    });
    return fonts;
  }

  Future<SettingsHarness> pump(
    WidgetTester tester, {
    Size size = const Size(400, 900),
    Map<String, Object?> settings = const {},
  }) async {
    final registrar = FontRegistrar(
      registrar: (family, _) async {
        registered.add(family);
        await gates[family]?.future;
      },
    );
    return pumpSettings(
      tester,
      location: SettingsPaths.fonts,
      size: size,
      scaffold: true,
      overrides: [
        fontStorageProvider.overrideWithValue(storage),
        fontLoaderProvider.overrideWithValue(registrar),
        documentPickerProvider.overrideWithValue(picker),
      ],
    );
  }

  Future<void> importThroughDialog(WidgetTester tester) async {
    await tester.tap(find.text('Import font'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose file…'));
    await settle(tester);
  }

  Finder row(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(FontChoiceRow));

  testWidgets('shows the block with its hint and the import row', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('Import font'), findsOneWidget);
    expect(find.byType(FontChoiceRow), findsNWidgets(3 + 7));
  });

  testWidgets('desktop import row opens a dialog and says so', (tester) async {
    await pump(tester, size: const Size(1400, 900));
    expect(find.text('Import font…'), findsOneWidget);
  });

  testWidgets('cancelling the consent dialog never opens the picker', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Import font'));
    await tester.pumpAndSettle();
    expect(find.text('Import font'), findsNWidgets(2)); // row + dialog title
    expect(
      find.textContaining('Only import fonts you have the right to use'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(picker.opened, 0);
  });

  testWidgets('cancelling the file dialog changes nothing', (tester) async {
    await pump(tester);
    await importThroughDialog(tester);
    expect(picker.opened, 1);
    expect(find.byType(SnackBar), findsNothing);
    expect(storage.customDir.existsSync(), isFalse);
  });

  testWidgets('a good file is listed, announced and not applied', (
    tester,
  ) async {
    final h = await pump(tester);
    picker
      ..doc = _doc('Whatever.ttf')
      ..content = Ok(nunitoBytes());
    await importThroughDialog(tester);
    expect(find.text('Imported “Nunito” · tap to use'), findsOneWidget);
    expect(row('Nunito'), findsOneWidget);
    expect(h.container.read(customFontsProvider), hasLength(1));
    expect(h.store.read('app.font'), isNull);
  });

  testWidgets('the same file twice is listed once', (tester) async {
    await pump(tester);
    picker
      ..doc = _doc('a.ttf')
      ..content = Ok(nunitoBytes());
    await importThroughDialog(tester);
    await importThroughDialog(tester);
    expect(find.text('Imported “Nunito” · tap to use'), findsOneWidget);
    expect(find.byType(FontChoiceRow), findsNWidgets(3 + 1 + 7));
  });

  testWidgets('a file over the limit says so and keeps nothing', (
    tester,
  ) async {
    await pump(tester);
    picker
      ..doc = _doc('big.ttf')
      ..content = const Err(DocumentError.tooLarge);
    await importThroughDialog(tester);
    expect(
      find.text('The font file is too large (20 MB at most).'),
      findsOneWidget,
    );
    expect(storage.customDir.existsSync(), isFalse);
  });

  testWidgets('a file that is not a font says so and keeps nothing', (
    tester,
  ) async {
    await pump(tester);
    picker
      ..doc = _doc('fake.ttf')
      ..content = Ok(Uint8List.fromList(List.filled(100, 7)));
    await importThroughDialog(tester);
    expect(find.text('This file is not a .ttf or .otf font.'), findsOneWidget);
    expect(storage.customDir.existsSync(), isFalse);
  });

  testWidgets('an unreadable file and a wrong extension give the same note', (
    tester,
  ) async {
    await pump(tester);
    picker
      ..doc = _doc('a.ttf')
      ..content = const Err(DocumentError.unreadable);
    await importThroughDialog(tester);
    expect(find.text('This file is not a .ttf or .otf font.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    picker
      ..doc = _doc('notes.txt')
      ..content = Ok(nunitoBytes());
    await importThroughDialog(tester);
    expect(find.text('This file is not a .ttf or .otf font.'), findsOneWidget);
    expect(storage.customDir.existsSync(), isFalse);
  });

  testWidgets('a failing file dialog is reported, nothing is kept', (
    tester,
  ) async {
    await pump(tester);
    picker.failure = const DocumentPickerException(
      DocumentPickerFailure.unavailable,
    );
    await importThroughDialog(tester);
    expect(find.text('This file is not a .ttf or .otf font.'), findsOneWidget);
  });

  testWidgets('deleting asks first; cancel keeps the font', (tester) async {
    await seed(tester, ['Alpha']);
    await pump(tester);
    await tester.tap(byIconButton('Delete Alpha'));
    await tester.pumpAndSettle();
    expect(find.text('Delete the font “Alpha”?'), findsOneWidget);
    expect(
      find.text(
        'The imported font file is deleted from Kanaru. To use it again you have to import it again.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(row('Alpha'), findsOneWidget);
  });

  testWidgets('confirming deletes the font and its folder', (tester) async {
    final fonts = await seed(tester, ['Alpha', 'Beta']);
    await pump(tester);
    await tester.tap(byIconButton('Delete Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(find.text('Font deleted'), findsOneWidget);
    expect(row('Alpha'), findsNothing);
    expect(row('Beta'), findsOneWidget);
    expect(
      Directory('${storage.customDir.path}/${fonts.first.id}').existsSync(),
      isFalse,
    );
  });

  testWidgets('the font in use shows a tick and has no delete button', (
    tester,
  ) async {
    await seed(tester, ['Alpha', 'Beta']);
    final h = await pump(tester);
    expect(byIconButton('Delete Alpha'), findsOneWidget);
    await tester.tap(row('Alpha'));
    await settle(tester);
    expect(find.text('Font changed'), findsOneWidget);
    expect(byIconButton('Delete Alpha'), findsNothing);
    expect(byIconButton('Delete Beta'), findsOneWidget);
    final fonts = h.container.read(customFontsProvider);
    expect(h.container.read(activeFontIdProvider), fonts.first.id);
    expect(
      () =>
          h.container.read(customFontsProvider.notifier).delete(fonts.first.id),
      throwsStateError,
    );
  });

  testWidgets('rows are sorted by name, ignoring case', (tester) async {
    await seed(tester, ['beta', 'Alpha', 'Charlie']);
    await pump(tester);
    final titles = [
      for (final r in tester.widgetList<FontChoiceRow>(
        find.byType(FontChoiceRow),
      ))
        r.title,
    ];
    final custom = titles.where(
      (t) => ['Alpha', 'beta', 'Charlie'].contains(t),
    );
    expect(custom, ['Alpha', 'beta', 'Charlie']);
  });

  testWidgets('every imported font loads at once and draws in its face', (
    tester,
  ) async {
    final fonts = await seed(tester, ['Alpha', 'Beta']);
    gates = {for (final f in fonts) f.id: Completer<void>()};
    await pump(tester);
    await settle(tester);
    // Both loads started before either finished.
    expect(registered, unorderedEquals(fonts.map((f) => f.id)));
    FontChoiceRow rowOf(String n) => tester.widget<FontChoiceRow>(row(n));
    expect(rowOf('Alpha').family, isNull);
    gates[fonts.first.id]!.complete();
    await tester.pumpAndSettle();
    expect(rowOf('Alpha').family, fonts.first.id);
    expect(rowOf('Beta').family, isNull);
  });

  testWidgets('a font that fails to load keeps the app font in its row', (
    tester,
  ) async {
    final fonts = await seed(tester, ['Alpha']);
    final failing = Completer<void>();
    failing.future.ignore();
    failing.completeError(StateError('x'));
    gates = {fonts.single.id: failing};
    await pump(tester);
    await settle(tester);
    expect(tester.widget<FontChoiceRow>(row('Alpha')).family, isNull);
    expect(find.text('Alpha'), findsOneWidget);
  });
}
