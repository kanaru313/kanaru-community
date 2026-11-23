import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import 'picker_actions.dart';
import 'picker_controller.dart';
import 'picker_view.dart';
import 'picker_header.dart';
import 'picker_preview_page.dart';
import 'picker_results.dart';
import 'picker_search_bar.dart';

/// The picker on the touch shells: the search bar and the results as rows
/// with a `›`. Nothing is chosen here and there is no footer: a tap opens the
/// preview page over the list, which holds [Dùng lời này].
class PickerMobile extends ConsumerWidget {
  const PickerMobile({super.key, required this.trackId, required this.actions});

  final TrackId trackId;
  final PickerActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(pickerViewProvider(trackId));
    final controller = ref.read(pickerControllerProvider(trackId).notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PickerHeader(
          title: l10n.lyricsPickerTitle,
          backTooltip: l10n.lyricsPickerBack,
          onBack: actions.back,
          onClose: () => actions.close(),
        ),
        PickerSearchBar(trackId: trackId),
        Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
        Expanded(
          child: PickerResults(
            view: view,
            selected: null,
            onResult: (g, m) async {
              final picked = await showPickerPreviewPage(
                context,
                trackId: trackId,
                ref: m.candidate.ref,
                fallback: m.candidate,
                sourceName: g.source.name,
                songDuration: view.songDuration,
              );
              if (picked != null) actions.pick(picked);
            },
            onSearchOff: () => controller.searchDisabled(),
            closePicker: actions.close,
          ),
        ),
      ],
    );
  }
}
