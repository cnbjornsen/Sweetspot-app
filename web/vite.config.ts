import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// `base` rewrites asset URLs for the GitHub Pages subpath
// (https://<user>.github.io/Sweetspot-app/). Dev mode keeps `/` so
// http://localhost:5173/ still works without the prefix.
export default defineConfig(({ command }) => ({
  base: command === 'build' ? process.env.PAGES_BASE ?? '/Sweetspot-app/' : '/',
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5173,
  },
}));
