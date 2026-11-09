import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/main.dart';

void main() {
  testWidgets('shows the native library versions it was given', (tester) async {
    await tester.pumpWidget(const KanaruApp(nativeVersions: 'bridge 0.1.0'));

    expect(find.text('Native: bridge 0.1.0'), findsOneWidget);
  });
}
