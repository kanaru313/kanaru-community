import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/library_keys.dart';
import '../../../media/domain/track_info.dart';
import '../../domain/music_folder.dart';
import 'menu_action_runner.dart';
import 'menu_loaders.dart';
import 'menu_model.dart';
import 'menu_origin.dart';
import 'menu_renderer.dart';

final _log = Logger('library.menu');

/// Opens the menu of a song. [origin] is the page the song is listed on.
Future<void> openSongMenu(
  BuildContext context,
  TrackInfo info, {
  MenuOrigin origin = const MenuOrigin.list(),
  bool viaKeyboard = false,
}) => _open(
  context,
  (container, env) => songMenuSpec(container, env, info, origin),
  viaKeyboard: viaKeyboard,
);

/// Opens the menu of an album. On its own page pass [MenuOrigin.own].
Future<void> openAlbumMenu(
  BuildContext context,
  AlbumKey key, {
  MenuOrigin origin = const MenuOrigin.list(),
  bool viaKeyboard = false,
}) => _open(
  context,
  (container, env) => albumMenuSpec(container, env, key, origin),
  viaKeyboard: viaKeyboard,
);

Future<void> openArtistMenu(
  BuildContext context,
  ArtistKey key, {
  MenuOrigin origin = const MenuOrigin.list(),
  bool viaKeyboard = false,
}) => _open(
  context,
  (container, env) => artistMenuSpec(container, env, key, origin),
  viaKeyboard: viaKeyboard,
);

/// [genreKey] is the stored `genre_key`, [name] the genre as written.
Future<void> openGenreMenu(
  BuildContext context, {
  required String genreKey,
  required String name,
  MenuOrigin origin = const MenuOrigin.list(),
  bool viaKeyboard = false,
}) => _open(
  context,
  (container, env) => genreMenuSpec(container, env, genreKey, name, origin),
  viaKeyboard: viaKeyboard,
);

/// A null [code] is the group of songs without a language.
Future<void> openLanguageMenu(
  BuildContext context,
  String? code, {
  MenuOrigin origin = const MenuOrigin.list(),
  bool viaKeyboard = false,
}) => _open(
  context,
  (container, env) => languageMenuSpec(container, env, code, origin),
  viaKeyboard: viaKeyboard,
);

/// [key] is the folder's path inside [folder] (`''` = the music folder);
/// [subfolders] how many folders it holds; [flat] the flat list's folder.
Future<void> openFolderMenu(
  BuildContext context, {
  required MusicFolder folder,
  required String key,
  required String name,
  required int subfolders,
  bool flat = false,
  MenuOrigin origin = const MenuOrigin.list(),
  bool viaKeyboard = false,
}) => _open(
  context,
  (container, env) => folderMenuSpec(
    container,
    env,
    folder: folder,
    key: key,
    name: name,
    subfolders: subfolders,
    flat: flat,
    origin: origin,
  ),
  viaKeyboard: viaKeyboard,
);

/// Opens the menu of the selection panel.
Future<void> openSelectionMenu(
  BuildContext context, {
  bool viaKeyboard = false,
}) => _open(context, selectionMenuSpec, viaKeyboard: viaKeyboard);

/// A load that takes longer than this is given up, so one stuck read cannot
/// leave every menu of the app dead.
const _loadLimit = Duration(seconds: 10);

/// A second tap while the first menu is still loading opens nothing.
bool _loading = false;

/// Loads the menu data, builds the spec and shows it on the root navigator.
/// A failure is logged and shown as a toast. The menu is shown and acted on
/// through the root navigator's context, so a tile that went away meanwhile
/// changes nothing.
Future<void> _open(
  BuildContext context,
  Future<MenuSpec> Function(ProviderContainer container, MenuEnv env) build, {
  bool viaKeyboard = false,
}) async {
  if (_loading) return;
  _loading = true;
  final root = Navigator.of(context, rootNavigator: true).context;
  final container = ProviderScope.containerOf(context, listen: false);
  final l10n = AppLocalizations.of(context);
  final desktop = FormFactor.of(context) == FormFactor.desktop;
  final MenuSpec spec;
  final KMenuPage page;
  try {
    final env = await loadMenuEnv(
      container,
      l10n,
      trash: desktop,
    ).timeout(_loadLimit);
    spec = await build(container, env).timeout(_loadLimit);
    if (!root.mounted) return;
    page = renderMenu(spec, l10n, MenuActionRunner(container, root));
  } on Object catch (e, s) {
    _log.warning('opening a menu failed', e, s);
    if (root.mounted) showAppSnackBar(root, l10n.libraryMenuLoadFailed);
    return;
  } finally {
    _loading = false;
  }
  await showKLayeredMenu(
    root,
    root: page,
    backTooltip: l10n.libraryMenuBack,
    viaKeyboard: viaKeyboard,
  );
}
