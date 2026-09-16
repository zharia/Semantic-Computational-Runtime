use crate::error::IdentityError;
use std::cmp::Ordering;
use std::fmt;

/// Coordinate Region representing a half-open interval [low, high)
/// within the coordinate space.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct CoordinateRegion {
    pub low: u64,
    pub high: u64,
}

impl CoordinateRegion {
    pub fn new(low: u64, high: u64) -> Result<Self, IdentityError> {
        if low >= high {
            return Err(IdentityError::InvalidRegion(format!(
                "low bound ({}) must be strictly less than high bound ({})",
                low, high
            )));
        }
        Ok(Self { low, high })
    }

    pub fn contains(&self, coord: u64) -> bool {
        self.low <= coord && coord < self.high
    }

    pub fn is_subset_of(&self, other: &CoordinateRegion) -> bool {
        self.low >= other.low && self.high <= other.high
    }

    pub fn overlaps(&self, other: &CoordinateRegion) -> bool {
        std::cmp::max(self.low, other.low) < std::cmp::min(self.high, other.high)
    }

    pub fn intersection(&self, other: &CoordinateRegion) -> Option<CoordinateRegion> {
        let l = std::cmp::max(self.low, other.low);
        let h = std::cmp::min(self.high, other.high);
        if l < h {
            Some(CoordinateRegion { low: l, high: h })
        } else {
            None
        }
    }

    pub fn size(&self) -> u64 {
        self.high - self.low
    }
}

impl fmt::Display for CoordinateRegion {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "[{}, {})", self.low, self.high)
    }
}

/// SID-001 Concrete Semantic Identifier Coordinate.
/// Represents an immutable point in the semantic address space.
///
/// Bit layout (128 bits):
/// - bits 64..127: Domain ID (64 bits)
/// - bits 32..63:  Local Index / Sequence within domain (32 bits)
/// - bits 0..31:   Authority Generation at allocation time (32 bits)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct SidCoordinate {
    pub domain_id: u64,
    pub index: u32,
    pub generation: u32,
}

impl SidCoordinate {
    pub const fn new(domain_id: u64, index: u32, generation: u32) -> Self {
        Self {
            domain_id,
            index,
            generation,
        }
    }

    /// Convert coordinate into a 128-bit unsigned integer.
    pub const fn to_u128(&self) -> u128 {
        ((self.domain_id as u128) << 64)
            | ((self.index as u128) << 32)
            | (self.generation as u128)
    }

    /// Reconstruct coordinate from a 128-bit unsigned integer.
    pub const fn from_u128(val: u128) -> Self {
        let domain_id = (val >> 64) as u64;
        let index = ((val >> 32) & 0xffff_ffff) as u32;
        let generation = (val & 0xffff_ffff) as u32;
        Self {
            domain_id,
            index,
            generation,
        }
    }

    /// Convert coordinate into a high-throughput 16-byte array (big endian).
    pub const fn to_bytes(&self) -> [u8; 16] {
        self.to_u128().to_be_bytes()
    }

    /// Reconstruct coordinate from a 16-byte array (big endian).
    pub const fn from_bytes(bytes: [u8; 16]) -> Self {
        Self::from_u128(u128::from_be_bytes(bytes))
    }

    /// Format as canonical URI: `sid://<root_id>/<domain_id>/<index>?gen=<generation>`
    pub fn to_uri(&self, root_id: &str) -> String {
        format!(
            "sid://{}/{}/{}?gen={}",
            root_id, self.domain_id, self.index, self.generation
        )
    }

    /// Parse from canonical URI: `sid://<root_id>/<domain_id>/<index>?gen=<generation>`
    pub fn from_uri(uri: &str) -> Result<(String, Self), IdentityError> {
        let stripped = uri.strip_prefix("sid://").ok_or_else(|| {
            IdentityError::InvalidUri(format!("Expected 'sid://' prefix in '{}'", uri))
        })?;

        let parts: Vec<&str> = stripped.split('/').collect();
        if parts.len() != 3 {
            return Err(IdentityError::InvalidUri(format!(
                "Expected format 'sid://<root>/<domain>/<index>?gen=<gen>', got '{}'",
                uri
            )));
        }

        let root_id = parts[0].to_string();
        let domain_id: u64 = parts[1].parse().map_err(|_| {
            IdentityError::InvalidUri(format!("Invalid domain ID in URI: '{}'", parts[1]))
        })?;

        let index_and_query: Vec<&str> = parts[2].split("?gen=").collect();
        if index_and_query.len() != 2 {
            return Err(IdentityError::InvalidUri(format!(
                "Expected '?gen=<generation>' query parameter in URI: '{}'",
                uri
            )));
        }

        let index: u32 = index_and_query[0].parse().map_err(|_| {
            IdentityError::InvalidUri(format!("Invalid index in URI: '{}'", index_and_query[0]))
        })?;

        let generation: u32 = index_and_query[1].parse().map_err(|_| {
            IdentityError::InvalidUri(format!(
                "Invalid generation in URI: '{}'",
                index_and_query[1]
            ))
        })?;

        Ok((
            root_id,
            Self {
                domain_id,
                index,
                generation,
            },
        ))
    }
}

impl PartialOrd for SidCoordinate {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for SidCoordinate {
    fn cmp(&self, other: &Self) -> Ordering {
        self.to_u128().cmp(&other.to_u128())
    }
}

impl fmt::Display for SidCoordinate {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "SID({}:{}:g{})",
            self.domain_id, self.index, self.generation
        )
    }
}

/// Rule IAM-R019: Multi-Root Scoped Identity (Model B).
/// Combines an external Root Authority context with an immutable coordinate.
#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct GlobalIdentity {
    pub root_id: String,
    pub coordinate: SidCoordinate,
}

impl GlobalIdentity {
    pub fn new(root_id: impl Into<String>, coordinate: SidCoordinate) -> Self {
        Self {
            root_id: root_id.into(),
            coordinate,
        }
    }

    pub fn to_uri(&self) -> String {
        self.coordinate.to_uri(&self.root_id)
    }
}

impl fmt::Display for GlobalIdentity {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.to_uri())
    }
}
