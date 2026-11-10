//! Cooperative cancellation and deadline, checked between steps of a job.

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::{Duration, Instant};

use crate::MediaError;

#[derive(Debug, Clone)]
pub struct Cancel {
    flag: Arc<AtomicBool>,
    deadline: Option<Instant>,
}

impl Cancel {
    pub fn new() -> Self {
        Self {
            flag: Arc::new(AtomicBool::new(false)),
            deadline: None,
        }
    }

    /// Same flag, plus a deadline `timeout` from now.
    pub fn with_timeout(&self, timeout: Duration) -> Self {
        Self {
            flag: Arc::clone(&self.flag),
            deadline: Some(Instant::now() + timeout),
        }
    }

    /// Cancels every clone sharing this flag.
    pub fn cancel(&self) {
        self.flag.store(true, Ordering::Relaxed);
    }

    /// `Cancelled` when cancelled, `Timeout` when the deadline passed.
    pub fn check(&self) -> Result<(), MediaError> {
        if self.flag.load(Ordering::Relaxed) {
            return Err(MediaError::Cancelled);
        }
        match self.deadline {
            Some(d) if Instant::now() >= d => Err(MediaError::Timeout),
            _ => Ok(()),
        }
    }
}

impl Default for Cancel {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fresh_token_passes() {
        assert_eq!(Cancel::new().check(), Ok(()));
    }

    #[test]
    fn cancel_reaches_clones() {
        let a = Cancel::new();
        let b = a.with_timeout(Duration::from_secs(60));
        a.cancel();
        assert_eq!(b.check(), Err(MediaError::Cancelled));
    }

    #[test]
    fn deadline_times_out() {
        let c = Cancel::new().with_timeout(Duration::ZERO);
        assert_eq!(c.check(), Err(MediaError::Timeout));
    }
}
