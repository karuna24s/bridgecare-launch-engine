// vite.config.mts
import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

export default defineConfig({
  plugins: [
    tailwindcss(),
    RubyPlugin(),
    // Senior Move: This enables Vue 3 SFC (Single File Component) support
    vue(),
  ],
  resolve: {
    alias: {
      // Allows us to use '@' as a shortcut for the frontend root
      '@': path.resolve(__dirname, 'app/frontend'),
    },
  },
  server: {
    // Ensuring the HMR (Hot Module Replacement) plays nice with Rails
    strictPort: true,
  }
})