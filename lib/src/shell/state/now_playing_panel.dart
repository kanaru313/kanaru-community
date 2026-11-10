import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../playback/domain/playback_settings.dart';
import '../../playback/state/playback_settings_providers.dart';

/// State of the desktop Now Playing panel.
class NowPlayingPanelState {
  const NowPlayingPanelState({
    this.open = false,
    this.tab = NowPlayingTab.lyrics,
    this.covered = false,
  });

  /// The panel is wanted open (it may still be animating in).
  final bool open;
  final NowPlayingTab tab;

  /// The panel fully covers the left region, so the region goes offstage.
  /// Only the overlay sets it, once it is fully open.
  final bool covered;

  NowPlayingPanelState copyWith({
    bool? open,
    NowPlayingTab? tab,
    bool? covered,
  }) => NowPlayingPanelState(
    open: open ?? this.open,
    tab: tab ?? this.tab,
    covered: covered ?? this.covered,
  );

  @override
  bool operator ==(Object other) =>
      other is NowPlayingPanelState &&
      other.open == open &&
      other.tab == tab &&
      other.covered == covered;

  @override
  int get hashCode => Object.hash(open, tab, covered);
}

/// Opens and closes the desktop Now Playing panel. The last tab is remembered
/// in `playback.np_tab`.
class NowPlayingPanel extends Notifier<NowPlayingPanelState> {
  @override
  NowPlayingPanelState build() =>
      NowPlayingPanelState(tab: ref.read(npTabSettingProvider));

  void open(NowPlayingTab tab) {
    state = state.copyWith(open: true, tab: tab);
    ref.read(npTabSettingProvider.notifier).set(tab);
  }

  /// Opens at the tab used last (lyrics by default).
  void openLast() => open(ref.read(npTabSettingProvider));

  /// Closes the panel; it no longer covers anything.
  void close() => state = state.copyWith(open: false, covered: false);

  void setCovered(bool covered) {
    if (state.covered == covered) return;
    state = state.copyWith(covered: covered);
  }
}

final nowPlayingPanelProvider =
    NotifierProvider<NowPlayingPanel, NowPlayingPanelState>(
      NowPlayingPanel.new,
    );
