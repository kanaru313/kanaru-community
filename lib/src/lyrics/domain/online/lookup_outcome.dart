/// Why the last lookup of a track found nothing without anyone saying "no
/// lyrics".
enum LookupFailReason {
  /// Network, timeout, server or rate-limit failures; a retry is scheduled.
  network,

  /// Every asked source needs its configuration filled in.
  needsConfig,

  /// The sources answered badly or not at all (broken plugin, bad output).
  noAnswer,
}

/// How the lookup of one track ended without a result. Kept in memory only;
/// the lookup clears it when its retry time comes or the sources, the
/// settings or a plugin's configuration change.
sealed class LookupOutcome {
  const LookupOutcome();
}

/// Every source asked failed, or was skipped for needs-config, backoff or a
/// pause. [retryAt] is when the next try starts (null when nothing is
/// scheduled, e.g. every source needs configuration); [asked] is the number of
/// enabled sources it covered.
class LookupFailed extends LookupOutcome {
  const LookupFailed({required this.reason, required this.asked, this.retryAt});

  final LookupFailReason reason;
  final int asked;
  final DateTime? retryAt;
}

/// Every enabled source is paused (a rate-limit answer) until [until].
class LookupPaused extends LookupOutcome {
  const LookupPaused(this.until);

  final DateTime until;
}
