# Fonts module

`lib/src/fonts/` owns the app font: the setting, the built-in and catalog
fonts, custom imports and the code that loads font files into the engine. The
page that drives it is `screens/settings/ui/appearance/fonts/`. DAG edge:
`fonts -> plugins, platform, foundation` (it reuses the plugin module's
`HttpFetcher` and address rules; `screens` imports `fonts`). `fonts/domain/` is
plain Dart.

## Fonts and setting

- Setting `app.font` (`fonts/domain/font_setting.dart`): a font id matching
  `^[a-zA-Z0-9_-]{1,128}$`, default `nunito`.
- Built-in: `system` (family `sans-serif`, so Linux follows the fontconfig
  default), `inter`, `nunito` (bundled assets, never on disk).
- Catalog (`domain/font_catalog.dart`): a const list in code with id, label,
  family, zip filename, size and the lowercase SHA-256 of the zip.
- Custom: ids `custom_<slug>_<8 hex of the SHA-256 of the bytes>`, so the same
  file imported twice is one font.

## Disk layout

Under `dataDir/fonts/` (`data/font_storage.dart`, every path builder rejects an
invalid id):

```
fonts/catalog/<id>/        .ttf / .otf files + licence (OFL.txt, LICENSE*)
fonts/catalog/<id>.tmp/    staging of an install in progress
fonts/custom/<id>/         one imported .ttf / .otf
fonts/custom/<id>.tmp/     staging of an import in progress
fonts/custom_fonts.json    id -> label of the custom fonts
```

The folders are the truth: a custom folder with no manifest entry gets a label
from its id; an unreadable manifest is moved aside (`.corrupt.<ms>`). Installs
and imports write to `<id>.tmp`, then rename to `<id>`. `repairTmpLeftovers()`
deletes every `*.tmp` under both folders at startup, so an interrupted install
leaves nothing. Custom store operations run one at a time.

## Startup

`prepareStartupFont` runs between `bootstrap` and `runApp`
(`data/startup_font.dart`): repair leftovers, read `app.font`, load the font
into the engine, and when it is unusable (invalid id, unknown id, files
missing, load error) fall back to `nunito` and rewrite the setting so the page
shows the truth. It never throws. Its `FontRegistrar` is passed as the
`fontLoaderProvider` override.

## Catalog download

Release `fonts-v1` of `kanaru313/kanaru-community` hosts the zips
(`catalogReleaseBase`). `FontDownloader` fetches through `HttpFetcher` (public
addresses only, body capped at twice the declared size), checks the SHA-256
**before** writing anything, unzips (a flat list of `.ttf` / `.otf` plus the
licence; `..`, absolute and drive paths, duplicate names and more than 32 MB
unpacked are refused), writes `<id>.tmp`, renames, registers the font and
keeps the licence file. Any failure removes what was written. The hashes live
in code, so a changed release asset never installs.

## Custom import

`CustomFontStore.import`: at most 20 MB (`maxCustomFontBytes`), then a header
check (`parseFontHeader`): magic `0x00010000` / `OTTO` / `true` (`ttcf`
collections refused), a table directory inside the file, `name`, `cmap` and
outlines (`glyf` + `loca` or `CFF` / `CFF2`). The label is the family name from
the `name` table, else the file name. Failures are `CustomFontError.tooLarge`
or `invalid`.

## Known limits

- Flutter cannot unload a registered font. A font loaded once (startup, a
  download or an import) stays in memory until the app restarts, even after the
  user deletes it; deleting removes the files and the choice only.
- Catalog family names shadow a system family with the same name inside the
  app. Harmless: the user asked for that name.
