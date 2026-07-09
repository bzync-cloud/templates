import { defineConfig } from "vite";
import laravel from "laravel-vite-plugin";
import { svelte } from "@sveltejs/vite-plugin-svelte";

const extraHosts = process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS
  ? process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS.split(",")
  : [];

export default defineConfig({
  plugins: [
    laravel({
      input: ["resources/js/app.js"],
      refresh: true,
    }),
    svelte(),
  ],
  server: {
    allowedHosts: extraHosts,
  },
});
