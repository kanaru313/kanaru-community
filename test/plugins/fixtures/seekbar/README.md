# Seekbar sample fixtures

`manifests/<slug>.json` are the `plugin.json` files of
`kanaru-plugins/src/seekbar/<slug>/`, and `zips/<slug>.zip` are the built
packages of the same samples, both taken at `kanaru-plugins` commit `57a270c`
(`feat(seekbar): align samples and checker with the app's v1 rules`).
21 parse in strict mode and install; `vinyl` uses a Lottie thumb and is
refused with `UnsupportedFeature('seekbar.thumb.lottie')`.
Refresh by copying `plugin.json` and each built `plugin.zip` again and
updating the commit above.
