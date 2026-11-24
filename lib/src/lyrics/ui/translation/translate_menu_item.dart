import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'translate_entry_state.dart';

/// Whether the ⋮ item "Dịch lời…" can open: the playing song has lyrics. The
/// item is dimmed and inert otherwise.
final translateMenuAvailableProvider = Provider.autoDispose<bool>(
  (ref) => ref.watch(translateEntryProvider.select((s) => s.available)),
);
