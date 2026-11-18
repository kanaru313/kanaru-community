import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

void main() {
  valueRowTests();
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('rows render without overflow ($name)', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(
        host(
          SetupSection(
            title: const Text('Appearance'),
            children: [
              SetupValueRow(
                icon: KIcons.theme,
                title: const Text('Theme'),
                value: const Text('Follow system'),
                onTap: () {},
              ),
              SetupAddRow(
                icon: KIcons.folderAdd,
                label: const Text('Add excluded folder'),
                onTap: () {},
              ),
              const SetupNote(
                child: Text('Nothing here yet, and a longer note.'),
              ),
            ],
          ),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a value row shows its value and reports taps', (tester) async {
    useWindow(tester, const Size(400, 800));
    var taps = 0;
    await tester.pumpWidget(
      host(
        SetupValueRow(
          icon: KIcons.language,
          title: const Text('Language'),
          value: const Text('English'),
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.text('English'), findsOneWidget);
    expect(find.byIcon(KIcons.chevronRight), findsOneWidget);
    await tester.tap(find.text('Language'));
    expect(taps, 1);
    expect(
      tester.getSize(find.byType(SetupValueRow)).height,
      greaterThanOrEqualTo(56),
    );
  });

  testWidgets('the anchor key gives the row box to a desktop picker', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final key = GlobalKey();
    await tester.pumpWidget(
      host(
        SetupValueRow(
          anchorKey: key,
          icon: KIcons.theme,
          title: const Text('Theme'),
          value: const Text('Dark'),
          onTap: () {},
        ),
      ),
    );
    expect(key.currentContext?.findRenderObject(), isA<RenderBox>());
  });

  testWidgets('the add row is primary coloured and dims without onTap', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        const SetupAddRow(
          icon: KIcons.add,
          label: Text('Add folder'),
          onTap: null,
        ),
      ),
    );
    final scheme = Theme.of(tester.element(find.text('Add folder')))
        .colorScheme;
    final text = tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text('Add folder'),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );
    expect(text.style.color, scheme.primary);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, lessThan(1));
  });
}

void valueRowTests() {
  testWidgets('the value is the line under the title, chevron trailing', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        SetupValueRow(
          icon: KIcons.theme,
          title: const Text('Theme'),
          value: const Text('Dark'),
          onTap: () {},
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('Dark')).dy,
      greaterThan(tester.getBottomLeft(find.text('Theme')).dy - 1),
    );
    expect(
      tester.getTopLeft(find.text('Dark')).dx,
      tester.getTopLeft(find.text('Theme')).dx,
    );
    expect(
      tester.getCenter(find.byIcon(KIcons.chevronRight)).dx,
      greaterThan(tester.getCenter(find.text('Dark')).dx),
    );
  });

  testWidgets('the value is read together with the title', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        SetupValueRow(
          icon: KIcons.theme,
          title: const Text('Theme'),
          value: const Text('Dark'),
          onTap: () {},
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('Theme')),
      matchesSemantics(
        label: 'Theme\nDark',
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a value icon sits before the value', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        SetupValueRow(
          icon: KIcons.language,
          title: const Text('Translator'),
          value: const Text('Gemini'),
          valueLeading: KIcons.help,
          onTap: () {},
        ),
      ),
    );
    expect(
      tester.getCenter(find.byIcon(KIcons.help)).dx,
      lessThan(tester.getCenter(find.text('Gemini')).dx),
    );
    expect(tester.getSize(find.byIcon(KIcons.help)).width, 16);
  });

  testWidgets('disabled: reason replaces the value, no taps, semantics off', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      host(
        SetupValueRow(
          icon: KIcons.theme,
          title: const Text('Gain'),
          value: const Text('Album'),
          enabled: false,
          disabledReason: const Text('Turn on ReplayGain first'),
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.text('Album'), findsNothing);
    expect(find.text('Turn on ReplayGain first'), findsOneWidget);
    await tester.tap(find.text('Gain'), warnIfMissed: false);
    expect(taps, 0);
    expect(
      tester.getSemantics(find.text('Gain')),
      matchesSemantics(
        label: 'Gain\nTurn on ReplayGain first',
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('coming soon: label instead of chevron, dimmed, no taps', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      host(
        SetupValueRow(
          icon: KIcons.theme,
          title: const Text('Crossfade'),
          value: const Text('Off'),
          comingSoon: true,
          soonLabel: 'Coming soon',
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.byIcon(KIcons.chevronRight), findsNothing);
    expect(find.text('Off'), findsOneWidget);
    await tester.tap(find.text('Crossfade'), warnIfMissed: false);
    expect(taps, 0);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.5);
    expect(
      tester.getSemantics(find.text('Crossfade')),
      matchesSemantics(
        label: 'Crossfade\nOff\nComing soon',
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('long Vietnamese text at 200 % wraps without overflow', (
    tester,
  ) async {
    useWindow(tester, const Size(360, 800));
    await tester.pumpWidget(
      host(
        SetupValueRow(
          icon: KIcons.language,
          title: const Text('Dịch vụ dịch mặc định cho lời bài hát'),
          value: const Text('Dịch vụ dịch rất dài của một plugin bên thứ ba'),
          valueLeading: KIcons.help,
          comingSoon: true,
          soonLabel: 'Sắp có',
          onTap: () {},
        ),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
