import '../../media/domain/play_context.dart';
import '../../platform/domain/setting.dart';
import 'repeat_mode.dart';

T _enumByName<T extends Enum>(List<T> values, Object? json) {
  if (json is String) {
    for (final v in values) {
      if (v.name == json) return v;
    }
  }
  throw FormatException('Unknown value: $json');
}

int _int(Object? json) {
  if (json is int) return json;
  if (json is double && json == json.roundToDouble()) return json.toInt();
  throw FormatException('Not an integer: $json');
}

/// Entry id of the loaded queue entry; null = none.
final Setting<int?> currentEntrySetting = Setting<int?>(
  'playback.queue.current_entry',
  null,
  decode: (json) => json == null ? null : _int(json),
  encode: (v) => v,
);

/// Entry ids of the play-next run: the entries added with "play next" that
/// still wait right after the current one. Kept so that a later "play next"
/// goes behind them after a restart. Ids that are no longer a contiguous run
/// after the current entry are ignored on restore.
final Setting<List<int>> playNextRunSetting = Setting<List<int>>(
  'playback.queue.play_next_run',
  const [],
  decode: (json) {
    if (json is! List) throw FormatException('Not a list: $json');
    return [for (final v in json) _int(v)];
  },
  encode: (v) => v,
);

/// Last saved position in the loaded entry, ms.
final Setting<int> positionMsSetting = Setting<int>(
  'playback.position_ms',
  0,
  decode: (json) => _int(json) < 0 ? 0 : _int(json),
  encode: (v) => v,
);

final Setting<bool> shuffleSetting = Setting<bool>(
  'playback.shuffle',
  false,
  decode: (json) {
    if (json is bool) return json;
    throw FormatException('Not a bool: $json');
  },
  encode: (v) => v,
);

/// Stored as `'off' | 'all' | 'one' | 'allShuffled'`: the first three are the
/// original values, the last one is the reshuffled repeat of the whole queue.
final Setting<RepeatMode> repeatSetting = Setting<RepeatMode>(
  'playback.repeat',
  RepeatMode.off,
  decode: (json) => _enumByName(RepeatMode.values, json),
  encode: (v) => v.name,
);

/// Extra plays of the loaded entry still to come under a counted repeat
/// (0 = none, at most 99). Out-of-range stored values are clamped.
final Setting<int> repeatCountSetting = Setting<int>(
  'playback.repeat_count',
  0,
  decode: (json) => _int(json).clamp(0, maxRepeatTimes),
  encode: (v) => v.clamp(0, maxRepeatTimes),
);

/// Where the queue was started: `{kind, ref, label}`. An unknown kind (a
/// newer version wrote it) reads as [PlayContextKind.queue].
final Setting<PlayContext?> contextSetting = Setting<PlayContext?>(
  'playback.context',
  null,
  decode: (json) {
    if (json == null) return null;
    if (json is! Map) throw FormatException('Not a context: $json');
    final kind = json['kind'];
    final ref = json['ref'];
    final label = json['label'];
    if ((ref != null && ref is! String) ||
        (label != null && label is! String)) {
      throw FormatException('Bad context: $json');
    }
    return PlayContext(
      PlayContextKind.values.firstWhere(
        (k) => k.name == kind,
        orElse: () => PlayContextKind.queue,
      ),
      ref: ref as String?,
      label: label as String?,
    );
  },
  encode: (v) =>
      v == null ? null : {'kind': v.kind.name, 'ref': v.ref, 'label': v.label},
);

/// Volume 0-100 (desktop). Out-of-range stored values are clamped.
final Setting<int> volumeSetting = Setting<int>(
  'playback.volume',
  100,
  decode: (json) => _int(json).clamp(0, 100),
  encode: (v) => v.clamp(0, 100),
);
