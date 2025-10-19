/**
 * OPFS Bridge for Isar SQLite VFS
 *
 * This module provides a JavaScript bridge between the Rust WASM core and the
 * Origin-Private File System (OPFS) APIs. It implements synchronous file operations
 * using FileSystemSyncAccessHandle when available.
 *
 * Requirements:
 * - Must run in a Worker context (OPFS sync APIs not available on main thread)
 * - Requires COOP/COEP headers for SharedArrayBuffer support
 * - Browser must support OPFS (Chrome 102+, Edge 102+, Firefox 111+, Safari 16.4+)
 */

class OPFSBridge {
  constructor() {
    // Map of file descriptor (integer) -> { handle: FileSystemSyncAccessHandle, path: string }
    this.openFiles = new Map();
    this.nextFd = 1;
    this.rootDir = null;
    this.initialized = false;
    this.supportsOPFS = false;
  }

  /**
   * Initialize the OPFS bridge
   * @returns {Promise<boolean>} true if OPFS is available, false otherwise
   */
  async initialize() {
    if (this.initialized) {
      return this.supportsOPFS;
    }

    try {
      // Check if OPFS is available
      if (!navigator.storage || !navigator.storage.getDirectory) {
        console.warn("OPFS not available in this browser");
        this.initialized = true;
        this.supportsOPFS = false;
        return false;
      }

      // Get the OPFS root directory
      this.rootDir = await navigator.storage.getDirectory();
      this.supportsOPFS = true;
      this.initialized = true;
      console.log("OPFS initialized successfully");
      return true;
    } catch (error) {
      console.error("Failed to initialize OPFS:", error);
      this.initialized = true;
      this.supportsOPFS = false;
      return false;
    }
  }

  /**
   * Ensure a directory path exists, creating it if necessary
   * @param {string} path - Path to ensure (e.g., "/my/db/file.db" ensures "/my/db" exists)
   */
  async ensureDirectory(path) {
    const parts = path.split("/").filter((p) => p && p !== ".");

    // Remove the filename from the end
    if (parts.length > 0 && parts[parts.length - 1].includes(".")) {
      parts.pop();
    }

    let currentDir = this.rootDir;
    for (const part of parts) {
      try {
        currentDir = await currentDir.getDirectoryHandle(part, {
          create: true,
        });
      } catch (error) {
        console.error(`Failed to create directory ${part}:`, error);
        throw error;
      }
    }
  }

  /**
   * Open or create a file and return a file descriptor
   * @param {string} path - File path (e.g., "/databases/mydb.db")
   * @param {number} flags - Open flags (bitfield: 1=create, 2=read, 4=write, 8=exclusive, 16=truncate)
   * @returns {Promise<number>} File descriptor (>0) or error code (<0)
   */
  async open(path, flags) {
    try {
      if (!this.supportsOPFS) {
        return -1; // SQLITE_ERROR
      }

      // Normalize path (remove leading slash if present)
      const normalizedPath = path.startsWith("/") ? path.slice(1) : path;
      if (!normalizedPath) {
        return -14; // SQLITE_CANTOPEN
      }

      // Ensure directory exists
      await this.ensureDirectory(normalizedPath);

      // Parse path to get directory and filename
      const pathParts = normalizedPath.split("/").filter((p) => p);
      const fileName = pathParts.pop();

      let currentDir = this.rootDir;
      for (const part of pathParts) {
        currentDir = await currentDir.getDirectoryHandle(part, {
          create: true,
        });
      }

      const createIfNotExists = (flags & 1) !== 0;
      const truncate = (flags & 16) !== 0;

      // Get or create the file handle
      const fileHandle = await currentDir.getFileHandle(fileName, {
        create: createIfNotExists,
      });

      // Get sync access handle (requires Worker context)
      const syncHandle = await fileHandle.createSyncAccessHandle();

      // Truncate if requested
      if (truncate) {
        syncHandle.truncate(0);
        syncHandle.flush();
      }

      // Store the handle with a file descriptor
      const fd = this.nextFd++;
      this.openFiles.set(fd, {
        handle: syncHandle,
        path: normalizedPath,
        size: syncHandle.getSize(),
      });

      return fd;
    } catch (error) {
      console.error(`Failed to open file ${path}:`, error);
      if (error.name === "NotFoundError") {
        return -14; // SQLITE_CANTOPEN
      }
      return -1; // SQLITE_ERROR
    }
  }

  /**
   * Close a file descriptor
   * @param {number} fd - File descriptor
   * @returns {number} 0 on success, error code on failure
   */
  close(fd) {
    try {
      const file = this.openFiles.get(fd);
      if (!file) {
        return -1; // SQLITE_ERROR
      }

      file.handle.close();
      this.openFiles.delete(fd);
      return 0; // SQLITE_OK
    } catch (error) {
      console.error(`Failed to close fd ${fd}:`, error);
      return -1; // SQLITE_ERROR
    }
  }

  /**
   * Read from a file
   * @param {number} fd - File descriptor
   * @param {Uint8Array} buffer - Buffer to read into
   * @param {number} offset - Offset in file to read from
   * @returns {number} Number of bytes read, or negative error code
   */
  read(fd, buffer, offset) {
    try {
      const file = this.openFiles.get(fd);
      if (!file) {
        return -1; // SQLITE_ERROR
      }

      const bytesRead = file.handle.read(buffer, { at: offset });
      return bytesRead;
    } catch (error) {
      console.error(`Failed to read from fd ${fd}:`, error);
      return -10; // SQLITE_IOERR_READ
    }
  }

  /**
   * Write to a file
   * @param {number} fd - File descriptor
   * @param {Uint8Array} data - Data to write
   * @param {number} offset - Offset in file to write to
   * @returns {number} Number of bytes written, or negative error code
   */
  write(fd, data, offset) {
    try {
      const file = this.openFiles.get(fd);
      if (!file) {
        return -1; // SQLITE_ERROR
      }

      const bytesWritten = file.handle.write(data, { at: offset });
      file.handle.flush();

      // Update size if we wrote beyond current size
      const newSize = Math.max(file.size, offset + bytesWritten);
      if (newSize > file.size) {
        file.size = newSize;
      }

      return bytesWritten;
    } catch (error) {
      console.error(`Failed to write to fd ${fd}:`, error);
      return -10; // SQLITE_IOERR_WRITE
    }
  }

  /**
   * Truncate a file to a specific size
   * @param {number} fd - File descriptor
   * @param {number} size - New size in bytes
   * @returns {number} 0 on success, error code on failure
   */
  truncate(fd, size) {
    try {
      const file = this.openFiles.get(fd);
      if (!file) {
        return -1; // SQLITE_ERROR
      }

      file.handle.truncate(size);
      file.handle.flush();
      file.size = size;
      return 0; // SQLITE_OK
    } catch (error) {
      console.error(`Failed to truncate fd ${fd}:`, error);
      return -10; // SQLITE_IOERR_TRUNCATE
    }
  }

  /**
   * Sync file data to disk
   * @param {number} fd - File descriptor
   * @returns {number} 0 on success, error code on failure
   */
  sync(fd) {
    try {
      const file = this.openFiles.get(fd);
      if (!file) {
        return -1; // SQLITE_ERROR
      }

      file.handle.flush();
      return 0; // SQLITE_OK
    } catch (error) {
      console.error(`Failed to sync fd ${fd}:`, error);
      return -10; // SQLITE_IOERR_FSYNC
    }
  }

  /**
   * Get file size
   * @param {number} fd - File descriptor
   * @returns {number} File size in bytes, or negative error code
   */
  fileSize(fd) {
    try {
      const file = this.openFiles.get(fd);
      if (!file) {
        return -1; // SQLITE_ERROR
      }

      return file.handle.getSize();
    } catch (error) {
      console.error(`Failed to get size of fd ${fd}:`, error);
      return -1; // SQLITE_ERROR
    }
  }

  /**
   * Delete a file
   * @param {string} path - File path to delete
   * @returns {Promise<number>} 0 on success, error code on failure
   */
  async delete(path) {
    try {
      if (!this.supportsOPFS) {
        return -1; // SQLITE_ERROR
      }

      const normalizedPath = path.startsWith("/") ? path.slice(1) : path;
      if (!normalizedPath) {
        return -1; // SQLITE_ERROR
      }

      // Parse path to get directory and filename
      const pathParts = normalizedPath.split("/").filter((p) => p);
      const fileName = pathParts.pop();

      let currentDir = this.rootDir;
      for (const part of pathParts) {
        try {
          currentDir = await currentDir.getDirectoryHandle(part);
        } catch (error) {
          // Directory doesn't exist, so file doesn't exist
          return 0; // SQLITE_OK (deleting non-existent file is OK)
        }
      }

      await currentDir.removeEntry(fileName);
      return 0; // SQLITE_OK
    } catch (error) {
      if (error.name === "NotFoundError") {
        return 0; // SQLITE_OK (deleting non-existent file is OK)
      }
      console.error(`Failed to delete file ${path}:`, error);
      return -10; // SQLITE_IOERR_DELETE
    }
  }

  /**
   * Check if a file exists
   * @param {string} path - File path to check
   * @returns {Promise<number>} 1 if exists, 0 if not, negative on error
   */
  async access(path) {
    try {
      if (!this.supportsOPFS) {
        return -1; // SQLITE_ERROR
      }

      const normalizedPath = path.startsWith("/") ? path.slice(1) : path;
      if (!normalizedPath) {
        return 0; // File doesn't exist
      }

      // Parse path to get directory and filename
      const pathParts = normalizedPath.split("/").filter((p) => p);
      const fileName = pathParts.pop();

      let currentDir = this.rootDir;
      for (const part of pathParts) {
        try {
          currentDir = await currentDir.getDirectoryHandle(part);
        } catch (error) {
          return 0; // Directory doesn't exist, so file doesn't exist
        }
      }

      await currentDir.getFileHandle(fileName);
      return 1; // File exists
    } catch (error) {
      if (error.name === "NotFoundError") {
        return 0; // File doesn't exist
      }
      console.error(`Failed to check access for ${path}:`, error);
      return -1; // SQLITE_ERROR
    }
  }

  /**
   * Lock a file (simplified - OPFS sync handles provide exclusive access)
   * @param {number} fd - File descriptor
   * @param {number} lockType - Lock type (not used in OPFS)
   * @returns {number} 0 on success, error code on failure
   */
  lock(fd, lockType) {
    // OPFS sync access handles are exclusive by nature
    // Just verify the fd is valid
    const file = this.openFiles.get(fd);
    if (!file) {
      return -1; // SQLITE_ERROR
    }
    return 0; // SQLITE_OK
  }

  /**
   * Unlock a file
   * @param {number} fd - File descriptor
   * @param {number} lockType - Lock type (not used in OPFS)
   * @returns {number} 0 on success, error code on failure
   */
  unlock(fd, lockType) {
    // OPFS sync access handles are exclusive by nature
    // Just verify the fd is valid
    const file = this.openFiles.get(fd);
    if (!file) {
      return -1; // SQLITE_ERROR
    }
    return 0; // SQLITE_OK
  }
}

// Export the bridge instance
const opfsBridge = new OPFSBridge();

// Export functions for WASM imports
export const isar_opfs_init = async () => {
  return (await opfsBridge.initialize()) ? 1 : 0;
};

export const isar_opfs_open = async (pathPtr, pathLen, flags) => {
  const decoder = new TextDecoder();
  const pathBytes = new Uint8Array(memory.buffer, pathPtr, pathLen);
  const path = decoder.decode(pathBytes);
  return await opfsBridge.open(path, flags);
};

export const isar_opfs_close = (fd) => {
  return opfsBridge.close(fd);
};

export const isar_opfs_read = (fd, bufferPtr, bufferLen, offset) => {
  const buffer = new Uint8Array(memory.buffer, bufferPtr, bufferLen);
  return opfsBridge.read(fd, buffer, offset);
};

export const isar_opfs_write = (fd, dataPtr, dataLen, offset) => {
  const data = new Uint8Array(memory.buffer, dataPtr, dataLen);
  return opfsBridge.write(fd, data, offset);
};

export const isar_opfs_truncate = (fd, size) => {
  return opfsBridge.truncate(fd, size);
};

export const isar_opfs_sync = (fd) => {
  return opfsBridge.sync(fd);
};

export const isar_opfs_file_size = (fd) => {
  return opfsBridge.fileSize(fd);
};

export const isar_opfs_delete = async (pathPtr, pathLen) => {
  const decoder = new TextDecoder();
  const pathBytes = new Uint8Array(memory.buffer, pathPtr, pathLen);
  const path = decoder.decode(pathBytes);
  return await opfsBridge.delete(path);
};

export const isar_opfs_access = async (pathPtr, pathLen) => {
  const decoder = new TextDecoder();
  const pathBytes = new Uint8Array(memory.buffer, pathPtr, pathLen);
  const path = decoder.decode(pathBytes);
  return await opfsBridge.access(path);
};

export const isar_opfs_lock = (fd, lockType) => {
  return opfsBridge.lock(fd, lockType);
};

export const isar_opfs_unlock = (fd, lockType) => {
  return opfsBridge.unlock(fd, lockType);
};

// Memory will be set by the worker when WASM is initialized
let memory = null;

export const setMemory = (wasmMemory) => {
  memory = wasmMemory;
};
