import { Hono } from "hono";
import { serve } from "@hono/node-server";
import { getSessionReplicaHint } from "./services/redis.js";
import { tokenCounterMiddleware } from "./middleware/tokenCounter.js";

const app = new Hono();

const PORT = parseInt(process.env.PORT ?? "8080", 10);
const BACKEND_SERVICE_URL =
  process.env.BACKEND_SERVICE_URL ?? "http://localhost:8000";
const REQUEST_TIMEOUT_MS = parseInt(
  process.env.REQUEST_TIMEOUT_MS ?? "120000",
  10,
);

app.get("/healthz", (c) => c.json({ status: "healthy" }));

app.post("/v1/chat/completions", tokenCounterMiddleware(), async (c) => {
  const tenantId = c.req.header("X-Tenant-ID") ?? "default-tenant";
  const sessionId = c.req.query("session_id") ?? "default-session";

  const replicaHint = await getSessionReplicaHint(tenantId, sessionId);

  const headers = new Headers(c.req.raw.headers);
  if (replicaHint) {
    headers.set("X-Replica-Hint", replicaHint);
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  try {
    const requestBody = await c.req.raw.clone().arrayBuffer();
    const backendResponse = await fetch(
      `${BACKEND_SERVICE_URL}/v1/chat/completions`,
      {
        method: "POST",
        headers,
        body: requestBody,
        signal: controller.signal,
      },
    );

    const contentType = backendResponse.headers.get("Content-Type") ?? "";
    if (contentType.includes("event-stream")) {
      return new Response(backendResponse.body, {
        headers: backendResponse.headers,
        status: backendResponse.status,
      });
    }

    const responseBody = await backendResponse.json();
    return c.json(responseBody, backendResponse.status as 200);
  } catch (err) {
    const message = err instanceof Error ? err.message : "unknown error";
    if (controller.signal.aborted) {
      return c.json({ error: "backend timeout", detail: message }, 504);
    }
    return c.json({ error: "backend request failed", detail: message }, 502);
  } finally {
    clearTimeout(timeoutId);
  }
});

serve({ fetch: app.fetch, port: PORT });
console.log(`model-gateway listening on :${PORT}`);
