import { createMedusaApp } from "@medusajs/medusa";

const { start } = await createMedusaApp({
  loaders: [],
});

await start();
