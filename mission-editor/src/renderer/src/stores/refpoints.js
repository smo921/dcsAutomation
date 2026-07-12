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
      // Merge with existing data instead of replacing
      const existingNames = new Set()
      this.bullseyes.forEach(b => existingNames.add(b.name))
      this.airbases.forEach(ab => existingNames.add(ab.name))
      this.zones.forEach(z => existingNames.add(z.name))
      this.lines.forEach(l => existingNames.add(l.name))

      // Add bullseyes
      (config.bullseyes || []).forEach(b => {
        let name = b.name
        let counter = 1
        while (existingNames.has(name)) {
          name = `${b.name}_${counter}`
          counter++
        }
        existingNames.add(name)
        this.bullseyes.push({ name })
      })

      // Add airbases
      (config.airbases || []).forEach(ab => {
        let name = ab.name
        let counter = 1
        while (existingNames.has(name)) {
          name = `${ab.name}_${counter}`
          counter++
        }
        existingNames.add(name)
        this.airbases.push({ name })
      })

      // Add zones
      (config.zones || []).forEach(z => {
        let name = z.name
        let counter = 1
        while (existingNames.has(name)) {
          name = `${z.name}_${counter}`
          counter++
        }
        existingNames.add(name)
        this.zones.push({ name })
      })

      // Add lines
      (config.lines || []).forEach(l => {
        let name = l.name
        let counter = 1
        while (existingNames.has(name)) {
          name = `${l.name}_${counter}`
          counter++
        }
        existingNames.add(name)
        this.lines.push({ name, startX: l.startX || 0, startY: l.startY || 0, endX: l.endX || 0, endY: l.endY || 0 })
      })
    },

    loadFromFullConfig(fullConfig) {
      // Merge with existing data instead of replacing
      const existingNames = new Set()
      this.bullseyes.forEach(b => existingNames.add(b.name))
      this.airbases.forEach(ab => existingNames.add(ab.name))
      this.zones.forEach(z => existingNames.add(z.name))
      this.lines.forEach(l => existingNames.add(l.name))

      // Add bullseyes
      const bullseyes = fullConfig.refpoints?.bullseyes || []
      bullseyes.forEach(b => {
        let name = b.name
        let counter = 1
        while (existingNames.has(name)) {
          name = `${b.name}_${counter}`
          counter++
        }
        existingNames.add(name)
        this.bullseyes.push({ name })
      })

      // Add airbases
      const airbases = fullConfig.refpoints?.airbases || []
      airbases.forEach(ab => {
        let name = ab.name
        let counter = 1
        while (existingNames.has(name)) {
          name = `${ab.name}_${counter}`
          counter++
        }
        existingNames.add(name)
        this.airbases.push({ name })
      })

      // Add zones
      const zones = fullConfig.refpoints?.zones || []
      zones.forEach(z => {
        let name = z.name
        let counter = 1
        while (existingNames.has(name)) {
          name = `${z.name}_${counter}`
          counter++
        }
        existingNames.add(name)
        this.zones.push({ name })
      })

      // Add lines
      const lines = fullConfig.refpoints?.lines || []
      lines.forEach(l => {
        let name = l.name
        let counter = 1
        while (existingNames.has(name)) {
          name = `${l.name}_${counter}`
          counter++
        }
        existingNames.add(name)
        this.lines.push({ name, startX: l.startX || 0, startY: l.startY || 0, endX: l.endX || 0, endY: l.endY || 0 })
      })
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
