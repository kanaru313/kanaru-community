import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/font_catalog.dart';
import 'font_downloads.dart';
import 'font_providers.dart';

/// Ids of the catalog fonts on disk. Kept alive for the whole run.
class InstalledCatalogFonts extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.read(fontStorageProvider).installedCatalogIds();

  /// Reads the disk again.
  void refresh() => state = ref.read(fontStorageProvider).installedCatalogIds();

  /// Deletes the downloaded font [id]; it can be downloaded again. Throws
  /// [StateError] for the font in use, one that is downloading, or an id that
  /// is not in the catalog.
  void delete(String id) {
    final font = catalogFontById(id);
    if (font == null) throw StateError('"$id" is not a catalog font');
    if (ref.read(activeFontIdProvider) == id) {
      throw StateError('"$id" is the font in use');
    }
    if (ref.read(fontDownloadsProvider).contains(id)) {
      throw StateError('"$id" is downloading');
    }
    ref.read(fontStorageProvider).deleteFont(font.asAppFont);
    refresh();
  }
}

final installedCatalogFontsProvider =
    NotifierProvider<InstalledCatalogFonts, Set<String>>(
      InstalledCatalogFonts.new,
    );
