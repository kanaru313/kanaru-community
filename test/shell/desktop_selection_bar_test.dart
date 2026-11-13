import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/ui/selection/selection_panel.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';

import 'support/desktop_now_playing_host.dart';

void main() {
  testWidgets('the selection panel hides while Now Playing is open and '
      'returns when it closes, the selection kept', (tester) async {
    final host = await pumpDesktopShell(tester);
    host.container
        .read(librarySelectionProvider.notifier)
        .toggle(host.h.tracks.first);
    await tester.pump();
    expect(find.byType(SelectionPanel), findsOneWidget);

    final panel = host.container.read(nowPlayingPanelProvider.notifier);
    panel.open();
    await tester.pump();
    await settleSlide(tester);
    // The shell's panel sits in the covered region: nothing shows, and the
    // queue pane of Now Playing has none of its own.
    expect(find.byType(SelectionPanel), findsNothing);
    expect(host.container.read(hasSelectionProvider), isTrue);

    panel.close();
    await tester.pump();
    await settleSlide(tester);
    expect(find.byType(SelectionPanel), findsOneWidget);

    // Let the panel's throttled duration read finish before the test ends.
    host.container.read(librarySelectionProvider.notifier).clear();
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
  });
}
