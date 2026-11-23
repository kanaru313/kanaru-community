import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/finders.dart';
import '../support/host.dart';

const _desktop = Size(1400, 900);
const _phone = Size(400, 800);

/// Records what the app puts on the clipboard.
List<String> _clipboard(WidgetTester tester) {
  final log = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        log.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return log;
}

Widget _row(KInfoRow row, {double width = 360, KOverlayKind? kind}) {
  final body = Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: width, child: row),
  );
  return kind == null ? body : KOverlayPageScope(kind: kind, child: body);
}

/// The row's background tint.
Color? _tint(WidgetTester tester) =>
    (tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration
            as BoxDecoration)
        .color;

Future<TestGesture> _hover(WidgetTester tester, Finder at) async {
  useKeyboardHighlight();
  final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await g.addPointer(location: const Offset(1, 1));
  addTearDown(g.removePointer);
  await g.moveTo(tester.getCenter(at));
  await tester.pump();
  return g;
}

void main() {
  testWidgets('label, value, at least 48 tall, spoken as "label: value"', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useWindow(tester, _phone);
    await tester.pumpWidget(
      host(_row(const KInfoRow(label: 'Format', value: 'FLAC'))),
    );
    expect(find.text('Format'), findsOneWidget);
    expect(find.text('FLAC'), findsOneWidget);
    expect(
      tester.getSize(find.byType(KInfoRow)).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.bySemanticsLabel('Format: FLAC'), findsOneWidget);
    handle.dispose();
  });

  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders in $name without overflow', (tester) async {
      useWindow(tester, _phone);
      await tester.pumpWidget(
        host(
          _row(const KInfoRow(label: 'Path', value: '/a/very/long/path.flac')),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('label column is 112 on a page and 148 in a box', (tester) async {
    useWindow(tester, _phone);
    double gap() =>
        tester.getTopLeft(find.text('Value')).dx -
        tester.getTopLeft(find.text('Label')).dx;
    const row = KInfoRow(label: 'Label', value: 'Value');
    await tester.pumpWidget(host(_row(row, kind: KOverlayKind.page)));
    final page = gap();
    await tester.pumpWidget(host(_row(row, kind: KOverlayKind.box)));
    expect(gap() - page, 148 - 112);
  });

  testWidgets('200 % text puts the label above the value', (tester) async {
    useWindow(tester, _phone);
    const row = KInfoRow(label: 'Label', value: 'Value');
    await tester.pumpWidget(host(_row(row)));
    expect(
      tester.getTopLeft(find.text('Label')).dy,
      tester.getTopLeft(find.text('Value')).dy,
    );
    await tester.pumpWidget(host(_row(row), textScale: 2));
    final label = tester.getRect(find.text('Label'));
    final value = tester.getRect(find.text('Value'));
    expect(value.top, greaterThanOrEqualTo(label.bottom));
    expect(value.left, label.left);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long unbroken value wraps at 360 wide, no overflow', (
    tester,
  ) async {
    useWindow(tester, const Size(360, 800));
    await tester.pumpWidget(
      host(
        _row(
          KInfoRow(label: 'Path', value: '/home/an/${'Music/' * 20}song.flac'),
          width: 360,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.byType(KInfoRow)).right, lessThanOrEqualTo(360));
  });

  group('mobile copy', () {
    testWidgets('long press copies, flashes and calls onCopied', (
      tester,
    ) async {
      useWindow(tester, _phone);
      final log = _clipboard(tester);
      final copied = <String>[];
      await tester.pumpWidget(
        host(
          _row(
            KInfoRow(
              label: 'Title',
              value: 'Shown',
              copyText: 'Raw',
              onCopied: copied.add,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Shown'));
      await tester.pump();
      expect(log, isEmpty, reason: 'a plain tap never copies');
      await tester.longPress(find.text('Shown'));
      await tester.pump();
      expect(log, ['Raw']);
      expect(copied, ['Raw']);
      Color? tint() => _tint(tester);
      await tester.pump(KMotion.fast);
      expect(tint()!.a, greaterThan(0.05));
      await tester.pump(KMotion.flash + KMotion.fast);
      await tester.pumpAndSettle();
      expect(tint()!.a, 0);
    });

    testWidgets('the text is not selectable', (tester) async {
      useWindow(tester, _phone);
      await tester.pumpWidget(
        host(_row(const KInfoRow(label: 'Title', value: 'Shown'))),
      );
      expect(find.byType(SelectableText), findsNothing);
    });

    testWidgets('no copy button without a mouse', (tester) async {
      useWindow(tester, _phone);
      await tester.pumpWidget(
        host(_row(const KInfoRow(label: 'Title', value: 'Shown'))),
      );
      expect(byIconButton('Copy'), findsNothing);
    });

    testWidgets('a mouse hovering shows the copy button on this shell too', (
      tester,
    ) async {
      useWindow(tester, _phone);
      final log = _clipboard(tester);
      await tester.pumpWidget(
        host(_row(const KInfoRow(label: 'Title', value: 'Shown'))),
      );
      await _hover(tester, find.text('Shown'));
      expect(byIconButton('Copy'), findsOneWidget);
      await tester.tap(byIconButton('Copy'));
      await tester.pump();
      expect(log, ['Shown']);
    });
  });

  group('desktop copy', () {
    testWidgets('selectable text; the copy button shows only on hover', (
      tester,
    ) async {
      useWindow(tester, _desktop);
      final log = _clipboard(tester);
      await tester.pumpWidget(
        host(_row(const KInfoRow(label: 'Title', value: 'Shown'))),
      );
      expect(find.byType(SelectableText), findsOneWidget);
      expect(byIconButton('Copy'), findsNothing);
      final base = tester.getRect(find.text('Shown'));
      final g = await _hover(tester, find.text('Shown'));
      expect(byIconButton('Copy'), findsOneWidget);
      expect(
        tester.getRect(find.text('Shown')),
        base,
        reason: 'the button has its slot, the text does not move',
      );
      expect(tester.getSize(byIconButton('Copy')).width, 32);
      await tester.tap(byIconButton('Copy'));
      await tester.pump();
      expect(log, ['Shown']);
      await g.moveTo(const Offset(1300, 800));
      await tester.pump();
      expect(byIconButton('Copy'), findsNothing);
    });

    testWidgets('hover tints the row 4 %', (tester) async {
      useWindow(tester, _desktop);
      await tester.pumpWidget(
        host(_row(const KInfoRow(label: 'Title', value: 'Shown'))),
      );
      await _hover(tester, find.text('Shown'));
      await tester.pumpAndSettle();
      final tint = _tint(tester)!;
      expect(tint.a, closeTo(0.04, 0.005));
    });

    testWidgets('a clipboard failure shows no copied message', (tester) async {
      useWindow(tester, _desktop);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            throw PlatformException(code: 'denied');
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      var copied = 0;
      await tester.pumpWidget(
        host(_row(KInfoRow(label: 'T', value: 'V', onCopied: (_) => copied++))),
      );
      await _hover(tester, find.text('V'));
      await tester.tap(byIconButton('Copy'));
      await tester.pump();
      expect(copied, 0);
    });
  });

  testWidgets('soon: dimmed, shows the label text, never copies', (
    tester,
  ) async {
    useWindow(tester, _desktop);
    final log = _clipboard(tester);
    await tester.pumpWidget(
      host(_row(const KInfoRow(label: 'ReplayGain', soon: 'Sắp có'))),
    );
    expect(find.text('Sắp có'), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 0.5);
    await _hover(tester, find.text('Sắp có'));
    expect(byIconButton('Copy'), findsNothing);
    expect(log, isEmpty);
  });

  testWidgets('unknownText: italic, quiet colour, spoken after the label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    useWindow(tester, _phone);
    await tester.pumpWidget(
      host(_row(const KInfoRow(label: 'Genre', unknownText: 'Không rõ'))),
    );
    final style = tester.widget<Text>(find.text('Không rõ')).style!;
    final scheme = Theme.of(tester.element(find.text('Không rõ'))).colorScheme;
    expect(style.fontStyle, FontStyle.italic);
    expect(style.color, scheme.onSurfaceVariant);
    expect(find.bySemanticsLabel('Genre: Không rõ'), findsOneWidget);
    await tester.longPress(find.text('Không rõ'));
    handle.dispose();
  });

  testWidgets('missing: error colour, struck through, still copyable', (
    tester,
  ) async {
    useWindow(tester, _phone);
    final log = _clipboard(tester);
    await tester.pumpWidget(
      host(
        _row(const KInfoRow(label: 'Path', value: '/gone.flac', missing: true)),
      ),
    );
    final style = tester.widget<Text>(find.text('/gone.flac')).style!;
    final scheme = Theme.of(tester.element(find.text('/gone.flac')))
        .colorScheme;
    expect(style.color, scheme.error);
    expect(style.decoration, TextDecoration.lineThrough);
    await tester.longPress(find.text('/gone.flac'));
    await tester.pump(KMotion.flash + KMotion.fast);
    expect(log, ['/gone.flac']);
  });

  testWidgets('links in a row: no copy button, a long press copies nothing', (
    tester,
  ) async {
    useWindow(tester, _desktop);
    final log = _clipboard(tester);
    var taps = 0;
    await tester.pumpWidget(
      host(
        _row(
          KInfoRow(
            label: 'Artist',
            valueWidget: KTextLink(text: 'Ann', onTap: () => taps++),
          ),
        ),
      ),
    );
    expect(find.byType(SelectableText), findsNothing);
    await _hover(tester, find.text('Ann'));
    expect(byIconButton('Copy'), findsNothing);
    await tester.longPress(find.text('Ann'));
    await tester.pump(KMotion.flash);
    expect(log, isEmpty);
    final before = taps;
    await tester.tap(find.text('Ann'));
    expect(taps, before + 1);
  });

  testWidgets('the trailing buttons stay their own accessible nodes', (
    tester,
  ) async {
    useWindow(tester, _desktop);
    var runs = 0;
    await tester.pumpWidget(
      host(
        _row(
          KInfoRow(
            label: 'Path',
            value: '/a.flac',
            trailing: KIconButton(
              tooltip: 'Open folder',
              icon: KIcons.openInNew,
              onPressed: () => runs++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(byIconButton('Open folder'));
    expect(runs, 1);
  });

  testWidgets('animations off: the flash shows without fading', (tester) async {
    useWindow(tester, _phone);
    _clipboard(tester);
    await tester.pumpWidget(
      host(_row(const KInfoRow(label: 'T', value: 'V')), reduceMotion: true),
    );
    await tester.longPress(find.text('V'));
    await tester.pump();
    final box = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(box.duration, Duration.zero);
    expect(_tint(tester)!.a, greaterThan(0.05));
    await tester.pump(KMotion.flash);
  });

  testWidgets('leaving while the flash runs leaves no timer behind', (
    tester,
  ) async {
    useWindow(tester, _phone);
    _clipboard(tester);
    await tester.pumpWidget(host(_row(const KInfoRow(label: 'T', value: 'V'))));
    await tester.longPress(find.text('V'));
    await tester.pump();
    await tester.pumpWidget(host(const SizedBox()));
    expect(tester.takeException(), isNull);
  });
}
