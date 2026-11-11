//! Levels from generated audio: loudness maths through the public API.

mod waveform_support;

use kanaru_media::waveform::levels::{LevelAccumulator, MAX_LEVELS, SLOT_COUNT};
use waveform_support::{sine, wav, wav_levels};

const RATE: u32 = 8000;

fn near(level: u8, want: f64, tolerance: f64) -> bool {
    (f64::from(level) - want).abs() <= tolerance
}

#[test]
fn a_steady_sine_gives_flat_full_levels() {
    let w = wav_levels(RATE, &sine(RATE, 2.0, 0.5, 1));
    assert_eq!(w.levels.len(), 200);
    assert!(
        w.levels.iter().all(|&l| near(l, 255.0, 4.0)),
        "{:?}",
        w.levels
    );
    assert_eq!(w.duration_ms, 2000);
}

#[test]
fn silence_gives_zero_levels() {
    let w = wav_levels(RATE, &vec![0.0; 16_000]);
    assert_eq!(w.levels.len(), 200);
    assert!(w.levels.iter().all(|&l| l == 0));
}

#[test]
fn a_clip_shorter_than_ten_milliseconds_has_no_levels() {
    let w = wav_levels(RATE, &sine(RATE, 0.005, 0.5, 1));
    assert!(w.levels.is_empty());
    assert_eq!(w.duration_ms, 5);
}

#[test]
fn quiet_parts_follow_the_square_root_scale() {
    let mut samples = sine(RATE, 1.0, 0.25, 1);
    samples.extend(sine(RATE, 1.0, 0.5, 1));
    let w = wav_levels(RATE, &samples);
    // Half the amplitude is a quarter of the power: sqrt(0.5) of full scale.
    assert!(
        near(w.levels[10], 255.0 * 0.5_f64.sqrt(), 5.0),
        "{}",
        w.levels[10]
    );
    assert!(near(w.levels[190], 255.0, 4.0), "{}", w.levels[190]);
}

#[test]
fn rms_counts_every_channel() {
    // Left channel only has half the power of both channels playing.
    let both = sine(RATE, 1.0, 0.5, 2);
    let left_only: Vec<f32> = both.chunks(2).flat_map(|f| [f[0], 0.0]).collect();
    let mut samples = both.clone();
    samples.extend(&left_only);
    let w = waveform_support::compute_bytes(wav(RATE, 2, &samples), Some("wav"))
        .expect("stereo wav decodes");
    assert!(near(w.levels[10], 255.0, 4.0));
    assert!(
        near(w.levels[110], 255.0 * 0.5_f64.sqrt().sqrt(), 5.0),
        "{}",
        w.levels[110]
    );
}

#[test]
fn there_are_never_more_than_a_thousand_levels() {
    let w = wav_levels(RATE, &sine(RATE, 20.0, 0.5, 1));
    assert_eq!(w.levels.len(), MAX_LEVELS);
}

#[test]
fn samples_split_across_pushes_land_in_the_same_slots() {
    let samples = sine(RATE, 3.0, 0.5, 2);
    let mut whole = LevelAccumulator::new(RATE);
    whole.push(&samples, 2);
    let mut pieces = LevelAccumulator::new(RATE);
    for piece in samples.chunks(2 * 37) {
        pieces.push(piece, 2);
    }
    assert_eq!(pieces.finish().0, whole.finish().0);
}

#[test]
fn folding_keeps_the_shape_of_the_unfolded_run() {
    // 24 windows of 10 ms into 8 slots fold twice (40 ms windows); the
    // reference has room for every window and never folds.
    let amplitude = |w: usize| 0.1 + 0.8 * (w % 8) as f32 / 8.0;
    let mut samples = Vec::new();
    for w in 0..24 {
        samples.extend(sine(RATE, 0.01, amplitude(w), 1));
    }
    let mut small = LevelAccumulator::with_slots(RATE, 8);
    small.push(&samples, 1);
    let mut reference = LevelAccumulator::with_slots(RATE, 64);
    reference.push(&samples, 1);
    let (folded, folded_frames) = small.finish();
    let (plain, plain_frames) = reference.finish();
    assert_eq!(folded_frames, plain_frames);
    assert_eq!((folded.len(), plain.len()), (6, 24));
    // A bucket is the root of the mean power of its windows, normalised to the
    // loudest bucket and square-rooted.
    let expected = |per_bucket: usize, count: usize| -> Vec<f64> {
        let rms: Vec<f64> = (0..count)
            .map(|b| {
                let power: f64 = (b * per_bucket..(b + 1) * per_bucket)
                    .map(|w| f64::from(amplitude(w)).powi(2) / 2.0)
                    .sum();
                (power / per_bucket as f64).sqrt()
            })
            .collect();
        let loudest = rms.iter().copied().fold(0.0, f64::max);
        rms.iter().map(|r| 255.0 * (r / loudest).sqrt()).collect()
    };
    for (got, want) in [(&folded, expected(4, 6)), (&plain, expected(1, 24))] {
        for (i, (&level, want)) in got.iter().zip(&want).enumerate() {
            assert!(near(level, *want, 3.0), "{i}: {level} vs {want}");
        }
    }
}

#[test]
fn a_very_long_input_merges_slots_and_keeps_its_memory_and_levels() {
    let mut acc = LevelAccumulator::new(RATE);
    // Three times the slot count of 10 ms windows: two folds.
    let window = sine(RATE, 0.01, 0.5, 1);
    for _ in 0..SLOT_COUNT * 3 {
        acc.push(&window, 1);
    }
    let (levels, frames) = acc.finish();
    assert_eq!(frames, u64::from(RATE) / 100 * (SLOT_COUNT as u64) * 3);
    assert_eq!(levels.len(), MAX_LEVELS);
    assert!(levels.iter().all(|&l| near(l, 255.0, 4.0)));
}
