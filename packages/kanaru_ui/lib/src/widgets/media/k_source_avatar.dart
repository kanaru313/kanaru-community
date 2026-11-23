import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

/// The picture of a lyrics source (a plugin): its own icon, else its first
/// letter on a tonal square. [removed] (the plugin is no longer installed)
/// always draws the letter on grey, whatever picture is known, so a kept copy
/// whose plugin is gone never looks like a live source.
///
/// The corner radius follows the size (a quarter of it), so the same widget
/// serves the 16 dp card icon, the 22 dp header button and the 24 dp rows.
/// Decorative: it adds no semantics; the owner names the source in text.
class KSourceAvatar extends StatelessWidget {
  const KSourceAvatar({
    super.key,
    required this.label,
    required this.size,
    this.imageBytes,
    this.removed = false,
  });

  /// The plugin's icon bytes; null (or [removed]) shows the initial.
  final Uint8List? imageBytes;

  /// The plugin's name; its first letter is the fallback.
  final String label;

  final double size;
  final bool removed;

  /// First visible character of [label], upper-cased; "?" when it has none.
  static String initialOf(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return '?';
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(size / 4);
    final bytes = removed ? null : imageBytes;
    final Color background = removed
        ? scheme.outlineVariant
        : scheme.secondaryContainer;
    final Color foreground = removed
        ? scheme.onSurfaceVariant
        : scheme.onSecondaryContainer;
    final initial = Center(
      child: Text(
        initialOf(label),
        maxLines: 1,
        style: TextStyle(
          fontSize: size * 0.46,
          fontWeight: FontWeight.w700,
          height: 1,
          color: foreground,
        ),
      ),
    );
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: radius,
          child: ColoredBox(
            color: background,
            child: bytes == null
                ? initial
                : Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    // Decoded at the size it is drawn, not the picture's own.
                    cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                        .round(),
                    // A damaged picture falls back to the initial.
                    errorBuilder: (_, _, _) => initial,
                  ),
          ),
        ),
      ),
    );
  }
}
