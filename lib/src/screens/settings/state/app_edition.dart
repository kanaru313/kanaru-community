import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which edition of Kanaru is running. The public build is always [free];
/// the Pro build overrides [appEditionProvider]. Public code only shows the
/// locked Pro surface and holds no Pro logic.
enum AppEdition { free, pro }

final appEditionProvider = Provider<AppEdition>((ref) => AppEdition.free);
