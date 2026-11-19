import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/state/m3u/m3u_providers.dart';
import 'package:kanaru/src/library/ui/m3u/m3u_export_flow.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../database/support/test_db.dart';
import 'support/m3u_flow_harness.dart';

void flowTest(String name, Future<void> Function(WidgetTester t) body) =>
    testWidgets(name, (t) async {
      await body(t);
      await t.pumpAndSettle(const Duration(seconds: 5));
    });

Future<String> _playlist(
  WidgetTester t,
  M3uFlowHarness h, {
  String name = 'Road',
  List<String> songs = const ['a.mp3'],
}) async {
  for (final s in songs) {
    h.env.file(s);
  }
  return (await t.runAsync(() async {
    final ids = [
      for (final s in songs)
        TrackId(await addTrack(h.env.db, h.env.source, locator: s)),
    ];
    return h.env.repo.createPlaylist(name: name, tracks: ids);
  }))!;
}

/// The picker answers with a file in `lists/` (existing or not).
SaveTarget _target(M3uFlowHarness h, String name, {bool local = true}) {
  final path = '${h.env.tmp}/lists/$name';
  return SaveTarget(
    name: name,
    handle: path,
    localPath: local ? path : null,
    exists: File(path).existsSync(),
  );
}

Future<void> _run(
  WidgetTester t,
  M3uFlowHarness h,
  String uid, {
  bool relative = false,
}) async {
  final flow = h.start(t, (c) => runM3uExport(c, uid, relative: relative));
  await h.untilDone(t, flow);
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

void main() {
  flowTest('absolute paths: file written, toast names the returned name', (
    t,
  ) async {
    final h = await M3uFlowHarness.pump(t);
    final uid = await _playlist(t, h);
    h.picker.onCreate = (_) async => _target(h, 'Road (1).m3u8');
    await _run(t, h, uid);
    expect(h.picker.suggestedName, 'Road.m3u8');
    expect(h.picker.createFilter!.matchesName('x.m3u8'), isTrue);
    final text = File('${h.env.tmp}/lists/Road (1).m3u8').readAsStringSync();
    expect(text, contains('${h.env.music}/a.mp3'));
    expect(
      find.text(h.l10n(t).playlistM3uExported(1, 'Road (1).m3u8')),
      findsOneWidget,
    );
    expect(h.container.read(m3uExportBusyProvider), isFalse);
  });

  flowTest('relative paths are written relative to the file folder', (t) async {
    final h = await M3uFlowHarness.pump(t);
    final uid = await _playlist(t, h);
    h.picker.onCreate = (_) async => _target(h, 'rel.m3u8');
    await _run(t, h, uid, relative: true);
    final text = File('${h.env.tmp}/lists/rel.m3u8').readAsStringSync();
    expect(text, contains('../music/a.mp3'));
    expect(text, isNot(contains(h.env.tmp)));
  });

  flowTest('cancelled save dialog: nothing written or shown', (t) async {
    final h = await M3uFlowHarness.pump(t);
    final uid = await _playlist(t, h);
    await _run(t, h, uid);
    expect(h.picker.inner.writes, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });

  group('an existing file', () {
    Future<(M3uFlowHarness, String)> setUpExisting(WidgetTester t) async {
      final h = await M3uFlowHarness.pump(t);
      final uid = await _playlist(t, h);
      File('${h.env.tmp}/lists/old.m3u8').writeAsStringSync('OLD');
      h.picker.onCreate = (_) async => _target(h, 'old.m3u8');
      return (h, uid);
    }

    flowTest('Cancel keeps the file', (t) async {
      final (h, uid) = await setUpExisting(t);
      final l10n = h.l10n(t);
      final flow = h.start(t, (c) => runM3uExport(c, uid, relative: false));
      await h.untilFound(
        t,
        find.text(l10n.playlistM3uReplaceTitle('old.m3u8')),
      );
      await t.tap(
        find.text(MaterialLocalizations.of(h.hostContext(t)).cancelButtonLabel),
      );
      await h.untilDone(t, flow);
      expect(File('${h.env.tmp}/lists/old.m3u8').readAsStringSync(), 'OLD');
      expect(h.picker.inner.writes, isEmpty);
    });

    flowTest('Replace overwrites it', (t) async {
      final (h, uid) = await setUpExisting(t);
      final l10n = h.l10n(t);
      final flow = h.start(t, (c) => runM3uExport(c, uid, relative: false));
      await h.untilFound(t, find.text(l10n.m3uExportReplace));
      await t.tap(find.text(l10n.m3uExportReplace));
      await h.untilDone(t, flow);
      expect(
        File('${h.env.tmp}/lists/old.m3u8').readAsStringSync(),
        contains('a.mp3'),
      );
    });
  });

  flowTest('Favorites is named by its display name', (t) async {
    final h = await M3uFlowHarness.pump(t);
    await _playlist(t, h);
    h.picker.onCreate = (_) async => null;
    await _run(t, h, PlaylistUids.favorites);
    expect(h.picker.suggestedName, '${h.l10n(t).playlistFavoritesName}.m3u8');
  });

  flowTest('the suggested name is cleaned and cut to 100 characters', (
    t,
  ) async {
    final h = await M3uFlowHarness.pump(t);
    final uid = await _playlist(t, h, name: 'a/b\u202E${'x' * 150}');
    await _run(t, h, uid);
    final name = h.picker.suggestedName!;
    expect(name, endsWith('.m3u8'));
    expect(name.length, 105);
    expect(name, startsWith('a_b x'));
  });

  flowTest('relative export with an unknown folder: discard and toast', (
    t,
  ) async {
    final h = await M3uFlowHarness.pump(t);
    final uid = await _playlist(t, h);
    final target = _target(h, 'x.m3u8', local: false);
    h.picker.onCreate = (_) async => target;
    await _run(t, h, uid, relative: true);
    expect(h.picker.inner.discarded, [target]);
    expect(find.text(h.l10n(t).m3uExportFolderUnknown), findsOneWidget);
  });

  flowTest('a write failure: discard once and the failure toast', (t) async {
    final h = await M3uFlowHarness.pump(t);
    final uid = await _playlist(t, h);
    final target = _target(h, 'x.m3u8');
    h.picker.onCreate = (_) async => target;
    h.picker.inner.writeResult = const Err(DocumentError.unwritable);
    await _run(t, h, uid);
    expect(h.picker.inner.discarded, [target]);
    expect(find.text(h.l10n(t).playlistM3uExportFailed), findsOneWidget);
  });

  flowTest('an unknown playlist: failure toast, no dialog', (t) async {
    final h = await M3uFlowHarness.pump(t);
    await _run(t, h, 'no-such-uid');
    expect(h.picker.suggestedName, isNull);
    expect(find.text(h.l10n(t).playlistM3uExportFailed), findsOneWidget);
  });

  flowTest('songs without a file are counted in the toast', (t) async {
    final h = await M3uFlowHarness.pump(t);
    final uid = await _playlist(t, h);
    await t.runAsync(() async {
      final remote = await addSource(h.env.db, name: 'Remote');
      final id = await addTrack(h.env.db, remote, locator: 'r1');
      await h.env.repo.addToPlaylists(
        playlistUids: [uid],
        tracks: [TrackId(id)],
      );
    });
    h.picker.onCreate = (_) async => _target(h, 'mix.m3u8');
    await _run(t, h, uid);
    final l10n = h.l10n(t);
    expect(
      find.text(l10n.m3uExportedSkipped(1, 'mix.m3u8', 1)),
      findsOneWidget,
    );
  });
}
