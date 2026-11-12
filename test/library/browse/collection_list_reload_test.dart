import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/browse_items.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/state/browse/collection_providers.dart';

class _Counter extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

void main() {
  test('a list keeps its rows while its summaries reload', () async {
    final dep = NotifierProvider<_Counter, int>(_Counter.new);
    var pending = Completer<List<LanguageSummary>>();
    final container = ProviderContainer(
      overrides: [
        languageSummariesProvider.overrideWith((ref) {
          ref.watch(dep);
          return Stream.fromFuture(pending.future);
        }),
      ],
    );
    addTearDown(container.dispose);
    const key = (sort: SortSpec(SortCriterion.title), filter: '');
    final sub = container.listen(languageListProvider(key), (_, _) {});
    addTearDown(sub.close);
    expect(sub.read().hasValue, isFalse);

    pending.complete(const [
      LanguageSummary(code: 'en', trackCount: 3, detectedCount: 0),
    ]);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().value?.length, 1);

    pending = Completer<List<LanguageSummary>>();
    container.read(dep.notifier).bump();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(languageSummariesProvider).isLoading, isTrue);
    expect(sub.read().value?.length, 1);
  });

  test('an error after data surfaces as an error', () async {
    final dep = NotifierProvider<_Counter, int>(_Counter.new);
    var pending = Completer<List<LanguageSummary>>();
    final container = ProviderContainer(
      // Riverpod 3 retries a failed provider and shows it as loading.
      retry: (_, _) => null,
      overrides: [
        languageSummariesProvider.overrideWith((ref) {
          ref.watch(dep);
          return Stream.fromFuture(pending.future);
        }),
      ],
    );
    addTearDown(container.dispose);
    const key = (sort: SortSpec(SortCriterion.title), filter: '');
    final sub = container.listen(languageListProvider(key), (_, _) {});
    addTearDown(sub.close);
    pending.complete(const [
      LanguageSummary(code: 'en', trackCount: 3, detectedCount: 0),
    ]);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().hasValue, isTrue);
    pending = Completer<List<LanguageSummary>>();
    container.read(dep.notifier).bump();
    await Future<void>.delayed(Duration.zero);
    pending.completeError('boom');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(languageSummariesProvider).hasError, isTrue);
    expect(sub.read().hasError, isTrue);
  });
}
