import { app, BrowserWindow, ipcMain, dialog, Menu, MenuItem } from 'electron'
import path from 'path'
import fs from 'fs'
import { parseMizFile } from './mizParser.js'
import { MissionEditorValidator } from './missionValidator.js'

// Settings file for storing user preferences (including DCS path)
const SETTINGS_PATH = path.join(__dirname, '../../config/settings.json')

function loadSettings() {
  try {
    if (fs.existsSync(SETTINGS_PATH)) {
      return JSON.parse(fs.readFileSync(SETTINGS_PATH, 'utf8'))
    }
  } catch (e) {
    console.error('Failed to load settings:', e)
  }
  return {}
}

function saveSettings(settings) {
  try {
    const settingsDir = path.dirname(SETTINGS_PATH)
    if (!fs.existsSync(settingsDir)) {
      fs.mkdirSync(settingsDir, { recursive: true })
    }
    fs.writeFileSync(SETTINGS_PATH, JSON.stringify(settings, null, 2))
    return true
  } catch (e) {
    console.error('Failed to save settings:', e)
    return false
  }
}

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
      preload: path.join(__dirname, 'preload.mjs')
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
        {
          label: 'Import from .miz...',
          click: async () => {
            console.log('[MIZ Import] Menu item clicked')
            const result = await dialog.showOpenDialog(win, {
              title: 'Select DCS Mission File',
              filters: [{ name: 'DCS Mission', extensions: ['miz'] }],
              properties: ['openFile']
            })
            console.log('[MIZ Import] Dialog result:', result.canceled ? 'canceled' : 'file selected')
            if (!result.canceled && result.filePaths.length) {
              try {
                console.log('[MIZ Import] Parsing file:', result.filePaths[0])
                // Load settings to get DCS install path
                const settings = loadSettings()
                console.log('[MIZ Import] DCS path:', settings.dcsInstallPath || 'not set')
                const data = parseMizFile(result.filePaths[0], settings.dcsInstallPath)
                console.log('[MIZ Import] Sending data to renderer:', data)
                win.webContents.send('menu:miz-import', data)
              } catch (e) {
                console.error('[MIZ Import] Error:', e)
                dialog.showErrorBox('MIZ Import Error', 'Failed to parse .miz file: ' + e.message)
              }
            }
          }
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
  // Unit template loading
  ipcMain.handle('unit-template:load-all', async (event) => {
    const unitTemplatesDir = path.join(__dirname, '../../config/unit_templates')
    if (!fs.existsSync(unitTemplatesDir)) return []

    const files = fs.readdirSync(unitTemplatesDir)
    const unitTemplates = {}

    for (const file of files) {
      if (file.endsWith('.json')) {
        const content = fs.readFileSync(path.join(unitTemplatesDir, file), 'utf8')
        try {
          unitTemplates[file.replace('.json', '')] = JSON.parse(content)
        } catch (e) {
          console.error(`Error parsing unit template file ${file}:`, e)
        }
      }
    }
    return unitTemplates
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

  // Template save (legacy alias for unit-template:save)
  ipcMain.handle('unit-template:save', async (event, template, name) => {
    const unitTemplatesDir = path.join(__dirname, '../../config/unit_templates')
    if (!fs.existsSync(unitTemplatesDir)) {
      fs.mkdirSync(unitTemplatesDir, { recursive: true })
    }

    const filePath = path.join(unitTemplatesDir, `${name}.json`)
    fs.writeFileSync(filePath, JSON.stringify(template, null, 2))
    return { success: true, path: filePath }
  })

  // Legacy template save alias
  ipcMain.handle('template:save', async (event, template, name) => {
    return ipcMain.handlers['unit-template:save'](event, template, name)
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
    const unitTemplatesDir = path.join(__dirname, '../../config/unit_templates')
    const samplePath = path.join(__dirname, '../../sample-data.json')

    const hasRefpoints = fs.existsSync(refpointsPath)
    const hasUnitTemplates = fs.existsSync(unitTemplatesDir) && fs.readdirSync(unitTemplatesDir).length > 0
    const hasSample = fs.existsSync(samplePath)

    return {
      hasConfig: hasRefpoints || hasUnitTemplates,
      hasSample,
      paths: {
        refpoints: refpointsPath,
        unitTemplates: unitTemplatesDir
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

  // Load unit templates from selected file(s) - returns parsed template objects
  ipcMain.handle('unit-templates:load-from-files', async (event) => {
    const result = await dialog.showOpenDialog(win, {
      title: 'Select Unit Template File(s)',
      defaultPath: path.join(__dirname, '../../config/unit_templates'),
      filters: [
        { name: 'JSON Files', extensions: ['json'] },
        { name: 'All Files', extensions: ['*'] }
      ],
      properties: ['openFile', 'multiSelections']
    })

    if (result.canceled || !result.filePaths.length) {
      return { success: false, error: 'No file selected' }
    }

    const unitTemplates = {}
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
          unitTemplates[category] = data
        } else if (typeof data === 'object') {
          // Object format with category keys
          Object.keys(data).forEach(key => {
            if (Array.isArray(data[key])) {
              unitTemplates[key] = data[key]
            }
          })
        }
      } catch (e) {
        errors.push({ file: filePath, error: e.message })
      }
    }

    if (Object.keys(unitTemplates).length === 0 && errors.length > 0) {
      return { success: false, error: errors[0].error }
    }

    return { success: true, unitTemplates, errors }
  })

  // Legacy alias for templates:load-from-files
  ipcMain.handle('templates:load-from-files', async (event) => {
    return ipcMain.handlers['unit-templates:load-from-files'](event)
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

  // Load route templates from selected file(s)
  ipcMain.handle('route-templates:load-from-files', async (event) => {
    const result = await dialog.showOpenDialog(win, {
      title: 'Select Route Template File(s)',
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

    const routeTemplates = {}
    const errors = []

    for (const filePath of result.filePaths) {
      try {
        const content = fs.readFileSync(filePath, 'utf8')
        const data = JSON.parse(content)

        // Handle formats:
        // 1. Object with template keys: { "awacs_orbit": {...}, ... }
        // 2. Array of templates: [{ name: "...", route [...] }, ...]

        if (Array.isArray(data)) {
          // Array format - convert to object
          data.forEach(t => {
            if (t.id) routeTemplates[t.id] = t
          })
        } else if (typeof data === 'object') {
          // Object format
          Object.keys(data).forEach(key => {
            if (data[key] && data[key].route) {
              routeTemplates[key] = data[key]
            }
          })
        }
      } catch (e) {
        errors.push({ file: filePath, error: e.message })
      }
    }

    if (Object.keys(routeTemplates).length === 0 && errors.length > 0) {
      return { success: false, error: errors[0].error }
    }

    return { success: true, routeTemplates, errors }
  })

  // Clear all reference points
  ipcMain.handle('refpoints:clear', async () => {
    return { success: true }
  })

  // Clear all templates
  // Clear all unit templates
  ipcMain.handle('unit-templates:clear', async () => {
    return { success: true }
  })

  // Clear all route templates
  ipcMain.handle('route-templates:clear', async () => {
    return { success: true }
  })

  // Settings management
  ipcMain.handle('settings:load', async () => {
    return { success: true, settings: loadSettings() }
  })

  ipcMain.handle('settings:save', async (event, settings) => {
    const success = saveSettings(settings)
    return { success }
  })

  // MIZ file operations
  ipcMain.handle('miz:load-refpoints', async (event, mizPath, dcsInstallPath) => {
    try {
      const data = parseMizFile(mizPath, dcsInstallPath)
      return { success: true, data }
    } catch (e) {
      console.error('Error parsing .miz file:', e)
      return { success: false, error: e.message }
    }
  })

  ipcMain.handle('miz:import', async (event, dcsInstallPath) => {
    const result = await dialog.showOpenDialog(win, {
      title: 'Select DCS Mission File',
      defaultPath: path.join(__dirname, '../../'),
      filters: [{ name: 'DCS Mission', extensions: ['miz'] }],
      properties: ['openFile']
    })

    if (result.canceled || !result.filePaths.length) {
      return { success: false, error: 'No file selected' }
    }

    try {
      const data = parseMizFile(result.filePaths[0], dcsInstallPath)
      return { success: true, data, path: result.filePaths[0] }
    } catch (e) {
      console.error('Error parsing .miz file:', e)
      return { success: false, error: e.message }
    }
  })

  // Mission validation
  let missionValidator = null

  ipcMain.handle('validator:initialize', async (event, configPath) => {
    try {
      if (!missionValidator) {
        // Create a mock editor instance for the validator
        const mockEditor = {
          getMissionData: () => global.currentMissionData
        }
        missionValidator = new MissionEditorValidator(mockEditor)
        missionValidator.initialize(configPath)
      }
      return { success: true }
    } catch (e) {
      console.error('Validator initialization failed:', e)
      return { success: false, error: e.message }
    }
  })

  ipcMain.handle('validator:validate', async (event, dcsInstallPath) => {
    if (!missionValidator) {
      return { success: false, error: 'Validator not initialized' }
    }

    try {
      const results = await missionValidator.validate(dcsInstallPath)
      return { success: true, results }
    } catch (e) {
      console.error('Validation failed:', e)
      return { success: false, error: e.message }
    }
  })

  ipcMain.handle('validator:export', async (event, format, outputPath) => {
    if (!missionValidator) {
      return { success: false, error: 'Validator not initialized' }
    }

    try {
      const filePath = missionValidator.exportReport(format, outputPath)
      return { success: true, path: filePath }
    } catch (e) {
      console.error('Export failed:', e)
      return { success: false, error: e.message }
    }
  })

  // Store current mission data for validator access
  ipcMain.handle('mission:set-data', async (event, missionData) => {
    global.currentMissionData = missionData
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
