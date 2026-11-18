import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru_ui/src/widgets/k_fab_menu_parts.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';
import 'support/scaled_host.dart';

/// Minimal Router with a root back dispatcher, so [BackButtonListener]s are
/// live; [shellBacks] counts Back presses that reached the "shell" listener
/// above the page (the one the menu must pre-empt while it is open).
class _Delegate extends RouterDelegate<Object> with ChangeNotifier {
  _Delegate(this.page, this.onShellBack);

  final WidgetBuilder page;
  final VoidCallback onShellBack;

  @override
  Widget build(BuildContext context) => BackButtonListener(
    onBackButtonPressed: () async {
      onShellBack();
      return true;
    },
    child: Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (context) => Scaffold(body: page(context)),
      ),
    ),
  );

  @override
  Future<void> setNewRoutePath(Object configuration) async {}

  @override
  Future<bool> popRoute() async => false;
}

class _Shell {
  _Shell(this.dispatcher);

  final RootBackButtonDispatcher dispatcher;
  int backs = 0;
}

Future<_Shell> _pumpRouted(
  WidgetTester tester,
  WidgetBuilder page, {
  Size size = const Size(360, 800),
}) async {
  useWindow(tester, size);
  final dispatcher = RootBackButtonDispatcher();
  final shell = _Shell(dispatcher);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildKanaruTheme(brightness: Brightness.light),
      home: Router<Object>(
        routerDelegate: _Delegate(page, () => shell.backs++),
        backButtonDispatcher: dispatcher,
      ),
    ),
  );
  return shell;
}

List<KFabMenuItem> _items({
  VoidCallback? onNew,
  bool smartEnabled = false,
  VoidCallback? onSmart,
}) => [
  KFabMenuItem(icon: KIcons.add, label: 'New', onPressed: onNew),
  KFabMenuItem(icon: KIcons.fileImport, label: 'Import', onPressed: () {}),
  KFabMenuItem(
    icon: KIcons.smartPlaylist,
    label: 'Smart',
    enabled: smartEnabled,
    onPressed: onSmart,
    trailing: const ProBadge(),
  ),
];

Widget _menu({
  KFabMenuController? controller,
  List<KFabMenuItem>? items,
  Widget child = const SizedBox.expand(),
}) => KFabMenu(
  controller: controller,
  openTooltip: 'Create',
  closeTooltip: 'Close',
  items: items ?? _items(),
  child: child,
);

Finder get _fab => find.byType(FabMenuButton);

void main() {
  group('open and close', () {
    testWidgets('closed shows only the button; open shows pills and ✕', (
      tester,
    ) async {
      await tester.pumpWidget(host(_menu()));
      expect(find.text('New'), findsNothing);
      expect(find.byTooltip('Create'), findsOneWidget);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Import'), findsOneWidget);
      expect(find.text('Smart'), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);
    });

    testWidgets('the ✕ closes', (tester) async {
      await tester.pumpWidget(host(_menu()));
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      expect(find.text('New'), findsNothing);
    });

    testWidgets('the scrim closes and covers only the child', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(
        host(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 300, height: 600, child: _menu()),
          ),
        ),
      );
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      // Outside the menu's area: nothing there to hit, still open.
      await tester.tapAt(const Offset(340, 700));
      await tester.pumpAndSettle();
      expect(find.text('New'), findsOneWidget);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.text('New'), findsNothing);
    });

    testWidgets('an item closes first, then runs', (tester) async {
      final controller = KFabMenuController();
      addTearDown(controller.dispose);
      bool? openWhenRun;
      await tester.pumpWidget(
        host(
          _menu(
            controller: controller,
            items: _items(onNew: () => openWhenRun = controller.value),
          ),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();
      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      expect(openWhenRun, isFalse);
      expect(find.text('New'), findsNothing);
    });

    testWidgets('the controller opens and closes it', (tester) async {
      final controller = KFabMenuController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(_menu(controller: controller)));
      controller.open();
      await tester.pumpAndSettle();
      expect(find.text('Import'), findsOneWidget);
      controller.close();
      await tester.pumpAndSettle();
      expect(find.text('Import'), findsNothing);
    });

    testWidgets('a tab that stops ticking closes it', (tester) async {
      final controller = KFabMenuController();
      addTearDown(controller.dispose);
      Widget app(bool active) => host(
        TickerMode(
          enabled: active,
          child: _menu(controller: controller),
        ),
      );
      await tester.pumpWidget(app(true));
      controller.open();
      await tester.pumpAndSettle();
      await tester.pumpWidget(app(false));
      await tester.pump();
      await tester.pump();
      expect(controller.value, isFalse);
    });
  });

  group('disabled item', () {
    testWidgets('is inert and exposes enabled: false', (tester) async {
      var ran = false;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(_menu(items: _items(onSmart: () => ran = true))),
      );
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Smart'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(ran, isFalse);
      expect(find.text('Smart'), findsOneWidget, reason: 'menu stays open');
      expect(
        tester.getSemantics(find.text('Smart')),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });
  });

  group('Back', () {
    testWidgets('closed: not consumed, the shell gets it', (tester) async {
      final shell = await _pumpRouted(tester, (_) => _menu());
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(shell.backs, 1);
    });

    testWidgets('open: closes the menu, the shell is not asked', (
      tester,
    ) async {
      final shell = await _pumpRouted(tester, (_) => _menu());
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('New'), findsNothing);
      expect(shell.backs, 0);
    });

    testWidgets('open with a root modal above: not consumed, menu stays', (
      tester,
    ) async {
      late BuildContext inner;
      final shell = await _pumpRouted(
        tester,
        (context) => Builder(
          builder: (c) {
            inner = c;
            return _menu();
          },
        ),
      );
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      showDialog<void>(
        context: inner,
        builder: (_) => const AlertDialog(content: Text('modal')),
      );
      await tester.pumpAndSettle();
      // Ask the dispatcher directly (the app's own Navigator observer would
      // otherwise pop the modal before any listener is asked): the menu must
      // answer false so the shell's listener is reached.
      await shell.dispatcher.invokeCallback(Future.value(false));
      await tester.pumpAndSettle();
      expect(shell.backs, 1);
      expect(find.text('New'), findsOneWidget);
      // The system Back then closes the modal and still leaves the menu open.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('modal'), findsNothing);
      expect(find.text('New'), findsOneWidget);
    });
  });

  group('Esc', () {
    testWidgets('closes an open menu', (tester) async {
      await tester.pumpWidget(host(_menu()));
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('New'), findsNothing);
    });

    testWidgets('does nothing while closed', (tester) async {
      final controller = KFabMenuController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(_menu(controller: controller)));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(controller.value, isFalse);
    });

    testWidgets('yields to a focused text field outside the page', (
      tester,
    ) async {
      final controller = KFabMenuController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          Column(
            children: [
              const TextField(autofocus: true),
              Expanded(child: _menu(controller: controller)),
            ],
          ),
        ),
      );
      await tester.pump();
      controller.open();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(controller.value, isTrue);
    });

    testWidgets('with a root modal above: left to the modal', (tester) async {
      late BuildContext inner;
      await _pumpRouted(
        tester,
        (context) => Builder(
          builder: (c) {
            inner = c;
            return _menu();
          },
        ),
      );
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      showDialog<void>(
        context: inner,
        builder: (_) => const AlertDialog(content: Text('modal')),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('a closed or disposed menu ignores Esc', (tester) async {
      final controller = KFabMenuController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(_menu(controller: controller)));
      controller.open();
      await tester.pumpAndSettle();
      controller.close();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(controller.value, isFalse);
      controller.open();
      await tester.pumpAndSettle();
      await tester.pumpWidget(host(const SizedBox()));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(controller.value, isTrue, reason: 'disposed menu did not act');
      expect(tester.takeException(), isNull);
    });
  });

  group('page behind the scrim and focus', () {
    testWidgets('the page is out of semantics and focus only while open', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(_menu(child: const Center(child: Text('behind')))),
      );
      expect(find.semantics.byLabel('behind'), findsOneWidget);
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      expect(find.semantics.byLabel('behind'), findsNothing);
      expect(
        tester
            .widget<ExcludeFocus>(
              find.ancestor(
                of: find.text('behind'),
                matching: find.byType(ExcludeFocus),
              ),
            )
            .excluding,
        isTrue,
      );
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      expect(find.semantics.byLabel('behind'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the scrim uses the theme scrim colour at 40 %', (
      tester,
    ) async {
      await tester.pumpWidget(host(_menu()));
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      final scrim = Theme.of(tester.element(_fab)).colorScheme.scrim;
      final box = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(GestureDetector),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(box.color, scrim.withValues(alpha: 0.4));
    });

    String? focusedPill(WidgetTester tester) => FocusManager
        .instance
        .primaryFocus
        ?.context
        ?.findAncestorWidgetOfExactType<FabMenuPill>()
        ?.label;

    bool fabFocused() =>
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<FabMenuButton>() !=
        null;

    testWidgets('opened with the keyboard: focus goes to the first enabled '
        'pill and returns to the button on close', (tester) async {
      await tester.pumpWidget(host(_menu(items: _items(onNew: () {}))));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(fabFocused(), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('New'), findsOneWidget);
      expect(focusedPill(tester), 'New');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(fabFocused(), isTrue);
    });

    testWidgets('a disabled first pill is skipped', (tester) async {
      await tester.pumpWidget(
        host(
          _menu(
            items: [
              const KFabMenuItem(
                icon: KIcons.add,
                label: 'Off',
                enabled: false,
              ),
              KFabMenuItem(icon: KIcons.add, label: 'On', onPressed: () {}),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(focusedPill(tester), 'On');
    });

    testWidgets('opened by pointer: focus stays where it was', (tester) async {
      await tester.pumpWidget(host(_menu()));
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      expect(focusedPill(tester), isNull);
    });
  });

  group('motion', () {
    double opacityOf(WidgetTester tester, String label) => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    testWidgets('pills rise one KMotion.stagger after the other', (
      tester,
    ) async {
      await tester.pumpWidget(host(_menu()));
      await tester.tap(_fab);
      await tester.pump();
      await tester.pump(KMotion.stagger);
      final first = opacityOf(tester, 'New');
      final second = opacityOf(tester, 'Import');
      final third = opacityOf(tester, 'Smart');
      expect(first, greaterThan(second));
      expect(second, greaterThan(third));
      await tester.pumpAndSettle();
      expect(opacityOf(tester, 'Smart'), 1);
    });

    testWidgets('animations off: instant open and close', (tester) async {
      await tester.pumpWidget(host(_menu(), reduceMotion: true));
      await tester.tap(_fab);
      await tester.pump();
      expect(opacityOf(tester, 'Smart'), 1);
      await tester.tap(_fab);
      await tester.pump();
      expect(find.text('New'), findsNothing);
    });
  });

  group('layout', () {
    Future<Rect> fabRect(WidgetTester tester, Size size) async {
      useWindow(tester, size);
      await tester.pumpWidget(host(_menu()));
      return tester.getRect(_fab);
    }

    testWidgets('360 px: 56 square, 16 from the bottom end', (tester) async {
      final r = await fabRect(tester, const Size(360, 800));
      expect(r.size, const Size(56, 56));
      expect(360 - r.right, 16);
      expect(800 - r.bottom, 16);
    });

    testWidgets('1280 px: 24 from the bottom end', (tester) async {
      final r = await fabRect(tester, const Size(1280, 800));
      expect(1280 - r.right, 24);
      expect(800 - r.bottom, 24);
    });

    testWidgets('clears the bottom padding of the shell', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(padding: const EdgeInsets.only(bottom: 80)),
              child: _menu(),
            ),
          ),
        ),
      );
      expect(800 - tester.getRect(_fab).bottom, 96);
    });

    testWidgets('pills are 56 high on mobile, 52 on desktop', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(host(_menu()));
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(
              find.ancestor(
                of: find.text('New'),
                matching: find.byType(FabMenuPill),
              ),
            )
            .height,
        56,
      );
      useWindow(tester, const Size(1280, 800));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(
              find.ancestor(
                of: find.text('New'),
                matching: find.byType(FabMenuPill),
              ),
            )
            .height,
        52,
      );
    });

    for (final (name, brightness, scale) in hostVariants) {
      testWidgets('long label does not overflow ($name)', (tester) async {
        useWindow(tester, const Size(360, 800));
        await tester.pumpWidget(
          host(
            _menu(
              items: [
                KFabMenuItem(
                  icon: KIcons.add,
                  label: 'Nhập tệp danh sách phát M3U từ thư mục',
                  onPressed: () {},
                  trailing: const ProBadge(label: 'Pro'),
                ),
              ],
            ),
            brightness: brightness,
            textScale: scale,
          ),
        );
        await tester.tap(_fab);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('200 % text does not overflow', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(scaledHost(_menu(), textScale: 2));
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
