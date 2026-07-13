import { defineStore } from 'pinia'
import { mergeTemplates, loadUnitTemplatesFromConfig } from '../config/configLoader'

// Use the auto-naming convention: defineStore('unitTemplates') creates useUnitTemplatesStore
export const useUnitTemplatesStore = defineStore('unitTemplates', {
  state: () => ({
    categories: {
      air: [],
      ground: [],
      naval: [],
      support: []
    }
  }),

  actions: {
    // Use pure JS loader
    loadFromFullConfig(fullConfig) {
      loadUnitTemplatesFromConfig(this, fullConfig)
    },

    loadTemplates(templates) {
      // Merge templates with existing ones instead of replacing
      for (const [templateKey, items] of Object.entries(templates)) {
        if (items && Array.isArray(items)) {
          const category = templateKey.replace('_templates', '')
          if (this.categories[category]) {
            this.categories[category] = mergeTemplates(this.categories[category], items)
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
    },

    addTemplate(category, template) {
      if (!this.categories[category]) {
        this.categories[category] = []
      }
      this.categories[category].push(template)
    },

    updateTemplate(category, templateIndex, template) {
      if (this.categories[category]) {
        this.categories[category][templateIndex] = template
      }
    },

    deleteTemplate(category, templateIndex) {
      if (this.categories[category]) {
        this.categories[category][templateIndex] = template
      }
    },

    deleteTemplateById(category, templateId) {
      if (this.categories[category]) {
        const index = this.categories[category].findIndex(t => t.id === templateId)
        if (index !== -1) {
          this.categories[category].splice(index, 1)
        }
      }
    }
  }
})
