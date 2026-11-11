import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:kanaru/src/database/database.dart';

/// Counts the finished SELECT statements of a test database, so a test can
/// wait until the provider under test has really loaded.
class QueryCounter extends QueryInterceptor {
  final _finished = <String>[];

  /// Finished SELECTs whose text contains [fragment].
  int loads(String fragment) =>
      _finished.where((s) => s.contains(fragment)).length;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final rows = await super.runSelect(executor, statement, args);
    _finished.add(statement);
    return rows;
  }
}

/// An in-memory database with the same setup as `openTestDb`, watched by
/// [counter].
AppDatabase openCountingDb(QueryCounter counter) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(
    NativeDatabase.memory(setup: configureConnection).interceptWith(counter),
  );
}
