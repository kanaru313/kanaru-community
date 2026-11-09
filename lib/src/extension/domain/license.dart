/// A feature gated behind Pro. Identified by a stable string id.
extension type const ProFeature(String id) {}

enum LicenseStatus { granted, locked }

/// Answers whether a Pro feature is unlocked. The default build ships
/// [FreeLicenseService]; extension packages can provide custom implementations.
abstract interface class LicenseService {
  LicenseStatus statusOf(ProFeature feature);
}

/// Public default: every Pro feature is locked.
class FreeLicenseService implements LicenseService {
  const FreeLicenseService();

  @override
  LicenseStatus statusOf(ProFeature feature) => LicenseStatus.locked;
}
