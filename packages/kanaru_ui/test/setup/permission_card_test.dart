import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

PermissionCard _card({
  bool audio = false,
  bool images = false,
  bool collapsed = false,
  VoidCallback? onAction,
}) => PermissionCard(
  collapsed: collapsed,
  collapsedTitle: const Text('Everything allowed'),
  collapsedSubtitle: const Text('Music and audio · Photos and videos'),
  rows: [
    PermissionRowData(
      icon: KIcons.musicFile,
      title: const Text('Music and audio'),
      subtitle: const Text('Find and play songs'),
      granted: audio,
      stateLabel: audio ? 'Granted' : 'Not granted',
    ),
    PermissionRowData(
      icon: KIcons.image,
      title: const Text('Photos and videos'),
      subtitle: const Text('Only to read cover art next to the music'),
      granted: images,
      stateLabel: images ? 'Granted' : 'Not granted',
    ),
  ],
  action: FilledButton(onPressed: onAction, child: const Text('Allow')),
  note: const Text('Both are needed.'),
);

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('expanded card renders ($name)', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(
        host(
          SingleChildScrollView(child: _card(audio: true)),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Allow'), findsOneWidget);
      expect(find.text('Both are needed.'), findsOneWidget);
    });

    testWidgets('collapsed card renders ($name)', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(
        host(
          _card(audio: true, images: true, collapsed: true),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a granted row shows a check, a missing one an empty circle', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_card(audio: true)));
    // One check: the granted row. The other state is an empty ring.
    expect(find.byIcon(KIcons.check), findsOneWidget);
  });

  testWidgets('states are spoken', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_card(audio: true)));
    expect(find.bySemanticsLabel('Granted'), findsOneWidget);
    expect(find.bySemanticsLabel('Not granted'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('collapsing hides the rows and the action', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(_card(audio: true, images: true, collapsed: true)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Everything allowed'), findsOneWidget);
    expect(find.text('Music and audio · Photos and videos'), findsOneWidget);
    expect(find.text('Allow'), findsNothing);
    expect(find.text('Music and audio'), findsNothing);
    expect(find.byIcon(KIcons.check), findsOneWidget);
  });

  testWidgets('the action is tappable', (tester) async {
    useWindow(tester, const Size(400, 800));
    var taps = 0;
    await tester.pumpWidget(host(_card(onAction: () => taps++)));
    await tester.tap(find.text('Allow'));
    expect(taps, 1);
  });

  test('a collapsed card needs its title and description', () {
    expect(
      () => PermissionCard(
        rows: const [],
        action: const SizedBox(),
        collapsed: true,
      ),
      throwsAssertionError,
    );
  });

  testWidgets('attention tints the card toward the error container', (
    tester,
  ) async {
    useWindow(tester, const Size(360, 800));
    Future<Color?> pumpColor(bool attention) async {
      await tester.pumpWidget(
        host(
          SingleChildScrollView(
            child: PermissionCard(
              attention: attention,
              rows: const [],
              action: const SizedBox(),
            ),
          ),
        ),
      );
      return tester
          .widget<Material>(
            find
                .descendant(
                  of: find.byType(PermissionCard),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color;
    }

    final plain = await pumpColor(false);
    final tinted = await pumpColor(true);
    expect(tinted, isNot(plain));
  });
}
