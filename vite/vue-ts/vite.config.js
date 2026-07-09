import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";

const extraHosts = process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS
  ? process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS.split(",")
  : [];

export default defineConfig({
  plugins: [vue()],
  server: {
    allowedHosts: extraHosts,
  },
});
