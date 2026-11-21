import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';

import 'install_test_support.dart';
import 'services_test_support.dart';

void main() {
  late InstallHarness h;
  setUp(() => h = InstallHarness());
  tearDown(() => h.dispose());

  InstallFailure? failureOf(InstallResult r) =>
      r is InstallRefused ? r.failure : null;

  Future<(int, String)> installedV3() async {
    final repo = await h.addRepo({'netease': {}});
    final id = await h.installFromRepo(repo, 'netease');
    return (repo, id);
  }

  test('a newer version in the catalog updates silently', () async {
    final (repo, id) = await installedV3();
    await h.setCatalog(repo, {
      'netease': {'version': 4},
    });
    h.zips['https://cdn.example.com/netease/plugin.zip'] = InstallHarness.zipOf(
      version: 4,
    );

    final result = await h.actions.updater.update(id);

    expect((result as Installed).outcome, InstallOutcome.updated);
    expect((await h.rows.liveById(id))!.version, 4);
    expect(h.actions.activity.snapshot.updating, isEmpty);
  });

  test('no newer version and a gone entry', () async {
    final (repo, id) = await installedV3();
    expect(
      failureOf(await h.actions.updater.update(id)),
      InstallFailure.noNewerVersion,
    );
    await h.setCatalog(repo, {'other': {}});
    expect(
      failureOf(await h.actions.updater.update(id)),
      InstallFailure.entryGone,
    );
  });

  test('a removed repository stops the updates', () async {
    final (repo, id) = await installedV3();
    await h.repoRows.remove(repo);
    expect(
      failureOf(await h.actions.updater.update(id)),
      InstallFailure.repoRemoved,
    );
  });

  test('new hosts in the catalog: nothing is downloaded', () async {
    final (repo, id) = await installedV3();
    await h.setCatalog(repo, {
      'netease': {
        'version': 4,
        'hosts': ['music.example.com', 'new.example.com'],
      },
    });
    final calls = h.fetcher.calls.length;

    final result = await h.actions.updater.update(id);

    expect(failureOf(result), InstallFailure.needsReview);
    expect(h.fetcher.calls.length, calls);
  });

  test('a download that turns out to add hosts is handed back', () async {
    final (repo, id) = await installedV3();
    await h.setCatalog(repo, {
      'netease': {'version': 4},
    });
    h.zips['https://cdn.example.com/netease/plugin.zip'] = InstallHarness.zipOf(
      version: 4,
    );
    h.fetcher.answer = (uri) async {
      // The user's consent narrows while the zip is on its way, so the
      // downloaded package now adds hosts the catalog did not show.
      await h.db.customStatement(
        "UPDATE plugins SET consented_hosts_json = '[\"other.example.com\"]'",
      );
      return served(InstallHarness.zipOf(version: 4));
    };

    final kept = await h.actions.updater.update(id);
    expect(kept, isA<InstallNeedsReview>());
    final held = (kept as InstallNeedsReview).held;
    expect(h.held.peek(held.token), isNotNull);
    expect((await h.rows.liveById(id))!.version, 3);
    expect(h.actions.activity.snapshot.needsReview, {id});
  });

  test('a failed download is a typed failure and the plugin stays', () async {
    final (repo, id) = await installedV3();
    await h.setCatalog(repo, {
      'netease': {'version': 4},
    });
    h.zips.clear();
    expect(await h.actions.updater.update(id), isA<InstallPrepareFailed>());
    expect((await h.rows.liveById(id))!.version, 3);
  });

  test('two calls for one plugin share one update', () async {
    final (repo, id) = await installedV3();
    await h.setCatalog(repo, {
      'netease': {'version': 4},
    });
    h.zips['https://cdn.example.com/netease/plugin.zip'] = InstallHarness.zipOf(
      version: 4,
    );
    final a = h.actions.updater.update(id);
    final b = h.actions.updater.update(id);
    expect(identical(a, b), isTrue);
    await a;
  });
}
