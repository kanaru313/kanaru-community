import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/covers/cover_dialog_controller.dart';
import '../../state/covers/cover_draft.dart';
import '../../state/covers/cover_texts.dart';
import '../../state/custom_cover_providers.dart';
import 'cover_dialog_footer.dart';
import 'cover_dialog_head.dart';
import 'cover_hint_line.dart';
import 'cover_option_rows.dart';
import 'cover_preview_frame.dart';
import 'cover_small_image_card.dart';

/// The "Ảnh bìa" dialog (04d) for an album, artist or playlist.
///
/// Save mode ([formMode] false): Lưu writes the cover through a save job that
/// outlives this route and reports on [messenger]. Form mode: Chọn pops a
/// [CoverDraft] and writes nothing. [messenger] and [texts] are taken from the
/// root before the route opens, so they stay valid after it closes.
/// [fixedHeight] fills the sheet's height instead of fitting the content.
class CoverDialog extends ConsumerStatefulWidget {
  const CoverDialog({
    super.key,
    required this.kind,
    required this.itemKey,
    required this.messenger,
    required this.texts,
    required this.fixedHeight,
    this.formMode = false,
    this.draft,
  });

  final CustomCoverKind kind;
  final String itemKey;
  final ScaffoldMessengerState messenger;
  final CoverTexts texts;
  final bool fixedHeight;
  final bool formMode;
  final CoverDraft? draft;

  @override
  ConsumerState<CoverDialog> createState() => _CoverDialogState();
}

class _CoverDialogState extends ConsumerState<CoverDialog> {
  /// The messenger inside the dialog: errors raised while it is open show
  /// there, above the modal (the root messenger draws under it).
  final _inner = GlobalKey<ScaffoldMessengerState>();

  CoverDialogArgs get _args =>
      (kind: widget.kind, itemKey: widget.itemKey, draft: widget.draft);

  CoverDialogController get _ctl =>
      ref.read(coverDialogControllerProvider(_args).notifier);

  Future<void> _confirm() async {
    final navigator = Navigator.of(context);
    final ctl = _ctl;
    if (widget.formMode) {
      final draft = await ctl.toDraft();
      if (draft == null) return;
      if (mounted) {
        navigator.pop(draft);
      } else {
        // Closed meanwhile: nobody will hold the draft's temp files.
        await draft.discard();
      }
      return;
    }
    final saved = await ctl.save(
      messenger: widget.messenger,
      openMessenger: () => _inner.currentState,
      texts: widget.texts,
    );
    if (saved && mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = coverDialogControllerProvider(_args);
    final s = ref.watch(provider);
    ref.listen(provider.select((s) => s.error), (_, error) {
      if (error == null) return;
      showAppSnackBarOn(
        _inner.currentState ?? widget.messenger,
        widget.texts.errorFor(error.cause),
      );
      _ctl.clearError();
    });
    final ctl = _ctl;
    final picked = s.chosenPicked?.preview;
    final body = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const KGap(KSpace.x2),
          Center(
            child: CoverPreviewFrame(
              kind: widget.kind,
              itemKey: widget.itemKey,
              state: s,
              onOffset: ctl.setOffset,
              onDrop: ctl.drop,
            ),
          ),
          CoverHintLine(kind: widget.kind, state: s),
          if (picked != null &&
              (picked.width < smallCoverSide || picked.height < smallCoverSide))
            CoverSmallImageCard(width: picked.width, height: picked.height),
          const KGap(KSpace.x2),
          CoverOptionRows(
            kind: widget.kind,
            itemKey: widget.itemKey,
            state: s,
            onSelect: ctl.select,
            onPick: () => ctl.pick(dialogLabel: widget.texts.linuxDialogLabel),
          ),
          const KGap(KSpace.x2),
        ],
      ),
    );
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CoverDialogHead(itemName: s.options.value?.itemName ?? ''),
        if (widget.fixedHeight)
          Expanded(child: body)
        else
          Flexible(child: body),
        CoverDialogFooter(
          kind: widget.kind,
          formMode: widget.formMode,
          enabled: s.changed,
          saving: s.saving,
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: _confirm,
        ),
      ],
    );
    // The Scaffold is only a host for the snack bars: it sits over the
    // content, takes no pointer input and paints nothing.
    return ScaffoldMessenger(
      key: _inner,
      child: Stack(
        children: [
          column,
          const Positioned.fill(
            child: IgnorePointer(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
