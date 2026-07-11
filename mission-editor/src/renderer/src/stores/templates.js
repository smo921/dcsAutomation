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
    // Merge templates with duplicate handling
    mergeTemplates(existing, newItems) {
      if (!Array.isArray(existing)) existing = []
      if (!Array.isArray(newItems)) newItems = []

      // Build set of existing IDs
      const existingIds = new Set()
      for (const item of existing) {
        if (item && item.id) {
          existingIds.add(item.id)
        }
      }

      // Build set of new IDs to track duplicates within newItems
      const newIds = new Set()
      for (const item of newItems) {
        if (item && item.id) {
          newIds.add(item.id)
        }
      }

      const result = [...existing]
      for (const item of newItems) {
        if (!item || !item.id) continue

        let currentId = item.id
        let counter = 1

        // Keep renaming until we find a unique ID
        while (existingIds.has(currentId) || newIds.has(currentId)) {
          currentId = `${item.id}_${counter}`
          counter++
        }

        if (currentId !== item.id) {
          item.id = currentId
        }

        newIds.add(currentId)
        existingIds.add(currentId)
        result.push(item)
      }

      return result
    },

    loadTemplates(templates) {
      // Merge templates with existing ones instead of replacing
      for (const [templateKey, items] of Object.entries(templates)) {
        if (items && Array.isArray(items)) {
          const category = templateKey.replace('_templates', '')
          if (this.categories[category]) {
            this.categories[category] = this.mergeTemplates(this.categories[category], items)
          }
        }
      }
    },

    loadWaypointTemplates(waypointTemplates) {
      // Merge waypoint templates with existing ones instead of replacing
      if (waypointTemplates) {
        const existingMap = new Map(this.waypointTemplates.map(t => [t.id, t]))
        Object.entries(waypointTemplates).forEach(([key, value]) => {
          if (!existingMap.has(key)) {
            this.waypointTemplates.push({ id: key, ...value })
          }
        })
      }
    },

    loadFromFullConfig(fullConfig) {
      // Merge templates from a full config object
      const templates = fullConfig.templates || {}
      for (const [key, items] of Object.entries(templates)) {
        if (items && Array.isArray(items)) {
          const category = key.replace('_templates', '')
          if (this.categories[category]) {
            this.categories[category] = this.mergeTemplates(this.categories[category], items)
          }
        }
      }

      // Merge waypoint templates
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
