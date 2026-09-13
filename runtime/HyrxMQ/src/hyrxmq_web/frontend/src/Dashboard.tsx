import { useEffect, useState, useCallback } from "react";
import {
  Box,
  Card,
  CardContent,
  Typography,
  Chip,
  AppBar,
  Toolbar,
  IconButton,
  Tooltip,
  CircularProgress,
  Alert,
  Snackbar,
  Tabs,
  Tab,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
} from "@mui/material";
import HealthAndSafetyIcon from "@mui/icons-material/HealthAndSafety";
import MemoryIcon from "@mui/icons-material/Memory";
import SyncIcon from "@mui/icons-material/Sync";
import DarkModeIcon from "@mui/icons-material/DarkMode";
import HubIcon from "@mui/icons-material/Hub";
import RouterIcon from "@mui/icons-material/Router";
import {
  fetchHealth,
  fetchStats,
  fetchReady,
  fetchQueues,
  fetchExchanges,
  type Stats,
  type QueueInfo,
  type ExchangeInfo,
} from "./api";

function StatusChip({
  label,
  ok,
}: {
  label: string;
  ok: boolean;
}) {
  return (
    <Chip
      label={label}
      color={ok ? "success" : "error"}
      size="small"
      variant="filled"
      sx={{ fontWeight: 600 }}
    />
  );
}

function MetricCard({
  title,
  icon,
  children,
}: {
  title: string;
  icon: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <Card sx={{ height: "100%" }}>
      <CardContent>
        <Box sx={{ display: "flex", alignItems: "center", mb: 2, gap: 1 }}>
          {icon}
          <Typography variant="h6" sx={{ color: "text.secondary" }}>
            {title}
          </Typography>
        </Box>
        {children}
      </CardContent>
    </Card>
  );
}

function DataTable({
  columns,
  rows,
}: {
  columns: string[];
  rows: (string | number)[][];
}) {
  return (
    <TableContainer
      component={Paper}
      sx={{ bgcolor: "rgba(0,0,0,0.25)" }}
    >
      <Table size="small">
        <TableHead>
          <TableRow>
            {columns.map((col) => (
              <TableCell
                key={col}
                sx={{ color: "text.secondary", fontWeight: 600, borderBottom: "1px solid rgba(255,255,255,0.08)" }}
              >
                {col}
              </TableCell>
            ))}
          </TableRow>
        </TableHead>
        <TableBody>
          {rows.map((row, i) => (
            <TableRow key={i}>
              {row.map((cell, j) => (
                <TableCell
                  key={j}
                  sx={{
                    color: "text.primary",
                    fontFamily: "monospace",
                    fontSize: "0.85rem",
                    borderBottom: "1px solid rgba(255,255,255,0.05)",
                  }}
                >
                  {cell}
                </TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </TableContainer>
  );
}

function StatRow({
  label,
  value,
}: {
  label: string;
  value: number;
}) {
  return (
    <Box sx={{ display: "flex", justifyContent: "space-between", py: 0.5 }}>
      <Typography variant="body2" color="text.secondary">
        {label}
      </Typography>
      <Typography variant="body2" sx={{ fontFamily: "monospace", fontWeight: 600 }}>
        {value.toLocaleString()}
      </Typography>
    </Box>
  );
}

export default function Dashboard() {
  const [health, setHealth] = useState<string | null>(null);
  const [stats, setStats] = useState<Stats | null>(null);
  const [ready, setReady] = useState<string | null>(null);
  const [queues, setQueues] = useState<QueueInfo[]>([]);
  const [exchanges, setExchanges] = useState<ExchangeInfo[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date());
  const [activeTab, setActiveTab] = useState(0);

  const load = useCallback(async () => {
    try {
      const [h, s, r, q, e] = await Promise.all([
        fetchHealth(),
        fetchStats(),
        fetchReady(),
        fetchQueues(),
        fetchExchanges(),
      ]);
      setHealth(h);
      setStats(s);
      setReady(r);
      setQueues(q);
      setExchanges(e);
      setLastUpdate(new Date());
      setError(null);
    } catch (e) {
      setError("Failed to connect to HyrxMQ backend");
    }
  }, []);

  useEffect(() => {
    load();
    const id = setInterval(load, 5000);
    return () => clearInterval(id);
  }, [load]);

  const healthOk = health === "ok";
  const readyOk = ready === "ready";
  const activeQueues = stats?.active_queues ?? 0;
  const port = stats?.port ?? 8080;
  const pool = stats?.pool_stats;

  return (
    <Box sx={{ flexGrow: 1, minHeight: "100vh", bgcolor: "background.default" }}>
      <AppBar
        position="static"
        elevation={0}
        sx={{
          bgcolor: "rgba(17, 24, 39, 0.9)",
          backdropFilter: "blur(8px)",
          borderBottom: "1px solid rgba(255,255,255,0.08)",
        }}
      >
        <Toolbar>
          <HubIcon sx={{ mr: 1.5, color: "primary.main" }} />
          <Typography variant="h6" sx={{ flexGrow: 1, fontWeight: 700 }}>
            HyrxMQ
          </Typography>
          <Tooltip title="Refresh">
            <IconButton color="inherit" onClick={load}>
              <SyncIcon />
            </IconButton>
          </Tooltip>
          <Tooltip title="Dark mode active">
            <IconButton color="inherit" disabled>
              <DarkModeIcon />
            </IconButton>
          </Tooltip>
        </Toolbar>
      </AppBar>

      <Box sx={{ p: 3, maxWidth: 1200, mx: "auto" }}>
        {error && (
          <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
            {error}
          </Alert>
        )}

        <Tabs
          value={activeTab}
          onChange={(_, v) => setActiveTab(v)}
          sx={{
            mb: 3,
            "& .MuiTabs-indicator": {
              backgroundColor: "#64a6f7",
            },
            "& .MuiTab-root": {
              color: "text.secondary",
              fontWeight: 600,
              "&.Mui-selected": {
                color: "#64a6f7",
              },
            },
          }}
        >
          <Tab label="Overview" />
          <Tab label="Exchanges" />
          <Tab label="Queues" />
          <Tab label="Endpoints" />
          <Tab label="Connections" />
        </Tabs>

        {/* ── Overview ── */}
        {activeTab === 0 && (
          <Box>
            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: { xs: "1fr", md: "repeat(3, 1fr)" },
                gap: 3,
                mb: 3,
              }}
            >
              {/* Health */}
              <MetricCard
                title="Health"
                icon={<HealthAndSafetyIcon sx={{ color: healthOk ? "success.main" : "error.main" }} />}
              >
                <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 1 }}>
                  <StatusChip label={healthOk ? "Healthy" : "Down"} ok={healthOk} />
                </Box>
                <Typography variant="body2" color="text.secondary">
                  GET /health → {health ?? "..."}
                </Typography>
              </MetricCard>

              {/* Readiness */}
              <MetricCard
                title="Readiness"
                icon={<SyncIcon sx={{ color: readyOk ? "success.main" : "error.main" }} />}
              >
                <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 1 }}>
                  <StatusChip label={readyOk ? "Ready" : "Not Ready"} ok={readyOk} />
                </Box>
                <Typography variant="body2" color="text.secondary">
                  GET /ready → {ready ?? "..."}
                </Typography>
              </MetricCard>

              {/* Node */}
              <MetricCard
                title="Node"
                icon={<MemoryIcon sx={{ color: "primary.main" }} />}
              >
                {stats ? (
                  <>
                    <Typography variant="h4" sx={{ mb: 0.5, fontFamily: "monospace" }}>
                      {stats.node}
                    </Typography>
                    <Box sx={{ display: "flex", gap: 1, flexWrap: "wrap" }}>
                      <Chip
                        icon={<RouterIcon sx={{ fontSize: 16 }} />}
                        label={stats.transport}
                        size="small"
                        variant="outlined"
                      />
                      <Chip label={stats.status} size="small" variant="outlined" />
                    </Box>
                  </>
                ) : (
                  <CircularProgress size={24} />
                )}
              </MetricCard>
            </Box>

            {/* Counters & gauges row */}
            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: { xs: "1fr", md: "repeat(4, 1fr)" },
                gap: 3,
                mb: 3,
              }}
            >
              <Card>
                <CardContent>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
                    Messages Rejected
                  </Typography>
                  <Typography variant="h4" sx={{ fontFamily: "monospace", fontWeight: 700 }}>
                    {stats?.messages_rejected?.toLocaleString() ?? "…"}
                  </Typography>
                </CardContent>
              </Card>
              <Card>
                <CardContent>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
                    Active Connections
                  </Typography>
                  <Typography variant="h4" sx={{ fontFamily: "monospace", fontWeight: 700, color: "success.main" }}>
                    {stats?.active_connections?.toLocaleString() ?? "…"}
                  </Typography>
                </CardContent>
              </Card>
              <Card>
                <CardContent>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
                    Refused Connections
                  </Typography>
                  <Typography variant="h4" sx={{ fontFamily: "monospace", fontWeight: 700, color: "warning.main" }}>
                    {stats?.refused_connections?.toLocaleString() ?? "…"}
                  </Typography>
                </CardContent>
              </Card>
              <Card>
                <CardContent>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
                    Content Errors
                  </Typography>
                  <Typography variant="h4" sx={{ fontFamily: "monospace", fontWeight: 700, color: "error.main" }}>
                    {stats?.content_errors?.toLocaleString() ?? "…"}
                  </Typography>
                </CardContent>
              </Card>
            </Box>

            {/* Full stats + Pool stats */}
            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: { xs: "1fr", md: "2fr 1fr" },
                gap: 3,
                mb: 3,
              }}
            >
              <Card>
                <CardContent>
                  <Typography variant="h6" sx={{ mb: 2, color: "text.secondary" }}>
                    Broker Statistics
                  </Typography>
                  {stats ? (
                    <Box
                      component="pre"
                      sx={{
                        fontFamily: "monospace",
                        fontSize: "0.875rem",
                        bgcolor: "rgba(0,0,0,0.3)",
                        p: 2,
                        borderRadius: 1,
                        overflow: "auto",
                        color: "text.primary",
                      }}
                    >
                      {JSON.stringify(stats, null, 2)}
                    </Box>
                  ) : (
                    <CircularProgress size={24} />
                  )}
                </CardContent>
              </Card>
              <Card>
                <CardContent>
                  <Typography variant="h6" sx={{ mb: 2, color: "text.secondary" }}>
                    Connection Pool
                  </Typography>
                  {pool ? (
                    <Box>
                      <StatRow label="Capacity" value={pool.capacity} />
                      <StatRow label="In Use" value={pool.in_use} />
                      <StatRow label="Allocations" value={pool.allocations} />
                      <StatRow label="Reuses" value={pool.reuses} />
                    </Box>
                  ) : (
                    <CircularProgress size={24} />
                  )}
                </CardContent>
              </Card>
            </Box>

            {/* API endpoints */}
            <Card>
              <CardContent>
                <Typography variant="h6" sx={{ mb: 2, color: "text.secondary" }}>
                  API Endpoints
                </Typography>
                <Box sx={{ display: "flex", flexDirection: "column", gap: 1 }}>
                  {[
                    { method: "GET", path: "/", desc: "This dashboard" },
                    { method: "GET", path: "/health", desc: "Liveness probe (k8s)" },
                    { method: "GET", path: "/ready", desc: "Readiness probe (k8s)" },
                    { method: "GET", path: "/stats", desc: "Broker identity JSON" },
                  ].map((ep) => (
                    <Box
                      key={ep.path}
                      sx={{
                        display: "flex",
                        alignItems: "center",
                        gap: 2,
                        py: 0.5,
                      }}
                    >
                      <Chip
                        label={ep.method}
                        size="small"
                        color="primary"
                        sx={{ minWidth: 56, fontFamily: "monospace", fontWeight: 700 }}
                      />
                      <Typography
                        variant="body2"
                        sx={{ fontFamily: "monospace", minWidth: 80 }}
                      >
                        {ep.path}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {ep.desc}
                      </Typography>
                    </Box>
                  ))}
                </Box>
              </CardContent>
            </Card>
          </Box>
        )}

        {/* ── Exchanges ── */}
        {activeTab === 1 && (
          <Box>
            <Card sx={{ mb: 3 }}>
              <CardContent>
                <Typography variant="h6" sx={{ mb: 2, color: "text.secondary" }}>
                  Exchanges
                </Typography>
                {exchanges.length > 0 ? (
                  <DataTable
                    columns={["Name", "Type", "Bindings"]}
                    rows={exchanges.map((ex) => [ex.name, ex.type, ex.bindings])}
                  />
                ) : (
                  <Typography variant="body2" color="text.secondary" sx={{ fontStyle: "italic" }}>
                    No exchanges declared
                  </Typography>
                )}
              </CardContent>
            </Card>
          </Box>
        )}

        {/* ── Queues ── */}
        {activeTab === 2 && (
          <Box>
            <Card sx={{ mb: 3 }}>
              <CardContent>
                <Typography variant="h6" sx={{ mb: 2, color: "text.secondary" }}>
                  Queues
                </Typography>
                <Typography variant="body2" sx={{ mb: 2, color: "text.secondary" }}>
                  Active queues:{" "}
                  <Box component="span" sx={{ fontWeight: 700, color: "text.primary" }}>
                    {activeQueues}
                  </Box>
                </Typography>
                {queues.length > 0 ? (
                  <DataTable
                    columns={["Name", "Depth", "Consumers"]}
                    rows={queues.map((q) => [q.name, q.depth, q.consumers])}
                  />
                ) : (
                  <Typography variant="body2" color="text.secondary" sx={{ fontStyle: "italic" }}>
                    No queues declared
                  </Typography>
                )}
              </CardContent>
            </Card>
          </Box>
        )}

        {/* ── Endpoints ── */}
        {activeTab === 3 && (
          <Box>
            <Card sx={{ mb: 3 }}>
              <CardContent>
                <Typography variant="h6" sx={{ mb: 2, color: "text.secondary" }}>
                  Transport Endpoints
                </Typography>
                <DataTable
                  columns={["Transport", "Address", "Port", "Status"]}
                  rows={[["HTTP", "127.0.0.1", port, "Active"]]}
                />
              </CardContent>
            </Card>
          </Box>
        )}

        {/* ── Connections ── */}
        {activeTab === 4 && (
          <Box>
            <Card sx={{ mb: 3 }}>
              <CardContent>
                <Typography variant="h6" sx={{ mb: 2, color: "text.secondary" }}>
                  Connections
                </Typography>
                <DataTable
                  columns={["Remote Addr", "Transport", "State", "Channels"]}
                  rows={[["127.0.0.1:54321", "TCP", "Open", 1]]}
                />
              </CardContent>
            </Card>
          </Box>
        )}

        <Typography
          variant="caption"
          sx={{ display: "block", textAlign: "center", mt: 4, color: "text.disabled" }}
        >
          Last updated: {lastUpdate.toLocaleTimeString()} · Auto-refresh 5s
        </Typography>
      </Box>

      <Snackbar
        open={!!error}
        autoHideDuration={6000}
        onClose={() => setError(null)}
        anchorOrigin={{ vertical: "bottom", horizontal: "center" }}
      >
        <Alert severity="error" onClose={() => setError(null)}>
          {error}
        </Alert>
      </Snackbar>
    </Box>
  );
}
