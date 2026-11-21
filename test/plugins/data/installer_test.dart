import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/plugins/data/install/package_writer.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_store.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/data/store/plugin_rows.dart';
import 'package:kanaru/src/plugins/domain/install/held_package.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';
import 'package:kanaru/src/plugins/domain/install/install_rules.dart';
import 'package:kanaru/src/plugins/domain/install/script_checker.dart';

import '../domain/plugin_test_support.dart';
import '../fixtures/zip_builders.dart';
import 'install_test_support.dart';
import 'store_test_support.dart';

void main() {
  late InstallHarness h;
  setUp(() => h = InstallHarness());
  tearDown(() => h.dispose());

  final demoId = fileInstallId('Demo', 'someone');

  Future<InstallResult> install(HeldPackage held) =>
      h.actions.installer.install(held.token);

  InstallFailure? failureOf(InstallResult r) =>
      r is InstallRefused ? r.failure : null;

  group('new install', () {
    test('a file plugin: row, folder, consent = the package hosts', () async {
      final held = await h.prepareFile(InstallHarness.zipOf());
      final result = await install(held);

      expect(result, isA<Installed>());
      expect((result as Installed).outcome, InstallOutcome.installed);
      final row = (await h.rows.liveById(demoId))!;
      expect(row.consentedHosts, ['music.example.com']);
      expect(row.packageSha256, held.sha256);
      expect(row.originKind, PluginOrigin.file);
      expect(await h.files.exists(row), isTrue);
    });

    test('a repository plugin is installed under its repository id', () async {
      final repo = await h.addRepo({'netease': {}});
      final id = await h.installFromRepo(repo, 'netease');
      final row = (await h.rows.liveById(id))!;
      expect(row.originKind, PluginOrigin.repo);
      expect(row.repoSlug, 'netease');
    });

    test('a link plugin keeps its link as the source', () async {
      h.zips['https://x.example.com/p.zip'] = InstallHarness.zipOf();
      final held = await h.prepareLink('https://x.example.com/p.zip');
      expect(await install(held), isA<Installed>());
      final row = (await h.rows.liveById(demoId))!;
      expect(row.originKind, PluginOrigin.link);
      expect(row.originLabel, 'https://x.example.com/p.zip');
    });

    test('a removed plugin comes back as a fresh install', () async {
      await install(await h.prepareFile(InstallHarness.zipOf()));
      await h.actions.remover.remove(demoId);
      expect(await h.rows.liveById(demoId), isNull);

      final result = await install(await h.prepareFile(InstallHarness.zipOf()));
      expect((result as Installed).outcome, InstallOutcome.revived);
      expect(await h.rows.liveById(demoId), isNotNull);
    });

    test('an unknown or used token is tokenExpired', () async {
      expect(
        failureOf(await h.actions.installer.install('nope')),
        InstallFailure.tokenExpired,
      );
      final held = await h.prepareFile(InstallHarness.zipOf());
      await install(held);
      expect(failureOf(await install(held)), InstallFailure.tokenExpired);
    });

    test('a package with problems is refused', () async {
      h.checker.problems['search.js'] = const ScriptProblem(message: 'x');
      final held = await h.prepareFile(InstallHarness.zipOf());
      expect(held.review, isA<ProblemsReview>());
      expect(failureOf(await install(held)), InstallFailure.hasProblems);
      expect(await h.rows.live(), isEmpty);
    });
  });

  group('rules over an installed plugin', () {
    setUp(() async {
      await install(await h.prepareFile(InstallHarness.zipOf(version: 3)));
    });

    test('the same version is refused, an older one too', () async {
      expect(
        failureOf(
          await install(await h.prepareFile(InstallHarness.zipOf(version: 3))),
        ),
        InstallFailure.sameVersion,
      );
      expect(
        failureOf(
          await install(await h.prepareFile(InstallHarness.zipOf(version: 2))),
        ),
        InstallFailure.olderVersion,
      );
    });

    test('a newer version updates: old folder gone, consent follows', () async {
      final before = (await h.rows.liveById(demoId))!;
      final result = await install(
        await h.prepareFile(
          InstallHarness.zipOf(
            version: 4,
            hosts: ['music.example.com', 'api.example.com'],
          ),
        ),
      );
      expect((result as Installed).outcome, InstallOutcome.updated);
      final row = (await h.rows.liveById(demoId))!;
      expect(row.version, 4);
      expect(row.consentedHosts, ['music.example.com', 'api.example.com']);
      expect(row.packageDir, isNot(before.packageDir));
      final folders = await h.files.listFolders();
      expect([for (final f in folders) f.packageDir], [row.packageDir]);
    });

    test('config follows the new form in the same update', () async {
      // Replace the installed plugin with one that has a form.
      await h.actions.remover.remove(demoId);
      final form = {
        'region': {'title': 'Region', 'mode': 'input', 'format': 'text'},
        'old': {'title': 'Old', 'mode': 'input', 'format': 'text'},
      };
      Map<String, Object?> manifest(int v, Object config) =>
          withMeta((m) => m['version'] = v)..['config'] = config;
      await install(await h.prepareFile(validZip(manifest: manifest(5, form))));
      await h.actions.configWrites.setValue(demoId, 'region', 'vn');
      await h.actions.configWrites.setValue(demoId, 'old', 'x');

      final result = await install(
        await h.prepareFile(
          validZip(manifest: manifest(6, {'region': form['region']})),
        ),
      );
      expect(result, isA<Installed>());
      final data = await h.config.read(demoId);
      expect(data.values, {'region': 'vn'});
    });

    test('another kind of plugin is refused', () async {
      final manifest = streamingManifest()
        ..['metadata'] = {
          ...streamingManifest()['metadata']! as Map<String, Object?>,
          'name': 'Demo',
          'author': 'someone',
          'version': 9,
        };
      final held = await h.prepareFile(
        validZip(manifest: manifest, extra: {'src/stream.js': 'x'}),
      );
      expect(failureOf(await install(held)), InstallFailure.kindChange);
    });

    test(
      'a file cannot replace a plugin that came from a repository',
      () async {
        // A row of the file id whose source is a repository.
        await h.actions.remover.remove(demoId);
        final package = packageOf();
        final folder = await h.files.write(demoId, package);
        await h.rows.installOrRevive(
          demoId,
          draftOf(package, folder),
          const PluginSource.repo('https://repo.example.com/plugins.json', 'x'),
        );
        final held = await h.prepareFile(InstallHarness.zipOf(version: 8));
        expect(failureOf(await install(held)), InstallFailure.otherOrigin);
        expect((await h.rows.liveById(demoId))!.version, 3);
      },
    );

    test('a review that is out of date is refused', () async {
      final first = await h.prepareFile(InstallHarness.zipOf(version: 4));
      final second = await h.prepareFile(InstallHarness.zipOf(version: 5));
      expect(await install(second), isA<Installed>());
      expect(failureOf(await install(first)), InstallFailure.reviewStale);
      expect((await h.rows.liveById(demoId))!.version, 5);
    });

    test('a plugin removed since the review is reviewStale', () async {
      final held = await h.prepareFile(InstallHarness.zipOf(version: 4));
      await h.actions.remover.remove(demoId);
      expect(failureOf(await install(held)), InstallFailure.reviewStale);
    });
  });

  group('same origin rule', () {
    final repoA = const RepoHeldSource(
      repoId: 1,
      repoUrl: 'https://a.example.com/p.json',
      slug: 'x',
    );
    test('repo only from the same entry, file and link together', () {
      expect(sameOrigin(repoA, repoA), isTrue);
      expect(
        sameOrigin(
          repoA,
          const RepoHeldSource(
            repoId: 2,
            repoUrl: 'https://b.example.com/p.json',
            slug: 'x',
          ),
        ),
        isFalse,
      );
      expect(sameOrigin(repoA, const FileHeldSource('a.zip')), isFalse);
      expect(
        sameOrigin(const FileHeldSource('a.zip'), const LinkHeldSource('u')),
        isTrue,
      );
      expect(sameOrigin(const FileHeldSource('a.zip'), repoA), isFalse);
      expect(sameOrigin(null, const FileHeldSource('a.zip')), isFalse);
    });
  });

  group('Free rule', () {
    Map<String, Object?> streaming(String name, [int version = 1]) => {
      'metadata': {
        ...(streamingManifest()['metadata']! as Map<String, Object?>),
        'name': name,
        'version': version,
      },
      'script': streamingManifest()['script'],
    };
    Future<InstallResult> installStreaming(String name, [int v = 1]) async =>
        install(
          await h.prepareFile(
            validZip(
              manifest: streaming(name, v),
              extra: {'src/stream.js': 'x'},
            ),
            '$name.zip',
          ),
        );

    test('a file: the second streaming plugin needs Pro', () async {
      expect(await installStreaming('One'), isA<Installed>());
      expect(
        failureOf(await installStreaming('Two')),
        InstallFailure.proRequired,
      );
      h.unlocked = true;
      expect(await installStreaming('Two'), isA<Installed>());
    });

    test('a repository: locked refuses, granted allows', () async {
      Map<String, Object?> entry(String name) => {
        'type': 'streaming',
        'name': name,
        'version': 1,
        'hosts': ['www.youtube.com', '*.googlevideo.com'],
      };
      final zip = validZip(
        manifest: streamingManifest(),
        extra: {'src/stream.js': 'x'},
      );
      final repo = await h.addRepo({
        'a': entry('A'),
        'b': entry('B'),
      }, zip: zip);
      await h.installFromRepo(repo, 'a');
      expect(
        failureOf(await install(await h.prepareRepo(repo, 'b'))),
        InstallFailure.proRequired,
      );
      expect(
        await h.actions.gate.streamingInstallAllowed(
          repoInstallId('https://repo.example.com/plugins.json', 'b'),
        ),
        isFalse,
      );
      h.unlocked = true;
      expect(await install(await h.prepareRepo(repo, 'b')), isA<Installed>());
    });

    test('updating the one streaming plugin is never blocked', () async {
      await installStreaming('One');
      final result = await installStreaming('One', 2);
      expect((result as Installed).outcome, InstallOutcome.updated);
    });

    test('a link: the second streaming plugin needs Pro', () async {
      await installStreaming('One');
      h.zips['https://x.example.com/two.zip'] = validZip(
        manifest: streaming('Two'),
        extra: {'src/stream.js': 'x'},
      );
      final held = await h.prepareLink('https://x.example.com/two.zip');
      expect(failureOf(await install(held)), InstallFailure.proRequired);
    });
  });

  group('failure cleanup', () {
    test('a database failure deletes the new folder', () async {
      final writer = PackageWriter(
        rows: _ThrowingRows(h.db),
        files: h.files,
        config: h.config,
      );
      final held = await h.prepareFile(InstallHarness.zipOf());
      final result = await writer.write(
        installId: demoId,
        package: held.package,
        source: const PluginSource.file('a.zip'),
        mode: InstallMode.install,
      );
      expect((result as InstallRefused).failure, InstallFailure.databaseFailed);
      expect(await h.files.listFolders(), isEmpty);
    });

    test(
      'a config that cannot follow the new form aborts the update',
      () async {
        await install(await h.prepareFile(InstallHarness.zipOf(version: 3)));
        final before = (await h.rows.liveById(demoId))!;
        final writer = PackageWriter(
          rows: h.rows,
          files: h.files,
          config: _RefusingConfig(h),
        );
        final held = await h.prepareFile(InstallHarness.zipOf(version: 4));

        final result = await writer.write(
          installId: demoId,
          package: held.package,
          source: const PluginSource.file('a.zip'),
          mode: InstallMode.update,
        );

        expect(
          (result as InstallRefused).failure,
          InstallFailure.databaseFailed,
        );
        final row = (await h.rows.liveById(demoId))!;
        expect(row.version, 3);
        expect(row.packageDir, before.packageDir);
        expect(
          [for (final f in await h.files.listFolders()) f.packageDir],
          [before.packageDir],
        );
      },
    );

    test('a disk failure writes nothing to the database', () async {
      final bad = InstallHarness(
        writeFile: (file, bytes) async => throw const FileSystemException('x'),
      );
      addTearDown(bad.dispose);
      final held = await bad.prepareFile(InstallHarness.zipOf());
      expect(
        failureOf(await bad.actions.installer.install(held.token)),
        InstallFailure.diskFailed,
      );
      expect(await bad.rows.live(), isEmpty);
    });
  });
}

class _RefusingConfig extends PluginConfigStore {
  _RefusingConfig(InstallHarness h) : super(h.db, h.rows);

  @override
  Future<ConfigWrite> adaptToForm(
    String installId,
    List<ConfigField> before,
    List<ConfigField> after,
  ) async => ConfigWrite.tooLarge;
}

class _ThrowingRows extends PluginRows {
  _ThrowingRows(super.db);

  @override
  Future<(PluginInstallWrite, PluginRow)> installOrRevive(
    String installId,
    PluginDraft draft,
    PluginSource source,
  ) => throw StateError('db down');
}
