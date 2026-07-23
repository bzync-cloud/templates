import { defineConfig } from "vite";

const extraHosts = process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS
  ? process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS.split(",")
  : [];

export default defineConfig({
  server: {
    allowedHosts: extraHosts,
  },
});
