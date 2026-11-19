import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_space.dart';

/// Page body: side gutter, centred max width, vertical scroll. The list ends
/// above the bottom media padding (system bar, a floating dock) plus 32 dp
/// (mobile) or 48 dp (desktop).
class KPage extends StatelessWidget {
  const KPage({
    super.key,
    required this.children,
    this.maxWidth = KLayout.readable,
  });

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final gutter = desktop ? KLayout.gutterDesktop : KLayout.gutterMobile;
    // Breathing room under the last item, on top of the system inset.
    final tail = desktop ? KSpace.x9 : KSpace.x7;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          padding: EdgeInsets.only(
            left: gutter,
            right: gutter,
            bottom: MediaQuery.paddingOf(context).bottom + tail,
          ),
          children: children,
        ),
      ),
    );
  }
}
