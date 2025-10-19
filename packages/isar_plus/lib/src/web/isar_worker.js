/**
 * Isar Web Worker
 *
 * This worker loads the Isar WASM module with OPFS support and handles
 * message-based communication with the main Dart isolate.
 *
 * Requirements:
 * - Must be served with COOP/COEP headers for SharedArrayBuffer support
 * - Browser must support OPFS for persistence (falls back to in-memory otherwise)
 */

importScripts("./opfs_bridge.js");

let wasmInstance = null;
let wasmMemory = null;
let opfsInitialized = false;

/**
 * Initialize the WASM module with OPFS bridge
 */
async function initializeWasm(wasmUrl) {
  try {
    // Initialize OPFS first
    opfsInitialized = await isar_opfs_init();

    if (!opfsInitialized) {
      console.warn(
        "OPFS not available - persistence will not work. Falling back to in-memory mode."
      );
    }

    // Create the import object with OPFS bridge functions
    const importObject = {
      env: {
        // OPFS bridge functions
        isar_opfs_open: async (pathPtr, pathLen, flags) => {
          return await isar_opfs_open(pathPtr, pathLen, flags);
        },
        isar_opfs_close: (fd) => {
          return isar_opfs_close(fd);
        },
        isar_opfs_read: (fd, bufferPtr, bufferLen, offset) => {
          return isar_opfs_read(fd, bufferPtr, bufferLen, offset);
        },
        isar_opfs_write: (fd, dataPtr, dataLen, offset) => {
          return isar_opfs_write(fd, dataPtr, dataLen, offset);
        },
        isar_opfs_truncate: (fd, size) => {
          return isar_opfs_truncate(fd, size);
        },
        isar_opfs_sync: (fd) => {
          return isar_opfs_sync(fd);
        },
        isar_opfs_file_size: (fd) => {
          return isar_opfs_file_size(fd);
        },
        isar_opfs_delete: async (pathPtr, pathLen) => {
          return await isar_opfs_delete(pathPtr, pathLen);
        },
        isar_opfs_access: async (pathPtr, pathLen) => {
          return await isar_opfs_access(pathPtr, pathLen);
        },
        isar_opfs_lock: (fd, lockType) => {
          return isar_opfs_lock(fd, lockType);
        },
        isar_opfs_unlock: (fd, lockType) => {
          return isar_opfs_unlock(fd, lockType);
        },
      },
    };

    // Load and instantiate the WASM module
    const response = await fetch(wasmUrl);
    const wasmBytes = await response.arrayBuffer();
    const wasmModule = await WebAssembly.compile(wasmBytes);
    wasmInstance = await WebAssembly.instantiate(wasmModule, importObject);

    // Store the memory reference for the OPFS bridge
    wasmMemory = wasmInstance.exports.memory;
    setMemory(wasmMemory);

    postMessage({
      type: "initialized",
      opfsAvailable: opfsInitialized,
    });

    return true;
  } catch (error) {
    console.error("Failed to initialize WASM:", error);
    postMessage({
      type: "error",
      message: `Failed to initialize WASM: ${error.message}`,
    });
    return false;
  }
}

/**
 * Call a WASM function by name
 */
function callWasmFunction(functionName, args) {
  try {
    if (!wasmInstance) {
      throw new Error("WASM not initialized");
    }

    const func = wasmInstance.exports[functionName];
    if (!func) {
      throw new Error(`Function ${functionName} not found in WASM exports`);
    }

    const result = func(...args);
    return { success: true, result };
  } catch (error) {
    console.error(`Error calling ${functionName}:`, error);
    return { success: false, error: error.message };
  }
}

/**
 * Handle messages from the main thread
 */
self.onmessage = async function (event) {
  const { type, id, data } = event.data;

  switch (type) {
    case "initialize":
      await initializeWasm(data.wasmUrl);
      break;

    case "call":
      const result = callWasmFunction(data.functionName, data.args || []);
      postMessage({
        type: "result",
        id,
        ...result,
      });
      break;

    case "ping":
      postMessage({ type: "pong", id });
      break;

    default:
      console.warn("Unknown message type:", type);
      postMessage({
        type: "error",
        id,
        message: `Unknown message type: ${type}`,
      });
  }
};

// Notify that the worker is ready
postMessage({ type: "ready" });
