/// Why a translation could not be produced. Value equality so state and
/// tests can compare failures.
sealed class TranslationFailure {
  const TranslationFailure();

  /// No translate plugin is installed or chosen.
  const factory TranslationFailure.noService() = NoService;

  /// The plugin needs these settings (their titles) before it can run.
  const factory TranslationFailure.needsConfig(List<String> fieldTitles) =
      NeedsConfig;

  /// The service refused the key.
  const factory TranslationFailure.badKey() = BadKey;

  /// The service's quota is used up.
  const factory TranslationFailure.quota() = Quota;

  /// The service asked to wait until [until].
  const factory TranslationFailure.rateLimited(DateTime until) = RateLimited;

  /// The service could not be reached.
  const factory TranslationFailure.network() = NetworkFailure;

  /// The service answered with a server error.
  const factory TranslationFailure.server() = ServerFailure;

  /// The answer broke the output rules (shape, length, empty lines).
  const factory TranslationFailure.invalidResponse() = InvalidResponse;

  /// The song has more lines, characters or chunks than one job may send.
  const factory TranslationFailure.tooLong() = TooLong;

  /// The plugin was removed or changed kind while the job ran.
  const factory TranslationFailure.pluginGone() = PluginGone;

  /// The plugin does not list [target] among its languages; nothing is sent.
  const factory TranslationFailure.unsupportedLanguage(String target) =
      UnsupportedLanguage;
}

final class NoService extends TranslationFailure {
  const NoService();

  @override
  bool operator ==(Object other) => other is NoService;

  @override
  int get hashCode => (NoService).hashCode;
}

final class NeedsConfig extends TranslationFailure {
  const NeedsConfig(this.fieldTitles);

  final List<String> fieldTitles;

  @override
  bool operator ==(Object other) =>
      other is NeedsConfig && _sameList(other.fieldTitles, fieldTitles);

  @override
  int get hashCode => Object.hashAll(fieldTitles);
}

final class BadKey extends TranslationFailure {
  const BadKey();

  @override
  bool operator ==(Object other) => other is BadKey;

  @override
  int get hashCode => (BadKey).hashCode;
}

final class Quota extends TranslationFailure {
  const Quota();

  @override
  bool operator ==(Object other) => other is Quota;

  @override
  int get hashCode => (Quota).hashCode;
}

final class RateLimited extends TranslationFailure {
  const RateLimited(this.until);

  final DateTime until;

  @override
  bool operator ==(Object other) =>
      other is RateLimited && other.until == until;

  @override
  int get hashCode => until.hashCode;
}

final class NetworkFailure extends TranslationFailure {
  const NetworkFailure();

  @override
  bool operator ==(Object other) => other is NetworkFailure;

  @override
  int get hashCode => (NetworkFailure).hashCode;
}

final class ServerFailure extends TranslationFailure {
  const ServerFailure();

  @override
  bool operator ==(Object other) => other is ServerFailure;

  @override
  int get hashCode => (ServerFailure).hashCode;
}

final class InvalidResponse extends TranslationFailure {
  const InvalidResponse();

  @override
  bool operator ==(Object other) => other is InvalidResponse;

  @override
  int get hashCode => (InvalidResponse).hashCode;
}

final class TooLong extends TranslationFailure {
  const TooLong();

  @override
  bool operator ==(Object other) => other is TooLong;

  @override
  int get hashCode => (TooLong).hashCode;
}

final class PluginGone extends TranslationFailure {
  const PluginGone();

  @override
  bool operator ==(Object other) => other is PluginGone;

  @override
  int get hashCode => (PluginGone).hashCode;
}

final class UnsupportedLanguage extends TranslationFailure {
  const UnsupportedLanguage(this.target);

  final String target;

  @override
  bool operator ==(Object other) =>
      other is UnsupportedLanguage && other.target == target;

  @override
  int get hashCode => Object.hash(UnsupportedLanguage, target);
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
