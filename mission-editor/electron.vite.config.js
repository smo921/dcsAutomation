import { defineConfig } from 'electron-vite'
import path from 'path'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  main: {
    build: {
      lib: {
        entry: './src/main/index.js',
        formats: ['cjs'],
        fileName: 'index'
      },
      outDir: 'out/main',
      rollupOptions: {
        external: ['electron']
      }
    },
    preload: {
      entry: './src/preload/preload.js',
      outDir: 'out/main',
      fileName: 'preload'
    }
  },
  renderer: {
    root: './src/renderer',
    plugins: [vue()],
    build: {
      outDir: path.resolve(__dirname, 'out/renderer'),
      rollupOptions: {
        input: 'index.html'
      },
      emptyOutDir: true
    }
  }
})
