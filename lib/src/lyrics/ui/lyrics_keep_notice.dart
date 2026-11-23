import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';

/// A way to tell the user that lyrics could not be saved ("Không lưu được
/// lời"), taken now, while [context] is alive: the picker and the modal close
/// before the write ends, so the messenger and the words are captured first.
/// The notice is the app's shared snack bar; it does nothing when there is no
/// messenger or it is gone by then.
VoidCallback keepFailedNoticeOf(BuildContext context) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final message = AppLocalizations.of(context).lyricsKeepFailed;
  return () {
    if (messenger != null && messenger.mounted) {
      showAppSnackBarOn(messenger, message);
    }
  };
}
