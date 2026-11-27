import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/state/database_providers.dart';
import '../data/library_overview_query.dart';
import '../domain/overview/library_overview.dart';

export '../domain/overview/library_overview.dart';

/// Library totals for the AI tools.
final libraryOverviewReaderProvider = Provider<LibraryOverviewReader>(
  (ref) => LibraryOverviewQuery(ref.watch(appDatabaseProvider)),
);
