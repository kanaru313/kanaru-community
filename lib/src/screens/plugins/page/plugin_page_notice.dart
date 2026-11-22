import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// A page in a state with nothing to show but a sentence and one button: the
/// list cannot be read ([Thử lại]) or the plugin is gone ([Về Kho plugin]).
class PluginPageNotice extends StatelessWidget {
  const PluginPageNotice({
    super.key,
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KSpace.x9),
      child: Column(
        spacing: KSpace.x3,
        children: [
          Icon(icon, size: KIconSize.xl, color: scheme.onSurfaceVariant),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
