/// The container a stream is expected to hold.
enum StreamContainer { mp3, mp4, webm }

/// A checked answer of the `stream` script. Never printed with its url or
/// headers: they can carry credentials.
class StreamAnswer {
  const StreamAnswer({
    required this.url,
    this.headers = const {},
    required this.mimeType,
    required this.container,
    this.bitrate,
    this.expiresAt,
  });

  final Uri url;
  final Map<String, String> headers;
  final String mimeType;
  final StreamContainer container;
  final int? bitrate;

  /// UTC.
  final DateTime? expiresAt;

  @override
  String toString() => 'StreamAnswer(${container.name})';
}

sealed class StreamRead {
  const StreamRead();
}

class StreamPlayable extends StreamRead {
  const StreamPlayable(this.answer);

  final StreamAnswer answer;
}

/// A well-formed answer of a type this app cannot play.
class StreamUnsupported extends StreamRead {
  const StreamUnsupported(this.mediaType);

  /// Lower case, without parameters.
  final String mediaType;
}
