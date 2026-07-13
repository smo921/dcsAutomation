import { defineStore } from 'pinia'
import { loadRefpointsFromConfig, VALID_BULLSEYES } from '../config/configLoader'

// Use the auto-naming convention: defineStore('refpoints') creates useRefpointsStore
export const useRefpointsStore = defineStore('refpoints', {
  state: () => ({
    bullseyes: [],
    airbases: [],
    zones: [],
    lines: []
  }),

  actions: {
    // Valid bullseye names - imported from configLoader
    VALID_BULLSEYES,

    // Load configuration using pure JS loader
    loadFromFullConfig(fullConfig) {
      loadRefpointsFromConfig(this, fullConfig)
    },

    // Clear all data
    clear() {
      this.bullseyes = []
      this.airbases = []
      this.zones = []
      this.lines = []
    },

    // Export to config format
    toConfig() {
      return {
        bullseyes: this.bullseyes.map(b => ({
          name: b.name,
          ...(b.description && { description: b.description })
        })),
        airbases: this.airbases.map(a => ({
          name: a.name,
          ...(a.description && { description: a.description })
        })),
        zones: this.zones.map(z => ({
          name: z.name,
          ...(z.description && { description: z.description })
        })),
        lines: this.lines
      }
    }
  }
})
