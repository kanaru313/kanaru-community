import 'package:drift/drift.dart';

/// Schema version of each extension's own tables. Extensions migrate their
/// tables by hand and record the result here (see the Pro database design).
class ExtensionSchema extends Table {
  TextColumn get extensionId => text()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {extensionId};
}
