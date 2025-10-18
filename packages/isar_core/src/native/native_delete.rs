use super::native_open::get_isar_path;
use crate::core::error::Result;
use std::fs::remove_file;

pub fn delete_database_files(name: &str, dir: &str) -> Result<()> {
    let path = get_isar_path(name, dir);
    
    // Remove main database file
    let _ = remove_file(&path);
    
    // Remove lock file
    let lock_path = format!("{}.lock", path);
    let _ = remove_file(&lock_path);
    
    Ok(())
}