import 'online_text.dart';

/// A kept online copy of a track's lyrics, text already parsed.
class OnlinePick {
  const OnlinePick({
    required this.providerId,
    required this.providerName,
    required this.remoteId,
    this.text,
    this.instrumental = false,
    this.remoteDurationMs,
  });

  final String providerId;
  final String providerName;
  final String remoteId;
  final OnlineText? text;
  final bool instrumental;
  final int? remoteDurationMs;

  bool get usable => text != null || instrumental;
}

/// One row of the lookup cache for the song, text already parsed.
class OnlineCacheEntry {
  const OnlineCacheEntry({
    required this.providerId,
    required this.fetchedAt,
    this.found = false,
    this.remoteId,
    this.text,
    this.instrumental = false,
    this.remoteDurationMs,
  });

  final String providerId;
  final DateTime fetchedAt;

  /// The source answered with a result (see [text], [instrumental]); false is
  /// a "not found" answer.
  final bool found;
  final String? remoteId;
  final OnlineText? text;
  final bool instrumental;
  final int? remoteDurationMs;

  /// A result that carries lyrics or the instrumental flag.
  bool get hasResult => found && (text != null || instrumental);
}
