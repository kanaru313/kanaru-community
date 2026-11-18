# Kanaru branding

Logo: a white "K" stem and a coral wedge on a dark squircle. Decided 2026-10-19 for the prototype app and carried over unchanged to this app (2026-11-18). This folder keeps the sources that are not already shipped as app icons, the colours, the decisions and the export recipes.

## Colours

| Role | Hex |
| --- | --- |
| Background (squircle) | `#1B1F2A` |
| Stem | `#FFFFFF` |
| Stem on a light background | `#1B1F2A` |
| Wedge | `#FFB4A2` |
| Wedge on a light background | `#D9654A` |
| App theme seed (`kanaruSeed`, `packages/kanaru_ui/lib/src/theme/kanaru_theme.dart`) | `#FFB4A2` |

The seed is the wedge colour: as a tonal-spot seed only its hue counts, and the dark primary equals it, so the app matches its logo.

## Files

| File | Role |
| --- | --- |
| `../linux/icons/hicolor/scalable/apps/io.github.kanaru313.kanaru_community.svg` | Master app icon (squircle, rx 30/128). Every PNG is exported from it. Not duplicated here |
| `../linux/icons/hicolor/symbolic/apps/io.github.kanaru313.kanaru_community-symbolic.svg` | Single-colour `currentColor` glyph for tray and MPRIS. Not duplicated here |
| `../linux/icons/hicolor/<N>x<N>/apps/…png` | hicolor PNGs 16 to 512 |
| `../linux/io.github.kanaru313.kanaru_community.desktop`, `….metainfo.xml` | Desktop entry (audio MIME types) and AppStream metainfo. Inert until packaging installs them |
| `svg/kanaru-mark-on-dark.svg` | Glyph only, for dark backgrounds (README, website, splash) |
| `svg/kanaru-mark-on-light.svg` | Glyph only, for light backgrounds (wedge `#D9654A`) |
| `svg/kanaru-avatar-square.svg` | Full-bleed square background, safe when cropped to a circle (GitHub org avatar) |
| `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | Android adaptive icon: background colour `ic_launcher_background` (`values/ic_launcher_colors.xml`), foreground `drawable/ic_launcher_foreground.xml`, themed icon `drawable/ic_launcher_monochrome.xml` |
| `android/app/src/main/res/mipmap-*/ic_launcher.png` | Legacy launcher PNGs (API < 26), the master squircle |
| `android/app/src/main/res/drawable/ic_stat_kanaru.xml` | Status-bar icon of the playback notification: the symbolic glyph |
| `packages/kanaru_ui/lib/src/widgets/kanaru_logo.dart` | In-app logo `KanaruLogo` |

Paths in the last four rows are from the repository root.

## Decisions

- **In-app logo = the app icon in fixed colours** (`KanaruLogo`), never theme-tinted: a tinted one-colour glyph looked poor. Used in the mobile sidebar head (`KIconSize.lg`), the desktop top bar centre (`KIconSize.md`), the first-run header and the Settings › About header (`KSpace.x10`, 64). Replaces the music-note `appLogo` icon of the first mockups (user, 2026-11-18). Mockups draw it with `kLogo(px)` from `mockups/_base.js`.
- `KanaruLogo` mirrors the scalable SVG. If the logo changes, update that SVG, `kanaru_logo.dart` (its test checks the SVG literals), the Android vectors, `kLogo` in the mockups and the seed note above together. The symbolic SVG changes on its own.
- The wedge is a plain fill path (no stroke), so `.ico`, `.icns` and Android exporters handle it.
- **Icon names follow the app id** `io.github.kanaru313.kanaru_community` (`linux/CMakeLists.txt` `APPLICATION_ID`): desktop shells map the window to the `.desktop` entry and its icon by that id. No window-icon call in the Linux runner.
- **Desktop entry**: `Exec=kanaru %U`; MIME types cover every extension of `audioExtensions` (`lib/src/platform/domain/local_audio_catalog.dart`) that shared-mime-info knows, with the older aliases kept for Debian 12; no `SingleMainWindow` key (Debian 12's `desktop-file-validate` rejects it; single instance comes from `GApplication`). The metainfo `<release>` follows `pubspec.yaml` `version`.
- **Android adaptive icon**: the 128 viewBox maps onto the visible 72 dp of the 108 dp canvas (scale 0.5625), glyph centre (65, 64) on (54, 54); the glyph stays inside the 66 dp safe circle. The monochrome layer is the same glyph in white (the system tints it, Android 13+).
- Not committed because they are derivable or have no target yet: 1024 px icon and avatar PNGs, raster marks, `favicon.ico`.

## Export

Run from the repository root. `rsvg-convert` comes from librsvg (Nix: `nix shell nixpkgs#librsvg`).

```bash
id=io.github.kanaru313.kanaru_community
src=packaging/linux/icons/hicolor/scalable/apps/$id.svg
for n in 16 24 32 48 64 128 256 512; do
  rsvg-convert -w $n -h $n "$src" -o packaging/linux/icons/hicolor/${n}x${n}/apps/$id.png
done
for p in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  rsvg-convert -w ${p#*:} -h ${p#*:} "$src" -o android/app/src/main/res/mipmap-${p%:*}/ic_launcher.png
done
```

Check: `desktop-file-validate packaging/linux/$id.desktop` and `appstreamcli validate --no-net packaging/linux/$id.metainfo.xml` (both in the dev shell).

## Not made yet

- Trademark and look-alike check: the glyph resembles a "previous track" button (Google Lens, TinEye, WIPO Brand DB).
- The `#1B1F2A` background sinks into dark docks and themes; consider a lighter 1 px edge.
- macOS `.icns`, multi-size Windows `.ico`.
- Wordmark "Kanaru" and a 1280x640 repository social preview image.
- Installing the desktop entry and icons (AppImage / Flatpak packaging, or a dev install target like the prototype's `make install-desktop`).
