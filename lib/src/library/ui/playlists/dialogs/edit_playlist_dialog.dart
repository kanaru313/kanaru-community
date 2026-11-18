import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/playlists/playlist_models.dart';
import 'edit_playlist_cover.dart';
import 'edit_playlist_fields.dart';
import 'edit_playlist_save.dart';
import 'playlist_dialog_actions.dart';
import 'playlist_form_model.dart';

/// "Sửa playlist": name, description and cover of [summary]. A full-screen
/// dialog on the mobile shell, a 620 dp dialog (cover left, fields right) on
/// the desktop shell. Back, close, Esc and the scrim drop unsaved edits.
Future<void> showEditPlaylistDialog(
  BuildContext context,
  PlaylistSummary summary,
) {
  assert(!summary.isFavorites, 'Favorites cannot be edited');
  final container = ProviderScope.containerOf(context);
  // Captured before any await: the toast outlives the page that asked.
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final save = PlaylistEditSave(container, messenger, l10n, summary);
  if (FormFactor.of(context) == FormFactor.desktop) {
    return showKDialog<void>(
      context,
      maxWidth: KLayout.dialogWide,
      builder: (_) => _DesktopEditDialog(summary: summary, save: save),
    );
  }
  // Captured now: the caller's element may be gone when Save finishes.
  final navigator = Navigator.of(context, rootNavigator: true);
  ModalRoute<void>? dialogRoute;
  final form = PlaylistFormModel(
    name: summary.name,
    description: summary.description,
  );
  return showKFullScreenDialog<void>(
    context,
    title: l10n.playlistEditTitle,
    closeTooltip: l10n.playlistClose,
    actionLabel: l10n.playlistSave,
    actionEnabledListenable: form.valid,
    onAction: () async {
      // The dialog does not pop itself: close this dialog's own route (not
      // whatever is on top, e.g. a picker opened meanwhile) when the save says so.
      final route = dialogRoute;
      if (!await save.run(form) || route == null || !route.isActive) return;
      if (route.isCurrent) {
        navigator.pop();
      } else {
        navigator.removeRoute(route);
      }
    },
    body: (bodyContext) {
      dialogRoute = ModalRoute.of(bodyContext);
      return PlaylistFormOwner(
        model: form,
        child: _EditBody(summary: summary, form: form, coverSize: 120),
      );
    },
  );
}

/// Cover, name and description. The cover sits on top on mobile and on the
/// left on desktop ([wide]).
class _EditBody extends StatelessWidget {
  const _EditBody({
    required this.summary,
    required this.form,
    required this.coverSize,
    this.wide = false,
  });

  final PlaylistSummary summary;
  final PlaylistFormModel form;
  final double coverSize;
  final bool wide;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: form.saving,
    builder: (context, saving, _) => _layout(!saving),
  );

  Widget _layout(bool enabled) {
    final cover = PlaylistCoverEditor(
      summary: summary,
      automaticCover: form.automaticCover,
      dimension: coverSize,
      enabled: enabled,
    );
    final fields = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlaylistNameField(
          controller: form.nameController,
          autofocus: true,
          enabled: enabled,
          textInputAction: TextInputAction.next,
        ),
        const KGap(KSpace.x3),
        PlaylistDescriptionField(
          controller: form.descriptionController,
          enabled: enabled,
        ),
      ],
    );
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: coverSize, child: cover),
          const KGap(KSpace.x6),
          Expanded(child: fields),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.all(KSpace.x4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [cover, const KGap(KSpace.x5), fields],
      ),
    );
  }
}

class _DesktopEditDialog extends StatefulWidget {
  const _DesktopEditDialog({required this.summary, required this.save});

  final PlaylistSummary summary;
  final PlaylistEditSave save;

  @override
  State<_DesktopEditDialog> createState() => _DesktopEditDialogState();
}

class _DesktopEditDialogState extends State<_DesktopEditDialog> {
  late final PlaylistFormModel _form = PlaylistFormModel(
    name: widget.summary.name,
    description: widget.summary.description,
  );
  bool _busy = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.valid.value) return;
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    final close = await widget.save.run(_form);
    if (!mounted) return;
    setState(() => _busy = false);
    if (close) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        scrollable: true,
        title: Text(l10n.playlistEditTitle),
        // Full width: the dialog sizes to its content, which would otherwise
        // shrink to the text fields' intrinsic width.
        content: SizedBox(
          width: double.maxFinite,
          child: _EditBody(
            summary: widget.summary,
            form: _form,
            coverSize: 200,
            wide: true,
          ),
        ),
        actions: playlistDialogActions(
          context,
          confirmLabel: l10n.playlistSave,
          enabled: _form.valid,
          busy: _busy,
          onConfirm: () => unawaited(_save()),
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
