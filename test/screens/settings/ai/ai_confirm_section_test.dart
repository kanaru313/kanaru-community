import 'package:flutter_test/flutter_test.dart';

import '../../../support/memory_settings_store.dart';
import 'ai_settings_host.dart';

void main() {
  testWidgets('shown only when autoAsk is off', (tester) async {
    await openAiSettings(tester);
    expect(find.text('Confirmation box'), findsNothing);
  });

  testWidgets('Bật lại hides it', (tester) async {
    final store = MemorySettingsStore();
    await store.write('ai.auto_ask', false);
    await openAiSettings(tester, store: store);
    expect(find.text('Confirmation box'), findsOneWidget);
    expect(find.text('Ask before turning on Automatic'), findsOneWidget);

    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();
    expect(store.read('ai.auto_ask'), true);
    expect(find.text('Confirmation box'), findsNothing);
    expect(
      find.text('Choosing Automatic in the chat will ask again'),
      findsOneWidget,
    );
  });
}
