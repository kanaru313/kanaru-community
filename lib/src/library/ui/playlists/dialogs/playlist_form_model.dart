import 'package:material_ui/material_ui.dart';

import '../../../domain/playlists/playlist_text_rules.dart';
import '../../../state/playlists/playlist_editor.dart';

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

  /// True once the user chose "automatic cover" for the Edit form.
  final automaticCover = ValueNotifier<bool>(false);

  /// True while a save runs: the form's fields and buttons are disabled.
  final saving = ValueNotifier<bool>(false);

  String get cleanName => cleanPlaylistName(nameController.text);
  String get cleanDescription =>
      cleanPlaylistDescription(descriptionController.text);

  /// Cover change to hand to `PlaylistEditor.save`.
  PlaylistCoverEdit get cover => automaticCover.value
      ? const PlaylistCoverEdit.automatic()
      : const PlaylistCoverEdit.keep();

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
    automaticCover.dispose();
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
