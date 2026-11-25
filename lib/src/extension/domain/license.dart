/// A feature gated behind Pro. Identified by a stable string id.
extension type const ProFeature(String id) {}

enum LicenseStatus { granted, locked }

/// Answers whether a Pro feature is unlocked. The default build ships
/// [FreeLicenseService]; extension packages can provide custom implementations.
///
/// UI and state code never call [statusOf] directly: they read
/// `proFeatureStatusProvider(feature)`, which follows [changes].
abstract interface class LicenseService {
  LicenseStatus statusOf(ProFeature feature);

  /// Emits after [statusOf] may answer differently for any feature (a purchase
  /// confirmed, a licence expired or revoked). Implementations update their
  /// state first, then emit; listeners re-ask [statusOf] instead of reading a
  /// value from the event. Never emit from inside [statusOf]: every listener
  /// asks again, so that would never settle.
  ///
  /// Readers keep the last answer until this stream emits; they never re-ask
  /// on a clock. An answer that depends on time (an expiry, the end of a grace
  /// period) must therefore be emitted here by the implementation itself when
  /// that moment comes, e.g. from its own timer.
  ///
  /// Must be a broadcast stream: several providers listen at once and come and
  /// go while the app runs.
  Stream<void> get changes;
}

/// Public default: every Pro feature is locked, and that never changes.
class FreeLicenseService implements LicenseService {
  const FreeLicenseService();

  @override
  LicenseStatus statusOf(ProFeature feature) => LicenseStatus.locked;

  @override
  Stream<void> get changes => const Stream<void>.empty();
}
