import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/fonts/data/font_downloader.dart';
import 'package:kanaru/src/fonts/data/font_registrar.dart';
import 'package:kanaru/src/fonts/data/font_storage.dart';
import 'package:kanaru/src/fonts/domain/app_font.dart';
import 'package:kanaru/src/fonts/domain/font_catalog.dart';
import 'package:kanaru/src/fonts/state/font_downloads.dart';
import 'package:kanaru/src/fonts/state/font_providers.dart';
import 'package:kanaru/src/fonts/state/installed_catalog_fonts.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/plugins/data/net/fetcher.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru/src/screens/settings/ui/appearance/fonts/font_choice_row.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

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

/// Finishes (or fails) a download when the test says so, then leaves the font
/// on disk like the real one.
class _FakeDownloader extends FontDownloader {
  _FakeDownloader(FontStorage storage)
    : _storage = storage,
      super(
        fetcher: HttpFetcher(),
        storage: storage,
        registrar: FontRegistrar(registrar: (_, _) async {}),
      );

  final FontStorage _storage;
  final gate = Completer<void>();
  Object? error;
  final started = <String>[];

  @override
  Future<void> download(CatalogFont font) async {
    started.add(font.id);
    await gate.future;
    final e = error;
    if (e != null) throw e;
    final dir = _storage.fontDir(font.asAppFont.kind, font.id)
      ..createSync(recursive: true);
    File('${dir.path}/a.ttf').writeAsBytesSync([1]);
  }
}

/// Loads nothing: real file reads never finish under the test's fake clock.
class _InstantRegistrar extends FontRegistrar {
  @override
  Future<void> ensureLoaded(AppFont font, FontStorage storage) =>
      Future.value();
}

void main() {
  late Directory tmp;
  late FontStorage storage;
  late _FakeDownloader downloader;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('catalog_block');
    storage = FontStorage(_Paths(tmp));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  void install(String id) {
    final dir = storage.fontDir(AppFontKind.catalog, id)
      ..createSync(recursive: true);
    File('${dir.path}/a.ttf').writeAsBytesSync([1]);
  }

  Future<SettingsHarness> pump(
    WidgetTester tester, {
    Widget home = const SizedBox.shrink(),
  }) {
    // Made here, inside the test body: a completer from setUp would not run
    // under the test's fake clock.
    downloader = _FakeDownloader(storage);
    return pumpSettings(
      tester,
      location: SettingsPaths.fonts,
      size: const Size(400, 1600),
      scaffold: true,
      home: home,
      overrides: [
        fontStorageProvider.overrideWithValue(storage),
        fontLoaderProvider.overrideWithValue(_InstantRegistrar()),
        fontDownloaderProvider.overrideWithValue(downloader),
      ],
    );
  }

  Finder row(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(FontChoiceRow));
  Finder inRow(String name, Finder f) =>
      find.descendant(of: row(name), matching: f);
  Finder button(String tooltip) =>
      find.byWidgetPredicate((w) => w is KIconButton && w.tooltip == tooltip);
  Finder download(String name) => button('Download $name');
  Finder delete(String name) => button('Delete $name');

  testWidgets('downloaded fonts come first, then the rest in catalog order', (
    tester,
  ) async {
    install('lexend');
    install('roboto');
    await pump(tester);
    final names = [
      for (final f in tester.widgetList<FontChoiceRow>(
        find.byType(FontChoiceRow),
      ))
        f.title,
    ].skip(3).toList();
    expect(names, [
      'Roboto',
      'Lexend',
      'Be Vietnam Pro',
      'Plus Jakarta Sans',
      'Lora',
      'Fira Sans',
      'JetBrains Mono',
    ]);
    expect(find.text('Online fonts'), findsOneWidget);
  });

  testWidgets('trailing states: size and download, delete, nothing for tap', (
    tester,
  ) async {
    install('lora');
    await pump(tester);
    expect(inRow('Be Vietnam Pro', find.text('160 KB')), findsOneWidget);
    expect(download('Be Vietnam Pro'), findsOneWidget);
    expect(delete('Be Vietnam Pro'), findsNothing);
    expect(delete('Lora'), findsOneWidget);
    expect(download('Lora'), findsNothing);
    // A font that is not downloaded does nothing when its row is tapped.
    await tester.tap(find.text('Fira Sans'));
    await tester.pumpAndSettle();
    expect(downloader.started, isEmpty);
    expect(find.text('Font changed'), findsNothing);
  });

  testWidgets('download shows a spinner, then the delete button and a note', (
    tester,
  ) async {
    final h = await pump(tester);
    await tester.tap(download('Lora'));
    await tester.pump();
    expect(
      inRow('Lora', find.byType(CircularProgressIndicator)),
      findsOneWidget,
    );
    expect(download('Lora'), findsNothing);
    expect(h.container.read(fontDownloadsProvider), {'lora'});
    downloader.gate.complete();
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Font downloaded'), findsOneWidget);
    expect(delete('Lora'), findsOneWidget);
    expect(h.container.read(activeFontIdProvider), 'nunito');
    expect(h.container.read(fontDownloadsProvider), isEmpty);
  });

  testWidgets('a failed download says so and can be tried again', (
    tester,
  ) async {
    await pump(tester);
    downloader.error = const FontDownloadException('network');
    await tester.tap(download('Lora'));
    await tester.pump();
    downloader.gate.complete();
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Couldn't download the font Lora. Check your connection and try again.",
      ),
      findsOneWidget,
    );
    expect(download('Lora'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a second tap on the button while downloading is ignored', (
    tester,
  ) async {
    final h = await pump(tester);
    await tester.tap(download('Lora'));
    await tester.pump();
    final result = await h.container
        .read(fontDownloadsProvider.notifier)
        .download(catalogFontById('lora')!);
    expect(result, FontDownloadResult.ignored);
    expect(downloader.started, ['lora']);
    downloader.gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('a download that ends after the page closed still tells', (
    tester,
  ) async {
    final h = await pump(tester);
    await tester.tap(download('Lora'));
    await tester.pump();
    h.router.go('/');
    await tester.pumpAndSettle();
    downloader.gate.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Font downloaded'), findsOneWidget);
    expect(h.container.read(installedCatalogFontsProvider), {'lora'});
  });

  testWidgets(
    'delete is immediate, says so, and the font can be fetched again',
    (tester) async {
      install('lora');
      final h = await pump(tester);
      await tester.tap(delete('Lora'));
      await tester.pumpAndSettle();
      expect(
        find.text('Font deleted (you can download it again)'),
        findsOneWidget,
      );
      expect(download('Lora'), findsOneWidget);
      expect(storage.installedCatalogIds(), isEmpty);
      expect(h.container.read(installedCatalogFontsProvider), isEmpty);
    },
  );

  testWidgets('the active font has no delete and the state layer refuses it', (
    tester,
  ) async {
    install('lora');
    final h = await pump(tester);
    await h.store.write('app.font', 'lora');
    await tester.pumpAndSettle();
    expect(delete('Lora'), findsNothing);
    expect(
      () => h.container
          .read(installedCatalogFontsProvider.notifier)
          .delete('lora'),
      throwsStateError,
    );
    expect(storage.installedCatalogIds(), {'lora'});
  });

  testWidgets('delete is refused for a font that is downloading', (
    tester,
  ) async {
    final h = await pump(tester);
    await tester.tap(download('Lora'));
    await tester.pump();
    expect(
      () => h.container
          .read(installedCatalogFontsProvider.notifier)
          .delete('lora'),
      throwsStateError,
    );
    downloader.gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('tapping a downloaded font uses it', (tester) async {
    install('lora');
    final h = await pump(tester);
    await tester.tap(find.text('Lora'));
    await tester.pumpAndSettle();
    expect(h.container.read(activeFontIdProvider), 'lora');
    expect(find.text('Font changed'), findsOneWidget);
  });
}
