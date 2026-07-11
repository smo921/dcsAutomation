const { app, BrowserWindow, ipcMain, dialog, Menu, MenuItem } = require('electron')
const path = require('path')
const fs = require('fs')

let win = null
const isDev = process.env.NODE_ENV === 'development'

function createWindow () {
  win = new BrowserWindow({
    width: 1400,
    height: 900,
    minHeight: 800,
    minWidth: 1200,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    },
    backgroundColor: '#1e1e1e',
    autoHideMenuBar: true
  })

  win.loadURL(
    isDev
      ? 'http://localhost:5173'
      : `file://${path.join(__dirname, '../../out/renderer/index.html')}`
  )

  if (isDev) {
    win.webContents.openDevTools()
  }

  // Create application menu
  const menu = Menu.buildFromTemplate([
    {
      label: 'File',
      submenu: [
        {
          label: 'Export JSON',
          click: () => win.webContents.send('menu:export-json')
        },
        {
          label: 'Export Lua',
          click: () => win.webContents.send('menu:export-lua')
        },
        { type: 'separator' },
        {
          label: 'Load JSON...',
          click: () => win.webContents.send('menu:load-json')
        },
        { type: 'separator' },
        { role: 'quit' }
      ]
    },
    {
      label: 'Edit',
      submenu: [
        { role: 'undo' },
        { role: 'redo' },
        { type: 'separator' },
        { role: 'cut' },
        { role: 'copy' },
        { role: 'paste' },
        { type: 'separator' },
        { role: 'selectAll' }
      ]
    },
    {
      label: 'View',
      submenu: [
        { role: 'reload' },
        { role: 'forceReload' },
        { role: 'toggleDevTools' },
        { type: 'separator' },
        { role: 'resetZoom' },
        { role: 'zoomIn' },
        { role: 'zoomOut' },
        { type: 'separator' },
        { role: 'toggleFullScreen' }
      ]
    }
  ])
  Menu.setApplicationMenu(menu)
}

function registerIpcHandlers () {
  // Template loading
  ipcMain.handle('template:load-all', async (event) => {
    const templatesDir = path.join(__dirname, '../../config/templates')
    if (!fs.existsSync(templatesDir)) return []

    const files = fs.readdirSync(templatesDir)
    const templates = {}

    for (const file of files) {
      if (file.endsWith('.json')) {
        const content = fs.readFileSync(path.join(templatesDir, file), 'utf8')
        try {
          templates[file.replace('.json', '')] = JSON.parse(content)
        } catch (e) {
          console.error(`Error parsing template file ${file}:`, e)
        }
      }
    }
    return templates
  })

  // Reference points
  ipcMain.handle('refpoints:load', async () => {
    const refpointsPath = path.join(__dirname, '../../config/refpoints.json')
    if (!fs.existsSync(refpointsPath)) return { bullseyes: [], airbases: [], zones: [], lines: [] }
    return JSON.parse(fs.readFileSync(refpointsPath, 'utf8'))
  })

  ipcMain.handle('refpoints:save', async (event, data) => {
    const refpointsPath = path.join(__dirname, '../../config/refpoints.json')
    fs.writeFileSync(refpointsPath, JSON.stringify(data, null, 2))
    return true
  })

  // File operations
  ipcMain.handle('file:save-json', async (event, content, suggestedName) => {
    const result = await dialog.showSaveDialog(win, {
      title: 'Save Configuration',
      defaultPath: suggestedName || 'mission-config.json',
      filters: [{ name: 'JSON', extensions: ['json'] }]
    })

    if (!result.canceled && result.filePath) {
      fs.writeFileSync(result.filePath, content)
      return { success: true, path: result.filePath }
    }
    return { success: false }
  })

  ipcMain.handle('file:save-lua', async (event, content, suggestedName) => {
    const result = await dialog.showSaveDialog(win, {
      title: 'Save Lua Configuration',
      defaultPath: suggestedName || 'mission-config.lua',
      filters: [{ name: 'Lua', extensions: ['lua'] }]
    })

    if (!result.canceled && result.filePath) {
      fs.writeFileSync(result.filePath, content)
      return { success: true, path: result.filePath }
    }
    return { success: false }
  })

  // Template save
  ipcMain.handle('template:save', async (event, template, name) => {
    const templatesDir = path.join(__dirname, '../../config/templates')
    if (!fs.existsSync(templatesDir)) {
      fs.mkdirSync(templatesDir, { recursive: true })
    }

    const filePath = path.join(templatesDir, `${name}.json`)
    fs.writeFileSync(filePath, JSON.stringify(template, null, 2))
    return { success: true, path: filePath }
  })

  // Load JSON configuration from a selected file
  ipcMain.handle('config:load-json', async (event) => {
    const result = await dialog.showOpenDialog(win, {
      title: 'Load Configuration',
      defaultPath: path.join(__dirname, '../../config'),
      filters: [
        { name: 'JSON Files', extensions: ['json'] },
        { name: 'All Files', extensions: ['*'] }
      ],
      properties: ['openFile']
    })

    if (result.canceled || !result.filePaths.length) {
      return { success: false, error: 'No file selected' }
    }

    const filePath = result.filePaths[0]
    try {
      const content = fs.readFileSync(filePath, 'utf8')
      const config = JSON.parse(content)
      return { success: true, config: config }
    } catch (e) {
      return { success: false, error: e.message }
    }
  })

  // Check if config files exist
  ipcMain.handle('config:check', async () => {
    const refpointsPath = path.join(__dirname, '../../config/refpoints.json')
    const templatesDir = path.join(__dirname, '../../config/templates')
    const samplePath = path.join(__dirname, '../../sample-data.json')

    const hasRefpoints = fs.existsSync(refpointsPath)
    const hasTemplates = fs.existsSync(templatesDir) && fs.readdirSync(templatesDir).length > 0
    const hasSample = fs.existsSync(samplePath)

    return {
      hasConfig: hasRefpoints || hasTemplates,
      hasSample,
      paths: {
        refpoints: refpointsPath,
        templates: templatesDir
      }
    }
  })

  // Load sample configuration
  ipcMain.handle('config:load-sample', async () => {
    const samplePath = path.join(__dirname, '../../sample-data.json')
    if (!fs.existsSync(samplePath)) {
      return { success: false, error: 'Sample file not found' }
    }
    try {
      const content = fs.readFileSync(samplePath, 'utf8')
      const config = JSON.parse(content)
      return { success: true, config: config }
    } catch (e) {
      return { success: false, error: e.message }
    }
  })

  // Load templates from selected file(s) - returns parsed template objects
  ipcMain.handle('templates:load-from-files', async (event) => {
    const result = await dialog.showOpenDialog(win, {
      title: 'Select Template File(s)',
      defaultPath: path.join(__dirname, '../../config/templates'),
      filters: [
        { name: 'JSON Files', extensions: ['json'] },
        { name: 'All Files', extensions: ['*'] }
      ],
      properties: ['openFile', 'multiSelections']
    })

    if (result.canceled || !result.filePaths.length) {
      return { success: false, error: 'No file selected' }
    }

    const templates = {}
    const errors = []

    for (const filePath of result.filePaths) {
      try {
        const content = fs.readFileSync(filePath, 'utf8')
        const data = JSON.parse(content)

        // Handle two formats:
        // 1. Array of templates: [{}, {}]
        // 2. Object with category keys: { air_templates: [], ground_templates: [] }

        if (Array.isArray(data)) {
          // Simple array format - infer category from filename
          const category = path.basename(filePath, '.json').replace('_templates', '').replace('_templates', '')
          templates[category] = data
        } else if (typeof data === 'object') {
          // Object format with category keys
          Object.keys(data).forEach(key => {
            if (Array.isArray(data[key])) {
              templates[key] = data[key]
            }
          })
        }
      } catch (e) {
        errors.push({ file: filePath, error: e.message })
      }
    }

    if (Object.keys(templates).length === 0 && errors.length > 0) {
      return { success: false, error: errors[0].error }
    }

    return { success: true, templates, errors }
  })

  // Load reference points from selected file
  ipcMain.handle('refpoints:load-from-file', async (event) => {
    const result = await dialog.showOpenDialog(win, {
      title: 'Select Reference Points File',
      defaultPath: path.join(__dirname, '../../config'),
      filters: [
        { name: 'JSON Files', extensions: ['json'] },
        { name: 'All Files', extensions: ['*'] }
      ],
      properties: ['openFile']
    })

    if (result.canceled || !result.filePaths.length) {
      return { success: false, error: 'No file selected' }
    }

    const filePath = result.filePaths[0]
    try {
      const content = fs.readFileSync(filePath, 'utf8')
      const data = JSON.parse(content)

      // Extract refpoints from various possible formats
      let refpoints = null
      if (data.refpoints) {
        refpoints = data.refpoints
      } else if (Array.isArray(data)) {
        // If data is an array, assume it's bullseyes
        refpoints = { bullseyes: data, airbases: [], zones: [], lines: [] }
      } else {
        // Try to build from keys
        refpoints = {
          bullseyes: data.bullseyes || [],
          airbases: data.airbases || [],
          zones: data.zones || [],
          lines: data.lines || []
        }
      }

      return { success: true, refpoints }
    } catch (e) {
      return { success: false, error: e.message }
    }
  })

  // Load waypoint templates from selected file(s)
  ipcMain.handle('waypoint-templates:load-from-files', async (event) => {
    const result = await dialog.showOpenDialog(win, {
      title: 'Select Waypoint Template File(s)',
      defaultPath: path.join(__dirname, '../../config'),
      filters: [
        { name: 'JSON Files', extensions: ['json'] },
        { name: 'All Files', extensions: ['*'] }
      ],
      properties: ['openFile', 'multiSelections']
    })

    if (result.canceled || !result.filePaths.length) {
      return { success: false, error: 'No file selected' }
    }

    const waypointTemplates = {}
    const errors = []

    for (const filePath of result.filePaths) {
      try {
        const content = fs.readFileSync(filePath, 'utf8')
        const data = JSON.parse(content)

        // Handle formats:
        // 1. Object with template keys: { "awacs_orbit": {...}, ... }
        // 2. Array of templates: [{ id: "...", name: "...", waypoints: [...] }, ...]

        if (Array.isArray(data)) {
          // Array format - convert to object
          data.forEach(t => {
            if (t.id) waypointTemplates[t.id] = t
          })
        } else if (typeof data === 'object') {
          // Object format
          Object.keys(data).forEach(key => {
            if (data[key] && data[key].waypoints) {
              waypointTemplates[key] = data[key]
            }
          })
        }
      } catch (e) {
        errors.push({ file: filePath, error: e.message })
      }
    }

    if (Object.keys(waypointTemplates).length === 0 && errors.length > 0) {
      return { success: false, error: errors[0].error }
    }

    return { success: true, waypointTemplates, errors }
  })

  // Clear all reference points
  ipcMain.handle('refpoints:clear', async () => {
    return { success: true }
  })

  // Clear all templates
  ipcMain.handle('templates:clear', async () => {
    return { success: true }
  })
}

app.whenReady().then(() => {
  createWindow()
  registerIpcHandlers()

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow()
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})

app.on('quit', () => {
  win = null
})
