/// Durability guarantee level declared by a persistence manifestation.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum DurabilityLevel {
    /// In-memory caching only; vulnerable to process crash.
    VolatileMemory,
    /// Preserved across individual process terminations (e.g. staging buffer).
    ProcessBoundaryDurability,
    /// Flushed and fsynced to non-volatile persistent storage.
    CommittedStorageDurability,
    /// Synchronously or quorum-replicated across independent failure domains.
    DistributedReplicatedDurability,
}
