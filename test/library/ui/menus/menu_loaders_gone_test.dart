import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/ui/menus/menu_loaders.dart';
import 'package:kanaru/src/library/ui/menus/menu_origin.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';

import '../../../database/support/test_db.dart';
import 'menu_fixtures.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    final db = openTestDb();
    addTearDown(db.close);
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
  });

  test(
    'the menu of an album that left the library is "gone", not a fault',
    () async {
      await expectLater(
        albumMenuSpec(
          container,
          env(),
          AlbumKey('artist', 'title'),
          const MenuOrigin.list(),
        ),
        throwsA(isA<ItemGoneException>()),
      );
    },
  );

  test('the menu of an artist that left the library is "gone"', () async {
    await expectLater(
      artistMenuSpec(
        container,
        env(),
        ArtistKey('nobody'),
        const MenuOrigin.list(),
      ),
      throwsA(isA<ItemGoneException>()),
    );
  });
}
