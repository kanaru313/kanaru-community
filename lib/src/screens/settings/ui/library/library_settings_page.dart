import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../library/state/library_settings_focus.dart';
import '../../../../platform/state/media_permissions_provider.dart';
import '../../../first_run/ui/exclusions_section.dart';
import '../../../first_run/ui/library_tabs_section.dart';
import '../../../first_run/ui/music_folders_section.dart';
import '../../../first_run/ui/permissions_section.dart';
import '../../../first_run/ui/setup_mode.dart';
import '../../settings_routes.dart';
import '../settings_scaffold.dart';
import 'library_overview_card.dart';
import 'organise_block.dart';
import 'scan_rules_block.dart';

/// Settings › Library: the overview, the permissions (Android), the first-run
/// blocks for folders, exclusions and tabs, then the scan rules, the
/// arrangement and the removed tracks.
///
/// Another screen can ask for a block through [librarySettingsFocusProvider]:
/// the page scrolls to it and pulses it once (also when the page is already
/// open behind another tab).
class LibrarySettingsPage extends ConsumerStatefulWidget {
  const LibrarySettingsPage({super.key});

  @override
  ConsumerState<LibrarySettingsPage> createState() =>
      _LibrarySettingsPageState();
}

class _LibrarySettingsPageState extends ConsumerState<LibrarySettingsPage> {
  final _foldersKey = GlobalKey();
  final _foldersPulse = GlobalKey<SetupSectionPulseState>();
  Timer? _settle;

  /// Captured while mounted: `dispose` cannot use the widget ref.
  late final LibrarySettingsFocus _focus;

  /// The request waiting for its reveal; null once consumed.
  LibrarySettingsFocusRequest? _pending;

  @override
  void initState() {
    super.initState();
    _focus = ref.read(librarySettingsFocusProvider.notifier);
    ref.listenManual(librarySettingsFocusProvider, (_, request) {
      if (request != null) _show(request);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _settle?.cancel();
    // Closed before the reveal ran: drop the request, or a later unrelated
    // visit would scroll and pulse unasked. Deferred: providers must not
    // change while the tree is being torn down.
    final pending = _pending;
    final focus = _focus;
    if (pending != null) {
      Future.microtask(() {
        try {
          focus.clearIf(pending);
        } on StateError {
          // The container is gone too: nothing left to clear.
        }
      });
    }
    super.dispose();
  }

  /// Waits for the first frame and the settle time (the page may still be
  /// sliding in), then scrolls to the block and pulses it.
  void _show(LibrarySettingsFocusRequest request) {
    _settle?.cancel();
    _pending = request;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _settle = Timer(KMotion.focusSettle, () => unawaited(_reveal(request)));
    });
  }

  Future<void> _reveal(LibrarySettingsFocusRequest request) async {
    if (!mounted) return;
    final target = switch (request.anchor) {
      LibrarySettingsAnchor.folders => _foldersKey.currentContext,
    };
    if (target != null) {
      final reduce = MediaQuery.disableAnimationsOf(context);
      await Scrollable.ensureVisible(
        target,
        alignment: 0.1,
        duration: reduce ? Duration.zero : KMotion.slow,
        curve: KMotion.emphasized,
      );
    }
    if (!mounted) return;
    _foldersPulse.currentState?.pulse();
    // A newer request must survive this one finishing.
    if (_pending == request) _pending = null;
    _focus.clearIf(request);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final permission = ref.watch(mediaPermissionStateProvider).value;
    return SettingsScaffold(
      title: l10n.settingsRootLibrary,
      parentPath: SettingsPaths.root,
      children: [
        const LibraryOverviewCard(),
        if (permission != null && permission.applies)
          const PermissionsSection(mode: SetupMode.settings),
        KeyedSubtree(
          key: _foldersKey,
          child: SetupSectionPulse(
            key: _foldersPulse,
            child: const MusicFoldersSection(mode: SetupMode.settings),
          ),
        ),
        const ExclusionsSection(mode: SetupMode.settings),
        const LibraryTabsSection(mode: SetupMode.settings),
        const ScanRulesBlock(),
        const OrganiseBlock(),
        const RemovedBlock(),
      ],
    );
  }
}
