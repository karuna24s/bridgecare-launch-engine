import './application.css'

import { createApp, h } from 'vue'
import { createInertiaApp } from '@inertiajs/vue3'

createInertiaApp({
  // This resolves the 'Launch/Dashboard' string from your controller
  // to the actual .vue file
  resolve: name => {
    const pages = import.meta.glob('../Pages/**/*.vue', { eager: true })
    const mod = pages[`../Pages/${name}.vue`]
    if (!mod) {
      throw new Error(`Unknown Inertia page: ${name}`)
    }
    return mod.default ?? mod
  },
  setup({ el, App, props, plugin }) {
    createApp({ render: () => h(App, props) })
      .use(plugin)
      .mount(el)
  },
})