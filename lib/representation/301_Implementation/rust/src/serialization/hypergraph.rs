use crate::error::RepresentationError;
use crate::serialization::schema::SchemaDescriptor;
use crate::serialization::value::SemanticValue;
use crate::serialization::format::{CanonicalSerializer, CanonicalDeserializer};
use scr_hypergraph::{
    Hypergraph, ElementId, RelationId, IncidenceId, Role, Direction,
};
use std::collections::BTreeMap;

pub const HYPERGRAPH_SCHEMA_ID: &str = "scr.representation.hypergraph";
pub const HYPERGRAPH_SCHEMA_VERSION: u32 = 1;

/// Lossless serializer and deserializer for Semantic Hypergraphs conforming to HGT-001.
pub struct HypergraphSerializer;

impl HypergraphSerializer {
    pub fn schema() -> SchemaDescriptor {
        SchemaDescriptor::new(
            HYPERGRAPH_SCHEMA_ID,
            HYPERGRAPH_SCHEMA_VERSION,
            1,
            "Normative SCR Semantic Hypergraph Serialization Schema",
        )
    }

    /// Convert a Hypergraph into a canonical SemanticValue.
    pub fn to_value(hg: &Hypergraph) -> SemanticValue {
        let mut root = BTreeMap::new();

        // 1. Elements
        let mut elements_arr = Vec::new();
        for elem in hg.elements() {
            let mut elem_map = BTreeMap::new();
            elem_map.insert("id".into(), SemanticValue::EntityRef(elem.id().0.clone()));
            elem_map.insert("name".into(), SemanticValue::String(elem.name().to_string()));
            elements_arr.push(SemanticValue::Map(elem_map));
        }
        root.insert("elements".into(), SemanticValue::Array(elements_arr));

        // 2. Relations (including nullary relations with zero incidences!)
        let mut relations_arr = Vec::new();
        for rel in hg.relations() {
            let mut rel_map = BTreeMap::new();
            rel_map.insert("id".into(), SemanticValue::EntityRef(rel.id().0.clone()));
            rel_map.insert("name".into(), SemanticValue::String(rel.name().to_string()));
            rel_map.insert("is_nullary".into(), SemanticValue::Bool(rel.is_nullary()));
            relations_arr.push(SemanticValue::Map(rel_map));
        }
        root.insert("relations".into(), SemanticValue::Array(relations_arr));

        // 3. Incidences
        let mut incidences_arr = Vec::new();
        for inc in hg.incidences() {
            let mut inc_map = BTreeMap::new();
            inc_map.insert("id".into(), SemanticValue::EntityRef(inc.id().0.clone()));
            inc_map.insert("element".into(), SemanticValue::EntityRef(inc.element().0.clone()));
            inc_map.insert("relation".into(), SemanticValue::EntityRef(inc.relation().0.clone()));
            inc_map.insert("role".into(), SemanticValue::String(inc.role().to_string()));
            inc_map.insert("direction".into(), SemanticValue::String(inc.direction().to_string()));
            incidences_arr.push(SemanticValue::Map(inc_map));
        }
        root.insert("incidences".into(), SemanticValue::Array(incidences_arr));

        SemanticValue::Map(root)
    }

    /// Reconstruct a Hypergraph from a SemanticValue.
    pub fn from_value(val: &SemanticValue) -> Result<Hypergraph, RepresentationError> {
        let map = val.as_map().ok_or_else(|| {
            RepresentationError::DeserializationError("Root value is not a map".into())
        })?;

        let mut hg = Hypergraph::new();

        // 1. Elements
        if let Some(SemanticValue::Array(elems)) = map.get("elements") {
            for elem_val in elems {
                let em = elem_val.as_map().ok_or_else(|| {
                    RepresentationError::DeserializationError("Element is not a map".into())
                })?;
                let id_str = match em.get("id") {
                    Some(SemanticValue::EntityRef(s)) | Some(SemanticValue::String(s)) => s.clone(),
                    _ => return Err(RepresentationError::DeserializationError("Missing element id".into())),
                };
                let name_str = em.get("name").and_then(|v| v.as_str()).unwrap_or("");
                hg.create_element(ElementId::new(id_str), name_str)
                    .map_err(|e| RepresentationError::DeserializationError(e.to_string()))?;
            }
        }

        // 2. Relations
        if let Some(SemanticValue::Array(rels)) = map.get("relations") {
            for rel_val in rels {
                let rm = rel_val.as_map().ok_or_else(|| {
                    RepresentationError::DeserializationError("Relation is not a map".into())
                })?;
                let id_str = match rm.get("id") {
                    Some(SemanticValue::EntityRef(s)) | Some(SemanticValue::String(s)) => s.clone(),
                    _ => return Err(RepresentationError::DeserializationError("Missing relation id".into())),
                };
                let name_str = rm.get("name").and_then(|v| v.as_str()).unwrap_or("");
                hg.create_relation(RelationId::new(id_str), name_str)
                    .map_err(|e| RepresentationError::DeserializationError(e.to_string()))?;
            }
        }

        // 3. Incidences
        if let Some(SemanticValue::Array(incs)) = map.get("incidences") {
            for inc_val in incs {
                let im = inc_val.as_map().ok_or_else(|| {
                    RepresentationError::DeserializationError("Incidence is not a map".into())
                })?;
                let id_str = match im.get("id") {
                    Some(SemanticValue::EntityRef(s)) | Some(SemanticValue::String(s)) => s.clone(),
                    _ => return Err(RepresentationError::DeserializationError("Missing incidence id".into())),
                };
                let elem_str = match im.get("element") {
                    Some(SemanticValue::EntityRef(s)) | Some(SemanticValue::String(s)) => s.clone(),
                    _ => return Err(RepresentationError::DeserializationError("Missing incidence element".into())),
                };
                let rel_str = match im.get("relation") {
                    Some(SemanticValue::EntityRef(s)) | Some(SemanticValue::String(s)) => s.clone(),
                    _ => return Err(RepresentationError::DeserializationError("Missing incidence relation".into())),
                };

                let role = match im.get("role").and_then(|v| v.as_str()).unwrap_or("Operand") {
                    "Input" => Role::Input,
                    "Output" => Role::Output,
                    "Parameter" => Role::Parameter,
                    "Subject" => Role::Subject,
                    "Object" => Role::Object,
                    "Operand" => Role::Operand,
                    "Constraint" => Role::Constraint,
                    "Cause" => Role::Cause,
                    "Effect" => Role::Effect,
                    "Source" => Role::Source,
                    "Target" => Role::Target,
                    other => Role::Custom(other.to_string()),
                };

                let direction = match im.get("direction").and_then(|v| v.as_str()).unwrap_or("--") {
                    "->" => Direction::Ingoing,
                    "<-" => Direction::Outgoing,
                    _ => Direction::Undirected,
                };

                hg.attach_incidence(
                    IncidenceId::new(id_str),
                    &ElementId::new(elem_str),
                    &RelationId::new(rel_str),
                    role,
                    direction,
                )
                .map_err(|e| RepresentationError::DeserializationError(e.to_string()))?;
            }
        }

        Ok(hg)
    }

    /// Serialize a Hypergraph into canonical bytes.
    pub fn to_bytes(hg: &Hypergraph) -> Result<Vec<u8>, RepresentationError> {
        let val = Self::to_value(hg);
        CanonicalSerializer::serialize(&Self::schema(), &val)
    }

    /// Reconstruct a Hypergraph from canonical bytes.
    pub fn from_bytes(data: &[u8]) -> Result<Hypergraph, RepresentationError> {
        let (schema, val) = CanonicalDeserializer::deserialize(data)?;
        if schema.id.0 != HYPERGRAPH_SCHEMA_ID {
            return Err(RepresentationError::SchemaMismatch {
                expected: HYPERGRAPH_SCHEMA_ID.into(),
                found: schema.id.0,
            });
        }
        Self::from_value(&val)
    }
}
