import { Elysia } from "elysia";

const port = Number(process.env.PORT ?? 3000);

new Elysia()
  .get("/", () => ({ message: "Bun Elysia API running on Bzync Cloud" }))
  .get("/health", () => ({ status: "ok" }))
  .listen({
    hostname: "0.0.0.0",
    port,
  });
