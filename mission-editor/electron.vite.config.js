import { defineConfig } from 'electron-vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  main: {
    build: {
      lib: {
        entry: './main/index.js',
        formats: ['cjs'],
        fileName: 'index'
      },
      outDir: 'out/main',
      rollupOptions: {
        external: ['electron']
      }
    },
    preload: {
      entry: './main/preload.js',
      outDir: 'out/main',
      fileName: 'preload'
    }
  },
  renderer: {
    root: '.',
    plugins: [vue()],
    build: {
      outDir: 'out/renderer',
      rollupOptions: {
        input: 'renderer/index.html'
      }
    }
  }
})
