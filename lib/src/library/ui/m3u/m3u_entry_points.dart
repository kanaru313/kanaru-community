import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Whether M3U import and export work. Entry points stay dimmed while false.
bool get m3uAvailable => false;

/// Starts an M3U import. Placeholder until the import flow replaces the body.
Future<void> importM3u(BuildContext context) async {
  showAppSnackBar(context, AppLocalizations.of(context).appComingSoon);
}

/// Exports playlist [uid] as M3U ([relative] paths or absolute). Placeholder
/// until the export flow replaces the body.
Future<void> exportM3u(
  BuildContext context,
  String uid, {
  required bool relative,
}) async {
  showAppSnackBar(context, AppLocalizations.of(context).appComingSoon);
}

/// Progress of a running M3U import, the first sliver of the playlists list.
/// Draws nothing until the import flow fills it.
class M3uImportProgressSliver extends ConsumerWidget {
  const M3uImportProgressSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const SliverToBoxAdapter(child: SizedBox.shrink());
}
