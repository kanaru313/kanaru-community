import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';

/// The snack bars of the lyrics choices: "Đã giữ bản NetEase cho bài này" and
/// the others on success, "Không lưu được lời" when the write was refused or
/// failed. Taken now, while [context] is alive: the picker and the modal close
/// before the write ends, so the messenger and the words are captured first.
/// Each does nothing when there is no messenger or it is gone by then.
class LyricsNotices {
  LyricsNotices._(this._messenger, this._l10n);

  /// The notices of the screen [context] stands in.
  factory LyricsNotices.of(BuildContext context) => LyricsNotices._(
    ScaffoldMessenger.maybeOf(context),
    AppLocalizations.of(context),
  );

  final ScaffoldMessengerState? _messenger;
  final AppLocalizations _l10n;

  void _say(String message) {
    final messenger = _messenger;
    if (messenger != null && messenger.mounted) {
      showAppSnackBarOn(messenger, message);
    }
  }

  /// The copy could not be saved.
  void failed() => _say(_l10n.lyricsKeepFailed);

  /// "Giữ bản này".
  void kept(String plugin) => _say(_l10n.lyricsToastKept(plugin));

  /// "Không đúng bài" on a copy found automatically.
  void refusedAuto() => _say(_l10n.lyricsToastRefusedAuto);

  /// "Không đúng bài" on the kept copy.
  void refusedKept() => _say(_l10n.lyricsToastRefusedKept);

  /// "Dùng lời này".
  void chosen(String plugin) => _say(_l10n.lyricsToastChosen(plugin));
}
