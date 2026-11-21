import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/install/plugin_activity.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';

import '../domain/plugin_test_support.dart';
import '../fixtures/zip_builders.dart';
import 'install_test_support.dart';
import 'services_test_support.dart';

const _repoUrl = 'https://repo.example.com/plugins.json';
String _zipOf(String slug) => 'https://cdn.example.com/$slug/plugin.zip';

void main() {
  late InstallHarness h;
  late int repo;
  setUp(() async {
    h = InstallHarness();
    repo = await h.addRepo({'a': {}, 'b': {}, 'c': {}, 'd': {}});
    for (final slug in ['a', 'b', 'c', 'd']) {
      // Each slug is its own plugin with its own name: the id comes from the
      // source, so one zip serves all.
      await h.installFromRepo(repo, slug);
    }
  });
  tearDown(() => h.dispose());

  UpdateOutcome outcome(UpdateAllState s, String slug) => s.outcomes.firstWhere(
    (o) => o.installId == repoInstallId(_repoUrl, slug),
  );

  test(
    'updates the eligible ones; review and failures do not stop it',
    () async {
      final newer = InstallHarness.zipOf(version: 4);
      await h.setCatalog(repo, {
        'a': {'version': 4},
        // New hosts in the catalog: skipped without a download.
        'b': {
          'version': 4,
          'hosts': ['music.example.com', 'new.example.com'],
        },
        'c': {'version': 4},
        // Not newer: not part of the run.
        'd': {},
      });
      h.zips[_zipOf('a')] = newer;
      h.zips.remove(_zipOf('c')); // the download of c fails
      final calls = h.fetcher.calls.length;

      final first = h.actions.updateAll.run();
      final second = h.actions.updateAll.run();
      expect(identical(first, second), isTrue);
      final state = await first;

      expect(state.running, isFalse);
      expect(state.total, 3);
      expect(state.done, 3);
      expect(outcome(state, 'a').result, isA<Installed>());
      expect(
        (outcome(state, 'b').result as InstallRefused).failure,
        InstallFailure.needsReview,
      );
      expect(outcome(state, 'c').result, isA<InstallPrepareFailed>());
      expect(state.notUpdated.length, 2);
      // Only a and c were downloaded; b never.
      final urls = [
        for (final c in h.fetcher.calls.skip(calls)) c.uri.toString(),
      ];
      expect(urls, isNot(contains(_zipOf('b'))));
      expect(urls, containsAll([_zipOf('a'), _zipOf('c')]));
      expect(h.actions.activity.snapshot.updateAll.done, 3);
    },
  );

  test('a package that needs review is dropped and flagged', () async {
    await h.setCatalog(repo, {
      'a': {'version': 4},
    });
    h.fetcher.answer = (uri) async {
      // The user's consent narrows while the zip is on its way, so the
      // downloaded package now adds hosts the catalog did not show.
      await h.db.customStatement(
        "UPDATE plugins SET consented_hosts_json = '[\"other.example.com\"]'",
      );
      return served(InstallHarness.zipOf(version: 4));
    };

    final state = await h.actions.updateAll.run();

    expect(outcome(state, 'a').result, isA<InstallNeedsReview>());
    expect(
      h.held.peek(
        (outcome(state, 'a').result as InstallNeedsReview).held.token,
      ),
      isNull,
    );
    expect(h.actions.activity.snapshot.needsReview, {
      repoInstallId(_repoUrl, 'a'),
    });
    final rows = await h.rows.liveById(repoInstallId(_repoUrl, 'a'));
    expect(rows!.version, 3);
  });

  test('a plugin flagged Cần xem is not downloaded again', () async {
    await h.setCatalog(repo, {
      'a': {'version': 4},
    });
    h.zips[_zipOf('a')] = InstallHarness.zipOf(version: 4);
    h.actions.activity.flagReview(repoInstallId(_repoUrl, 'a'));
    final calls = h.fetcher.calls.length;

    final first = await h.actions.updateAll.run();
    final second = await h.actions.updateAll.run();

    expect(h.fetcher.calls.length, calls);
    expect(
      (outcome(first, 'a').result as InstallRefused).failure,
      InstallFailure.needsReview,
    );
    expect(second.notUpdated.length, 1);
  });

  test('a locked streaming plugin is not downloaded by update all', () async {
    final yt = {
      'type': 'streaming',
      'hosts': ['www.youtube.com', '*.googlevideo.com'],
    };
    final zip = validZip(
      manifest: streamingManifest(),
      extra: {'src/stream.js': 'x'},
    );
    final repo2 = await h.addRepo(
      {
        'holder': {...yt, 'version': 1},
        'other': {...yt, 'version': 1},
      },
      zip: zip,
      url: 'https://repo2.example.com/plugins.json',
    );
    h.unlocked = true;
    await h.installFromRepo(
      repo2,
      'holder',
      repoUrl: 'https://repo2.example.com/plugins.json',
    );
    await h.installFromRepo(
      repo2,
      'other',
      repoUrl: 'https://repo2.example.com/plugins.json',
    );
    h.unlocked = false;
    final newer = {...yt, 'version': 2};
    await h.setCatalog(repo2, {
      'holder': newer,
      'other': newer,
    }, url: 'https://repo2.example.com/plugins.json');
    final calls = h.fetcher.calls.length;

    await h.actions.updateAll.run();

    final urls = [
      for (final c in h.fetcher.calls.skip(calls)) c.uri.toString(),
    ];
    expect(urls, contains(_zipOf('holder')));
    expect(urls, isNot(contains(_zipOf('other'))));
  });

  test('nothing to update is an empty run', () async {
    final state = await h.actions.updateAll.run();
    expect(state.total, 0);
    expect(state.running, isFalse);
  });
}
