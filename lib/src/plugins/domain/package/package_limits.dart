/// Size and count caps for a plugin package. Each one applies to the declared
/// size and to what inflating really produces.
const maxPackageBytes = 5 * 1024 * 1024;
const maxZipEntries = 50;
const maxUnpackedBytes = 5 * 1024 * 1024;
const maxScriptBytes = 1024 * 1024;
const maxManifestBytes = 64 * 1024;
const maxIconBytes = 64 * 1024;
const maxIconSide = 256;
