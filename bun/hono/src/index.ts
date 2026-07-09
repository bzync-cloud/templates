import { Hono } from "hono";

const app = new Hono();

app.get("/", (c) => c.json({ message: "Bun Hono API running on Bzync Cloud" }));
app.get("/health", (c) => c.json({ status: "ok" }));

Bun.serve({
  fetch: app.fetch,
  hostname: "0.0.0.0",
  port: Number(process.env.PORT ?? 3000),
});
