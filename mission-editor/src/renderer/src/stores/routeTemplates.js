import { defineStore } from 'pinia'
import { loadRouteTemplatesFromConfig } from '../config/configLoader'

// Use the auto-naming convention: defineStore('routeTemplates') creates useRouteTemplatesStore
export const useRouteTemplatesStore = defineStore('routeTemplates', {
  state: () => ({
    templates: []
  }),

  actions: {
    // Use pure JS loader
    loadFromFullConfig(fullConfig) {
      loadRouteTemplatesFromConfig(this.templates, fullConfig)
    },

    /*
    loadRouteTemplates(routeTemplates) {
      // Merge route templates with existing ones instead of replacing
      if (routeTemplates) {
        const existingMap = new Map(this.templates.map(t => [t.id, t]))
        Object.entries(routeTemplates).forEach(([key, value]) => {
          if (!existingMap.has(key)) {
            this.templates.push({ id: key, ...value })
          }
        })
      }
    },
*/
    clear() {
      this.templates = []
    },

    getTemplateById(id) {
      return this.templates.find(t => t.id === id) || null
    },

    addTemplate(template) {
      this.templates.push(template)
    },

    updateTemplate(templateIndex, template) {
      if (this.templates[templateIndex]) {
        this.templates[templateIndex] = template
      }
    },

    deleteTemplate(templateIndex) {
      if (templateIndex !== -1) {
        this.templates.splice(templateIndex, 1)
      }
    },

    deleteTemplateById(templateId) {
      const index = this.templates.findIndex(t => t.id === templateId)
      if (index !== -1) {
        this.templates.splice(index, 1)
      }
    }
  }
})
