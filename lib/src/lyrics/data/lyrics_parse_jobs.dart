import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import '../domain/lrc_parser.dart';
import '../domain/lyrics.dart';
import '../domain/lyrics_text_decoder.dart';

/// Input above this many bytes / characters is decoded and parsed off the UI
/// isolate; smaller input is cheaper inline than the isolate hand-off.
const lyricsIsolateThreshold = 16 * 1024;

/// Runs [computation] on another isolate (tests inject an inline runner to
/// count the calls).
typedef IsolateRunner = Future<R> Function<R>(
  FutureOr<R> Function() computation,
);

Future<R> runInIsolate<R>(FutureOr<R> Function() computation) =>
    Isolate.run(computation);

/// Decodes and parses `.lrc` [bytes]; large input goes through [run]. Any
/// failure is the caller's to classify.
Future<Lyrics?> parseLrcBytes(Uint8List bytes, IsolateRunner run) =>
    bytes.length > lyricsIsolateThreshold
    ? run(() => _parseBytes(bytes))
    : Future.value(_parseBytes(bytes));

/// Parses tag [text] as lyrics; large text goes through [run].
Future<Lyrics?> parseTagText(String text, IsolateRunner run) =>
    text.length > lyricsIsolateThreshold
    ? run(() => parseLyricsText(text, LyricsOrigin.tag))
    : Future.value(parseLyricsText(text, LyricsOrigin.tag));

Lyrics? _parseBytes(Uint8List bytes) =>
    parseLyricsText(decodeLyricsBytes(bytes), LyricsOrigin.lrc);
