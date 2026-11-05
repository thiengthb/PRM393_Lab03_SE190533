import fs from 'node:fs';
import path from 'node:path';
import { crx } from '@crxjs/vite-plugin';
import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import { defineConfig, loadEnv, type Plugin } from 'vite';

import { createManifest } from './manifest.config';

/**
 * CRXJS exposes every `?script` file to all http(s) pages via web_accessible_resources. The adapter is
 * only ever injected by chrome.scripting from the side panel, which needs no such entry, so drop it:
 * a web-accessible file lets any site detect the extension.
 */
function stripWebAccessibleResources(): Plugin {
  return {
    name: 'fap:strip-web-accessible-resources',
    enforce: 'post',
    apply: 'build',
    // CRXJS writes manifest.json after the bundle hooks, so patch the file once the build closes.
    closeBundle() {
      const file = path.resolve(import.meta.dirname, 'dist/manifest.json');
      if (!fs.existsSync(file)) return;
      const manifest = JSON.parse(fs.readFileSync(file, 'utf8')) as Record<string, unknown>;
      delete manifest.web_accessible_resources;
      fs.writeFileSync(file, `${JSON.stringify(manifest, null, 2)}\n`);
    },
  };
}

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), 'VITE_');
  return {
    plugins: [
      react(),
      tailwindcss(),
      crx({ manifest: createManifest(env) }),
      stripWebAccessibleResources(),
    ],
    resolve: { alias: { '@': path.resolve(import.meta.dirname, 'src') } },
    build: { outDir: 'dist', emptyOutDir: true, sourcemap: false, target: 'chrome116' },
    server: { port: 5199, strictPort: true, cors: { origin: [/chrome-extension:\/\//] } },
  };
});
