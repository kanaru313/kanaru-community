import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../plugins/state/plugin_services_provider.dart';
import '../data/font_downloader.dart';
import '../domain/font_catalog.dart';
import 'font_providers.dart';
import 'installed_catalog_fonts.dart';

final _log = Logger('font_downloads');

final fontDownloaderProvider = Provider<FontDownloader>(
  (ref) => FontDownloader(
    fetcher: ref.watch(pluginFetcherProvider),
    storage: ref.watch(fontStorageProvider),
    registrar: ref.watch(fontLoaderProvider),
  ),
);

/// How a [FontDownloads.download] request ended.
enum FontDownloadResult {
  /// The font is installed.
  done,

  /// Nothing was installed; the user may try again.
  failed,

  /// The font is already downloading or installed; nothing was started.
  ignored,
}

/// Ids of the catalog fonts being downloaded. Kept alive, so a download goes
/// on when the page is closed.
class FontDownloads extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  Future<FontDownloadResult> download(CatalogFont font) async {
    if (state.contains(font.id) ||
        ref.read(installedCatalogFontsProvider).contains(font.id)) {
      return FontDownloadResult.ignored;
    }
    state = {...state, font.id};
    try {
      await ref.read(fontDownloaderProvider).download(font);
      return FontDownloadResult.done;
    } on FontDownloadException catch (e) {
      _log.warning('Download of "${font.id}" failed: ${e.message}');
      return FontDownloadResult.failed;
    } finally {
      state = {...state}..remove(font.id);
      ref.read(installedCatalogFontsProvider.notifier).refresh();
    }
  }
}

final fontDownloadsProvider = NotifierProvider<FontDownloads, Set<String>>(
  FontDownloads.new,
);
