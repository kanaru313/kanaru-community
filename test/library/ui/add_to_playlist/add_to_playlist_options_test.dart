import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/data/playlists/playlist_reads.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/ui/add_to_playlist/add_to_playlist_model.dart';
import 'package:kanaru/src/library/ui/add_to_playlist/add_to_playlist_options.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../playlists/support/playlist_fixtures.dart';
import 'support/picker_host.dart';

class _Opened {
  Future<Set<String>?>? result;
}

/// Opens the picker with the builders of [content], as the flow does.
void Function(BuildContext) _open(
  AddToPlaylistPickerContent c,
  _Opened opened,
) =>
    (context) => opened.result = showMultiSelectionPicker<String>(
      context,
      title: c.title,
      subtitle: c.subtitle,
      options: c.options,
      pinned: c.pinned,
      leadingAction: c.leadingAction,
      filterHint: c.filterHint,
      footerNote: c.footerNote,
      cancelLabel: c.cancelLabel,
      confirmLabel: c.confirmLabel,
      canConfirm: c.canConfirm,
      confirmTimeout: null,
    );

Finder _row(String text) => find.widgetWithText(SelectionRow, text);

bool _ticked(WidgetTester tester, String text) =>
    tester.widget<SelectionRow>(_row(text)).selected;

double _y(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

class _Setup {
  _Setup(this.fx, this.tracks);
  final PlaylistFixture fx;
  final List<TrackId> tracks;
}

Future<_Setup> _fixture(WidgetTester tester, {int playlists = 3}) async {
  late _Setup setup;
  await tester.runAsync(() async {
    final fx = await PlaylistFixture.open();
    final tracks = await fx.tracks(3);
    for (var i = 0; i < playlists; i++) {
      fx.clock += 100;
      await fx.repo.createPlaylist(name: 'List $i', tracks: [tracks.first]);
    }
    setup = _Setup(fx, tracks);
  });
  return setup;
}

Future<AddToPlaylistPickerContent> _content(
  WidgetTester tester,
  _Setup s, {
  String locale = 'en',
  String? excludeUid,
  String sourceLabel = 'Album',
  List<TrackId>? tracks,
}) async {
  late AddToPlaylistPickerContent content;
  await tester.runAsync(() async {
    final summaries = await loadSummaries(s.fx.db);
    final batch = tracks ?? s.tracks;
    final counts = await s.fx.repo.countExisting(batch);
    content = AddToPlaylistPickerContent(
      l10n: l10nOf(locale),
      request: AddToPlaylistRequest(
        tracks: batch,
        sourceLabel: sourceLabel,
        excludePlaylistUid: excludeUid,
      ),
      summaries: summaries,
      counts: counts,
    );
  });
  return content;
}

void main() {
  testWidgets('order: Favorites, divider, new, playlists newest first; '
      'no select-all', (tester) async {
    final s = await _fixture(tester);
    final c = await _content(tester, s);
    final opened = _Opened();
    await pumpOpener(tester, onOpen: _open(c, opened));
    await openIt(tester);

    final order = ['Favorites', 'New playlist…', 'List 2', 'List 1', 'List 0'];
    final ys = [for (final t in order) _y(tester, find.text(t))];
    expect(ys, [...ys]..sort(), reason: 'rows are in this order');
    expect(find.byType(Divider), findsOneWidget);
    expect(find.textContaining('Select all'), findsNothing);
    expect(find.byType(KFilterField), findsNothing);
    expect(
      find.text(c.l10n.playlistPickerFavoritesHint),
      findsNothing,
      reason: 'the Favorites hint is not a visible line',
    );
    expect(c.pinned.single.hint, c.l10n.playlistPickerFavoritesHint);
    expect(c.options.every((o) => o.hint == null), isTrue);
    expect(find.text('Add to playlist'), findsOneWidget);
    expect(find.text('3 songs · Album'), findsOneWidget);
  });

  testWidgets('no playlists: Favorites, divider, new only', (tester) async {
    final s = await _fixture(tester, playlists: 0);
    final c = await _content(tester, s);
    await pumpOpener(tester, onOpen: _open(c, _Opened()));
    await openIt(tester);
    expect(find.byType(SelectionRow), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('New playlist…'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(find.byType(KFilterField), findsNothing);
  });

  testWidgets('source playlist is hidden; Favorites as source hides the pin', (
    tester,
  ) async {
    final s = await _fixture(tester);
    final uid = (await tester.runAsync(() => loadSummaries(s.fx.db)))!
        .playlists
        .first
        .uid;
    final c = await _content(tester, s, excludeUid: uid);
    expect(c.options.length, 2);
    expect(c.offeredUids, isNot(contains(uid)));

    final fav = await _content(tester, s, excludeUid: PlaylistUids.favorites);
    expect(fav.pinned, isEmpty);
    await pumpOpener(tester, onOpen: _open(fav, _Opened()));
    await openIt(tester);
    expect(find.text('Favorites'), findsNothing);
    expect(find.byType(Divider), findsNothing);
    expect(find.text('New playlist…'), findsOneWidget);
  });

  testWidgets('subtitle tells how many of the songs a playlist holds', (
    tester,
  ) async {
    final s = await _fixture(tester);
    final c = await _content(tester, s);
    await pumpOpener(tester, onOpen: _open(c, _Opened()));
    await openIt(tester);
    expect(find.text('1 song · has 1 / 3'), findsNWidgets(3));

    final one = await _content(tester, s, tracks: [s.tracks.first]);
    final hint = one.options.first.subtitle! as Text;
    expect(hint.data, '1 song · has this song');
    final none = await _content(tester, s, tracks: [s.tracks.last]);
    expect((none.options.first.subtitle! as Text).data, '1 song');
  });

  testWidgets('empty source label shows the selection size', (tester) async {
    final s = await _fixture(tester);
    final c = await _content(tester, s, sourceLabel: '');
    await pumpOpener(tester, onOpen: _open(c, _Opened()));
    await openIt(tester);
    expect(find.text('3 selected songs'), findsOneWidget);
  });

  testWidgets('filter field from 11 playlists, not at 10; ticks survive it', (
    tester,
  ) async {
    final ten = await _fixture(tester, playlists: 10);
    final c10 = await _content(tester, ten);
    expect(c10.filterHint, isNull);

    final s = await _fixture(tester, playlists: 11);
    final c = await _content(tester, s);
    expect(c.filterHint, c.l10n.playlistFilterHint);
    await pumpOpener(tester, onOpen: _open(c, _Opened()));
    await openIt(tester);
    expect(find.byType(KFilterField), findsOneWidget);

    await tester.tap(find.text('List 10'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'list 7');
    await tester.pumpAndSettle();
    expect(find.text('List 3'), findsNothing);
    expect(find.text('List 7'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget, reason: 'one hidden tick counts');

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(_ticked(tester, 'List 10'), isTrue);
  });

  testWidgets('new playlist: named in a dialog, ticked, recorded in order', (
    tester,
  ) async {
    final s = await _fixture(tester, playlists: 1);
    final c = await _content(tester, s);
    final opened = _Opened();
    await pumpOpener(tester, onOpen: _open(c, opened));
    await openIt(tester);

    await tester.tap(find.text('New playlist…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Road trip');
    await tester.tap(find.text(c.l10n.playlistPickerNewConfirm));
    await tester.pumpAndSettle();

    expect(c.pendingNames, {pendingKey(1): 'Road trip'});
    expect(_row('Road trip'), findsOneWidget);
    expect(_ticked(tester, 'Road trip'), isTrue);
    expect(find.text('New'), findsOneWidget, reason: 'the badge');
    expect(find.text('Created when you press Add'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);

    // A second typed playlist keeps typed order and a numbered default.
    await tester.tap(find.text('New playlist…'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField).last);
    expect(field.controller!.text, 'New playlist');
    await tester.tap(find.text(c.l10n.playlistPickerNewConfirm));
    await tester.pumpAndSettle();
    expect(c.pendingNames.keys.toList(), [pendingKey(1), pendingKey(2)]);
    expect(find.text('Add to 2 playlists'), findsOneWidget);

    await tester.tap(find.text('Add to 2 playlists'));
    await tester.pumpAndSettle();
    expect(await opened.result, {pendingKey(1), pendingKey(2)});
  });

  testWidgets('cancelling the name dialog leaves the picker as it was', (
    tester,
  ) async {
    final s = await _fixture(tester);
    final c = await _content(tester, s);
    await pumpOpener(tester, onOpen: _open(c, _Opened()));
    await openIt(tester);
    await tester.tap(find.text('List 1'));
    await tester.pump();

    await tester.tap(find.text('New playlist…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(c.l10n.playlistCancel).last);
    await tester.pumpAndSettle();

    expect(c.pendingNames, isEmpty);
    expect(_ticked(tester, 'List 1'), isTrue);
    expect(find.text('Add to playlist'), findsOneWidget);
  });

  testWidgets('confirm is off while every tick is a known-deleted playlist', (
    tester,
  ) async {
    final s = await _fixture(tester);
    final c = await _content(tester, s);
    final gone = c.options.first.value;
    c.knownGone.add(gone);
    expect(c.canConfirm({gone}), isFalse);
    expect(c.canConfirm({gone, c.options.last.value}), isTrue);
    expect(c.canConfirm({}), isFalse);
  });

  testWidgets('Esc in the name dialog closes only it; ticks stay', (
    tester,
  ) async {
    final s = await _fixture(tester);
    final c = await _content(tester, s);
    await pumpOpener(tester, onOpen: _open(c, _Opened()));
    await openIt(tester);
    await tester.tap(find.text('List 1'));
    await tester.pump();

    await tester.tap(find.text('New playlist…'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Add to playlist'), findsOneWidget);
    expect(c.pendingNames, isEmpty);
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(_row('List 1')),
      isSemantics(
        isChecked: true,
        hasCheckedState: true,
        isEnabled: true,
        hasEnabledState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('pending row: badge, visible state line, ticked', (tester) async {
    final s = await _fixture(tester, playlists: 1);
    final c = await _content(tester, s);
    await pumpOpener(tester, onOpen: _open(c, _Opened()));
    await openIt(tester);
    await tester.tap(find.text('New playlist…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Road trip');
    await tester.tap(find.text(c.l10n.playlistPickerNewConfirm));
    await tester.pumpAndSettle();

    final row = _row('Road trip');
    expect(
      find.descendant(
        of: row,
        matching: find.text(c.l10n.playlistPickerNewBadge),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row,
        matching: find.text(c.l10n.playlistPickerNewHint),
      ),
      findsOneWidget,
    );
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(row),
      isSemantics(
        isChecked: true,
        hasCheckedState: true,
        isEnabled: true,
        hasEnabledState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('filter finds a pending name and Favorites by its localized '
      'name; ticks survive', (tester) async {
    final s = await _fixture(tester, playlists: 11);
    final c = await _content(tester, s);
    await pumpOpener(tester, onOpen: _open(c, _Opened()), size: desktop);
    await openIt(tester);
    await tester.tap(find.text('List 10'));
    await tester.tap(find.text('New playlist…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Road trip');
    await tester.tap(find.text(c.l10n.playlistPickerNewConfirm));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'road');
    await tester.pumpAndSettle();
    expect(_row('Road trip'), findsOneWidget);
    expect(find.byType(SelectionRow), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'favor');
    await tester.pumpAndSettle();
    expect(_row('Favorites'), findsOneWidget);
    expect(find.byType(SelectionRow), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    expect(_ticked(tester, 'List 10'), isTrue);
    expect(_ticked(tester, 'Road trip'), isTrue);
  });

  group('layout', () {
    for (final (label, size, scale, brightness, reduce) in [
      ('phone 1.5', phone, 1.5, Brightness.light, false),
      ('phone 2.0 dark', phone, 2.0, Brightness.dark, false),
      ('desktop 1.5', desktop, 1.5, Brightness.light, false),
      ('desktop 2.0 dark, animations off', desktop, 2.0, Brightness.dark, true),
    ]) {
      testWidgets('long Vietnamese names do not overflow ($label)', (
        tester,
      ) async {
        late _Setup s;
        await tester.runAsync(() async {
          final fx = await PlaylistFixture.open();
          final tracks = await fx.tracks(2);
          for (var i = 0; i < 2; i++) {
            fx.clock += 100;
            await fx.repo.createPlaylist(
              name:
                  'Những bản nhạc buồn nhất mọi thời đại để nghe vào đêm '
                  'mưa muộn $i',
              tracks: [tracks.first],
            );
          }
          s = _Setup(fx, tracks);
        });
        final c = await _content(
          tester,
          s,
          locale: 'vi',
          sourceLabel: 'Album Những bản nhạc buồn nhất mọi thời đại',
        );
        final opened = _Opened();
        await pumpOpener(
          tester,
          onOpen: _open(c, opened),
          size: size,
          locale: 'vi',
          textScale: scale,
          brightness: brightness,
          reduceMotion: reduce,
        );
        await openIt(tester);
        // A pending row with a long name and the badge.
        // At large text the header and footer leave a short list: scroll.
        await tester.ensureVisible(find.text(c.l10n.playlistPickerNew));
        await tester.pumpAndSettle();
        await tester.tap(find.text(c.l10n.playlistPickerNew));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).last,
          'Danh sách phát có cái tên rất dài để thử cắt chữ ' * 3,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(c.l10n.playlistPickerNewConfirm));
        await tester.pumpAndSettle();
        expect(c.pendingNames, hasLength(1));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
