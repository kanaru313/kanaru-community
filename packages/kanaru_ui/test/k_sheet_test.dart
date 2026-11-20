import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter/services.dart';

import 'support/host.dart';
import 'support/scaled_host.dart';

Widget _opener({bool draggable = true}) => Builder(
  builder: (context) => TextButton(
    onPressed: () => showKSheet<void>(
      context,
      draggable: draggable,
      builder: (_) =>
          const Padding(padding: EdgeInsets.all(24), child: Text('content')),
    ),
    child: const Text('open'),
  ),
);

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('narrow window uses a bottom sheet ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(_opener(), brightness: brightness, textScale: scale),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('600 dp and wider uses a dialog', (tester) async {
    useWindow(tester, const Size(700, 800));
    await tester.pumpWidget(host(_opener()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('scrim tap closes the sheet', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_opener()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();
    expect(find.text('content'), findsNothing);
  });

  testWidgets('dragging down past the threshold closes the sheet', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_opener()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('content'), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(find.text('content'), findsNothing);
  });

  testWidgets('system Back closes the sheet', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_opener()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('content'), findsNothing);
  });

  testWidgets('keyboard shrinks the sheet room', (tester) async {
    useWindow(tester, const Size(400, 800));
    tester.view.viewInsets = const FakeViewPadding(bottom: 500);
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showKSheet<void>(
              context,
              fixedHeight: true,
              builder: (_) => const SizedBox.expand(key: Key('body')),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const Key('body'))).height,
      lessThanOrEqualTo(300),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('fixedHeight applies to the dialog branch', (tester) async {
    useWindow(tester, const Size(700, 800));
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showKSheet<void>(
              context,
              fixedHeight: true,
              builder: (_) => const Text('short'),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(
            find
                .descendant(
                  of: find.byType(Dialog),
                  matching: find.byType(ConstrainedBox),
                )
                .last,
          )
          .height,
      closeTo(680, 1),
    );
  });

  testWidgets('useRootNavigator shows the sheet on the root navigator', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final nestedKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      host(
        Navigator(
          key: nestedKey,
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (context) => TextButton(
              onPressed: () => showKSheet<void>(
                context,
                useRootNavigator: true,
                builder: (_) => const Text('content'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('content'), findsOneWidget);
    // The nested navigator still holds only its page; the sheet went to the root.
    expect(nestedKey.currentState!.canPop(), isFalse);
  });

  for (final (width, expected) in [
    (400.0, KRowEdges.fullBleed),
    (700.0, KRowEdges.inset),
  ]) {
    testWidgets('hosts rows with $expected at ${width}dp', (tester) async {
      useWindow(tester, Size(width, 800));
      KRowEdges? seen;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showKSheet<void>(
                context,
                builder: (_) => Builder(
                  builder: (context) {
                    seen = KRowEdgesScope.maybeOf(context);
                    return const Text('content');
                  },
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(seen, expected);
    });
  }

  group('modal look', () {
    Widget modalOpener({
      Widget content = const SizedBox(height: 1000, child: Text('content')),
      FocusNode? returnFocus,
    }) => Builder(
      builder: (context) => TextButton(
        onPressed: () => showKSheet<void>(
          context,
          dialog: KSheetDialog.modal,
          returnFocus: returnFocus,
          builder: (_) => content,
        ),
        child: const Text('open'),
      ),
    );

    Finder card() => find
        .ancestor(of: find.text('content'), matching: find.byType(Material))
        .first;

    for (final (scale, width) in [
      (1.0, KLayout.dialogModal),
      (2.0, KLayout.dialogModalLarge),
    ]) {
      testWidgets('dialog at 1200x600 and text $scale: ${width}dp, scrolls, '
          'keeps 24 dp from the edges', (tester) async {
        useWindow(tester, const Size(1200, 600));
        await tester.pumpWidget(scaledHost(modalOpener(), textScale: scale));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        final rect = tester.getRect(card());
        expect(rect.width, closeTo(width, 0.5));
        expect(rect.top, greaterThanOrEqualTo(24));
        expect(rect.bottom, lessThanOrEqualTo(600 - 24));
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('dialog scales in over the dialog token, not with reduced '
        'motion', (tester) async {
      useWindow(tester, const Size(1200, 600));
      await tester.pumpWidget(
        scaledHost(modalOpener(content: const Text('content'))),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(KMotion.dialogIn ~/ 4);
      expect(tester.getRect(card()).width, lessThan(KLayout.dialogModal));
      await tester.pumpAndSettle();
      expect(tester.getRect(card()).width, closeTo(KLayout.dialogModal, 0.5));
    });

    testWidgets('reduced motion shows the dialog at full size at once', (
      tester,
    ) async {
      useWindow(tester, const Size(1200, 600));
      await tester.pumpWidget(
        scaledHost(
          modalOpener(content: const Text('content')),
          reduceMotion: true,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.getRect(card()).width, closeTo(KLayout.dialogModal, 0.5));
    });

    testWidgets('phone gets the soft sheet (surfaceContainerLow, 92 %)', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(scaledHost(modalOpener()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
      final scheme = Theme.of(tester.element(find.byType(BottomSheet)))
          .colorScheme;
      expect(sheet.backgroundColor, scheme.surfaceContainerLow);
      expect(
        tester.getSize(find.byType(BottomSheet)).height,
        lessThanOrEqualTo(800 * 0.92 + 0.5),
      );
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('keyboard inset keeps the field and the footer hit-testable', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      var footer = 0;
      await tester.pumpWidget(
        scaledHost(
          modalOpener(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 100),
                const TextField(key: Key('field')),
                const SizedBox(height: 100),
                TextButton(onPressed: () => footer++, child: const Text('ok')),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const Key('field'))).bottom,
        lessThan(500),
      );
      expect(tester.getRect(find.text('ok')).bottom, lessThan(500));
      await tester.tap(find.byKey(const Key('field')));
      await tester.tap(find.text('ok'));
      expect(footer, 1);
    });

    for (final (name, width) in [('dialog', 1200.0), ('sheet', 400.0)]) {
      testWidgets('returnFocus gets focus back when attached ($name)', (
        tester,
      ) async {
        useWindow(tester, Size(width, 800));
        final node = FocusNode();
        addTearDown(node.dispose);
        await tester.pumpWidget(
          scaledHost(
            Column(
              children: [
                Focus(focusNode: node, child: const Text('anchor')),
                modalOpener(content: const Text('content'), returnFocus: node),
              ],
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(node.hasFocus, isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('content'), findsNothing);
        expect(node.hasFocus, isTrue);
      });
    }

    testWidgets('returnFocus that is not attached does nothing', (
      tester,
    ) async {
      useWindow(tester, const Size(1200, 800));
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        scaledHost(
          modalOpener(content: const Text('content'), returnFocus: node),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('content'), findsNothing);
      expect(node.hasFocus, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Esc closes and never reaches a shortcut above the route', (
      tester,
    ) async {
      useWindow(tester, const Size(1200, 800));
      var shell = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildKanaruTheme(brightness: Brightness.light),
          builder: (context, app) => CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () => shell++,
            },
            child: app!,
          ),
          home: Scaffold(body: modalOpener(content: const Text('content'))),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('content'), findsNothing);
      expect(shell, 0);
    });

    for (final (name, size) in [
      ('dialog', const Size(1200, 800)),
      ('sheet', const Size(400, 800)),
    ]) {
      testWidgets(
        'an autofocus in the content wins; Esc still closes ($name)',
        (tester) async {
          useWindow(tester, size);
          final node = FocusNode();
          addTearDown(node.dispose);
          await tester.pumpWidget(
            scaledHost(
              modalOpener(
                content: KStartTile(
                  title: '45 phút',
                  semanticLabel: '45 phút',
                  onPressed: () {},
                  autofocus: true,
                  focusNode: node,
                ),
              ),
            ),
          );
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          expect(
            node.hasPrimaryFocus,
            isTrue,
            reason: '${FocusManager.instance.primaryFocus}',
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(find.text('45 phút'), findsNothing);
        },
      );
    }

    testWidgets('content without a focusable still holds focus for Esc', (
      tester,
    ) async {
      useWindow(tester, const Size(1200, 800));
      await tester.pumpWidget(
        scaledHost(modalOpener(content: const Text('content'))),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'KModalEscScope');
    });

    testWidgets('scrim and shadow come from the scheme roles', (tester) async {
      useWindow(tester, const Size(1200, 800));
      await tester.pumpWidget(
        scaledHost(modalOpener(content: const Text('content'))),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final scheme = Theme.of(tester.element(find.text('content'))).colorScheme;
      final barrier = tester.widget<ModalBarrier>(
        find.byType(ModalBarrier).last,
      );
      expect(barrier.color, scheme.scrim.withValues(alpha: 0.45));
      expect(tester.widget<Material>(card()).shadowColor, scheme.shadow);
    });

    testWidgets('scrim tap closes the dialog', (tester) async {
      useWindow(tester, const Size(1200, 800));
      await tester.pumpWidget(
        scaledHost(modalOpener(content: const Text('content'))),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('content'), findsNothing);
    });
  });
}
