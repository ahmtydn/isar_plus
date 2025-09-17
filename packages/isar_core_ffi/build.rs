use std::{env, fs, fs::File, io::Write, path::Path};

fn main() {
    let out_dir = env::var("OUT_DIR").unwrap();
    let dest_path = Path::new(&out_dir).join("version.rs");
    let mut f = File::create(&dest_path).unwrap();

    let version = option_env!("ISAR_VERSION");
    let version = version.map_or("debug", |version| {
        let version = if version.starts_with("v") {
            &version[1..]
        } else {
            version
        };
        version
    });

    // Try to read the libmdbx tag from the sibling crate `mdbx_sys/build.rs`
    // Fallback to "unknown" if not found.
    let workspace_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let mdbx_build_rs = Path::new(&workspace_dir).join("../mdbx_sys/build.rs");
    let mdbx_tag = fs::read_to_string(&mdbx_build_rs)
        .ok()
        .and_then(|content| {
            let key = "const LIBMDBX_TAG: &str = \"";
            content
                .split('\n')
                .find(|line| line.trim_start().starts_with(key))
                .and_then(|line| {
                    let start = line.find('"')? + 1;
                    let end = line[start..].find('"')? + start;
                    Some(line[start..end].to_string())
                })
        })
        .unwrap_or_else(|| "unknown".to_string());

    write!(&mut f, "const ISAR_VERSION: &str = \"{version}\0\";").unwrap();
    write!(
        &mut f,
        "const MDBX_VERSION: &str = \"{mdbx_tag}\0\";"
    )
    .unwrap();
    println!("cargo:rerun-if-env-changed=ISAR_VERSION");
}
