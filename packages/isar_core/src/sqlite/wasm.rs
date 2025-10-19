use libsqlite3_sys::{
    sqlite3_file, sqlite3_io_methods, sqlite3_vfs, sqlite3_vfs_register, 
    SQLITE_IOERR, SQLITE_OK, SQLITE_CANTOPEN, SQLITE_IOERR_READ,
    SQLITE_IOERR_WRITE, SQLITE_IOERR_TRUNCATE, SQLITE_IOERR_FSYNC,
    SQLITE_IOERR_DELETE, SQLITE_IOERR_ACCESS, SQLITE_OPEN_READONLY,
    SQLITE_OPEN_READWRITE, SQLITE_OPEN_CREATE, SQLITE_OPEN_EXCLUSIVE,
    SQLITE_OPEN_DELETEONCLOSE, SQLITE_LOCK_NONE, SQLITE_LOCK_SHARED,
    SQLITE_LOCK_RESERVED, SQLITE_LOCK_PENDING, SQLITE_LOCK_EXCLUSIVE,
};
use std::ffi::CStr;
use std::os::raw::{c_char, c_int, c_void};
use std::ptr::null_mut;
use std::sync::atomic::{AtomicI32, Ordering};

// External JavaScript functions for OPFS bridge
extern "C" {
    // OPFS bridge functions - these are imported from JavaScript
    fn isar_opfs_open(path_ptr: *const u8, path_len: usize, flags: i32) -> i32;
    fn isar_opfs_close(fd: i32) -> i32;
    fn isar_opfs_read(fd: i32, buffer: *mut u8, buffer_len: usize, offset: i64) -> i32;
    fn isar_opfs_write(fd: i32, data: *const u8, data_len: usize, offset: i64) -> i32;
    fn isar_opfs_truncate(fd: i32, size: i64) -> i32;
    fn isar_opfs_sync(fd: i32) -> i32;
    fn isar_opfs_file_size(fd: i32) -> i64;
    fn isar_opfs_delete(path_ptr: *const u8, path_len: usize) -> i32;
    fn isar_opfs_access(path_ptr: *const u8, path_len: usize) -> i32;
    fn isar_opfs_lock(fd: i32, lock_type: i32) -> i32;
    fn isar_opfs_unlock(fd: i32, lock_type: i32) -> i32;
}

// Custom sqlite3_file structure that includes our file descriptor
#[repr(C)]
struct WasmFile {
    base: sqlite3_file,
    fd: AtomicI32,
    lock_level: AtomicI32,
}

impl WasmFile {
    fn new() -> Self {
        WasmFile {
            base: sqlite3_file {
                pMethods: null_mut(),
            },
            fd: AtomicI32::new(-1),
            lock_level: AtomicI32::new(SQLITE_LOCK_NONE),
        }
    }
}


// IO Methods for OPFS-backed files
static WASM_IO_METHODS: sqlite3_io_methods = sqlite3_io_methods {
    iVersion: 1,
    xClose: Some(wasm_file_close),
    xRead: Some(wasm_file_read),
    xWrite: Some(wasm_file_write),
    xTruncate: Some(wasm_file_truncate),
    xSync: Some(wasm_file_sync),
    xFileSize: Some(wasm_file_size),
    xLock: Some(wasm_file_lock),
    xUnlock: Some(wasm_file_unlock),
    xCheckReservedLock: Some(wasm_file_check_reserved_lock),
    xFileControl: Some(wasm_file_control),
    xSectorSize: Some(wasm_file_sector_size),
    xDeviceCharacteristics: Some(wasm_file_device_characteristics),
    xShmMap: None,
    xShmLock: None,
    xShmBarrier: None,
    xShmUnmap: None,
    xFetch: None,
    xUnfetch: None,
};

#[no_mangle]
pub unsafe extern "C" fn sqlite3_os_init() -> c_int {
    let vfs = sqlite3_vfs {
        iVersion: 1,
        szOsFile: std::mem::size_of::<WasmFile>() as c_int,
        mxPathname: 1024,
        pNext: null_mut(),
        zName: "opfs-wasm\0".as_ptr() as *const c_char,
        pAppData: null_mut(),
        xOpen: Some(wasm_vfs_open),
        xDelete: Some(wasm_vfs_delete),
        xAccess: Some(wasm_vfs_access),
        xFullPathname: Some(wasm_vfs_fullpathname),
        xDlOpen: Some(wasm_vfs_dlopen),
        xDlError: Some(wasm_vfs_dlerror),
        xDlSym: Some(wasm_vfs_dlsym),
        xDlClose: Some(wasm_vfs_dlclose),
        xRandomness: Some(xRandomness),
        xSleep: Some(xSleep),
        xCurrentTime: Some(xCurrentTime),
        xGetLastError: None,
        xCurrentTimeInt64: None,
        xSetSystemCall: None,
        xGetSystemCall: None,
        xNextSystemCall: None,
    };

    sqlite3_vfs_register(Box::leak(Box::new(vfs)), 1)
}

pub unsafe extern "C" fn xSleep(_arg1: *mut sqlite3_vfs, microseconds: c_int) -> c_int {
    0
}

pub unsafe extern "C" fn xRandomness(
    _arg1: *mut sqlite3_vfs,
    nByte: c_int,
    zByte: *mut c_char,
) -> c_int {
    0
}

pub unsafe extern "C" fn xCurrentTime(_arg1: *mut sqlite3_vfs, pTime: *mut f64) -> c_int {
    0
}

const fn max(a: usize, b: usize) -> usize {
    [a, b][(a < b) as usize]
}

const ALIGN: usize = max(
    8, // wasm32 max_align_t
    max(std::mem::size_of::<usize>(), std::mem::align_of::<usize>()),
);

#[no_mangle]
pub unsafe extern "C" fn malloc(size: usize) -> *mut u8 {
    let layout = match std::alloc::Layout::from_size_align(size + ALIGN, ALIGN) {
        Ok(layout) => layout,
        Err(_) => return null_mut(),
    };

    let ptr = std::alloc::alloc(layout);
    if ptr.is_null() {
        return null_mut();
    }

    *(ptr as *mut usize) = size;
    ptr.offset(ALIGN as isize)
}

#[no_mangle]
pub unsafe extern "C" fn free(ptr: *mut u8) {
    let ptr = ptr.offset(-(ALIGN as isize));
    let size = *(ptr as *mut usize);
    let layout = std::alloc::Layout::from_size_align_unchecked(size + ALIGN, ALIGN);

    std::alloc::dealloc(ptr, layout);
}

#[no_mangle]
pub unsafe extern "C" fn realloc(ptr: *mut u8, new_size: usize) -> *mut u8 {
    let ptr = ptr.offset(-(ALIGN as isize));
    let size = *(ptr as *mut usize);
    let layout = std::alloc::Layout::from_size_align_unchecked(size + ALIGN, ALIGN);

    let ptr = std::alloc::realloc(ptr, layout, new_size + ALIGN);
    if ptr.is_null() {
        return null_mut();
    }

    *(ptr as *mut usize) = new_size;
    ptr.offset(ALIGN as isize)
}

#[no_mangle]
unsafe extern "C" fn wasm_vfs_open(
    _vfs: *mut sqlite3_vfs,
    z_name: *const c_char,
    file: *mut sqlite3_file,
    flags: c_int,
    p_out_flags: *mut c_int,
) -> c_int {
    if file.is_null() {
        return SQLITE_IOERR;
    }

    // Initialize the file structure
    let wasm_file = file as *mut WasmFile;
    *wasm_file = WasmFile::new();

    // Get the file path
    let path = if z_name.is_null() {
        // Temporary file - use a unique name
        format!("/tmp/sqlite-temp-{}", std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis())
    } else {
        match CStr::from_ptr(z_name).to_str() {
            Ok(s) => s.to_string(),
            Err(_) => return SQLITE_IOERR,
        }
    };

    // Convert SQLite flags to OPFS flags
    let mut opfs_flags = 0;
    if (flags & SQLITE_OPEN_CREATE) != 0 {
        opfs_flags |= 1; // CREATE
    }
    if (flags & SQLITE_OPEN_READONLY) != 0 {
        opfs_flags |= 2; // READ
    }
    if (flags & SQLITE_OPEN_READWRITE) != 0 {
        opfs_flags |= 6; // READ | WRITE
    }
    if (flags & SQLITE_OPEN_EXCLUSIVE) != 0 {
        opfs_flags |= 8; // EXCLUSIVE
    }
    if (flags & SQLITE_OPEN_DELETEONCLOSE) != 0 {
        opfs_flags |= 16; // TRUNCATE
    }

    // Call JavaScript bridge to open the file
    let fd = isar_opfs_open(path.as_ptr(), path.len(), opfs_flags);
    
    if fd < 0 {
        // Error opening file
        return if fd == -14 { SQLITE_CANTOPEN } else { SQLITE_IOERR };
    }

    // Store the file descriptor
    (*wasm_file).fd.store(fd, Ordering::SeqCst);
    
    // Set the IO methods
    (*wasm_file).base.pMethods = &WASM_IO_METHODS as *const _ as *mut _;

    // Set output flags if requested
    if !p_out_flags.is_null() {
        *p_out_flags = flags & (SQLITE_OPEN_READONLY | SQLITE_OPEN_READWRITE);
    }

    SQLITE_OK
}

#[no_mangle]
unsafe extern "C" fn wasm_vfs_delete(
    _vfs: *mut sqlite3_vfs,
    z_name: *const c_char,
    _sync_dir: c_int,
) -> c_int {
    if z_name.is_null() {
        return SQLITE_IOERR;
    }

    let path = match CStr::from_ptr(z_name).to_str() {
        Ok(s) => s,
        Err(_) => return SQLITE_IOERR,
    };

    let result = isar_opfs_delete(path.as_ptr(), path.len());
    
    if result == 0 {
        SQLITE_OK
    } else {
        SQLITE_IOERR_DELETE
    }
}

#[no_mangle]
unsafe extern "C" fn wasm_vfs_access(
    _vfs: *mut sqlite3_vfs,
    z_name: *const c_char,
    _flags: c_int,
    p_res_out: *mut c_int,
) -> c_int {
    if z_name.is_null() || p_res_out.is_null() {
        return SQLITE_IOERR;
    }

    let path = match CStr::from_ptr(z_name).to_str() {
        Ok(s) => s,
        Err(_) => return SQLITE_IOERR,
    };

    let result = isar_opfs_access(path.as_ptr(), path.len());
    
    if result < 0 {
        return SQLITE_IOERR_ACCESS;
    }

    *p_res_out = result;
    SQLITE_OK
}

#[no_mangle]
unsafe extern "C" fn wasm_vfs_fullpathname(
    _vfs: *mut sqlite3_vfs,
    z_name: *const c_char,
    n_out: c_int,
    z_out: *mut c_char,
) -> c_int {
    if z_name.is_null() || z_out.is_null() {
        return SQLITE_IOERR;
    }

    let path = match CStr::from_ptr(z_name).to_str() {
        Ok(s) => s,
        Err(_) => return SQLITE_IOERR,
    };

    // Simply copy the path (OPFS uses absolute paths from root)
    let path_bytes = path.as_bytes();
    let copy_len = std::cmp::min(path_bytes.len(), (n_out - 1) as usize);
    
    std::ptr::copy_nonoverlapping(
        path_bytes.as_ptr() as *const c_char,
        z_out,
        copy_len,
    );
    *z_out.add(copy_len) = 0; // Null terminator

    SQLITE_OK
}

// File IO Methods

#[no_mangle]
unsafe extern "C" fn wasm_file_close(file: *mut sqlite3_file) -> c_int {
    if file.is_null() {
        return SQLITE_IOERR;
    }

    let wasm_file = file as *mut WasmFile;
    let fd = (*wasm_file).fd.load(Ordering::SeqCst);
    
    if fd < 0 {
        return SQLITE_OK; // Already closed
    }

    let result = isar_opfs_close(fd);
    (*wasm_file).fd.store(-1, Ordering::SeqCst);
    
    if result == 0 {
        SQLITE_OK
    } else {
        SQLITE_IOERR
    }
}

#[no_mangle]
unsafe extern "C" fn wasm_file_read(
    file: *mut sqlite3_file,
    buffer: *mut c_void,
    amount: c_int,
    offset: i64,
) -> c_int {
    if file.is_null() || buffer.is_null() {
        return SQLITE_IOERR_READ;
    }

    let wasm_file = file as *mut WasmFile;
    let fd = (*wasm_file).fd.load(Ordering::SeqCst);
    
    if fd < 0 {
        return SQLITE_IOERR_READ;
    }

    let bytes_read = isar_opfs_read(
        fd,
        buffer as *mut u8,
        amount as usize,
        offset,
    );

    if bytes_read < 0 {
        return SQLITE_IOERR_READ;
    }

    if bytes_read < amount {
        // Fill the rest with zeros (SQLite expects this)
        let remaining = (amount - bytes_read) as usize;
        std::ptr::write_bytes(
            (buffer as *mut u8).add(bytes_read as usize),
            0,
            remaining,
        );
    }

    SQLITE_OK
}

#[no_mangle]
unsafe extern "C" fn wasm_file_write(
    file: *mut sqlite3_file,
    data: *const c_void,
    amount: c_int,
    offset: i64,
) -> c_int {
    if file.is_null() || data.is_null() {
        return SQLITE_IOERR_WRITE;
    }

    let wasm_file = file as *mut WasmFile;
    let fd = (*wasm_file).fd.load(Ordering::SeqCst);
    
    if fd < 0 {
        return SQLITE_IOERR_WRITE;
    }

    let bytes_written = isar_opfs_write(
        fd,
        data as *const u8,
        amount as usize,
        offset,
    );

    if bytes_written != amount {
        return SQLITE_IOERR_WRITE;
    }

    SQLITE_OK
}

#[no_mangle]
unsafe extern "C" fn wasm_file_truncate(file: *mut sqlite3_file, size: i64) -> c_int {
    if file.is_null() {
        return SQLITE_IOERR_TRUNCATE;
    }

    let wasm_file = file as *mut WasmFile;
    let fd = (*wasm_file).fd.load(Ordering::SeqCst);
    
    if fd < 0 {
        return SQLITE_IOERR_TRUNCATE;
    }

    let result = isar_opfs_truncate(fd, size);
    
    if result == 0 {
        SQLITE_OK
    } else {
        SQLITE_IOERR_TRUNCATE
    }
}

#[no_mangle]
unsafe extern "C" fn wasm_file_sync(file: *mut sqlite3_file, _flags: c_int) -> c_int {
    if file.is_null() {
        return SQLITE_IOERR_FSYNC;
    }

    let wasm_file = file as *mut WasmFile;
    let fd = (*wasm_file).fd.load(Ordering::SeqCst);
    
    if fd < 0 {
        return SQLITE_IOERR_FSYNC;
    }

    let result = isar_opfs_sync(fd);
    
    if result == 0 {
        SQLITE_OK
    } else {
        SQLITE_IOERR_FSYNC
    }
}

#[no_mangle]
unsafe extern "C" fn wasm_file_size(file: *mut sqlite3_file, size: *mut i64) -> c_int {
    if file.is_null() || size.is_null() {
        return SQLITE_IOERR;
    }

    let wasm_file = file as *mut WasmFile;
    let fd = (*wasm_file).fd.load(Ordering::SeqCst);
    
    if fd < 0 {
        return SQLITE_IOERR;
    }

    let file_size = isar_opfs_file_size(fd);
    
    if file_size < 0 {
        return SQLITE_IOERR;
    }

    *size = file_size;
    SQLITE_OK
}

#[no_mangle]
unsafe extern "C" fn wasm_file_lock(file: *mut sqlite3_file, lock_type: c_int) -> c_int {
    if file.is_null() {
        return SQLITE_IOERR;
    }

    let wasm_file = file as *mut WasmFile;
    let fd = (*wasm_file).fd.load(Ordering::SeqCst);
    
    if fd < 0 {
        return SQLITE_IOERR;
    }

    let result = isar_opfs_lock(fd, lock_type);
    
    if result == 0 {
        (*wasm_file).lock_level.store(lock_type, Ordering::SeqCst);
        SQLITE_OK
    } else {
        SQLITE_IOERR
    }
}

#[no_mangle]
unsafe extern "C" fn wasm_file_unlock(file: *mut sqlite3_file, lock_type: c_int) -> c_int {
    if file.is_null() {
        return SQLITE_IOERR;
    }

    let wasm_file = file as *mut WasmFile;
    let fd = (*wasm_file).fd.load(Ordering::SeqCst);
    
    if fd < 0 {
        return SQLITE_IOERR;
    }

    let result = isar_opfs_unlock(fd, lock_type);
    
    if result == 0 {
        (*wasm_file).lock_level.store(lock_type, Ordering::SeqCst);
        SQLITE_OK
    } else {
        SQLITE_IOERR
    }
}

#[no_mangle]
unsafe extern "C" fn wasm_file_check_reserved_lock(
    file: *mut sqlite3_file,
    res_out: *mut c_int,
) -> c_int {
    if file.is_null() || res_out.is_null() {
        return SQLITE_IOERR;
    }

    let wasm_file = file as *mut WasmFile;
    let lock_level = (*wasm_file).lock_level.load(Ordering::SeqCst);
    
    *res_out = if lock_level >= SQLITE_LOCK_RESERVED { 1 } else { 0 };
    SQLITE_OK
}

#[no_mangle]
unsafe extern "C" fn wasm_file_control(
    _file: *mut sqlite3_file,
    _op: c_int,
    _arg: *mut c_void,
) -> c_int {
    // Not implemented - return not found
    1 // SQLITE_NOTFOUND
}

#[no_mangle]
unsafe extern "C" fn wasm_file_sector_size(_file: *mut sqlite3_file) -> c_int {
    4096 // Standard page size
}

#[no_mangle]
unsafe extern "C" fn wasm_file_device_characteristics(_file: *mut sqlite3_file) -> c_int {
    0 // No special characteristics
}

#[no_mangle]
unsafe extern "C" fn wasm_vfs_dlopen(
    _arg1: *mut sqlite3_vfs,
    _zFilename: *const c_char,
) -> *mut c_void {
    null_mut()
}

#[no_mangle]
unsafe extern "C" fn wasm_vfs_dlerror(
    _arg1: *mut sqlite3_vfs,
    _nByte: c_int,
    _zErrMsg: *mut c_char,
) {
    // no-op
}

#[no_mangle]
unsafe extern "C" fn wasm_vfs_dlsym(
    _arg1: *mut sqlite3_vfs,
    _arg2: *mut c_void,
    _zSymbol: *const c_char,
) -> ::std::option::Option<unsafe extern "C" fn(*mut sqlite3_vfs, *mut c_void, *const i8)> {
    None
}

#[no_mangle]
unsafe extern "C" fn wasm_vfs_dlclose(_arg1: *mut sqlite3_vfs, _arg2: *mut c_void) {
    // no-op
}
