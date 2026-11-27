import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/install/prepare_result.dart';
import '../../../plugins/domain/package/plugin_kind.dart';

/// "Đang tải và kiểm gói…" with a progress bar and the line under it.
class InstallProgress extends StatelessWidget {
  const InstallProgress({super.key, required this.progress, this.kind});

  final PrepareProgress? progress;

  /// The kind, when known before the package is read: a seek bar package is
  /// checked for images, not for hosts and scripts.
  final PluginKind? kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final p = progress;
    final total = p?.total;
    final downloading = p?.stage == PrepareStage.downloading;
    final fraction = downloading && total != null && total > 0
        ? (p!.done / total).clamp(0.0, 1.0)
        : null;
    final seekbar = kind == PluginKind.seekbar;
    final line = !downloading
        ? (seekbar ? l10n.pluginsPkgCheckingSeekbar : l10n.pluginsPkgChecking)
        : total == null
        ? (seekbar
              ? l10n.pluginsPkgProgressUnknownSeekbar(_kb(p!.done))
              : l10n.pluginsPkgProgressUnknown(_kb(p!.done)))
        : (seekbar
              ? l10n.pluginsPkgProgressSeekbar(_kb(p!.done), _kb(total))
              : l10n.pluginsPkgProgress(_kb(p!.done), _kb(total)));
    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: KSpace.x2,
        children: [
          Row(
            spacing: KSpace.x2,
            children: [
              const SizedBox.square(
                dimension: KIconSize.sm,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              Expanded(
                child: Text(l10n.pluginsPkgLoading, style: text.bodyMedium),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: KRadius.full,
            child: LinearProgressIndicator(value: fraction, minHeight: 4),
          ),
          Text(
            line,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  static int _kb(int bytes) => (bytes / 1024).ceil();
}
