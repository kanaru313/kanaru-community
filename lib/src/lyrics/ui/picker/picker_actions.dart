import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart' show VoidCallback;

import '../../../media/domain/track_id.dart';
import '../../data/online/online_lyrics_commands.dart';
import '../../data/online/store_result.dart';
import '../../domain/online/lyrics_candidate.dart';
import '../../state/online/online_commands_provider.dart';

final _log = Logger('lyrics_picker');

/// What "Dùng lời này" does with the chosen result (its lyrics already
/// fetched) and the name of the plugin it came from. The picker gives the
/// song's own use ([keepForTrack]); another screen that needs a lyrics
/// choice passes its own.
typedef PickerUse = Future<void> Function(
  LyricsCandidate result,
  String providerName,
);

/// The default use: keeps the result as the song's own copy, so the lyrics
/// show at once. The commands are taken now, while the picker is alive: it is
/// called after the picker has closed. A refused or failed write is logged and
/// reported through [onFailed]; the picker is gone by then.
PickerUse keepForTrack(
  WidgetRef ref,
  TrackId trackId, {
  required VoidCallback onFailed,
}) {
  final OnlineLyricsCommands commands = ref.read(onlineLyricsCommandsProvider);
  return (result, providerName) async {
    try {
      final stored = await commands.keep(
        trackId,
        result,
        providerName: providerName,
      );
      if (stored == StoreResult.notStored) {
        _log.warning('picked lyrics were not stored');
        onFailed();
      }
    } on Object catch (error, stack) {
      _log.warning('picked lyrics write failed', error, stack);
      onFailed();
    }
  };
}

/// A result chosen in the picker: the candidate with its lyrics, and its
/// plugin's name.
typedef PickedLyrics = ({LyricsCandidate candidate, String providerName});

/// What the two layouts of the picker call on its host.
class PickerActions {
  const PickerActions({
    required this.close,
    required this.back,
    required this.pick,
  });

  /// Closes the picker; false when it is already closing.
  final bool Function() close;

  /// ← , Back, Esc and Huỷ: back to "Lời cho bài này" (or just closes
  /// without a way back).
  final VoidCallback back;

  /// "Dùng lời này".
  final void Function(PickedLyrics picked) pick;
}

/// Runs [use] without waiting for it.
void runPickerUse(PickerUse use, PickedLyrics picked) =>
    unawaited(use(picked.candidate, picked.providerName));
