import { defineStore } from 'pinia'
import { loadUnitTemplatesFromConfig, loadRouteTemplatesFromConfig } from '../config/configLoader'

// Use the auto-naming convention: defineStore('templates') creates useTemplatesStore
export const useTemplatesStore = defineStore('templates', {
  state: () => ({
    categories: {
      air: [],
      ground: [],
      naval: [],
      support: []
    },
    routeTemplates: []
  }),

  actions: {
    // Use pure JS loaders
    loadFromFullConfig(fullConfig) {
      loadUnitTemplatesFromConfig(this, fullConfig)
      loadRouteTemplatesFromConfig(this.routeTemplates, fullConfig)
    },

    clear() {
      for (const category of Object.keys(this.categories)) {
        this.categories[category] = []
      }
      this.routeTemplates = []
    },

    getTemplateById(id) {
      for (const category of Object.values(this.categories)) {
        const found = category.find(t => t.id === id)
        if (found) return found
      }
      return null
    },

    getRouteTemplateById(id) {
      return this.routeTemplates.find(t => t.id === id) || null
    },

    getCategories() {
      return Object.keys(this.categories)
    }
  }
})
