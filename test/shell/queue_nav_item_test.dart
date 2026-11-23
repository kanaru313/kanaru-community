import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/library/library_extension.dart';
import 'package:kanaru/src/screens/now_playing/now_playing_registration.dart';

void main() {
  // The saved queues are a page of the Playlist tab: the library registers
  // the item, Now Playing does not. The live queue is the right panel (desktop)
  // and the sheet from the mini player (mobile).
  test('the Queue nav item is live, a sidebar child of Playlists', () {
    final r = ExtensionRegistry()..install(const [LibraryExtension()]);
    final item = r.navItems.singleWhere((n) => n.id == 'queue');
    expect(item.comingSoon, isFalse);
    expect(item.path, '/playlists/queues');
    expect(item.parentId, 'playlists');
    expect(item.order, 230);
    expect(item.mobileTab, isFalse);
  });

  test('Now Playing registers no Queue item', () {
    final r = ExtensionRegistry();
    registerNowPlaying(r);
    expect(r.navItems.where((n) => n.id == 'queue'), isEmpty);
  });
}
