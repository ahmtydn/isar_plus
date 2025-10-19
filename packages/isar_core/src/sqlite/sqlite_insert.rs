use super::sql::insert_sql;
use super::sqlite3::SQLiteStatement;
use super::sqlite_collection::SQLiteCollection;
use super::sqlite_txn::SQLiteTxn;
use crate::core::error::{IsarError, Result};
use crate::core::insert::IsarInsert;
use ouroboros::self_referencing;
use std::cell::Cell;

#[self_referencing]
struct TxnWithStatement {
    txn: SQLiteTxn,
    #[borrows(txn)]
    #[not_covariant]
    statement: Cell<SQLiteStatement<'this>>,
}

impl TxnWithStatement {
    fn open(
        txn: SQLiteTxn,
        collection: &SQLiteCollection,
        count: u32,
    ) -> Result<(u32, TxnWithStatement)> {
        let (batch_size, sql) = insert_sql(&collection.name, &collection.properties, count);
        let txn_stmt = Self::try_new(txn, |txn| {
            Ok(Cell::new(txn.get_sqlite(true)?.prepare(&sql)?))
        })?;
        Ok((batch_size, txn_stmt))
    }

    fn next(&mut self, collection: &SQLiteCollection, count: u32) -> Result<u32> {
        let (batch_size, sql) = insert_sql(&collection.name, &collection.properties, count);

        self.with_mut(|s| {
            s.txn.guard(|| s.statement.get_mut().step())?;
            s.statement.replace(s.txn.get_sqlite(true)?.prepare(&sql)?);
            Ok(())
        })?;

        Ok(batch_size)
    }

    fn finish(mut self) -> Result<SQLiteTxn> {
        self.with_mut(|s| s.txn.guard(|| s.statement.get_mut().step()))?;
        Ok(self.into_heads().txn)
    }
}

pub struct SQLiteInsert<'a> {
    pub(crate) collection: &'a SQLiteCollection,
    pub(crate) all_collections: &'a Vec<SQLiteCollection>,

    txn_stmt: TxnWithStatement,

    remaining: u32,
    pub(crate) batch_size: u32,
    pub(crate) batch_remaining: u32,

    // Track inserted IDs for detailed change detection
    inserted_ids: Vec<i64>,
}

impl<'a> SQLiteInsert<'a> {
    pub(crate) fn new(
        txn: SQLiteTxn,
        collection: &'a SQLiteCollection,
        all_collections: &'a Vec<SQLiteCollection>,
        count: u32,
    ) -> Result<Self> {
        let (batch_size, txn_stmt) = TxnWithStatement::open(txn, collection, count)?;
        let insert = Self {
            collection,
            all_collections,
            txn_stmt,
            remaining: count - batch_size,
            batch_size,
            batch_remaining: batch_size,
            inserted_ids: Vec::new(),
        };
        Ok(insert)
    }

    #[inline]
    pub(crate) fn with_stmt<T>(&mut self, callback: impl FnOnce(&mut SQLiteStatement) -> T) -> T {
        self.txn_stmt
            .with_statement_mut(|stmt| callback(stmt.get_mut()))
    }
}

impl<'a> IsarInsert<'a> for SQLiteInsert<'a> {
    type Txn = SQLiteTxn;

    fn save(&mut self, id: i64) -> Result<()> {
        if self.batch_remaining > 0 {
            self.collection.update_auto_increment(id);

            let id_property = (self.batch_size - self.batch_remaining)
                * (self.collection.properties.len() as u32 + 1);
            self.with_stmt(|stmt| stmt.bind_long(id_property, id))?;

            self.batch_remaining -= 1;

            // Store ID for detailed change detection
            if self.collection.watchers.has_detailed_watchers() {
                self.inserted_ids.push(id);
            }

            if self.batch_remaining == 0 && self.remaining > 0 {
                let batch_size = self.txn_stmt.next(self.collection, self.remaining)?;
                self.remaining -= batch_size;
                self.batch_size = batch_size;
                self.batch_remaining = batch_size;
            }

            Ok(())
        } else {
            Err(IsarError::UnsupportedOperation {})
        }
    }

    fn finish(self) -> Result<Self::Txn> {
        let txn = self.txn_stmt.finish()?;

        // Generate detailed changes for inserted objects
        if self.collection.watchers.has_detailed_watchers() && !self.inserted_ids.is_empty() {
            use super::sqlite_collection::SQLiteProperty;
            use super::sqlite_reader::SQLiteReader;
            use crate::core::change_detector::ChangeDetector;

            for object_id in self.inserted_ids {
                // Read the inserted object
                let select_sql = format!(
                    "SELECT * FROM {} WHERE {} = ?",
                    self.collection.name,
                    SQLiteProperty::ID_NAME
                );

                if let Ok(sqlite) = txn.get_sqlite(false) {
                    if let Ok(mut stmt) = sqlite.prepare(&select_sql) {
                        if stmt.bind_long(0, object_id).is_ok() && stmt.step().unwrap_or(false) {
                            let reader = SQLiteReader::new(
                                std::borrow::Cow::Borrowed(&stmt),
                                self.collection,
                                self.all_collections,
                            );
                            let after_json = reader.to_json();

                            // Generate insert change detail (no before state, only after)
                            if let Some(change_detail) = ChangeDetector::detect_changes_from_json(
                                &self.collection.name,
                                object_id,
                                None, // No before state for insert
                                Some(&after_json),
                            ) {
                                if let Ok(mut change_set) = txn.change_set.try_borrow_mut() {
                                    change_set.register_detailed_change(change_detail);
                                }
                            }
                        }
                    }
                }
            }
        }

        Ok(txn)
    }
}
