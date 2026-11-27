import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru/src/ai/domain/output/chat_readiness.dart';
import 'package:kanaru/src/ai/state/chat_view/composer_inputs.dart';
import 'package:kanaru/src/ai/ui/chat_auto_confirm_provider.dart';
import 'package:kanaru/src/ai/ui/auto_mode_confirm.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:material_ui/material_ui.dart';

import 'package:kanaru_ui/kanaru_ui.dart' show KChip, SelectionRow;

import '../../../support/icon_button_finders.dart';
import '../../../support/kanaru_ui_finders.dart';
import '../../../support/memory_settings_store.dart';
import 'composer_harness.dart';

const _pluginButton = 'AI service: Claude';
const _permissionButton =
    'Permission: Ask first · Asks before changing anything';

final _plugins = [
  chatPlugin(),
  chatPlugin(id: 'p2', name: 'Gemini', readiness: const ChatNeedsKey()),
];

void main() {
  group('plugin picker', () {
    testWidgets('selected rows via bySemanticsSelected', (tester) async {
      final handle = tester.ensureSemantics();
      final setup = await pumpComposer(tester, plugins: _plugins);
      await tester.tap(byIconButton(_pluginButton));
      await tester.pumpAndSettle();

      expect(find.text('AI service'), findsOneWidget);
      expect(bySemanticsSelected('Claude'), findsOneWidget);
      expect(bySemanticsSelected('Gemini'), findsNothing);
      expect(find.text('API key set'), findsOneWidget);
      expect(find.text('Needs an API key'), findsOneWidget);
      expect(
        find.text('Applies from the next message. History stays as it is.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Gemini'));
      await tester.pumpAndSettle();
      expect(setup.session.calls, contains('switchPlugin p2'));
      handle.dispose();
    });

    testWidgets('the footer opens the plugin store', (tester) async {
      final setup = await pumpComposer(tester, plugins: _plugins);
      await tester.tap(byIconButton(_pluginButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add an AI service…'));
      await tester.pumpAndSettle();
      expect(setup.host.calls, ['openSettings /settings/plugins?kind=aiChat']);
      expect(find.text('Add an AI service…'), findsNothing);
    });

    testWidgets('the phone shows it as a sheet', (tester) async {
      await pumpComposer(tester, size: const Size(400, 800), plugins: _plugins);
      await tester.tap(byIconButton(_pluginButton));
      await tester.pumpAndSettle();
      expect(find.text('Gemini'), findsOneWidget);
      expect(find.text('Add an AI service…'), findsOneWidget);
    });
  });

  group('permission picker', () {
    testWidgets('selected rows via bySemanticsSelected', (tester) async {
      final handle = tester.ensureSemantics();
      final setup = await pumpComposer(tester);
      await tester.tap(byIconButton(_permissionButton));
      await tester.pumpAndSettle();

      expect(bySemanticsSelected('Ask first'), findsOneWidget);
      expect(bySemanticsSelected('Read only'), findsNothing);
      expect(find.text('Permission in this chat'), findsOneWidget);
      expect(find.text('For this conversation only.'), findsOneWidget);

      // Read only needs no confirmation.
      await tester.tap(find.text('Read only'));
      await tester.pumpAndSettle();
      expect(setup.session.calls, contains('permission readOnly'));
      handle.dispose();
    });

    testWidgets('Tự động uses the shared confirm and cancel keeps the picker '
        'open', (tester) async {
      final scopes = <AutoModeScope>[];
      var allow = false;
      final setup = await pumpComposer(
        tester,
        overrides: [
          chatAutoModeConfirmProvider.overrideWithValue((
            context,
            ref, {
            required scope,
          }) async {
            scopes.add(scope);
            return allow;
          }),
        ],
      );
      await tester.tap(byIconButton(_permissionButton));
      await tester.pumpAndSettle();

      // Cancel: the picker stays, nothing changes.
      await tester.tap(find.text('Automatic'));
      await tester.pumpAndSettle();
      expect(scopes, [AutoModeScope.conversation]);
      expect(find.text('For this conversation only.'), findsOneWidget);
      expect(
        setup.session.calls.where((c) => c.startsWith('permission')),
        isEmpty,
      );

      // Confirm: the picker closes and the permission changes.
      allow = true;
      await tester.tap(find.text('Automatic'));
      await tester.pumpAndSettle();
      expect(scopes, hasLength(2));
      expect(find.text('For this conversation only.'), findsNothing);
      expect(setup.session.calls, contains('permission auto'));
    });
  });

  group('permission picker with the default confirm', () {
    testWidgets(
      'Tự động asks through the shared dialog; cancel changes nothing',
      (tester) async {
        final store = MemorySettingsStore();
        final setup = await pumpComposer(
          tester,
          overrides: [settingsStoreProvider.overrideWithValue(store)],
        );
        await tester.tap(byIconButton(_permissionButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Automatic'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('For this conversation only.'), findsOneWidget);
        expect(
          setup.session.calls.where((c) => c.startsWith('permission')),
          isEmpty,
        );
        expect(store.read('ai.auto_ask'), isNull);
      },
    );
  });

  group('model picker', () {
    testWidgets('model list = options + custom choices with capability tags', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final setup = await pumpComposer(tester);
      await tester.tap(find.text('m1'));
      await tester.pumpAndSettle();

      expect(find.text('Model · Claude'), findsOneWidget);
      expect(find.text('Applies from the next message.'), findsOneWidget);
      expect(find.text('Model 1'), findsOneWidget);
      expect(find.text('Model 2'), findsOneWidget);
      expect(bySemanticsSelected('Model 1'), findsOneWidget);
      // Tags: images, tools, context; a custom model says so.
      expect(find.widgetWithText(KChip, 'Images'), findsNWidgets(2));
      expect(find.widgetWithText(KChip, 'Tools'), findsNWidgets(2));
      expect(find.widgetWithText(KChip, '200K'), findsOneWidget);
      expect(find.widgetWithText(KChip, '32K'), findsOneWidget);
      expect(find.widgetWithText(KChip, 'Custom'), findsOneWidget);
      // The model without images / tools shows those chips dimmed, said aloud.
      expect(
        tester
            .getSemantics(
              find.ancestor(
                of: find.text('Model 2'),
                matching: find.byType(SelectionRow),
              ),
            )
            .label,
        'Model 2\nImages: unavailable\nTools: unavailable\n32K\nCustom',
      );

      await tester.tap(find.text('Model 2'));
      await tester.pumpAndSettle();
      expect(setup.session.calls, contains('switchModel m2'));
      handle.dispose();
    });

    testWidgets('a request from an error card opens it', (tester) async {
      final setup = await pumpComposer(tester);
      setup.container.read(modelPickerRequestProvider.notifier).request();
      await tester.pumpAndSettle();
      expect(find.text('Model 2'), findsOneWidget);
      expect(setup.container.read(modelPickerRequestProvider), isFalse);
    });
  });

  group('locks', () {
    testWidgets('pickers locked while streaming', (tester) async {
      final setup = await pumpComposer(tester, plugins: _plugins);
      setup.session.setTurn(TurnState.streaming);
      await tester.pump();

      await tester.tap(byIconButton(_pluginButton));
      await tester.pumpAndSettle();
      expect(find.text('Add an AI service…'), findsNothing);

      await tester.tap(byIconButton(_permissionButton));
      await tester.pumpAndSettle();
      expect(find.text('For this conversation only.'), findsNothing);

      await tester.tap(find.text('m1'));
      await tester.pumpAndSettle();
      expect(find.text('Model 2'), findsNothing);

      // A request meanwhile is dropped, not kept for later.
      setup.container.read(modelPickerRequestProvider.notifier).request();
      await tester.pumpAndSettle();
      expect(find.text('Model 2'), findsNothing);
      expect(setup.container.read(modelPickerRequestProvider), isFalse);
    });

    testWidgets('pickers stay on while a card waits for the user', (
      tester,
    ) async {
      final setup = await pumpComposer(tester);
      setup.session.setTurn(TurnState.awaitingConfirm);
      await tester.pump();
      await tester.tap(byIconButton(_permissionButton));
      await tester.pumpAndSettle();
      expect(find.text('For this conversation only.'), findsOneWidget);
    });
  });
}
