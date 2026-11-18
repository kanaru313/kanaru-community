import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/widgets.dart';

import '../domain/image_file_picker.dart';

/// The first path that is a regular file (folders, links to folders and
/// missing paths are skipped), as a user-owned [PickedImage]. Format is not
/// checked here.
PickedImage? firstDroppedFile(Iterable<String> paths) {
  for (final path in paths) {
    if (path.isEmpty) continue;
    if (FileSystemEntity.typeSync(path) != FileSystemEntityType.file) continue;
    return PickedImage(
      file: File(path),
      name: path.split(Platform.pathSeparator).last,
      temporary: false,
    );
  }
  return null;
}

/// Accepts one image file dropped on [child] (Linux only; on Android it is
/// just [child]).
class ImageDropTarget extends StatelessWidget {
  const ImageDropTarget({
    super.key,
    required this.child,
    required this.onDrop,
    this.onHover,
    this.enabled = true,
    this.isLinux,
  });

  final Widget child;

  /// Called with the first dropped item that is a local file.
  final ValueChanged<PickedImage> onDrop;

  /// True while a drag is over [child], false when it leaves or drops.
  final ValueChanged<bool>? onHover;

  final bool enabled;

  /// Overrides the platform check in tests; null means the real platform.
  final bool? isLinux;

  @override
  Widget build(BuildContext context) {
    if (!(isLinux ?? Platform.isLinux)) return child;
    return DropTarget(
      enable: enabled,
      onDragEntered: (_) => onHover?.call(true),
      onDragExited: (_) => onHover?.call(false),
      onDragDone: (details) {
        onHover?.call(false);
        final picked = firstDroppedFile(details.files.map((f) => f.path));
        if (picked != null) onDrop(picked);
      },
      child: child,
    );
  }
}
