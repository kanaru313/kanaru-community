import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/saved_queues/saved_queue_menu.dart';

import '../menus/menu_fixtures.dart' show hasRow, rowIds, rowOf;
import 'support/fake_saved_queue_store.dart';

final _en = AppLocalizationsEn();
final _saved = DateTime(2026, 11, 21, 21, 17).millisecondsSinceEpoch;
final _today = DateTime(2026, 11, 21);

MenuSpec _menu({
  List<int> ids = const [1, 2, 3, 4],
  Set<int> missing = const {},
}) => buildSavedQueueMenu(
  savedQueue('a', savedAt: _saved, ids: ids, missing: missing),
  _en,
  today: _today,
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  test('eight rows in the drawn order, the last one apart', () {
    final spec = _menu(missing: {4});
    expect(spec.groups, hasLength(2));
    expect(rowIds([spec.groups.first]), [
      MenuItemId.play,
      MenuItemId.shuffle,
      MenuItemId.queueAppend,
      MenuItemId.playlist,
      MenuItemId.playlistFavoriteAll,
      MenuItemId.playlistExportM3u,
      MenuItemId.playlistRemoveMissing,
    ]);
    expect(rowIds([spec.groups.last]), [MenuItemId.playlistDelete]);
  });

  test('"remove missing" only when a song is gone', () {
    expect(hasRow(_menu(), MenuItemId.playlistRemoveMissing), isFalse);
    expect(
      hasRow(_menu(missing: {2}), MenuItemId.playlistRemoveMissing),
      isTrue,
    );
  });

  test('the delete row is destructive, the others are not', () {
    final spec = _menu(missing: {1});
    expect(rowOf(spec, MenuItemId.playlistDelete).danger, isTrue);
    expect(
      [
        for (final g in spec.groups)
          for (final i in g)
            if (i.danger) i.id,
      ],
      [MenuItemId.playlistDelete],
    );
  });

  test('the head is the queue: its name and counts', () {
    final spec = _menu(ids: [1, 2, 3], missing: {3});
    expect(spec.header.title, 'Today · 21:17');
    expect(spec.header.subtitle, '3 songs · 3 min · 1 song gone');
    expect(spec.header.image, MenuImage.playlist);
    expect(spec.header.itemKey, 'a');
  });

  test('titles follow the spec', () {
    final spec = _menu();
    expect(rowOf(spec, MenuItemId.play).title, _en.savedQueueMenuPlay);
    expect(rowOf(spec, MenuItemId.queueAppend).title, _en.savedQueueMenuAppend);
    expect(
      rowOf(spec, MenuItemId.playlist).title,
      _en.savedQueueMenuSaveAsPlaylist,
    );
  });

  test('rows that need a song are dim when none can play now', () {
    final spec = _menu(ids: [1, 2], missing: {1, 2});
    for (final id in [
      MenuItemId.play,
      MenuItemId.shuffle,
      MenuItemId.queueAppend,
      MenuItemId.playlist,
      MenuItemId.playlistFavoriteAll,
    ]) {
      expect(rowOf(spec, id).enabled, isFalse, reason: '$id');
    }
    // The export keeps the old paths of the missing songs: it still works.
    expect(rowOf(spec, MenuItemId.playlistExportM3u).enabled, isTrue);
    expect(rowOf(spec, MenuItemId.playlistDelete).enabled, isTrue);
  });

  test('a queue with no entry cannot be exported', () {
    final spec = _menu(ids: const []);
    expect(rowOf(spec, MenuItemId.playlistExportM3u).enabled, isFalse);
  });

  test('a playlist is not a saved queue', () {
    final playlist = savedQueue('p', savedAt: 0, ids: [1]);
    final plain = playlist.copyWithoutSavedQueue();
    expect(
      () => buildSavedQueueMenu(plain, _en, today: _today),
      throwsArgumentError,
    );
  });
}
