import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const apiUrl = env.VITE_API_URL || 'http://localhost:5000/api';

  return {
    plugins: [react()],
    server: {
      host: "0.0.0.0",
      port: 5173,
      proxy: {
        '/api': {
          target: apiUrl,
          changeOrigin: true,
          secure: false,
          rewrite: (path) => path.replace(/^\/api/, '')
        },
        '/verify-email': {
          target: apiUrl,
          changeOrigin: true,
          secure: false,
        }
      }
    },
    build: {
      outDir: "dist",
      sourcemap: false, // Disable source maps
      assetsInlineLimit: 0, // Serve all assets as files
      rollupOptions: {
        input: {
          main: 'index.html',
          'service-worker': 'public/service-worker.js' // Uncommented ServiceWorker input
        }
      }
    },
  };
});
