import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

const extraHosts = process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS
  ? process.env.__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS.split(",")
  : [];

export default defineConfig({
  plugins: [react()],
  server: {
    allowedHosts: extraHosts,
  },
});
