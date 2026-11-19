import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../platform/state/document_picker_provider.dart';
import 'm3u_export_flow.dart';
import 'm3u_import_flow.dart';
import 'm3u_import_progress_card.dart';

/// Whether M3U import and export work: true where a document picker exists
/// (the same answer `documentPickerProvider` uses).
bool get m3uAvailable => documentPickerSupported;

/// Starts an M3U import (system file dialog, then toast or report).
Future<void> importM3u(BuildContext context) => runM3uImport(context);

/// Exports playlist [uid] as M3U ([relative] paths or absolute).
Future<void> exportM3u(
  BuildContext context,
  String uid, {
  required bool relative,
}) => runM3uExport(context, uid, relative: relative);

/// Progress of a running M3U import, the first sliver of the playlists list.
/// Draws nothing while no import has run for more than a second.
class M3uImportProgressSliver extends ConsumerWidget {
  const M3uImportProgressSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const SliverToBoxAdapter(child: M3uImportProgressCard());
}
