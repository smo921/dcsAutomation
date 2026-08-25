import { contextBridge, ipcRenderer } from 'electron'

// Set up event handlers
const eventHandlers = new Map()

// Listen for events from main process
ipcRenderer.on('menu:load-json', () => {
  if (eventHandlers.has('load-json')) {
    eventHandlers.get('load-json')()
  }
})

ipcRenderer.on('menu:export-json', () => {
  if (eventHandlers.has('export-json')) {
    eventHandlers.get('export-json')()
  }
})

ipcRenderer.on('menu:export-lua', () => {
  if (eventHandlers.has('export-lua')) {
    eventHandlers.get('export-lua')()
  }
})

// MIZ import event
ipcRenderer.on('menu:miz-import', (event, data) => {
  if (eventHandlers.has('miz-import')) {
    eventHandlers.get('miz-import')(data)
  }
})

// Expose protected methods that allow the renderer process to communicate
// with the main process without exposing the full Node.js API
contextBridge.exposeInMainWorld('api', {
  // Reference points
  refpoints: {
    load: () => ipcRenderer.invoke('refpoints:load'),
    save: (data) => ipcRenderer.invoke('refpoints:save', data),
    loadFromFile: () => ipcRenderer.invoke('refpoints:load-from-file'),
    clear: () => ipcRenderer.invoke('refpoints:clear')
  },

  // Unit templates
  unitTemplates: {
    loadAll: () => ipcRenderer.invoke('unit-template:load-all'),
    loadFromFiles: () => ipcRenderer.invoke('unit-templates:load-from-files'),
    clear: () => ipcRenderer.invoke('unit-templates:clear')
  },

  // Route templates
  routeTemplates: {
    loadFromFiles: () => ipcRenderer.invoke('route-templates:load-from-files'),
    clear: () => ipcRenderer.invoke('route-templates:clear')
  },

  // Configuration loading
  config: {
    loadJson: () => ipcRenderer.invoke('config:load-json'),
    loadSample: () => ipcRenderer.invoke('config:load-sample')
  },

  // Export
  export: {
    json: () => ipcRenderer.send('menu:export-json'),
    lua: () => ipcRenderer.send('menu:export-lua'),
    onJson: (callback) => {
      eventHandlers.set('export-json', callback)
      return () => eventHandlers.delete('export-json')
    },
    onLua: (callback) => {
      eventHandlers.set('export-lua', callback)
      return () => eventHandlers.delete('export-lua')
    },
    onLoadJson: (callback) => {
      eventHandlers.set('load-json', callback)
      return () => eventHandlers.delete('load-json')
    },
    onMizImport: (callback) => {
      eventHandlers.set('miz-import', callback)
      return () => eventHandlers.delete('miz-import')
    }
  },

  // File operations
  file: {
    saveJson: (content, suggestedName) => ipcRenderer.invoke('file:save-json', content, suggestedName),
    saveLua: (content, suggestedName) => ipcRenderer.invoke('file:save-lua', content, suggestedName)
  },

  // Templates
  template: {
    save: (template, name) => ipcRenderer.invoke('template:save', template, name)
  },

  // Settings
  settings: {
    load: () => ipcRenderer.invoke('settings:load'),
    save: (settings) => ipcRenderer.invoke('settings:save', settings)
  },

  // MIZ import
  miz: {
    import: (dcsInstallPath) => ipcRenderer.invoke('miz:import', dcsInstallPath)
  }
})
