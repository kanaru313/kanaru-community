import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/alerts_provider.dart';
import '../../../plugins/state/install_ops.dart';
import '../../../plugins/state/plugin_page_provider.dart';
import '../../../plugins/state/plugin_store_providers.dart';
import '../../settings/ui/settings_scaffold.dart';
import '../plugin_paths.dart';
import '../remove/remove_flow.dart';
import '../config/config_form.dart';
import 'config_slot.dart';
import 'details_block.dart';
import 'error_band.dart';
import 'plugin_head_card.dart';
import 'plugin_page_header.dart';
import 'plugin_page_notice.dart';
import 'soon_blocks.dart';
import 'update_band.dart';

/// The page of one installed plugin ("Chi tiết plugin"): head card, the update
/// and error bands, Chi tiết, the slot of the plugin's settings, Kết nối and
/// Dữ liệu. The header's 🗑 removes the plugin. While the list is read the
/// page is blank; an unreadable list and a plugin that is gone each say so.
class PluginPage extends ConsumerStatefulWidget {
  const PluginPage({super.key, required this.installId});

  final String installId;

  @override
  ConsumerState<PluginPage> createState() => _PluginPageState();
}

class _PluginPageState extends ConsumerState<PluginPage>
    with WidgetsBindingObserver {
  final _nameKey = GlobalKey();
  final _headerKey = GlobalKey();
  final _slotKey = GlobalKey<ConfigSlotState>();
  final _collapsed = ValueNotifier<bool>(false);

  /// The user confirmed the removal: the page is blank until it leaves, so the
  /// plugin vanishing from the list never shows "không còn được cài".
  bool _removing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() => _queueMeasure();

  @override
  void didChangeTextScaleFactor() => _queueMeasure();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _collapsed.dispose();
    super.dispose();
  }

  bool _measureQueued = false;

  /// Scroll offset of the latest notification.
  double _pixels = 0;

  /// The plugin's name while the page is blank for a removal, so the header
  /// keeps it instead of falling back to "Chi tiết plugin".
  String? _lastName;

  /// A scroll moved the list. Layout of the new offset is not done yet, so
  /// the position of the name is read after the frame.
  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    _pixels = notification.metrics.pixels;
    _queueMeasure();
    return false;
  }

  /// Reads the position of the name once the frame is laid out.
  void _queueMeasure() {
    if (_measureQueued) return;
    _measureQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureQueued = false;
      if (mounted) _measure(_pixels);
    });
  }

  /// The header shows the plugin's name while the name in the head card is
  /// under the header.
  void _measure(double pixels) {
    final name = _nameKey.currentContext?.findRenderObject();
    final header = _headerKey.currentContext?.findRenderObject();
    if (header is! RenderBox || !header.attached) return;
    if (name is! RenderBox || !name.attached) {
      // The list dropped the head card: it is far above.
      _collapsed.value = pixels > 0;
      return;
    }
    final nameBottom = name.localToGlobal(Offset(0, name.size.height)).dy;
    final headerBottom = header.localToGlobal(Offset(0, header.size.height)).dy;
    if (nameBottom.isNaN) {
      // Kept by the list but off the screen and not laid out: far above.
      _collapsed.value = pixels > 0;
      return;
    }
    _collapsed.value = nameBottom <= headerBottom + 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final page = ref.watch(pluginPageProvider(widget.installId));
    final data = _removing ? null : page.value;
    if (data != null) _lastName = data.row.name;
    // New page data moves the name without a scroll: measure after the frame
    // (a window or text scale change does the same, see the observer).
    _queueMeasure();
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: _scaffold(context, l10n, page, data),
    );
  }

  Widget _scaffold(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<PluginPageData?> page,
    PluginPageData? data,
  ) {
    return SettingsScaffold(
      title: l10n.pluginsPageTitle,
      parentPath: PluginPaths.store,
      headerBuilder: (context, onBack) => KeyedSubtree(
        key: _headerKey,
        child: PluginPageHeader(
          collapsed: _collapsed,
          name: data?.row.name ?? (_removing ? _lastName : null),
          onBack: onBack,
          actions: [
            if (data != null)
              KIconButton(
                icon: KIcons.delete,
                emphasis: KIconEmphasis.critical,
                tooltip: l10n.pluginsRemoveTooltip(data.row.name),
                onPressed: () => unawaited(_remove()),
              ),
          ],
        ),
      ),
      children: _children(context, l10n, page, data),
    );
  }

  List<Widget> _children(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<PluginPageData?> page,
    PluginPageData? data,
  ) {
    if (_removing) return const [];
    if (page.hasError) {
      return [
        PluginPageNotice(
          icon: KIcons.warning,
          message: l10n.pluginsPageLoadFailed,
          actionLabel: l10n.pluginsRetry,
          onAction: _retry,
        ),
      ];
    }
    if (page.isLoading) return const [];
    if (data == null) {
      return [
        PluginPageNotice(
          icon: KIcons.extension,
          message: l10n.pluginsPageGone,
          actionLabel: l10n.pluginsPageToStore,
          onAction: () => context.go(PluginPaths.store),
        ),
      ];
    }
    final hasConfig = data.manifest?.config.isNotEmpty ?? false;
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: KSpace.x3,
        children: [
          PluginHeadCard(data: data, nameKey: _nameKey),
          if (data.update != null) UpdateBand(data: data),
          if (PluginErrorBand.applies(data))
            PluginErrorBand(
              data: data,
              onOpenConfig: () => unawaited(_openConfig()),
            ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailsBlock(data: data),
          if (hasConfig)
            ConfigSlot(
              key: _slotKey,
              child: ConfigForm(
                installId: widget.installId,
                locked: _formLocked(data),
              ),
            ),
        ],
      ),
      const ConnectionBlock(),
      DataBlock(kind: data.kind),
    ];
  }

  /// The form is dimmed only while the package is broken or this plugin is
  /// being updated in place.
  bool _formLocked(PluginPageData data) =>
      data.updating ||
      data.alerts.contains(PluginAlert.packageMissing) ||
      data.alerts.contains(PluginAlert.broken) ||
      data.alerts.contains(PluginAlert.reinstallFromFile);

  void _retry() {
    ref.invalidate(installedPluginsProvider);
    ref.invalidate(pluginPageProvider(widget.installId));
  }

  /// Scrolls to the settings. The scroll is programmatic, so the name is
  /// measured again once it has finished.
  Future<void> _openConfig() async {
    await _slotKey.currentState?.reveal(
      animate: !MediaQuery.disableAnimationsOf(context),
    );
    if (mounted) _queueMeasure();
  }

  Future<void> _remove() async {
    final gone = await removePluginFlow(
      context,
      ref.read(installOpsProvider),
      widget.installId,
      onBeforeRemove: () => setState(() => _removing = true),
    );
    if (!mounted) return;
    if (!gone) {
      setState(() => _removing = false);
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(PluginPaths.store);
    }
  }
}
