import 'package:flutter_riverpod/flutter_riverpod.dart';

const firstRunPath = '/welcome';

/// True while the user has not finished setup; the router redirects every
/// location to [firstRunPath]. The first-run flow replaces the body.
final firstRunRequiredProvider = Provider<bool>((ref) => false);
