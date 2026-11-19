import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/m3u/m3u_import_progress.dart';
import '../browse/library_list_scaffold.dart';

/// "Importing FILE · N / M lines" with a bar, while an M3U import has run
/// for more than a second. Draws nothing otherwise. Margins follow the
/// mockup: 4 above, the page gutter at the sides, 8 below.
class M3uImportProgressCard extends ConsumerWidget {
  const M3uImportProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(m3uImportProgressProvider);
    if (view == null || !view.visible) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final total = view.total;
    final gutter = libraryGutter(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, KSpace.x1, gutter, KSpace.x2),
      child: ProgressNoticeCard(
        icon: KIcons.fileImport,
        title: Text(l10n.m3uImportProgressTitle(view.fileName)),
        subtitle: total == null
            ? null
            : Text(l10n.m3uImportProgressLines(view.done, total)),
        progress: total == null || total == 0 ? null : view.done / total,
      ),
    );
  }
}
