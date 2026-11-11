//! Decodes a whole audio stream with symphonia into waveform levels.
//!
//! The file is untrusted: the limits in [`super::limits`] bound its sample
//! rate, channels, length and packet errors, and memory does not depend on the
//! length (see [`super::levels::LevelAccumulator`]).

use std::io::{ErrorKind, Read, Seek, SeekFrom};

use symphonia::core::codecs::audio::{AudioDecoder, AudioDecoderOptions};
use symphonia::core::errors::Error;
use symphonia::core::formats::probe::Hint;
use symphonia::core::formats::{FormatOptions, FormatReader};
use symphonia::core::io::{MediaSource, MediaSourceStream};
use symphonia::core::meta::MetadataOptions;

use crate::{Cancel, MediaError};

use super::limits::{check_shape, refuse_undecodable, ErrorBudget, Streaming};

/// What decoding one stream gave.
#[derive(Debug, PartialEq, Eq)]
pub struct Decoded {
    pub levels: Vec<u8>,
    pub frames: u64,
    pub sample_rate: u32,
}

/// Decodes `source` to levels. `ext_hint` (a file extension without the dot)
/// helps the probe and refuses formats this build cannot decode. `cancel` is
/// checked before every packet.
pub fn decode_levels(
    mut source: Box<dyn MediaSource>,
    ext_hint: Option<&str>,
    cancel: &Cancel,
) -> Result<Decoded, MediaError> {
    cancel.check()?;
    // Compressed formats the probe would take for MP3 are refused up front.
    let mut magic = [0u8; 4];
    let read_magic = source.read_exact(&mut magic).is_ok();
    refuse_undecodable(ext_hint, if read_magic { &magic } else { &[0; 4] })?;
    source.seek(SeekFrom::Start(0))?;

    let stream = MediaSourceStream::new(source, Default::default());
    let mut hint = Hint::new();
    if let Some(ext) = ext_hint {
        hint.with_extension(ext);
    }
    // Memory spent on tags is bounded by the tag sizes in the file.
    let mut format = symphonia::default::get_probe()
        .probe(
            &hint,
            stream,
            FormatOptions::default(),
            MetadataOptions::default(),
        )
        .map_err(map_error)?;
    let (mut decoder, mut track_id) = open_decoder(format.as_ref())?;

    let mut state = Streaming::new();
    let mut budget = ErrorBudget::default();
    let mut samples: Vec<f32> = Vec::new();
    loop {
        cancel.check()?;
        let packet = match format.next_packet() {
            Ok(Some(packet)) => packet,
            Ok(None) => break,
            Err(Error::ResetRequired) => {
                budget.reset()?;
                (decoder, track_id) = open_decoder(format.as_ref())?;
                continue;
            }
            // A truncated file plays up to where it ends.
            Err(Error::IoError(e)) if e.kind() == ErrorKind::UnexpectedEof => break,
            Err(e) => return Err(map_error(e)),
        };
        if packet.track_id != track_id {
            continue;
        }
        match decoder.decode(&packet) {
            Ok(buffer) => {
                budget.packet_decoded();
                let spec = buffer.spec();
                buffer.copy_to_vec_interleaved(&mut samples);
                state.push(spec.rate(), spec.channels().count(), &samples)?;
            }
            Err(Error::DecodeError(_) | Error::IoError(_)) => budget.packet_failed()?,
            Err(e) => return Err(map_error(e)),
        }
    }
    let (levels, frames, sample_rate) = state.finish()?;
    Ok(Decoded {
        levels,
        frames,
        sample_rate,
    })
}

/// A decoder for the first audio track that has one, and its id. The shape a
/// container states is checked before any decoding starts; a track that is
/// refused is skipped, and its reason is kept in case no other track works.
fn open_decoder(format: &dyn FormatReader) -> Result<(Box<dyn AudioDecoder>, u32), MediaError> {
    let mut refused = MediaError::Unsupported;
    for track in format.tracks() {
        let Some(params) = track.codec_params.as_ref().and_then(|p| p.audio()) else {
            continue;
        };
        let declared = match (params.sample_rate, params.channels.as_ref()) {
            (Some(rate), Some(channels)) => check_shape(rate, channels.count()),
            (Some(rate), None) => check_shape(rate, 1),
            _ => Ok(()),
        };
        let made = declared.and_then(|()| {
            symphonia::default::get_codecs()
                .make_audio_decoder(params, &AudioDecoderOptions::default())
                .map_err(map_error)
        });
        match made {
            Ok(decoder) => return Ok((decoder, track.id)),
            Err(e) if refused == MediaError::Unsupported => refused = e,
            Err(_) => {}
        }
    }
    Err(refused)
}

/// Maps a symphonia error to the error the cache and the caller act on.
fn map_error(error: Error) -> MediaError {
    match error {
        Error::Unsupported(_) => MediaError::Unsupported,
        Error::IoError(e) if e.kind() == ErrorKind::UnexpectedEof => {
            MediaError::Corrupt("truncated file".into())
        }
        Error::IoError(e) => MediaError::Io(e.kind()),
        Error::DecodeError(reason) | Error::LimitError(reason) => {
            MediaError::Corrupt(reason.to_string())
        }
        // `Error` is non-exhaustive: anything new is a stream we cannot read.
        _ => MediaError::Corrupt("unreadable stream".into()),
    }
}
