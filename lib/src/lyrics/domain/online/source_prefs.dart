import 'lyrics_source.dart';

/// The user's saved choice for one lyrics plugin: its place in the list (the
/// list order) and its switch.
class SourcePref {
  const SourcePref(this.id, {required this.on});

  final String id;
  final bool on;

  Map<String, Object?> toJson() => {'id': id, 'on': on};

  @override
  bool operator ==(Object other) =>
      other is SourcePref && other.id == id && other.on == on;

  @override
  int get hashCode => Object.hash(id, on);
}

/// Reads the stored list `[{id, on}]`. Throws [FormatException] when the value
/// is not a list; a malformed item is skipped (the rest of the list stays) and
/// a repeated id keeps its first entry.
List<SourcePref> decodeSourcePrefs(Object? json) {
  if (json is! List) throw const FormatException('source prefs: not a list');
  final seen = <String>{};
  final prefs = <SourcePref>[];
  for (final item in json) {
    if (item is! Map || item['id'] is! String || item['on'] is! bool) continue;
    final id = item['id'] as String;
    if (seen.add(id)) prefs.add(SourcePref(id, on: item['on'] as bool));
  }
  return prefs;
}

/// A new lyrics plugin starts on when it came from a repository and off when
/// the user installed it from a file or a link, until the user turns it on.
bool defaultSourceEnabled(LyricsSourceOrigin origin) =>
    origin == LyricsSourceOrigin.repo;

/// The sources in the user's order. [installed] are the live lyrics plugins in
/// install order, each with its default switch. Saved ids come first in the
/// saved order and with the saved switch; plugins that are not saved follow in
/// install order with their default; saved ids of removed plugins drop out.
List<LyricsSource> applySourcePrefs(
  List<SourcePref> saved,
  List<LyricsSource> installed,
) {
  final byId = {for (final s in installed) s.id: s};
  final ordered = <LyricsSource>[];
  final used = <String>{};
  for (final pref in saved) {
    final source = byId[pref.id];
    if (source == null || !used.add(pref.id)) continue;
    ordered.add(_withEnabled(source, pref.on));
  }
  for (final source in installed) {
    if (used.add(source.id)) ordered.add(source);
  }
  return ordered;
}

/// The prefs that store [sources] as they are now (order and switches).
List<SourcePref> prefsOf(List<LyricsSource> sources) => [
  for (final s in sources) SourcePref(s.id, on: s.enabled),
];

LyricsSource _withEnabled(LyricsSource s, bool enabled) => LyricsSource(
  id: s.id,
  name: s.name,
  version: s.version,
  origin: s.origin,
  enabled: enabled,
  problem: s.problem,
  pausedUntil: s.pausedUntil,
);
