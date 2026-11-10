// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;

i0.Trigger get customCoversPlaylistDelete => i0.Trigger(
  'CREATE TRIGGER custom_covers_playlist_delete AFTER DELETE ON playlists BEGIN DELETE FROM custom_covers WHERE kind = \'playlist\' AND item_key = old.uid;END',
  'custom_covers_playlist_delete',
);
i0.Trigger get customCoversPlaylistExistsInsert => i0.Trigger(
  'CREATE TRIGGER custom_covers_playlist_exists_insert BEFORE INSERT ON custom_covers WHEN new.kind = \'playlist\' AND NOT EXISTS (SELECT 1 FROM playlists WHERE uid = new.item_key) BEGIN SELECT RAISE (ABORT, \'custom_covers: no such playlist\');END',
  'custom_covers_playlist_exists_insert',
);
i0.Trigger get customCoversPlaylistExistsUpdate => i0.Trigger(
  'CREATE TRIGGER custom_covers_playlist_exists_update BEFORE UPDATE OF kind, item_key ON custom_covers WHEN new.kind = \'playlist\' AND NOT EXISTS (SELECT 1 FROM playlists WHERE uid = new.item_key) BEGIN SELECT RAISE (ABORT, \'custom_covers: no such playlist\');END',
  'custom_covers_playlist_exists_update',
);
