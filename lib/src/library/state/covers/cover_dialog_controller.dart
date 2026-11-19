import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../platform/domain/image_file_picker.dart';
import '../../../platform/state/image_file_picker_provider.dart';
import '../custom_cover_providers.dart';
import 'cover_choice_resolver.dart';
import 'cover_dialog_opening.dart';
import 'cover_dialog_options.dart';
import 'cover_dialog_state.dart';
import 'cover_draft.dart';
import 'cover_save_job.dart';
import 'cover_temp_files.dart';
import 'cover_texts.dart';

final _log = Logger('library.cover_dialog');

/// Which dialog: the item, and the draft of the Edit playlist form when it
/// reopens the dialog (null otherwise). The draft's files stay the form's.
typedef CoverDialogArgs = ({
  CustomCoverKind kind,
  String itemKey,
  CoverDraft? draft,
});

/// State of one open cover dialog; the provider is auto-disposed with the
/// route. Dispose deletes only the temp files the controller still owns (a
/// save or a draft takes them over).
final coverDialogControllerProvider = NotifierProvider.autoDispose
    .family<CoverDialogController, CoverDialogState, CoverDialogArgs>(
      CoverDialogController.new,
    );

class CoverDialogController extends Notifier<CoverDialogState> {
  CoverDialogController(this.args);

  final CoverDialogArgs args;

  CustomCoverItem get _item => (kind: args.kind, itemKey: args.itemKey);

  /// The picked row whose files this controller deletes. Null when there is
  /// none, when it came from the form's draft (the form's), or when a save or
  /// draft took it over.
  CoverPicked? _owned;

  /// The earlier pick (owned by this controller) kept while a new image is
  /// read; deleted when the new preview is ready, put back when it fails.
  CoverPicked? _replaced;
  int _generation = 0;
  bool _picking = false;

  @override
  CoverDialogState build() {
    ref.onDispose(() {
      final owned = [?_owned, ?_replaced];
      _owned = null;
      _replaced = null;
      for (final pick in owned) {
        unawaited(deleteTempFiles(pick.ownedFiles));
      }
    });
    ref.listen(
      coverDialogOptionsProvider(_item),
      (_, next) => _onOptions(next),
    );
    final draft = args.draft;
    final initial = CoverDialogState(
      options: ref.read(coverDialogOptionsProvider(_item)),
      picked: draft?.picked,
      offset: draft?.offset ?? 0.5,
    );
    return initial.options.hasValue ? openCoverDialog(initial, draft) : initial;
  }

  void _onOptions(AsyncValue<CoverDialogOptions> next) {
    state = next.hasValue && state.opening == null
        ? openCoverDialog(state.copyWith(options: next), args.draft)
        : state.copyWith(options: next);
  }

  /// Chooses a row (not the picked row while it is being read).
  void select(String rowId) {
    if (state.saving || state.selectedId == null) return;
    if (rowId == CoverRowIds.picked && state.picked == null) return;
    if (rowId == CoverRowIds.picked && state.reading) return;
    final options = state.options.value;
    final known =
        rowId == CoverRowIds.picked ||
        rowId == CoverRowIds.automatic ||
        (rowId == CoverRowIds.current && options?.current != null) ||
        (options?.suggestions.any((s) => s.rowId == rowId) ?? false);
    if (known) state = state.copyWith(selectedId: rowId);
  }

  /// Moves the pan position (clamped to 0..1); only while the chosen image
  /// can be panned.
  void setOffset(double offset) {
    if (state.saving || !state.panPossible) return;
    state = state.copyWith(offset: offset.clamp(0.0, 1.0));
  }

  /// Opens the platform picker and reads the image. A cancelled picker does
  /// nothing; a failure shows as [CoverDialogState.error] and leaves no row.
  Future<void> pick() async {
    if (state.saving || _picking) return;
    _picking = true;
    PickedImage? image;
    try {
      // A PlatformException (or anything else) from the picker is an error
      // value for the dialog, never thrown to the caller.
      image = await ref.read(imageFilePickerProvider).pick();
    } on Object catch (e, st) {
      _log.warning('image picker failed', e, st);
      _fail(e);
    } finally {
      _picking = false;
    }
    if (image != null) await drop(image);
  }

  /// Uses [image] (picked, or a file dropped on the preview): makes its
  /// preview and, when that works, selects its row. The earlier pick stays
  /// until the new preview is ready, then its temp files are deleted; when the
  /// new image fails, the earlier pick is back (a reading earlier pick is
  /// simply dropped). [image] is deleted when it is a temp copy and the
  /// dialog cannot use it.
  Future<void> drop(PickedImage image) async {
    if (!ref.mounted || state.saving || state.selectedId == null) {
      await _deleteIfTemp(image);
      return;
    }
    final generation = ++_generation;
    final before = state.selectedId;
    final beforeOffset = state.offset;
    // A ready earlier pick is kept (it may be the form draft's, then it is
    // not ours to delete); a pick still being read is superseded: its own
    // late result deletes the preview, its image goes now.
    final kept = state.picked != null && !state.reading ? state.picked : null;
    final owned = _owned;
    _owned = null;
    if (owned != null && !identical(owned, kept)) {
      await deleteTempFiles(owned.ownedFiles);
    }
    final replaced = identical(owned, kept) ? owned : null;
    _replaced = replaced;
    final reading = CoverPicked(image);
    _owned = image.temporary ? reading : null;
    state = state.copyWith(
      picked: reading,
      selectedId: CoverRowIds.picked,
      offset: 0.5,
    );
    final controller = ref.read(customCoverControllerProvider);
    try {
      final preview = await controller.previewCover(image.file);
      final ready = CoverPicked(image, preview);
      if (!ref.mounted || generation != _generation) {
        await deleteTempFiles([...ready.ownedFiles, ...?replaced?.ownedFiles]);
        return;
      }
      _owned = ready;
      _replaced = null;
      state = state.copyWith(picked: ready);
      if (replaced != null) await deleteTempFiles(replaced.ownedFiles);
    } on Object catch (e, st) {
      if (e is! FormatException && e is! FileSystemException) {
        _log.warning('cover preview failed', e, st);
      }
      await _deleteIfTemp(image);
      if (!ref.mounted || generation != _generation) {
        await deleteTempFiles(replaced?.ownedFiles ?? const []);
        return;
      }
      // The earlier pick is back; the selection only goes back when the
      // failed row is still the chosen one (the user may have moved on).
      _owned = replaced;
      _replaced = null;
      state = state.copyWith(
        picked: kept,
        offset: kept == null ? state.offset : beforeOffset,
        selectedId: state.selectedId == CoverRowIds.picked
            ? _rowAfterFailedPick(before, hasPicked: kept != null)
            : state.selectedId,
        error: CoverDialogError(e),
      );
    }
  }

  /// Save mode: starts a [CoverSaveJob] that outlives the dialog and waits
  /// for it. True when the cover was saved (pop the dialog); false when
  /// nothing was started or the save failed (the job showed the error; the
  /// dialog stays open and unlocked). [messenger] and [texts] must be taken
  /// from the root before this call. [openMessenger] is the messenger inside
  /// the dialog, used for a failure while the dialog is still open.
  Future<bool> save({
    required ScaffoldMessengerState messenger,
    required CoverTexts texts,
    ScaffoldMessengerState? Function() openMessenger = _noMessenger,
  }) async {
    if (!state.changed || state.selectedId == CoverRowIds.current) return false;
    final snapshot = state;
    final owned = snapshot.selectedId == CoverRowIds.picked ? _owned : null;
    if (owned != null) _owned = null;
    state = state.copyWith(saving: true);
    final controller = ref.read(customCoverControllerProvider);
    final job = CoverSaveJob(
      controller: controller,
      kind: args.kind,
      itemKey: args.itemKey,
      choice: () => resolveCoverChoice(controller, snapshot),
      messenger: messenger,
      openMessenger: openMessenger,
      texts: texts,
      ownedFiles: owned?.ownedFiles ?? const [],
      dialogOpen: () => ref.mounted,
    );
    final saved = await job.run();
    if (saved) return true;
    if (!ref.mounted) {
      await deleteTempFiles(owned?.ownedFiles ?? const []);
      return false;
    }
    _owned = owned ?? _owned;
    state = state.copyWith(saving: false);
    return false;
  }

  /// Form mode: the draft of the chosen cover, nothing written. The draft
  /// owns the picked image's temp files from now on. Choosing the item's
  /// stored cover again gives a draft with a null choice ([CoverDraft.keepsStored]).
  /// Null when nothing changed or the choice cannot be made (shown as
  /// [CoverDialogState.error]).
  Future<CoverDraft?> toDraft() async {
    if (!state.changed) return null;
    final snapshot = state;
    if (snapshot.selectedId == CoverRowIds.current) {
      return const CoverDraft(choice: null, rowId: CoverRowIds.current);
    }
    // The draft takes the picked files over before any await, so a dispose
    // while the choice is resolved cannot delete what the draft will hold.
    final picked = snapshot.chosenPicked;
    final taken = picked != null && identical(_owned, picked);
    if (taken) _owned = null;
    state = state.copyWith(saving: true);
    try {
      final choice = await resolveCoverChoice(
        ref.read(customCoverControllerProvider),
        snapshot,
      );
      return CoverDraft(
        choice: choice,
        rowId: snapshot.selectedId!,
        displayFile:
            picked?.preview?.file ?? snapshot.selectedSuggestion?.thumb,
        picked: picked,
        offset: snapshot.offset,
      );
    } on Object catch (e, st) {
      if (e is! FormatException && e is! FileSystemException) {
        _log.warning('cover draft failed', e, st);
      }
      if (taken) {
        // No draft: the controller owns the files again (or, when it is
        // already disposed, nobody does and they go now).
        if (ref.mounted) {
          _owned = picked;
        } else {
          await deleteTempFiles(picked.ownedFiles);
        }
      }
      _fail(e);
      return null;
    } finally {
      if (ref.mounted) state = state.copyWith(saving: false);
    }
  }

  /// The row to go back to when a pick failed: the one chosen before; when
  /// that was the picked row and no pick is left ([hasPicked] false), the
  /// opening row.
  String? _rowAfterFailedPick(String? before, {required bool hasPicked}) {
    if (before != CoverRowIds.picked || hasPicked) return before;
    final opening = state.opening?.rowId;
    if (opening != CoverRowIds.picked) return opening;
    return state.options.value?.current != null
        ? CoverRowIds.current
        : CoverRowIds.automatic;
  }

  /// The error was shown; forget it.
  void clearError() {
    if (state.error != null) state = state.copyWith(error: null);
  }

  void _fail(Object cause) {
    if (ref.mounted) state = state.copyWith(error: CoverDialogError(cause));
  }

  Future<void> _deleteIfTemp(PickedImage image) =>
      image.temporary ? deleteTempFiles([image.file]) : Future.value();
}

ScaffoldMessengerState? _noMessenger() => null;
