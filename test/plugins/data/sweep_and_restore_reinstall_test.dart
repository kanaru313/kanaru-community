import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/install/restore_reinstall.dart';
import 'package:kanaru/src/plugins/data/install/sweep_and_restore.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';

import '../domain/plugin_test_support.dart';
import '../fixtures/zip_builders.dart';
import 'install_test_support.dart';
import 'services_test_support.dart' show pickedZip;

void main() {
  late InstallHarness h;
  setUp(() => h = InstallHarness());
  tearDown(() => h.dispose());

  InstallResult resultOf(List<RestoreOutcome> outcomes, String id) =>
      outcomes.firstWhere((o) => o.installId == id).result;

  Future<void> loseFolder(String id) async {
    final row = (await h.rows.liveById(id))!;
    await h.files.deleteFolder(id, row.packageDir!);
  }

  group('restore re-install', () {
    test('a repository plugin within consent comes back silently', () async {
      final repo = await h.addRepo({'netease': {}});
      final id = await h.installFromRepo(repo, 'netease');
      await loseFolder(id);

      final outcomes = await h.actions.restorer.restoreMissing();

      expect(resultOf(outcomes, id), isA<Installed>());
      expect(await h.files.exists((await h.rows.liveById(id))!), isTrue);
      expect(h.actions.activity.snapshot.missing, isEmpty);
    });

    test('offline: it stays missing and the next retry installs it', () async {
      final repo = await h.addRepo({'netease': {}});
      final id = await h.installFromRepo(repo, 'netease');
      await loseFolder(id);
      final zips = Map.of(h.zips);
      h.zips.clear();

      final first = await h.actions.restorer.restoreMissing();
      expect(resultOf(first, id), isA<InstallPrepareFailed>());
      expect(h.actions.activity.snapshot.missing[id], RestoreAction.download);

      h.zips.addAll(zips);
      final second = await h.actions.restorer.restoreMissing();
      expect(resultOf(second, id), isA<Installed>());
      expect(h.actions.activity.snapshot.missing, isEmpty);
    });

    test('a file plugin waits for the user', () async {
      await h.actions.installer.install(
        (await h.prepareFile(InstallHarness.zipOf())).token,
      );
      final id = fileInstallId('Demo', 'someone');
      await loseFolder(id);

      final outcomes = await h.actions.restorer.restoreMissing();

      expect(
        (resultOf(outcomes, id) as InstallRefused).failure,
        InstallFailure.needsFile,
      );
      expect(h.actions.activity.snapshot.missing[id], RestoreAction.pickFile);
    });

    test('new hosts wait as "Cần xem" and nothing is installed', () async {
      final repo = await h.addRepo({'netease': {}});
      final id = await h.installFromRepo(repo, 'netease');
      await loseFolder(id);
      final hosts = ['music.example.com', 'new.example.com'];
      await h.setCatalog(repo, {
        'netease': {'version': 4, 'hosts': hosts},
      });
      h.zips['https://cdn.example.com/netease/plugin.zip'] =
          InstallHarness.zipOf(version: 4, hosts: hosts);

      final outcomes = await h.actions.restorer.restoreMissing();

      expect(resultOf(outcomes, id), isA<InstallNeedsReview>());
      final held = (resultOf(outcomes, id) as InstallNeedsReview).held;
      expect(h.held.peek(held.token), isNull);
      expect(h.actions.activity.snapshot.needsReview, {id});
      expect(await h.files.exists((await h.rows.liveById(id))!), isFalse);
    });

    test('Free rule: the second streaming plugin stays locked', () async {
      final zip = validZip(
        manifest: streamingManifest(),
        extra: {'src/stream.js': 'x'},
      );
      Map<String, Object?> entry() => {
        'type': 'streaming',
        'version': 1,
        'hosts': ['www.youtube.com', '*.googlevideo.com'],
      };
      final repo = await h.addRepo({'a': entry(), 'b': entry()}, zip: zip);
      h.unlocked = true;
      final a = await h.installFromRepo(repo, 'a');
      final b = await h.installFromRepo(repo, 'b');
      await loseFolder(a);
      await loseFolder(b);

      h.unlocked = false;
      final locked = await h.actions.restorer.restoreMissing();
      expect(resultOf(locked, a), isA<Installed>());
      expect(
        (resultOf(locked, b) as InstallRefused).failure,
        InstallFailure.proRequired,
      );

      h.unlocked = true;
      final granted = await h.actions.restorer.restoreMissing();
      expect(resultOf(granted, b), isA<Installed>());
    });

    test(
      'a refused second streaming plugin stays locked on every path',
      () async {
        Map<String, Object?> streaming(String name, int v) => {
          'metadata': {
            ...(streamingManifest()['metadata']! as Map<String, Object?>),
            'name': name,
            'version': v,
          },
          'script': streamingManifest()['script'],
        };
        Future<InstallResult> installFile(String name, int v) async =>
            h.actions.installer.install(
              (await h.prepareFile(
                validZip(
                  manifest: streaming(name, v),
                  extra: {'src/stream.js': 'x'},
                ),
                '$name.zip',
              )).token,
            );
        h.unlocked = true;
        expect(await installFile('One', 1), isA<Installed>());
        expect(await installFile('Two', 1), isA<Installed>());
        final one = fileInstallId('One', null);
        final two = fileInstallId('Two', null);
        await loseFolder(one);
        await loseFolder(two);
        h.unlocked = false;

        // Both are missing: the oldest may come back, the other may not.
        Future<InstallResult> pick(String name, int v, String id) {
          h.pickedBytes = validZip(
            manifest: streaming(name, v),
            extra: {'src/stream.js': 'x'},
          );
          return h.actions.repairer.repairFromFile(id, pickedZip());
        }

        expect(await pick('One', 1, one), isA<Installed>());
        expect(
          (await pick('Two', 1, two) as InstallRefused).failure,
          InstallFailure.proRequired,
        );
        // A newer version of the locked one is refused too.
        expect(
          (await installFile('Two', 2) as InstallRefused).failure,
          InstallFailure.proRequired,
        );
        // The working one still updates.
        expect(await installFile('One', 2), isA<Installed>());
      },
    );

    test(
      'a repository plugin refused at restore cannot repair or update',
      () async {
        final zip = validZip(
          manifest: streamingManifest(),
          extra: {'src/stream.js': 'x'},
        );
        Map<String, Object?> entry() => {
          'type': 'streaming',
          'version': 1,
          'hosts': ['www.youtube.com', '*.googlevideo.com'],
        };
        final repo = await h.addRepo({'a': entry(), 'b': entry()}, zip: zip);
        h.unlocked = true;
        final a = await h.installFromRepo(repo, 'a');
        final b = await h.installFromRepo(repo, 'b');
        await loseFolder(b);
        h.unlocked = false;

        final outcomes = await h.actions.restorer.restoreMissing();
        expect(
          (resultOf(outcomes, b) as InstallRefused).failure,
          InstallFailure.proRequired,
        );
        expect(
          ((await h.actions.repairer.repair(b)) as InstallRefused).failure,
          InstallFailure.proRequired,
        );
        expect(await h.files.exists((await h.rows.liveById(b))!), isFalse);
        // The holder is untouched.
        expect(await h.files.exists((await h.rows.liveById(a))!), isTrue);
      },
    );

    test(
      'the startup restore scans again and never replays a stale list',
      () async {
        final repo = await h.addRepo({'netease': {}});
        final id = await h.installFromRepo(repo, 'netease');
        await loseFolder(id);
        await h.actions.restorer.restoreMissing();
        final calls = h.fetcher.calls.length;

        final outcomes = await h.actions.restorer.restoreAtStartup();

        expect(outcomes, isEmpty);
        expect(h.fetcher.calls.length, calls);
      },
    );

    test('the startup list is restored too', () async {
      // The queue's first job ran before any row existed: it found nothing.
      final outcomes = await h.actions.restorer.restoreAtStartup();
      expect(outcomes, isEmpty);
    });

    test('repairing a removed plugin is pluginGone', () async {
      final repo = await h.addRepo({'netease': {}});
      final id = await h.installFromRepo(repo, 'netease');
      await loseFolder(id);
      final candidates = await h.actions.repairer.repair(id);
      expect(candidates, isA<Installed>());
      await h.actions.remover.remove(id);
      final result = await h.actions.repairer.repair(id, restore: true);
      expect((result as InstallRefused).failure, InstallFailure.pluginGone);
    });
  });

  group('one queue', () {
    test(
      'a sweep never deletes a folder an install is still writing',
      () async {
        final slow = Completer<void>();
        var first = true;
        final s = InstallHarness(
          writeFile: (file, bytes) async {
            if (first) {
              first = false;
              await slow.future;
            }
            await file.writeAsBytes(bytes);
          },
        );
        addTearDown(s.dispose);
        await s.queue.startup;
        final held = await s.prepareFile(InstallHarness.zipOf());

        final install = s.actions.installer.install(held.token);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final sweep = s.queue.run(s.sweeper.sweep);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        slow.complete();

        expect(await install, isA<Installed>());
        expect(await sweep, 0);
        final row = (await s.rows.liveById(fileInstallId('Demo', 'someone')))!;
        expect(await s.files.exists(row), isTrue);
      },
    );
  });
}
