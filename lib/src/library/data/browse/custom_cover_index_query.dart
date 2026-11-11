import 'package:drift/drift.dart' show Variable;

import '../../../database/database.dart';

/// Live set of the item keys that have a custom cover of [kind] (the
/// `custom_covers.kind` name: `album` or `artist`). Read only; the rows are
/// written by the custom cover controller. Re-emits only when the set changes.
Stream<Set<String>> watchCustomCoverItemKeys(AppDatabase db, String kind) => db
    .customSelect(
      'SELECT item_key FROM custom_covers WHERE kind = ?',
      variables: [Variable.withString(kind)],
      readsFrom: {db.customCovers},
    )
    .watch()
    .map((rows) => {for (final r in rows) r.read<String>('item_key')})
    .distinct(_sameKeys);

bool _sameKeys(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
