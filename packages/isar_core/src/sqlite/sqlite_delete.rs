use crate::core::error::Result;
#[cfg(all(target_arch = "wasm32", target_os = "unknown"))]
use super::wasm;

#[cfg(not(all(target_arch = "wasm32", target_os = "unknown")))]
use std::fs::remove_file;
#[cfg(not(all(target_arch = "wasm32", target_os = "unknown")))]
use std::path::PathBuf;
#[cfg(not(all(target_arch = "wasm32", target_os = "unknown")))]
use crate::SQLITE_MEMORY_DIR;

pub fn delete_database_files(name: &str, dir: &str) -> Result<()> {
    #[cfg(all(target_arch = "wasm32", target_os = "unknown"))]
    {
        return wasm::delete_database(name, dir);
    }

    #[cfg(not(all(target_arch = "wasm32", target_os = "unknown")))]
    {
        if dir == SQLITE_MEMORY_DIR {
            // Memory databases don't have files to delete
            return Ok(());
        }

        let mut path_buf = PathBuf::from(dir);
        path_buf.push(format!("{}.sqlite", name));
        let path = path_buf.to_string_lossy().to_string();

        // Remove main database file
        let _ = remove_file(&path_buf);

        // Remove WAL file
        let _ = remove_file(&format!("{}-wal", path));

        // Remove SHM file
        let _ = remove_file(&format!("{}-shm", path));

        Ok(())
    }
}
