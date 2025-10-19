//! This module is codegen from build.rs

#[cfg(all(not(feature = "buildtime-bindgen"), feature = "sqlite3mc"))]
mod sqlite3mc_bindgen;

#[cfg(all(not(feature = "buildtime-bindgen"), not(feature = "sqlite3mc")))]
mod sqlite3_bindgen;

mod bindgen {
    #[cfg(feature = "buildtime-bindgen")]
    include!(concat!(env!("OUT_DIR"), "/bindgen.rs"));

    #[cfg(all(not(feature = "buildtime-bindgen"), feature = "sqlite3mc"))]
    pub use super::sqlite3mc_bindgen::*;

    #[cfg(all(not(feature = "buildtime-bindgen"), not(feature = "sqlite3mc")))]
    pub use super::sqlite3_bindgen::*;
}

mod error;

pub use bindgen::*;
pub use error::*;

use std::mem;

#[must_use]
pub fn SQLITE_STATIC() -> sqlite3_destructor_type {
    None
}

#[must_use]
pub fn SQLITE_TRANSIENT() -> sqlite3_destructor_type {
    Some(unsafe { mem::transmute::<isize, unsafe extern "C" fn(*mut std::ffi::c_void)>(-1_isize) })
}

impl Default for sqlite3_vtab {
    fn default() -> Self {
        unsafe { mem::zeroed() }
    }
}

impl Default for sqlite3_vtab_cursor {
    fn default() -> Self {
        unsafe { mem::zeroed() }
    }
}
