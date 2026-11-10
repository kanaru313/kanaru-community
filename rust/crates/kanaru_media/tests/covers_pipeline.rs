//! `make_cover` on generated audio files, embedded pictures, sidecars and
//! hostile images, writing to a temporary cache folder.

mod covers_fixtures;
#[path = "tags_fixtures/mod.rs"]
mod tags_fixtures;

use std::path::{Path, PathBuf};

use kanaru_media::covers::key::{cover_key, is_cover_key};
use kanaru_media::covers::{
    colors, import_cover, make_cover, CoverError, CoverOutcome, FolderMemo,
};
use kanaru_media::{Cancel, MediaError};
use lofty::picture::{MimeType, Picture, PictureType};
use lofty::tag::{ItemKey, Tag, TagType};

use covers_fixtures::{
    jpeg, jpeg_header_only, jpeg_size, pixel_at, png, png_header_only, transparent_png,
    two_color_jpeg, varied_jpeg, webp_with_orientation, with_jpeg_orientation,
};
use tags_fixtures::{mp3_bytes, open_plain, save, tag_with, wav_bytes, TempDir};

/// A scratch area: audio files and sidecars in `dir`, the cache in `dir/cache`.
struct Scene {
    root: TempDir,
}

impl Scene {
    fn new() -> Self {
        Self {
            root: TempDir::new(),
        }
    }

    fn cache(&self) -> PathBuf {
        self.root.path("cache")
    }

    /// A WAV with no embedded picture.
    fn wav(&self, name: &str) -> PathBuf {
        self.root.write(name, &wav_bytes())
    }

    /// An MP3 with the given pictures.
    fn mp3_with(&self, name: &str, pictures: Vec<(PictureType, Vec<u8>)>) -> PathBuf {
        let path = self.root.write(name, &mp3_bytes());
        let mut tag: Tag = tag_with(TagType::Id3v2, &[(ItemKey::TrackTitle, "Song")]);
        for (kind, data) in pictures {
            tag.push_picture(
                Picture::unchecked(data)
                    .pic_type(kind)
                    .mime_type(MimeType::Jpeg)
                    .build(),
            );
        }
        save(&tag, &path);
        path
    }

    fn run(&self, audio: &Path, sidecars: bool) -> Result<CoverOutcome, CoverError> {
        self.run_with(audio, sidecars, &mut FolderMemo::default())
    }

    fn run_with(
        &self,
        audio: &Path,
        sidecars: bool,
        memo: &mut FolderMemo,
    ) -> Result<CoverOutcome, CoverError> {
        make_cover(
            audio,
            &open_plain,
            sidecars,
            &self.cache(),
            memo,
            &Cancel::new(),
        )
    }

    fn read(&self, size: &str, key: &str) -> Vec<u8> {
        std::fs::read(self.cache().join(format!("covers/{size}/{key}.jpg"))).expect("cover file")
    }
}

fn found(outcome: Result<CoverOutcome, CoverError>) -> (String, bool, Option<colors::CoverColors>) {
    match outcome {
        Ok(CoverOutcome::Found { key, made, colors }) => (key, made, colors),
        other => panic!("expected Found, got {other:?}"),
    }
}

#[test]
fn embedded_picture_is_cached_in_both_sizes() {
    let scene = Scene::new();
    let original = two_color_jpeg(1600, 1200);
    let audio = scene.mp3_with(
        "song.mp3",
        vec![(PictureType::CoverFront, original.clone())],
    );

    let (key, made, colors) = found(scene.run(&audio, true));
    assert!(made);
    assert!(is_cover_key(&key), "{key}");
    assert_eq!(key, cover_key(&original));
    assert_eq!(jpeg_size(&scene.read("full", &key)), (1024, 768));
    assert_eq!(jpeg_size(&scene.read("thumb", &key)), (256, 192));
    let colors = colors.expect("colours of a made cover");
    assert!(colors.palette.len() >= 2);

    // Second call: nothing to do, no colours.
    let (again, made, colors_again) = found(scene.run(&audio, true));
    assert_eq!((again, made, colors_again), (key.clone(), false, None));

    // The colours read back from the cached thumb are the same.
    let cached = colors::colors_of_cached_thumb(&scene.cache(), &key, &open_plain).expect("cached");
    assert_eq!(cached, Some(colors));
}

#[test]
fn front_cover_beats_other_pictures() {
    let scene = Scene::new();
    let other = varied_jpeg(200, 200, 1);
    let front = varied_jpeg(200, 200, 2);
    let audio = scene.mp3_with(
        "song.mp3",
        vec![
            (PictureType::Other, other),
            (PictureType::CoverFront, front.clone()),
        ],
    );
    let (key, _, _) = found(scene.run(&audio, true));
    assert_eq!(key, cover_key(&front));
}

#[test]
fn a_bad_embedded_picture_falls_through_to_the_sidecar() {
    let scene = Scene::new();
    let audio = scene.mp3_with(
        "song.mp3",
        vec![(PictureType::CoverFront, b"this is not an image".to_vec())],
    );
    let sidecar = varied_jpeg(300, 300, 5);
    scene.root.write("Song.JPG", &sidecar);
    let (key, made, _) = found(scene.run(&audio, true));
    assert!(made);
    assert_eq!(key, cover_key(&sidecar));
}

#[test]
fn a_bad_picture_and_no_sidecar_is_no_cover() {
    let scene = Scene::new();
    let audio = scene.mp3_with(
        "song.mp3",
        vec![(PictureType::CoverFront, b"not an image".to_vec())],
    );
    assert!(matches!(scene.run(&audio, true), Ok(CoverOutcome::NoCover)));
    assert!(!scene.cache().exists(), "nothing written");
}

#[test]
fn sidecar_order_and_case() {
    let scene = Scene::new();
    let audio = scene.wav("Track.wav");
    let by_stem = varied_jpeg(100, 100, 10);
    let by_folder = varied_jpeg(100, 100, 20);
    scene.root.write("COVER.JPG", &by_folder);
    let (key, _, _) = found(scene.run(&audio, true));
    assert_eq!(key, cover_key(&by_folder), "folder name, any case");

    scene.root.write("track.JPEG", &by_stem);
    let (key, _, _) = found(scene.run(&audio, true));
    assert_eq!(key, cover_key(&by_stem), "named after the audio file first");
}

#[test]
fn sidecars_off_ignores_images_next_to_the_audio() {
    let scene = Scene::new();
    let audio = scene.wav("a.wav");
    scene.root.write("cover.jpg", &varied_jpeg(100, 100, 3));
    assert!(matches!(
        scene.run(&audio, false),
        Ok(CoverOutcome::NoCover)
    ));
    assert!(matches!(
        scene.run(&audio, true),
        Ok(CoverOutcome::Found { .. })
    ));
}

#[test]
fn no_picture_anywhere_is_no_cover() {
    let scene = Scene::new();
    let audio = scene.wav("a.wav");
    scene.root.write("notes.txt", b"hello");
    assert!(matches!(scene.run(&audio, true), Ok(CoverOutcome::NoCover)));
}

#[test]
fn tracks_of_an_album_share_the_sidecar_decode() {
    let scene = Scene::new();
    let a = scene.wav("a.wav");
    let b = scene.wav("b.wav");
    scene
        .root
        .write("folder.png", &png(80, 80, |x, _| [x as u8, 40, 90]));
    let mut memo = FolderMemo::default();
    let (key_a, made_a, colors_a) = found(scene.run_with(&a, true, &mut memo));
    let (key_b, made_b, colors_b) = found(scene.run_with(&b, true, &mut memo));
    assert_eq!(key_a, key_b);
    assert!(made_a && colors_a.is_some());
    assert!(!made_b && colors_b.is_none());
}

#[test]
fn unreadable_audio_is_a_permanent_error_unless_a_sidecar_exists() {
    let scene = Scene::new();
    let junk = scene.root.write("junk.mp3", &[7u8; 4096]);
    match scene.run(&junk, true) {
        Err(CoverError::Source(e)) => {
            assert!(
                matches!(e, MediaError::Unsupported | MediaError::Corrupt(_)),
                "{e:?}"
            );
            assert!(!e.is_transient());
        }
        other => panic!("expected a source error, got {other:?}"),
    }
    scene.root.write("cover.jpg", &varied_jpeg(120, 120, 9));
    assert!(matches!(
        scene.run(&junk, true),
        Ok(CoverOutcome::Found { .. })
    ));
}

#[test]
fn missing_audio_is_not_found_and_open_failures_pass_through() {
    let scene = Scene::new();
    let gone = scene.root.path("gone.mp3");
    assert!(matches!(
        scene.run(&gone, true),
        Err(CoverError::Source(MediaError::Io(
            std::io::ErrorKind::NotFound
        )))
    ));
    let busy = |_: &Path| Err(MediaError::Io(std::io::ErrorKind::TimedOut));
    let result = make_cover(
        &gone,
        &busy,
        true,
        &scene.cache(),
        &mut FolderMemo::default(),
        &Cancel::new(),
    );
    assert!(matches!(result, Err(CoverError::Source(e)) if e.is_transient()));
}

#[test]
fn a_cache_that_cannot_be_written_is_a_cache_error_with_no_partial_files() {
    let scene = Scene::new();
    let audio = scene.wav("a.wav");
    scene.root.write("cover.jpg", &varied_jpeg(100, 100, 4));
    // The cache folder is a regular file.
    scene.root.write("cache", b"i am a file");
    assert!(matches!(scene.run(&audio, true), Err(CoverError::Cache(_))));
    assert!(scene.cache().is_file());
}

#[cfg(unix)]
#[test]
fn a_read_only_cache_folder_is_a_cache_error() {
    use std::os::unix::fs::PermissionsExt;
    let scene = Scene::new();
    let audio = scene.wav("a.wav");
    scene.root.write("cover.jpg", &varied_jpeg(100, 100, 4));
    std::fs::create_dir_all(scene.cache()).expect("cache dir");
    std::fs::set_permissions(scene.cache(), std::fs::Permissions::from_mode(0o555)).expect("chmod");
    // Root ignores the mode: then there is nothing to assert.
    let writable = std::fs::File::create(scene.cache().join("probe")).is_ok();
    let result = scene.run(&audio, true);
    std::fs::set_permissions(scene.cache(), std::fs::Permissions::from_mode(0o755)).expect("chmod");
    if !writable {
        assert!(matches!(result, Err(CoverError::Cache(_))), "{result:?}");
        assert_eq!(std::fs::read_dir(scene.cache()).expect("list").count(), 0);
    }
}

#[test]
fn transparent_parts_end_up_on_black() {
    let scene = Scene::new();
    let audio = scene.wav("a.wav");
    scene.root.write("cover.png", &transparent_png(64, 64));
    let (key, _, _) = found(scene.run(&audio, true));
    let [r, g, b] = pixel_at(&scene.read("thumb", &key), 10, 10);
    assert!(r < 20 && g < 20 && b < 20, "{r} {g} {b}");
}

#[test]
fn small_images_are_never_enlarged() {
    let scene = Scene::new();
    let audio = scene.wav("a.wav");
    scene
        .root
        .write("cover.png", &png(100, 50, |x, y| [x as u8, y as u8, 7]));
    let (key, _, _) = found(scene.run(&audio, true));
    assert_eq!(jpeg_size(&scene.read("thumb", &key)), (100, 50));
    assert_eq!(jpeg_size(&scene.read("full", &key)), (100, 50));
}

#[test]
fn a_clean_small_baseline_jpeg_is_its_own_full_size() {
    let scene = Scene::new();
    let audio = scene.wav("a.wav");
    let original = varied_jpeg(600, 600, 11);
    scene.root.write("cover.jpg", &original);
    let (key, _, _) = found(scene.run(&audio, true));
    assert_eq!(scene.read("full", &key), original);
    assert_eq!(jpeg_size(&scene.read("thumb", &key)), (256, 256));
}

#[test]
fn bytes_after_the_end_of_image_are_never_copied() {
    let scene = Scene::new();
    let audio = scene.wav("a.wav");
    let mut hostile = varied_jpeg(300, 300, 12);
    hostile.extend_from_slice(b"<script>trailing payload</script>");
    scene.root.write("cover.jpg", &hostile);
    let (key, _, _) = found(scene.run(&audio, true));
    let full = scene.read("full", &key);
    assert!(!full.windows(8).any(|w| w == b"<script>"));
    assert_ne!(full, hostile);
}

#[test]
fn a_truncated_jpeg_is_never_copied_as_is() {
    let scene = Scene::new();
    let audio = scene.wav("a.wav");
    let whole = varied_jpeg(400, 400, 13);
    let cut = &whole[..whole.len() / 2];
    scene.root.write("cover.jpg", cut);
    match scene.run(&audio, true) {
        Ok(CoverOutcome::Found { key, .. }) => assert_ne!(scene.read("full", &key), cut),
        Ok(CoverOutcome::NoCover) => {}
        other => panic!("unexpected {other:?}"),
    }
}

#[test]
fn exif_orientation_turns_jpeg_and_webp_upright() {
    let scene = Scene::new();
    let audio = scene.wav("a.wav");
    let rotated = with_jpeg_orientation(&two_color_jpeg(400, 200), 6);
    scene.root.write("cover.jpg", &rotated);
    let (key, _, _) = found(scene.run(&audio, true));
    assert_eq!(jpeg_size(&scene.read("full", &key)), (200, 400));
    assert_eq!(jpeg_size(&scene.read("thumb", &key)), (128, 256));

    let scene = Scene::new();
    let webp = webp_with_orientation(40, 20, 6);
    let audio = scene.mp3_with("song.mp3", vec![(PictureType::CoverFront, webp)]);
    let (key, _, _) = found(scene.run(&audio, true));
    assert_eq!(jpeg_size(&scene.read("full", &key)), (20, 40));
}

#[test]
fn progressive_jpeg_covers_work() {
    let scene = Scene::new();
    let audio = scene.wav("a.wav");
    scene.root.write(
        "cover.jpg",
        &jpeg(500, 500, true, |x, y| [(x / 3) as u8, (y / 3) as u8, 90]),
    );
    let (key, _, _) = found(scene.run(&audio, true));
    assert_eq!(jpeg_size(&scene.read("thumb", &key)), (256, 256));
}

#[test]
fn a_large_jpeg_is_decoded_scaled_and_fitted() {
    let scene = Scene::new();
    let audio = scene.wav("a.wav");
    scene.root.write("cover.jpg", &two_color_jpeg(3000, 2000));
    let (key, _, _) = found(scene.run(&audio, true));
    assert_eq!(jpeg_size(&scene.read("full", &key)), (1024, 683));
    assert_eq!(jpeg_size(&scene.read("thumb", &key)), (256, 171));
}

#[test]
fn hostile_headers_are_rejected_without_decoding() {
    for (name, bytes) in [
        ("cover.png", png_header_only(7000, 7000)),
        ("cover.png", png_header_only(5000, 5000)),
        ("cover.jpg", jpeg_header_only(5000, 5000)),
        ("cover.jpg", jpeg_header_only(9000, 9000)),
        ("cover.jpg", jpeg_header_only(40000, 40000)),
    ] {
        let scene = Scene::new();
        let audio = scene.wav("a.wav");
        scene.root.write(name, &bytes);
        let outcome = scene.run(&audio, true);
        assert!(
            matches!(outcome, Ok(CoverOutcome::NoCover)),
            "{name}: {outcome:?}"
        );
        assert!(!scene.cache().exists());
    }
}

#[test]
fn two_large_covers_in_parallel_both_finish() {
    let scene = Scene::new();
    let first_dir = scene.root.path("one");
    let second_dir = scene.root.path("two");
    std::fs::create_dir_all(&first_dir).expect("dir");
    std::fs::create_dir_all(&second_dir).expect("dir");
    std::fs::write(first_dir.join("a.wav"), wav_bytes()).expect("wav");
    std::fs::write(second_dir.join("a.wav"), wav_bytes()).expect("wav");
    // 9 MP each: over the size that waits for the decode gate.
    std::fs::write(first_dir.join("cover.jpg"), varied_jpeg(3000, 3000, 31)).expect("jpg");
    std::fs::write(second_dir.join("cover.jpg"), varied_jpeg(3000, 3000, 77)).expect("jpg");
    let scene = &scene;
    let (a, b) = std::thread::scope(|s| {
        let a = s.spawn(|| scene.run(&first_dir.join("a.wav"), true));
        let b = s.spawn(|| scene.run(&second_dir.join("a.wav"), true));
        (a.join().expect("thread"), b.join().expect("thread"))
    });
    let (key_a, made_a, _) = found(a);
    let (key_b, made_b, _) = found(b);
    assert!(made_a && made_b);
    assert_ne!(key_a, key_b);
}

#[test]
fn cancel_stops_before_any_work() {
    let scene = Scene::new();
    let audio = scene.wav("a.wav");
    scene.root.write("cover.jpg", &varied_jpeg(100, 100, 1));
    let cancel = Cancel::new();
    cancel.cancel();
    let result = make_cover(
        &audio,
        &open_plain,
        true,
        &scene.cache(),
        &mut FolderMemo::default(),
        &cancel,
    );
    assert!(matches!(
        result,
        Err(CoverError::Source(MediaError::Cancelled))
    ));
}

#[test]
fn a_sidecar_that_cannot_be_read_does_not_hide_the_next_one_and_is_not_remembered() {
    let scene = Scene::new();
    let audio = scene.wav("a.wav");
    let broken = scene.root.path("cover.jpg");
    scene.root.write("cover.jpg", &varied_jpeg(100, 100, 1));
    let good = varied_jpeg(100, 100, 2);
    scene.root.write("folder.jpg", &good);
    // `cover.jpg` is first in order; its open fails transiently.
    let flaky = |p: &Path| {
        if p == broken {
            Err(MediaError::Io(std::io::ErrorKind::TimedOut))
        } else {
            open_plain(p)
        }
    };
    let mut memo = FolderMemo::default();
    let run = |memo: &mut FolderMemo| {
        make_cover(&audio, &flaky, true, &scene.cache(), memo, &Cancel::new())
    };
    let (key, _, _) = found(run(&mut memo));
    assert_eq!(key, cover_key(&good));

    // With only the broken one left, the item is a transient Retry twice (the
    // failure is not memoised as "no cover").
    std::fs::remove_file(scene.root.path("folder.jpg")).expect("remove");
    let mut memo = FolderMemo::default();
    for _ in 0..2 {
        assert!(matches!(run(&mut memo), Err(CoverError::Retry(_))));
    }
}

fn import(
    scene: &Scene,
    name: &str,
    bytes: &[u8],
) -> Result<kanaru_media::covers::ImportedCover, CoverError> {
    let path = scene.root.write(name, bytes);
    import_cover(&path, &open_plain, &scene.cache(), &Cancel::new())
}

#[test]
fn import_handles_jpeg_png_webp_and_names_without_extension() {
    let scene = Scene::new();
    let jpeg = two_color_jpeg(1500, 1000);
    let png = png(300, 200, |x, _| {
        if x < 150 {
            [220, 30, 30]
        } else {
            [30, 30, 220]
        }
    });
    let webp = webp_with_orientation(40, 20, 6);
    for (name, bytes, full) in [
        ("photo", &jpeg, (1024, 683)),
        ("picture.dat", &png, (300, 200)),
        ("cover.webp", &webp, (20, 40)),
    ] {
        let done = import(&scene, name, bytes).expect(name);
        assert_eq!(done.key, cover_key(bytes), "{name}");
        assert_eq!(jpeg_size(&scene.read("full", &done.key)), full, "{name}");
        assert!(jpeg_size(&scene.read("thumb", &done.key)).0 <= 256);
    }
}

#[test]
fn import_gives_colours_and_none_for_near_gray() {
    let scene = Scene::new();
    let colourful = import(&scene, "a", &two_color_jpeg(200, 200)).expect("import");
    assert!(colourful.colors.is_some_and(|c| c.palette.len() >= 2));
    let gray = import(&scene, "b", &jpeg(200, 200, false, |_, _| [128, 128, 130])).expect("import");
    assert_eq!(gray.colors, None);
}

#[test]
fn import_rewrites_both_files_with_the_same_key_and_colours() {
    let scene = Scene::new();
    let bytes = two_color_jpeg(400, 400);
    let first = import(&scene, "a", &bytes).expect("first");
    let thumb = scene
        .cache()
        .join(format!("covers/thumb/{}.jpg", first.key));
    let full = scene.cache().join(format!("covers/full/{}.jpg", first.key));
    let good_full = std::fs::read(&full).expect("full");
    std::fs::write(&thumb, b"damaged").expect("damage");
    std::fs::write(&full, b"damaged too").expect("damage");
    let second = import(&scene, "b", &bytes).expect("second");
    assert_eq!(second, first);
    assert_eq!(jpeg_size(&scene.read("thumb", &first.key)), (256, 256));
    assert_eq!(std::fs::read(&full).expect("full"), good_full);
}

#[test]
fn import_rejects_bad_input_permanently() {
    let scene = Scene::new();
    let permanent = |r: Result<kanaru_media::covers::ImportedCover, CoverError>| match r {
        Err(CoverError::Source(e)) => {
            assert!(!e.is_transient(), "{e:?}");
            e
        }
        other => panic!("expected a source error, got {other:?}"),
    };
    assert_eq!(
        permanent(import(&scene, "t.txt", b"hello")),
        MediaError::Unsupported
    );
    assert_eq!(
        permanent(import(&scene, "e.png", b"")),
        MediaError::Unsupported
    );
    assert_eq!(
        permanent(import(&scene, "huge.png", &png_header_only(7000, 7000))),
        MediaError::TooLarge
    );
    // A valid header with no pixel data behind it.
    assert!(matches!(
        permanent(import(&scene, "cut.png", &png_header_only(300, 300))),
        MediaError::Corrupt(_)
    ));
    // Over the byte cap: refused from the size, a sparse file is enough.
    let big = scene.root.path("big.jpg");
    let file = std::fs::File::create(&big).expect("create");
    file.set_len(kanaru_media::limits::MAX_COVER_BYTES + 1)
        .expect("sparse");
    drop(file);
    let result = import_cover(&big, &open_plain, &scene.cache(), &Cancel::new());
    assert_eq!(permanent(result), MediaError::TooLarge);
    assert!(!scene.cache().exists(), "nothing written");
}

#[test]
fn import_reports_a_cache_failure_and_a_missing_file() {
    let scene = Scene::new();
    scene.root.write("cache", b"i am a file");
    assert!(matches!(
        import(&scene, "a.jpg", &two_color_jpeg(100, 100)),
        Err(CoverError::Cache(_))
    ));
    let gone = scene.root.path("gone.jpg");
    assert!(matches!(
        import_cover(&gone, &open_plain, &scene.cache(), &Cancel::new()),
        Err(CoverError::Source(MediaError::Io(
            std::io::ErrorKind::NotFound
        )))
    ));
}
