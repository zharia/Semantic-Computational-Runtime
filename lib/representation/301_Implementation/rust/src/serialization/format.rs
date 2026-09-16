use crate::error::RepresentationError;
use crate::serialization::schema::SchemaDescriptor;
use crate::serialization::value::SemanticValue;
use std::collections::BTreeMap;

pub const MAGIC_BYTES: &[u8; 4] = b"SCRS"; // Semantic Computational Runtime Serialization
pub const CANONICAL_FORMAT_VERSION: u32 = 1;

/// Canonical deterministic serializer.
pub struct CanonicalSerializer;

impl CanonicalSerializer {
    /// Serialize a SemanticValue along with its SchemaDescriptor into deterministic canonical bytes.
    pub fn serialize(
        schema: &SchemaDescriptor,
        value: &SemanticValue,
    ) -> Result<Vec<u8>, RepresentationError> {
        let mut buf = Vec::new();

        // 1. Magic header
        buf.extend_from_slice(MAGIC_BYTES);

        // 2. Format version (u32 LE)
        buf.extend_from_slice(&schema.format_version.0.to_le_bytes());

        // 3. Schema ID length + bytes
        let schema_id_bytes = schema.id.0.as_bytes();
        if schema_id_bytes.len() > u16::MAX as usize {
            return Err(RepresentationError::SerializationError(
                "Schema ID exceeds maximum allowed length of 65535 bytes".into(),
            ));
        }
        buf.extend_from_slice(&(schema_id_bytes.len() as u16).to_le_bytes());
        buf.extend_from_slice(schema_id_bytes);

        // 4. Schema version (u32 LE)
        buf.extend_from_slice(&schema.version.0.to_le_bytes());

        // 5. Value body
        Self::encode_value(value, &mut buf)?;

        Ok(buf)
    }

    fn encode_value(val: &SemanticValue, buf: &mut Vec<u8>) -> Result<(), RepresentationError> {
        match val {
            SemanticValue::Null => {
                buf.push(0x00);
            }
            SemanticValue::Bool(false) => {
                buf.push(0x01);
            }
            SemanticValue::Bool(true) => {
                buf.push(0x02);
            }
            SemanticValue::Int64(i) => {
                buf.push(0x03);
                buf.extend_from_slice(&i.to_le_bytes());
            }
            SemanticValue::Float64(f) => {
                buf.push(0x04);
                // Canonicalize floating-point representation: convert -0.0 to 0.0 and canonicalize NaN bits
                let canonical_f = if *f == 0.0 {
                    0.0
                } else if f.is_nan() {
                    f64::from_bits(0x7ff8000000000000)
                } else {
                    *f
                };
                buf.extend_from_slice(&canonical_f.to_bits().to_le_bytes());
            }
            SemanticValue::String(s) => {
                buf.push(0x05);
                let bytes = s.as_bytes();
                buf.extend_from_slice(&(bytes.len() as u32).to_le_bytes());
                buf.extend_from_slice(bytes);
            }
            SemanticValue::Bytes(b) => {
                buf.push(0x06);
                buf.extend_from_slice(&(b.len() as u32).to_le_bytes());
                buf.extend_from_slice(b);
            }
            SemanticValue::Array(items) => {
                buf.push(0x07);
                buf.extend_from_slice(&(items.len() as u32).to_le_bytes());
                for item in items {
                    Self::encode_value(item, buf)?;
                }
            }
            SemanticValue::Map(map) => {
                buf.push(0x08);
                buf.extend_from_slice(&(map.len() as u32).to_le_bytes());
                // Iterating BTreeMap is inherently in strictly sorted key order -> canonical determinism!
                for (k, v) in map {
                    let k_bytes = k.as_bytes();
                    buf.extend_from_slice(&(k_bytes.len() as u32).to_le_bytes());
                    buf.extend_from_slice(k_bytes);
                    Self::encode_value(v, buf)?;
                }
            }
            SemanticValue::EntityRef(id) => {
                buf.push(0x09);
                let bytes = id.as_bytes();
                buf.extend_from_slice(&(bytes.len() as u32).to_le_bytes());
                buf.extend_from_slice(bytes);
            }
        }
        Ok(())
    }
}

/// Canonical deterministic deserializer.
pub struct CanonicalDeserializer;

impl CanonicalDeserializer {
    /// Deserialize bytes into a SchemaDescriptor and SemanticValue.
    pub fn deserialize(
        data: &[u8],
    ) -> Result<(SchemaDescriptor, SemanticValue), RepresentationError> {
        if data.len() < 4 + 4 + 2 + 4 {
            return Err(RepresentationError::MalformedInput(
                "Input buffer too small to contain valid SCRS header".into(),
            ));
        }

        let mut offset = 0;

        // 1. Verify magic
        if &data[offset..offset + 4] != MAGIC_BYTES {
            return Err(RepresentationError::MalformedInput(
                "Invalid magic header: expected 'SCRS'".into(),
            ));
        }
        offset += 4;

        // 2. Format version
        let format_version = u32::from_le_bytes(
            data[offset..offset + 4]
                .try_into()
                .map_err(|_| RepresentationError::MalformedInput("Failed to read format version".into()))?,
        );
        offset += 4;

        // 3. Schema ID
        let id_len = u16::from_le_bytes(
            data[offset..offset + 2]
                .try_into()
                .map_err(|_| RepresentationError::MalformedInput("Failed to read schema id len".into()))?,
        ) as usize;
        offset += 2;

        if offset + id_len > data.len() {
            return Err(RepresentationError::MalformedInput(
                "Schema ID length exceeds buffer".into(),
            ));
        }
        let schema_id_str = std::str::from_utf8(&data[offset..offset + id_len])
            .map_err(|_| RepresentationError::MalformedInput("Invalid UTF-8 in schema ID".into()))?
            .to_string();
        offset += id_len;

        // 4. Schema version
        if offset + 4 > data.len() {
            return Err(RepresentationError::MalformedInput(
                "Buffer truncated before schema version".into(),
            ));
        }
        let schema_version = u32::from_le_bytes(
            data[offset..offset + 4]
                .try_into()
                .map_err(|_| RepresentationError::MalformedInput("Failed to read schema version".into()))?,
        );
        offset += 4;

        let schema = SchemaDescriptor::new(
            schema_id_str,
            schema_version,
            format_version,
            "Deserialized SCR schema",
        );

        // 5. Decode value
        let (val, bytes_read) = Self::decode_value(&data[offset..])?;
        offset += bytes_read;

        if offset != data.len() {
            return Err(RepresentationError::MalformedInput(format!(
                "Extraneous unconsumed trailing bytes: {} remaining",
                data.len() - offset
            )));
        }

        Ok((schema, val))
    }

    fn decode_value(slice: &[u8]) -> Result<(SemanticValue, usize), RepresentationError> {
        if slice.is_empty() {
            return Err(RepresentationError::MalformedInput(
                "Unexpected end of input while reading tag".into(),
            ));
        }

        let tag = slice[0];
        let mut offset = 1;

        match tag {
            0x00 => Ok((SemanticValue::Null, offset)),
            0x01 => Ok((SemanticValue::Bool(false), offset)),
            0x02 => Ok((SemanticValue::Bool(true), offset)),
            0x03 => {
                if offset + 8 > slice.len() {
                    return Err(RepresentationError::MalformedInput("Truncated Int64".into()));
                }
                let val = i64::from_le_bytes(slice[offset..offset + 8].try_into().unwrap());
                offset += 8;
                Ok((SemanticValue::Int64(val), offset))
            }
            0x04 => {
                if offset + 8 > slice.len() {
                    return Err(RepresentationError::MalformedInput("Truncated Float64".into()));
                }
                let bits = u64::from_le_bytes(slice[offset..offset + 8].try_into().unwrap());
                let val = f64::from_bits(bits);
                offset += 8;
                Ok((SemanticValue::Float64(val), offset))
            }
            0x05 => {
                if offset + 4 > slice.len() {
                    return Err(RepresentationError::MalformedInput("Truncated String length".into()));
                }
                let len = u32::from_le_bytes(slice[offset..offset + 4].try_into().unwrap()) as usize;
                offset += 4;
                if offset + len > slice.len() {
                    return Err(RepresentationError::MalformedInput("Truncated String content".into()));
                }
                let s = std::str::from_utf8(&slice[offset..offset + len])
                    .map_err(|_| RepresentationError::MalformedInput("Invalid UTF-8 in String".into()))?
                    .to_string();
                offset += len;
                Ok((SemanticValue::String(s), offset))
            }
            0x06 => {
                if offset + 4 > slice.len() {
                    return Err(RepresentationError::MalformedInput("Truncated Bytes length".into()));
                }
                let len = u32::from_le_bytes(slice[offset..offset + 4].try_into().unwrap()) as usize;
                offset += 4;
                if offset + len > slice.len() {
                    return Err(RepresentationError::MalformedInput("Truncated Bytes content".into()));
                }
                let bytes = slice[offset..offset + len].to_vec();
                offset += len;
                Ok((SemanticValue::Bytes(bytes), offset))
            }
            0x07 => {
                if offset + 4 > slice.len() {
                    return Err(RepresentationError::MalformedInput("Truncated Array count".into()));
                }
                let count = u32::from_le_bytes(slice[offset..offset + 4].try_into().unwrap()) as usize;
                offset += 4;
                let mut items = Vec::with_capacity(count);
                for _ in 0..count {
                    let (item, read) = Self::decode_value(&slice[offset..])?;
                    items.push(item);
                    offset += read;
                }
                Ok((SemanticValue::Array(items), offset))
            }
            0x08 => {
                if offset + 4 > slice.len() {
                    return Err(RepresentationError::MalformedInput("Truncated Map count".into()));
                }
                let count = u32::from_le_bytes(slice[offset..offset + 4].try_into().unwrap()) as usize;
                offset += 4;
                let mut map = BTreeMap::new();
                for _ in 0..count {
                    if offset + 4 > slice.len() {
                        return Err(RepresentationError::MalformedInput("Truncated Map key length".into()));
                    }
                    let k_len = u32::from_le_bytes(slice[offset..offset + 4].try_into().unwrap()) as usize;
                    offset += 4;
                    if offset + k_len > slice.len() {
                        return Err(RepresentationError::MalformedInput("Truncated Map key string".into()));
                    }
                    let key = std::str::from_utf8(&slice[offset..offset + k_len])
                        .map_err(|_| RepresentationError::MalformedInput("Invalid UTF-8 in Map key".into()))?
                        .to_string();
                    offset += k_len;

                    let (v, read) = Self::decode_value(&slice[offset..])?;
                    map.insert(key, v);
                    offset += read;
                }
                Ok((SemanticValue::Map(map), offset))
            }
            0x09 => {
                if offset + 4 > slice.len() {
                    return Err(RepresentationError::MalformedInput("Truncated EntityRef length".into()));
                }
                let len = u32::from_le_bytes(slice[offset..offset + 4].try_into().unwrap()) as usize;
                offset += 4;
                if offset + len > slice.len() {
                    return Err(RepresentationError::MalformedInput("Truncated EntityRef string".into()));
                }
                let ref_id = std::str::from_utf8(&slice[offset..offset + len])
                    .map_err(|_| RepresentationError::MalformedInput("Invalid UTF-8 in EntityRef".into()))?
                    .to_string();
                offset += len;
                Ok((SemanticValue::EntityRef(ref_id), offset))
            }
            other => Err(RepresentationError::MalformedInput(format!(
                "Unknown tag byte 0x{:02x}",
                other
            ))),
        }
    }
}
