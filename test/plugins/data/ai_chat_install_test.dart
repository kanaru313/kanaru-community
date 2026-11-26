import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';

import '../domain/chat_test_support.dart';
import '../fixtures/zip_builders.dart';
import 'install_test_support.dart';

void main() {
  late InstallHarness h;
  setUp(() => h = InstallHarness());
  tearDown(() => h.dispose());

  test('installs a synthetic ai-chat package into drift', () async {
    final zip = validZip(
      manifest: chatManifest((m) {
        (m['metadata']! as Map<String, Object?>)['author'] = 'someone';
      }),
      extra: {'src/chat.js': 'function execute(req) { return req; }'},
    );
    final held = await h.prepareFile(zip);
    final result = await h.actions.installer.install(held.token);

    expect(result, isA<Installed>());
    final row = (await h.rows.liveById(fileInstallId('Chat', 'someone')))!;
    expect(row.kind, 'ai-chat');
  });
}
