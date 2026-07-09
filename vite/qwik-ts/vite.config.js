import { defineConfig } from "vite";
import { qwikVite } from "@builder.io/qwik/optimizer";

const extraHosts = process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS
  ? process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS.split(",")
  : [];

export default defineConfig({
  plugins: [qwikVite()],
  server: {
    allowedHosts: extraHosts,
  },
});
