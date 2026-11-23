import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/data/online/online_cache_store.dart';

import '../../../database/support/test_db.dart';

void main() {
  test('watchByKey emits on listen and after each write to its key', () async {
    final db = openTestDb();
    addTearDown(db.close);
    final store = OnlineCacheStore(db);
    final seen = <List<String>>[];
    final sub = store
        .watchByKey('k')
        .listen((rows) => seen.add([for (final r in rows) r.providerId]));
    await pumpEventQueue();
    expect(seen.last, isEmpty);

    await store.putNotFound('other', 'x', now: 1);
    await store.putNotFound('k', 'a', now: 1);
    await pumpEventQueue();
    expect(seen.last, ['a']);

    await store.deleteRow('k', 'a');
    await pumpEventQueue();
    expect(seen.last, isEmpty);

    await sub.cancel();
    final count = seen.length;
    await store.putNotFound('k', 'b', now: 2);
    await pumpEventQueue();
    expect(seen, hasLength(count), reason: 'nothing after cancel');
  });
}
