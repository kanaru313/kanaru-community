import 'json_read.dart';
import 'seekbar_limits.dart';
import 'seekbar_spec.dart';

/// Reads single values of the `seekbar` block.
///
/// Strict (install): the first wrong value stops with
/// `InvalidManifest('<path>')`. Lenient (load): a number out of range is
/// clamped, a wrong optional value gives its default, and only a value with
/// no default (`fallback` null) still throws, so the caller can drop the part
/// it belongs to. Never trusts the JSON: every type is checked.
class SeekbarFields {
  const SeekbarFields({required this.strict});

  final bool strict;

  /// Strict: refuse every key of [raw] not in [allowed]; the path names it.
  void noUnknownKeys(JsonObject raw, Set<String> allowed, String path) {
    if (!strict) return;
    for (final key in raw.keys) {
      if (!allowed.contains(key)) invalid('$path.$key');
    }
  }

  /// [fallback] in lenient mode when there is one, else the problem.
  T refuse<T>(String path, T? fallback) {
    if (!strict && fallback != null) return fallback;
    invalid(path);
  }

  /// A number within [lo]..[hi] under `raw[key]`; [fallback] when absent.
  double number(
    JsonObject raw,
    String key,
    String path, {
    required double lo,
    required double hi,
    required double fallback,
  }) {
    if (!raw.containsKey(key)) return fallback;
    return numberIn(raw[key], '$path.$key', lo, hi, fallback);
  }

  /// [v] as a number within [lo]..[hi]: strict refuses a wrong type or a
  /// value out of range; lenient gives [fb] for a wrong type (throws when
  /// null) and clamps a value out of range.
  double numberIn(Object? v, String path, double lo, double hi, double? fb) {
    if (v is! num) return refuse(path, fb);
    final n = v.toDouble();
    if (n >= lo && n <= hi) return n;
    if (strict) invalid(path);
    return n.clamp(lo, hi).toDouble();
  }

  /// An integer within [lo]..[hi] under `raw[key]`; [fallback] when absent.
  int integer(
    JsonObject raw,
    String key,
    String path, {
    required int lo,
    required int hi,
    required int fallback,
  }) {
    if (!raw.containsKey(key)) return fallback;
    final v = raw[key];
    if (v is! int) return refuse('$path.$key', fallback);
    if (v >= lo && v <= hi) return v;
    if (strict) invalid('$path.$key');
    return v.clamp(lo, hi);
  }

  /// The member of [values] whose `name` is `raw[key]`; [fallback] when
  /// absent or (lenient) unknown.
  T pick<T extends Enum>(
    JsonObject raw,
    String key,
    String path,
    List<T> values,
    T fallback,
  ) {
    if (!raw.containsKey(key)) return fallback;
    final v = raw[key];
    for (final value in values) {
      if (value.name == v) return value;
    }
    return refuse('$path.$key', fallback);
  }

  /// `[a, b]` of numbers within [lo]..[hi]. Null [fallback] means required.
  List<double> pair(
    Object? v,
    String path, {
    required double lo,
    required double hi,
    List<double>? fallback,
  }) {
    if (v is! List || v.length != 2 || v.any((x) => x is! num)) {
      return refuse(path, fallback);
    }
    return [
      numberIn(v[0], path, lo, hi, null),
      numberIn(v[1], path, lo, hi, null),
    ];
  }

  /// `[min, max]` within [lo]..[hi] with min <= max. Strict refuses a
  /// reversed pair; lenient swaps it.
  List<double> range(
    Object? v,
    String path, {
    required double lo,
    required double hi,
  }) {
    final p = pair(v, path, lo: lo, hi: hi);
    if (p[0] <= p[1]) return p;
    if (strict) invalid(path);
    return [p[1], p[0]];
  }

  /// A boolean under `raw[key]`; false when absent (or, lenient, wrong).
  bool flag(JsonObject raw, String key, String path) {
    if (!raw.containsKey(key)) return false;
    final v = raw[key];
    return v is bool ? v : refuse('$path.$key', false);
  }

  /// A theme role or `#rrggbb`; null (lenient) when it is neither.
  SkinColor? colour(Object? v, String path) {
    if (v is String) {
      for (final role in SkinRole.values) {
        if (role.name == v) return SkinRoleColor(role);
      }
      if (seekbarHexColor.hasMatch(v)) {
        return SkinRgbColor(int.parse(v.substring(1), radix: 16));
      }
    }
    if (strict) invalid(path);
    return null;
  }

  /// Optional colour under `raw[key]`.
  SkinColor? optionalColour(JsonObject raw, String key, String path) =>
      raw.containsKey(key) ? colour(raw[key], '$path.$key') : null;
}
