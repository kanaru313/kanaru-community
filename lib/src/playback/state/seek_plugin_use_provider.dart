import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/state/settings_providers.dart';
import '../domain/seek_bar_style.dart';

/// Stored value prefix that names an installed seek bar plugin
/// (`plugin:<installId>`) in the style and fallback settings.
const seekPluginPrefix = 'plugin:';

/// How the stored seek bar settings use one seek bar plugin: it is the chosen
/// style, and / or it stands in as the ★ style while a song has no waveform.
class SeekPluginUse {
  const SeekPluginUse({this.chosen = false, this.fallback = false});

  final bool chosen;
  final bool fallback;

  bool get unused => !chosen && !fallback;

  @override
  bool operator ==(Object other) =>
      other is SeekPluginUse &&
      other.chosen == chosen &&
      other.fallback == fallback;

  @override
  int get hashCode => Object.hash(chosen, fallback);
}

/// Reads the raw stored style and ★ values for [installId] (the typed
/// settings decode built-in names only) and follows their changes.
final seekPluginUseProvider = Provider.autoDispose
    .family<SeekPluginUse, String>((ref, installId) {
      final store = ref.watch(settingsStoreProvider);
      final keys = {seekBarStyleSetting.key, seekBarFallbackSetting.key};
      final sub = store.changes
          .where(keys.contains)
          .listen((_) => ref.invalidateSelf());
      ref.onDispose(sub.cancel);
      final wanted = '$seekPluginPrefix$installId';
      return SeekPluginUse(
        chosen: store.read(seekBarStyleSetting.key) == wanted,
        fallback: store.read(seekBarFallbackSetting.key) == wanted,
      );
    });
