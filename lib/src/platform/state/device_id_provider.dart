import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Id of this install. Overridden by `runKanaru` (and by tests).
final deviceIdProvider = Provider<String>(
  (ref) => throw UnimplementedError('deviceIdProvider must be overridden'),
);
