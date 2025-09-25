use bindgen::callbacks::{IntKind, ParseCallbacks};
use std::process::Command;
use std::{env, fs, path::PathBuf};

#[derive(Debug)]
struct Callbacks;

impl ParseCallbacks for Callbacks {
    fn int_macro(&self, name: &str, _value: i64) -> Option<IntKind> {
        match name {
            "MDBX_SUCCESS"
            | "MDBX_KEYEXIST"
            | "MDBX_NOTFOUND"
            | "MDBX_PAGE_NOTFOUND"
            | "MDBX_CORRUPTED"
            | "MDBX_PANIC"
            | "MDBX_VERSION_MISMATCH"
            | "MDBX_INVALID"
            | "MDBX_MAP_FULL"
            | "MDBX_DBS_FULL"
            | "MDBX_READERS_FULL"
            | "MDBX_TLS_FULL"
            | "MDBX_TXN_FULL"
            | "MDBX_CURSOR_FULL"
            | "MDBX_PAGE_FULL"
            | "MDBX_MAP_RESIZED"
            | "MDBX_INCOMPATIBLE"
            | "MDBX_BAD_RSLOT"
            | "MDBX_BAD_TXN"
            | "MDBX_BAD_VALSIZE"
            | "MDBX_BAD_DBI"
            | "MDBX_LOG_DONTCHANGE"
            | "MDBX_DBG_DONTCHANGE"
            | "MDBX_RESULT_TRUE"
            | "MDBX_UNABLE_EXTEND_MAPSIZE"
            | "MDBX_PROBLEM"
            | "MDBX_LAST_LMDB_ERRCODE"
            | "MDBX_BUSY"
            | "MDBX_EMULTIVAL"
            | "MDBX_EBADSIGN"
            | "MDBX_WANNA_RECOVERY"
            | "MDBX_EKEYMISMATCH"
            | "MDBX_TOO_LARGE"
            | "MDBX_THREAD_MISMATCH"
            | "MDBX_TXN_OVERLAPPING"
            | "MDBX_LAST_ERRCODE" => Some(IntKind::Int),
            _ => Some(IntKind::UInt),
        }
    }
}

const LIBMDBX_REPO: &str = "https://github.com/isar/libmdbx.git";
const LIBMDBX_TAG: &str = "v0.13.8";

fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    env::set_var("IPHONEOS_DEPLOYMENT_TARGET", "11.0");

    let is_android = env::var("CARGO_CFG_TARGET_OS").unwrap() == "android";

    let _ = fs::remove_dir_all("libmdbx");

    Command::new("git")
        .arg("clone")
        .arg(LIBMDBX_REPO)
        .arg("--branch")
        .arg(LIBMDBX_TAG)
        .output()
        .unwrap();

    // Create amalgamated source manually instead of using make dist
    let mdbx_root = PathBuf::from(&env::var("CARGO_MANIFEST_DIR").unwrap()).join("libmdbx");
    let mdbx_src = mdbx_root.join("src");
    let mdbx_dist = mdbx_root.join("dist");
    
    // Ensure dist directory exists
    let _ = fs::create_dir_all(&mdbx_dist);
    
    // Copy header file
    fs::copy(mdbx_root.join("mdbx.h"), mdbx_dist.join("mdbx.h")).unwrap();
    
    // Create version.c if it doesn't exist
    if !mdbx_src.join("version.c").exists() {
        Command::new("make")
            .arg("src/version.c")
            .current_dir(&mdbx_root)
            .output()
            .expect("Failed to generate version.c");
    }
    

    let mut mdbx = PathBuf::from(&env::var("CARGO_MANIFEST_DIR").unwrap());
    mdbx.push("libmdbx");

    let core_path = mdbx_src.join("alloy.c");
    let mut core = fs::read_to_string(core_path.as_path()).unwrap();
    core = core.replace("!CharToOemBuffA(buf, buf, size)", "false");
    if is_android {
        core = core.replace(
            "memset(ior, -1, sizeof(osal_ioring_t))",
            "memset(ior, 0, sizeof(osal_ioring_t))",
        );
        core = core.replace("unlikely(linux_kernel_version < 0x04000000)", "false");
        core = core.replace(
            "assert(linux_kernel_version >= 0x03060000);",
            "if (linux_kernel_version >= 0x03060000) return MDBX_SUCCESS;
            __fallthrough",
        );
    }
    fs::write(core_path.as_path(), core).unwrap();

    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());

    // Configure bindgen with iOS-specific settings
    let mut bindgen_builder = bindgen::Builder::default()
        .header(mdbx_root.join("mdbx.h").to_string_lossy())
        .allowlist_var("^(MDBX|mdbx)_.*")
        .allowlist_type("^(MDBX|mdbx)_.*")
        .allowlist_function("^(MDBX|mdbx)_.*")
        .rustified_enum("^(MDBX_option_t|MDBX_cursor_op)")
        .size_t_is_usize(false)
        .ctypes_prefix("std::ffi")
        .parse_callbacks(Box::new(Callbacks))
        .layout_tests(false)
        .prepend_enum_name(false)
        .generate_comments(true)
        .disable_header_comment();

    // Add iOS-specific clang args for bindgen
    let target = env::var("TARGET").unwrap();
    if target.contains("apple-ios") {
        if let Ok(sdk_path) = env::var("SDKROOT") {
            bindgen_builder = bindgen_builder
                .clang_arg(format!("-isysroot{}", sdk_path))
                .clang_arg("-x")
                .clang_arg("c");
        } else {
            // Try to find the iOS SDK automatically
            let sdk_name = if target.contains("ios-sim") || target.contains("x86_64-apple-ios") {
                "iphonesimulator"
            } else {
                "iphoneos"
            };
            
            if let Ok(output) = Command::new("xcrun")
                .args(&["--sdk", sdk_name, "--show-sdk-path"])
                .output()
            {
                if output.status.success() {
                    let sdk_path_str = String::from_utf8_lossy(&output.stdout);
                    let sdk_path = sdk_path_str.trim();
                    bindgen_builder = bindgen_builder
                        .clang_arg(format!("-isysroot{}", sdk_path))
                        .clang_arg("-x")
                        .clang_arg("c");
                }
            }
        }
        
        // Add target-specific flags
        if target.contains("aarch64-apple-ios-sim") {
            bindgen_builder = bindgen_builder
                .clang_arg("--target=arm64-apple-ios-simulator");
        } else if target.contains("aarch64-apple-ios") {
            bindgen_builder = bindgen_builder
                .clang_arg("--target=arm64-apple-ios");
        } else if target.contains("x86_64-apple-ios") {
            bindgen_builder = bindgen_builder
                .clang_arg("--target=x86_64-apple-ios-simulator");
        }
    }

    let bindings = bindgen_builder
        .generate()
        .expect("Unable to generate bindings");

    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Couldn't write bindings!");

    let mut cc_builder = cc::Build::new();
    let flags = format!("{:?}", cc_builder.get_compiler().cflags_env());
    cc_builder.flag_if_supported("-Wno-everything");

    if cfg!(windows) {
        // Use native cc build for Windows (much faster than CMake)
        cc_builder
            .define("MDBX_BUILD_FLAGS", flags.as_str())
            .define("MDBX_BUILD_CXX", "0")
            .define("MDBX_BUILD_TOOLS", "0")
            .define("MDBX_BUILD_SHARED_LIBRARY", "0")
            .define("MDBX_LOCK_SUFFIX", "\".lock\"")
            .define("MDBX_TXN_CHECKOWNER", "0")
            .define("MDBX_WITHOUT_MSVC_CRT", "1")
            .define("UNICODE", "1")
            .define("HAVE_LIBM", "1")
            .define("NDEBUG", "1")
            // Windows specific includes and flags
            .include(mdbx_root.join("src"))
            .file(mdbx_src.join("alloy.c"))
            .flag_if_supported("/w") // Suppress warnings on MSVC
            .flag_if_supported("-w") // Suppress warnings on MinGW
            .compile("libmdbx.a");
            
        // Link Windows system libraries
        println!(r"cargo:rustc-link-lib=ntdll");
        println!(r"cargo:rustc-link-lib=kernel32");
        println!(r"cargo:rustc-link-lib=user32");
        println!(r"cargo:rustc-link-lib=advapi32");
    } else {
        // Non-Windows platforms (Linux, macOS, etc.)
        cc_builder
            .define("MDBX_BUILD_FLAGS", flags.as_str())
            .define("MDBX_BUILD_CXX", "0")
            .define("MDBX_BUILD_TOOLS", "0")
            .define("MDBX_BUILD_SHARED_LIBRARY", "0")
            .define("MDBX_LOCK_SUFFIX", "\".lock\"")
            .define("MDBX_TXN_CHECKOWNER", "0")
            .define("MDBX_APPLE_SPEED_INSTEADOF_DURABILITY", "1")
            .define("MDBX_HAVE_BUILTIN_CPU_SUPPORTS", "0")
            .define("NDEBUG", "1")
            .include(mdbx_root.join("src")) 
            .file(mdbx_src.join("alloy.c"))  
            .compile("libmdbx.a");
    }
}
