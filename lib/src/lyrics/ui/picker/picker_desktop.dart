import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/online/lyrics_candidate.dart';
import 'picker_actions.dart';
import 'picker_controller.dart';
import 'picker_view.dart';
import 'picker_header.dart';
import 'picker_preview.dart';
import 'picker_results.dart';
import 'picker_search_bar.dart';

/// The picker on the desktop shell: the results on the left (one is chosen,
/// the first at the start), its lyrics on the right, and a footer with
/// "Chỉ áp dụng cho bài này", [Huỷ] and [Dùng lời này]. The last is on only
/// while the chosen result's lyrics are there.
class PickerDesktop extends ConsumerWidget {
  const PickerDesktop({
    super.key,
    required this.trackId,
    required this.actions,
  });

  final TrackId trackId;
  final PickerActions actions;

  static const double _previewWidth = 330;
  static const double _maxHeight = 640;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(pickerViewProvider(trackId));
    final picker = ref.watch(pickerControllerProvider(trackId));
    final controller = ref.read(pickerControllerProvider(trackId).notifier);
    final scheme = Theme.of(context).colorScheme;
    final chosen = view.find(picker.selected) ?? view.first;
    final candidate = chosen?.match.candidate;
    final usable = candidate?.body?.isUsable ?? false;
    // 640 dp, or the room the window leaves the dialog when that is less
    // (the dialog's constraints cap the box).
    return SizedBox(
      height: _maxHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PickerHeader(
            title: l10n.lyricsPickerTitle,
            backTooltip: l10n.lyricsPickerBack,
            onBack: actions.back,
            onClose: () => actions.close(),
          ),
          PickerSearchBar(trackId: trackId),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: PickerResults(
                    view: view,
                    selected: candidate?.ref,
                    onResult: (g, m) => controller.select(m.candidate.ref),
                    onSearchOff: () => controller.searchDisabled(),
                    closePicker: actions.close,
                  ),
                ),
                VerticalDivider(width: 1, color: scheme.outlineVariant),
                SizedBox(
                  width: _previewWidth,
                  child: _Pane(
                    trackId: trackId,
                    sourceName: chosen?.group.source.name,
                    candidate: candidate,
                  ),
                ),
              ],
            ),
          ),
          PickerFooter(
            note: Text(l10n.lyricsPickerFootNote),
            buttons: [
              KModalButton(
                label: l10n.lyricsPickerCancel,
                emphasis: KModalEmphasis.text,
                onPressed: actions.back,
              ),
              KModalButton(
                label: l10n.lyricsPickerUse,
                onPressed: usable
                    ? () => actions.pick((
                        candidate: candidate!,
                        providerName: chosen!.group.source.name,
                      ))
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({
    required this.trackId,
    required this.sourceName,
    required this.candidate,
  });

  final TrackId trackId;
  final String? sourceName;
  final LyricsCandidate? candidate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final c = candidate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpace.x5,
            KSpace.x3,
            KSpace.x5,
            KSpace.x2,
          ),
          child: Text(
            sourceName == null
                ? l10n.lyricsPickerPreview
                : l10n.lyricsPickerPreviewFrom(sourceName!),
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: c == null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: KSpace.x5),
                  child: Text(
                    l10n.lyricsPickerPickOne,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: scheme.outline),
                  ),
                )
              : PickerPreview(
                  // A new result starts at its top, not where the last one
                  // was scrolled to.
                  key: ValueKey(c.ref),
                  trackId: trackId,
                  candidate: c,
                  compact: true,
                  padding: const EdgeInsets.fromLTRB(
                    KSpace.x5,
                    0,
                    KSpace.x5,
                    KSpace.x4,
                  ),
                ),
        ),
      ],
    );
  }
}
