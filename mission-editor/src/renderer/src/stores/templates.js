import { defineStore } from 'pinia'

// Use the auto-naming convention: defineStore('templates') creates useTemplatesStore
export const useTemplatesStore = defineStore('templates', {
  state: () => ({
    categories: {
      air: [],
      ground: [],
      naval: [],
      support: []
    }
  }),

  actions: {
    loadTemplates(templates) {
      // templates is object with keys like 'air_templates', 'ground_templates'
      // We need to map these to our categories structure
      for (const [templateKey, items] of Object.entries(templates)) {
        if (items) {
          // Convert 'air_templates' to 'air', 'ground_templates' to 'ground', etc.
          const category = templateKey.replace('_templates', '')
          if (this.categories[category]) {
            this.categories[category] = Array.isArray(items) ? items : [items]
          }
        }
      }
    },

    loadFromFullConfig(fullConfig) {
      // Load templates from a full config object
      const templates = fullConfig.templates || {}
      for (const [key, items] of Object.entries(templates)) {
        if (items && Array.isArray(items)) {
          // Convert 'air_templates' to 'air', 'ground_templates' to 'ground', etc.
          const category = key.replace('_templates', '')
          if (this.categories[category]) {
            this.categories[category] = items
          }
        }
      }
    },

    clear() {
      for (const category of Object.keys(this.categories)) {
        this.categories[category] = []
      }
    },

    getTemplateById(id) {
      for (const category of Object.values(this.categories)) {
        const found = category.find(t => t.id === id)
        if (found) return found
      }
      return null
    },

    getCategories() {
      return Object.keys(this.categories)
    }
  }
})
