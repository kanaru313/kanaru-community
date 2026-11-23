/// How an online copy came to be shown.
enum OnlineHow {
  /// The user kept it ("Bản đã giữ"): it survives the cache.
  kept,

  /// Found by the automatic lookup and held in the cache only.
  auto,
}

/// Where online lyrics came from.
class OnlineLyricsRef {
  const OnlineLyricsRef({
    required this.providerId,
    required this.providerName,
    required this.remoteId,
    required this.how,
    this.remoteDurationMs,
  });

  /// Install id of the plugin.
  final String providerId;

  /// The plugin's name; for a kept copy the name it had when it was kept.
  final String providerName;
  final String remoteId;

  /// Duration the result declared; null when it declared none.
  final int? remoteDurationMs;
  final OnlineHow how;

  @override
  bool operator ==(Object other) =>
      other is OnlineLyricsRef &&
      other.providerId == providerId &&
      other.providerName == providerName &&
      other.remoteId == remoteId &&
      other.remoteDurationMs == remoteDurationMs &&
      other.how == how;

  @override
  int get hashCode =>
      Object.hash(providerId, providerName, remoteId, remoteDurationMs, how);

  @override
  String toString() => 'OnlineLyricsRef($providerId, $remoteId, ${how.name})';
}
