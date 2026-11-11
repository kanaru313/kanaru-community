import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State of the desktop Now Playing panel. It lives with the playback state
/// (not in `shell/`) because the shell, the screens and the player bar all
/// open and close it.
class NowPlayingPanelState {
  const NowPlayingPanelState({this.open = false, this.covered = false});

  /// The panel is wanted open (it may still be animating in).
  final bool open;

  /// The panel fully covers the left region, so the region goes offstage.
  /// Only the overlay sets it, once it is fully open.
  final bool covered;

  NowPlayingPanelState copyWith({bool? open, bool? covered}) =>
      NowPlayingPanelState(
        open: open ?? this.open,
        covered: covered ?? this.covered,
      );

  @override
  bool operator ==(Object other) =>
      other is NowPlayingPanelState &&
      other.open == open &&
      other.covered == covered;

  @override
  int get hashCode => Object.hash(open, covered);
}

/// Opens and closes the desktop Now Playing panel.
class NowPlayingPanel extends Notifier<NowPlayingPanelState> {
  @override
  NowPlayingPanelState build() => const NowPlayingPanelState();

  void open() => state = state.copyWith(open: true);

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
