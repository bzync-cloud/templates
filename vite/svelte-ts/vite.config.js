import { defineConfig } from "vite";
import { svelte } from "@sveltejs/vite-plugin-svelte";

const extraHosts = process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS
  ? process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS.split(",")
  : [];

export default defineConfig({
  plugins: [svelte()],
  server: {
    allowedHosts: extraHosts,
  },
});
