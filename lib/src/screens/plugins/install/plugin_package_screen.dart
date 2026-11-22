import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/install/prepare_result.dart';
import '../../../plugins/state/install_ops.dart';
import '../common/plugin_labels.dart';
import 'package_body.dart';
import 'package_controller.dart';
import 'package_icon.dart';

/// The one screen of install and update: a dialog on desktop (600 wide, up to
/// 840 high), a full-screen page on mobile ([fullScreen]). It pops with a
/// `PackageExit`, or null when the user closes it. The held package is
/// discarded however the screen ends.
class PluginPackageScreen extends ConsumerStatefulWidget {
  const PluginPackageScreen({
    super.key,
    required this.start,
    required this.subject,
    required this.fullScreen,
    this.expectUpdate = false,
  });

  /// Starts one preparation of the package; called again by [Thử lại].
  final PrepareOperation Function() start;
  final PackageSubject subject;
  final bool fullScreen;

  /// The screen was opened from an update row: its title says so while the
  /// package loads.
  final bool expectUpdate;

  @override
  ConsumerState<PluginPackageScreen> createState() => _PackageScreenState();
}

class _PackageScreenState extends ConsumerState<PluginPackageScreen> {
  late final PackageController _c;
  var _closing = false;

  @override
  void initState() {
    super.initState();
    _c = PackageController(
      ops: ref.read(installOpsProvider),
      start: widget.start,
      subject: widget.subject,
    )..addListener(_onChange);
    _c.prepare();
  }

  @override
  void dispose() {
    _c.removeListener(_onChange);
    _c.dispose();
    super.dispose();
  }

  void _onChange() {
    final exit = _c.exit;
    if (exit != null && !_closing && mounted) {
      _closing = true;
      Navigator.of(context).pop(exit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final working = _c.phase == PackagePhase.working;
        final content = _content(context);
        return PopScope(
          canPop: !working,
          child: widget.fullScreen
              ? Scaffold(body: SafeArea(child: content))
              : Dialog(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 840),
                    child: content,
                  ),
                ),
        );
      },
    );
  }

  Widget _content(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final working = _c.phase == PackagePhase.working;
    final ready = _c.phase == PackagePhase.ready && !_c.proBlocked;
    final update = _c.held == null ? widget.expectUpdate : _c.isUpdate;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context, l10n),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: KSpace.x5),
            child: PackageBody(controller: _c),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(KSpace.x4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: KSpace.x2,
            children: [
              TextButton(
                onPressed: working ? null : () => Navigator.of(context).pop(),
                child: Text(update ? l10n.pluginsPkgLater : l10n.pluginsCancel),
              ),
              FilledButton(
                onPressed: ready ? _c.confirm : null,
                child: working
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: KSpace.x2,
                        children: [
                          const SizedBox.square(
                            dimension: KIconSize.sm,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          Text(
                            update
                                ? l10n.pluginsPkgUpdating
                                : l10n.pluginsPkgInstalling,
                          ),
                        ],
                      )
                    : Text(
                        update ? l10n.pluginsPkgUpdate : l10n.pluginsPkgInstall,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n) {
    final held = _c.held;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final manifest = held?.package.manifest;
    final update = held == null ? widget.expectUpdate : _c.isUpdate;
    final name = manifest?.name ?? widget.subject.name;
    final title = held == null && !widget.subject.named
        ? l10n.pluginsPkgLoadingTitle
        : update
        ? l10n.pluginsPkgUpdateTitle(name)
        : l10n.pluginsPkgInstallTitle(name);
    String? subtitle;
    if (manifest != null) {
      final kind = (kindLabel(l10n, manifest.kind) ?? '').toLowerCase();
      final author = manifest.author.isEmpty
          ? l10n.pluginsAuthorUnknown
          : l10n.pluginsPkgAuthorDeclared(manifest.author);
      subtitle = update
          ? l10n.pluginsPkgUpdateSubtitle(kind, author)
          : l10n.pluginsPkgInstallSubtitle(kind, manifest.version, author);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x5,
        KSpace.x4,
        KSpace.x2,
        KSpace.x3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: KSpace.x3,
        children: [
          PackageIcon(kind: manifest?.kind, bytes: held?.package.icon),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: text.titleLarge),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          KIconButton(
            icon: KIcons.close,
            tooltip: l10n.pluginsPkgClose,
            onPressed: _c.phase == PackagePhase.working
                ? null
                : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
