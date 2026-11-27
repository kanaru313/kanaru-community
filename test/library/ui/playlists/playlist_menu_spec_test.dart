import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kanaru/src/database/database.dart' show TrackStatus;
import 'package:kanaru/src/library/domain/ask_ai_target.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_text_rules.dart';
import 'package:kanaru/src/library/ui/menus/ask_ai_entry.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/menus/menu_origin.dart';
import 'package:kanaru/src/library/ui/playlists/menu/favorites_menu_spec.dart';
import 'package:kanaru/src/library/ui/playlists/menu/playlist_menu_spec.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/library/ui/playlists/menu/playlist_menu_rows.dart';

import '../../playlists/support/playlist_fixtures.dart';
import 'support/playlist_menu_support.dart';

final _today = DateTime(2026, 11, 18);

class _RecordingEntry implements AskAiEntry {
  _RecordingEntry(this.asked);

  final List<AskAiTarget> asked;

  @override
  Future<void> ask(BuildContext context, AskAiTarget target) async =>
      asked.add(target);
}

/// A context the recording entry never touches.
class _NoContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<PlaylistDetail> _load(PlaylistFixture fx, String uid) async =>
    (await fx.repo.loadPlaylist(uid))!;

MenuSpec _playlist(
  PlaylistDetail d, {
  bool own = false,
  bool desktop = false,
}) => buildPlaylistMenu(d, menuEnv(), onOwnPage: own, desktop: desktop);

MenuSpec _favorites(
  PlaylistDetail d, {
  bool own = false,
  bool desktop = false,
}) => buildFavoritesMenu(
  d,
  menuEnv(),
  onOwnPage: own,
  desktop: desktop,
  today: _today,
);

void main() {
  late PlaylistFixture fx;

  // The app gets this from its Material localizations; a pure test does not.
  setUpAll(() => initializeDateFormatting('en'));

  setUp(() async {
    fx = await PlaylistFixture.open();
  });

  Future<PlaylistDetail> playlist({
    String name = 'Chill',
    String description = '',
    int songs = 3,
    bool duplicates = false,
    bool missing = false,
  }) async {
    final tracks = [for (var i = 0; i < songs; i++) await fx.track('$name-$i')];
    final all = [
      ...tracks,
      if (duplicates) tracks.first,
      if (missing) await fx.track('$name-gone', status: TrackStatus.missing),
    ];
    final uid = await fx.repo.createPlaylist(
      name: name,
      description: description,
      tracks: all,
    );
    return _load(fx, uid);
  }

  group('playlist menu', () {
    test('groups and rows elsewhere: go to, play block, Advanced', () async {
      final spec = _playlist(await playlist());
      expect(idsOf(spec.groups), [
        [MenuItemId.link],
        [
          MenuItemId.play,
          MenuItemId.shuffle,
          MenuItemId.playlist,
          MenuItemId.playlistFavoriteAll,
          MenuItemId.playlistEdit,
          MenuItemId.playlistAskAi,
        ],
        [MenuItemId.advanced],
      ]);
      expect(idsOf(spec.advanced), [
        [MenuItemId.playlistDuplicate],
        [MenuItemId.playlistExportM3u, MenuItemId.playlistExportM3uRelative],
        [MenuItemId.playlistDelete],
      ]);
    });

    test('on its own page: no go to, Play or Shuffle', () async {
      final spec = _playlist(await playlist(), own: true);
      expect(idsOf(spec.groups).first, [
        MenuItemId.playlist,
        MenuItemId.playlistFavoriteAll,
        MenuItemId.playlistEdit,
        MenuItemId.playlistAskAi,
      ]);
    });

    test(
      'Delete is only in Advanced, danger, with the files-stay line',
      () async {
        final spec = _playlist(await playlist());
        final main = [for (final g in spec.groups) ...g].map((r) => r.id);
        expect(main, isNot(contains(MenuItemId.playlistDelete)));
        final del = rowOf(spec, MenuItemId.playlistDelete);
        expect(del.danger, isTrue);
        expect(del.subtitle, enL10n.playlistMenuDeleteHint);
      },
    );

    test('Ask AI is a dimmed row without the Pro badge', () async {
      final ai = rowOf(_playlist(await playlist()), MenuItemId.playlistAskAi);
      expect(ai.soon, isTrue);
      expect(ai.pro, isFalse);
      expect(ai.active, isFalse);
    });

    test('Ask AI hands over the playlist uid and its name', () async {
      final detail = await playlist();
      final asked = <AskAiTarget>[];
      final spec = buildPlaylistMenu(
        detail,
        MenuEnv(
          l10n: enL10n,
          canReveal: true,
          pathOf: (_) => null,
          askAi: _RecordingEntry(asked),
        ),
        onOwnPage: false,
        desktop: false,
      );
      final row = rowOf(spec, MenuItemId.playlistAskAi);
      expect(row.soon, isFalse);
      await ((row.action! as RunAction).run(_NoContext()));
      final target = asked.single as AskAiPlaylist;
      expect(target.uid, detail.summary.uid);
      expect(target.label, 'Chill');
    });

    test('explanations are the rows hint, never the subtitle', () async {
      final spec = _playlist(await playlist(songs: 2));
      final copy = rowOf(spec, MenuItemId.playlist);
      expect(copy.hint, enL10n.playlistMenuCopyToHint(2));
      expect(copy.subtitle, isNull);
      final edit = rowOf(spec, MenuItemId.playlistEdit);
      expect(edit.hint, enL10n.playlistMenuEditHint);
      expect(edit.subtitle, isNull);
      final relative = rowOf(spec, MenuItemId.playlistExportM3uRelative);
      expect(relative.hint, enL10n.playlistMenuExportM3uRelativeHint);
      expect(relative.subtitle, isNull);
    });

    test('Duplicate shows the name of the copy as its value', () async {
      final spec = _playlist(await playlist(name: 'x' * 200));
      final dup = rowOf(spec, MenuItemId.playlistDuplicate);
      expect(dup.subtitle, capPlaylistName(enL10n.playlistCopyName('x' * 200)));
      expect(dup.subtitle!.length, 200);
    });

    test(
      'cleanup rows appear only for a count above 0, with the count',
      () async {
        final clean = _playlist(await playlist());
        expect(hasRow(clean, MenuItemId.playlistRemoveDuplicates), isFalse);
        expect(hasRow(clean, MenuItemId.playlistRemoveMissing), isFalse);

        final dirty = _playlist(
          await playlist(name: 'Dirty', duplicates: true, missing: true),
        );
        expect(
          rowOf(dirty, MenuItemId.playlistRemoveDuplicates).subtitle,
          enL10n.playlistMenuRemoveDuplicatesHint(1),
        );
        expect(
          rowOf(dirty, MenuItemId.playlistRemoveMissing).subtitle,
          enL10n.playlistMenuRemoveUnavailableHint(1),
        );
      },
    );

    test(
      'a playlist of missing songs only: nothing to play, cleanup offered',
      () async {
        final uid = await fx.repo.createPlaylist(
          name: 'Lost',
          tracks: [await fx.track('a', status: TrackStatus.missing)],
        );
        final spec = _playlist(await _load(fx, uid));
        expect(rowOf(spec, MenuItemId.play).enabled, isFalse);
        expect(rowOf(spec, MenuItemId.playlist).enabled, isFalse);
        expect(rowOf(spec, MenuItemId.playlistFavoriteAll).enabled, isFalse);
        expect(rowOf(spec, MenuItemId.playlistExportM3u).enabled, isTrue);
        expect(hasRow(spec, MenuItemId.playlistRemoveMissing), isTrue);
        expect(spec.queueIds, isEmpty);
      },
    );

    test(
      'an empty playlist: rows dimmed, no queue buttons, head says empty',
      () async {
        final uid = await fx.repo.createPlaylist(name: 'Void');
        final spec = _playlist(await _load(fx, uid));
        expect(spec.header.subtitle, enL10n.playlistTrackCount(0));
        expect(spec.queueIds, isEmpty);
        for (final id in [
          MenuItemId.play,
          MenuItemId.shuffle,
          MenuItemId.playlist,
          MenuItemId.playlistFavoriteAll,
          MenuItemId.playlistExportM3u,
          MenuItemId.playlistExportM3uRelative,
        ]) {
          expect(rowOf(spec, id).enabled, isFalse, reason: '$id');
        }
        expect(rowOf(spec, MenuItemId.playlistEdit).enabled, isTrue);
      },
    );

    test(
      'Play and the queue buttons take the playable songs in saved order',
      () async {
        final detail = await playlist(missing: true);
        // The last song moves to the top: saved order is not insertion order.
        final entries = await fx.live(detail.summary.uid);
        await fx.repo.moveEntry(
          detail.summary.uid,
          entries[2].uid,
          afterEntryUid: null,
        );
        final expected = [
          TrackId(entries[2].track),
          TrackId(entries[0].track),
          TrackId(entries[1].track),
        ];
        final spec = _playlist(await _load(fx, detail.summary.uid));
        expect(spec.queueIds, expected);
        final play = rowOf(spec, MenuItemId.play).action! as PlayAction;
        final shuffle = rowOf(spec, MenuItemId.shuffle).action! as PlayAction;
        expect(play.ids, expected);
        expect(play.shuffle, isFalse);
        expect(shuffle.ids, expected);
        expect(shuffle.shuffle, isTrue);
        expect(
          play.context,
          PlayContext(
            PlayContextKind.playlist,
            ref: detail.summary.uid,
            label: 'Chill',
          ),
        );
      },
    );

    test('Add to playlist hands the picker the playable songs, this playlist excluded', () async {
      final detail = await playlist(missing: true);
      final request = playlistCopyRequest(detail, enL10n);
      final entries = await fx.live(detail.summary.uid);
      expect(request.tracks, [
        for (final e in entries.take(3)) TrackId(e.track),
      ]);
      expect(request.excludePlaylistUid, detail.summary.uid);
      expect(request.sourceLabel, enL10n.playlistPickerFrom('Chill'));
    });

    test('head: the playlist row, description or desktop edit date', () async {
      final withNote = _playlist(await playlist(description: 'Rainy days'));
      expect(withNote.header.image, MenuImage.playlist);
      expect(withNote.header.title, 'Chill');
      expect(withNote.header.note, 'Rainy days');
      expect(withNote.header.subtitle, contains('3 songs'));
      expect(withNote.header.action!.tooltip, enL10n.playlistMenuChangeCover);

      final bare = await playlist(name: 'Bare');
      expect(_playlist(bare).header.note, isNull);
      final desk = _playlist(bare, desktop: true).header.note!;
      expect(desk, startsWith('Edited '));
    });

    test('origin is the playlist page', () async {
      final detail = await playlist();
      expect(_playlist(detail).origin, MenuOrigin.playlist(detail.summary.uid));
    });

    test(
      'M3U rows are live (not "coming soon") with the export hint',
      () async {
        final spec = _playlist(await playlist());
        expect(rowOf(spec, MenuItemId.playlistExportM3u).soon, isFalse);
        expect(
          rowOf(spec, MenuItemId.playlistExportM3u).subtitle,
          enL10n.playlistMenuExportM3uHint,
        );
      },
    );
  });

  group('Favorites menu', () {
    Future<PlaylistDetail> favorites({
      int songs = 2,
      bool missing = false,
    }) async {
      final tracks = [
        ...await fx.tracks(songs),
        if (missing) await fx.track('gone', status: TrackStatus.missing),
      ];
      if (tracks.isNotEmpty) {
        await fx.repo.addToPlaylists(
          tracks: tracks,
          playlistUids: [PlaylistUids.favorites],
        );
      }
      return _load(fx, PlaylistUids.favorites);
    }

    test('rows: no Edit, Delete, cover button, Ask AI or Add all', () async {
      final spec = _favorites(await favorites());
      expect(idsOf(spec.groups), [
        [MenuItemId.link],
        [MenuItemId.play, MenuItemId.shuffle, MenuItemId.playlist],
        [MenuItemId.advanced],
      ]);
      expect(idsOf(spec.advanced), [
        [MenuItemId.playlistSaveAs, MenuItemId.playlistExportM3u],
        [MenuItemId.playlistClearFavorites],
      ]);
      expect(spec.header.action, isNull);
      expect(spec.header.title, enL10n.playlistFavoritesName);
      expect(spec.header.itemKey, PlaylistUids.favorites);
      expect(hasRow(spec, MenuItemId.playlistExportM3uRelative), isFalse);
      expect(hasRow(spec, MenuItemId.playlistDelete), isFalse);
    });

    test('on its own page the go to and play rows are left out', () async {
      final spec = _favorites(await favorites(), own: true);
      expect(idsOf(spec.groups).first, [MenuItemId.playlist]);
    });

    test('Save as names the copy "Favorites (date)"', () async {
      final spec = _favorites(await favorites());
      final save = rowOf(spec, MenuItemId.playlistSaveAs);
      expect(save.subtitle, startsWith('Favorites ('));
      expect(save.subtitle, contains('2026'));
      expect(save.action, isA<RunAction>());
    });

    test('Remove all is danger with the count, dimmed at 0', () async {
      final full = _favorites(await favorites(songs: 3));
      final clear = rowOf(full, MenuItemId.playlistClearFavorites);
      expect(clear.danger, isTrue);
      expect(clear.enabled, isTrue);
      expect(clear.subtitle, enL10n.playlistMenuClearFavoritesHint(3));
    });

    test(
      'empty Favorites: Remove all and export are dimmed, no queue',
      () async {
        final empty = _favorites(await favorites(songs: 0));
        expect(
          rowOf(empty, MenuItemId.playlistClearFavorites).enabled,
          isFalse,
        );
        expect(rowOf(empty, MenuItemId.playlistExportM3u).enabled, isFalse);
        expect(empty.queueIds, isEmpty);
      },
    );

    test('Remove missing songs only when some are missing', () async {
      expect(
        hasRow(_favorites(await favorites()), MenuItemId.playlistRemoveMissing),
        isFalse,
      );
    });

    test(
      'Remove missing songs appears with the count when some are missing',
      () async {
        final spec = _favorites(await favorites(missing: true));
        expect(
          rowOf(spec, MenuItemId.playlistRemoveMissing).subtitle,
          enL10n.playlistMenuRemoveUnavailableHint(1),
        );
        expect(spec.queueIds, hasLength(2));
      },
    );

    test('Play carries the favorites context', () async {
      final spec = _favorites(await favorites());
      final play = rowOf(spec, MenuItemId.play).action! as PlayAction;
      expect(play.context.kind, PlayContextKind.favorites);
    });
  });
}
