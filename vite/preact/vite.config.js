import { defineConfig } from "vite";
import preact from "@preact/preset-vite";

const extraHosts = process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS
  ? process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS.split(",")
  : [];

export default defineConfig({
  plugins: [preact()],
  server: {
    allowedHosts: extraHosts,
  },
});
