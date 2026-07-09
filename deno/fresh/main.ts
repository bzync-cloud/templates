import { start } from "$fresh/server.ts";
import manifest from "./fresh.gen.ts";

await start(manifest, {
  port: Number(Deno.env.get("PORT") ?? 8000),
  hostname: "0.0.0.0",
});
