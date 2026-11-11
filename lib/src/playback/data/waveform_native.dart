import '../../rust/api/waveform.dart';
import '../domain/waveform.dart';

/// Starts a native waveform job for the file at [path]. The only place of the
/// app that talks to the waveform part of the native library. Empty levels
/// (a track under 10 ms) come back as they are; the repository decides.
WaveformRun startNativeWaveform(String path) {
  final job = WaveformJob();
  final result = waveformLevels(
    path: path,
    job: job,
  ).then((dto) => Ready(dto.levels, dto.durationMs));
  return (result: result, cancel: job.cancel);
}
