import '../../../rust/api/error.dart';
import '../../domain/scan/native_failure.dart';

/// The scanner's view of a native error.
NativeFailure failureOf(NativeError e) =>
    NativeFailure(kind: e.kind.name, transient: e.transient);
