import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/queue_strip.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../playback/support/ui_host.dart';
import '../../../support/icon_button_finders.dart';

void main() {
  // The strip's Next glyph is the Now Playing size at t = 0 and the mini
  // player size at t = 1, and moves linearly between them.
  for (final (t, size) in [
    (0.0, KIconSize.lg),
    (0.5, (KIconSize.lg + KIconSize.md) / 2),
    (1.0, KIconSize.md),
  ]) {
    testWidgets('strip Next glyph at t = $t is $size', (tester) async {
      await pumpWithPlayer(tester, Center(child: StripNext(t: t)));
      expect(tester.widget<KIconButton>(byIconButton('Next')).size, size);
    });
  }
}
