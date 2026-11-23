import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../history/history_page_frame.dart';

/// The page of a queue that is not (or no longer) there: a stale link, a
/// playlist id, a queue deleted or dropped while it was open.
class SavedQueueNotFound extends StatelessWidget {
  const SavedQueueNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return HistoryPageFrame(
      title: l10n.savedQueueNotFoundTitle,
      showBack: true,
      child: KEmpty(
        icon: KIcons.help,
        title: l10n.savedQueueNotFoundTitle,
        message: l10n.savedQueueNotFoundMessage,
      ),
    );
  }
}

/// The page waiting for its first answer, or one whose read failed.
class SavedQueuePending extends StatelessWidget {
  const SavedQueuePending({super.key, this.failed = false});

  final bool failed;

  @override
  Widget build(BuildContext context) => HistoryPageFrame(
    title: '',
    titleInContent: true,
    showBack: true,
    child: failed
        ? Center(
            child: Text(
              AppLocalizations.of(context).libraryLoadFailed,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          )
        : const SizedBox.shrink(),
  );
}
