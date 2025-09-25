use crate::core::data_type::DataType;
use crate::core::reader::IsarReader;
use crate::core::watcher::{ChangeDetail, ChangeType, FieldChange};
use serde_json::Value as JsonValue;
use std::collections::HashSet;

/// Detects and tracks changes between object states for database change streams.
pub struct ChangeDetector;

impl ChangeDetector {
    /// Detects changes between two objects using IsarReader implementations.
    /// 
    /// Returns `Some(ChangeDetail)` if changes are detected, `None` otherwise.
    pub fn detect_changes<R1: IsarReader, R2: IsarReader>(
        collection_name: &str,
        object_id: i64,
        old_object: Option<&R1>,
        new_object: Option<&R2>,
    ) -> Option<ChangeDetail> {
        match (old_object, new_object) {
            (None, Some(new_obj)) => Self::create_insert_change(collection_name, object_id, new_obj),
            (Some(old_obj), None) => Self::create_delete_change(collection_name, object_id, old_obj),
            (Some(old_obj), Some(new_obj)) => Self::create_update_change(collection_name, object_id, old_obj, new_obj),
            (None, None) => None,
        }
    }

    /// Detects changes between two JSON objects.
    /// 
    /// Returns `Some(ChangeDetail)` if changes are detected, `None` otherwise.
    pub fn detect_changes_from_json(
        collection_name: &str,
        object_id: i64,
        old_json: Option<&JsonValue>,
        new_json: Option<&JsonValue>,
    ) -> Option<ChangeDetail> {
        match (old_json, new_json) {
            (None, Some(new_obj)) => Self::create_json_insert_change(collection_name, object_id, new_obj),
            (Some(old_obj), None) => Self::create_json_delete_change(collection_name, object_id, old_obj),
            (Some(old_obj), Some(new_obj)) => Self::create_json_update_change(collection_name, object_id, old_obj, new_obj),
            (None, None) => None,
        }
    }

    // Private helper methods for IsarReader-based changes
    
    /// Extracts the key field from an object (typically at index 2 for Frame objects)
    fn extract_key_from_object<R: IsarReader>(object: &R) -> String {
        // For Frame objects, the key field is at index 2 (after id and typeId)
        // Try to read the key field, fallback to empty string if not found
        object.read_string(2).unwrap_or("").to_string()
    }
    
    fn create_insert_change<R: IsarReader>(
        collection_name: &str,
        object_id: i64,
        new_object: &R,
    ) -> Option<ChangeDetail> {
        let field_changes = Self::extract_all_fields::<R, R>(new_object, None);
        let key = Self::extract_key_from_object(new_object);
        
        // Directly serialize the new_object instead of reconstructing from fields
        let full_document = Self::serialize_isar_object(new_object);

        Some(ChangeDetail {
            change_type: ChangeType::Insert,
            collection_name: collection_name.to_string(),
            object_id,
            key,
            field_changes,
            full_document,
        })
    }

    fn create_delete_change<R: IsarReader>(
        collection_name: &str,
        object_id: i64,
        old_object: &R,
    ) -> Option<ChangeDetail> {
        let field_changes = Self::extract_field_changes_for_delete(old_object);
        let key = Self::extract_key_from_object(old_object);
        
        // Directly serialize the old_object instead of reconstructing from fields
        let full_document = Self::serialize_isar_object(old_object);

        Some(ChangeDetail {
            change_type: ChangeType::Delete,
            collection_name: collection_name.to_string(),
            object_id,
            key,
            field_changes,
            full_document,
        })
    }

    fn create_update_change<R1: IsarReader, R2: IsarReader>(
        collection_name: &str,
        object_id: i64,
        old_object: &R1,
        new_object: &R2,
    ) -> Option<ChangeDetail> {
        let field_changes = Self::extract_all_fields(new_object, Some(old_object));
        
        if field_changes.is_empty() {
            return None;
        }

        let key = Self::extract_key_from_object(new_object);
        
        // Directly serialize the new_object instead of reconstructing from fields
        let full_document = Self::serialize_isar_object(new_object);

        Some(ChangeDetail {
            change_type: ChangeType::Update,
            collection_name: collection_name.to_string(),
            object_id,
            key,
            field_changes,
            full_document,
        })
    }

    fn extract_all_fields<R1: IsarReader, R2: IsarReader>(
        new_object: &R1,
        old_object: Option<&R2>,
    ) -> Vec<FieldChange> {
        let mut field_changes = Vec::new();

        for (index, (field_name, data_type)) in new_object.properties().enumerate() {
            let field_index = index + 1;
            let new_value = Self::read_field_value(new_object, field_index, data_type);
            
            let old_value = old_object
                .and_then(|old_obj| Self::read_field_value(old_obj, field_index, data_type));

            let processed_new_value = Self::process_field_value(field_name, new_value);
            let processed_old_value = Self::process_field_value(field_name, old_value);

            // For updates, only include changes; for inserts, include all non-null fields
            let should_include_change = match old_object {
                Some(_) => processed_old_value != processed_new_value,
                None => processed_new_value.is_some(),
            };

            if should_include_change {
                field_changes.push(FieldChange {
                    field_name: field_name.to_string(),
                    old_value: processed_old_value.clone(),
                    new_value: processed_new_value.clone(),
                });
            }
        }

        field_changes
    }

    fn extract_field_changes_for_delete<R: IsarReader>(old_object: &R) -> Vec<FieldChange> {
        let mut field_changes = Vec::new();

        for (index, (field_name, data_type)) in old_object.properties().enumerate() {
            let old_value = Self::read_field_value(old_object, index + 1, data_type);
            let processed_old_value = Self::process_field_value(field_name, old_value);

            if let Some(value) = processed_old_value {
                field_changes.push(FieldChange {
                    field_name: field_name.to_string(),
                    old_value: Some(value),
                    new_value: None,
                });
            }
        }

        field_changes
    }

    /// Processes field values with special handling for the "value" field containing JSON.
    fn process_field_value(field_name: &str, value: Option<String>) -> Option<String> {
        let Some(val) = value else { return None };
        
        if field_name == "value" {
            Self::extract_inner_json_value(&val)
        } else {
            Some(val)
        }
    }

    /// Extracts the inner "value" from a JSON string, falling back to the original if parsing fails.
    fn extract_inner_json_value(json_str: &str) -> Option<String> {
        match serde_json::from_str::<JsonValue>(json_str) {
            Ok(parsed) => {
                if let Some(inner_value) = parsed.get("value") {
                    // Convert JsonValue to string without adding extra quotes for objects/arrays
                    match inner_value {
                        JsonValue::String(s) => Some(s.clone()),
                        _ => Some(serde_json::to_string(inner_value).unwrap_or_else(|_| inner_value.to_string()))
                    }
                } else {
                    Some(json_str.to_string())
                }
            }
            Err(_) => Some(json_str.to_string()),
        }
    }

    /// Directly serializes an IsarReader object to JSON string
    fn serialize_isar_object<R: IsarReader>(reader: &R) -> String {
        let mut buffer = Vec::new();
        let mut serializer = serde_json::Serializer::new(&mut buffer);
        
        match reader.serialize(&mut serializer) {
            Ok(()) => {
                String::from_utf8(buffer)
                    .unwrap_or_else(|_| panic!("Failed to convert serialized data to UTF-8 string"))
            }
            Err(_) => {
                panic!("Failed to serialize IsarReader object")
            }
        }
    }

    /// Reads a field value from an IsarReader and converts it to a string representation.
    fn read_field_value<R: IsarReader>(reader: &R, index: usize, data_type: DataType) -> Option<String> {
        let index = index as u32;
        
        if reader.is_null(index) {
            return None;
        }

        match data_type {
            DataType::Bool => reader.read_bool(index).map(|v| v.to_string()),
            DataType::Byte => Some(reader.read_byte(index).to_string()),
            DataType::Int => {
                let val = reader.read_int(index);
                (val != i32::MIN).then(|| val.to_string())
            }
            DataType::Float => {
                let val = reader.read_float(index);
                val.is_finite().then(|| val.to_string())
            }
            DataType::Long => {
                let val = reader.read_long(index);
                (val != i64::MIN).then(|| val.to_string())
            }
            DataType::Double => {
                let val = reader.read_double(index);
                val.is_finite().then(|| val.to_string())
            }
            DataType::String | DataType::Json => {
                reader.read_string(index).map(|s| s.to_string())
            }
            DataType::Object => Self::read_object_field(reader, index),
            DataType::BoolList | DataType::ByteList | DataType::IntList | 
            DataType::FloatList | DataType::LongList | DataType::DoubleList | 
            DataType::StringList | DataType::ObjectList => Self::read_list_field(reader, index),
        }
    }

    fn read_object_field<R: IsarReader>(reader: &R, index: u32) -> Option<String> {
        reader.read_object(index).and_then(|obj_reader| {
            let mut buffer = Vec::new();
            let mut serializer = serde_json::Serializer::new(&mut buffer);
            
            match obj_reader.serialize(&mut serializer) {
                Ok(()) => String::from_utf8(buffer).ok(),
                Err(_) => Some("[object]".to_string()),
            }
        })
    }

    fn read_list_field<R: IsarReader>(reader: &R, index: u32) -> Option<String> {
        reader.read_list(index)
            .map(|(_, length)| format!("[list:{}]", length))
    }

    // Private helper methods for JSON-based changes

    /// Extracts the key field from a JSON object
    fn extract_key_from_json(object: &JsonValue) -> String {
        object.get("key")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string()
    }

    fn create_json_insert_change(
        collection_name: &str,
        object_id: i64,
        new_object: &JsonValue,
    ) -> Option<ChangeDetail> {
        let field_changes = Self::extract_json_fields_for_insert(new_object);
        let key = Self::extract_key_from_json(new_object);

        // Create a clean full_document with unpacked JSON values  
        let full_document = Self::create_clean_full_document(new_object);

        Some(ChangeDetail {
            change_type: ChangeType::Insert,
            collection_name: collection_name.to_string(),
            object_id,
            key,
            field_changes,
            full_document,
        })
    }

    fn create_json_delete_change(
        collection_name: &str,
        object_id: i64,
        old_object: &JsonValue,
    ) -> Option<ChangeDetail> {
        let field_changes = Self::extract_json_fields_for_delete(old_object);
        let key = Self::extract_key_from_json(old_object);
        
        // Create full_document from the deleted object
        let full_document = Self::create_clean_full_document(old_object);

        Some(ChangeDetail {
            change_type: ChangeType::Delete,
            collection_name: collection_name.to_string(),
            object_id,
            key,
            field_changes,
            full_document,
        })
    }

    fn create_json_update_change(
        collection_name: &str,
        object_id: i64,
        old_object: &JsonValue,
        new_object: &JsonValue,
    ) -> Option<ChangeDetail> {
        let field_changes = Self::extract_json_field_changes(old_object, new_object);
        
        if field_changes.is_empty() {
            return None;
        }

        let key = Self::extract_key_from_json(new_object);
        // Create a clean full_document with unpacked JSON values
        let full_document = Self::create_clean_full_document(new_object);

        Some(ChangeDetail {
            change_type: ChangeType::Update,
            collection_name: collection_name.to_string(),
            object_id,
            key,
            field_changes,
            full_document,
        })
    }

    fn extract_json_fields_for_insert(new_object: &JsonValue) -> Vec<FieldChange> {
        let JsonValue::Object(new_map) = new_object else {
            return Vec::new();
        };

        new_map.iter().map(|(field_name, new_value)| {
            let processed_value = Self::process_json_field_value(field_name, new_value);
            FieldChange {
                field_name: field_name.clone(),
                old_value: None,
                new_value: Some(processed_value),
            }
        }).collect()
    }

    fn extract_json_fields_for_delete(old_object: &JsonValue) -> Vec<FieldChange> {
        let JsonValue::Object(old_map) = old_object else {
            return Vec::new();
        };

        old_map.iter().map(|(field_name, old_value)| {
            let processed_value = Self::process_json_field_value(field_name, old_value);
            FieldChange {
                field_name: field_name.clone(),
                old_value: Some(processed_value),
                new_value: None,
            }
        }).collect()
    }

    fn extract_json_field_changes(old_object: &JsonValue, new_object: &JsonValue) -> Vec<FieldChange> {
        let all_fields = Self::collect_all_json_field_names(old_object, new_object);
        let mut field_changes = Vec::new();

        for field_name in all_fields {
            let old_value = old_object.get(&field_name);
            let new_value = new_object.get(&field_name);
            
            let processed_old_value = old_value.map(|v| Self::process_json_field_value(&field_name, v));
            let processed_new_value = new_value.map(|v| Self::process_json_field_value(&field_name, v));
            
            if processed_old_value != processed_new_value {
                field_changes.push(FieldChange {
                    field_name: field_name.clone(),
                    old_value: processed_old_value,
                    new_value: processed_new_value,
                });
            }
        }

        field_changes
    }

    fn collect_all_json_field_names(old_object: &JsonValue, new_object: &JsonValue) -> HashSet<String> {
        let mut all_fields = HashSet::new();
        
        if let JsonValue::Object(old_map) = old_object {
            all_fields.extend(old_map.keys().cloned());
        }
        
        if let JsonValue::Object(new_map) = new_object {
            all_fields.extend(new_map.keys().cloned());
        }

        all_fields
    }

    /// Creates a clean full document JSON string with unpacked nested JSON values
    fn create_clean_full_document(object: &JsonValue) -> String {
        match object {
            JsonValue::Object(map) => {
                if map.is_empty() {
                    panic!("Cannot create full document from empty JSON object");
                }
                
                let mut clean_map = serde_json::Map::new();
                
                for (key, value) in map {
                    let clean_value = if key == "value" {
                        // Try to unpack JSON strings in the "value" field
                        match value {
                            JsonValue::String(s) => {
                                serde_json::from_str::<JsonValue>(s)
                                    .unwrap_or_else(|_| value.clone())
                            }
                            _ => value.clone()
                        }
                    } else {
                        value.clone()
                    };
                    
                    clean_map.insert(key.clone(), clean_value);
                }
                
                serde_json::to_string(&JsonValue::Object(clean_map))
                    .unwrap_or_else(|_| panic!("Failed to serialize clean full document"))
            }
            JsonValue::Null => panic!("Cannot create full document from null JSON value"),
            _ => serde_json::to_string(object)
                .unwrap_or_else(|_| panic!("Failed to serialize JSON value to full document"))
        }
    }

    /// Processes JSON field values with special handling for the "value" field.
    fn process_json_field_value(field_name: &str, value: &JsonValue) -> String {
        if field_name == "value" {
            if let JsonValue::String(value_str) = value {
                return Self::extract_inner_json_value(value_str)
                    .unwrap_or_else(|| value.to_string());
            }
        }

        match value {
            JsonValue::String(s) => s.clone(),
            _ => value.to_string(),
        }
    }
}