import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { traceApiPlugin } from "./src/server/middleware";

export default defineConfig({
  plugins: [react(), traceApiPlugin()],
  server: {
    open: true,
  },
});
