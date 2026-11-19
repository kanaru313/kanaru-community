import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../platform/domain/setting.dart';
import '../../../platform/state/settings_providers.dart';
import '../../domain/scan/format_groups.dart';
import '../../domain/scan/scan_rule_values.dart';
import '../../domain/scan/scan_rules.dart';

bool _bool(Object? json) {
  if (json is bool) return json;
  throw FormatException('not a bool: $json');
}

/// `library.setup_done`: the user pressed the arrow on the first-run screen.
/// While false the scanner does nothing and the router shows `/welcome`.
final Setting<bool> setupDoneSetting = Setting(
  'library.setup_done',
  false,
  decode: _bool,
  encode: (v) => v,
);

/// `library.skip_short_tracks`: kept in step with `library.min_duration_ms`
/// (true while the minimum is above 0) so an older build still reads the
/// user's choice. Never deleted. New code uses [minDurationMsProvider].
final Setting<bool> skipShortTracksSetting = Setting(
  'library.skip_short_tracks',
  true,
  decode: _bool,
  encode: (v) => v,
);

/// `library.setup_defaults_applied`: the first-run default folders were
/// added once; removing them later does not bring them back.
final Setting<bool> setupDefaultsAppliedSetting = Setting(
  'library.setup_defaults_applied',
  false,
  decode: _bool,
  encode: (v) => v,
);

final setupDoneProvider = settingNotifierProvider(setupDoneSetting);
final skipShortTracksProvider = settingNotifierProvider(skipShortTracksSetting);
final setupDefaultsAppliedProvider = settingNotifierProvider(
  setupDefaultsAppliedSetting,
);

/// `library.min_duration_ms`: files shorter than this are not scanned
/// (0 = off). Clamped to 0..180000 and snapped to 5 s on read.
final Setting<int> minDurationMsSetting = Setting(
  'library.min_duration_ms',
  ScanRules.defaultMinDurationMs,
  decode: decodeMinDurationMs,
  encode: (v) => v,
);

/// `library.min_size_bytes`: files smaller than this are not scanned
/// (0 = off). One of [minSizeStopsBytes]; decimal units (1 KB = 1000 B).
final Setting<int> minSizeBytesSetting = Setting(
  'library.min_size_bytes',
  0,
  decode: decodeMinSizeBytes,
  encode: (v) => v,
);

/// `library.format_groups`: ids of the format groups that are scanned. A
/// missing, damaged or empty value means every group.
final Setting<List<String>> formatGroupsSetting = Setting(
  'library.format_groups',
  allFormatGroupIds,
  decode: decodeFormatGroups,
  encode: (v) => v,
);

/// `library.respect_nomedia`: Linux only; skip folders holding `.nomedia`.
final Setting<bool> respectNomediaSetting = Setting(
  'library.respect_nomedia',
  false,
  decode: _bool,
  encode: (v) => v,
);

final minSizeBytesProvider = settingNotifierProvider(minSizeBytesSetting);
final formatGroupsProvider = settingNotifierProvider(formatGroupsSetting);
final respectNomediaProvider = settingNotifierProvider(respectNomediaSetting);

/// The minimum duration. While `library.min_duration_ms` is absent it follows
/// the older `library.skip_short_tracks` (false = 0, otherwise 30 s); writing
/// it also writes that key (`value > 0`), so an older build keeps the choice.
class MinDurationNotifier extends Notifier<int> {
  @override
  int build() {
    final store = ref.watch(settingsStoreProvider);
    final sub = store.changes
        .where(
          (k) =>
              k == minDurationMsSetting.key || k == skipShortTracksSetting.key,
        )
        .listen((_) => state = _read());
    ref.onDispose(sub.cancel);
    return _read();
  }

  int _read() {
    final store = ref.read(settingsStoreProvider);
    final raw = store.read(minDurationMsSetting.key);
    if (raw != null) {
      try {
        return minDurationMsSetting.decode(raw);
      } on FormatException catch (e) {
        Logger('settings').warning('Bad value for library.min_duration_ms: $e');
        return minDurationMsSetting.defaultValue;
      }
    }
    final legacy = store.read(skipShortTracksSetting.key);
    return legacy == false ? 0 : minDurationMsSetting.defaultValue;
  }

  /// Stores [value] (made valid first) and updates the state at once.
  Future<void> set(int value) {
    final store = ref.read(settingsStoreProvider);
    final valid = normalizeMinDurationMs(value);
    state = valid;
    return Future.wait([
      store.write(minDurationMsSetting.key, valid),
      store.write(skipShortTracksSetting.key, valid > 0),
    ]);
  }
}

final minDurationMsProvider = NotifierProvider<MinDurationNotifier, int>(
  MinDurationNotifier.new,
);

/// The scan rules as the settings hold them now. A pass reads it once when
/// it starts, so a change applies from the next pass.
final currentScanRulesProvider = Provider<ScanRules>(
  (ref) => ScanRules(
    minDurationMs: ref.watch(minDurationMsProvider),
    minSizeBytes: ref.watch(minSizeBytesProvider),
    allowedExtensions: extensionsOfGroups(
      _orAllFormats(ref.watch(formatGroupsProvider)),
    ),
    respectNomedia: ref.watch(respectNomediaProvider),
  ),
);

/// An empty format list would scan nothing: it means every format, as the
/// setting's decode does.
List<String> _orAllFormats(List<String> ids) =>
    ids.isEmpty ? allFormatGroupIds : ids;
