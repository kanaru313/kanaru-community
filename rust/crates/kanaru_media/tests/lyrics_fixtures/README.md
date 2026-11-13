# Lyrics reader fixtures

`lyrics_read.rs` builds MP3, WAV, FLAC and AIFF files in memory
(`mod.rs`); APE tags are written in memory onto an MP3. The four binaries
here were generated with the system `ffmpeg`, each kept tiny. Tests copy them
to a temp dir before writing tags; none holds lyrics.

```sh
S="sine=frequency=440:duration=0.5:sample_rate=44100"
ffmpeg -f lavfi -i "sine=frequency=440:duration=0.1:sample_rate=44100" -ac 2 -c:a wavpack sample.wv
ffmpeg -f lavfi -i "$S" -ac 1 -c:a libvorbis -q:a 0 sample.ogg
ffmpeg -f lavfi -i "$S" -ac 1 -c:a libopus -b:a 16k sample.opus
ffmpeg -f lavfi -i "$S" -ac 1 -c:a aac -b:a 24k -movflags +faststart sample.m4a
```

`sample.wv` is 0.1 s (not 1 s) because lossless WavPack of a sine is large.
