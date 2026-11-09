import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_layout.dart';

/// Page body: side gutter, centred max width, vertical scroll.
class KPage extends StatelessWidget {
  const KPage({super.key, required this.children, this.maxWidth = KLayout.readable});

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final gutter = FormFactor.of(context) == FormFactor.desktop
        ? KLayout.gutterDesktop
        : KLayout.gutterMobile;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          children: children,
        ),
      ),
    );
  }
}
