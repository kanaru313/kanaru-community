import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/package/plugin_kind.dart';
import '../../../plugins/state/store_ops.dart';

/// The 40 dp icon of a plugin: its own picture (from the installed package or
/// the repository), else a glyph of its kind. [alerted] pins the red dot on
/// its corner and names it "Có lỗi" for screen readers.
class PluginIcon extends ConsumerWidget {
  const PluginIcon({
    super.key,
    required this.installId,
    required this.kind,
    this.alerted = false,
    this.dimension = size,
  });

  final String installId;
  final PluginKind? kind;
  final bool alerted;

  static const double size = KIconSize.xl;

  /// Side of the icon; the plugin page draws it larger.
  final double dimension;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final bytes = ref.watch(pluginIconProvider(installId)).value;
    final glyph = ColoredBox(
      color: scheme.secondaryContainer,
      child: Icon(
        glyphOf(kind),
        size: KIconSize.md,
        color: scheme.onSecondaryContainer,
      ),
    );
    final face = SizedBox.square(
      dimension: dimension,
      child: ClipRRect(
        borderRadius: KRadius.sm,
        child: bytes == null
            ? glyph
            : Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                // A damaged picture falls back to the glyph.
                errorBuilder: (_, _, _) => glyph,
              ),
      ),
    );
    if (!alerted) return ExcludeSemantics(child: face);
    return Semantics(
      label: AppLocalizations.of(context).pluginsAlertLabel,
      image: true,
      child: KAlertDot.corner(child: face),
    );
  }

  /// The glyph shown for a plugin that has no picture of its own.
  static IconData glyphOf(PluginKind? kind) => switch (kind) {
    PluginKind.lyrics => KIcons.lyrics,
    PluginKind.translate || PluginKind.aiTranslate => KIcons.languages,
    PluginKind.streaming => KIcons.online,
    PluginKind.aiChat => KIcons.ai,
    null => KIcons.extension,
  };
}
