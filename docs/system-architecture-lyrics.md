# System architecture: lyrics

## Embedded lyrics reader

Code: `rust/crates/kanaru_media/src/tags/lyrics_reader.rs` (flow, types) and
`lyrics_sylt.rs` (ID3v2 `SYLT` frames). Plain Rust, no FFI, no threads. The
caller opens the file and passes it with an extension hint:

```rust
read_lyrics(file: File, ext_hint: Option<&str>) -> Result<Option<EmbeddedLyrics>, MediaError>
```

`EmbeddedLyrics { text: Option<String>, synced: Vec<SyncedLine> }`,
`SyncedLine { time_ms: u32, text: String }`. At least one part is present.
Per-word times are not kept.

### Flow

One lofty `Probe` per file: the extension hint picks the format to try first,
`guess_file_type` sniffs the content and decides. Options: no cover art, no
properties, `ParsingMode::BestAttempt`.

- MP3, WAV, AIFF: the probe is turned back into the reader, rewound and read
  as the concrete file type (`MpegFile`, `WavFile`, `AiffFile`). The concrete
  ID3v2 tag keeps what the generic tag drops: binary `SYLT` frames and `TXXX`
  user text.
- Every other format: `probe.read()`, generic tag only.

### Plain text

Keys `Lyrics` then `UnsyncLyrics`, in the primary tag first, then in the other
tags of the file (for example an APE tag on an MP3). The first value that is
not blank and at most 1 MiB (`MAX_LYRICS_TEXT_BYTES`) wins; blank or oversized
values are skipped and the search goes on.

`TXXX` fallback (ID3v2 only): `TXXX:LYRICS` or `TXXX:UNSYNCEDLYRICS`, used
only when the generic search found no text.

Formats read through the generic tag: FLAC, Ogg Vorbis, Opus, MP4/M4A, APE,
WavPack, and the non-ID3 tags of MP3/WAV/AIFF.

### Synced lyrics (`SYLT`)

- Only binary `SYLT` frames with millisecond timestamps and non-empty content;
  frames timed in MPEG frames are ignored.
- A frame typed as lyrics wins; otherwise the first frame typed "other" is used;
  other types (chords, events, trivia) are ignored.
- A language code that is not three ASCII letters is replaced by `xxx` before
  parsing (lofty refuses it).
- Two layouts: one entry per line, or one entry per syllable (karaoke) where an
  entry starting with `\r` or `\n` opens a new line; syllables are joined and the
  line takes the time of its first syllable. The check ignores the first entry.
- Only `\r` and `\n` are trimmed from line ends.
- Caps, applied in frame order: 10 000 lines (`MAX_SYNCED_LINES`) and 1 MiB of
  text over all lines (`MAX_SYNCED_TEXT_BYTES`). Then a stable sort by time.

### Error outcomes

| Case | Result |
|---|---|
| No lyrics, blank or oversized lyrics, no tag | `Ok(None)` |
| MP3/WAV/AIFF whose concrete read fails (broken ID3 tag or file), not transient | `Ok(None)`: the whole file has no lyrics, even if plain text exists elsewhere |
| Concrete read fails with a transient I/O error, or rewind fails | `Err(MediaError::Io)` |
| Sniffing the content fails | `Err`, via `errors::from_sniff_error` |
| Other formats: parse fails (unknown format, corrupt, truncated, I/O) | `Err`, via `errors::from_parse_error` |

### Known gaps

- foobar2000 Vorbis comment `UNSYNCED LYRICS` is not mapped by lofty, so it is
  not found.
- `SYLT` is read only from ID3v2 in MP3, WAV and AIFF; none in FLAC, MP4 or APE.
- A broken ID3 tag drops plain text stored elsewhere in the same file.
- lofty parses a whole `SYLT` frame before the caps apply.

## Bridge API

Code: `rust/crates/kanaru_bridge/src/api/lyrics.rs`; Dart binding
`lib/src/rust/api/lyrics.dart` (generated).

```rust
pub fn read_embedded_lyrics(path: String) -> Result<Option<EmbeddedLyricsDto>, NativeError>
```

Plain (async on the Dart side), not `#[frb(sync)]`. DTOs:
`EmbeddedLyricsDto { text: Option<String>, synced: Vec<SyncedLyricLineDto> }`,
`SyncedLyricLineDto { time_ms: i64, text: String }`.

The path is opened with `open_source` (regular files only), the extension
(lowercased) is the format hint. `Ok(None)` means the file has no lyrics.

| Error kind | Transient | When |
|---|---|---|
| `NotFound`, `PermissionDenied` | no | open failed |
| `Unsupported` | no | not a regular file (directory, FIFO, device) or unknown format |
| `Corrupt` | no | the content is corrupt (parse failed, or the sniff/rewind reported invalid data) |
| `Io` | by cause | read failed; a truncated or empty file gives `UnexpectedEof` (permanent, not `Corrupt`); also: thread could not start, or ended without a result (both transient) |
| `Panic` | no | the parser panicked (caught by `guarded`) |
| `Timeout` | yes | no answer within 10 s |

Threading: each call spawns its own thread (`kanaru-lyrics`, 8 MiB stack) and
waits at most 10 s (`READ_TIMEOUT`). No pool and no in-flight cap. A read
blocked in the kernel (dead network mount) cannot be cancelled; the caller gets
`Timeout` and the stuck thread is left behind. This leak is accepted: a pool
would let one dead mount block every later read.
