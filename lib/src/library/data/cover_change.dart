import '../domain/covers/cover_choice.dart';

/// The handle [CustomCoverStore.changeCover] returns. It holds no logic: undo
/// and release run in the store's serial queue, which owns the pins. [released]
/// is read and written only there.
class StoreCoverChange implements CoverChange {
  StoreCoverChange({
    required this.previousKey,
    required this.currentKey,
    required this._onUndo,
    required this._onRelease,
  });

  @override
  final String? previousKey;
  @override
  final String? currentKey;

  final Future<bool> Function(StoreCoverChange) _onUndo;
  final Future<void> Function(StoreCoverChange) _onRelease;

  /// True once the pin on [previousKey] is gone (undone or released).
  bool released = false;

  @override
  Future<bool> undo() => _onUndo(this);

  @override
  Future<void> release() => _onRelease(this);
}
