//! Decoding: one test per codec of the build, refusals before probing, limits
//! and cancellation.
//!
//! The fixtures in `waveform_fixtures/` are 1 s mono clips at 16 kHz: silence
//! for the first half, then a 440 Hz sine at half amplitude. Made with
//! `ffmpeg -f lavfi -i "aevalsrc='if(lt(t,0.5),0,0.5*sin(2*PI*440*t))':s=16000:d=1"
//! -ac 1 -map_metadata -1 -flags:a +bitexact -fflags +bitexact tone.<ext>` and
//! the codec flags `-c:a libmp3lame|flac|libvorbis|aac|alac|libopus`.

mod waveform_support;

use std::io::Cursor;
use std::sync::atomic::Ordering;
use std::time::Duration;

use kanaru_media::waveform::limits::{
    ErrorBudget, Streaming, MAX_CONSECUTIVE_ERRORS, MAX_TOTAL_ERRORS,
};
use kanaru_media::waveform::{compute, Waveform};
use kanaru_media::{Cancel, MediaError};
use waveform_support::{compute_bytes, fixture, sine, wav, Probe};

/// (AAC keeps its encoder delay, so up to 15% more than the clip.)
/// The silent half stays near zero and the sine half near full scale.
fn assert_tone(w: &Waveform) {
    assert!(
        (95..=115).contains(&w.levels.len()),
        "levels: {}",
        w.levels.len()
    );
    assert!(
        (950..=1150).contains(&w.duration_ms),
        "duration: {} ms",
        w.duration_ms
    );
    let n = w.levels.len();
    let (silent, loud) = (&w.levels[3..n / 2 - 8], &w.levels[n / 2 + 8..n - 8]);
    assert!(silent.iter().all(|&l| l <= 40), "silent half: {silent:?}");
    assert!(loud.iter().all(|&l| l >= 200), "loud half: {loud:?}");
}

#[test]
fn mp3_decodes() {
    assert_tone(&compute_bytes(fixture("tone.mp3"), Some("mp3")).expect("mp3"));
}

#[test]
fn flac_decodes() {
    assert_tone(&compute_bytes(fixture("tone.flac"), Some("flac")).expect("flac"));
}

#[test]
fn ogg_vorbis_decodes() {
    assert_tone(&compute_bytes(fixture("tone.ogg"), Some("ogg")).expect("ogg"));
}

#[test]
fn aac_in_mp4_decodes() {
    assert_tone(&compute_bytes(fixture("tone.aac.m4a"), Some("m4a")).expect("aac"));
}

#[test]
fn alac_in_mp4_decodes() {
    assert_tone(&compute_bytes(fixture("tone.alac.m4a"), Some("m4a")).expect("alac"));
}

#[test]
fn wav_decodes() {
    let mut samples = vec![0.0; 8000];
    samples.extend(sine(16_000, 0.5, 0.5, 1));
    let bytes = wav(16_000, 1, &samples);
    assert_tone(&compute_bytes(bytes, Some("wav")).expect("wav"));
}

#[test]
fn a_wrong_extension_is_probed_by_content() {
    assert_tone(&compute_bytes(fixture("tone.flac"), Some("mp3")).expect("flac as mp3"));
    assert_tone(&compute_bytes(fixture("tone.flac"), None).expect("flac without hint"));
}

#[test]
fn unsupported_extensions_are_refused_before_any_probing() {
    for ext in ["ape", "wv", "dsf", "dff", "aif", "AIFF", "opus"] {
        let (source, reads) = Probe::new(Cursor::new(fixture("tone.mp3")), |_| {});
        let result = compute(Box::new(source), Some(ext), &Cancel::new());
        assert_eq!(result, Err(MediaError::Unsupported), "{ext}");
        // Only the four magic bytes were read, not a probe's first buffer.
        assert_eq!(reads.load(Ordering::SeqCst), 1, "{ext}");
    }
}

#[test]
fn unsupported_magic_is_refused_whatever_the_name() {
    for magic in [b"MAC ", b"wvpk", b"DSD ", b"FRM8", b"FORM"] {
        let mut bytes = magic.to_vec();
        bytes.extend(fixture("tone.mp3"));
        assert_eq!(
            compute_bytes(bytes, Some("mp3")),
            Err(MediaError::Unsupported)
        );
    }
}

#[test]
fn opus_under_another_name_has_no_decoder() {
    assert_eq!(
        compute_bytes(fixture("tone.opus"), Some("ogg")),
        Err(MediaError::Unsupported)
    );
}

#[test]
fn garbage_is_an_error_not_a_waveform() {
    let noise: Vec<u8> = (0..4096u32)
        .map(|n| (n.wrapping_mul(2_654_435_761) >> 13) as u8)
        .collect();
    let result = compute_bytes(noise, Some("mp3"));
    assert!(
        matches!(
            result,
            Err(MediaError::Unsupported | MediaError::Corrupt(_))
        ),
        "{result:?}"
    );
    assert_eq!(
        compute_bytes(Vec::new(), Some("flac")).map_err(|e| e.is_transient()),
        Err(false)
    );
}

#[test]
fn a_truncated_file_gives_the_levels_up_to_its_end() {
    let mut bytes = fixture("tone.flac");
    bytes.truncate(bytes.len() * 6 / 10);
    let w = compute_bytes(bytes, Some("flac")).expect("truncated flac");
    assert!(!w.levels.is_empty());
    assert!(w.duration_ms < 900, "{} ms", w.duration_ms);
}

#[test]
fn a_sample_rate_outside_the_limits_is_corrupt() {
    for rate in [4_000, 1_000_000] {
        let bytes = wav(rate, 1, &sine(rate.min(48_000), 0.1, 0.5, 1));
        let result = compute_bytes(bytes, Some("wav"));
        assert!(
            matches!(result, Err(MediaError::Corrupt(_))),
            "{rate}: {result:?}"
        );
    }
}

#[test]
fn over_the_duration_limit_is_too_large() {
    let mut state = Streaming::with_max_seconds(1);
    let two_seconds = sine(8000, 2.0, 0.5, 1);
    assert_eq!(state.push(8000, 1, &two_seconds), Err(MediaError::TooLarge));
}

#[test]
fn a_stream_that_changes_shape_is_corrupt() {
    let mut state = Streaming::new();
    state
        .push(8000, 1, &sine(8000, 0.1, 0.5, 1))
        .expect("first");
    assert!(matches!(
        state.push(16_000, 1, &sine(16_000, 0.1, 0.5, 1)),
        Err(MediaError::Corrupt(_))
    ));
}

#[test]
fn packet_errors_have_a_budget() {
    let mut budget = ErrorBudget::default();
    for _ in 0..MAX_CONSECUTIVE_ERRORS {
        budget.packet_failed().expect("within the run limit");
    }
    assert!(matches!(
        budget.packet_failed(),
        Err(MediaError::Corrupt(_))
    ));

    // Failures broken up by good packets only hit the total limit.
    let mut spread = ErrorBudget::default();
    for _ in 0..MAX_TOTAL_ERRORS {
        spread.packet_failed().expect("within the total");
        spread.packet_decoded();
    }
    assert!(matches!(
        spread.packet_failed(),
        Err(MediaError::Corrupt(_))
    ));
    assert!(matches!(
        {
            let mut resets = ErrorBudget::default();
            (0..=MAX_TOTAL_ERRORS).try_for_each(|_| resets.reset())
        },
        Err(MediaError::Corrupt(_))
    ));
}

#[test]
fn a_cancelled_token_stops_before_reading() {
    let cancel = Cancel::new();
    cancel.cancel();
    let (source, reads) = Probe::new(Cursor::new(fixture("tone.flac")), |_| {});
    assert_eq!(
        compute(Box::new(source), Some("flac"), &cancel),
        Err(MediaError::Cancelled)
    );
    assert_eq!(reads.load(Ordering::SeqCst), 0);
}

#[test]
fn an_expired_deadline_is_a_timeout() {
    let cancel = Cancel::new().with_timeout(Duration::ZERO);
    let result = compute(
        Box::new(Cursor::new(fixture("tone.flac"))),
        Some("flac"),
        &cancel,
    );
    assert_eq!(result, Err(MediaError::Timeout));
}

#[test]
fn cancelling_mid_decode_stops_at_the_next_packet() {
    // 60 s of 16-bit mono at 8 kHz: about 1 MB, many reads of the stream.
    let bytes = wav(8000, 1, &sine(8000, 60.0, 0.5, 1));
    let cancel = Cancel::new();
    let trigger = cancel.clone();
    let (source, reads) = Probe::new(Cursor::new(bytes), move |n| {
        if n == 4 {
            trigger.cancel();
        }
    });
    let result = compute(Box::new(source), Some("wav"), &cancel);
    assert_eq!(result, Err(MediaError::Cancelled));
    assert!(
        reads.load(Ordering::SeqCst) < 40,
        "{}",
        reads.load(Ordering::SeqCst)
    );
}

/// Manual timing: `KANARU_WAVEFORM_FILE=/path/to/track.flac cargo test
/// --release -- --ignored --nocapture decode_time_of_a_real_file`.
#[test]
#[ignore = "needs a real file in KANARU_WAVEFORM_FILE"]
fn decode_time_of_a_real_file() {
    let Ok(path) = std::env::var("KANARU_WAVEFORM_FILE") else {
        return;
    };
    let ext = std::path::Path::new(&path)
        .extension()
        .and_then(|e| e.to_str())
        .map(str::to_owned);
    let file = std::fs::File::open(&path).expect("open file");
    let started = std::time::Instant::now();
    let w = compute(Box::new(file), ext.as_deref(), &Cancel::new()).expect("decode");
    println!(
        "{} levels, {} ms of audio, decoded in {:?}",
        w.levels.len(),
        w.duration_ms,
        started.elapsed()
    );
}
