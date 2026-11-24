import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/ui/menus/menu_action_runner.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/menus/menu_presenter.dart';
import 'package:kanaru/src/library/ui/menus/menu_renderer.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'menu_pump.dart';

const _header = MenuHeader(image: MenuImage.track, title: 'Song');

/// Opens [build] through `presentMenu` on a bare app (desktop width) and
/// returns the context of the app.
Future<BuildContext> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1300, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Text('home')),
      ),
    ),
  );
  return tester.element(find.text('home'));
}

void main() {
  testWidgets('presentMenu stays pending until a chosen run action completes', (
    tester,
  ) async {
    final context = await _pump(tester);
    final gate = Completer<void>();
    var started = false;
    var done = false;
    unawaited(
      presentMenu(
        context,
        (_, _) async => MenuSpec(
          header: _header,
          groups: [
            [
              MenuItemSpec(
                MenuItemId.sleepTimer,
                icon: KIcons.lyrics,
                title: 'Timer',
                action: MenuAction.run((_) {
                  started = true;
                  return gate.future;
                }),
              ),
            ],
          ],
        ),
      ).then((_) => done = true),
    );
    await pumpMenu(tester);
    expect(find.text('Timer'), findsOneWidget);
    await tester.tap(find.text('Timer'));
    await pumpMenu(tester);
    expect(started, isTrue);
    expect(find.text('Timer'), findsNothing, reason: 'the menu closed');
    expect(done, isFalse, reason: 'the caller action is still running');
    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(done, isTrue);
  });

  group('renderMenu', () {
    testWidgets('liveTitle and liveSubtitle reach the row and follow', (
      tester,
    ) async {
      final context = await _pump(tester);
      final handle = tester.ensureSemantics();
      final title = ValueNotifier('Timer - 10:00');
      final sub = ValueNotifier('ends at 21:00');
      addTearDown(title.dispose);
      addTearDown(sub.dispose);
      final spec = MenuSpec(
        header: _header,
        groups: [
          [
            MenuItemSpec(
              MenuItemId.sleepTimer,
              icon: KIcons.lyrics,
              title: 'Timer',
              liveTitle: title,
              liveSubtitle: sub,
            ),
          ],
        ],
      );
      final page = renderMenu(
        spec,
        AppLocalizations.of(context),
        MenuActionRunner(ProviderScope.containerOf(context), context),
      );
      unawaited(showKLayeredMenu(context, root: page, backTooltip: 'Back'));
      await tester.pumpAndSettle();
      expect(find.text('Timer - 10:00'), findsOneWidget);
      expect(find.text('Timer'), findsNothing);
      expect(
        tester.getSemantics(find.text('Timer - 10:00')),
        isSemantics(label: 'Timer - 10:00\nends at 21:00', isButton: true),
      );
      title.value = 'Timer - 09:59';
      await tester.pump();
      expect(find.text('Timer - 09:59'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('empty queueIds renders no footer, ids render it', (
      tester,
    ) async {
      final context = await _pump(tester);
      final l10n = AppLocalizations.of(context);
      final runner = MenuActionRunner(
        ProviderScope.containerOf(context),
        context,
      );
      MenuSpec spec(List<TrackId> ids) =>
          MenuSpec(header: _header, groups: const [], queueIds: ids);
      expect(renderMenu(spec([]), l10n, runner).footer, isEmpty);
      expect(renderMenu(spec([TrackId(1)]), l10n, runner).footer, hasLength(2));
    });
  });
}
