const { contextBridge, ipcRenderer } = require('electron')

// Expose protected methods that allow the renderer process to communicate
// with the main process without exposing the full Node.js API
contextBridge.exposeInMainWorld('api', {
  // Reference points
  refpoints: {
    load: () => ipcRenderer.invoke('refpoints:load'),
    save: (data) => ipcRenderer.invoke('refpoints:save', data)
  },

  // Templates
  templates: {
    loadAll: () => ipcRenderer.invoke('template:load-all')
  },

  // Configuration loading
  config: {
    loadJson: (filePath) => ipcRenderer.invoke('config:load-json', filePath),
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
