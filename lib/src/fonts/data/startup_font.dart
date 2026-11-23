import 'package:logging/logging.dart';

import '../../platform/domain/app_paths.dart';
import '../../platform/domain/settings_store.dart';
import '../domain/app_font.dart';
import '../domain/builtin_fonts.dart';
import '../domain/font_setting.dart';
import 'font_registrar.dart';
import 'font_storage.dart';

final _log = Logger('startup_font');

/// The font id the app should start with. Built-in fonts are used as is;
/// catalog and custom fonts must be on disk and load into the engine. Any
/// failure (unknown id, missing files, load error) gives [defaultFontId].
/// Never throws.
Future<String> resolveStartupFont({
  required String fontId,
  required FontStorage storage,
  required FontRegistrar registrar,
  Iterable<AppFont> catalog = const [],
}) async {
  try {
    if (!isValidFontId(fontId)) return defaultFontId;
    final font = appFontFor(fontId, catalog: catalog);
    if (font.id != fontId) return defaultFontId;
    await registrar.ensureLoaded(font, storage);
    return font.id;
  } on Object catch (e, st) {
    _log.warning('Startup font "$fontId" unusable, using the default', e, st);
    return defaultFontId;
  }
}

/// Runs before the first frame: repairs leftovers of an interrupted install,
/// loads the stored font and rewrites the setting when it was unusable so the
/// settings page shows the truth. Returns the id in use. Never throws.
Future<String> prepareStartupFont({
  required AppPaths paths,
  required SettingsStore settings,
  required FontRegistrar registrar,
  FontStorage? storage,
  Iterable<AppFont> catalog = const [],
}) async {
  try {
    final store = storage ?? FontStorage(paths);
    store.repairTmpLeftovers();
    final raw = settings.read(fontSetting.key);
    var stored = defaultFontId;
    if (raw != null) {
      try {
        stored = fontSetting.decode(raw);
      } on FormatException catch (e) {
        _log.warning('Stored font is invalid, using the default: $e');
      }
    }
    final id = await resolveStartupFont(
      fontId: stored,
      storage: store,
      registrar: registrar,
      catalog: catalog,
    );
    if (raw != null && raw != id) {
      try {
        await settings.write(fontSetting.key, fontSetting.encode(id));
      } on Object catch (e, st) {
        _log.warning('Could not rewrite the font setting', e, st);
      }
    }
    return id;
  } on Object catch (e, st) {
    _log.warning('Startup font failed, using the default', e, st);
    return defaultFontId;
  }
}
