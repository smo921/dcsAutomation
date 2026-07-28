import fs from 'fs'
import path from 'path'
import os from 'os'
import AdmZip from 'adm-zip'
import { parseTerrainData, latLonToDCS } from './terrainParser'

// Default DCS installation path (Windows Steam)
const DEFAULT_DCS_PATH = process.platform === 'win32'
  ? 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\DCSWorld'
  : null

/**
 * Parse a .miz file (DCS mission archive) and extract reference points
 * @param {string} mizPath - Path to .miz file
 * @param {string} dcsInstallPath - Optional path to DCS installation for airbase resolution
 * @returns {Object} - { bullseyes, airbases, zones, lines }
 */
function parseMizFile(mizPath, dcsInstallPath = null) {
  // Use default DCS path if not provided
  if (!dcsInstallPath && DEFAULT_DCS_PATH) {
    dcsInstallPath = DEFAULT_DCS_PATH
  }

  // Create temp directory for extraction
  const tempDir = path.join(os.tmpdir(), 'miz-extract-' + Date.now())
  fs.mkdirSync(tempDir, { recursive: true })

  try {
    // Extract .miz file using adm-zip (native Node.js, no external processes)
    const zip = new AdmZip(mizPath)

    // Extract all contents to temp directory
    zip.extractAllTo(tempDir, true)

    // Read the mission file
    const missionPath = path.join(tempDir, 'mission')
    if (!fs.existsSync(missionPath)) {
      throw new Error('Mission file not found in .miz archive')
    }

    const missionContent = fs.readFileSync(missionPath, 'utf8')
    const parsed = parseLuaTable(missionContent)

    // Detect theater from mission data
    const theater = parsed.theatre || 'Caucasus'

    // Extract reference points
    const result = {
      bullseyes: extractBullseyes(parsed),
      airbases: extractAirbases(parsed, theater, dcsInstallPath),
      zones: extractZones(parsed),
      lines: [] // Battle lines are not stored in .miz files
    }

    return result
  } catch (err) {
    // Handle corrupted or invalid ZIP files with user-friendly messages
    if (/corrupt|invalid|empty/i.test(err.message)) {
      throw new Error('Mission file is corrupted or empty')
    }
    if (/no such file/i.test(err.message)) {
      throw new Error('Mission file not found')
    }
    // Re-throw other errors with original message
    throw err
  } finally {
    // Cleanup temp directory
    try {
      fs.rmSync(tempDir, { recursive: true, force: true })
    } catch (e) {
      console.error('Failed to cleanup temp directory:', e)
    }
  }
}

/**
 * Parse Lua table syntax to JavaScript object
 * This is a simplified parser that handles DCS mission file format
 */
function parseLuaTable(luaString) {
  const result = {}

  // Helper to parse nested tables
  function parseValue(valueStr) {
    valueStr = valueStr.trim()

    // Handle nil
    if (valueStr === 'nil') return null

    // Handle numbers
    if (/^-?\d+\.?\d*$/.test(valueStr)) {
      return parseFloat(valueStr)
    }

    // Handle strings
    const stringMatch = valueStr.match(/^"([^"]*)"$/)
    if (stringMatch) return stringMatch[1]

    // Handle booleans
    if (valueStr === 'true') return true
    if (valueStr === 'false') return false

    // Handle tables (recursive)
    if (valueStr.startsWith('{') && valueStr.endsWith('}')) {
      return parseLuaTable(valueStr.slice(1, -1))
    }

    return valueStr
  }

  // Tokenize the content
  let depth = 0
  let current = ''
  const entries = []
  let inString = false
  let inComment = false

  for (let i = 0; i < luaString.length; i++) {
    const char = luaString[i]
    const nextChar = luaString[i + 1]

    // Handle comments
    if (char === '-' && nextChar === '-') {
      inComment = true
      continue
    }
    if (inComment && char === '\n') {
      inComment = false
      continue
    }
    if (inComment) continue

    // Handle strings
    if (char === '"') {
      inString = !inString
      current += char
      continue
    }
    if (inString) {
      current += char
      continue
    }

    // Handle brackets
    if (char === '[' || char === '{') {
      depth++
      current += char
    } else if (char === ']' || char === '}') {
      depth--
      current += char
      if (depth === 0 && current.trim()) {
        entries.push(current.trim())
        current = ''
      }
    } else if (char === ',' && depth === 0) {
      if (current.trim()) {
        entries.push(current.trim())
      }
      current = ''
    } else {
      current += char
    }
  }

  if (current.trim()) {
    entries.push(current.trim())
  }

  // Parse entries
  for (const entry of entries) {
    // Handle key-value pairs: ["key"] = value or key = value
    const kvMatch = entry.match(/^\[?"([^"]+)"\]?\s*=\s*(.+)$/s)
    if (kvMatch) {
      const key = kvMatch[1]
      const value = parseValue(kvMatch[2])
      result[key] = value
    }
    // Handle array indices: [1] = value
    const arrayMatch = entry.match(/^\[(\d+)\]\s*=\s*(.+)$/s)
    if (arrayMatch) {
      const index = parseInt(arrayMatch[1])
      const value = parseValue(arrayMatch[2])
      result[index] = value
    }
  }

  return result
}

/**
 * Extract bullseye coordinates from parsed mission data
 */
function extractBullseyes(parsed) {
  const bullseyes = []

  if (parsed.coalitions) {
    const coalitions = ['blue', 'red', 'neutrals']
    for (const coalition of coalitions) {
      if (parsed.coalitions[coalition] && parsed.coalitions[coalition].bullseye) {
        const bullseye = parsed.coalitions[coalition].bullseye
        if (bullseye.x !== undefined && bullseye.y !== undefined) {
          bullseyes.push({
            name: coalition.charAt(0).toUpperCase() + coalition.slice(1),
            x: bullseye.x,
            y: bullseye.y
          })
        }
      }
    }
  }

  return bullseyes
}

/**
 * Extract airbases from parsed mission data
 * If DCS installation is available, resolves airdromeId to names and coordinates
 * @param {Object} parsed - Parsed mission data
 * @param {string} theater - Theater name (e.g., "Caucasus")
 * @param {string} dcsInstallPath - Optional path to DCS installation
 * @returns {Array} - Array of airbase objects
 */
function extractAirbases(parsed, theater = 'Caucasus', dcsInstallPath = null) {
  const airdromeIds = new Set()

  // Find all airdromeId references in the mission
  function searchForAirdromes(obj) {
    if (!obj || typeof obj !== 'object') return

    if (Array.isArray(obj)) {
      obj.forEach(item => searchForAirdromes(item))
      return
    }

    // Check for airdromeId in route points (action = "Land")
    if (obj.action === 'Land' && obj.airdromeId !== undefined) {
      airdromeIds.add(obj.airdromeId)
    }

    // Check for airdromeId in any object
    if (obj.airdromeId !== undefined) {
      airdromeIds.add(obj.airdromeId)
    }

    // Recurse into nested objects
    for (const [key, value] of Object.entries(obj)) {
      if (typeof value === 'object' && value !== null) {
        searchForAirdromes(value)
      }
    }
  }

  searchForAirdromes(parsed)

  // If DCS installation is available, resolve airbase names and coordinates
  if (dcsInstallPath) {
    try {
      const terrainData = parseTerrainData(theater, dcsInstallPath)
      const airbasesByName = {}

      // Build lookup by airdromeId
      Object.values(terrainData.airbases).forEach(ab => {
        if (ab.airdromeId) {
          airbasesByName[ab.airdromeId] = ab
        }
      })

      // Resolve each airdromeId to full data
      return Array.from(airdromeIds).map(id => {
        const resolved = airbasesByName[id]
        if (resolved && resolved.x && resolved.y) {
          return {
            name: resolved.name,
            x: resolved.x,
            y: resolved.y,
            airdromeId: id,
            source: 'DCS terrain data'
          }
        }
        return {
          airdromeId: id,
          note: 'Could not resolve coordinates'
        }
      }).filter(ab => ab.name) // Only return resolved airbases
    } catch (e) {
      console.error('Failed to resolve airbases from terrain data:', e.message)
    }
  }

  // Without DCS installation, return just the IDs
  return Array.from(airdromeIds).map(id => ({
    airdromeId: id,
    note: 'Airbase name/coordinates require DCS installation path'
  }))
}

/**
 * Extract trigger zones from parsed mission data
 */
function extractZones(parsed) {
  const zones = []

  if (parsed.triggers && parsed.triggers.zones) {
    const zonesData = parsed.triggers.zones
    // Zones can be array or object with numeric keys
    const zoneArray = Array.isArray(zonesData)
      ? zonesData
      : Object.values(zonesData).filter(z => typeof z === 'object')

    for (const zone of zoneArray) {
      if (zone.name && zone.x !== undefined && zone.y !== undefined) {
        zones.push({
          name: zone.name,
          x: zone.x,
          y: zone.y,
          radius: zone.radius || 5000
        })
      }
    }
  }

  return zones
}

export {
  parseMizFile,
  parseLuaTable,
  extractBullseyes,
  extractAirbases,
  extractZones
}
