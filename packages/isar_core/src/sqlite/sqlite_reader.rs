use super::sqlite3::SQLiteStatement;
use super::sqlite_collection::SQLiteCollection;
use crate::core::{data_type::DataType, reader::IsarReader};
use base64::{engine::general_purpose, Engine as _};
use serde_json::{Map, Value};
use std::borrow::Cow;
use std::iter::empty;

pub struct SQLiteReader<'a> {
    stmt: Cow<'a, SQLiteStatement<'a>>,
    collection: &'a SQLiteCollection,
    all_collections: &'a [SQLiteCollection],
}

impl<'a> SQLiteReader<'a> {
    pub(crate) fn new(
        stmt: Cow<'a, SQLiteStatement<'a>>,
        collection: &'a SQLiteCollection,
        all_collections: &'a [SQLiteCollection],
    ) -> Self {
        Self {
            stmt,
            collection,
            all_collections,
        }
    }
}

impl<'a> IsarReader for SQLiteReader<'a> {
    type ObjectReader<'b> = SQLiteObjectReader<'b> where 'a: 'b;

    type ListReader<'b> = SQLiteListReader<'b> where 'a: 'b;

    fn id_name(&self) -> Option<&str> {
        self.collection.id_name.as_deref()
    }

    fn properties(&self) -> impl Iterator<Item = (&str, DataType)> {
        self.collection
            .properties
            .iter()
            .map(|p| (p.name.as_str(), p.data_type))
    }

    fn read_id(&self) -> i64 {
        self.stmt.get_long(0)
    }

    fn is_null(&self, index: u32) -> bool {
        self.stmt.is_null(index)
    }

    fn read_bool(&self, index: u32) -> Option<bool> {
        if self.is_null(index) {
            None
        } else {
            Some(self.stmt.get_int(index) != 0)
        }
    }

    fn read_byte(&self, index: u32) -> u8 {
        self.stmt.get_int(index) as u8
    }

    fn read_int(&self, index: u32) -> i32 {
        let val = self.stmt.get_int(index);
        if val == 0 && self.is_null(index) {
            i32::MIN
        } else {
            val
        }
    }

    fn read_float(&self, index: u32) -> f32 {
        self.read_double(index) as f32
    }

    fn read_long(&self, index: u32) -> i64 {
        let val = self.stmt.get_long(index);
        if val == 0 && self.is_null(index) {
            i64::MIN
        } else {
            val
        }
    }

    fn read_double(&self, index: u32) -> f64 {
        let val = self.stmt.get_double(index);
        if val == 0.0 && self.is_null(index) {
            f64::NAN
        } else {
            val
        }
    }

    fn read_string(&self, index: u32) -> Option<&str> {
        if self.is_null(index) {
            None
        } else {
            Some(self.stmt.get_text(index))
        }
    }

    fn read_blob(&self, index: u32) -> Option<Cow<'_, [u8]>> {
        if self.is_null(index) {
            None
        } else {
            let bytes = self.stmt.get_blob(index);
            Some(Cow::Borrowed(bytes))
        }
    }

    fn read_object(&self, index: u32) -> Option<Self::ObjectReader<'a>> {
        if let Some(property) = self.collection.get_property(index as u16) {
            if let Some(collection_index) = property.collection_index {
                let text = self.stmt.get_text(index);
                if let Ok(Value::Object(object)) = serde_json::from_str(text) {
                    let collection = &self.all_collections[collection_index as usize];
                    return Some(SQLiteObjectReader {
                        object: Cow::Owned(object),
                        collection,
                        all_collections: self.all_collections,
                    });
                }
            }
        }

        None
    }

    fn read_list(&self, index: u32) -> Option<(Self::ListReader<'a>, u32)> {
        if let Some(property) = self.collection.get_property(index as u16) {
            let text = self.stmt.get_text(index);
            if let Ok(Value::Array(list)) = serde_json::from_str(text) {
                let list_length = list.len();
                let list_reader = SQLiteListReader {
                    list: Cow::Owned(list),
                    collection_index: property.collection_index,
                    all_collections: self.all_collections,
                };
                return Some((list_reader, list_length as u32));
            }
        }
        None
    }
}

pub struct SQLiteObjectReader<'a> {
    object: Cow<'a, Map<String, Value>>,
    collection: &'a SQLiteCollection,
    all_collections: &'a [SQLiteCollection],
}

impl<'a> IsarReader for SQLiteObjectReader<'a> {
    type ObjectReader<'b> = SQLiteObjectReader<'b> where 'a: 'b;

    type ListReader<'b> = SQLiteListReader<'b> where 'a: 'b;

    fn id_name(&self) -> Option<&str> {
        None
    }

    fn properties(&self) -> impl Iterator<Item = (&str, DataType)> {
        self.collection
            .properties
            .iter()
            .map(|p| (p.name.as_str(), p.data_type))
    }

    fn read_id(&self) -> i64 {
        i64::MIN
    }

    fn is_null(&self, index: u32) -> bool {
        if let Some(property) = self.collection.get_property(index as u16) {
            if let Some(value) = self.object.get(&property.name) {
                return value.is_null();
            }
        }
        true
    }

    fn read_bool(&self, index: u32) -> Option<bool> {
        if let Some(property) = self.collection.get_property(index as u16) {
            if let Some(Value::Bool(val)) = self.object.get(&property.name) {
                return Some(*val);
            }
        }
        None
    }

    fn read_byte(&self, index: u32) -> u8 {
        if let Some(property) = self.collection.get_property(index as u16) {
            if let Some(Value::Number(num)) = self.object.get(&property.name) {
                if let Some(val) = num.as_u64() {
                    return val as u8;
                }
            }
        }
        0
    }

    fn read_int(&self, index: u32) -> i32 {
        self.read_long(index) as i32
    }

    fn read_float(&self, index: u32) -> f32 {
        self.read_double(index) as f32
    }

    fn read_long(&self, index: u32) -> i64 {
        if let Some(property) = self.collection.get_property(index as u16) {
            if let Some(Value::Number(num)) = self.object.get(&property.name) {
                if let Some(val) = num.as_i64() {
                    return val;
                }
            }
        }
        i64::MIN
    }

    fn read_double(&self, index: u32) -> f64 {
        if let Some(property) = self.collection.get_property(index as u16) {
            if let Some(Value::Number(num)) = self.object.get(&property.name) {
                if let Some(val) = num.as_f64() {
                    return val;
                }
            }
        }
        f64::NAN
    }

    fn read_string(&self, index: u32) -> Option<&str> {
        if let Some(property) = self.collection.get_property(index as u16) {
            if let Some(Value::String(val)) = self.object.get(&property.name) {
                return Some(val);
            }
        }
        None
    }

    fn read_blob(&self, index: u32) -> Option<Cow<'a, [u8]>> {
        if let Some(property) = self.collection.get_property(index as u16) {
            if let Some(Value::String(val)) = self.object.get(&property.name) {
                if let Ok(bytes) = general_purpose::STANDARD_NO_PAD.decode(val) {
                    return Some(Cow::Owned(bytes));
                }
            }
        }
        None
    }

    fn read_object(&self, index: u32) -> Option<Self::ObjectReader<'_>> {
        if let Some(property) = self.collection.get_property(index as u16) {
            if let Some(Value::Object(object)) = self.object.get(&property.name) {
                let collection_index = property.collection_index.unwrap();
                let collection = &self.all_collections[collection_index as usize];
                return Some(SQLiteObjectReader {
                    object: Cow::Borrowed(object),
                    collection,
                    all_collections: self.all_collections,
                });
            }
        }
        None
    }

    fn read_list(&self, index: u32) -> Option<(Self::ListReader<'_>, u32)> {
        if let Some(property) = self.collection.get_property(index as u16) {
            if let Some(Value::Array(list)) = self.object.get(&property.name) {
                let list_length = list.len();
                let list_reader = SQLiteListReader {
                    list: Cow::Borrowed(list),
                    collection_index: property.collection_index,
                    all_collections: self.all_collections,
                };
                return Some((list_reader, list_length as u32));
            }
        }
        None
    }
}

pub struct SQLiteListReader<'a> {
    list: Cow<'a, Vec<Value>>,
    collection_index: Option<u16>,
    all_collections: &'a [SQLiteCollection],
}

impl<'a> IsarReader for SQLiteListReader<'a> {
    type ObjectReader<'b> = SQLiteObjectReader<'b> where 'a: 'b;

    type ListReader<'b> = SQLiteListReader<'b> where 'a: 'b;

    fn id_name(&self) -> Option<&str> {
        None
    }

    fn properties(&self) -> impl Iterator<Item = (&str, DataType)> {
        empty()
    }

    fn read_id(&self) -> i64 {
        i64::MIN
    }

    fn is_null(&self, index: u32) -> bool {
        if let Some(value) = self.list.get(index as usize) {
            return value.is_null();
        }
        true
    }

    fn read_bool(&self, index: u32) -> Option<bool> {
        if let Some(Value::Bool(val)) = self.list.get(index as usize) {
            return Some(*val);
        }
        None
    }

    fn read_byte(&self, index: u32) -> u8 {
        if let Some(Value::Number(num)) = self.list.get(index as usize) {
            if let Some(val) = num.as_u64() {
                return val as u8;
            }
        }
        0
    }

    fn read_int(&self, index: u32) -> i32 {
        self.read_long(index) as i32
    }

    fn read_float(&self, index: u32) -> f32 {
        self.read_double(index) as f32
    }

    fn read_long(&self, index: u32) -> i64 {
        if let Some(Value::Number(num)) = self.list.get(index as usize) {
            if let Some(val) = num.as_i64() {
                return val;
            }
        }
        i64::MIN
    }

    fn read_double(&self, index: u32) -> f64 {
        if let Some(Value::Number(num)) = self.list.get(index as usize) {
            if let Some(val) = num.as_f64() {
                return val;
            }
        }
        f64::NAN
    }

    fn read_string(&self, index: u32) -> Option<&str> {
        if let Some(Value::String(val)) = self.list.get(index as usize) {
            Some(val)
        } else {
            None
        }
    }

    fn read_blob(&self, _index: u32) -> Option<Cow<'a, [u8]>> {
        None
    }

    fn read_object(&self, index: u32) -> Option<Self::ObjectReader<'_>> {
        if let Some(Value::Object(object)) = self.list.get(index as usize) {
            if let Some(collection_index) = self.collection_index {
                let collection = &self.all_collections[collection_index as usize];
                return Some(SQLiteObjectReader {
                    object: Cow::Borrowed(object),
                    collection,
                    all_collections: self.all_collections,
                });
            }
        }
        None
    }

    fn read_list(&self, _: u32) -> Option<(Self::ListReader<'_>, u32)> {
        None
    }
}

impl<'a> SQLiteReader<'a> {
    /// Convert the current SQLite row to JSON
    pub(crate) fn to_json(&self) -> serde_json::Value {
        let mut result = serde_json::Map::new();
        
        // Add the ID
        result.insert("id".to_string(), serde_json::Value::Number(self.read_id().into()));
        
        // Add all properties
        for (index, (field_name, data_type)) in self.properties().enumerate() {
            let index = index as u32 + 1; // Skip ID column
            
            let value = match data_type {
                DataType::Bool => {
                    if let Some(v) = self.read_bool(index) {
                        serde_json::Value::Bool(v)
                    } else {
                        serde_json::Value::Null
                    }
                }
                DataType::Byte => serde_json::Value::Number((self.read_byte(index) as i64).into()),
                DataType::Int => serde_json::Value::Number(self.read_int(index).into()),
                DataType::Float => {
                    if let Some(n) = serde_json::Number::from_f64(self.read_float(index) as f64) {
                        serde_json::Value::Number(n)
                    } else {
                        serde_json::Value::Null
                    }
                }
                DataType::Long => serde_json::Value::Number(self.read_long(index).into()),
                DataType::Double => {
                    if let Some(n) = serde_json::Number::from_f64(self.read_double(index)) {
                        serde_json::Value::Number(n)
                    } else {
                        serde_json::Value::Null
                    }
                }
                DataType::String => {
                    if let Some(s) = self.read_string(index) {
                        serde_json::Value::String(s.to_string())
                    } else {
                        serde_json::Value::Null
                    }
                }
                // Handle binary data - Note: DataType doesn't have Bytes, using ByteList pattern
                DataType::ByteList => {
                    if let Some(bytes) = self.read_blob(index) {
                        let encoded = general_purpose::STANDARD_NO_PAD.encode(&bytes);
                        serde_json::Value::String(encoded)
                    } else {
                        serde_json::Value::Null
                    }
                }
                // For complex types, use the existing JSON representation
                DataType::Object | DataType::Json | DataType::BoolList | DataType::IntList | 
                DataType::FloatList | DataType::LongList | DataType::DoubleList | 
                DataType::StringList | DataType::ObjectList => {
                    if self.is_null(index) {
                        serde_json::Value::Null
                    } else {
                        // For SQLite, complex types are already stored as JSON strings
                        let json_str = self.stmt.get_text(index);
                        serde_json::from_str(json_str).unwrap_or(serde_json::Value::Null)
                    }
                }
            };
            
            result.insert(field_name.to_string(), value);
        }
        
        serde_json::Value::Object(result)
    }
}
