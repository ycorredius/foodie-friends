import { defineConfig } from 'vite'
import ViteRails from 'vite-plugin-rails'
import React from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [
    ViteRails({
      fullReload:{
        additionalPaths: ['app/frontend', 'app/controllers' ],
      }
    }),
    React(),
  ],
})
