import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'

// Create and configure the app
const app = createApp(App)
const pinia = createPinia()

// Setup stores
app.use(pinia)

// Mount app
app.mount('#app')
