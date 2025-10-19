use crate::error::ERROR;
use isar_core::sqlite::wasm::{self, BackendKind, PollStatus};
use std::boxed::Box;

#[no_mangle]
pub unsafe extern "C" fn isar_web_persistence_start(dir: *mut String) -> u32 {
    let dir = *Box::from_raw(dir);
    wasm::start_persistence(dir)
}

#[no_mangle]
pub extern "C" fn isar_web_persistence_poll(handle: u32) -> u8 {
    match wasm::poll_persistence(handle) {
        PollStatus::Pending => 0,
        PollStatus::Ready => 1,
        PollStatus::Error => {
            if let Some(err) = wasm::last_error() {
                ERROR.replace(Some(err));
            }
            255
        }
        PollStatus::Unknown => {
            ERROR.replace(Some("Unknown web persistence handle".into()));
            254
        }
    }
}

#[no_mangle]
pub extern "C" fn isar_web_persistence_backend() -> u8 {
    match wasm::backend_kind() {
        BackendKind::None => 0,
        BackendKind::Opfs => 1,
        BackendKind::IndexedDb => 2,
    }
}
