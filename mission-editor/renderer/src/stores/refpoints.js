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
    addBullseye(name, x, y) {
      this.bullseyes.push({ name, x, y })
    },

    removeBullseye(index) {
      this.bullseyes.splice(index, 1)
    },

    addAirbase(name, x, y, runwayHeading = 0) {
      this.airbases.push({ name, x, y, runwayHeading })
    },

    removeAirbase(index) {
      this.airbases.splice(index, 1)
    },

    addZone(name, centerX, centerY, radius) {
      this.zones.push({ name, centerX, centerY, radius })
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
      this.bullseyes = config.bullseyes || []
      this.airbases = config.airbases || []
      this.zones = config.zones || []
      this.lines = config.lines || []
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
