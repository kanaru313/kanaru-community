//! Cropped cover imports and the crop-dialog preview, on images built in
//! memory (see `covers_fixtures`), written to a temporary folder.

mod covers_fixtures;
#[path = "tags_fixtures/mod.rs"]
mod tags_fixtures;

use kanaru_media::covers::key::{cover_key, cover_key_for};
use kanaru_media::covers::{
    import_cover, import_cover_cropped, prepare_preview, CoverError, CropRect, ImportedCover,
    PREVIEW_PREFIX,
};
use kanaru_media::{Cancel, MediaError};

use covers_fixtures::{
    jpeg_size, nearest_quadrant_color, pixel_at, quadrant_jpeg, quadrant_png, two_color_jpeg,
    webp_quadrants, with_jpeg_orientation, BLUE, GREEN, RED, YELLOW,
};
use tags_fixtures::{open_plain, TempDir};

struct Scene {
    root: TempDir,
}

impl Scene {
    fn new() -> Self {
        Self {
            root: TempDir::new(),
        }
    }

    fn import(&self, bytes: &[u8], crop: Option<CropRect>) -> Result<ImportedCover, CoverError> {
        let path = self.root.write("picture.bin", bytes);
        import_cover_cropped(
            &path,
            &open_plain,
            &self.root.path("cache"),
            crop,
            &Cancel::new(),
        )
    }

    fn read(&self, size: &str, key: &str) -> Vec<u8> {
        std::fs::read(
            self.root
                .path("cache")
                .join(format!("covers/{size}/{key}.jpg")),
        )
        .expect("cover file")
    }

    fn preview(&self, bytes: &[u8]) -> Result<kanaru_media::covers::CoverPreview, CoverError> {
        let path = self.root.write("picture.bin", bytes);
        prepare_preview(
            &path,
            &open_plain,
            &self.root.path("previews"),
            &Cancel::new(),
        )
    }
}

const fn rect(left: u32, top: u32, side: u32) -> Option<CropRect> {
    Some(CropRect { left, top, side })
}

/// The colour at the centre of the stored `full` file.
fn centre(scene: &Scene, key: &str) -> [u8; 3] {
    let full = scene.read("full", key);
    let (w, h) = jpeg_size(&full);
    nearest_quadrant_color(pixel_at(&full, w / 2, h / 2))
}

/// Upright layout (top-left, top-right, bottom-left, bottom-right) of the
/// stored red / green / blue / yellow quadrants after each EXIF turn.
fn upright_layout(orientation: u16) -> [[u8; 3]; 4] {
    match orientation {
        1 => [RED, GREEN, BLUE, YELLOW],
        3 => [YELLOW, BLUE, GREEN, RED],
        6 => [BLUE, RED, YELLOW, GREEN],
        8 => [GREEN, YELLOW, RED, BLUE],
        other => panic!("no layout for {other}"),
    }
}

/// Crops each upright quadrant (a 20 px square) of an 80 x 40 picture stored
/// with `orientation` and checks the colour at the centre of `full`.
fn assert_quadrant_crops(scene: &Scene, bytes: &[u8], orientation: u16, label: &str) {
    let (uw, uh) = if orientation == 6 || orientation == 8 {
        (40, 80)
    } else {
        (80, 40)
    };
    let expected = upright_layout(orientation);
    for (i, want) in expected.into_iter().enumerate() {
        let (qx, qy) = ((i % 2) as u32, (i / 2) as u32);
        let crop = rect(qx * uw / 2, qy * uh / 2, 20);
        let done = scene.import(bytes, crop).expect(label);
        assert_eq!(centre(scene, &done.key), want, "{label} quadrant {i}");
        assert_eq!(
            jpeg_size(&scene.read("full", &done.key)),
            (20, 20),
            "{label}"
        );
        assert_eq!(
            jpeg_size(&scene.read("thumb", &done.key)),
            (20, 20),
            "{label}"
        );
        assert_eq!(done.key, cover_key_for(bytes, crop), "{label}");
    }
}

#[test]
fn a_crop_of_each_quadrant_lands_where_the_user_saw_it_for_every_orientation() {
    for orientation in [3, 6, 8] {
        let scene = Scene::new();
        let jpeg = with_jpeg_orientation(&quadrant_jpeg(80, 40), orientation);
        assert_quadrant_crops(&scene, &jpeg, orientation, &format!("jpeg {orientation}"));
    }
    for orientation in [3, 8] {
        let scene = Scene::new();
        let webp = webp_quadrants(80, 40, orientation);
        assert_quadrant_crops(&scene, &webp, orientation, &format!("webp {orientation}"));
    }
    let scene = Scene::new();
    assert_quadrant_crops(&scene, &quadrant_png(80, 40), 1, "png");
    let scene = Scene::new();
    assert_quadrant_crops(&scene, &quadrant_jpeg(80, 40), 1, "jpeg 1");
}

#[test]
fn no_crop_is_the_same_output_as_import_cover() {
    let scene = Scene::new();
    let bytes = two_color_jpeg(1500, 1000);
    let none = scene.import(&bytes, None).expect("import");
    assert_eq!(none.key, cover_key(&bytes));
    let path = scene.root.path("picture.bin");
    let plain = import_cover(
        &path,
        &open_plain,
        &scene.root.path("plain"),
        &Cancel::new(),
    )
    .expect("plain import");
    assert_eq!(plain.key, none.key);
    for size in ["full", "thumb"] {
        let other = std::fs::read(
            scene
                .root
                .path("plain")
                .join(format!("covers/{size}/{}.jpg", plain.key)),
        )
        .expect("file");
        assert_eq!(other, scene.read(size, &none.key), "{size}");
    }
    assert_eq!(jpeg_size(&scene.read("full", &none.key)), (1024, 683));
}

#[test]
fn the_whole_of_a_square_image_is_no_crop() {
    let scene = Scene::new();
    let bytes = quadrant_png(64, 64);
    let whole = scene.import(&bytes, rect(0, 0, 64)).expect("whole");
    assert_eq!(whole.key, cover_key(&bytes));
    let none = scene.import(&bytes, None).expect("none");
    assert_eq!(whole.key, none.key);
    // Any other crop of it is a different cover.
    let inner = scene.import(&bytes, rect(0, 0, 63)).expect("inner");
    assert_ne!(inner.key, none.key);
    // The full height of a wide picture is a real crop.
    let wide = quadrant_png(64, 32);
    let square = scene.import(&wide, rect(0, 0, 32)).expect("square");
    assert_eq!(square.key, cover_key_for(&wide, rect(0, 0, 32)));
    assert_ne!(square.key, cover_key(&wide));
}

#[test]
fn an_invalid_crop_is_unsupported_and_writes_nothing() {
    let scene = Scene::new();
    // Stored 80 x 40, turned to 40 x 80: a 41 px square does not fit.
    let jpeg = with_jpeg_orientation(&quadrant_jpeg(80, 40), 6);
    for bad in [
        rect(0, 0, 0),
        rect(0, 0, 41),
        rect(1, 0, 40),
        rect(0, 41, 40),
        rect(40, 0, 1),
        rect(u32::MAX, 0, 2),
    ] {
        let result = scene.import(&jpeg, bad);
        assert!(
            matches!(result, Err(CoverError::Source(MediaError::Unsupported))),
            "{bad:?}: {result:?}"
        );
    }
    assert!(!scene.root.path("cache").exists(), "nothing written");
    // The same bad crop is valid once the image is upright and wide.
    scene
        .import(&quadrant_jpeg(80, 40), rect(0, 0, 40))
        .expect("fits unturned");
}

#[test]
fn a_wide_original_crops_to_a_full_1024_square_from_the_full_decode() {
    let scene = Scene::new();
    let wide = two_color_jpeg(6000, 2000);
    let left = scene.import(&wide, rect(0, 0, 2000)).expect("left");
    assert_eq!(jpeg_size(&scene.read("full", &left.key)), (1024, 1024));
    assert_eq!(jpeg_size(&scene.read("thumb", &left.key)), (256, 256));
    assert_eq!(centre(&scene, &left.key), RED);
    let right = scene.import(&wide, rect(4000, 0, 2000)).expect("right");
    assert_eq!(jpeg_size(&scene.read("full", &right.key)), (1024, 1024));
    assert_eq!(centre(&scene, &right.key), BLUE);
}

#[test]
fn a_turned_portrait_crop_keeps_its_place_through_the_scaled_decode() {
    let scene = Scene::new();
    // 4096 x 2560 stored, turned to 2560 x 4096. A 2560 px crop from
    // row 1536 is decoded at half size and shrunk to 1024.
    let bytes = with_jpeg_orientation(&quadrant_jpeg(4096, 2560), 6);
    let done = scene.import(&bytes, rect(0, 1536, 2560)).expect("import");
    let full = scene.read("full", &done.key);
    assert_eq!(jpeg_size(&full), (1024, 1024));
    let at = |x, y| nearest_quadrant_color(pixel_at(&full, x, y));
    // Upright layout of orientation 6: blue red / yellow green, split at
    // x 1280 and y 2048 (here x 512, y 205).
    let layout = upright_layout(6);
    assert_eq!(at(256, 128), layout[0]);
    assert_eq!(at(900, 128), layout[1]);
    assert_eq!(at(256, 700), layout[2]);
    assert_eq!(at(900, 700), layout[3]);
}

#[test]
fn a_four_thousand_pixel_portrait_crop_is_1024() {
    let scene = Scene::new();
    let tall = covers_fixtures::jpeg(2000, 4000, false, |_, y| if y < 2000 { RED } else { BLUE });
    let done = scene.import(&tall, rect(0, 1000, 2000)).expect("import");
    assert_eq!(jpeg_size(&scene.read("full", &done.key)), (1024, 1024));
}

#[test]
fn preview_is_upright_with_the_original_size() {
    for orientation in [3, 6, 8] {
        let scene = Scene::new();
        let bytes = with_jpeg_orientation(&quadrant_jpeg(80, 40), orientation);
        let preview = scene.preview(&bytes).expect("preview");
        let expected_size = if orientation == 3 { (80, 40) } else { (40, 80) };
        assert_eq!((preview.width, preview.height), expected_size);
        let jpeg = std::fs::read(&preview.path).expect("file");
        assert_eq!(jpeg_size(&jpeg), expected_size, "orientation {orientation}");
        let layout = upright_layout(orientation);
        let (w, h) = expected_size;
        let at = |x, y| nearest_quadrant_color(pixel_at(&jpeg, x, y));
        assert_eq!(at(w / 4, h / 4), layout[0], "{orientation}");
        assert_eq!(at(w * 3 / 4, h / 4), layout[1], "{orientation}");
        assert_eq!(at(w / 4, h * 3 / 4), layout[2], "{orientation}");
        assert_eq!(at(w * 3 / 4, h * 3 / 4), layout[3], "{orientation}");
        let name = preview.path.file_name().unwrap().to_string_lossy();
        assert!(
            name.starts_with(PREVIEW_PREFIX) && name.ends_with(".jpg"),
            "{name}"
        );
        assert_eq!(
            preview.path.parent(),
            Some(scene.root.path("previews").as_path())
        );
    }
}

#[test]
fn preview_of_webp_and_png_is_upright_too() {
    let scene = Scene::new();
    let webp = scene.preview(&webp_quadrants(80, 40, 8)).expect("webp");
    assert_eq!((webp.width, webp.height), (40, 80));
    let jpeg = std::fs::read(&webp.path).expect("file");
    assert_eq!(jpeg_size(&jpeg), (40, 80));
    assert_eq!(nearest_quadrant_color(pixel_at(&jpeg, 10, 20)), GREEN);
    let png = scene.preview(&quadrant_png(80, 40)).expect("png");
    assert_eq!((png.width, png.height), (80, 40));
}

#[test]
fn a_large_preview_is_1024_on_the_long_side_and_reports_the_original() {
    let scene = Scene::new();
    let preview = scene.preview(&two_color_jpeg(6000, 2000)).expect("preview");
    assert_eq!((preview.width, preview.height), (6000, 2000));
    let jpeg = std::fs::read(&preview.path).expect("file");
    assert_eq!(jpeg_size(&jpeg), (1024, 341));
    // A small picture is not enlarged.
    let small = scene.preview(&quadrant_jpeg(300, 200)).expect("small");
    assert_eq!(jpeg_size(&std::fs::read(&small.path).unwrap()), (300, 200));
}

#[test]
fn preview_errors_are_the_import_errors_and_leave_no_file() {
    let scene = Scene::new();
    for (bytes, want) in [
        (b"not an image".to_vec(), MediaError::Unsupported),
        (
            covers_fixtures::png_header_only(7000, 7000),
            MediaError::TooLarge,
        ),
    ] {
        let result = scene.preview(&bytes);
        assert!(
            matches!(&result, Err(CoverError::Source(e)) if e == &want),
            "{result:?}"
        );
    }
    let truncated = quadrant_jpeg(200, 200)[..300].to_vec();
    assert!(matches!(
        scene.preview(&truncated),
        Err(CoverError::Source(MediaError::Corrupt(_)))
    ));
    assert!(!scene.root.path("previews").exists(), "nothing written");
    let missing = prepare_preview(
        &scene.root.path("gone"),
        &open_plain,
        &scene.root.path("previews"),
        &Cancel::new(),
    );
    assert!(matches!(
        missing,
        Err(CoverError::Source(MediaError::Io(
            std::io::ErrorKind::NotFound
        )))
    ));
}

#[test]
fn preview_into_an_unwritable_folder_is_a_cache_error() {
    let scene = Scene::new();
    let blocker = scene.root.write("blocker", b"a file");
    let path = scene.root.write("picture.bin", &quadrant_jpeg(40, 40));
    let result = prepare_preview(&path, &open_plain, &blocker, &Cancel::new());
    assert!(matches!(result, Err(CoverError::Cache(_))), "{result:?}");
}
