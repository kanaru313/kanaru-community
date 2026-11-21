import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/install/remover.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';

import '../domain/plugin_test_support.dart';
import '../fixtures/zip_builders.dart';
import 'install_test_support.dart';
import 'services_test_support.dart';

void main() {
  late InstallHarness h;
  setUp(() => h = InstallHarness());
  tearDown(() => h.dispose());

  final id = fileInstallId('Demo', 'someone');

  Future<void> installDemo({int version = 3, Object? config}) async {
    final manifest = withMeta((m) => m['version'] = version);
    if (config != null) manifest['config'] = config;
    final result = await h.actions.installer.install(
      (await h.prepareFile(validZip(manifest: manifest))).token,
    );
    expect(result, isA<Installed>());
  }

  const form = {
    'region': {'title': 'Region', 'mode': 'input', 'format': 'text'},
  };

  test('remove: tombstone, data and folder gone', () async {
    await installDemo(config: form);
    await h.actions.configWrites.setValue(id, 'region', 'vn');

    expect(await h.actions.remover.remove(id), RemoveResult.removed);

    final row = (await h.rows.byId(id))!;
    expect(row.removedAt, isNotNull);
    expect(row.packageDir, isNull);
    expect((await h.config.read(id)).values, isEmpty);
    expect(await h.files.listFolders(), isEmpty);
    expect(await h.actions.remover.remove(id), RemoveResult.alreadyRemoved);
    expect(
      await h.actions.remover.remove('plugin-${'0' * 32}'),
      RemoveResult.missing,
    );
  });

  test('the summary is read fresh', () async {
    await installDemo(config: form);
    var summary = (await h.actions.remover.removeSummary(id))!;
    expect(summary.name, 'Demo');
    expect(summary.hasUserData, isFalse);

    await h.actions.configWrites.setValue(id, 'region', 'vn');
    summary = (await h.actions.remover.removeSummary(id))!;
    expect(summary.configValues, 1);
    expect(summary.hasUserData, isTrue);

    await h.actions.remover.remove(id);
    expect(await h.actions.remover.removeSummary(id), isNull);
  });

  test(
    'a remove while an update is on its way wins; the update finds it gone',
    () async {
      final repo = await h.addRepo({'netease': {}});
      final repoId = await h.installFromRepo(repo, 'netease');
      await h.setCatalog(repo, {
        'netease': {'version': 4},
      });
      final gate = Completer<void>();
      h.fetcher.answer = (uri) async {
        await gate.future;
        return served(InstallHarness.zipOf(version: 4));
      };
      final update = h.actions.updater.update(repoId);
      await Future<void>.delayed(Duration.zero);

      expect(await h.actions.remover.remove(repoId), RemoveResult.removed);
      gate.complete();
      final result = await update;

      expect((result as InstallRefused).failure, InstallFailure.pluginGone);
      expect(await h.rows.liveById(repoId), isNull);
      expect(await h.files.listFolders(), isEmpty);
    },
  );
}
