//! Runs one plugin job on the calling thread: a fresh `Runtime` and `Context`
//! with the limits, the script, the call of `execute`, and the mapping of
//! every way it can end to a [`ScriptResult`] (see `result.rs`).
//!
//! `Runtime` and `Context` are `!Send`, are created and dropped here, and
//! never outlive the call. The caller must give the thread a large stack
//! ([`crate::limits::THREAD_STACK_BYTES`]).

mod result;

use std::collections::HashMap;
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::sync::atomic::{AtomicBool, AtomicU8, Ordering};
use std::sync::Arc;
use std::time::{Duration, Instant};

use rquickjs::{Context, Ctx, Runtime};

use crate::collector::Collector;
use crate::globals::{self, JsFailure, Sources};
use crate::host::budget::ByteBudget;
use crate::host::late::LateDrain;
use crate::host::{HostEnv, NoNetwork, PluginHost, STOP_CANCELLED, STOP_NONE, STOP_TIMEOUT};
use crate::limits::{MEMORY_LIMIT_BYTES, RUST_BYTE_BUDGET, SCRIPT_STACK_BYTES};
use crate::memory::LimitedAllocator;
use crate::types::{ScriptResult, ScriptStatus};

pub use result::failure;

/// Everything one run needs.
pub struct JobSpec {
    /// Id of the job in the registry (0 when the spec was not made for a request).
    pub job: u32,
    /// Identity of the plugin, copied into every call to the host.
    pub install_id: String,
    pub sources: Sources,
    pub entry: String,
    pub input_json: String,
    pub timeout: Duration,
    pub cancel: Arc<AtomicBool>,
    /// Read-only `localConfig` entries; values are JSON texts.
    pub config: Vec<(String, String)>,
    /// The plugin's stored map as JSON; empty means nothing stored.
    pub storage_json: String,
    /// Answers `fetch` and stream calls; the default has no network.
    pub host: Arc<dyn PluginHost>,
    /// Takes the futures of host calls the script stopped waiting for.
    pub(crate) late: Arc<LateDrain>,
}

impl JobSpec {
    /// Builds a spec from owned files; `None` when a file name repeats. The
    /// host has no network and late answers get a drain of their own.
    pub fn new(
        files: impl IntoIterator<Item = (String, String)>,
        entry: String,
        input_json: String,
        timeout: Duration,
        cancel: Arc<AtomicBool>,
    ) -> Option<Self> {
        let mut map = HashMap::new();
        for (name, code) in files {
            if map.insert(name, code).is_some() {
                return None;
            }
        }
        Some(Self {
            job: 0,
            install_id: String::new(),
            sources: Arc::new(map),
            entry,
            input_json,
            timeout,
            cancel,
            config: Vec::new(),
            storage_json: String::new(),
            host: Arc::new(NoNetwork),
            late: Arc::new(LateDrain::new(None)),
        })
    }
}

/// Runs the job and always returns a result: a panic inside is `Internal`.
/// Console lines and other captured data survive every failure path because
/// they live in a collector made before the guarded part.
pub fn run_job(spec: &JobSpec) -> ScriptResult {
    let collector = Collector::new();
    let mut result = catch_unwind(AssertUnwindSafe(|| run_guarded(spec, &collector)))
        .unwrap_or_else(|_| failure(ScriptStatus::Internal, "the plugin worker panicked"));
    collector.fill(&mut result);
    result
}

fn run_guarded(spec: &JobSpec, collector: &Collector) -> ScriptResult {
    if spec.cancel.load(Ordering::SeqCst) {
        return failure(ScriptStatus::Cancelled, "cancelled before start");
    }
    if !spec.sources.contains_key(&spec.entry) {
        return failure(
            ScriptStatus::Internal,
            format!("entry file {} is not in the request files", spec.entry),
        );
    }
    let deadline = Instant::now() + spec.timeout;
    let stop = Arc::new(AtomicU8::new(STOP_NONE));

    let (allocator, memory_hit) = LimitedAllocator::new(MEMORY_LIMIT_BYTES);
    let runtime = match Runtime::new_with_alloc(allocator) {
        Ok(rt) => rt,
        Err(e) => return failure(ScriptStatus::Internal, format!("runtime: {e}")),
    };
    runtime.set_max_stack_size(SCRIPT_STACK_BYTES);
    {
        let (stop, cancel) = (stop.clone(), spec.cancel.clone());
        runtime.set_interrupt_handler(Some(Box::new(move || {
            if cancel.load(Ordering::SeqCst) {
                let _ = stop.compare_exchange(
                    STOP_NONE,
                    STOP_CANCELLED,
                    Ordering::SeqCst,
                    Ordering::SeqCst,
                );
                true
            } else if Instant::now() >= deadline {
                let _ = stop.compare_exchange(
                    STOP_NONE,
                    STOP_TIMEOUT,
                    Ordering::SeqCst,
                    Ordering::SeqCst,
                );
                true
            } else {
                false
            }
        })));
    }
    let context = match Context::full(&runtime) {
        Ok(c) => c,
        Err(e) => return failure(ScriptStatus::Internal, format!("context: {e}")),
    };

    let budget_hit = Arc::new(AtomicBool::new(false));
    let host = HostEnv {
        deadline,
        cancel: spec.cancel.clone(),
        stop: stop.clone(),
        budget: ByteBudget::new(RUST_BYTE_BUDGET, budget_hit.clone()),
        collector: collector.clone(),
        host: spec.host.clone(),
        install_id: spec.install_id.clone(),
        late: spec.late.clone(),
        config: spec.config.iter().cloned().collect(),
        storage_json: spec.storage_json.clone(),
    };
    let result =
        context.with(|ctx| run_in_context(&ctx, spec, host, &stop, &memory_hit, &budget_hit));
    // Drop order matters: Context first, Runtime last, both on this thread.
    drop(context);
    drop(runtime);
    result
}

fn run_in_context<'js>(
    ctx: &Ctx<'js>,
    spec: &JobSpec,
    host: HostEnv,
    stop: &AtomicU8,
    memory_hit: &AtomicBool,
    budget_hit: &AtomicBool,
) -> ScriptResult {
    // A cancel or the deadline can land while the globals are being set up;
    // that is still a cancel or a timeout, not an internal failure.
    let setup_failed = |f: JsFailure, what: &str| {
        let stopped = stop.load(Ordering::SeqCst);
        if stopped != STOP_NONE {
            return result::map_js_failure(
                f,
                stopped,
                memory_hit.load(Ordering::SeqCst),
                spec.timeout,
            );
        }
        failure(ScriptStatus::Internal, format!("{what}: {}", f.message))
    };
    let helpers = match globals::install(ctx, spec.sources.clone(), &spec.entry, host) {
        Ok(h) => h,
        Err(e) => return setup_failed(globals::describe_error(ctx, e), "globals"),
    };
    let input = match ctx.json_parse(spec.input_json.as_str()) {
        Ok(v) => v,
        Err(e) => {
            return setup_failed(
                globals::describe_error(ctx, e),
                "input_json is not valid JSON",
            )
        }
    };

    let entry_code = &spec.sources[&spec.entry];
    let outcome = match globals::eval_classic(ctx, entry_code, &spec.entry) {
        Ok(_) => globals::call_execute(ctx, input, &helpers),
        Err(e) => Err(globals::RunFailure::Js(globals::describe_error(ctx, e))),
    };
    result::settle(
        outcome,
        stop.load(Ordering::SeqCst),
        memory_hit.load(Ordering::SeqCst),
        budget_hit.load(Ordering::SeqCst),
        spec.timeout,
    )
}
