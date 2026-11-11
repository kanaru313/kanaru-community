import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/screens/now_playing/now_playing_registration.dart';

void main() {
  // Saved queues have no mockup yet: the item is dimmed on both shells and
  // does nothing. The live queue is the right panel (desktop) and the sheet
  // from the mini player (mobile).
  test('the Queue nav item is a dimmed "coming soon" item', () {
    final r = ExtensionRegistry();
    registerNowPlaying(r);
    final item = r.navItems.singleWhere((n) => n.id == 'queue');
    expect(item.comingSoon, isTrue);
    expect(item.onSelect, isNull);
    expect(item.isBranch, isFalse);
  });
}
