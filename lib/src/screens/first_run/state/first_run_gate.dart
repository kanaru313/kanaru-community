import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/state/scan/scan_settings.dart';

const firstRunPath = '/welcome';

/// True while the user has not finished setup (`library.setup_done` is
/// false); the router redirects every location to [firstRunPath].
final firstRunRequiredProvider = Provider<bool>(
  (ref) => !ref.watch(setupDoneProvider),
);
