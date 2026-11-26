# Manifest fixtures

All 44 `plugin.json` files of the plugins repo (`kanaru313/kanaru-plugins`,
`src/<type>/<slug>/plugin.json`), copied flat as `<type>__<slug>.json`
(type = the `src/` folder: `lyrics`, `translate`, `ai-translate`, `ai-chat`,
`streaming`). `manifest_corpus_test.dart` parses every file here and expects
zero problems, so a manifest shape the parser does not know fails in CI.

Source: plugins repo HEAD `7c3129c` plus the uncommitted working-tree edit of
the five manifests that still used `"format": "secret"` (baidu-translate,
papago-translate, immersive-translate, spotify, subsonic): `secret` became
`text` in the plugins clone, nothing else changed (no version bump yet).
The app refuses `secret`, so these copies must carry `text`. Refresh the
folder from the plugins commit that lands that change (copy the 44 files
again and update the hash here).

The two `ai-chat` manifests (gemini-chat, openai-compatible-chat) are copied
from the plugins repo commit `e3d8c44` unchanged.
