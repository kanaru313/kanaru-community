import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/fonts/data/font_registrar.dart';
import 'package:kanaru/src/fonts/data/font_storage.dart';
import 'package:kanaru/src/fonts/domain/app_font.dart';
import 'package:kanaru/src/fonts/state/font_providers.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru/src/screens/settings/ui/appearance/fonts/font_choice_row.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import '../../../support/memory_settings_store.dart';
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

/// Loads `inter` only when [gate] completes (or fails with [error]); every
/// other font is ready at once.
class _GatedRegistrar extends FontRegistrar {
  final gate = Completer<void>();
  Object? error;

  @override
  Future<void> ensureLoaded(AppFont font, FontStorage storage) {
    if (font.id != 'inter') return Future.value();
    final e = error;
    if (e != null) return Future.error(e);
    return gate.future;
  }
}

/// A store whose writes fail once [failWrites] is set.
class _FailingStore extends MemorySettingsStore {
  bool failWrites = false;

  @override
  Future<void> write(String key, Object? value) async {
    if (failWrites) throw const FileSystemException('read-only');
    await super.write(key, value);
  }
}

/// The row of the font named [name].
Finder _row(String name) => find.ancestor(
  of: find.textContaining(name),
  matching: find.byType(FontChoiceRow),
);

/// Expects the row of [name] to report [selected] through semantics.
void _expectSelected(WidgetTester tester, String name, bool selected) => expect(
  tester.getSemantics(_row(name)),
  isSemantics(isButton: true, isSelected: selected),
  reason: name,
);

void main() {
  const tall = Size(400, 900);

  Future<SettingsHarness> pump(
    WidgetTester tester, {
    _GatedRegistrar? loader,
  }) => pumpSettings(
    tester,
    location: SettingsPaths.fonts,
    size: tall,
    scaffold: true,
    overrides: [
      fontStorageProvider.overrideWithValue(
        FontStorage(_Paths(Directory.systemTemp)),
      ),
      if (loader != null) fontLoaderProvider.overrideWithValue(loader),
    ],
  );

  testWidgets('shows the three built-in fonts, the default is active', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    expect(find.text('Built in'), findsOneWidget);
    expect(find.textContaining('Nunito'), findsOneWidget);
    expect(find.text('Inter'), findsOneWidget);
    expect(find.text('System font'), findsOneWidget);
    expect(find.text('Aa Bb Cc Gg Qq Rr Yy 0123456789'), findsNWidgets(10));
    _expectSelected(tester, 'Nunito', true);
    _expectSelected(tester, 'Inter', false);
    _expectSelected(tester, 'System font', false);
    semantics.dispose();
  });

  testWidgets('tapping Inter changes the font and says so', (tester) async {
    final semantics = tester.ensureSemantics();
    final h = await pump(tester);
    await tester.tap(find.text('Inter'));
    await tester.pumpAndSettle();
    expect(h.container.read(activeFontIdProvider), 'inter');
    expect(h.store.read('app.font'), 'inter');
    expect(find.text('Font changed'), findsOneWidget);
    _expectSelected(tester, 'Inter', true);
    _expectSelected(tester, 'Nunito', false);
    semantics.dispose();
  });

  testWidgets('tapping the active font does nothing', (tester) async {
    final h = await pump(tester);
    await tester.tap(find.textContaining('Nunito'));
    await tester.pumpAndSettle();
    expect(find.text('Font changed'), findsNothing);
    expect(h.store.read('app.font'), isNull);
  });

  testWidgets('two quick taps end on the second font', (tester) async {
    final loader = _GatedRegistrar();
    final h = await pump(tester, loader: loader);
    await tester.tap(find.text('Inter'));
    await tester.pump();
    await tester.tap(find.text('System font'));
    await tester.pumpAndSettle();
    expect(h.container.read(activeFontIdProvider), 'system');
    // The slow first request finishes late and must not win.
    loader.gate.complete();
    await tester.pumpAndSettle();
    expect(h.container.read(activeFontIdProvider), 'system');
    expect(h.store.read('app.font'), 'system');
    expect(find.text('Font changed'), findsOneWidget);
  });

  testWidgets('a font that cannot be loaded keeps the old one', (tester) async {
    final loader = _GatedRegistrar()..error = StateError('no file');
    final h = await pump(tester, loader: loader);
    await tester.tap(find.text('Inter'));
    await tester.pumpAndSettle();
    expect(h.container.read(activeFontIdProvider), 'nunito');
    expect(h.store.read('app.font'), isNull);
    expect(find.text("Couldn't use the font Inter."), findsOneWidget);
    expect(find.text('Font changed'), findsNothing);
  });

  testWidgets('a font that cannot be saved keeps the old one', (tester) async {
    final store = _FailingStore();
    final h = await pumpSettings(
      tester,
      location: SettingsPaths.fonts,
      size: tall,
      scaffold: true,
      store: store,
      overrides: [
        fontStorageProvider.overrideWithValue(
          FontStorage(_Paths(Directory.systemTemp)),
        ),
      ],
    );
    store.failWrites = true;
    await tester.tap(find.text('Inter'));
    await tester.pumpAndSettle();
    expect(h.container.read(activeFontIdProvider), 'nunito');
    expect(find.text("Couldn't use the font Inter."), findsOneWidget);
    expect(find.text('Font changed'), findsNothing);
  });

  testWidgets('desktop header arrow leads to Appearance', (tester) async {
    final h = await pumpSettings(
      tester,
      location: SettingsPaths.fonts,
      size: const Size(1400, 900),
      scaffold: true,
      overrides: [
        fontStorageProvider.overrideWithValue(
          FontStorage(_Paths(Directory.systemTemp)),
        ),
      ],
    );
    await tester.tap(byIconButton('Back'));
    await tester.pumpAndSettle();
    expect(
      h.router.routerDelegate.currentConfiguration.last.matchedLocation,
      SettingsPaths.appearance,
    );
  });

  testWidgets('desktop shows the same block', (tester) async {
    await pumpSettings(
      tester,
      location: SettingsPaths.fonts,
      size: const Size(1400, 900),
      scaffold: true,
      overrides: [
        fontStorageProvider.overrideWithValue(
          FontStorage(_Paths(Directory.systemTemp)),
        ),
      ],
    );
    expect(find.text('Built in'), findsOneWidget);
    expect(find.text('Inter'), findsOneWidget);
  });
}
