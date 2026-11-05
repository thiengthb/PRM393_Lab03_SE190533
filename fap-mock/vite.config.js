import { defineConfig } from 'vite';

// Hosting phục vụ trang ở /fap/ (firebase/firebase.json); dev chạy ở cổng 4173 như Lab 1.
export default defineConfig({
  base: '/fap/',
  server: { host: '127.0.0.1', port: 4173, fs: { allow: ['..'] } },
  preview: { host: '127.0.0.1', port: 4173 },
});
