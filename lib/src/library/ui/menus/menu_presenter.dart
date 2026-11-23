import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../../state/favorites_providers.dart';
import 'menu_action_runner.dart';
import 'menu_loaders.dart';
import 'menu_model.dart';
import 'menu_renderer.dart';

final _log = Logger('library.menu');

/// A load that takes longer than this is given up, so one stuck read cannot
/// leave every menu of the app dead.
const _loadLimit = Duration(seconds: 10);

/// A second tap while the first menu is still loading opens nothing.
bool _loading = false;

/// Loads the menu data, builds the spec and shows it on the root navigator.
/// A failure is logged and shown as a toast. The menu is shown and acted on
/// through the root navigator's context, so a tile that went away meanwhile
/// changes nothing.
Future<void> presentMenu(
  BuildContext context,
  Future<MenuSpec> Function(ProviderContainer container, MenuEnv env) build, {
  bool viaKeyboard = false,
  VoidCallback? beforeNavigate,
  TrackId? favoriteOf,
  void Function(BuildContext root, bool viaKeyboard)? onHeaderTap,
}) async {
  if (_loading) return;
  _loading = true;
  final root = Navigator.of(context, rootNavigator: true).context;
  final container = ProviderScope.containerOf(context, listen: false);
  final l10n = AppLocalizations.of(context);
  final desktop = FormFactor.of(context) == FormFactor.desktop;
  final MenuSpec spec;
  final KMenuPage page;
  ValueNotifier<bool>? live;
  ProviderSubscription<bool>? watching;
  try {
    final env = await loadMenuEnv(
      container,
      l10n,
      trash: desktop,
    ).timeout(_loadLimit);
    spec = await build(container, env).timeout(_loadLimit);
    if (!root.mounted) return;
    live = favoriteOf == null
        ? null
        : ValueNotifier(container.read(isFavoriteProvider(favoriteOf)));
    watching = favoriteOf == null
        ? null
        : container.listen<bool>(
            isFavoriteProvider(favoriteOf),
            (_, on) => live!.value = on,
          );
    page = renderMenu(
      spec,
      l10n,
      MenuActionRunner(container, root, beforeNavigate: beforeNavigate),
      onHeaderTap: onHeaderTap == null
          ? null
          : (viaKeyboard) => onHeaderTap(root, viaKeyboard),
      favorite: live,
    );
  } on ItemGoneException catch (e) {
    watching?.close();
    live?.dispose();
    _log.info('menu of an item that is gone: $e');
    if (root.mounted) showAppSnackBar(root, l10n.libraryNotFoundMessage);
    return;
  } on Object catch (e, s) {
    watching?.close();
    live?.dispose();
    _log.warning('opening a menu failed', e, s);
    if (root.mounted) showAppSnackBar(root, l10n.libraryMenuLoadFailed);
    return;
  } finally {
    _loading = false;
  }
  try {
    await showKLayeredMenu(
      root,
      root: page,
      backTooltip: l10n.libraryMenuBack,
      viaKeyboard: viaKeyboard,
    );
  } finally {
    // The live heart row stops following the favorites when the menu is gone.
    watching?.close();
    live?.dispose();
  }
}
