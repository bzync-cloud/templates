import { Hono } from "hono";

const app = new Hono();

app.get("/", (c) => c.json({ message: "Deno Hono API running on Bzync Cloud" }));
app.get("/health", (c) => c.json({ status: "ok" }));

Deno.serve({ hostname: "0.0.0.0", port: Number(Deno.env.get("PORT") ?? 8000) }, app.fetch);
