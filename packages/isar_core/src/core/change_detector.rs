use crate::core::data_type::DataType;
use crate::core::reader::IsarReader;
use crate::core::watcher::{ChangeDetail, ChangeType, FieldChange};
use std::collections::HashMap;

pub struct ChangeDetector;

impl ChangeDetector {
    /// Compare two objects and generate field changes
    pub fn detect_changes<R1: IsarReader, R2: IsarReader>(
        collection_name: &str,
        object_id: i64,
        old_object: Option<&R1>,
        new_object: Option<&R2>,
    ) -> Option<ChangeDetail> {
        match (old_object, new_object) {
            (None, Some(new_obj)) => {
                // Insert operation
                let mut field_changes = Vec::new();
                let mut full_document_fields = HashMap::new();
                
                for (index, (field_name, data_type)) in new_obj.properties().enumerate() {
                    let new_value = Self::read_field_value(new_obj, index + 1, data_type);
                    if let Some(value) = &new_value {
                        field_changes.push(FieldChange {
                            field_name: field_name.to_string(),
                            old_value: None,
                            new_value: Some(value.clone()),
                        });
                        full_document_fields.insert(field_name.to_string(), value.clone());
                    }
                }
                
                let full_document = if !full_document_fields.is_empty() {
                    serde_json::to_string(&full_document_fields).ok()
                } else {
                    None
                };

                Some(ChangeDetail {
                    change_type: ChangeType::Insert,
                    collection_name: collection_name.to_string(),
                    object_id,
                    field_changes,
                    full_document,
                })
            }
            (Some(old_obj), None) => {
                // Delete operation
                let mut field_changes = Vec::new();
                
                for (index, (field_name, data_type)) in old_obj.properties().enumerate() {
                    let old_value = Self::read_field_value(old_obj, index + 1, data_type);
                    if let Some(value) = old_value {
                        field_changes.push(FieldChange {
                            field_name: field_name.to_string(),
                            old_value: Some(value),
                            new_value: None,
                        });
                    }
                }

                Some(ChangeDetail {
                    change_type: ChangeType::Delete,
                    collection_name: collection_name.to_string(),
                    object_id,
                    field_changes,
                    full_document: None,
                })
            }
            (Some(old_obj), Some(new_obj)) => {
                // Update operation
                let mut field_changes = Vec::new();
                let mut full_document_fields = HashMap::new();
                let mut has_changes = false;
                
                // Use new_obj properties as the reference since it represents the current state
                for (index, (field_name, data_type)) in new_obj.properties().enumerate() {
                    let old_value = Self::read_field_value(old_obj, index + 1, data_type);
                    let new_value = Self::read_field_value(new_obj, index + 1, data_type);
                    
                    if old_value != new_value {
                        field_changes.push(FieldChange {
                            field_name: field_name.to_string(),
                            old_value,
                            new_value: new_value.clone(),
                        });
                        has_changes = true;
                    }
                    
                    // Include current field value in full document
                    if let Some(value) = &new_value {
                        full_document_fields.insert(field_name.to_string(), value.clone());
                    }
                }
                
                if has_changes {
                    let full_document = if !full_document_fields.is_empty() {
                        serde_json::to_string(&full_document_fields).ok()
                    } else {
                        None
                    };

                    Some(ChangeDetail {
                        change_type: ChangeType::Update,
                        collection_name: collection_name.to_string(),
                        object_id,
                        field_changes,
                        full_document,
                    })
                } else {
                    None
                }
            }
            (None, None) => None,
        }
    }

    /// Read a field value from an IsarReader and convert it to a string representation
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
                if val != i32::MIN {
                    Some(val.to_string())
                } else {
                    None
                }
            }
            DataType::Float => {
                let val = reader.read_float(index);
                if val.is_finite() {
                    Some(val.to_string())
                } else {
                    None
                }
            }
            DataType::Long => {
                let val = reader.read_long(index);
                if val != i64::MIN {
                    Some(val.to_string())
                } else {
                    None
                }
            }
            DataType::Double => {
                let val = reader.read_double(index);
                if val.is_finite() {
                    Some(val.to_string())
                } else {
                    None
                }
            }
            DataType::String | DataType::Json => {
                reader.read_string(index).map(|s| s.to_string())
            }
            DataType::Object => {
                if let Some(obj_reader) = reader.read_object(index) {
                    // Serialize the embedded object to JSON
                    let mut buffer = Vec::new();
                    let mut serializer = serde_json::Serializer::new(&mut buffer);
                    if let Ok(()) = obj_reader.serialize(&mut serializer) {
                        String::from_utf8(buffer).ok()
                    } else {
                        Some("[object]".to_string())
                    }
                } else {
                    None
                }
            }
            // Handle list types
            DataType::BoolList | DataType::ByteList | DataType::IntList | 
            DataType::FloatList | DataType::LongList | DataType::DoubleList | 
            DataType::StringList | DataType::ObjectList => {
                if let Some((_list_reader, length)) = reader.read_list(index) {
                    // For now, just indicate it's a list with length
                    Some(format!("[list:{}]", length))
                } else {
                    None
                }
            }
        }
    }
    
    /// Compare two JSON objects and generate field changes
    pub fn detect_changes_from_json(
        collection_name: &str,
        object_id: i64,
        old_json: Option<&serde_json::Value>,
        new_json: Option<&serde_json::Value>,
    ) -> Option<ChangeDetail> {
        match (old_json, new_json) {
            (None, Some(new_obj)) => {
                // Insert operation
                let mut field_changes = Vec::new();
                if let serde_json::Value::Object(new_map) = new_obj {
                    for (field_name, new_value) in new_map {
                        field_changes.push(FieldChange {
                            field_name: field_name.clone(),
                            old_value: None,
                            new_value: Some(new_value.to_string()),
                        });
                    }
                }

                Some(ChangeDetail {
                    change_type: ChangeType::Insert,
                    collection_name: collection_name.to_string(),
                    object_id,
                    field_changes,
                    full_document: Some(new_obj.to_string()),
                })
            }
            (Some(old_obj), None) => {
                // Delete operation
                let mut field_changes = Vec::new();
                if let serde_json::Value::Object(old_map) = old_obj {
                    for (field_name, old_value) in old_map {
                        field_changes.push(FieldChange {
                            field_name: field_name.clone(),
                            old_value: Some(old_value.to_string()),
                            new_value: None,
                        });
                    }
                }

                Some(ChangeDetail {
                    change_type: ChangeType::Delete,
                    collection_name: collection_name.to_string(),
                    object_id,
                    field_changes,
                    full_document: Some(old_obj.to_string()),
                })
            }
            (Some(old_obj), Some(new_obj)) => {
                // Update operation
                let mut field_changes = Vec::new();
                let mut has_changes = false;

                // Compare fields from both objects
                let mut all_fields = std::collections::HashSet::new();
                
                if let serde_json::Value::Object(old_map) = old_obj {
                    for field_name in old_map.keys() {
                        all_fields.insert(field_name.clone());
                    }
                }
                
                if let serde_json::Value::Object(new_map) = new_obj {
                    for field_name in new_map.keys() {
                        all_fields.insert(field_name.clone());
                    }
                }

                for field_name in all_fields {
                    let old_value = old_obj.get(&field_name);
                    let new_value = new_obj.get(&field_name);
                    
                    if old_value != new_value {
                        has_changes = true;
                        field_changes.push(FieldChange {
                            field_name: field_name.clone(),
                            old_value: old_value.map(|v| v.to_string()),
                            new_value: new_value.map(|v| v.to_string()),
                        });
                    }
                }

                if has_changes {
                    Some(ChangeDetail {
                        change_type: ChangeType::Update,
                        collection_name: collection_name.to_string(),
                        object_id,
                        field_changes,
                        full_document: Some(new_obj.to_string()),
                    })
                } else {
                    None
                }
            }
            _ => None,
        }
    }
}