import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/ui/transport_buttons.dart';
import 'package:kanaru/src/playback/ui/volume_control.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/desktop_now_playing_header.dart';
import 'package:kanaru/src/screens/now_playing/ui/favorite_button.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shell/support/desktop_now_playing_host.dart';

Future<DesktopHost> _open(WidgetTester tester) async {
  final host = await pumpDesktopShell(tester);
  host.container.read(nowPlayingPanelProvider.notifier).open();
  await tester.pump();
  await settleSlide(tester);
  return host;
}

double _x(WidgetTester tester, Finder f) => tester.getCenter(f.first).dx;

Finder _in(Finder inside, Finder f) => find.descendant(of: inside, matching: f);

void main() {
  final header = find.byType(DesktopNowPlayingHeader);

  testWidgets(
    'left group: close, cover column, favourite, playlist, translate',
    (tester) async {
      await _open(tester);
      final xs = [
        _x(tester, _in(header, find.byIcon(KIcons.collapse))),
        _x(tester, _in(header, find.byIcon(KIcons.sidebarCover))),
        _x(tester, _in(header, find.byType(FavoriteButton))),
        _x(tester, _in(header, find.byIcon(KIcons.playlistAdd))),
        _x(tester, _in(header, find.text('Translate'))),
      ];
      expect(xs, [...xs]..sort());
    },
  );

  testWidgets('right group: repeat, sleep timer, volume, more', (tester) async {
    await _open(tester);
    final xs = [
      _x(tester, _in(header, find.byType(RepeatButton))),
      _x(tester, _in(header, find.byIcon(KIcons.sleepTimer))),
      _x(tester, _in(header, find.byType(VolumeControl))),
      _x(tester, _in(header, find.byIcon(KIcons.moreVert))),
    ];
    expect(xs, [...xs]..sort());
    // The right group sits right of the left one.
    expect(
      xs.first,
      greaterThan(_x(tester, _in(header, find.text('Translate')))),
    );
  });

  testWidgets('there is no Shuffle in the header', (tester) async {
    await _open(tester);
    expect(_in(header, find.byType(ShuffleButton)), findsNothing);
    expect(_in(header, find.byIcon(KIcons.shuffle)), findsNothing);
  });

  testWidgets('unbuilt items are dimmed and inert', (tester) async {
    await _open(tester);
    for (final tip in [
      'Add to playlist · Coming soon',
      'Sleep timer · Coming soon',
    ]) {
      final button = tester.widget<IconButton>(
        find
            .ancestor(
              of: find.byTooltip(tip),
              matching: find.byType(IconButton),
            )
            .first,
      );
      expect(button.onPressed, isNull, reason: tip);
    }
    final chip = find.ancestor(
      of: find.text('Translate'),
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(chip.first).opacity, lessThan(1));
    expect(find.byTooltip('Translate · Coming soon'), findsOneWidget);
  });

  testWidgets('the header is 64 dp tall', (tester) async {
    await _open(tester);
    expect(tester.getSize(header).height, 64);
  });

  testWidgets('the More menu has the track head and both item groups', (
    tester,
  ) async {
    await _open(tester);
    await tester.tap(_in(header, find.byIcon(KIcons.moreVert)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    for (final label in [
      'Sleep timer',
      'Add to playlist',
      'Go to album',
      'Go to artist',
      'Lyrics source',
      'Translate lyrics…',
      'Visual effects',
      'Track info',
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.byType(ProBadge), findsOneWidget);
    // The head row: the playing track.
    expect(find.text('T0'), findsWidgets);
  });

  testWidgets('the cover-column button reflects and flips the view', (
    tester,
  ) async {
    await _open(tester);
    expect(find.byKey(const ValueKey('split')), findsOneWidget);
    await tester.tap(_in(header, find.byIcon(KIcons.sidebarCover)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('split')), findsNothing);
    expect(find.byKey(const ValueKey('pane only')), findsOneWidget);
  });

  testWidgets('the heart is 16 dp after the cover-column button', (
    tester,
  ) async {
    await _open(tester);
    final toggle = tester.getTopRight(
      _in(
        header,
        find.ancestor(
          of: find.byIcon(KIcons.sidebarCover),
          matching: find.byType(IconButton),
        ),
      ),
    );
    final heart = tester.getTopLeft(_in(header, find.byType(FavoriteButton)));
    expect(heart.dx - toggle.dx, 16);
  });
}
