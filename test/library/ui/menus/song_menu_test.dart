import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/menus/menu_origin.dart';
import 'package:kanaru/src/library/ui/menus/song_menu.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import 'menu_fixtures.dart';

MenuSpec _menu({
  MenuOrigin origin = const MenuOrigin.list(),
  List<String> artists = const ['Miles'],
  List<String> albumArtists = const [],
  String? album = 'Blue',
  String folder = 'Blue',
  bool favorite = false,
  bool selected = false,
  bool canReveal = true,
  bool trash = false,
}) => buildSongMenu(
  SongMenuData(
    info: trackInfo(artists: artists, album: album),
    links: trackLinks(
      artists: artists,
      albumArtists: albumArtists,
      album: album,
      folder: folder,
    ),
    file: songFile,
    favorite: favorite,
    selected: selected,
  ),
  origin,
  env(canReveal: canReveal, trash: trash),
);

void main() {
  test('rows of a song in a list, and the queue ids captured', () {
    final spec = _menu();
    expect(rowIds(spec.groups), [
      MenuItemId.goAlbum,
      MenuItemId.goArtist,
      MenuItemId.goFolder,
      MenuItemId.playlist,
      MenuItemId.favorite,
      MenuItemId.edit,
      MenuItemId.select,
      MenuItemId.ai,
      MenuItemId.advanced,
    ]);
    expect(rowIds(spec.advanced), [
      MenuItemId.lyrics,
      MenuItemId.hide,
      MenuItemId.delete,
    ]);
    expect(spec.queueIds, [TrackId(1)]);
    expect(spec.header.title, 'So What');
    expect(spec.header.subtitle, 'Miles · Blue');
  });

  test('rows that are not built are dimmed with the coming-soon label', () {
    final spec = _menu();
    for (final id in [
      MenuItemId.playlist,
      MenuItemId.edit,
      MenuItemId.ai,
      MenuItemId.lyrics,
      MenuItemId.hide,
      MenuItemId.delete,
    ]) {
      expect(rowOf(spec, id).soon, isTrue, reason: '$id');
      expect(rowOf(spec, id).active, isFalse);
    }
    expect(rowOf(spec, MenuItemId.ai).pro, isTrue);
    expect(rowOf(spec, MenuItemId.delete).danger, isTrue);
    expect(rowOf(spec, MenuItemId.favorite).active, isTrue);
    expect(rowOf(spec, MenuItemId.select).active, isTrue);
  });

  test('the delete row says Trash on desktop', () {
    expect(rowOf(_menu(), MenuItemId.delete).title, 'Delete files from device');
    expect(
      rowOf(_menu(trash: true), MenuItemId.delete).title,
      'Move files to Trash',
    );
  });

  test('favorite and select rows flip with the state', () {
    final on = _menu(favorite: true, selected: true);
    expect(
      rowOf(on, MenuItemId.favorite).action,
      MenuAction.favorite([TrackId(1)], on: false),
    );
    expect(rowOf(on, MenuItemId.favorite).title, 'Remove from favorites');
    expect(
      rowOf(on, MenuItemId.select).action,
      MenuAction.select(TrackId(1), on: false),
    );
    expect(rowOf(on, MenuItemId.select).title, 'Deselect');
    final off = _menu();
    expect(
      rowOf(off, MenuItemId.favorite).action,
      MenuAction.favorite([TrackId(1)], on: true),
    );
    expect(
      rowOf(off, MenuItemId.select).action,
      MenuAction.select(TrackId(1), on: true),
    );
  });

  test('no album: a dimmed "no album" row', () {
    final row = rowOf(_menu(album: null), MenuItemId.goAlbum);
    expect(row.enabled, isFalse);
    expect(row.subtitle, 'No album');
  });

  test('artists are chips: open under 4, folded from 4, never a page', () {
    final two = rowOf(_menu(artists: ['A', 'B']), MenuItemId.goArtist);
    expect(two.chips.map((c) => c.label), ['A', 'B']);
    expect(two.chipsOpen, isTrue);
    final four = _menu(artists: ['A', 'B', 'C', 'D']);
    final row = rowOf(four, MenuItemId.goArtist);
    expect(row.chips, hasLength(4));
    expect(row.chipsOpen, isFalse);
    expect(four.pages, isEmpty);
    expect(row.subtitle, '4 artists');
  });

  test(
    'album artist row only when the album artists are not all in the song',
    () {
      expect(hasRow(_menu(), MenuItemId.goAlbumArtist), isFalse);
      final spec = _menu(albumArtists: ['Various']);
      final row = rowOf(spec, MenuItemId.goAlbumArtist);
      expect(row.subtitle, 'Various');
      expect(row.action, isA<GoAction>());
    },
  );

  test('song info page is attached and opened by the header', () {
    const page = MenuPageSpec(title: 'Song info', groups: []);
    final spec = buildSongMenu(
      SongMenuData(
        info: trackInfo(),
        links: trackLinks(),
        file: songFile,
        favorite: false,
        selected: false,
      ),
      const MenuOrigin.list(),
      env(),
      infoPage: page,
    );
    expect(spec.header.infoPage, infoPageKey);
    expect(spec.pages[infoPageKey], same(page));
    expect(_menu().header.infoPage, isNull);
  });

  group('origin', () {
    test('album page: no "Go to album"', () {
      final spec = _menu(origin: MenuOrigin.album(albumKeyOf('Blue', 'Miles')));
      expect(hasRow(spec, MenuItemId.goAlbum), isFalse);
      expect(hasRow(spec, MenuItemId.goArtist), isTrue);
    });

    test('another album page keeps the link', () {
      final spec = _menu(
        origin: MenuOrigin.album(albumKeyOf('Other', 'Miles')),
      );
      expect(hasRow(spec, MenuItemId.goAlbum), isTrue);
    });

    test('folder page of the song folder: reveal replaces "Go to folder"', () {
      final spec = _menu(origin: const MenuOrigin.folder(1, 'Blue'));
      expect(hasRow(spec, MenuItemId.goFolder), isFalse);
      final row = rowOf(spec, MenuItemId.reveal);
      expect(row.action, const MenuAction.reveal('/home/u/Music/Blue/1.flac'));
      expect(row.active, isTrue);
    });

    test('folder page above the song folder keeps "Go to folder"', () {
      final spec = _menu(origin: const MenuOrigin.folder(1, ''));
      expect(hasRow(spec, MenuItemId.goFolder), isTrue);
      expect(hasRow(spec, MenuItemId.reveal), isFalse);
    });

    test('reveal is dimmed where the file manager is not available', () {
      final spec = _menu(
        origin: const MenuOrigin.folder(1, 'Blue'),
        canReveal: false,
      );
      expect(rowOf(spec, MenuItemId.reveal).soon, isTrue);
    });

    test('artist page: its artist is not a chip; the row goes when alone', () {
      final page = MenuOrigin.artist(ArtistKey(groupKey('Miles')));
      final alone = _menu(origin: page);
      expect(hasRow(alone, MenuItemId.goArtist), isFalse);
      final duo = _menu(origin: page, artists: ['Miles', 'Coltrane']);
      final row = rowOf(duo, MenuItemId.goArtist);
      // One target left: a plain row, not chips.
      expect(row.subtitle, 'Coltrane');
      expect(row.chips, isEmpty);
      final trio = _menu(origin: page, artists: ['Miles', 'A', 'B']);
      expect(rowOf(trio, MenuItemId.goArtist).chips.map((c) => c.label), [
        'A',
        'B',
      ]);
    });

    test('artist page also leaves its artist out of the album artists', () {
      final page = MenuOrigin.artist(ArtistKey(groupKey('Various')));
      final spec = _menu(origin: page, albumArtists: ['Various']);
      expect(hasRow(spec, MenuItemId.goAlbumArtist), isFalse);
    });

    test('a menu never links to the page it was opened from', () {
      final miles = ArtistKey(groupKey('Miles'));
      final blue = albumKeyOf('Blue', 'Miles');
      final cases = <MenuOrigin, String>{
        MenuOrigin.album(blue): LibraryLocations.album(blue),
        MenuOrigin.artist(miles): LibraryLocations.artist(miles),
      };
      cases.forEach((origin, self) {
        final spec = _menu(
          origin: origin,
          artists: ['Miles', 'Coltrane'],
          albumArtists: ['Miles'],
        );
        expect(goLocations(spec), isNot(contains(self)), reason: '$origin');
      });
    });
  });
}
