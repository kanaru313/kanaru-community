import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../platform/domain/media_permissions.dart';
import '../../../platform/state/media_permissions_provider.dart';
import 'section_states.dart';

final _log = Logger('screens.first_run');

/// The permission group (Android only; the page leaves it out where
/// `MediaPermissionState.applies` is false).
class PermissionsSection extends ConsumerStatefulWidget {
  const PermissionsSection({super.key});

  @override
  ConsumerState<PermissionsSection> createState() => _PermissionsSectionState();
}

class _PermissionsSectionState extends ConsumerState<PermissionsSection> {
  bool _busy = false;

  Future<void> _ask(MediaPermissionState before) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final notifier = ref.read(mediaPermissionStateProvider.notifier);
      final after = before.anyPermanentlyDenied
          ? null
          : await notifier.request();
      if (before.anyPermanentlyDenied) {
        await notifier.openSettings();
      } else if (after != null && mounted) {
        final message = _denial(l10n, after);
        if (message != null) showAppSnackBar(context, message);
      }
    } on Object catch (e, st) {
      _log.warning('permission request failed', e, st);
      if (mounted) showAppSnackBar(context, l10n.scanSetupLoadFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Why the permission is still missing, or null when nothing is.
  String? _denial(AppLocalizations l10n, MediaPermissionState s) {
    if (s.audio != MediaPermissionStatus.granted) {
      return s.audio == MediaPermissionStatus.permanentlyDenied
          ? null
          : l10n.scanSetupAudioDenied;
    }
    return switch (s.images) {
      MediaPermissionStatus.limited => l10n.scanSetupImagesLimited,
      MediaPermissionStatus.denied => l10n.scanSetupImagesDenied,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final permission = ref.watch(mediaPermissionStateProvider);
    return SetupSection(
      card: false,
      title: Text(l10n.scanSetupPermissionsTitle),
      children: [
        permission.when(
          loading: () => const SetupNote(child: SectionSpinner()),
          error: (_, _) => SectionLoadFailed(
            onRetry: () => ref.invalidate(mediaPermissionStateProvider),
          ),
          data: (state) => _card(l10n, state),
        ),
      ],
    );
  }

  Widget _card(AppLocalizations l10n, MediaPermissionState state) {
    final blocked = state.anyPermanentlyDenied;
    final audioOk = state.audio == MediaPermissionStatus.granted;
    final label = blocked
        ? l10n.scanSetupOpenAppSettings
        : audioOk
        ? l10n.scanSetupGrantMissing
        : l10n.scanSetupGrant;
    PermissionRowData row(
      IconData icon,
      String title,
      String subtitle,
      bool granted,
    ) => PermissionRowData(
      icon: icon,
      title: Text(title),
      subtitle: Text(subtitle),
      granted: granted,
      stateLabel: granted
          ? l10n.scanSetupPermissionAllowedLabel
          : l10n.scanSetupPermissionMissingLabel,
    );
    return PermissionCard(
      collapsed: state.allGranted,
      collapsedLabel: Text(l10n.scanSetupPermissionsGranted),
      rows: [
        row(
          KIcons.musicFile,
          l10n.scanSetupPermissionAudioTitle,
          l10n.scanSetupPermissionAudioSubtitle,
          audioOk,
        ),
        row(
          KIcons.image,
          l10n.scanSetupPermissionImagesTitle,
          l10n.scanSetupPermissionImagesSubtitle,
          state.images == MediaPermissionStatus.granted,
        ),
      ],
      action: FilledButton.icon(
        onPressed: _busy ? null : () => _ask(state),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(KLayout.minTarget),
        ),
        icon: Icon(blocked ? KIcons.settings : KIcons.permission),
        label: Text(label),
      ),
      note: Text(
        blocked
            ? l10n.scanSetupPermissionBlockedNote
            : l10n.scanSetupPermissionNote,
      ),
    );
  }
}
