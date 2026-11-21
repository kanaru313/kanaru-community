import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_lyrics_reader.dart';

/// The reader of the local lyrics sources. The default reads nothing (tests
/// never touch files or FFI); `runKanaru` overrides it with the real one.
final localLyricsReaderProvider = Provider<LocalLyricsReader>(
  (ref) => const NoLocalLyricsReader(),
);
