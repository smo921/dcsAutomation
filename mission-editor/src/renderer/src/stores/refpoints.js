import { defineStore } from 'pinia'

// Use the auto-naming convention: defineStore('refpoints') creates useRefpointsStore
export const useRefpointsStore = defineStore('refpoints', {
  state: () => ({
    bullseyes: [],
    airbases: [],
    zones: [],
    lines: []
  }),

  actions: {
    // Valid bullseye names - coalitions in DCS
    VALID_BULLSEYES: ['Red', 'Blue', 'Neutral'],

    addBullseye(name) {
      const validatedName = this.VALID_BULLSEYES.find(n => n.toLowerCase() === name.toLowerCase())
      if (validatedName) {
        this.bullseyes.push({ name: validatedName })
      }
    },

    removeBullseye(index) {
      this.bullseyes.splice(index, 1)
    },

    // Airbase names are stored without coordinates - resolved dynamically at runtime via Airbase.getByName()
    addAirbase(name) {
      this.airbases.push({ name })
    },

    removeAirbase(index) {
      this.airbases.splice(index, 1)
    },

    addZone(name) {
      // Zones only need name - geometry is defined in DCS Mission Editor
      this.zones.push({ name })
    },

    removeZone(index) {
      this.zones.splice(index, 1)
    },

    addLine(name, startX, startY, endX, endY) {
      this.lines.push({ name, startX, startY, endX, endY })
    },

    removeLine(index) {
      this.lines.splice(index, 1)
    },

    loadFromConfig(config) {
      this.bullseyes = (config.bullseyes || []).map(b => ({
        name: b.name
      }))
      this.airbases = (config.airbases || []).map(ab => ({
        name: ab.name
      }))
      this.zones = config.zones || []
      this.lines = config.lines || []
    },

    loadFromFullConfig(fullConfig) {
      // Load reference points from a full config object
      const refpoints = fullConfig.refpoints || {}
      this.bullseyes = (refpoints.bullseyes || []).map(b => ({ name: b.name }))
      this.airbases = (refpoints.airbases || []).map(ab => ({ name: ab.name }))
      this.zones = refpoints.zones || []
      this.lines = refpoints.lines || []
    },

    clear() {
      this.bullseyes = []
      this.airbases = []
      this.zones = []
      this.lines = []
    },

    toConfig() {
      return {
        bullseyes: this.bullseyes,
        airbases: this.airbases,
        zones: this.zones,
        lines: this.lines
      }
    }
  }
})
