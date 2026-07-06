import { defineStore } from 'pinia'

// Use the auto-naming convention: defineStore('templates') creates useTemplatesStore
export const useTemplatesStore = defineStore('templates', {
  state: () => ({
    categories: {
      air: [],
      ground: [],
      naval: [],
      support: []
    },
    waypointTemplates: []
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

    loadWaypointTemplates(waypointTemplates) {
      // waypointTemplates is object with keys like 'awacs_orbit', 'cas_sweep'
      if (waypointTemplates) {
        this.waypointTemplates = Object.entries(waypointTemplates).map(([key, value]) => ({
          id: key,
          ...value
        }))
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

      // Load waypoint templates
      const waypointTemplates = fullConfig.waypoint_templates || {}
      this.loadWaypointTemplates(waypointTemplates)
    },

    clear() {
      for (const category of Object.keys(this.categories)) {
        this.categories[category] = []
      }
      this.waypointTemplates = []
    },

    getTemplateById(id) {
      for (const category of Object.values(this.categories)) {
        const found = category.find(t => t.id === id)
        if (found) return found
      }
      return null
    },

    getWaypointTemplateById(id) {
      return this.waypointTemplates.find(t => t.id === id) || null
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
        this.categories[category].splice(templateIndex, 1)
      }
    },

    deleteTemplateById(category, templateId) {
      if (this.categories[category]) {
        const index = this.categories[category].findIndex(t => t.id === templateId)
        if (index !== -1) {
          this.categories[category].splice(index, 1)
        }
      }
    },

    deleteWaypointTemplate(id) {
      const index = this.waypointTemplates.findIndex(t => t.id === id)
      if (index !== -1) {
        this.waypointTemplates.splice(index, 1)
      }
    }
  }
})
