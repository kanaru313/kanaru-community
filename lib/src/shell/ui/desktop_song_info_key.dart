import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:material_ui/material_ui.dart';

import '../../library/ui/info/open_song_info.dart';
import '../../library/state/browse/selection_providers.dart';
import '../../media/domain/track_id.dart';
import '../../playback/state/now_playing_panel.dart';
import '../../playback/state/playback_providers.dart';
import '../../playback/state/track_info_providers.dart';

/// Whether [event] is a fresh Alt+Enter press (no other modifier, no repeat).
bool isSongInfoKey(KeyEvent event) {
  if (event is! KeyDownEvent) return false;
  if (event.logicalKey != LogicalKeyboardKey.enter) return false;
  final k = HardwareKeyboard.instance;
  return k.isAltPressed &&
      !k.isControlPressed &&
      !k.isShiftPressed &&
      !k.isMetaPressed;
}

/// The song Alt+Enter acts on when no row or card has the focus: the single
/// selected song, else the playing one (two or more selected: the playing
/// one). While the desktop Now Playing layer is open the playing song is the
/// target whatever is selected underneath. Null when there is none.
TrackId? songInfoKeyTarget(T Function<T>(ProviderListenable<T> provider) read) {
  final selection = read(librarySelectionProvider);
  if (!read(nowPlayingPanelProvider).open && selection.ids.length == 1) {
    return selection.ids.first;
  }
  return read(nowPlayingProvider).value?.trackId;
}

/// Longest wait for the song's row before the key gives up.
const songInfoLookupTimeout = Duration(seconds: 3);

/// Opens the info of [songInfoKeyTarget] for Alt+Enter. One per shell: it
/// remembers a lookup in flight so a quick second press opens nothing more.
class SongInfoKey {
  bool _busy = false;

  /// Returns true when the key was taken (a song exists); the route opens once
  /// its row is read. The caller has already checked that no modal is on top
  /// and no text field has the focus.
  bool open(BuildContext context, WidgetRef ref) {
    final id = songInfoKeyTarget(ref.read);
    if (id == null) return false;
    if (_busy) return true;
    _busy = true;
    unawaited(_open(context, ref, id));
    return true;
  }

  Future<void> _open(BuildContext context, WidgetRef ref, TrackId id) async {
    ProviderSubscription<Object?>? hold;
    try {
      // The provider auto-disposes: hold it until the first value is read.
      hold = ref.listenManual(trackInfoProvider(id), (_, _) {});
      final info = await ref
          .read(trackInfoProvider(id).future)
          .timeout(songInfoLookupTimeout);
      // Looked up: the route guard of openSongInfo takes over from here.
      _busy = false;
      hold.close();
      hold = null;
      if (info == null || !context.mounted) return;
      await openSongInfo(context, info, viaKeyboard: true);
    } on TimeoutException {
      // The row never came: give up quietly, the next press tries again.
    } on Object catch (e, s) {
      // A failed lookup leaves the key without effect; report it, never crash
      // the key handler.
      FlutterError.reportError(
        FlutterErrorDetails(exception: e, stack: s, library: 'song info key'),
      );
    } finally {
      hold?.close();
      _busy = false;
    }
  }
}
