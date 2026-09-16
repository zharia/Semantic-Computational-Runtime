/// Defined boundary across which persistent state remains recoverable.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum LifetimeBoundary {
    /// State survives within the lifetime of the host process.
    ProcessLifetime,
    /// State survives process termination and restart within a persistent session.
    ExecutionSession,
    /// State survives host reboot and power cycling.
    SystemRestart,
    /// State survives across hardware lifecycles and permanent archival storage.
    PermanentArchival,
}
