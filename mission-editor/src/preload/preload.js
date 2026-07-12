const { contextBridge, ipcRenderer } = require('electron')

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
    lua: () => ipcRenderer.send('menu:export-lua')
  },

  // File operations
  file: {
    saveJson: (content, suggestedName) => ipcRenderer.invoke('file:save-json', content, suggestedName),
    saveLua: (content, suggestedName) => ipcRenderer.invoke('file:save-lua', content, suggestedName)
  },

  // Templates
  template: {
    save: (template, name) => ipcRenderer.invoke('template:save', template, name)
  }
})
