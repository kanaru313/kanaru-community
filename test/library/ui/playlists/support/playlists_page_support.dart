import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/extension/state/registry_entries.dart';
import 'package:kanaru/src/library/ui/playlists/playlists_page.dart';
import 'package:kanaru/src/platform/domain/settings_store.dart';
import 'package:kanaru/src/platform/state/file_manager_provider.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../support/fake_playback_commands.dart';
import 'playlist_menu_support.dart';
import 'playlist_ui_harness.dart';

/// Navigation items the hub reads: History and Most played (soon unless
/// [historySoon] is false) and the live Queue.
ExtensionRegistry hubRegistry({bool historySoon = true}) => ExtensionRegistry()
  ..addNavItem(
    NavItem(
      id: 'history',
      path: '/playlists/history',
      icon: KIcons.history,
      selectedIcon: KIcons.history,
      label: (_) => 'History',
      order: 240,
      mobileTab: false,
      comingSoon: historySoon,
    ),
  )
  ..addNavItem(
    NavItem(
      id: 'most_played',
      path: '/playlists/most-played',
      icon: KIcons.mostPlayed,
      selectedIcon: KIcons.mostPlayed,
      label: (_) => 'Most played',
      order: 250,
      mobileTab: false,
      comingSoon: true,
    ),
  )
  ..addNavItem(
    NavItem(
      id: 'queue',
      path: '/playlists/queues',
      icon: KIcons.queue,
      selectedIcon: KIcons.queue,
      label: (_) => 'Queue',
      order: 230,
      mobileTab: false,
    ),
  );

final List<ProviderContainer> _containers = [];

/// [uiTest] for the page: the tree goes and the containers are disposed
/// before the final drain, so the throttled list queries leave no timer.
void pageTest(String description, Future<void> Function(WidgetTester t) body) =>
    testWidgets(description, (t) async {
      _containers.clear();
      await body(t);
      await t.pumpWidget(const SizedBox());
      for (final c in _containers) {
        c.dispose();
      }
      await drain(t);
    });

/// Lets database answers (real time) arrive and routes / popovers animate.
Future<void> settlePage(WidgetTester t) async {
  for (var i = 0; i < 4; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await t.pump(const Duration(milliseconds: 600));
  }
  await t.pumpAndSettle();
}

/// Pumps the real [PlaylistsPage] above a host route, over the real
/// repository. [playback] records what ▶ plays.
Future<PlaylistUiHarness> pumpPlaylistsPage(
  WidgetTester t, {
  double width = 400,
  double textScale = 1,
  bool disableAnimations = false,
  FakePlaybackCommands? playback,
  SettingsStore? settings,
  ExtensionRegistry? registry,
  bool asRoot = false,
  Widget Function(Widget page)? wrap,
}) async {
  final h = await PlaylistUiHarness.pump(
    t,
    width: width,
    textScale: textScale,
    disableAnimations: disableAnimations,
    settings: settings,
    listBuilder: (_) =>
        wrap == null ? const PlaylistsPage() : wrap(const PlaylistsPage()),
    overrides: [
      extensionRegistryProvider.overrideWithValue(registry ?? hubRegistry()),
      fileManagerProvider.overrideWithValue(NoFileManager()),
      playbackCommandsProvider.overrideWithValue(
        playback ?? FakePlaybackCommands(),
      ),
    ],
  );
  _containers.add(h.container);
  // [asRoot]: the page is the only route (the app's real shape), so a pushed
  // route above it is always a modal. Otherwise it sits above a host route.
  if (asRoot) {
    h.router.go('/playlists');
  } else {
    unawaited(h.router.push<void>('/playlists'));
  }
  await settlePage(t);
  return h;
}

/// Seeds playlists in order, one second apart on the fixture clock, so
/// "date modified" differs and the last one is the newest.
Future<void> seedPlaylists(
  WidgetTester t,
  PlaylistUiHarness h,
  List<String> names,
) async {
  for (final name in names) {
    h.fixture.clock += 1000;
    await seedPlaylist(t, h, name: name, trackCount: 1);
  }
  // The list refreshes after a cooldown: wait until the page shows the last.
  await eventually(
    t,
    () => find.text(names.last).evaluate().isNotEmpty,
    what: 'the seeded playlists on the page',
  );
  await settlePage(t);
}

/// [names] in reading order on screen (row by row, left to right).
List<String> onScreenOrder(WidgetTester t, List<String> names) {
  final shown = [
    for (final n in names)
      if (find.text(n).evaluate().isNotEmpty) n,
  ];
  shown.sort((a, b) {
    final pa = t.getTopLeft(find.text(a).first);
    final pb = t.getTopLeft(find.text(b).first);
    return pa.dy == pb.dy ? pa.dx.compareTo(pb.dx) : pa.dy.compareTo(pb.dy);
  });
  return shown;
}

AppLocalizations pageL10n(WidgetTester t) =>
    AppLocalizations.of(t.element(find.byType(PlaylistsPage)));

/// Ctrl+N (with Shift when [shift]) pressed and released.
Future<void> pressCtrlN(WidgetTester t, {bool shift = false}) async {
  await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await t.sendKeyEvent(LogicalKeyboardKey.keyN);
  if (shift) await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await t.pump();
}
