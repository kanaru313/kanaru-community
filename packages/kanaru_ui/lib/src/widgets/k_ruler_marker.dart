import 'package:material_ui/material_ui.dart';

import '../tokens/k_shape.dart';
import 'k_focus_ring.dart';

/// The centre `primary` bar of the ruler; it shows the keyboard focus ring.
class KRulerMarker extends StatelessWidget {
  const KRulerMarker({super.key, required this.focused, required this.height});

  final bool focused;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Padding(
        padding: EdgeInsets.only(top: height * 0.3),
        child: KFocusRing(
          focused: focused,
          radius: KRadius.full,
          inset: 2,
          child: Container(
            width: 4,
            height: height * 0.55,
            decoration: ShapeDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: KShape.of(KRadius.full),
            ),
          ),
        ),
      ),
    );
  }
}
