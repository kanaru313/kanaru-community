import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('the last child scrolls clear of the bottom media padding', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            padding: EdgeInsets.only(bottom: 120),
          ),
          child: KPage(
            children: [
              for (var i = 0; i < 20; i++)
                SizedBox(height: 100, child: Text('row $i')),
            ],
          ),
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.text('row 19')).dy,
      lessThanOrEqualTo(680 - KSpace.x7),
    );
  });

  for (final (width, tail) in [(400.0, 32.0), (1400.0, 48.0)]) {
    testWidgets('keeps $tail dp under the last child at width $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, 800)),
            child: KPage(
              children: [
                for (var i = 0; i < 20; i++)
                  SizedBox(height: 100, child: Text('row $i')),
              ],
            ),
          ),
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pumpAndSettle();
      final list = tester.getRect(find.byType(ListView));
      expect(
        list.bottom - tester.getRect(find.text('row 19')).bottom,
        greaterThanOrEqualTo(tail),
      );
    });
  }
}
