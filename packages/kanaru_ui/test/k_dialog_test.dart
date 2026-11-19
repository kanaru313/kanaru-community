import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/finders.dart';
import 'support/host.dart';

Widget _opener(
  Future<Object?> Function(BuildContext) open,
  List<Object?> out,
) => Builder(
  builder: (context) => TextButton(
    onPressed: () async => out.add(await open(context)),
    child: const Text('open'),
  ),
);

double _alertWidth(WidgetTester tester) => tester
    .getSize(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Material),
          )
          .first,
    )
    .width;

const _wideBody = Dialog(
  insetPadding: EdgeInsets.zero,
  child: SizedBox(key: Key('body'), width: 2000, height: 50),
);

void main() {
  group('showKDialog', () {
    testWidgets('default width is capped at KLayout.dialog', (tester) async {
      useWindow(tester, const Size(1300, 900));
      await tester.pumpWidget(
        host(
          _opener((c) => showKDialog<void>(c, builder: (_) => _wideBody), []),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const Key('body'))).width,
        KLayout.dialog,
      );
    });

    testWidgets('maxWidth widens it', (tester) async {
      useWindow(tester, const Size(1300, 900));
      await tester.pumpWidget(
        host(
          _opener(
            (c) => showKDialog<void>(
              c,
              maxWidth: KLayout.dialogWide,
              builder: (_) => _wideBody,
            ),
            [],
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const Key('body'))).width,
        KLayout.dialogWide,
      );
    });
  });

  group('showKDialog sizing', () {
    Future<void> show(
      WidgetTester tester,
      Widget dialog, {
      double? maxWidth,
    }) async {
      useWindow(tester, const Size(1300, 900));
      await tester.pumpWidget(
        host(
          _opener(
            (c) => showKDialog<void>(
              c,
              builder: (_) => dialog,
              maxWidth: maxWidth ?? KLayout.dialog,
            ),
            [],
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('an AlertDialog keeps its intrinsic width', (tester) async {
      await show(
        tester,
        const AlertDialog(title: Text('T'), content: Text('short')),
      );
      expect(_alertWidth(tester), lessThan(KLayout.dialog));
    });

    testWidgets('a long-text AlertDialog stops at KLayout.dialog', (
      tester,
    ) async {
      await show(tester, AlertDialog(content: Text('long text ' * 200)));
      expect(_alertWidth(tester), lessThanOrEqualTo(KLayout.dialog));
    });

    testWidgets('a long-text AlertDialog stops at maxWidth', (tester) async {
      await show(
        tester,
        AlertDialog(content: Text('long text ' * 200)),
        maxWidth: KLayout.dialogWide,
      );
      final width = _alertWidth(tester);
      expect(width, lessThanOrEqualTo(KLayout.dialogWide));
      expect(width, greaterThan(KLayout.dialog));
    });
  });

  group('showKFullScreenDialog', () {
    Widget open(
      List<Object?> out, {
      bool enabled = true,
      ValueListenable<bool>? listenable,
      Future<void> Function(BuildContext)? onAction,
      Widget body = const SizedBox(height: 100, child: Text('body')),
    }) => Builder(
      builder: (outer) => _opener(
        (c) => showKFullScreenDialog<String>(
          c,
          title: 'Edit',
          closeTooltip: 'Close',
          actionLabel: 'Save',
          actionEnabled: enabled,
          actionEnabledListenable: listenable,
          onAction: () => onAction?.call(c) ?? Future<void>.value(),
          body: (_) => body,
        ),
        out,
      ),
    );

    Future<void> opened(WidgetTester tester, Widget w) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(w));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    TextButton action(WidgetTester tester) =>
        tester.widget<TextButton>(find.byType(TextButton).last);

    testWidgets('fills the screen with the app bar [x] title [action]', (
      tester,
    ) async {
      await opened(tester, open([]));
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(tester.getSize(find.byType(Scaffold).last), const Size(400, 800));
    });

    testWidgets('close button and Back complete with null', (tester) async {
      final out = <Object?>[];
      await opened(tester, open(out));
      await tester.tap(byIconButton('Close'));
      await tester.pumpAndSettle();
      expect(out, [null]);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(out, [null, null]);
    });

    testWidgets('a disabled action cannot be pressed', (tester) async {
      await opened(tester, open([], enabled: false));
      expect(action(tester).onPressed, isNull);
    });

    testWidgets('the listenable overrides actionEnabled and rebuilds', (
      tester,
    ) async {
      final enabled = ValueNotifier(false);
      addTearDown(enabled.dispose);
      await opened(tester, open([], enabled: true, listenable: enabled));
      expect(action(tester).onPressed, isNull);
      enabled.value = true;
      await tester.pump();
      expect(action(tester).onPressed, isNotNull);
      enabled.value = false;
      await tester.pump();
      expect(action(tester).onPressed, isNull);
    });

    testWidgets('the caller pops from onAction with a result', (tester) async {
      final out = <Object?>[];
      await opened(
        tester,
        open(
          out,
          onAction: (c) async => Navigator.of(c, rootNavigator: true).pop('ok'),
        ),
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(out, ['ok']);
    });

    testWidgets('while onAction runs: busy, label in semantics, close and '
        'Back blocked', (tester) async {
      final handle = tester.ensureSemantics();
      final gate = Completer<void>();
      final out = <Object?>[];
      await opened(tester, open(out, onAction: (_) => gate.future));
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(find.bySemanticsLabel('Save'), findsOneWidget);
      expect(action(tester).onPressed, isNull);
      expect(
        tester.widget<KIconButton>(byIconButton('Close')).onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Edit'), findsOneWidget);
      expect(out, isEmpty);
      gate.complete();
      await tester.pump();
      expect(find.text('Save'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a throwing onAction keeps the dialog open and reports', (
      tester,
    ) async {
      await opened(
        tester,
        open([], onAction: (_) async => throw StateError('no disk')),
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final error = tester.takeException();
      expect(error, isA<StateError>());
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(action(tester).onPressed, isNotNull);
    });

    testWidgets('with the keyboard open the action stays on screen and the '
        'body scrolls', (tester) async {
      await opened(
        tester,
        open(
          [],
          body: const Column(
            children: [
              SizedBox(height: 900, child: Text('tall')),
              TextField(),
            ],
          ),
        ),
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Save')).bottom, lessThan(100));
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('showKDialog hosts rows inset', (tester) async {
    useWindow(tester, const Size(700, 800));
    KRowEdges? seen;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showKDialog<void>(
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
    expect(seen, KRowEdges.inset);
  });
}
