//! Job id registry of one runtime: id -> cancel flag.
//!
//! Lifecycle of an id:
//! - `begin` registers it (not started).
//! - `cancel` before the run was claimed removes the entry, so the later
//!   `claim` finds nothing and the run is `Cancelled` at once (nothing leaks
//!   even if the caller never runs the cancelled job).
//! - `attach_events` (streaming runs) hangs the event emitter on a not yet
//!   started id; a later `claim` moves it into the guard. An id that is
//!   unknown, claimed or cancelled refuses it and the emitter is dropped (so
//!   the receiving stream closes).
//! - `claim` marks it started and hands out a guard with the flag; `cancel`
//!   now only sets the flag. Dropping the guard removes the entry, so a late
//!   cancel of a finished id does nothing.
//! - `reset` cancels every started job and forgets every unstarted id.

use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, AtomicU32, Ordering};
use std::sync::{Arc, Mutex, MutexGuard};

use crate::host::emit::Emitter;

struct Entry {
    cancel: Arc<AtomicBool>,
    started: bool,
    /// Where `emit` of a streaming run sends its events, until claimed.
    events: Option<Emitter>,
}

pub struct JobRegistry {
    next: AtomicU32,
    entries: Mutex<HashMap<u32, Entry>>,
}

/// A claimed job. Dropping it forgets the id.
pub struct JobGuard {
    registry: Arc<JobRegistry>,
    id: u32,
    cancel: Arc<AtomicBool>,
    events: Option<Emitter>,
}

impl JobRegistry {
    pub fn new() -> Self {
        Self {
            next: AtomicU32::new(1),
            entries: Mutex::new(HashMap::new()),
        }
    }

    fn lock(&self) -> MutexGuard<'_, HashMap<u32, Entry>> {
        // A poisoned lock only means another thread panicked; the map is still valid.
        self.entries.lock().unwrap_or_else(|e| e.into_inner())
    }

    pub fn begin(&self) -> u32 {
        let id = self.next.fetch_add(1, Ordering::Relaxed);
        self.lock().insert(
            id,
            Entry {
                cancel: Arc::new(AtomicBool::new(false)),
                started: false,
                events: None,
            },
        );
        id
    }

    pub fn cancel(&self, id: u32) {
        let mut entries = self.lock();
        let Some(entry) = entries.get(&id) else {
            return;
        };
        if entry.started {
            entry.cancel.store(true, Ordering::SeqCst);
        } else {
            entries.remove(&id);
        }
    }

    /// Hangs `events` on a begun, not yet claimed `id`. False (and `events`
    /// dropped, which closes its stream) for an unknown, claimed or cancelled
    /// id, or one that already has an emitter.
    pub fn attach_events(&self, id: u32, events: Emitter) -> bool {
        let mut entries = self.lock();
        match entries.get_mut(&id) {
            Some(entry) if !entry.started && entry.events.is_none() => {
                entry.events = Some(events);
                true
            }
            _ => false,
        }
    }

    /// Cancels every started job and forgets every id that has not started.
    /// Ids keep rising: an id handed out before the reset is never reused.
    pub fn reset(&self) {
        self.lock().retain(|_, entry| {
            if entry.started {
                entry.cancel.store(true, Ordering::SeqCst);
            }
            entry.started
        });
    }

    /// Marks `id` started. `None` for an unknown, cancelled or already claimed id.
    pub fn claim(self: &Arc<Self>, id: u32) -> Option<JobGuard> {
        let mut entries = self.lock();
        let entry = entries.get_mut(&id)?;
        if entry.started {
            return None;
        }
        entry.started = true;
        Some(JobGuard {
            registry: self.clone(),
            id,
            cancel: entry.cancel.clone(),
            events: entry.events.take(),
        })
    }

    #[cfg(test)]
    pub fn len(&self) -> usize {
        self.lock().len()
    }
}

impl JobGuard {
    pub fn cancel_flag(&self) -> Arc<AtomicBool> {
        self.cancel.clone()
    }

    /// The emitter attached before the claim, once.
    pub fn take_events(&mut self) -> Option<Emitter> {
        self.events.take()
    }
}

impl Drop for JobGuard {
    fn drop(&mut self) {
        self.registry.lock().remove(&self.id);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn registry() -> Arc<JobRegistry> {
        Arc::new(JobRegistry::new())
    }

    #[test]
    fn ids_rise_and_claim_gives_the_flag() {
        let r = registry();
        let (a, b) = (r.begin(), r.begin());
        assert!(b > a);
        let guard = r.claim(a).expect("claim");
        assert!(!guard.cancel_flag().load(Ordering::SeqCst));
        assert!(r.claim(a).is_none(), "an id runs once");
        drop(guard);
        assert_eq!(r.len(), 1);
    }

    #[test]
    fn cancel_before_start_removes_the_entry() {
        let r = registry();
        for _ in 0..100 {
            let id = r.begin();
            r.cancel(id);
            assert!(r.claim(id).is_none(), "a cancelled id cannot be claimed");
        }
        assert_eq!(r.len(), 0);
    }

    #[test]
    fn cancel_while_running_sets_the_flag_and_end_forgets_the_id() {
        let r = registry();
        let id = r.begin();
        let guard = r.claim(id).expect("claim");
        r.cancel(id);
        assert!(guard.cancel_flag().load(Ordering::SeqCst));
        assert_eq!(r.len(), 1);
        drop(guard);
        assert_eq!(r.len(), 0);
        r.cancel(id); // late cancel: nothing happens
        assert_eq!(r.len(), 0);
    }

    #[test]
    fn unknown_id_is_not_claimable() {
        let r = registry();
        assert!(r.claim(12345).is_none());
        r.cancel(12345);
    }

    #[test]
    fn reset_cancels_started_jobs_and_forgets_unstarted_ids() {
        let r = registry();
        let (unstarted, running) = (r.begin(), r.begin());
        let guard = r.claim(running).expect("claim");
        r.reset();
        assert!(
            guard.cancel_flag().load(Ordering::SeqCst),
            "running job cancelled"
        );
        assert!(r.claim(unstarted).is_none(), "unstarted id forgotten");
        assert_eq!(r.len(), 1, "the running entry stays until its guard drops");
        drop(guard);
        assert_eq!(r.len(), 0);
        assert!(r.begin() > running, "ids keep rising after a reset");
    }

    /// An emitter that counts how many of its clones are alive.
    fn counted_emitter() -> (Emitter, std::sync::Weak<()>) {
        let token = Arc::new(());
        let weak = Arc::downgrade(&token);
        let emitter: Emitter = Arc::new(move |_| {
            let _keep = &token;
            true
        });
        (emitter, weak)
    }

    #[test]
    fn events_attached_before_the_claim_move_into_the_guard() {
        let r = registry();
        let id = r.begin();
        let (emitter, alive) = counted_emitter();
        assert!(r.attach_events(id, emitter));
        let mut guard = r.claim(id).expect("claim");
        let taken = guard.take_events().expect("emitter");
        assert!(taken("x".into()));
        assert!(guard.take_events().is_none(), "taken once");
        drop(taken);
        drop(guard);
        assert!(alive.upgrade().is_none());
        assert_eq!(r.len(), 0);
    }

    #[test]
    fn events_attached_after_the_claim_are_refused_and_dropped() {
        let r = registry();
        let id = r.begin();
        let mut guard = r.claim(id).expect("claim");
        let (emitter, alive) = counted_emitter();
        assert!(!r.attach_events(id, emitter));
        assert!(alive.upgrade().is_none(), "the sink is dropped at once");
        assert!(guard.take_events().is_none());
    }

    #[test]
    fn events_for_an_unknown_id_are_refused_and_dropped() {
        let r = registry();
        let (emitter, alive) = counted_emitter();
        assert!(!r.attach_events(777, emitter));
        assert!(alive.upgrade().is_none());
    }

    #[test]
    fn a_second_attach_is_refused_and_keeps_the_first() {
        let r = registry();
        let id = r.begin();
        let (first, first_alive) = counted_emitter();
        let (second, second_alive) = counted_emitter();
        assert!(r.attach_events(id, first));
        assert!(!r.attach_events(id, second));
        assert!(second_alive.upgrade().is_none());
        assert!(first_alive.upgrade().is_some());
    }

    #[test]
    fn cancelling_an_unstarted_job_drops_its_events() {
        let r = registry();
        let id = r.begin();
        let (emitter, alive) = counted_emitter();
        assert!(r.attach_events(id, emitter));
        r.cancel(id);
        assert!(alive.upgrade().is_none());
        assert_eq!(r.len(), 0);
        let (late, late_alive) = counted_emitter();
        assert!(!r.attach_events(id, late));
        assert!(late_alive.upgrade().is_none());
    }

    #[test]
    fn a_run_that_ends_without_starting_leaves_no_entry_and_no_sink() {
        // What a Busy streaming run does: claim, take the emitter, then drop
        // the guard and the emitter together.
        let r = registry();
        let id = r.begin();
        let (emitter, alive) = counted_emitter();
        assert!(r.attach_events(id, emitter));
        let mut guard = r.claim(id).expect("claim");
        let taken = guard.take_events();
        drop(guard);
        drop(taken);
        assert_eq!(r.len(), 0);
        assert!(alive.upgrade().is_none());
    }

    #[test]
    fn reset_drops_the_events_of_an_unstarted_job() {
        let r = registry();
        let id = r.begin();
        let (emitter, alive) = counted_emitter();
        assert!(r.attach_events(id, emitter));
        r.reset();
        assert!(alive.upgrade().is_none());
    }
}
