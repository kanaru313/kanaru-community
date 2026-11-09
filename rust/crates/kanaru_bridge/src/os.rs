//! Operating-system calls. The only file in the workspace (besides generated
//! code) allowed to contain `unsafe`.

/// Nice value of background workers: yields CPU to the UI and the audio thread.
#[cfg(any(target_os = "linux", target_os = "android"))]
const BACKGROUND_NICE: libc::c_int = 10;

/// Lowers the priority of the calling thread only (Linux and Android keep a
/// nice value per thread). Failure is ignored: the work just runs at normal
/// priority. No-op on other systems.
#[cfg(any(target_os = "linux", target_os = "android"))]
pub fn lower_current_thread_priority() {
    // SAFETY: `gettid` takes no arguments and cannot fail; `setpriority` with
    // PRIO_PROCESS and a thread id changes that thread's nice value and
    // touches no memory.
    unsafe {
        let tid = libc::syscall(libc::SYS_gettid) as libc::id_t;
        libc::setpriority(libc::PRIO_PROCESS, tid, BACKGROUND_NICE);
    }
}

#[cfg(not(any(target_os = "linux", target_os = "android")))]
pub fn lower_current_thread_priority() {}

#[cfg(all(test, any(target_os = "linux", target_os = "android")))]
mod tests {
    #[test]
    fn lowers_only_the_calling_thread() {
        let main_before = unsafe { libc::getpriority(libc::PRIO_PROCESS, 0) };
        let in_thread = std::thread::spawn(|| {
            super::lower_current_thread_priority();
            unsafe { libc::getpriority(libc::PRIO_PROCESS, 0) }
        })
        .join()
        .unwrap();
        assert!(in_thread >= super::BACKGROUND_NICE);
        let main_after = unsafe { libc::getpriority(libc::PRIO_PROCESS, 0) };
        assert_eq!(main_before, main_after);
    }
}
