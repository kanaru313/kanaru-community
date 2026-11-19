import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../domain/playlists/playlist_text_rules.dart';
import '../../../state/covers/cover_draft.dart';
import '../../../state/playlists/playlist_editor.dart';

/// The cover change a form has staged; nothing is written until Save.
sealed class FormCoverEdit {
  const FormCoverEdit();

  /// Leave the cover as it is.
  const factory FormCoverEdit.keep() = KeepFormCover;

  /// Drop the custom cover.
  const factory FormCoverEdit.automatic() = AutomaticFormCover;

  /// The image or cover the user picked in the dialog (form mode).
  const factory FormCoverEdit.choice(CoverDraft draft) = ChoiceFormCover;
}

class KeepFormCover extends FormCoverEdit {
  const KeepFormCover();
}

class AutomaticFormCover extends FormCoverEdit {
  const AutomaticFormCover();
}

class ChoiceFormCover extends FormCoverEdit {
  const ChoiceFormCover(this.draft);
  final CoverDraft draft;
}

/// What the Create, Duplicate and Edit forms edit: the name, the description
/// and a staged cover change, plus whether the whole form can be saved.
///
/// The cleaned values ([cleanName], [cleanDescription]) are the ones that are
/// validated, counted and saved. One owner creates it and calls [dispose]
/// when its widget leaves the tree.
class PlaylistFormModel {
  PlaylistFormModel({String name = '', String description = ''})
    : nameController = TextEditingController(text: name),
      descriptionController = TextEditingController(text: description) {
    // Opening with the whole name selected: typing replaces it.
    nameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: name.length,
    );
    valid = ValueNotifier(_isValid());
    nameController.addListener(_revalidate);
    descriptionController.addListener(_revalidate);
  }

  final TextEditingController nameController;
  final TextEditingController descriptionController;

  /// True while the name is acceptable and the description is not too long.
  late final ValueNotifier<bool> valid;

  /// The staged cover change of the Edit form.
  final coverEdit = ValueNotifier<FormCoverEdit>(const FormCoverEdit.keep());

  /// Stages [next]. The temp files of a staged draft that [next] replaces are
  /// deleted (kept when [next] is made from the same picked image).
  void stageCover(FormCoverEdit next) {
    final old = coverEdit.value;
    if (old is ChoiceFormCover) {
      unawaited(
        next is ChoiceFormCover
            ? old.draft.discardUnlessSharedWith(next.draft)
            : old.draft.discard(),
      );
    }
    coverEdit.value = next;
  }

  /// True when Save has a cover to write.
  bool get coverChanged => coverEdit.value is! KeepFormCover;

  /// True while a save runs: the form's fields and buttons are disabled.
  final saving = ValueNotifier<bool>(false);

  String get cleanName => cleanPlaylistName(nameController.text);
  String get cleanDescription =>
      cleanPlaylistDescription(descriptionController.text);

  /// Cover change to hand to `PlaylistEditor.save`.
  PlaylistCoverEdit get cover => switch (coverEdit.value) {
    KeepFormCover() => const PlaylistCoverEdit.keep(),
    AutomaticFormCover() => const PlaylistCoverEdit.automatic(),
    ChoiceFormCover(:final draft) =>
      draft.choice == null
          ? const PlaylistCoverEdit.keep()
          : PlaylistCoverEdit.choice(draft.choice!),
  };

  bool _isValid() =>
      checkPlaylistName(nameController.text) == null &&
      !isPlaylistDescriptionTooLong(descriptionController.text);

  void _revalidate() {
    final now = _isValid();
    if (valid.value != now) valid.value = now;
  }

  void dispose() {
    nameController
      ..removeListener(_revalidate)
      ..dispose();
    descriptionController
      ..removeListener(_revalidate)
      ..dispose();
    valid.dispose();
    // Cancel, close or after Save: the draft's temp files are no longer needed.
    final staged = coverEdit.value;
    if (staged is ChoiceFormCover) unawaited(staged.draft.discard());
    coverEdit.dispose();
    saving.dispose();
  }
}

/// Disposes [model] when this widget leaves the tree. For a form whose
/// model must exist before its route is built (a full-screen dialog reads the
/// validity for its action), so the route's own widget has to own the end of
/// its life: the push future completes before the exit animation ends.
class PlaylistFormOwner extends StatefulWidget {
  const PlaylistFormOwner({
    super.key,
    required this.model,
    required this.child,
  });

  final PlaylistFormModel model;
  final Widget child;

  @override
  State<PlaylistFormOwner> createState() => _PlaylistFormOwnerState();
}

class _PlaylistFormOwnerState extends State<PlaylistFormOwner> {
  @override
  void dispose() {
    widget.model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
