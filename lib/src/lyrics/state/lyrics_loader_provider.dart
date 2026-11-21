import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/lyrics_loader.dart';
import 'lyrics_reader_provider.dart';

/// The app-lifetime loader (one tag read at a time, memory cache). Plain
/// provider: nothing is read until a request comes in.
final lyricsLoaderProvider = Provider<LyricsLoader>(
  (ref) => LyricsLoader(ref.watch(localLyricsReaderProvider)),
);
