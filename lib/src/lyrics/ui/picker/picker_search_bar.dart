import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import 'picker_controller.dart';
import 'picker_view.dart';
import 'search_sources_sheet.dart';

/// The top of the picker: the search field, filled with "title artist" of the
/// song (Enter searches it; a newer search replaces the older one), and the
/// chip that shows which source is listed and opens "Nguồn tìm kiếm". On the
/// desktop the chip stands before the field; on the touch shells it has its
/// own row under it.
///
/// Starts the first search of the picker.
class PickerSearchBar extends ConsumerStatefulWidget {
  const PickerSearchBar({super.key, required this.trackId});

  final TrackId trackId;

  @override
  ConsumerState<PickerSearchBar> createState() => _PickerSearchBarState();
}

class _PickerSearchBarState extends ConsumerState<PickerSearchBar> {
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  Future<void> _boot() async {
    final text = await ref
        .read(pickerControllerProvider(widget.trackId).notifier)
        .boot();
    if (mounted && _text.text.isEmpty) _text.text = text;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit(String text) => unawaited(
    ref.read(pickerControllerProvider(widget.trackId).notifier).submit(text),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(pickerViewProvider(widget.trackId));
    final label = view.filter == null
        ? l10n.lyricsPickerFilterAll
        : view.groups.firstWhere((g) => g.source.id == view.filter).source.name;
    final field = KFilterField(
      controller: _text,
      hint: l10n.lyricsPickerSearchHint,
      closeTooltip: l10n.lyricsPickerClearSearch,
      persistent: true,
      autofocus: false,
      onClose: () {},
      onSubmitted: _submit,
    );
    final chip = KChip(
      onRaised: true,
      semanticLabel: label,
      onTap: () => showSearchSourcesSheet(context, widget.trackId),
      label: Row(
        children: [
          Expanded(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const KGap(KSpace.x1),
          const Icon(KIcons.collapse),
        ],
      ),
    );
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x4,
        KSpace.x1,
        KSpace.x4,
        KSpace.x2,
      ),
      child: desktop
          ? Row(
              spacing: KSpace.x2,
              children: [
                SizedBox(width: 170, child: chip),
                Expanded(child: field),
              ],
            )
          : Column(
              spacing: KSpace.x2,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [field, chip],
            ),
    );
  }
}
