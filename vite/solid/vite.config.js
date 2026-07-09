import { defineConfig } from "vite";
import solid from "vite-plugin-solid";

const extraHosts = process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS
  ? process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS.split(",")
  : [];

export default defineConfig({
  plugins: [solid()],
  server: {
    allowedHosts: extraHosts,
  },
});
