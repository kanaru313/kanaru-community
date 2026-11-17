import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/state/browse/shelf_block_providers.dart';

void main() {
  test('collapsing is kept per kind and is idempotent', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(shelfBlockCollapsedProvider.notifier);
    expect(container.read(shelfBlockCollapsedProvider), isEmpty);

    notifier.set(ShelfBlockKind.albums, true);
    notifier.set(ShelfBlockKind.albums, true);
    expect(container.read(shelfBlockCollapsedProvider), {
      ShelfBlockKind.albums,
    });

    notifier.set(ShelfBlockKind.artists, true);
    notifier.set(ShelfBlockKind.albums, false);
    notifier.set(ShelfBlockKind.albums, false);
    expect(container.read(shelfBlockCollapsedProvider), {
      ShelfBlockKind.artists,
    });
  });
}
