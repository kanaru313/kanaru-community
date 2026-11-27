import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../plugins/state/store_ops.dart';

/// A chat plugin's own picture at [size], else the AI glyph; a plugin that is
/// gone ([removed]) shows a "?" tile. No plugin yet, or plugins still
/// loading, shows the glyph. Decorative: the name of the
/// plugin is always written next to it or on its button.
class ChatPluginIcon extends ConsumerWidget {
  const ChatPluginIcon({
    super.key,
    required this.installId,
    this.removed = false,
    this.size = 24,
  });

  /// The plugin; null when there is none to show.
  final String? installId;

  /// The chat's plugin was uninstalled: a "?" tile.
  final bool removed;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final id = installId;
    if (removed) {
      return ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: KRadius.xs,
            ),
            child: Center(
              child: Text(
                '?',
                style: TextStyle(
                  fontSize: size * 0.6,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }
    final bytes = id == null ? null : ref.watch(pluginIconProvider(id)).value;
    final glyph = ColoredBox(
      color: scheme.secondaryContainer,
      child: Icon(
        KIcons.ai,
        size: size * 0.7,
        color: scheme.onSecondaryContainer,
      ),
    );
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: KRadius.xs,
          child: bytes == null
              ? glyph
              : Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => glyph,
                ),
        ),
      ),
    );
  }
}
