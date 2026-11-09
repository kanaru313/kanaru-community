import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/kanaru.dart';

void main() {
  test('FreeLicenseService locks every feature', () {
    const service = FreeLicenseService();
    expect(service.statusOf(const ProFeature('ai-chat')), LicenseStatus.locked);
    expect(service.statusOf(const ProFeature('anything')), LicenseStatus.locked);
  });
}
