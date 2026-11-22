import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/install/prepare_result.dart';
import '../../../plugins/state/install_ops.dart';
import 'package_body.dart';
import 'package_controller.dart';
import 'package_exit.dart';
import 'package_header.dart';

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
    this.onInstalledAfterClose,
  });

  /// Starts one preparation of the package; called again by [Thử lại].
  final PrepareOperation Function() start;
  final PackageSubject subject;
  final bool fullScreen;

  /// The screen was opened from an update row: its title says so while the
  /// package loads.
  final bool expectUpdate;

  /// Tells the flow the plugin was written after this screen had closed.
  final void Function(PackageInstalled installed)? onInstalledAfterClose;

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
      onInstalledAfterClose: widget.onInstalledAfterClose,
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

  static const double _boxWidth = 600;
  static const double _boxMaxHeight = 840;

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
                  // showKDialog already caps the width at 600: no side inset
                  // of the Material dialog on top of it.
                  insetPadding: const EdgeInsets.symmetric(vertical: 24),
                  constraints: const BoxConstraints(
                    maxWidth: _boxWidth,
                    maxHeight: _boxMaxHeight,
                  ),
                  child: SizedBox(width: _boxWidth, child: content),
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
        PackageHeader(
          controller: _c,
          subject: widget.subject,
          expectUpdate: widget.expectUpdate,
        ),
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
}
