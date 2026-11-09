import '../icons/k_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../tokens/k_layout.dart';
import '../tokens/k_space.dart';

/// Header of every page: `[<]` (child pages only), title, spacer, actions.
/// Root pages pass no [onBack], so the back button is hidden.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.backTooltip,
  });

  final String title;

  /// Goes up to the parent page. Null on a root page.
  final VoidCallback? onBack;
  final List<Widget> actions;
  final String? backTooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: KLayout.minTarget + KSpace.x2,
      child: Row(
        spacing: KSpace.x2,
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(KIcons.back),
              tooltip: backTooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack,
            ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
