import 'package:material_ui/material_ui.dart';

import '../tokens/k_space.dart';

/// Empty state: icon, one sentence and an optional action.
class KEmpty extends StatelessWidget {
  const KEmpty({super.key, required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KSpace.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: KSpace.x3,
          children: [
            Icon(icon, size: KSpace.x9, color: scheme.onSurfaceVariant),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
