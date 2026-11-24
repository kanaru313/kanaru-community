import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/lyrics_status.dart';
import '../../state/playing_lyrics_providers.dart';
import '../../state/translation/translation_commands.dart';
import '../../state/translation/translation_settings.dart';
import 'modal/translate_modal.dart';
import 'translate_entry_state.dart';
import 'translation_language_name.dart';

final _log = Logger('translate_toggle');

/// Opens "Dịch lời" for [id], the song that plays. The desktop header passes
/// its own opener that keeps the header shown while the modal is open.
typedef TranslateOpener = Future<void> Function(
  BuildContext context,
  TrackId id,
);

/// The default [TranslateOpener]: the modal follows the playing song.
Future<void> openTranslateModalForPlaying(BuildContext context, TrackId id) =>
    showTranslateModal(context, id, followsPlaying: true);

/// Turns translation on or off for every song (right-click on the desktop
/// pill, the `T` key) and says so in a snack bar: "Bản dịch: {ngôn ngữ}" or
/// "Đã tắt bản dịch". Does nothing when the playing song has no lyrics. A
/// refused write is logged and says nothing (the switch did not move).
Future<void> toggleTranslation(BuildContext context, WidgetRef ref) async {
  final playing = ref.read(playingLyricsProvider);
  if (playing.trackId == null || playing.lyrics is! LyricsShown) return;
  final l10n = AppLocalizations.of(context);
  final turningOn = !ref.read(translationOnProvider);
  try {
    await ref.read(translationCommandsProvider).toggle();
  } on Object catch (error, stack) {
    _log.warning('translation toggle failed', error, stack);
    return;
  }
  if (!context.mounted) return;
  final target = ref.read(translateEntryProvider).target;
  final message = turningOn && target != null
      ? l10n.lyricsTranslateToastOn(translationLanguageName(l10n, target))
      : l10n.lyricsTranslateToastOff;
  showAppSnackBar(context, message);
}

/// [toggleTranslation] for a callback slot that cannot await.
void toggleTranslationNow(BuildContext context, WidgetRef ref) =>
    unawaited(toggleTranslation(context, ref));
