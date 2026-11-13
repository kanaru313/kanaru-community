//! [`PluginRuntime`]: the plugin runtime as an instance. It owns the worker
//! threads, the job registry and the late-answers drain, so nothing here is a
//! process global: the embedding app holds one, tests make their own.
//!
//! Model: a pool of worker threads; every job creates a fresh QuickJS
//! `Runtime` + `Context` on its worker, runs, and drops both there. A streaming
//! pool (one worker, no queue) starts beside it for streaming runs.
//!
//! Both pools start eagerly in [`PluginRuntime::new`], unlike the old app's
//! lazy start. A lazy stream pool would have to start on the first streaming
//! run, which can race with `shutdown` (a thread started after the join pass
//! is never joined). The price is one idle thread with an 8 MiB stack (virtual
//! memory, committed only when used) while no streaming run happens.

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::{Duration, Instant};

use crate::compile_check;
use crate::engine::{self, failure, JobSpec};
use crate::host::late::LateDrain;
use crate::host::PluginHost;
use crate::jobs::JobRegistry;
use crate::limits;
use crate::pool::{completion, Completer, Pool, ThreadStartHook};
use crate::types::{Pending, ScriptProblem, ScriptRequest, ScriptResult, ScriptStatus};

/// The longest `shutdown` (and so `Drop`) waits for threads to end. Workers
/// stop within one cancel poll of `reset`; the bound covers a native call
/// that cannot be interrupted (a huge `JSON.parse`), whose thread is then
/// left to end on its own.
const SHUTDOWN_JOIN_BOUND: Duration = Duration::from_secs(2);

/// How many threads of each kind a runtime starts, and what they run first.
#[derive(Clone)]
pub struct RuntimeConfig {
    /// Threads running JS at the same time (`plugin-js-N`).
    pub workers: usize,
    /// Jobs that may wait for a free worker; the next one is `Busy`.
    pub queue: usize,
    /// Threads running streaming JS (`plugin-js-stream-N`); no queue.
    pub stream_workers: usize,
    /// Stack of every JS thread and of the compile-check thread. Values below
    /// [`limits::THREAD_STACK_BYTES`] are raised to it: QuickJS is told scripts
    /// may use [`limits::SCRIPT_STACK_BYTES`], so a smaller thread stack would
    /// overflow for real (SIGSEGV) on deep recursion instead of ending `Stack`.
    pub stack_bytes: usize,
    /// Called first on every thread the runtime starts, with its name
    /// (`plugin-js-N`, `plugin-js-stream-N`, `plugin-js-check`,
    /// `plugin-late-answers`), so the app can lower priorities there.
    pub on_thread_start: Option<ThreadStartHook>,
}

impl Default for RuntimeConfig {
    /// The documented limits, no start hook.
    fn default() -> Self {
        Self {
            workers: limits::WORKER_THREADS,
            queue: limits::QUEUE_CAPACITY,
            stream_workers: limits::STREAM_WORKER_THREADS,
            stack_bytes: limits::THREAD_STACK_BYTES,
            on_thread_start: None,
        }
    }
}

/// A job waiting for or running on a worker.
struct QueuedJob {
    spec: JobSpec,
    done: Completer<ScriptResult>,
}

/// Runs the job, then drops its spec. The result is sent by the returned
/// closure, which the pool calls once the worker counts as free: whoever waits
/// for the result sees the worker free and can submit again. A panic here
/// drops `done`, so the waiter resolves to `None`.
fn handle(job: QueuedJob) -> impl FnOnce() {
    let QueuedJob { spec, done } = job;
    let result = engine::run_job(&spec);
    drop(spec);
    move || done.send(result)
}

/// Finishes jobs taken out of a queue because they were cancelled.
fn complete_cancelled(jobs: Vec<QueuedJob>) {
    for job in jobs {
        let QueuedJob { spec, done } = job;
        drop(spec);
        done.send(failure(ScriptStatus::Cancelled, "cancelled before start"));
    }
}

/// Sets the cancel flag when dropped: if the future of a caller is dropped,
/// the worker stops instead of running to the deadline.
struct StopOnDrop(Arc<AtomicBool>);

impl Drop for StopOnDrop {
    fn drop(&mut self) {
        self.0.store(true, Ordering::SeqCst);
    }
}

struct Inner {
    jobs: Arc<JobRegistry>,
    /// `None` when no worker thread could start; runs then end `Internal`.
    pool: Option<Arc<Pool<QueuedJob>>>,
    stream_pool: Option<Arc<Pool<QueuedJob>>>,
    late: Arc<LateDrain>,
    on_thread_start: Option<ThreadStartHook>,
    /// The effective thread stack (see [`RuntimeConfig::stack_bytes`]).
    stack_bytes: usize,
    stopped: AtomicBool,
}

/// What `shutdown` could not finish within its bound.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct ShutdownReport {
    /// Worker threads still inside a job that could not be interrupted.
    workers_left: usize,
    /// False when the late-answers thread did not end in time.
    late_joined: bool,
}

impl Inner {
    fn pools(&self) -> impl Iterator<Item = &Arc<Pool<QueuedJob>>> {
        self.pool.iter().chain(self.stream_pool.iter())
    }

    fn cancel_job(&self, id: u32) {
        self.jobs.cancel(id);
        for pool in self.pools() {
            complete_cancelled(pool.take_where(|queued| queued.spec.job == id));
        }
    }

    fn reset(&self) {
        // Flags first: a job claimed but not queued yet starts cancelled.
        self.jobs.reset();
        for pool in self.pools() {
            complete_cancelled(pool.take_where(|_| true));
        }
    }

    fn shutdown(&self) -> ShutdownReport {
        if self.stopped.swap(true, Ordering::SeqCst) {
            return ShutdownReport {
                workers_left: 0,
                late_joined: true,
            };
        }
        // Pools first: nothing is submitted after `stop`, so every job that
        // exists is then covered by the flags `reset` sets.
        for pool in self.pools() {
            complete_cancelled(pool.stop());
        }
        self.reset();
        let deadline = Instant::now() + SHUTDOWN_JOIN_BOUND;
        let workers_left = self.pools().map(|pool| pool.join_until(deadline)).sum();
        let late_joined = self.late.close(deadline);
        ShutdownReport {
            workers_left,
            late_joined,
        }
    }

    async fn run(&self, request: ScriptRequest, host: Arc<dyn PluginHost>) -> ScriptResult {
        if self.stopped.load(Ordering::SeqCst) {
            return failure(ScriptStatus::Internal, "the plugin runtime was shut down");
        }
        let Some(guard) = self.jobs.claim(request.job) else {
            return failure(ScriptStatus::Cancelled, "unknown or cancelled job id");
        };
        if request.install_id.is_empty() {
            return failure(ScriptStatus::Internal, "install_id is empty");
        }
        let cancel = guard.cancel_flag();
        let files = request.files.into_iter().map(|f| (f.name, f.code));
        let Some(spec) = JobSpec::new(
            files,
            request.entry,
            request.input_json,
            limits::effective_wall_time(request.timeout_ms),
            cancel.clone(),
        ) else {
            return failure(ScriptStatus::Internal, "two files share a name");
        };
        let spec = JobSpec {
            job: request.job,
            install_id: request.install_id,
            config: request.config,
            storage_json: request.storage_json,
            host,
            late: self.late.clone(),
            ..spec
        };
        let Some(pool) = &self.pool else {
            return failure(ScriptStatus::Internal, "no JS worker thread could start");
        };
        let (done, waiter) = completion();
        // Jobs cancelled while waiting must not hold queue slots.
        complete_cancelled(pool.take_where(|queued| queued.spec.cancel.load(Ordering::SeqCst)));
        if pool.try_submit(QueuedJob { spec, done }).is_err() {
            drop(guard);
            return if self.stopped.load(Ordering::SeqCst) {
                failure(ScriptStatus::Internal, "the plugin runtime was shut down")
            } else {
                failure(
                    ScriptStatus::Busy,
                    "all JS workers are busy and the queue is full",
                )
            };
        }
        let _stop = StopOnDrop(cancel);
        // `guard` lives to here: the id is spent when the job ends.
        let result = waiter
            .await
            .unwrap_or_else(|| failure(ScriptStatus::Internal, "the JS worker was lost"));
        drop(guard);
        result
    }
}

/// Runs plugin scripts on its own threads. `Send + Sync`: share it behind an
/// `Arc` or a `OnceLock`. Dropping it is [`PluginRuntime::shutdown`].
pub struct PluginRuntime {
    inner: Arc<Inner>,
}

impl PluginRuntime {
    /// Starts the worker threads. Threads that cannot start are not an error
    /// here: a run then ends `Internal` with the reason.
    pub fn new(config: RuntimeConfig) -> Self {
        let stack_bytes = config.stack_bytes.max(limits::THREAD_STACK_BYTES);
        let start = |threads: usize, queue: usize, name: &str| {
            if threads == 0 {
                return None;
            }
            match Pool::start(
                threads,
                queue,
                name,
                stack_bytes,
                config.on_thread_start.clone(),
                handle,
            ) {
                Ok(pool) => Some(pool),
                Err(e) => {
                    // No logging facade in the workspace; runs say only
                    // "no JS worker thread could start", the cause goes here.
                    eprintln!("plugin runtime: cannot start thread `{name}-*`: {e}");
                    None
                }
            }
        };
        let pool = start(config.workers, config.queue, "plugin-js");
        let stream_pool = start(
            config.stream_workers,
            limits::STREAM_QUEUE_CAPACITY,
            "plugin-js-stream",
        );
        Self {
            inner: Arc::new(Inner {
                jobs: Arc::new(JobRegistry::new()),
                pool,
                stream_pool,
                late: Arc::new(LateDrain::new(config.on_thread_start.clone())),
                on_thread_start: config.on_thread_start,
                stack_bytes,
                stopped: AtomicBool::new(false),
            }),
        }
    }

    /// Registers a job and returns its id. Ids only rise, so they stay unique
    /// across hot restarts of the caller. Pass every begun id to [`Self::run`]
    /// (even a cancelled one) or call [`Self::reset`]: the registry entry is
    /// freed there.
    pub fn begin_job(&self) -> u32 {
        self.inner.jobs.begin()
    }

    /// Cancels job `id`. A job still waiting in the queue ends `Cancelled` at
    /// once and gives its slot back; a running one stops at the next
    /// interrupt; one that has not run yet is forgotten, so a later run with
    /// that id is `Cancelled`. An unknown or finished id does nothing.
    pub fn cancel_job(&self, id: u32) {
        self.inner.cancel_job(id);
    }

    /// Queues the request and resolves with its result once a worker is done.
    /// `fetch` and stream calls of the script go to `host` on the JS worker
    /// thread. Dropping the returned future cancels the job. Never panics; a
    /// full queue is `Busy`.
    pub fn run(&self, request: ScriptRequest, host: Arc<dyn PluginHost>) -> Pending<ScriptResult> {
        let inner = self.inner.clone();
        Box::pin(async move { inner.run(request, host).await })
    }

    /// Compile-only syntax check on a thread of its own (`plugin-js-check`,
    /// worker-sized stack): the parser recurses and the caller is usually a
    /// small-stack thread. `None` when `code` parses.
    pub fn check_script(&self, name: &str, code: &str) -> Option<ScriptProblem> {
        compile_check::check_script(
            name,
            code,
            self.inner.stack_bytes,
            self.inner.on_thread_start.clone(),
        )
    }

    /// Cancels every running and queued job and forgets every id that has not
    /// started. The workers stay.
    pub fn reset(&self) {
        self.inner.reset();
    }

    /// Stops the runtime: cancels everything, stops and joins the workers and
    /// the late-answers thread (each for at most a short bound), and refuses
    /// further runs. The late thread forgets, never drops, the futures it
    /// still holds. Calling it again does nothing.
    pub fn shutdown(&self) {
        let report = self.inner.shutdown();
        if report.workers_left > 0 || !report.late_joined {
            eprintln!(
                "plugin runtime shutdown: {} worker thread(s) still busy, late-answers thread joined: {}",
                report.workers_left, report.late_joined
            );
        }
    }
}

impl Drop for PluginRuntime {
    fn drop(&mut self) {
        self.shutdown();
    }
}

#[cfg(test)]
mod tests;
