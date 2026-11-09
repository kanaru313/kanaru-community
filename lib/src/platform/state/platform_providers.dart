import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_paths.dart';

/// Overridden by `runKanaru` (and by tests) with the real value.
final appPathsProvider = Provider<AppPaths>(
  (ref) => throw UnimplementedError('appPathsProvider must be overridden'),
);

/// Versions of the native crates, loaded once at startup.
final nativeVersionsProvider = Provider<String>(
  (ref) => throw UnimplementedError('nativeVersionsProvider must be overridden'),
);
