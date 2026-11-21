import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/plugins/data/install/sweep_and_restore.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/state/alerts_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_actions_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_page_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';

import '../data/store_test_support.dart';
import '../domain/plugin_test_support.dart';
import 'state_test_support.dart';

const _url = 'https://repo.example.com/plugins.json';

void main() {
  late StateHarness h;
  tearDown(() => h.dispose());

  Future<String> install(
    String slug, {
    Map<String, Object?>? manifest,
    Map<String, Object> extra = const {},
  }) async {
    final id = repoInstallId(_url, slug);
    await h.container
        .read(pluginRowsProvider)
        .installOrRevive(
          id,
          draftOf(packageOf(manifest, extra), 'v3-1'),
          PluginSource.repo(_url, slug),
        );
    return id;
  }

  Future<PluginAlerts> alerts() async =>
      (await h.settled(pluginAlertsProvider)).requireValue;

  test('a plugin with nothing wrong has no alert', () async {
    h = StateHarness();
    await install('a');
    final a = await alerts();
    expect(a.any, isFalse);
    expect(a.of('x'), isEmpty);
  });

  test('a required setting without a value, until it is set', () async {
    h = StateHarness();
    final id = await install(
      'a',
      manifest: withConfig({
        'token': {
          'title': 'Token',
          'mode': 'input',
          'format': 'text',
          'required': true,
        },
      }),
    );
    expect((await alerts()).of(id), {PluginAlert.missingRequiredConfig});

    await h.container
        .read(pluginActionsProvider)
        .configWrites
        .setValue(id, 'token', 'abc');
    expect((await alerts()).any, isFalse);
  });

  test('missing folders: download or pick the file', () async {
    h = StateHarness();
    final a = await install('a');
    final b = await install('b');
    final row = (await h.container.read(pluginRowsProvider).liveById(a))!;
    h.container.read(pluginActionsProvider).activity.setMissing([
      RestoreCandidate(row, RestoreAction.download),
      RestoreCandidate(
        (await h.container.read(pluginRowsProvider).liveById(b))!,
        RestoreAction.pickFile,
      ),
    ]);

    final result = await alerts();

    expect(result.of(a), {PluginAlert.packageMissing});
    expect(result.of(b), {PluginAlert.reinstallFromFile});
    expect(result.any, isTrue);
  });

  test('a stored manifest that no longer reads is broken', () async {
    h = StateHarness();
    final id = await install('a');
    await h.db.customStatement("UPDATE plugins SET manifest_json = '{'");
    expect((await alerts()).of(id), {PluginAlert.broken});
  });

  test('a second streaming plugin needs Pro, not with it', () async {
    for (final unlocked in [false, true]) {
      h = StateHarness(unlocked: unlocked);
      final first = await install(
        'a',
        manifest: streamingManifest(),
        extra: {'src/stream.js': 'x'},
      );
      final second = await install(
        'b',
        manifest: streamingManifest(),
        extra: {'src/stream.js': 'x'},
      );
      final result = await alerts();
      expect(result.of(first), isEmpty);
      expect(result.of(second), unlocked ? isEmpty : {PluginAlert.proRequired});
      await h.dispose();
    }
    h = StateHarness();
  });

  test(
    'the oldest streaming plugin is offline: the working one keeps the slot',
    () async {
      h = StateHarness();
      final older = await install(
        'a',
        manifest: streamingManifest(),
        extra: {'src/stream.js': 'x'},
      );
      final younger = await install(
        'b',
        manifest: streamingManifest(),
        extra: {'src/stream.js': 'x'},
      );
      final row = (await h.container.read(pluginRowsProvider).liveById(older))!;
      h.container.read(pluginActionsProvider).activity.setMissing([
        RestoreCandidate(row, RestoreAction.download),
      ]);

      final result = await alerts();

      // The younger one works, so the older one is the one that waits.
      expect(result.of(younger), isEmpty);
      expect(result.of(older), {
        PluginAlert.packageMissing,
        PluginAlert.proRequired,
      });
    },
  );

  test('the page of a plugin: row, manifest, alerts, state', () async {
    h = StateHarness();
    final id = await install('a');
    h.container.read(pluginActionsProvider).activity.flagReview(id);

    final page = (await h.settled(pluginPageProvider(id))).requireValue!;

    expect(page.row.installId, id);
    expect(page.manifest?.kind, PluginKind.lyrics);
    expect(page.waitingReview, isTrue);
    expect(page.updating, isFalse);
    expect(page.missing, isNull);
    expect((await h.settled(pluginPageProvider('plugin-none'))).value, isNull);
  });

  test('installed by kind carries the restore state', () async {
    h = StateHarness();
    final id = await install('a');
    final row = (await h.container.read(pluginRowsProvider).liveById(id))!;
    h.container.read(pluginActionsProvider).activity.setMissing([
      RestoreCandidate(row, RestoreAction.download),
    ]);

    final grouped = (await h.settled(installedByKindProvider)).requireValue;

    expect(
      grouped.of(PluginKind.lyrics).single.missing,
      RestoreAction.download,
    );
    expect(grouped.of(PluginKind.streaming), isEmpty);
  });

  test('a database error is the error state', () async {
    h = StateHarness(
      more: [
        installedPluginsProvider.overrideWith(
          (ref) => Stream<List<PluginRow>>.error(StateError('db gone')),
        ),
      ],
    );
    expect((await h.settled(pluginAlertsProvider)).hasError, isTrue);
    expect((await h.settled(pluginPageProvider('x'))).hasError, isTrue);
  });
}
