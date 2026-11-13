//! `emit(value)` of a streaming run: hands one JSON text to the host at once.
//!
//! The prelude (`js/host_prelude.js`) serialises the value and checks that it
//! is well-formed Unicode; this module enforces the size of an event, the
//! total of a run and the rate, then calls the [`Emitter`]. Error texts are
//! fixed: an emitted payload never appears in a message or a log.

use std::cell::{Cell, RefCell};
use std::rc::Rc;
use std::sync::Arc;
use std::thread;
use std::time::{Duration, Instant};

use rquickjs::{Ctx, Exception, Function, Object};

use super::quiet::quietly_catching;
use super::{HostEnv, STOP_CANCELLED, STOP_INTERNAL, STOP_TIMEOUT};
use crate::limits::{
    CANCEL_POLL, EMIT_BURST, EMIT_RATE_PER_SEC, MAX_EMIT_EVENT_BYTES, MAX_EMIT_TOTAL_BYTES,
};
use std::sync::atomic::Ordering;

/// Receives the JSON text of one event. Returns `false` when the receiving
/// side is gone; the run goes on and the event is dropped.
pub type Emitter = Arc<dyn Fn(String) -> bool + Send + Sync>;

/// Token bucket: `burst` tokens at most, refilled at `rate` per second. The
/// clock is passed in so the arithmetic is testable.
pub struct TokenBucket {
    tokens: f64,
    last: Instant,
    rate: f64,
    burst: f64,
}

impl TokenBucket {
    pub fn new(rate_per_sec: u32, burst: u32, now: Instant) -> Self {
        Self {
            tokens: f64::from(burst),
            last: now,
            rate: f64::from(rate_per_sec),
            burst: f64::from(burst),
        }
    }

    /// Takes a token, or says how long until one is available.
    pub fn take(&mut self, now: Instant) -> Result<(), Duration> {
        let elapsed = now.saturating_duration_since(self.last).as_secs_f64();
        self.last = now.max(self.last);
        self.tokens = (self.tokens + elapsed * self.rate).min(self.burst);
        if self.tokens >= 1.0 {
            self.tokens -= 1.0;
            Ok(())
        } else {
            Err(Duration::from_secs_f64((1.0 - self.tokens) / self.rate))
        }
    }
}

/// What the `emit` of one run keeps between calls.
struct EmitState {
    total: Cell<usize>,
    bucket: RefCell<TokenBucket>,
}

/// Blocks until a token is available; `Err(reason)` when the run was cancelled
/// or ran out of time meanwhile.
fn wait_for_token(env: &HostEnv, state: &EmitState) -> Result<(), u8> {
    loop {
        if env.cancel.load(Ordering::SeqCst) {
            return Err(STOP_CANCELLED);
        }
        let now = Instant::now();
        if now >= env.deadline {
            return Err(STOP_TIMEOUT);
        }
        let wait = match state.bucket.borrow_mut().take(now) {
            Ok(()) => return Ok(()),
            Err(wait) => wait,
        };
        thread::park_timeout(CANCEL_POLL.min(wait).min(env.deadline - now));
    }
}

fn emit<'js>(
    ctx: &Ctx<'js>,
    env: &HostEnv,
    state: &EmitState,
    text: String,
) -> rquickjs::Result<()> {
    env.check_alive(ctx)?;
    if text.len() > MAX_EMIT_EVENT_BYTES {
        return Err(Exception::throw_range(
            ctx,
            "emit: an event is larger than 64 KiB of JSON",
        ));
    }
    let total = state.total.get().saturating_add(text.len());
    if total > MAX_EMIT_TOTAL_BYTES {
        return Err(Exception::throw_range(
            ctx,
            "emit: the run emitted more than 8 MiB",
        ));
    }
    if let Err(why) = wait_for_token(env, state) {
        return Err(env.stop_error(ctx, why));
    }
    state.total.set(total);
    let Some(streaming) = &env.streaming else {
        return Ok(());
    };
    // Without an emitter the event is counted and dropped.
    if let Some(emitter) = streaming.emitter.clone() {
        if quietly_catching(move || emitter(text)).is_err() {
            return Err(env.stop_error(ctx, STOP_INTERNAL));
        }
    }
    Ok(())
}

/// Native `emit(text)`; registered only for streaming runs.
pub fn register<'js>(
    ctx: &Ctx<'js>,
    natives: &Object<'js>,
    env: &Rc<HostEnv>,
) -> rquickjs::Result<()> {
    let env = env.clone();
    let state = EmitState {
        total: Cell::new(0),
        bucket: RefCell::new(TokenBucket::new(
            EMIT_RATE_PER_SEC,
            EMIT_BURST,
            Instant::now(),
        )),
    };
    natives.set(
        "emit",
        Function::new(ctx.clone(), move |ctx: Ctx<'js>, text: String| {
            emit(&ctx, &env, &state, text)
        })?,
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn burst_then_rate() {
        let t0 = Instant::now();
        let mut b = TokenBucket::new(100, 50, t0);
        for _ in 0..50 {
            assert!(b.take(t0).is_ok());
        }
        let wait = b.take(t0).unwrap_err();
        assert!(wait <= Duration::from_millis(10) && wait > Duration::ZERO);
        assert!(b.take(t0 + Duration::from_millis(10)).is_ok());
        assert!(b.take(t0 + Duration::from_millis(10)).is_err());
    }

    #[test]
    fn refill_is_capped_at_the_burst() {
        let t0 = Instant::now();
        let mut b = TokenBucket::new(100, 50, t0);
        let later = t0 + Duration::from_secs(60);
        for _ in 0..50 {
            assert!(b.take(later).is_ok());
        }
        assert!(b.take(later).is_err());
    }
}
