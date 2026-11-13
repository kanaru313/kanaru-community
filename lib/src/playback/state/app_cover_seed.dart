import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../platform/domain/setting.dart';
import '../../platform/state/settings_providers.dart';
import 'playing_cover_colors.dart';

final _log = Logger('AppCoverSeed');

/// Seed colour (ARGB) of the cover that drives the app theme; null = none, so
/// the default brand seed is used. Internal: the shell keeps it in step with
/// the playing cover, no screen edits it.
final Setting<int?> appCoverSeedSetting = Setting<int?>(
  'app.coverSeed',
  null,
  decode: (json) {
    if (json == null) return null;
    if (json is int && json >= 0 && json <= 0xFFFFFFFF) return json;
    throw FormatException('Not an ARGB colour: $json');
  },
  encode: (v) => v,
);

/// The seed the app theme is built from, read synchronously from the settings
/// store, so the first frame of a launch already has the last one. The root
/// widget reads colours only from here: reading the playing cover directly
/// would create the player while the root builds.
///
/// This is the one place that decides where the theme seed comes from. Today
/// it is the playing cover; a user-chosen seed per brightness (with a switch
/// for "follow the cover") would be decided here too.
final appCoverSeedProvider = settingNotifierProvider(appCoverSeedSetting);

/// Keeps the stored seed in step with the playing cover colours: [colours]
/// stores its seed, [none] clears a stale one, [pending] changes nothing (the
/// previous seed stays while the cover is still being resolved). Nothing is
/// written when the stored value is already right.
void syncAppCoverSeed(WidgetRef ref, PlayingCoverColors value) {
  final int? target;
  switch (value) {
    case PlayingCoverColorsPending():
      return;
    case PlayingCoverColorsFound(:final colors):
      target = colors.seed;
    case PlayingCoverColorsNone():
      target = null;
  }
  if (ref.read(appCoverSeedProvider) == target) return;
  ref.read(appCoverSeedProvider.notifier).set(target).catchError((
    Object e,
    StackTrace st,
  ) {
    _log.warning('could not store the theme seed: $e', e, st);
  });
}
