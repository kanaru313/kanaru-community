import 'dart:typed_data';

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../plugins/domain/package/plugin_kind.dart';
import '../common/plugin_icon.dart';

/// The 56 dp icon of the install screen: the package's own picture, else the
/// glyph of its kind.
class PackageIcon extends StatelessWidget {
  const PackageIcon({super.key, required this.kind, this.bytes});

  final PluginKind? kind;
  final Uint8List? bytes;

  static const double size = 56;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glyph = ColoredBox(
      color: scheme.secondaryContainer,
      child: Icon(
        PluginIcon.glyphOf(kind),
        size: KIconSize.lg,
        color: scheme.onSecondaryContainer,
      ),
    );
    final picture = bytes;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: KRadius.sm,
          child: picture == null
              ? glyph
              : Image.memory(
                  picture,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => glyph,
                ),
        ),
      ),
    );
  }
}
