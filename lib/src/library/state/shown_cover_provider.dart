import 'dart:io';

import 'package:flutter/foundation.dart' show immutable, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../../media/domain/cover_files.dart' show isCoverKey;
import 'browse/custom_cover_index_providers.dart';
import 'custom_cover_providers.dart';

/// Which picture an album or artist shows. The one rule behind the cover
/// widget and the page tint, so both always talk about the same image.
sealed class ShownCover {
  const ShownCover();
}

/// Not known yet (the custom cover index or the chosen file is still being
/// read). Draw a skeleton and no tint: showing the source cover first would
/// flash the wrong image and its colours.
class ShownCoverLoading extends ShownCover {
  const ShownCoverLoading();

  @override
  bool operator ==(Object other) => other is ShownCoverLoading;

  @override
  int get hashCode => 0;
}

/// The user's picture: its cover key (`ab/<32 hex>`, the key of its colours)
/// and its `full` file, which exists.
@immutable
class ShownCustomCover extends ShownCover {
  const ShownCustomCover(this.coverKey, this.file);

  final String coverKey;
  final File file;

  @override
  bool operator ==(Object other) =>
      other is ShownCustomCover &&
      other.coverKey == coverKey &&
      other.file.path == file.path;

  @override
  int get hashCode => Object.hash(coverKey, file.path);
}

/// The automatic cover: [coverKey] is the source cover, null when there is
/// none (placeholder, no tint). Also the answer when a custom cover is gone
/// from disk.
@immutable
class ShownAutomaticCover extends ShownCover {
  const ShownAutomaticCover(this.coverKey);

  final String? coverKey;

  @override
  bool operator ==(Object other) =>
      other is ShownAutomaticCover && other.coverKey == coverKey;

  @override
  int get hashCode => coverKey.hashCode;
}

/// An item and the cover its tracks give it when it has no custom one.
typedef ShownCoverQuery = ({CustomCoverItem item, String? automaticCoverKey});

enum _Index { loading, has, hasNot }

final _log = Logger('library.covers');

/// Index failures already logged, by type and message. Every tile of a list
/// sees the same failure, so each distinct one is logged once, not once per
/// tile; a different error later is still logged. Once per process on
/// purpose: index errors are rare and repeat with the same text, so the set
/// stays small, and the same error after a database reopen is not logged
/// again.
final _loggedIndexErrors = <String>{};

/// Forgets the logged failures. Tests only.
@visibleForTesting
void resetCoverIndexErrorLog() => _loggedIndexErrors.clear();

void _logIndexError(Object error, StackTrace? stack) {
  if (_loggedIndexErrors.add('${error.runtimeType}: $error')) {
    _log.warning('custom cover index failed', error, stack);
  }
}

/// The cover key of a custom cover file: the store writes it to
/// `<dir>/covers/<size>/<xx>/<hex>.jpg` (`coverRelativePath`), so the key is
/// the last directory plus the file name without its extension. Null when the
/// path does not look like that. Reading the key from the file keeps picture
/// and colours on one stream: they can never disagree, and the picture needs
/// no second (non keep-alive) stream.
@visibleForTesting
String? customCoverKeyOfFile(File file) {
  final parts = p.split(file.path);
  if (parts.length < 2) return null;
  final key =
      '${parts[parts.length - 2]}/${p.basenameWithoutExtension(file.path)}';
  return isCoverKey(key) ? key : null;
}

/// Custom cover, else the automatic [ShownCoverQuery.automaticCoverKey].
///
/// A missing or empty custom file counts as "no custom cover" here (checked
/// by `customCoverFileProvider`), so the tint and the picture both use the
/// automatic cover. A file that exists but cannot be decoded is only known
/// when the image paints: the cover widget then shows the automatic picture
/// while the tint keeps the custom cover's colours (those were extracted from
/// that very file at import, so this needs a corrupt file after a good one).
///
/// An index that failed before its first answer means "no custom cover" (logged
/// once). When the answer becomes unknown again after it was known (a cover
/// was just chosen on an open page and its file is read), the last answer
/// stays until the new one is ready, so neither the picture nor the tint
/// flashes a skeleton.
final shownCoverProvider =
    NotifierProvider.family<_ShownCoverNotifier, ShownCover, ShownCoverQuery>(
      _ShownCoverNotifier.new,
      isAutoDispose: true,
    );

class _ShownCoverNotifier extends Notifier<ShownCover> {
  _ShownCoverNotifier(this.query);

  final ShownCoverQuery query;

  /// Last answer that was not [ShownCoverLoading]. The notifier outlives
  /// rebuilds, so it survives the input changing.
  ShownCover? _settled;

  @override
  ShownCover build() {
    final resolved = _resolve();
    if (resolved is ShownCoverLoading) return _settled ?? resolved;
    return _settled = resolved;
  }

  ShownCover _resolve() {
    final item = query.item;
    final automatic = ShownAutomaticCover(query.automaticCoverKey);
    ref.listen(
      customCoverIndexProvider(item.kind)
          .select((v) => v.hasValue ? null : v.error),
      (_, error) {
        if (error != null) _logIndexError(error, null);
      },
      fireImmediately: true,
    );
    // Select the three-way answer, so a list of thousands rebuilds a tile
    // only when its own answer changes.
    final index = ref.watch(
      customCoverIndexProvider(item.kind).select((v) {
        if (v.hasValue) {
          return v.requireValue.contains(item.itemKey)
              ? _Index.has
              : _Index.hasNot;
        }
        // An error before the first answer: no custom cover (logged by the
        // `ref.listen` above).
        if (v.hasError) return _Index.hasNot;
        return _Index.loading;
      }),
    );
    switch (index) {
      case _Index.loading:
        return const ShownCoverLoading();
      case _Index.hasNot:
        return automatic;
      case _Index.has:
        final file = ref.watch(customCoverFileProvider(item));
        if (!file.hasValue && !file.hasError) return const ShownCoverLoading();
        final f = file.value;
        final k = f == null ? null : customCoverKeyOfFile(f);
        return f == null || k == null ? automatic : ShownCustomCover(k, f);
    }
  }
}
