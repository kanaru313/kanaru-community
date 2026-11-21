import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';

import '../fixtures/zip_builders.dart';
import 'install_test_support.dart';
import 'services_test_support.dart';

void main() {
  late InstallHarness h;
  setUp(() => h = InstallHarness());
  tearDown(() => h.dispose());

  InstallFailure? failureOf(InstallResult r) =>
      r is InstallRefused ? r.failure : null;

  Future<String> repoPlugin() async {
    final repo = await h.addRepo({'netease': {}});
    return h.installFromRepo(repo, 'netease');
  }

  final url = 'https://cdn.example.com/netease/plugin.zip';

  group('repository plugin', () {
    test('the same zip rewrites a lost folder silently', () async {
      final id = await repoPlugin();
      final before = (await h.rows.liveById(id))!;
      await h.files.deleteFolder(id, before.packageDir!);
      expect(await h.files.exists(before), isFalse);

      final result = await h.actions.repairer.repair(id);

      expect((result as Installed).outcome, InstallOutcome.repaired);
      final row = (await h.rows.liveById(id))!;
      expect(await h.files.exists(row), isTrue);
      expect(row.consentedHosts, before.consentedHosts);
      expect(row.installedAt, before.installedAt);
    });

    test(
      'an intact plugin is rewritten into a new folder, old one gone',
      () async {
        final id = await repoPlugin();
        final before = (await h.rows.liveById(id))!;
        await h.actions.repairer.repair(id);
        final row = (await h.rows.liveById(id))!;
        expect(row.packageDir, isNot(before.packageDir));
        expect(
          [for (final f in await h.files.listFolders()) f.packageDir],
          [row.packageDir],
        );
      },
    );

    test('the same version with another hash is refused', () async {
      final id = await repoPlugin();
      h.zips[url] = validZip(extra: {'src/extra.js': 'var a = 1;'});
      expect(
        failureOf(await h.actions.repairer.repair(id)),
        InstallFailure.sameVersion,
      );
    });

    test('a newer version is an update: silent within consent', () async {
      final id = await repoPlugin();
      final repo = (await h.repoRows.all()).single.id;
      await h.setCatalog(repo, {
        'netease': {'version': 4},
      });
      h.zips[url] = InstallHarness.zipOf(version: 4);
      final result = await h.actions.repairer.repair(id);
      expect((result as Installed).outcome, InstallOutcome.updated);
    });

    test('a newer version with new hosts is held for review', () async {
      final id = await repoPlugin();
      final repo = (await h.repoRows.all()).single.id;
      final hosts = ['music.example.com', 'new.example.com'];
      await h.setCatalog(repo, {
        'netease': {'version': 4, 'hosts': hosts},
      });
      h.zips[url] = InstallHarness.zipOf(version: 4, hosts: hosts);
      final result = await h.actions.repairer.repair(id);
      expect(result, isA<InstallNeedsReview>());
      final held = (result as InstallNeedsReview).held;
      expect(h.held.peek(held.token), isNotNull);
      expect((await h.rows.liveById(id))!.version, 3);
    });

    test('offline: a typed failure, the row stays', () async {
      final id = await repoPlugin();
      h.zips.clear();
      expect(await h.actions.repairer.repair(id), isA<InstallPrepareFailed>());
      expect(await h.rows.liveById(id), isNotNull);
    });

    test('a removed repository cannot repair', () async {
      final id = await repoPlugin();
      await h.repoRows.remove((await h.repoRows.all()).single.id);
      expect(
        failureOf(await h.actions.repairer.repair(id)),
        InstallFailure.repoRemoved,
      );
    });
  });

  group('file plugin', () {
    final id = fileInstallId('Demo', 'someone');
    // Built once: a zip carries a timestamp, so two builds can differ.
    final zip = InstallHarness.zipOf();
    setUp(() async {
      await h.actions.installer.install((await h.prepareFile(zip)).token);
    });

    test('repair asks for the file', () async {
      expect(
        failureOf(await h.actions.repairer.repair(id)),
        InstallFailure.needsFile,
      );
    });

    test('the same file brings the folder back', () async {
      final row = (await h.rows.liveById(id))!;
      await h.files.deleteFolder(id, row.packageDir!);
      h.pickedBytes = zip;
      final result = await h.actions.repairer.repairFromFile(id, pickedZip());
      expect((result as Installed).outcome, InstallOutcome.repaired);
    });

    test('the same version with another hash is refused', () async {
      h.pickedBytes = validZip(extra: {'src/extra.js': 'var a = 1;'});
      expect(
        failureOf(await h.actions.repairer.repairFromFile(id, pickedZip())),
        InstallFailure.sameVersion,
      );
    });

    test('a newer version updates; another plugin is refused', () async {
      h.pickedBytes = InstallHarness.zipOf(version: 4);
      expect(
        await h.actions.repairer.repairFromFile(id, pickedZip()),
        isA<Installed>(),
      );
      h.pickedBytes = validZip(
        manifest: {
          'metadata': {
            'apiVersion': 1,
            'type': 'lyrics',
            'name': 'Other',
            'version': 9,
            'hosts': ['music.example.com'],
          },
          'script': {'search': 'search.js', 'lyrics': 'lyrics.js'},
        },
      );
      expect(
        failureOf(await h.actions.repairer.repairFromFile(id, pickedZip())),
        InstallFailure.wrongPlugin,
      );
    });
  });

  test('a link plugin is downloaded again', () async {
    h.zips['https://x.example.com/p.zip'] = InstallHarness.zipOf();
    await h.actions.installer.install(
      (await h.prepareLink('https://x.example.com/p.zip')).token,
    );
    final id = fileInstallId('Demo', 'someone');
    final row = (await h.rows.liveById(id))!;
    await h.files.deleteFolder(id, row.packageDir!);
    expect(await h.actions.repairer.repair(id), isA<Installed>());
  });
}
