use crate::core::error::Result;
use crate::SQLITE_MEMORY_DIR;
use std::fs::remove_file;
use std::path::PathBuf;

pub fn delete_database_files(name: &str, dir: &str) -> Result<()> {
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