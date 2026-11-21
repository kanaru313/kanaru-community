#!/usr/bin/env bash
# Generates the integration-test music fixtures: short synthetic tones (never
# real music) with tags and `.lrc` sidecars, into
# integration_test/fixtures/music/. Needs ffmpeg (libmp3lame, flac, libvorbis)
# and python3 (standard library only, used to write the ID3v2 SYLT frame
# ffmpeg cannot write). The output is committed; run this only to change it.
#
# Usage: tool/make_fixtures.sh [output-dir]
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=${1:-$ROOT/integration_test/fixtures/music}
mkdir -p "$OUT"
command rm -f "$OUT"/*

# tone <file> <codec args...>: 3 s sine, mono, low rate, no metadata.
tone() {
  local file=$1
  shift
  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "sine=frequency=440:duration=3" \
    -ac 1 -ar 22050 -map_metadata -1 "$@" "$file"
}

# id3 <file> <title> [uslt <text> | sylt <ms|text;ms|text>]
# Prepends an ID3v2.4 tag (UTF-8) with TIT2, TPE1 and optionally USLT or SYLT.
id3() {
  python3 -I - "$@" <<'PY'
import struct, sys

path, title = sys.argv[1], sys.argv[2]
kind = sys.argv[3] if len(sys.argv) > 3 else None
value = sys.argv[4] if len(sys.argv) > 4 else None

def syncsafe(n):
    return bytes([(n >> 21) & 0x7F, (n >> 14) & 0x7F, (n >> 7) & 0x7F, n & 0x7F])

def frame(frame_id, data):
    return frame_id.encode() + syncsafe(len(data)) + b"\x00\x00" + data

def text_frame(frame_id, text):
    return frame(frame_id, b"\x03" + text.encode("utf-8"))

frames = [text_frame("TIT2", title), text_frame("TPE1", "Kanaru Fixture")]
if kind == "uslt":
    frames.append(frame("USLT", b"\x03eng\x00" + value.encode("utf-8")))
elif kind == "sylt":
    body = b"\x03eng\x02\x01\x00"  # UTF-8, ms timestamps, lyrics, no description
    for pair in value.split(";"):
        ms, text = pair.split("|", 1)
        body += text.encode("utf-8") + b"\x00" + struct.pack(">I", int(ms))
    frames.append(frame("SYLT", body))
payload = b"".join(frames)
tag = b"ID3\x04\x00\x00" + syncsafe(len(payload)) + payload
with open(path, "rb") as f:
    audio = f.read()
with open(path, "wb") as f:
    f.write(tag + audio)
PY
}

mp3() { tone "$1" -c:a libmp3lame -b:a 16k -write_id3v2 0; }

# MP3 with a SYLT frame (synced, tag).
mp3 "$OUT/sylt.mp3"
id3 "$OUT/sylt.mp3" "IT Sylt Tag" sylt "500|Sylt first line;1500|Sylt second line"

# MP3 with a USLT frame (plain, tag).
mp3 "$OUT/uslt.mp3"
id3 "$OUT/uslt.mp3" "IT Uslt Tag" uslt $'Uslt first line\nUslt second line'

# FLAC with LRC text in the LYRICS comment (synced, tag).
tone "$OUT/flac_lrc.flac" -c:a flac -compression_level 8 \
  -metadata title="IT Flac Lrc Tag" -metadata artist="Kanaru Fixture" \
  -metadata LYRICS=$'[00:00.50]Flac first line\n[00:01.50]Flac second line'

# OGG with plain text in the LYRICS comment (plain, tag).
tone "$OUT/ogg_plain.ogg" -c:a libvorbis -q:a -1 \
  -metadata title="IT Ogg Plain Tag" -metadata artist="Kanaru Fixture" \
  -metadata LYRICS=$'Ogg first line\nOgg second line'

# Tracks without tag lyrics, with `.lrc` sidecars.
mp3 "$OUT/lrc_utf8.mp3"
id3 "$OUT/lrc_utf8.mp3" "IT Lrc Utf8"
printf '[00:00.50]Utf8 first line\n[00:01.50]Utf8 second line - d\xc3\xa9j\xc3\xa0 vu\n' >"$OUT/lrc_utf8.lrc"

mp3 "$OUT/lrc_utf16.mp3"
id3 "$OUT/lrc_utf16.mp3" "IT Lrc Utf16"
printf '[00:00.50]Utf16 first line\n[00:01.50]Utf16 second line\n' |
  iconv -f UTF-8 -t UTF-16 >"$OUT/lrc_utf16.lrc" # UTF-16 with BOM

mp3 "$OUT/lrc_upper.mp3"
id3 "$OUT/lrc_upper.mp3" "IT Lrc Upper"
printf '[00:00.50]Upper first line\n[00:01.50]Upper second line\n' >"$OUT/lrc_upper.LRC"

# No lyrics anywhere.
mp3 "$OUT/none.mp3"
id3 "$OUT/none.mp3" "IT No Lyrics"

du -sb "$OUT" | cut -f1 | xargs -I{} echo "fixtures: {} bytes in $OUT"
