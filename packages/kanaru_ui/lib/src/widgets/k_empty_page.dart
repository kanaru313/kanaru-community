import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_layout.dart';
import 'k_empty.dart';
import 'page_header.dart';

/// Root page that has nothing to show yet: header on top, [KEmpty] filling the
/// rest. Same gutter and max width as `KPage`.
class KEmptyPage extends StatelessWidget {
  const KEmptyPage({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
    this.headerActions = const [],
  });

  final String title;
  final IconData icon;
  final String message;
  final List<Widget> headerActions;

  @override
  Widget build(BuildContext context) {
    final gutter = FormFactor.of(context) == FormFactor.desktop
        ? KLayout.gutterDesktop
        : KLayout.gutterMobile;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: KLayout.readable),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: Column(
            children: [
              PageHeader(title: title, actions: headerActions),
              Expanded(child: KEmpty(icon: icon, message: message)),
            ],
          ),
        ),
      ),
    );
  }
}
