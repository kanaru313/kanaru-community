import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';

import '../support/app_harness.dart';
import '../support/nav_fixture.dart';

void main() {
  // The harness uses the silent engine under flutter test, so creating the
  // player makes no sound and loads no native library.
  for (final (name, width) in [('desktop', 1280.0), ('mobile', 400.0)]) {
    testWidgets('the $name shell creates the player after its first frame', (
      tester,
    ) async {
      final container = await pumpKanaruApp(
        tester,
        extensions: [const NavFixture()],
        width: width,
        settle: false,
      );
      // pumpWidget ran the first frame, and with it the post-frame start.
      expect(container.read(playerControllerProvider.exists), isTrue);
    });
  }
}
