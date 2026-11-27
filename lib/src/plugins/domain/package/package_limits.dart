/// Size and count caps for a plugin package. Each one applies to the declared
/// size and to what inflating really produces.
const maxPackageBytes = 5 * 1024 * 1024;
const maxZipEntries = 50;
const maxUnpackedBytes = 5 * 1024 * 1024;
const maxScriptBytes = 1024 * 1024;
const maxManifestBytes = 64 * 1024;
const maxIconBytes = 64 * 1024;
const maxIconSide = 256;

/// Caps of a seekbar package (zip and unpacked total), and of one asset.
const maxSeekbarPackageBytes = 1024 * 1024;
const maxSeekbarUnpackedBytes = 1024 * 1024;
const maxSeekbarImageBytes = 512 * 1024;
const maxSeekbarJsonBytes = 256 * 1024;

/// Longest side of a seekbar image, in pixels.
const maxSeekbarImageSide = 2048;

/// The file name of an `assets/` entry: flat, restricted characters, and an
/// extension of a kind a seekbar plugin may carry.
final assetFileName = RegExp(r'^[A-Za-z0-9_.-]{1,64}\.(png|webp|json)$');

/// The byte cap of the asset [name] (a name that passed [assetFileName]).
int assetByteCap(String name) =>
    name.endsWith('.json') ? maxSeekbarJsonBytes : maxSeekbarImageBytes;
