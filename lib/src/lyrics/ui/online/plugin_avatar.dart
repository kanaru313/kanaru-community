import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../plugins/state/store_ops.dart';
import 'online_source_providers.dart';

/// The picture of the lyrics plugin [providerId]: its icon, else the first
/// letter of [name]; a plugin that is no longer installed is the letter on
/// grey. [name] is the name the lyrics were kept with, so it is known even
/// when the plugin is gone.
class PluginAvatar extends ConsumerWidget {
  const PluginAvatar({
    super.key,
    required this.providerId,
    required this.name,
    required this.size,
  });

  final String providerId;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final removed = ref.watch(onlineSourceRemovedProvider(providerId));
    final bytes = removed
        ? null
        : ref.watch(pluginIconProvider(providerId)).value;
    return KSourceAvatar(
      label: name,
      size: size,
      imageBytes: bytes,
      removed: removed,
    );
  }
}
