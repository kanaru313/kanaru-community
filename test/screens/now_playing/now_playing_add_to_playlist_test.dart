import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/add_to_playlist/add_to_playlist.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:kanaru/src/playback/state/track_info_providers.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/desktop_now_playing_header.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_page.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../playback/support/ui_host.dart';
import '../../shell/support/desktop_now_playing_host.dart';
import '../../support/icon_button_finders.dart';
import 'support/add_to_playlist_support.dart';
import 'support/song_menu_pump.dart';

Future<UiHost> _openMobileSheet(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  addTearDown(resetAddToPlaylistGuard);
  final host = await pumpWithPlayer(
    tester,
    const Text('home'),
    overrides: overrides,
    routes: nowPlayingRoutes,
    size: const Size(390, 900),
  );
  host.router!.push('/now-playing');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await host.letStreamsArrive(tester);
  await tester.tap(byIconButton('More'));
  await menuLoads(tester);
  return host;
}

Future<DesktopHost> _openDesktop(
  WidgetTester tester, {
  bool play = true,
}) async {
  addTearDown(resetAddToPlaylistGuard);
  final host = await pumpDesktopShell(tester, play: play);
  host.container.read(nowPlayingPanelProvider.notifier).open();
  await tester.pump();
  await settleSlide(tester);
  return host;
}

final _header = find.byType(DesktopNowPlayingHeader);

Finder get _headerAdd =>
    find.descendant(of: _header, matching: byIconButton('Add to playlist'));

void main() {
  group('mobile song menu', () {
    testWidgets('the item opens the picker over Now Playing; cancel returns', (
      tester,
    ) async {
      final host = await _openMobileSheet(tester);
      await tester.tap(find.text('Add to playlist…'));
      await tester.pump();
      await waitForPicker(tester);

      expect(find.text('1 song · T0'), findsOneWidget);
      expect(pickerReachable(), isTrue);

      await cancelPicker(tester);
      expect(find.text('New playlist…'), findsNothing);
      expect(find.byType(NowPlayingPage), findsOneWidget);
      expect(
        host.router!.routerDelegate.currentConfiguration.last.matchedLocation,
        '/now-playing',
      );
    });

    testWidgets('adding shows the toast above the page and writes the row', (
      tester,
    ) async {
      final host = await _openMobileSheet(tester);
      final uid = await createPlaylist(tester, host, 'Chill');
      await tester.tap(find.text('Add to playlist…'));
      await tester.pump();
      await waitForPicker(tester);

      await tick(tester, 'Chill');
      await pressAdd(tester);
      await pumpUntil(tester, () => toast('Added 1 song to “Chill”'));

      expect(await heldTracks(tester, host, uid), [host.h.tracks[0].value]);
      await drainAfterAdd(tester);
    });

    testWidgets('a song that is not in the library opens no menu, only the '
        'toast', (tester) async {
      await _openMobileSheet(
        tester,
        overrides: [
          trackInfoProvider.overrideWith((ref, id) => Stream.value(null)),
        ],
      );
      expect(find.text('Add to playlist…'), findsNothing);
      expect(toast('This is no longer in your library.'), isTrue);
      await settle(tester);
      expect(find.text('New playlist…'), findsNothing);
    });
  });

  group('desktop', () {
    testWidgets('the header button opens the picker over Now Playing', (
      tester,
    ) async {
      await _openDesktop(tester);
      final button = tester.widget<KIconButton>(_headerAdd);
      expect(button.onPressed, isNotNull);

      await tester.tap(_headerAdd);
      await tester.pump();
      await waitForPicker(tester);
      expect(find.text('1 song · T0'), findsOneWidget);
      expect(pickerReachable(), isTrue);

      await cancelPicker(tester);
      expect(find.text('New playlist…'), findsNothing);
      expect(_header, findsOneWidget);
    });

    testWidgets('the ⋮ menu item opens the picker', (tester) async {
      await _openDesktop(tester);
      await tester.tap(
        find.descendant(of: _header, matching: find.byIcon(KIcons.moreVert)),
      );
      await menuLoads(tester);
      await tester.tap(find.text('Add to playlist…'));
      await tester.pump();
      await waitForPicker(tester);
      expect(find.text('1 song · T0'), findsOneWidget);

      await cancelPicker(tester);
      expect(_header, findsOneWidget);
    });

    testWidgets('without a current track the header button is off', (
      tester,
    ) async {
      await _openDesktop(tester, play: false);
      final button = tester.widget<KIconButton>(_headerAdd);
      expect(button.onPressed, isNull);
    });

    testWidgets('without a current track the ⋮ opens no menu, only the toast', (
      tester,
    ) async {
      await _openDesktop(tester, play: false);
      await tester.tap(
        find.descendant(of: _header, matching: find.byIcon(KIcons.moreVert)),
      );
      await menuLoads(tester);
      expect(find.text('Add to playlist…'), findsNothing);
      expect(toast('This is no longer in your library.'), isTrue);
      await settle(tester);
      expect(find.text('New playlist…'), findsNothing);
    });
  });
}
