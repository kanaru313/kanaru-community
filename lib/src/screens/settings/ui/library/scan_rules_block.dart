import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../library/domain/scan/format_groups.dart';
import '../../../../library/domain/scan_status.dart';
import '../../../../library/domain/scan/scan_rule_values.dart';
import '../../../../library/state/scan/scan_settings.dart';
import '../../../../library/state/scan_providers.dart';
import '../../../../platform/domain/local_audio_catalog.dart';
import '../../../../platform/state/local_audio_catalog_provider.dart';
import '../../../first_run/ui/folder_actions.dart';
import '../soon_row.dart';
import 'scan_rule_labels.dart';

/// Block "Scan": what the scanner leaves out. Every change applies at the
/// next scan; a SnackBar says so and offers "Rescan" (nothing scans by
/// itself).
class ScanRulesBlock extends ConsumerStatefulWidget {
  const ScanRulesBlock({super.key});

  @override
  ConsumerState<ScanRulesBlock> createState() => _ScanRulesBlockState();
}

class _ScanRulesBlockState extends ConsumerState<ScanRulesBlock> {
  final _durationKey = GlobalKey();
  final _sizeKey = GlobalKey();
  final _formatsKey = GlobalKey();

  /// Tells the user a rule changed: it applies at the next scan.
  void _applyLater(
    ScaffoldMessengerState messenger,
    AppLocalizations l10n,
    LibraryScanCommands scan,
  ) {
    showAppSnackBarOn(
      messenger,
      l10n.settingsLibraryRulesApplyLater,
      actionLabel: l10n.scanSetupRescan,
      // `scan` was read while the page was alive: the toast can outlive it.
      onAction: () => rescanInBackground(scan),
    );
  }

  Future<void> _pickDuration(AppLocalizations l10n, int current) async {
    final messenger = ScaffoldMessenger.of(context);
    final scan = ref.read(libraryScanCommandsProvider);
    final notifier = ref.read(minDurationMsProvider.notifier);
    var changed = false;
    await showSliderSheet(
      context,
      anchor: _durationKey,
      anchorAlign: KAnchorAlign.end,
      title: Text(l10n.settingsLibraryMinDuration),
      caption: Text(l10n.settingsLibraryMinDurationCaption),
      sliders: [
        KStopSliderSpec<int>(
          stops: minDurationStopsMs,
          value: current,
          liveLabel: (ms) => minDurationLabel(l10n, ms),
          minLabel: l10n.settingsPlaybackOff,
          maxLabel: minDurationLabel(l10n, maxMinDurationMs),
          onCommitted: (ms) {
            changed = true;
            notifier.set(ms);
          },
        ),
      ],
    );
    if (changed) _applyLater(messenger, l10n, scan);
  }

  Future<void> _pickSize(AppLocalizations l10n, int current) async {
    final messenger = ScaffoldMessenger.of(context);
    final scan = ref.read(libraryScanCommandsProvider);
    final notifier = ref.read(minSizeBytesProvider.notifier);
    var changed = false;
    await showSliderSheet(
      context,
      anchor: _sizeKey,
      anchorAlign: KAnchorAlign.end,
      title: Text(l10n.settingsLibraryMinSize),
      caption: Text(l10n.settingsLibraryMinSizeCaption),
      sliders: [
        KStopSliderSpec<int>(
          stops: minSizeStopsBytes,
          value: current,
          liveLabel: (bytes) => minSizeLabel(l10n, bytes),
          minLabel: l10n.settingsPlaybackOff,
          maxLabel: minSizeLabel(l10n, minSizeStopsBytes.last),
          onCommitted: (bytes) {
            changed = true;
            notifier.set(bytes);
          },
        ),
      ],
    );
    if (changed) _applyLater(messenger, l10n, scan);
  }

  Future<void> _pickFormats(AppLocalizations l10n, List<String> current) async {
    final messenger = ScaffoldMessenger.of(context);
    final scan = ref.read(libraryScanCommandsProvider);
    final notifier = ref.read(formatGroupsProvider.notifier);
    var changed = false;
    await showMultiSelectionPicker<String>(
      context,
      anchor: _formatsKey,
      anchorAlign: KAnchorAlign.end,
      title: Text(l10n.settingsLibraryFormats),
      subtitle: Text(l10n.settingsLibraryFormatsCaption),
      options: [
        for (final group in formatGroups)
          SelectionOption(
            value: group.id,
            title: Text(formatGroupName(group.id)),
            subtitle: Text(group.extensions.join(', ')),
          ),
      ],
      initial: current.toSet(),
      selectAllLabel: l10n.settingsLibraryFormatsSelectAll,
      selectedCountLabel: l10n.settingsCountOfTotal,
      minSelected: 1,
      minSelectedNote: l10n.settingsLibraryFormatsKeepOne,
      onChanged: (picked) {
        changed = true;
        notifier.set([
          for (final id in allFormatGroupIds)
            if (picked.contains(id)) id,
        ]);
      },
    );
    if (changed) _applyLater(messenger, l10n, scan);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final minDuration = ref.watch(minDurationMsProvider);
    final minSize = ref.watch(minSizeBytesProvider);
    final formats = ref.watch(formatGroupsProvider);
    final nomedia = ref.watch(respectNomediaProvider);
    // `.nomedia` is a Linux scan rule: Android's media index already honours it.
    final linux =
        ref.watch(localAudioCatalogProvider).folderChoice ==
        FolderChoice.systemDialog;
    return SetupSection(
      title: Text(l10n.settingsLibraryBlockScan),
      children: [
        SetupValueRow(
          anchorKey: _durationKey,
          icon: KIcons.skipShort,
          title: Text(l10n.settingsLibraryMinDuration),
          value: Text(minDurationLabel(l10n, minDuration)),
          onTap: () => _pickDuration(l10n, minDuration),
        ),
        SetupValueRow(
          anchorKey: _sizeKey,
          icon: KIcons.fileSize,
          title: Text(l10n.settingsLibraryMinSize),
          value: Text(minSizeLabel(l10n, minSize)),
          onTap: () => _pickSize(l10n, minSize),
        ),
        SetupValueRow(
          anchorKey: _formatsKey,
          icon: KIcons.scanFormats,
          title: Text(l10n.settingsLibraryFormats),
          value: Text(
            formats.length == formatGroups.length
                ? l10n.settingsLibraryFormatsAll
                : l10n.settingsCountOfTotal(
                    formats.length,
                    formatGroups.length,
                  ),
          ),
          onTap: () => _pickFormats(l10n, formats),
        ),
        // The "merge same-named files" switch goes here (duplicate hiding).
        if (linux)
          KSwitchRow(
            leading: const Icon(KIcons.noMedia),
            title: Text(l10n.settingsLibraryNomedia),
            subtitle: Text(l10n.settingsLibraryNomediaDesc),
            switchLabel: l10n.settingsLibraryNomedia,
            value: nomedia,
            onChanged: (v) {
              ref.read(respectNomediaProvider.notifier).set(v);
              _applyLater(
                ScaffoldMessenger.of(context),
                l10n,
                ref.read(libraryScanCommandsProvider),
              );
            },
          ),
        SoonRow(
          icon: KIcons.watchFolders,
          title: Text(l10n.settingsLibraryWatch),
          desc: l10n.settingsLibraryWatchDesc,
        ),
      ],
    );
  }
}
