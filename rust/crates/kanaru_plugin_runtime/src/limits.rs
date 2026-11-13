//! Every limit of the plugin runtime in one place. The plugin host API
//! document mirrors this table; a unit test pins every value.

use std::time::Duration;

/// Threads running JS at the same time.
pub const WORKER_THREADS: usize = 4;
/// Jobs that may wait for a free worker; the next one is `Busy`.
pub const QUEUE_CAPACITY: usize = 16;
/// Stack of every JS worker thread (and of the compile-check thread).
pub const THREAD_STACK_BYTES: usize = 8 * 1024 * 1024;
/// Script heap cap (QuickJS allocations).
pub const MEMORY_LIMIT_BYTES: usize = 32 * 1024 * 1024;
/// Script stack cap; far below the thread stack so QuickJS fails first, even
/// inside native recursion (`JSON.parse`, `String(nested array)`).
pub const SCRIPT_STACK_BYTES: usize = 1024 * 1024;
/// Wall time of a call that asks for none (lyrics runs).
pub const DEFAULT_WALL_TIME: Duration = Duration::from_secs(15);
/// Longest wall time a caller may ask for.
pub const MAX_WALL_TIME: Duration = Duration::from_secs(90);
/// Largest `output_json`.
pub const MAX_OUTPUT_BYTES: usize = 2 * 1024 * 1024;
/// Longest `Response.error` message and thrown-error message kept, in characters.
pub const MAX_ERROR_MESSAGE_CHARS: usize = 1000;
/// Longest thrown-error stack kept, in bytes.
pub const MAX_ERROR_STACK_BYTES: usize = 16 * 1024;
/// Largest request body a script may hand to `fetch`.
pub const MAX_FETCH_REQUEST_BODY_BYTES: usize = 256 * 1024;
/// HTTP sends (retries included) one call may use; the next `fetch` is refused.
pub const MAX_FETCH_SENDS: u32 = 10;
/// Rust-side bytes one job may hold in fetch bodies that were not read yet.
/// QuickJS' heap cap does not see Rust allocations, so this is a second cap.
pub const RUST_BYTE_BUDGET: usize = 16 * 1024 * 1024;
/// Largest text `Html.parse` accepts, UTF-8 bytes.
pub const MAX_HTML_INPUT_BYTES: usize = 4 * 1024 * 1024;
/// Parsed documents one call may hold.
pub const MAX_HTML_DOCUMENTS: usize = 8;
/// Nodes (elements, text, comments) one parsed document may have.
pub const MAX_HTML_NODES: usize = 200_000;
/// Deepest element nesting a parsed document may have, counted from the
/// document node (`<html>` is 1). Deeper pages are refused (`RangeError`):
/// html5ever takes quadratic time for deeply nested `<div>`, selector
/// matching is quadratic in the depth, and `:has` overflows the thread stack
/// at tens of thousands of levels. 512 is also Chrome's parser depth limit.
pub const MAX_HTML_DEPTH: Option<u32> = Some(512);
/// What one parsed node is charged against the Rust byte budget (the tree
/// node, its element or text data, and its handle slot), on top of the input
/// size that stands for the text and attribute data.
pub const HTML_NODE_COST_BYTES: usize = 160;
/// Longest CSS selector `select` accepts, bytes. Matching a selector with many
/// alternatives against every node cannot be interrupted, so its size is capped.
pub const MAX_HTML_SELECTOR_BYTES: usize = 1024;
/// How often a blocked host call (fetch, sleep) looks at the cancel flag.
pub const CANCEL_POLL: Duration = Duration::from_millis(50);
/// `localStorage` quota: keys plus values, UTF-8 bytes.
pub const STORAGE_QUOTA_BYTES: usize = 64 * 1024;
/// Console lines kept per call, the "N lines dropped" line included.
pub const MAX_LOG_LINES: usize = 50;
/// Longest console line kept, in characters.
pub const MAX_LOG_LINE_CHARS: usize = 500;

/// Wall time of a streaming run, and the most it may ask for.
pub const MAX_STREAM_WALL_TIME: Duration = Duration::from_secs(300);
/// Idle time a streaming run is given when its caller asks for none.
pub const DEFAULT_STREAM_IDLE: Duration = Duration::from_secs(60);
/// Longest idle time a streaming run may ask for.
pub const MAX_STREAM_IDLE: Duration = Duration::from_secs(90);
/// Shortest idle time a streaming run may ask for.
pub const MIN_STREAM_IDLE: Duration = Duration::from_secs(1);
/// Least extra time Rust waits for the app after a single wait's deadline in a
/// streaming run (the app's isolate may be busy).
pub const MIN_OP_GRACE: Duration = Duration::from_secs(1);
/// Most extra time Rust waits after a single wait's deadline in a streaming run.
pub const MAX_OP_GRACE: Duration = Duration::from_secs(9);
/// Threads running streaming JS at the same time; a second run is `Busy`.
pub const STREAM_WORKER_THREADS: usize = 1;
/// Streaming jobs that may wait for the worker.
pub const STREAM_QUEUE_CAPACITY: usize = 0;
/// Largest JSON text of one `emit` event.
pub const MAX_EMIT_EVENT_BYTES: usize = 64 * 1024;
/// Largest JSON text one run may emit in total.
pub const MAX_EMIT_TOTAL_BYTES: usize = 8 * 1024 * 1024;
/// Events per second a run may emit once its burst is used; `emit` waits.
pub const EMIT_RATE_PER_SEC: u32 = 100;
/// Events a run may emit at once before the rate applies.
pub const EMIT_BURST: u32 = 50;

/// Bytes one stream read asks the app for.
pub const MAX_STREAM_READ_BYTES: usize = 64 * 1024;
/// Raw bytes one stream may deliver in total.
pub const MAX_STREAM_BODY_BYTES: usize = 16 * 1024 * 1024;
/// Longest line `readLine()` returns, UTF-8 bytes.
pub const MAX_STREAM_LINE_BYTES: usize = 1024 * 1024;
/// Longest text `text()` of a stream returns, UTF-8 bytes.
pub const MAX_STREAM_TEXT_BYTES: usize = 4 * 1024 * 1024;
/// Streams of one run that may be open, or dead and not yet closed.
pub const MAX_OPEN_STREAMS: usize = 2;

/// The wall time of a call: the request's value capped by [`MAX_WALL_TIME`];
/// 0 means [`DEFAULT_WALL_TIME`].
pub fn effective_wall_time(requested_ms: u32) -> Duration {
    if requested_ms == 0 {
        return DEFAULT_WALL_TIME;
    }
    Duration::from_millis(u64::from(requested_ms)).min(MAX_WALL_TIME)
}

/// The wall time of a streaming run: the request's value capped by
/// [`MAX_STREAM_WALL_TIME`]; 0 means [`MAX_STREAM_WALL_TIME`].
pub fn effective_stream_wall_time(requested_ms: u32) -> Duration {
    if requested_ms == 0 {
        return MAX_STREAM_WALL_TIME;
    }
    Duration::from_millis(u64::from(requested_ms)).min(MAX_STREAM_WALL_TIME)
}

/// The idle time of a stream: the request's value clamped to
/// [`MIN_STREAM_IDLE`]..=[`MAX_STREAM_IDLE`]; 0 means [`DEFAULT_STREAM_IDLE`].
pub fn effective_stream_idle(requested_ms: u32) -> Duration {
    if requested_ms == 0 {
        return DEFAULT_STREAM_IDLE;
    }
    Duration::from_millis(u64::from(requested_ms)).clamp(MIN_STREAM_IDLE, MAX_STREAM_IDLE)
}

/// Extra time Rust waits after a single wait of `wait`: a tenth of it, between
/// [`MIN_OP_GRACE`] and [`MAX_OP_GRACE`].
pub fn op_grace(wait: Duration) -> Duration {
    (wait / 10).clamp(MIN_OP_GRACE, MAX_OP_GRACE)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn stream_times_are_capped_and_clamped() {
        assert_eq!(effective_stream_wall_time(0), Duration::from_secs(300));
        assert_eq!(effective_stream_wall_time(1000), Duration::from_secs(1));
        assert_eq!(
            effective_stream_wall_time(400_000),
            Duration::from_secs(300)
        );
        assert_eq!(
            effective_stream_wall_time(u32::MAX),
            Duration::from_secs(300)
        );
        assert_eq!(effective_stream_idle(0), Duration::from_secs(60));
        assert_eq!(effective_stream_idle(5), Duration::from_secs(1));
        assert_eq!(effective_stream_idle(30_000), Duration::from_secs(30));
        assert_eq!(effective_stream_idle(u32::MAX), Duration::from_secs(90));
    }

    #[test]
    fn grace_scales_with_the_wait() {
        assert_eq!(op_grace(Duration::from_millis(200)), Duration::from_secs(1));
        assert_eq!(op_grace(Duration::from_secs(30)), Duration::from_secs(3));
        assert_eq!(op_grace(Duration::from_secs(90)), Duration::from_secs(9));
        assert_eq!(op_grace(Duration::from_secs(300)), Duration::from_secs(9));
    }

    #[test]
    fn wall_time_is_capped_and_defaults() {
        assert_eq!(effective_wall_time(0), Duration::from_secs(15));
        assert_eq!(effective_wall_time(200), Duration::from_millis(200));
        assert_eq!(effective_wall_time(15_000), Duration::from_secs(15));
        assert_eq!(effective_wall_time(60_000), Duration::from_secs(60));
        assert_eq!(effective_wall_time(90_000), Duration::from_secs(90));
        assert_eq!(effective_wall_time(u32::MAX), Duration::from_secs(90));
    }

    #[test]
    fn script_stack_is_far_below_thread_stack() {
        const { assert!(SCRIPT_STACK_BYTES * 4 <= THREAD_STACK_BYTES) };
    }

    #[test]
    fn constants_match_the_documented_limits() {
        const MIB: usize = 1024 * 1024;
        assert_eq!(WORKER_THREADS, 4);
        assert_eq!(QUEUE_CAPACITY, 16);
        assert_eq!(THREAD_STACK_BYTES, 8 * MIB);
        assert_eq!(MEMORY_LIMIT_BYTES, 32 * MIB);
        assert_eq!(SCRIPT_STACK_BYTES, MIB);
        assert_eq!(DEFAULT_WALL_TIME, Duration::from_secs(15));
        assert_eq!(MAX_WALL_TIME, Duration::from_secs(90));
        assert_eq!(MAX_OUTPUT_BYTES, 2 * MIB);
        assert_eq!(MAX_ERROR_MESSAGE_CHARS, 1000);
        assert_eq!(MAX_ERROR_STACK_BYTES, 16 * 1024);
        assert_eq!(MAX_FETCH_REQUEST_BODY_BYTES, 256 * 1024);
        assert_eq!(MAX_FETCH_SENDS, 10);
        assert_eq!(RUST_BYTE_BUDGET, 16 * MIB);
        assert_eq!(MAX_HTML_INPUT_BYTES, 4 * MIB);
        assert_eq!(MAX_HTML_DOCUMENTS, 8);
        assert_eq!(MAX_HTML_NODES, 200_000);
        assert_eq!(MAX_HTML_DEPTH, Some(512));
        assert_eq!(HTML_NODE_COST_BYTES, 160);
        assert_eq!(MAX_HTML_SELECTOR_BYTES, 1024);
        assert_eq!(CANCEL_POLL, Duration::from_millis(50));
        assert_eq!(STORAGE_QUOTA_BYTES, 64 * 1024);
        assert_eq!(MAX_LOG_LINES, 50);
        assert_eq!(MAX_LOG_LINE_CHARS, 500);
        assert_eq!(MAX_STREAM_WALL_TIME, Duration::from_secs(300));
        assert_eq!(DEFAULT_STREAM_IDLE, Duration::from_secs(60));
        assert_eq!(MAX_STREAM_IDLE, Duration::from_secs(90));
        assert_eq!(MIN_STREAM_IDLE, Duration::from_secs(1));
        assert_eq!(MIN_OP_GRACE, Duration::from_secs(1));
        assert_eq!(MAX_OP_GRACE, Duration::from_secs(9));
        assert_eq!(STREAM_WORKER_THREADS, 1);
        assert_eq!(STREAM_QUEUE_CAPACITY, 0);
        assert_eq!(MAX_EMIT_EVENT_BYTES, 64 * 1024);
        assert_eq!(MAX_EMIT_TOTAL_BYTES, 8 * MIB);
        assert_eq!(EMIT_RATE_PER_SEC, 100);
        assert_eq!(EMIT_BURST, 50);
        assert_eq!(MAX_STREAM_READ_BYTES, 64 * 1024);
        assert_eq!(MAX_STREAM_BODY_BYTES, 16 * MIB);
        assert_eq!(MAX_STREAM_LINE_BYTES, MIB);
        assert_eq!(MAX_STREAM_TEXT_BYTES, 4 * MIB);
        assert_eq!(MAX_OPEN_STREAMS, 2);
    }
}
