use crate::core::error::{IsarError, Result};
use crate::SQLITE_MEMORY_DIR;
use libsqlite3_sys::relaxed_idb_vfs::{self, Preload, RelaxedIdbCfg, RelaxedIdbUtil};
use libsqlite3_sys::sahpool_vfs::{self, OpfsSAHPoolCfg, OpfsSAHPoolUtil};
use std::cell::{Cell, RefCell};
use wasm_bindgen_futures::spawn_local;

thread_local! {
    static BACKEND: RefCell<Option<PersistenceBackend>> = RefCell::new(None);
    static NEXT_TASK_ID: Cell<u32> = Cell::new(1);
    static TASKS: RefCell<Vec<TaskEntry>> = RefCell::new(Vec::new());
    static LAST_ERROR: RefCell<Option<String>> = RefCell::new(None);
}

enum PersistenceBackend {
    Opfs(OpfsSAHPoolUtil),
    IndexedDb(RelaxedIdbUtil),
}

struct TaskEntry {
    id: u32,
    status: TaskStatus,
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum TaskStatus {
    Pending,
    Success,
    Error,
}

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum PollStatus {
    Pending,
    Ready,
    Error,
    Unknown,
}

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum BackendKind {
    None,
    Opfs,
    IndexedDb,
}

pub fn start_persistence(dir: String) -> u32 {
    if BACKEND.with(|backend| backend.borrow().is_some()) {
        return 0;
    }

    LAST_ERROR.with(|err| err.borrow_mut().take());

    let id = NEXT_TASK_ID.with(|next| {
        let id = next.get();
        next.set(id.saturating_add(1));
        id
    });

    TASKS.with(|tasks| {
        tasks.borrow_mut().push(TaskEntry {
            id,
            status: TaskStatus::Pending,
        });
    });

    spawn_local(async move {
        let outcome = match initialize_backend(dir).await {
            Ok(backend) => {
                BACKEND.with(|state| *state.borrow_mut() = Some(backend));
                LAST_ERROR.with(|err| err.borrow_mut().take());
                TaskStatus::Success
            }
            Err(err) => {
                LAST_ERROR.with(|last| *last.borrow_mut() = Some(err));
                TaskStatus::Error
            }
        };
        set_task_status(id, outcome);
    });

    id
}

pub fn poll_persistence(handle: u32) -> PollStatus {
    if handle == 0 {
        return if BACKEND.with(|backend| backend.borrow().is_some()) {
            PollStatus::Ready
        } else {
            PollStatus::Pending
        };
    }

    TASKS.with(|tasks| {
        let mut tasks = tasks.borrow_mut();
        if let Some(pos) = tasks.iter().position(|entry| entry.id == handle) {
            match tasks[pos].status {
                TaskStatus::Pending => PollStatus::Pending,
                TaskStatus::Success => {
                    tasks.remove(pos);
                    PollStatus::Ready
                }
                TaskStatus::Error => {
                    tasks.remove(pos);
                    PollStatus::Error
                }
            }
        } else {
            PollStatus::Unknown
        }
    })
}

pub fn backend_kind() -> BackendKind {
    BACKEND.with(|backend| match backend.borrow().as_ref() {
        Some(PersistenceBackend::Opfs(_)) => BackendKind::Opfs,
        Some(PersistenceBackend::IndexedDb(_)) => BackendKind::IndexedDb,
        None => BackendKind::None,
    })
}

pub fn last_error() -> Option<String> {
    LAST_ERROR.with(|err| err.borrow().clone())
}

pub(crate) fn delete_database(name: &str, dir: &str) -> Result<()> {
    if dir == SQLITE_MEMORY_DIR {
        return Ok(());
    }

    let file_name = make_db_path(name, dir);
    BACKEND.with(|backend| {
        let backend = backend.borrow();
        match backend.as_ref() {
            Some(PersistenceBackend::Opfs(util)) => util
                .delete_db(&file_name)
                .map(|_| ())
                .map_err(|err| map_error(err.to_string())),
            Some(PersistenceBackend::IndexedDb(util)) => match util.delete_db(&file_name) {
                Ok(wait) => {
                    spawn_local(async move {
                        if let Err(err) = wait.await {
                            LAST_ERROR.with(|last| *last.borrow_mut() = Some(err.to_string()));
                        }
                    });
                    Ok(())
                }
                Err(err) => Err(map_error(err.to_string())),
            },
            None => Err(IsarError::UnsupportedOperation {}),
        }
    })
}

pub(crate) fn make_db_path(name: &str, dir: &str) -> String {
    if dir.is_empty() || dir == SQLITE_MEMORY_DIR {
        format!("{name}.sqlite")
    } else {
        format!("{}/{}.sqlite", dir.trim_end_matches('/'), name)
    }
}

fn set_task_status(id: u32, status: TaskStatus) {
    TASKS.with(|tasks| {
        if let Some(entry) = tasks.borrow_mut().iter_mut().find(|entry| entry.id == id) {
            entry.status = status;
        }
    });
}

async fn initialize_backend(dir: String) -> std::result::Result<PersistenceBackend, String> {
    let sanitized_dir = sanitize_dir(&dir);

    match install_opfs(&sanitized_dir).await {
        Ok(util) => Ok(PersistenceBackend::Opfs(util)),
        Err(opfs_err) => match install_relaxed_idb(&sanitized_dir).await {
            Ok(util) => Ok(PersistenceBackend::IndexedDb(util)),
            Err(idb_err) => Err(format!(
                "Failed to initialize OPFS backend: {opfs_err}\nIndexedDB fallback failed: {idb_err}"
            )),
        },
    }
}

async fn install_opfs(dir: &str) -> std::result::Result<OpfsSAHPoolUtil, String> {
    let mut cfg = OpfsSAHPoolCfg::default();
    cfg.vfs_name = "isar-opfs".into();
    cfg.directory = opfs_directory(dir);
    cfg.initial_capacity = cfg.initial_capacity.max(8);

    sahpool_vfs::install(&cfg, true)
        .await
        .map_err(|err| err.to_string())
}

async fn install_relaxed_idb(_dir: &str) -> std::result::Result<RelaxedIdbUtil, String> {
    let mut cfg = RelaxedIdbCfg::default();
    cfg.vfs_name = "isar-relaxed-idb".into();
    cfg.clear_on_init = false;
    cfg.preload = Preload::All;

    relaxed_idb_vfs::install(&cfg, true)
        .await
        .map_err(|err| err.to_string())
}

fn sanitize_dir(dir: &str) -> String {
    if dir.is_empty() || dir == SQLITE_MEMORY_DIR {
        "default".into()
    } else {
        dir.trim_matches(|c| c == '/' || c == '\\')
            .replace(':', "_")
            .replace('\\', "/")
    }
}

fn opfs_directory(dir: &str) -> String {
    if dir.is_empty() {
        ".isar".into()
    } else {
        format!(".isar/{dir}")
    }
}

fn map_error(message: String) -> IsarError {
    IsarError::DbError { code: -1, message }
}
