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
- MP3 only: when that concrete read fails for a reason that is not a
  transient I/O error (a frame lofty refuses fails the whole tag), the ID3v2
  tag at the start of the file is read again with symphonia
  (`lyrics_reader/id3_fallback.rs`, see below).
- FLAC, Ogg Vorbis, Opus: read the same way as `FlacFile`, `VorbisFile`,
  `OpusFile`, to reach the Vorbis comments the generic tag drops (keys lofty
  does not map). Their parse failures stay errors (see Error outcomes).
- Every other format: `probe.read()`, generic tag only.

### Plain text

Keys `Lyrics` then `UnsyncLyrics`, in the primary tag first, then in the other
tags of the file (for example an APE tag on an MP3). The first value that is
not blank and at most 1 MiB (`MAX_LYRICS_TEXT_BYTES`) wins; blank or oversized
values are skipped and the search goes on.

Fallbacks from the concrete file, used only when the generic search found no
text (same blank and size rules, the first usable value wins):

- ID3v2 (MP3, WAV, AIFF): `TXXX:LYRICS` or `TXXX:UNSYNCEDLYRICS` (description
  matched ignoring ASCII case, LYRICS first).
- Vorbis comments (FLAC, Ogg Vorbis, Opus): foobar2000's `UNSYNCED LYRICS`
  (with a space; key matched ignoring ASCII case). `LYRICS` and
  `UNSYNCEDLYRICS` are mapped by lofty and found by the generic search. An
  ID3v2 tag in front of a FLAC stream is part of the generic tags, so its
  `USLT` wins over `UNSYNCED LYRICS`.

Formats read through the generic tag only: MP4/M4A, APE, WavPack, Speex, and
the non-ID3 tags of MP3/WAV/AIFF.

### Broken ID3v2 tag (MP3)

symphonia's ID3v2 reader keeps the frames it read before a structural error
(a frame header or size that makes the rest of the tag unreadable) and skips
the remainder of the tag. A frame whose content cannot be parsed (for example
a text encoding byte it does not know) is skipped alone and later frames are
still read. From the kept frames the fallback takes: the first usable `USLT`
text, else `TXXX:LYRICS` / `TXXX:UNSYNCEDLYRICS` (description matched ignoring
ASCII case), same blank and size rules as above; and the best `SYLT` frame
through the same parser as the normal path.

The tag is read into memory at most `MAX_ID3_FALLBACK_BYTES` (16 MiB). When
the declared tag size is larger than the bytes held (a hostile header, or a
file cut short), the declared size in our copy is lowered to the bytes held,
so no size check inside the parser trusts the header.

What it does not recover: frames after the first structural error; WAV and
AIFF (ID3v2 in a chunk); a FLAC with a broken ID3v2 prefix (whole read fails,
an error); the title and other tags used by the library scan (a failed tag read
there lists the file by its name).

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
| MP3 whose concrete read fails (broken ID3 tag or file, including an empty or truncated file), not transient | The ID3v2 fallback's result: the lyrics kept before the first structural error, else `Ok(None)`. Plain text stored elsewhere (an APE tag) is not read |
| WAV/AIFF whose concrete read fails, not transient | `Ok(None)`: the whole file has no lyrics, even if plain text exists elsewhere |
| ID3v2 fallback: I/O error that is transient | `Err(MediaError::Io)` |
| Concrete read fails with a transient I/O error, or rewind fails | `Err(MediaError::Io)` |
| Sniffing the content fails | `Err`, via `errors::from_sniff_error` |
| FLAC, Ogg Vorbis, Opus, other formats: parse fails (unknown format, corrupt, empty or truncated: `Io` `UnexpectedEof`, I/O) | `Err`, via `errors::from_parse_error` |

### Known gaps

- `SYLT` is read only from ID3v2 in MP3, WAV and AIFF; none in FLAC, MP4 or APE.
- A broken ID3 tag: only the frames before the first structural error are
  recovered (MP3); WAV and AIFF recover nothing; a FLAC with a broken ID3v2
  prefix is an error. Plain text stored elsewhere in the same file (an APE
  tag) is dropped.
- A `SYLT` frame body over 4 MiB (`MAX_SYLT_FRAME_BYTES`) is skipped; below that lofty parses the whole frame before the line caps apply.

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
| `Io` | by cause | read failed; for formats other than MP3/WAV/AIFF a truncated or empty file gives `UnexpectedEof` (permanent, not `Corrupt`; on MP3/WAV/AIFF it is `Ok(None)`); also: thread could not start, or ended without a result (both transient) |
| `Panic` | no | the parser panicked (caught by `guarded`) |
| `Timeout` | yes | no answer within 10 s, or refused at once while two earlier reads are still stuck |

Threading: each call spawns its own thread (`kanaru-lyrics`, 8 MiB stack) and
waits at most 10 s (`READ_TIMEOUT`). No pool. A read blocked in the kernel
(dead network mount) cannot be cancelled; the caller gets `Timeout` and the
stuck thread is left behind, because a pool would let one dead mount block
every later read. The leak is bounded: at most `MAX_STUCK_THREADS` (2) threads
may be abandoned past their timeout at once. While that many are still
blocked, a new read returns a transient `Timeout` without spawning (retry
later). A thread that finally ends frees its slot, so a recovered mount
recovers the reader. The cap is checked when a read starts and only abandoned
threads count, so reads still within their timeout are never refused; reads
started at the same time can push the stuck count past the cap, up to the cap
plus the reads in flight. Callers should run one read at a time.

## Dart side: readers

Code: `lib/src/lyrics/` (`domain/`, `data/`, `state/`). Only `data/` imports
`lib/src/rust/` and `database/`; `domain/` is pure Dart.

- **Model** (`domain/lyrics.dart`): `Lyrics { lines, synced, origin }`,
  `LyricLine { time, text, words }`, `LyricWord { start, text }`. `origin` is
  `tag` or `lrc`. Enhanced-LRC word times (`<mm:ss.xx>`) fill `words`; views
  ignore them (karaoke later). `Lyrics.lineAt(position)` is a binary search
  (`-1` before the first line or when not synced).
- **Parser** (`lrc_parser.dart`): time tags are scanned with an index
  (`matchAsPrefix`), so a row costs linear time. Caps: at most 100 time tags
  per row (the rest stays text), 10 000 lines, 1 MiB of line text in total
  after tags repeat a line (the first line that would pass it, and every
  later one of that kind, is dropped; synced and plain lines are capped
  separately). Known meta keys only (`[Chorus: X]` stays text); `[offset:ms]`
  anywhere applies to lines and words. Plain text trims blank edges.
- **Decoder** (`lyrics_text_decoder.dart`): UTF-8 (BOM or not), UTF-16 LE/BE
  with BOM (unpaired surrogates become U+FFFD), else Latin-1; never throws.
- **Selection** (`local_lyrics_pick.dart`): synced in the preferred source,
  synced in the other, plain in the preferred, plain in the other. The
  preferred source is the `lyrics.local_first` setting (`tag` default).
- **Readers** (`data/local_lyrics_reader.dart`): `LocalLyricsReader` has
  `readTag`, `statLrc`, `readLrc`; failures are `LyricsReadFailure(kind,
  transient)`. The default `localLyricsReaderProvider` is the inert
  `NoLocalLyricsReader` (no I/O, so widget tests never touch files or FFI);
  `lib/kanaru.dart` overrides it with `NativeLocalLyricsReader`: the tag
  through `readEmbeddedLyrics` (native `Timeout` is transient, every other
  kind permanent), the `.lrc` through `dart:io`.
- **`.lrc` file read** (`lrc_file_read.dart`): regular files only (a FIFO,
  device or folder is never opened), at most 1 MiB (also checked after the
  read), stat + read under a 5 s timeout (transient failure). Only
  ENOENT, EACCES and EPERM (errno 2, 13, 1) are permanent (absent); EIO and
  every other error are transient. The read reuses the stat taken for the
  cache key (no second stat). The `.lrc` path is the folder of the resolved audio path plus
  the file name of `track_details.lrc_locator`; without a locator
  `<stem>.lrc` then `<stem>.LRC` are probed. Logs carry the track id and an
  error kind, never a path or lyrics text.
- **Facts** (`lyrics_facts_query.dart`): `watchLyricsFacts` joins `tracks`,
  `track_details` and `track_lyrics_choices` (track revision, `.lrc` locator
  and revision, off). Playability and the audio path come only from
  `PlayableResolver`.
- **Choice store** (`lyrics_choice_store.dart`): `setLyricsOff` (upsert),
  `clearLyricsChoice`.

## Dart side: loading and state

- **`LyricsLoader`** (`data/lyrics_loader.dart`, app lifetime, shaped like the
  waveform loader). Per request it stats the `.lrc`, checks the cache, then
  reads tag and `.lrc` in parallel, each source independent: a failing source
  is absent and the other still shows. Tag reads go through `TagReadQueue`:
  one in flight (the bridge keeps at most two stuck threads), the newest
  waiting request next. A waiting read is dropped (`LyricsSuperseded`) only
  when its requester cancels it (`LoadCancel`, fired when the provider is
  disposed) and no other requester shares it; a newer request never drops an
  older one. A request whose requester left after its tag read started stays
  joinable. In-flight stats are shared per path and in-flight `.lrc` reads
  per path + mtime + size (the stat used for the cache key), so a dead mount
  holds at most one stuck call each and an edited file is never served an
  older read.
  Decode + parse run in `Isolate.run` above 16 KiB (tag text or `.lrc`
  bytes), inline below. Reads with a transiently failed source are returned
  but not cached; a parse failure is deterministic, so it counts as "no
  lyrics" and is cached.
- **Cache** (`lyrics_read_cache.dart`): LRU, at most 8 entries and 4 MiB of
  lyrics text. Key: track id, resolved audio path, `tracks.revision`, stat
  (path, mtime, size) of the `.lrc` actually read, so an edited or newly added
  `.lrc` is read again. `peek(trackId)` is the synchronous newest read of a
  track (for menus).
- **Providers** (`state/`): `lyricsFactsProvider(id)` (stream),
  `localLyricsReadProvider(id)` (resolver + loader; re-runs only when the
  file identity changes, so a choice write or a setting flip reads nothing; an
  unplayable track is `LocalLyricsRead.unavailable`, no I/O; a cancelled
  request never completes, nobody consumes it), `trackLyricsProvider(id)`
  (a refresh of the same track keeps what it shows; `TrackLyrics`: `LyricsLoading`, `LyricsShown`, `LyricsNone`, `LyricsOff`,
  `LyricsUnavailable`; applies the selection order and the choice),
  `playingLyricsProvider` (lyrics of the loaded entry with its entry id; loading
  right after an entry change, never the previous track's lines) and
  `playingLyricsLineProvider` (`Provider<int>`; watches the position only for
  shown synced lyrics, uses it only when its entry id matches, notifies only
  when the index changes), `lyricsChoiceCommandsProvider` (`setOff`, `clear`,
  `toggle`). Every family and both playing providers are `isAutoDispose: true` and every future / stream
  provider has `retry: null`. The views below are what watches them.
- **Settings** (`state/lyrics_settings.dart`): `lyrics.font_scale`
  (small 0.85 / medium 1.0 / large 1.2), `lyrics.align` (start / center),
  `lyrics.auto_return` (off / 3 / 5 / 10 s), `lyrics.dim` (light 0.36 /
  strong 0.20 / off 1.0, alpha of `onSurface`), `lyrics.local_first` (tag /
  lrc). Enum names; an unknown stored name falls back to the default.
- **Table:** `track_lyrics_choices` (see
  [system-architecture-database.md](./system-architecture-database.md)).

## Dart side: views (`lyrics/ui/`)

- **Sizes** (`kanaru_ui` `KLyricsMetrics`, `KLyricsMetricsBuilder`): the only place a width becomes a lyrics size, so `lib/src/` has no
  `LayoutBuilder`. The builder also hands the viewport height (anchor room, resize re-reveal). Line size, side padding (the caller
  multiplies the size by the font scale setting):

  | Surface | Rule | Line | Side padding |
  |---|---|---|---|
  | `screen` (mobile lyrics screen) | width < 600 / >= 600 | 25 / 34 | 24 / 56 |
  | `tab` (desktop pane) | pane < 900 | 22 | 24 |
  | | pane >= 900, cover column shown | 28 | 40 |
  | | pane >= 900, cover column hidden | 36 | 12 % of the pane |
  | `card` | any | 18 (plain 15) | none (card padding 16) |

  Plain lyrics are 0.7 of the line size (`KLyricsMetrics.plainScale`), line height 1.5.
- **`LyricsBody(surface, coverColumnShown, onOpenChoice)`**: watches `playingLyricsProvider` and the four display settings and picks
  `SyncedLyricsView`, `PlainLyricsView` or `LyricsStateView`. Loading is blank. The views are keyed by (entry id, lyrics): a new track
  builds a fresh view, equal lyrics keep their scroll. `onOpenChoice` is the off state's "Lời cho bài này" button (null hides it; the
  owner of the lyrics source wires it).
- **`SyncedLyricsView`**: a lazy `SuperListView.builder` (package `super_sliver_list`, MIT): only the lines near the viewport are
  built, whatever the length (up to the 10 000-line cap; a 10 000-line file froze the app when every line was built at once, including
  after a reopen, since the audio service keeps the engine and the open lyrics screen alive). Edge fade 12 % (`ShaderMask`), no
  scrollbar. One `ref.listen(playingLyricsLineProvider)` moves one shared `ValueNotifier<int>`; each built `LyricsLine` rebuilds only
  when it becomes or stops being the current line, so a line change rebuilds two lines and a position
  tick none. Lines are all the same size and w700; the current one is `onSurface`, scaled 1.02 and has a rounded `onSurface` 8 % fill (`KRadius.md`, padding on every line so its height never changes; always, every dim level, gaps too; animated with the text colour; hover/press ink shows through), the others `onSurface` at the `lyrics.dim`
  alpha; colour and scale animate `KMotion.slow`. A timed blank line is a gap: three music notes (`LyricsGapMark`, `KIcons.songs` at `KIconSize.sm`, text colour at half strength) that pulse (opacity + slight scale) only while it is
  current and animations are on (the ticker exists only then). Pressing a line (gaps too) seeks through `playerControllerProvider` and
  makes it current at once.
- **Scrolling** (`SyncedLyricsScroll` mixin, ported from the old app): the current line is kept at 40 % of the height with the view's own
  `ScrollController` only (`getOffsetToReveal`, never `ensureVisible`; an enclosing scrollable never moves), a generation counter so an
  overlapped glide cannot clear the "scrolling itself" flag of a newer one, glide `KMotion.normal`. A line that is built is revealed
  through its render object (found in a map of the built lines, no key per line); one that is not (a seek or a return from far away)
  is reached through the list's `ListController.jumpToItem`, which jumps on estimated heights and corrects them as lines lay out,
  without building the lines between: an animated move jumps three lines short of it and glides the rest. The pill's arrow side
  comes from the line's index against the list's visible range when the line is not built. A scroll the view did not start
  (drag, wheel, trackpad, keyboard) takes over: auto-scroll stops and the shared round `KLocateButton` (bottom right, arrow toward the line, tooltip "Về dòng đang hát") shows;
  the pill, or `lyrics.auto_return` (3 / 5 / 10 s, default off) after that long without input, glides back. A resize or a font-scale
  change puts the line back without a glide; with animations off every move is a jump.
- **`PlainLyricsView`**: the note "Lời thường, không có mốc thời gian: không tự cuộn." then a lazy `ListView.builder` (a blank line is
  a break); no highlight, no seek, no auto-scroll.
- **Intro gap**: `withIntroGap` (`domain/lyrics_intro_gap.dart`, applied once in `trackLyricsProvider`) adds a gap line at 0 s to synced lyrics whose first line is sung and starts at `introGapThreshold` (5 s) or later, so it is the current line during the intro (tap seeks to 0). Plain lyrics, a first line that is already a gap and mid-song silences are untouched. Line indexes always refer to this shown list. The gap exists only in the shown lyrics (`trackLyricsProvider`): saving or editing lyrics later must read the raw lyrics, not the shown list.
- **`LyricsStateView`**: none ("Không có lời trong tệp hay tệp .lrc cạnh bài.", no button; a track with no local file reads the same)
  and off (title, then the desktop or mobile sentence, and the tonal button when `onOpenChoice` is given), both `KEmpty`.
- **`LyricsCard`** (mobile Now Playing): `surfaceContainerHigh`, radius 20, padding 16; title, short source label and an open icon;
  body = previous (dim) / current / next lines of synced lyrics at 18 (one line each, ellipsis, a gap line, or the time before the first line, is the same `LyricsGapMark` (pulsing only as the current row); the slot before the first and after the last line is empty), the first three lines of plain lyrics at 15, or one status line. One button (semantics label "title · source").
- **Labels**: `lyricsSummaryLabel(l10n, summary, short:)`; strings are the `lyrics*` keys of `lib/l10n/parts/lyrics_*.arb`.

Where they are used: the card in `MobileNowPlaying`, the lyrics screen (`screens/now_playing/ui/mobile/lyrics_screen*.dart`, see
[system-architecture-playback.md](./system-architecture-playback.md) Now Playing mobile) and the desktop `DesktopSidePane`.

## Dart side: "Lời cho bài này" and the source button (`lyrics/ui/`)

- **`showLyricsForTrack(context, id, {followsPlaying})`**: a bottom sheet (`showKSheet`, root navigator) on the mobile shell, a dialog
  of `KLayout.dialog` (`showKDialog`) on the desktop shell, chosen with `FormFactor`. With `followsPlaying` it closes once when the
  playing track changes or stops (Now Playing entry points); opened from a song menu it stays on its track. Every close goes through
  one guarded path: it pops only while the modal is the current route (a later pop waits for that), and a second request (a double tap,
  a track change during the exit animation) does nothing.
- **Body** (`LyricsForTrackBody`): header "Lời cho bài này" and a settings button (`KIcons.settings`, tooltip "Cài đặt lời bài") and a close button, a status line "Không có lời trên
  máy" only when the file has no lyrics, the two choice rows, a divider, then three dimmed inert "Sắp có" rows (find online, create
  from audio, save).
- **Choice rows** (`LyricsChoiceRows`, two single-choice icon `SelectionRow`s, marked by tint and bold title only): "Lời trong
  file" (subtitle names tag or `.lrc` and synced or plain; disabled with "Không có lời trong file" when the file has none or the read
  is loading) and "Không hiện lời" (always enabled, even while loading). Choosing reads `LyricsChoiceCommands`, closes, then writes
  exactly once: file → `clear(id)`, off → `setOff(id)`. The chosen row only closes. A failed write is logged.
- **Song menu entry** (`song_lyrics_entry_impl.dart`, `LyricsSongEntry`, implements the library's `SongLyricsEntry`; the app overrides
  `songLyricsEntryProvider` in `lib/kanaru.dart`): `label` makes the subtitle of "Nguồn lời bài" with one one-shot read of the
  song's choice (`watchLyricsFacts(...).first`): off → "Tắt lời"; else `LyricsLoader.peek` (memory cache) with `pickLocalLyrics` and
  the `lyrics.local_first` setting → the summary label; else null (never a file read, never a subscription). `open` calls
  `showLyricsForTrack(context, id, followsPlaying: false)`.
- **`LyricsSourceButton`**: watches only `playingLyricsProvider`. Icon: file lyrics = `KIcons.lyrics` in `primary`; none, loading =
  the same at 38 %; off = `KIcons.lyricsOff`. 48 dp wide on mobile, 40 on desktop. Semantics label = the summary label (the modal
  title while loading). Disabled only without a track: a track whose file cannot be read keeps the dimmed look of "none" but still opens the modal (and the right-click toggle works), the same rule as every other entry, because the song menu cannot know a file is unreadable without file I/O; the modal then says the file has no lyrics and still offers "Không hiện lời". Desktop tooltip "<label> (L)" plus the
  right-click line when `onToggle` is given; right-click (`KContextRegion`, no long press) calls `onToggle`, built by
  `toggleLyricsOfPlaying(ref)` (off ↔ automatic through `LyricsChoiceCommands.toggle`).

## Settings › Lyrics (`screens/settings/ui/lyrics/`)

Route `/settings/lyrics`: `lyricsSettingsLocation` (`lyrics/ui/lyrics_settings_link.dart`) is the single copy of the path;
`SettingsPaths.lyrics` points at it and `buildSettingsRoute` has one `GoRoute(path: 'lyrics')`. The root row "Lời bài" opens it.
The ⚙ of "Lời cho bài này" takes the router and the Now Playing panel notifier first, closes the modal through its guarded close
(nothing happens when it is already closing), closes the desktop Now Playing panel, then `go`es to the location (the page opens at
its top). It works from Now Playing (mobile route and desktop panel) and from a song menu.

`LyricsChoiceRow<T>` is one value row plus its picker (anchored on desktop, a caption as the picker header, "Mặc định" as the
subtitle of the default option); a choice is written at once through the setting's notifier.

| Section | Row | Kind | Setting |
|---|---|---|---|
| Hiển thị lời | Cỡ chữ lời, Căn lời, Tự về dòng đang hát, Làm mờ dòng không hát | picker | `lyrics.font_scale`, `lyrics.align`, `lyrics.auto_return`, `lyrics.dim` |
| | Phiên âm; Giữ màn hình sáng (mobile shell only) | coming soon | none |
| Tìm và lưu lời | Lời trong máy | picker | `lyrics.local_first` |
| | Tự tìm lời khi bài không có lời, Tự lưu lời tìm được thành .lrc | coming soon | none |
| Nguồn lời trực tuyến, Dịch lời | Thêm nguồn lời trực tuyến; dịch vụ, ngôn ngữ, dịch trước, thêm dịch vụ | coming soon | none |
| Nơi hiện lời | Lời nổi trên màn hình + Pro (desktop shell); Lời trên màn khoá và thông báo (mobile shell) | coming soon | none |
| Tạo lời từ âm thanh | Thêm plugin chuyển giọng nói (section ⓘ) | coming soon | none |
