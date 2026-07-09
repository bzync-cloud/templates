import { defineConfig } from "vite";
import laravel from "laravel-vite-plugin";
import react from "@vitejs/plugin-react";

const extraHosts = process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS
  ? process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS.split(",")
  : [];

export default defineConfig({
  plugins: [
    laravel({
      input: ["resources/js/app.jsx"],
      refresh: true,
    }),
    react(),
  ],
  server: {
    allowedHosts: extraHosts,
  },
});
