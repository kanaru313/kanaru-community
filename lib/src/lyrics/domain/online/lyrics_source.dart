/// Where a lyrics plugin was installed from.
enum LyricsSourceOrigin { repo, file, link }

/// Why a source cannot be asked right now.
enum SourceProblem {
  /// The stored `plugin.json` no longer parses.
  broken,

  /// A required configuration field has no value.
  needsConfig,

  /// A rate-limit answer paused it; see [LyricsSource.pausedUntil].
  paused,
}

/// One lyrics plugin as the lyrics module sees it: the user's order, switch
/// and the plugin's state. [id] is the plugin install id and also the icon id.
class LyricsSource {
  const LyricsSource({
    required this.id,
    required this.name,
    required this.version,
    required this.origin,
    required this.enabled,
    this.problem,
    this.pausedUntil,
  });

  final String id;
  final String name;
  final int version;
  final LyricsSourceOrigin origin;

  /// The user's switch for automatic lookups (a manual search may still ask a
  /// disabled source on request).
  final bool enabled;

  /// Most severe first: broken, needs config, paused. Null when it can be
  /// asked.
  final SourceProblem? problem;

  /// End of the pause; set whenever the plugin is paused, even when a more
  /// severe [problem] is shown.
  final DateTime? pausedUntil;

  bool get askable => problem == null;

  @override
  bool operator ==(Object other) =>
      other is LyricsSource &&
      other.id == id &&
      other.name == name &&
      other.version == version &&
      other.origin == origin &&
      other.enabled == enabled &&
      other.problem == problem &&
      other.pausedUntil == pausedUntil;

  @override
  int get hashCode =>
      Object.hash(id, name, version, origin, enabled, problem, pausedUntil);

  @override
  String toString() => 'LyricsSource($id, ${enabled ? 'on' : 'off'})';
}

/// A source in its failure backoff (in memory, phase of the lookup).
class SourceBackoff {
  const SourceBackoff({required this.until, required this.network});

  final DateTime until;

  /// The failure was a network / server one (else the source answered badly).
  final bool network;
}
