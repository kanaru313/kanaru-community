import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/state/chat_view/history_view.dart';

void main() {
  ProviderContainer make() {
    final container = ProviderContainer(
      overrides: [
        chatHistoryDebounceProvider.overrideWithValue(
          const Duration(milliseconds: 30),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(chatHistorySearchProvider, (_, _) {});
    return container;
  }

  test(
    'the search text settles after the debounce, the last text wins',
    () async {
      final container = make();
      final query = container.read(chatHistoryQueryProvider.notifier);
      query.set('ly');
      query.set('lyr');
      expect(container.read(chatHistorySearchProvider), '');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(container.read(chatHistorySearchProvider), 'lyr');
    },
  );

  test('clearing the search shows the whole list at once', () async {
    final container = make();
    final query = container.read(chatHistoryQueryProvider.notifier);
    query.set('lyr');
    await Future<void>.delayed(const Duration(milliseconds: 120));
    query.set('');
    expect(container.read(chatHistorySearchProvider), '');
  });
}
