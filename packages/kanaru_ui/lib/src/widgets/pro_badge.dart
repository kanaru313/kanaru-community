import 'package:flutter/material.dart';

import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';

/// Small "PRO" tag marking a locked or Pro-only surface. Pure presentation.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key, this.label = 'PRO'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: KRadius.full),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KSpace.x2, vertical: KSpace.x1 / 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onTertiaryContainer,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
