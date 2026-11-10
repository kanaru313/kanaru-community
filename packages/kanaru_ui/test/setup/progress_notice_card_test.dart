import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders ($name)', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(
        host(
          const ProgressNoticeCard(
            icon: KIcons.rescan,
            title: Text('Scanning the library'),
            subtitle: Text('Reading tags and covers · 120 / 242 songs'),
            progress: 0.5,
          ),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Scanning the library'), findsOneWidget);
    });
  }

  testWidgets('shows the progress value, clamped', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        const ProgressNoticeCard(
          icon: KIcons.rescan,
          title: Text('t'),
          progress: 1.7,
        ),
      ),
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1.0,
    );
  });

  testWidgets('null progress is indeterminate', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(const ProgressNoticeCard(icon: KIcons.rescan, title: Text('t'))),
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      isNull,
    );
    // Stop the indeterminate animation before the test ends.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a finished notice has no bar', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        const ProgressNoticeCard(
          icon: KIcons.select,
          title: Text('Added 242 songs'),
          subtitle: Text('186 albums · 142 artists'),
          showBar: false,
        ),
      ),
    );
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('is a live region', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const ProgressNoticeCard(
          icon: KIcons.rescan,
          title: Text('Scanning'),
          showBar: false,
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('Scanning')),
      matchesSemantics(label: 'Scanning', isLiveRegion: true),
    );
    handle.dispose();
  });
}
