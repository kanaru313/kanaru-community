import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../plugins/state/store_ops.dart';

/// A chat plugin's own picture at [size], else the AI glyph; a plugin that is
/// gone ([installId] null) shows a "?" tile. Decorative: the name of the
/// plugin is always written next to it or on its button.
class ChatPluginIcon extends ConsumerWidget {
  const ChatPluginIcon({super.key, required this.installId, this.size = 24});

  /// The plugin; null when the chat's plugin is gone (a "?" tile).
  final String? installId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final id = installId;
    if (id == null) {
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
    final bytes = ref.watch(pluginIconProvider(id)).value;
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
