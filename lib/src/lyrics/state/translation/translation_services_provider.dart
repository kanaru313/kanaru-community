import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plugins/domain/package/plugin_kind.dart';
import '../../../plugins/state/plugin_page_provider.dart';
import 'translation_settings.dart';

/// One installed translate or AI translate plugin the user can choose.
class TranslateService {
  const TranslateService({
    required this.installId,
    required this.name,
    required this.ai,
  });

  final String installId;
  final String name;

  /// An `ai-translate` plugin: it has "Tinh chỉnh AI".
  final bool ai;

  @override
  bool operator ==(Object other) =>
      other is TranslateService &&
      other.installId == installId &&
      other.name == name &&
      other.ai == ai;

  @override
  int get hashCode => Object.hash(installId, name, ai);
}

/// The translate plugins installed and which one is chosen.
class TranslateServices {
  const TranslateServices({required this.all, this.current, this.gone = false});

  /// Plain translate plugins first, then the AI ones, install order within.
  final List<TranslateService> all;

  /// The chosen service when it is installed.
  final TranslateService? current;

  /// A service was chosen, but its plugin is no longer installed.
  final bool gone;

  /// No translate plugin is installed at all.
  bool get none => all.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is TranslateServices &&
      other.current == current &&
      other.gone == gone &&
      other.all.length == all.length &&
      [for (var i = 0; i < all.length; i++) all[i] == other.all[i]]
          .every((same) => same);

  @override
  int get hashCode => Object.hash(current, gone, all.length);
}

/// The services the Dịch lời modal offers. Loading or error while the
/// installed list is: "unknown" never reads as "no plugin".
final translateServicesProvider =
    Provider.autoDispose<AsyncValue<TranslateServices>>((ref) {
      final chosen = ref.watch(translationServiceProvider);
      return ref.watch(installedByKindProvider).whenData((installed) {
        final all = [
          for (final kind in [PluginKind.translate, PluginKind.aiTranslate])
            for (final entry in installed.of(kind))
              if (entry.row.removedAt == null)
                TranslateService(
                  installId: entry.row.installId,
                  name: entry.row.name,
                  ai: kind == PluginKind.aiTranslate,
                ),
        ];
        final current = all.where((s) => s.installId == chosen).firstOrNull;
        return TranslateServices(
          all: all,
          current: current,
          gone: chosen != null && current == null,
        );
      });
    });
