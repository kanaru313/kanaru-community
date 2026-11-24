import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/translation/translation_status.dart';
import '../../../state/translation/translation_commands.dart';
import '../../../state/translation/translation_credit_provider.dart';
import '../../../state/translation/translation_providers.dart';
import '../../../state/translation/translation_view.dart';
import 'translate_frame.dart';

/// How long a "Dịch lại" may take to show up as a running job before nobody
/// waits for it any more.
const Duration retranslateStartWait = Duration(seconds: 5);

/// "Dịch lại": the modal and its pages close at once, the old translation
/// stays on the lyrics, and a snack bar says when the new one is there. The
/// listener below also keeps the track's translation watched until then, so
/// the run is not dropped when the modal goes away.
void retranslateInBackground(
  BuildContext context,
  TranslateModalControl control,
) {
  final id = control.trackId;
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  var started = false;
  Timer? guard;
  late final ProviderSubscription<TranslationView> sub;
  void end() {
    guard?.cancel();
    sub.close();
  }

  sub = container.listen(trackTranslationProvider(id), (_, view) {
    final status = view.status;
    if (status is StatusLoading && status.background) {
      started = true;
      return;
    }
    if (!started) return;
    end();
    if (status is StatusReady) {
      final credit = container.read(translationCreditProvider(id));
      showAppSnackBarOn(
        messenger,
        l10n.lyricsTranslateRetranslated(credit?.style ?? credit?.plugin ?? ''),
      );
    }
  });
  guard = Timer(retranslateStartWait, () {
    if (!started) end();
  });
  container.read(translationCommandsProvider).retranslate(id);
  control.closeAll();
}
