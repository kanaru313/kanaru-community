import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/tool_env_write.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/playlists/playlist_repository.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:logging/logging.dart';

import '../../database/support/test_db.dart';

/// A store whose read-back of a new playlist fails.
class _FailingReadBack extends PlaylistRepository {
  _FailingReadBack(super.db);

  @override
  Future<PlaylistDetail?> loadPlaylist(String uid) =>
      throw StateError('secret-token-in-the-message');
}

void main() {
  late AppDatabase db;
  late List<LogRecord> records;
  late void Function() stopListening;

  setUp(() {
    db = openTestDb();
    addTearDown(db.close);
    records = [];
    final previous = Logger.root.level;
    Logger.root.level = Level.ALL;
    final sub = Logger.root.onRecord.listen(records.add);
    stopListening = () {
      sub.cancel();
      Logger.root.level = previous;
    };
    addTearDown(() => stopListening());
  });

  test('a failed read-back after create is logged, not reported', () async {
    final port = PlaylistsWritePortImpl(store: _FailingReadBack(db));

    final made = await port.create('Trip', const []);

    // The playlist exists, so the model is not told it failed.
    expect(made.count, 0);
    final warning = records.singleWhere((r) => r.loggerName == 'ai.tools');
    expect(warning.level, Level.WARNING);
    expect(warning.message, contains('StateError'));
    // The type only: never the text of the error.
    expect(warning.message, isNot(contains('secret-token')));
  });
}
