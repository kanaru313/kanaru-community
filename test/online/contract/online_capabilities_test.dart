import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/online/domain/contract/online_capabilities.dart';

void main() {
  test('every optional script sets its flag', () {
    final c = OnlineCapabilities.fromScripts([
      'search',
      'stream',
      'autocomplete',
      'home',
      'genre',
      'album',
      'playlist',
      'artist',
      'related',
      'resolve',
    ]);
    expect([
      c.autocomplete,
      c.home,
      c.genre,
      c.album,
      c.playlist,
      c.artist,
      c.related,
      c.resolve,
    ], everyElement(isTrue));
  });

  test('search and stream alone offer nothing more', () {
    final c = OnlineCapabilities.fromScripts(['search', 'stream']);
    expect([
      c.autocomplete,
      c.home,
      c.genre,
      c.album,
      c.playlist,
      c.artist,
      c.related,
      c.resolve,
    ], everyElement(isFalse));
  });
}
