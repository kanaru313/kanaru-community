import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/state/music_folders_providers.dart';
import '../../../library/state/scan/music_folder_editor_defaults.dart';
import '../../../library/state/scan/music_folder_editor_provider.dart';
import '../../../library/state/scan/setup_completion.dart';
import '../../../library/state/scan/scan_settings.dart';
import '../../../library/state/scan_providers.dart';
import '../../../platform/domain/media_permissions.dart';
import '../../../platform/state/media_permissions_provider.dart';
import '../../../platform/state/settings_providers.dart';
import 'appearance_section.dart';
import 'exclusions_section.dart';
import 'library_tabs_section.dart';
import 'music_folders_section.dart';
import 'permissions_section.dart';

final _log = Logger('screens.first_run');

/// Widest the setup column grows (the mockup's desktop column).
const double _columnMaxWidth = 640;

/// The one-page setup shown before the shell: permissions (Android), look,
/// library tabs, music folders and exclusions, and the arrow that ends it.
class FirstRunPage extends ConsumerStatefulWidget {
  const FirstRunPage({super.key});

  @override
  ConsumerState<FirstRunPage> createState() => _FirstRunPageState();
}

class _FirstRunPageState extends ConsumerState<FirstRunPage> {
  late final AppLifecycleListener _lifecycle;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    // Coming back from the system settings: look at the permissions again.
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          unawaited(ref.read(mediaPermissionStateProvider.notifier).refresh()),
    );
    // The defaults need audio access where the platform asks for it; the
    // editor checks, so asking on every permission change is enough.
    ref.listenManual(mediaPermissionStateProvider, (_, next) {
      if (next.hasValue) {
        unawaited(ref.read(musicFolderEditorProvider).applyFirstRunDefaults());
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    // Read everything before the first await: finishing re-runs the router
    // redirect, which disposes this page.
    final setupDone = ref.read(setupDoneProvider.notifier);
    final scan = ref.read(libraryScanCommandsProvider);
    final store = ref.read(settingsStoreProvider);
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).scanSetupWriteFailed;
    setState(() => _finishing = true);
    try {
      await completeSetup(setupDone: setupDone, scan: scan, store: store);
    } on Object catch (e, st) {
      _log.severe('finishing setup failed', e, st);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final permission =
        ref.watch(mediaPermissionStateProvider).value ??
        const MediaPermissionState.notApplicable();
    final hasFolder =
        (ref.watch(musicFoldersProvider).value ?? const []).isNotEmpty;
    // Android: only with both permissions and a folder. Elsewhere it is
    // always there and dimmed until a folder exists.
    final visible = permission.applies
        ? permission.allGranted && hasFolder
        : true;
    final inset = MediaQuery.viewPaddingOf(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _columnMaxWidth),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    KSpace.x4,
                    inset.top + KSpace.x4,
                    KSpace.x4,
                    inset.bottom + KSpace.x10 + KSpace.x10,
                  ),
                  children: [
                    _Header(
                      title: l10n.scanSetupWelcomeTitle,
                      subtitle: l10n.scanSetupWelcomeSubtitle,
                    ),
                    if (permission.applies) ...[
                      const KGap(KSpace.x5),
                      const PermissionsSection(),
                    ],
                    const KGap(KSpace.x5),
                    const AppearanceSection(),
                    const KGap(KSpace.x5),
                    const LibraryTabsSection(),
                    const KGap(KSpace.x5),
                    const MusicFoldersSection(),
                    const KGap(KSpace.x5),
                    const ExclusionsSection(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: KSpace.x4 + inset.right,
            bottom: KSpace.x4 + inset.bottom,
            child: SetupNextButton(
              visible: visible,
              semanticLabel: l10n.scanSetupNext,
              disabledTooltip: l10n.scanSetupNextDisabled,
              onPressed: hasFolder && !_finishing ? _finish : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        const KGap(KSpace.x4),
        DecoratedBox(
          decoration: ShapeDecoration(
            shape: KShape.of(KRadius.lg),
            color: scheme.primary,
          ),
          child: SizedBox.square(
            dimension: KSpace.x10,
            child: Icon(KIcons.appLogo, size: 36, color: scheme.onPrimary),
          ),
        ),
        const KGap(KSpace.x4),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall,
          ),
        ),
        const KGap(KSpace.x2),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
