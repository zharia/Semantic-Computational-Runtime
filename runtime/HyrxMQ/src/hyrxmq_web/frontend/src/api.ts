const API_BASE = window.location.origin;

export interface PoolStats {
  allocations: number;
  reuses: number;
  capacity: number;
  in_use: number;
}

export interface Stats {
  status: string;
  node: string;
  transport: string;
  port: number;
  active_queues: number;
  active_consumers: number;
  messages_published: number;
  messages_delivered: number;
  messages_acked: number;
  messages_rejected: number;
  active_connections: number;
  refused_connections: number;
  content_errors: number;
  pool_stats: PoolStats;
}

export interface QueueInfo {
  name: string;
  depth: number;
  consumers: number;
}

export interface ExchangeInfo {
  name: string;
  type: string;
  bindings: number;
}

export async function fetchHealth(): Promise<string> {
  const res = await fetch(`${API_BASE}/health`);
  return res.text();
}

export async function fetchStats(): Promise<Stats> {
  const res = await fetch(`${API_BASE}/stats`);
  return res.json();
}

export async function fetchReady(): Promise<string> {
  const res = await fetch(`${API_BASE}/ready`);
  return res.text();
}

export async function fetchQueues(): Promise<QueueInfo[]> {
  const res = await fetch(`${API_BASE}/queues`);
  const data = await res.json();
  return data.queues ?? [];
}

export async function fetchExchanges(): Promise<ExchangeInfo[]> {
  const res = await fetch(`${API_BASE}/exchanges`);
  const data = await res.json();
  return data.exchanges ?? [];
}
