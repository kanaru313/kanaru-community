// Every range of the `seekbar` block, in one place. Strict mode (install)
// refuses a value outside its range; lenient mode (load) clamps it.

const seekbarBaselineRange = (min: 0.2, max: 0.9);
const seekbarDefaultBaseline = 0.5;
const seekbarGlowRange = (min: 0.0, max: 16.0);

/// Draw box of a thumb or particle, in dp. The seek bar band is 56 high.
const seekbarSizeWidthRange = (min: 4.0, max: 64.0);
const seekbarSizeHeightRange = (min: 4.0, max: 56.0);
const seekbarAnchorRange = (min: 0.0, max: 1.0);
const seekbarDefaultAnchor = [0.5, 0.5];

const seekbarFramesRange = (min: 1, max: 64);
const seekbarFpsRange = (min: 1, max: 30);
const seekbarDefaultFps = 12;

/// Particles per second; strict needs 0 < rate, lenient raises to the floor.
const emitterRateRange = (min: 0.1, max: 20.0);

/// Lifetime in seconds; strict needs 0 < min <= max, lenient raises to the
/// floor.
const emitterLifeRange = (min: 0.05, max: 3.0);

/// Particle speed per axis, px per second.
const emitterVelocityRange = (min: -200.0, max: 200.0);

/// Particle spin, degrees per second.
const emitterSpinRange = (min: -720.0, max: 720.0);

/// `metadata.license`, in code points.
const seekbarLicenseMaxLength = 64;

/// Image file name inside the package: `assets/<name>.png|webp`.
final seekbarImageAsset = RegExp(r'^assets/[A-Za-z0-9_.-]{1,64}\.(png|webp)$');

/// Lottie file name inside the package.
final seekbarLottieAsset = RegExp(r'^assets/[A-Za-z0-9_.-]{1,64}\.json$');

final seekbarHexColor = RegExp(r'^#[0-9A-Fa-f]{6}$');
