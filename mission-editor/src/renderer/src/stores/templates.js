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
      for (const [category, items] of Object.entries(templates)) {
        if (items) {
          this.categories[category] = Array.isArray(items) ? items : [items]
        }
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
