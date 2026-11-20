import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';

/// Plays of one song, opened from History.
class TrackHistoryPage extends StatelessWidget {
  const TrackHistoryPage({super.key, required this.trackId});

  final int trackId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KEmptyPage(
      title: l10n.historyTitle,
      icon: KIcons.history,
      message: l10n.appComingSoon,
    );
  }
}
