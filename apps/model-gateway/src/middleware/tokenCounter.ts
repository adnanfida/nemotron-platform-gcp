// Token-counting middleware for cost attribution.
//
// Stub for now: logs structured JSON to stdout (Cloud Logging picks it up
// automatically when running on Cloud Run). Replace with a real Pub/Sub
// publisher once the data-plane module provisions the topic and the
// Terraform iam module grants pubsub.publisher to the gateway's GSA.
//
// TODO: real implementation:
//   import { PubSub } from "@google-cloud/pubsub";
//   const pubsub = new PubSub();
//   const topic = pubsub.topic(process.env.TOKEN_USAGE_TOPIC);
//   await topic.publishMessage({ json: usageEvent });

import type { Context, Next } from "hono";

type UsageEvent = {
  timestamp: string;
  tenantId: string;
  sessionId: string;
  model: string;
  inputTokens: number;
  outputTokens: number;
  status: number;
  latencyMs: number;
};

export function tokenCounterMiddleware() {
  return async (c: Context, next: Next) => {
    const start = Date.now();
    const tenantId = c.req.header("X-Tenant-ID") ?? "default-tenant";
    const sessionId = c.req.query("session_id") ?? "default-session";

    await next();

    // TODO: real token counting once we intercept the streaming body.
    // For now we emit a placeholder event so downstream consumers can
    // wire on the event shape without waiting for the parser.
    const event: UsageEvent = {
      timestamp: new Date().toISOString(),
      tenantId,
      sessionId,
      model: "unknown",
      inputTokens: 0,
      outputTokens: 0,
      status: c.res.status,
      latencyMs: Date.now() - start,
    };
    console.log(JSON.stringify({ severity: "INFO", usage: event }));
  };
}
