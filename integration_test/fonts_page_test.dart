import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:material_ui/material_ui.dart'
    show Scaffold, Text, Theme, Tooltip;
import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart' show Offset, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/fonts/domain/font_catalog.dart';
import 'package:kanaru/src/fonts/state/font_providers.dart';
import 'package:kanaru/src/fonts/state/installed_catalog_fonts.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';

import 'support/harness.dart';

/// Settings › Giao diện › Phông chữ on the real app, Linux, desktop width
/// (1400 wide). Downloads one catalog font from the real release (network),
/// selects it, opens the import consent dialog and walks back with the header
/// arrow and Esc. Asserts state (providers, theme family, widget presence),
/// never icons. Screenshots of the app window only go to
/// `FONT_SHOTS_DIR` (default `/tmp/kanaru-it/shots`).
///
/// The flutter_test tooltip finder matches the Flutter SDK's Tooltip only; the
/// app builds its tooltips with `material_ui`, so match that class by message.
Finder tooltipWith(String message) =>
    find.byWidgetPredicate((w) => w is Tooltip && w.message == message);

/// Run: `tool/integration_test.sh linux integration_test/fonts_page_test.dart`
/// (through the main checkout's `main-build.sh`).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final shotsDir =
      Platform.environment['FONT_SHOTS_DIR'] ?? '/tmp/kanaru-it/shots';

  testWidgets('font page: download, select, import dialog, back on desktop', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 400));
      final dir = Directory(shotsDir)..createSync(recursive: true);
      final view = tester.binding.renderViews.first;
      final layer = view.debugLayer! as OffsetLayer;
      final image = await layer.toImage(Offset.zero & view.size);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      File('${dir.path}/linux-fonts-desktop-$name.png')
          .writeAsBytesSync(bytes.buffer.asUint8List());
      debugPrint('shot linux-fonts-desktop-$name');
      // Keep the binding quiet between screenshots (no pumpAndSettle hang on
      // the spinner).
      await tester.pump(const Duration(milliseconds: 100));
    }

    final app = await startKanaru(tester);
    final container = app.container;
    final router = container.read(routerProvider);
    // Localizations sit below KanaruApp: read them from any Text on the page.
    final l10n = AppLocalizations.of(tester.element(find.byType(Text).first));

    // Target: first catalog font that is not installed yet (the fixtures
    // start with none). Deleting it at the end keeps the dev data as found.
    final installed = container.read(installedCatalogFontsProvider);
    final font = catalogFonts.firstWhere((f) => !installed.contains(f.id));
    expect(
      installed.contains(font.id),
      isFalse,
      reason: 'start with ${font.id} not downloaded',
    );

    // 1. Giao diện row of Settings › Giao diện.
    router.go(SettingsPaths.appearance);
    await tester.pump();
    await app.pumpUntil(
      () => find.text(l10n.settingsAppearanceFont).evaluate().isNotEmpty,
      what: 'Giao diện page with the Phông chữ row',
    );
    await shot('01-appearance-row');

    // 2. Phông chữ page: the three blocks.
    await tester.tap(find.text(l10n.settingsAppearanceFont).first);
    await app.pumpUntil(
      () => find.text(l10n.fontsCatalogTitle).evaluate().isNotEmpty,
      what: 'Phông chữ page',
    );
    expect(find.text(l10n.fontsBuiltInTitle), findsOneWidget);
    expect(find.text(l10n.fontsCustomTitle), findsOneWidget);
    await shot('02-fonts-page');

    // 3. Live download of one catalog font: spinner, then delete button and
    // the row in its own face.
    final download = tooltipWith(l10n.fontsDownloadTooltip(font.label));
    expect(download, findsOneWidget);
    final started = DateTime.now();
    await tester.tap(download);
    await tester.pump();
    await app.pumpUntil(
      () =>
          find
              .bySemanticsLabel(l10n.fontsDownloading(font.label))
              .evaluate()
              .isNotEmpty ||
          container.read(installedCatalogFontsProvider).contains(font.id),
      what: 'download spinner (or the font already done)',
      timeout: const Duration(seconds: 5),
    );
    await shot('03-downloading');
    await app.pumpUntil(
      () => container.read(installedCatalogFontsProvider).contains(font.id),
      what: 'live download of ${font.id} from the release',
      timeout: const Duration(seconds: 120),
    );
    final took = DateTime.now().difference(started);
    debugPrint('download ${font.id} took ${took.inMilliseconds} ms');
    await app.pumpUntil(
      () =>
          tooltipWith(l10n.fontsDeleteTooltip(font.label))
              .evaluate()
              .isNotEmpty,
      what: 'delete button on the downloaded row',
    );
    expect(find.text(l10n.fontsDownloaded), findsWidgets);
    await shot('04-downloaded');

    // 4. Select it: the choice moves and the app text takes its family.
    await tester.tap(find.text(font.label).first);
    await app.pumpUntil(
      () => container.read(activeFontIdProvider) == font.id,
      what: 'font ${font.id} selected',
    );
    // The snack bar of the download may still be up: the next one waits for it.
    await app.pumpUntil(
      () => find.text(l10n.fontsChanged).evaluate().isNotEmpty,
      what: 'Font changed snack bar',
      timeout: const Duration(seconds: 15),
    );
    final family = Theme.of(tester.element(find.byType(Scaffold).first))
        .textTheme
        .bodyLarge
        ?.fontFamily;
    debugPrint('theme bodyLarge family after select: $family');
    await shot('05-selected');

    // 5. Import consent dialog (the picker is not opened: no GTK dialog in
    // the self-check). Esc closes it.
    await tester.tap(find.text(l10n.fontsImportRowDialog));
    await app.pumpUntil(
      () => find.text(l10n.fontsImportTitle).evaluate().isNotEmpty,
      what: 'import consent dialog',
    );
    await shot('06-import-dialog');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await app.pumpUntil(
      () => find.text(l10n.fontsImportTitle).evaluate().isEmpty,
      what: 'import dialog closed by Esc',
    );

    // 6. Back to Giao diện with the header arrow.
    await tester.tap(tooltipWith(l10n.tooltipBack).first);
    await app.pumpUntil(
      () =>
          find.text(l10n.settingsAppearanceFont).evaluate().isNotEmpty &&
          find.text(l10n.fontsCatalogTitle).evaluate().isEmpty,
      what: 'back on Giao diện',
    );
    expect(
      router.routeInformationProvider.value.uri.path,
      SettingsPaths.appearance,
    );
    await shot('07-back-arrow');

    // 7. Esc goes back too (from the font page again).
    await tester.tap(find.text(l10n.settingsAppearanceFont).first);
    await app.pumpUntil(
      () => find.text(l10n.fontsCatalogTitle).evaluate().isNotEmpty,
      what: 'font page again',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await app.pumpUntil(
      () =>
          router.routeInformationProvider.value.uri.path ==
          SettingsPaths.appearance,
      what: 'Esc back to Giao diện',
    );
    await shot('08-esc-back');

    semantics.dispose();
  });
}
