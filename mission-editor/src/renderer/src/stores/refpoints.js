import { defineStore } from 'pinia'
import { loadRefpointsFromConfig, VALID_BULLSEYES } from '../config/configLoader'

// Use the auto-naming convention: defineStore('refpoints') creates useRefpointsStore
export const useRefpointsStore = defineStore('refpoints', {
  state: () => ({
    bullseyes: [],
    airbases: [],
    zones: [],
    towns: [], // Town reference points (imported from MIZ or added from terrain)
    lines: [],
    // All airbases from terrain (for user selection during import)
    allAirbases: [],
    // All towns from terrain (for user selection during import) - raw data
    terrainTowns: {}
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
      this.towns = []
      this.lines = []
      this.allAirbases = []
      this.terrainTowns = {}
    },

    // Set all airbases from terrain (called during MIZ import)
    setAllAirbases(airbases) {
      this.allAirbases = airbases || []
    },

    // Set terrain towns raw data (called during MIZ import)
    setTerrainTowns(towns) {
      this.terrainTowns = towns || {}
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
        towns: this.towns.map(t => ({
          name: t.name,
          ...(t.description && { description: t.description })
        })),
        lines: this.lines
      }
    }
  }
})
