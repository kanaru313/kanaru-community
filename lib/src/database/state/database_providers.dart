import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_database.dart';

/// Overridden by `runKanaru` with the opened database (tests: in-memory).
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);
