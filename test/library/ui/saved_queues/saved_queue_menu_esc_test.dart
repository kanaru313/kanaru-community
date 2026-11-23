import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kanaru/src/library/ui/saved_queues/saved_queue_tile.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import 'support/fake_saved_queue_store.dart';
import 'support/saved_queue_harness.dart';

/// Esc closes a saved queue row's menu on desktop, whether the ⋮ was pressed
/// with a mouse or a finger: the menu's focus wrapper takes focus, and the
/// dialog only needs its exit animation to finish.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi');
  });

  for (final kind in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
    testWidgets('desktop: a menu opened by a ${kind.name} tap closes on Esc', (
      t,
    ) async {
      await pumpSavedQueues(
        t,
        width: 1400,
        height: 900,
        store: FakeSavedQueueStore([
          savedQueue(
            'a',
            savedAt: DateTime(2026, 11, 21, 21, 17).millisecondsSinceEpoch,
            ids: [1, 2, 3],
          ),
        ]),
      );
      final l10n = l10nOf(t);
      final menuPlay = find.text(l10n.savedQueueMenuPlay);

      final gesture = await t.createGesture(kind: kind);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(t.getCenter(find.byType(SavedQueueTile)));
      await t.pump(const Duration(milliseconds: 200));
      await gesture.down(t.getCenter(byIconButton(l10n.libraryMenuMore)));
      await gesture.up();
      await settle(t);
      expect(menuPlay, findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget, reason: 'desktop dialog');

      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      // The dialog's exit animation outlasts a fixed 400 ms pump.
      await t.pumpAndSettle();
      expect(
        menuPlay,
        findsNothing,
        reason: 'focus: ${FocusManager.instance.primaryFocus}',
      );
    });
  }
}
