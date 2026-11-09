import '../../rust/api/native_info.dart';
import '../../rust/frb_generated.dart';

/// Loads the Rust library and returns the versions of the crates it links.
/// The only file outside `lib/src/rust/` that touches the generated bridge.
Future<String> loadNativeLibrary() async {
  await RustLib.init();
  return nativeVersions();
}
