// Memorystore (Redis) session affinity lookup.
//
// Stub for now: returns null so the gateway falls back to round-robin
// across the GKE Service. Replace with a real ioredis client once
// MEMORYSTORE_HOST + MEMORYSTORE_PORT env vars are wired in via the
// Terraform data-plane module.
//
// TODO: real implementation:
//   import Redis from "ioredis";
//   const client = new Redis({ host: ..., port: ..., lazyConnect: true });
//   client.get(`affinity:${tenantId}:${sessionId}`).then(hint => hint ?? null);
//
// Cache TTL ~10 minutes, refreshed on each successful request (via the
// async finalization in the request handler).

export async function getSessionReplicaHint(
  tenantId: string,
  sessionId: string,
): Promise<string | null> {
  // Suppress unused-warning until the real implementation lands.
  void tenantId;
  void sessionId;
  return null;
}
