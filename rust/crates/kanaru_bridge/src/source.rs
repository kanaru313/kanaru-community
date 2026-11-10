//! Where the bytes of a media file come from.

use std::fs::{File, OpenOptions};

use crate::error::{NativeError, NativeErrorKind};

/// Wave 1 reads paths only (Android local files come from MediaStore with
/// real paths). A file-descriptor variant arrives with SAF or cloud sources.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Source {
    Path(String),
}

/// Opens a regular file. The file is opened first with `O_NONBLOCK` (opening
/// a FIFO for reading then returns at once instead of waiting for a writer,
/// which once hung a whole library scan) and the type is checked on the open
/// handle, so nothing can change between the check and the open. FIFOs,
/// sockets, devices and directories are rejected.
pub fn open_source(source: &Source) -> Result<File, NativeError> {
    let Source::Path(path) = source;
    let mut options = OpenOptions::new();
    options.read(true);
    #[cfg(unix)]
    {
        use std::os::unix::fs::OpenOptionsExt;
        options.custom_flags(libc::O_NONBLOCK);
    }
    let file = options.open(path)?;
    if !file.metadata()?.is_file() {
        return Err(NativeError::new(
            NativeErrorKind::Unsupported,
            format!("not a regular file: {path}"),
            false,
        ));
    }
    Ok(file)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;

    fn temp_path(name: &str) -> std::path::PathBuf {
        std::env::temp_dir().join(format!("kanaru-source-{}-{name}", std::process::id()))
    }

    #[test]
    fn opens_regular_file() {
        let p = temp_path("regular");
        std::fs::File::create(&p)
            .and_then(|mut f| f.write_all(b"x"))
            .unwrap();
        let ok = open_source(&Source::Path(p.to_string_lossy().into_owned())).is_ok();
        std::fs::remove_file(&p).unwrap();
        assert!(ok);
    }

    #[test]
    fn missing_file_is_not_found() {
        let err = open_source(&Source::Path("/nonexistent/kanaru/none.mp3".into())).unwrap_err();
        assert_eq!(err.kind, NativeErrorKind::NotFound);
        assert!(!err.transient);
    }

    #[test]
    fn directory_is_rejected() {
        let dir = std::env::temp_dir();
        let err = open_source(&Source::Path(dir.to_string_lossy().into_owned())).unwrap_err();
        assert_eq!(err.kind, NativeErrorKind::Unsupported);
    }

    #[cfg(unix)]
    #[test]
    fn fifo_is_rejected_without_blocking() {
        let p = temp_path("fifo");
        if !make_fifo(&p) {
            eprintln!("skipped: mkfifo is not available");
            return;
        }
        let err = open_source(&Source::Path(p.to_string_lossy().into_owned()));
        std::fs::remove_file(&p).unwrap();
        assert_eq!(err.unwrap_err().kind, NativeErrorKind::Unsupported);
    }

    /// mkfifo through the `mkfifo` binary, so this file stays free of FFI.
    #[cfg(unix)]
    fn make_fifo(path: &std::path::Path) -> bool {
        std::process::Command::new("mkfifo")
            .arg(path)
            .status()
            .is_ok_and(|s| s.success())
    }
}
