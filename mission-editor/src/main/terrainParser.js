import fs from 'fs'
import path from 'path'

/**
 * Projection parameters for each DCS theater
 * Source: https://github.com/JonathanTurnock/dcs-projections
 * Note: Parameters may need updating as DCS updates theaters
 */
const THEATER_PROJECTIONS = {
  'Caucasus': {
    lat0: 0,
    lon0: 33,
    k0: 0.9996,
    x0: -99516.9999999732,
    y0: -4998114.999999984
  },
  'Normandy': {
    lat0: 49,
    lon0: 0,
    k0: 0.9996,
    x0: 500000,
    y0: 5400000
  },
  'PersianGulf': {
    lat0: 0,
    lon0: 54,
    k0: 0.9996,
    x0: -100000,
    y0: -2800000
  },
  'Syria': {
    lat0: 0,
    lon0: 38,
    k0: 0.9996,
    x0: -150000,
    y0: -3500000
  },
  'Nevada': {
    lat0: 0,
    lon0: -116,
    k0: 0.9996,
    x0: 200000,
    y0: 4200000
  },
  'Iraq': {
    lat0: 0,
    lon0: 44,
    k0: 0.9996,
    x0: -120000,
    y0: -3600000
  },
  'TheChannel': {
    lat0: 49.5,
    lon0: -1,
    k0: 0.9996,
    x0: 450000,
    y0: 5500000
  },
  'Sinai': {
    lat0: 0,
    lon0: 34,
    k0: 0.9996,
    x0: -100000,
    y0: -3300000
  },
  'SouthAtlantic': {
    lat0: -52,
    lon0: -59,
    k0: 0.9996,
    x0: 300000,
    y0: 4200000
  },
  'Afghanistan': {
    lat0: 0,
    lon0: 67,
    k0: 0.9996,
    x0: -200000,
    y0: -3500000
  },
  'Falklands': {
    lat0: -52,
    lon0: -59,
    k0: 0.9996,
    x0: 300000,
    y0: 4200000
  }
}

/**
 * Convert latitude/longitude to DCS world coordinates (meters)
 * Uses Transverse Mercator projection with theater-specific parameters
 *
 * @param {number} lat - Latitude in degrees
 * @param {number} lon - Longitude in degrees
 * @param {string} theater - Theater name (e.g., "Caucasus", "Normandy")
 * @returns {{x: number, y: number}} - DCS X/Y coordinates in meters
 */
function latLonToDCS(lat, lon, theater = 'Caucasus') {
  const params = THEATER_PROJECTIONS[theater] || THEATER_PROJECTIONS['Caucasus']

  const { lat0, lon0, k0, x0, y0 } = params
  const ELLIPSOID_A = 6378137.0 // WGS84 semi-major axis

  // Convert to radians
  const latRad = lat * Math.PI / 180
  const lonRad = lon * Math.PI / 180
  const lonOriginRad = lon0 * Math.PI / 180

  // Transverse Mercator forward calculation (simplified)
  const e = 0.081819190842621 // WGS84 eccentricity
  const e2 = e * e

  // Meridional arc
  const n = (1 - Math.sqrt(1 - e2)) / (1 + Math.sqrt(1 - e2))
  const A = ELLIPSOID_A * (1 - n) / (1 + n) * (1 + n*n/4 + n*n*n*n/64)

  // Coefficients for meridional arc
  const alpha = [
    A * (1 + n*n/4 + n*n*n*n/64),
    -A * (3*n/2 - 9*n*n*n/32 + 9*n*n*n*n*n/512),
    A * (15*n*n/16 - 15*n*n*n*n/256),
    -A * (35*n*n*n/48 - 175*n*n*n*n*n/3072)
  ]

  // Meridional arc length
  const M = alpha[0] * latRad +
            alpha[1] * Math.sin(2 * latRad) +
            alpha[2] * Math.sin(4 * latRad) +
            alpha[3] * Math.sin(6 * latRad)

  // Radius of curvature
  const v = ELLIPSOID_A / Math.sqrt(1 - e2 * Math.sin(latRad) * Math.sin(latRad))

  // Transverse Mercator coordinates
  const T = Math.tan(latRad) * Math.tan(latRad)
  const C = e2 / (1 - e2) * Math.cos(latRad) * Math.cos(latRad)
  const deltaLon = lonRad - lonOriginRad

  // X (easting) and Y (northing)
  const x = x0 + k0 * v * deltaLon * Math.cos(latRad) +
            k0 * v * Math.pow(deltaLon, 3) * Math.cos(latRad) * Math.cos(latRad) * Math.cos(latRad) / 6 *
            (1 - T + C)

  const y = y0 + k0 * (M +
            v * Math.tan(latRad) * deltaLon * deltaLon / 2 * Math.cos(latRad) * Math.cos(latRad) +
            v * Math.tan(latRad) * Math.pow(deltaLon, 4) / 24 * Math.cos(latRad) * Math.cos(latRad) * Math.cos(latRad) * Math.cos(latRad) *
            (5 - T + 9 * C + 4 * C * C))

  return { x, y }
}

/**
 * Parse a Lua table file and return JavaScript object
 * Handles simple key=value pairs and nested tables
 * @param {string} luaContent - Content of the Lua file
 * @param {string} theater - Theater name for coordinate conversion
 */
function parseLuaFile(luaContent, theater = 'Caucasus') {
  const result = {}

  // Remove comments
  luaContent = luaContent.replace(/--.*$/gm, '')

  // Match pattern: ["NAME"] = { lat, lon } or ["NAME"] = { latitude = X, longitude = Y }
  const entryPattern = /\["([^"]+)"\]\s*=\s*\{([^}]+)\}/g
  let match

  while ((match = entryPattern.exec(luaContent)) !== null) {
    const name = match[1]
    const content = match[2]

    // Try to extract latitude and longitude
    let lat, lon

    // Named format: latitude = X, longitude = Y
    const latMatch = content.match(/latitude\s*=\s*([-\d.]+)/)
    const lonMatch = content.match(/longitude\s*=\s*([-\d.]+)/)

    if (latMatch && lonMatch) {
      lat = parseFloat(latMatch[1])
      lon = parseFloat(lonMatch[1])
    } else {
      // Positional format: { lat, lon }
      const values = content.match(/([-\d.]+)/g)
      if (values && values.length >= 2) {
        lat = parseFloat(values[0])
        lon = parseFloat(values[1])
      }
    }

    if (lat !== undefined && lon !== undefined) {
      const coords = latLonToDCS(lat, lon, theater)
      result[name] = {
        name,
        lat,
        lon,
        x: coords.x,
        y: coords.y,
        theater
      }
    }
  }

  return result
}

/**
 * Detect theater name from directory or content
 */
function detectTheater(terrainPath) {
  const dirName = path.basename(terrainPath)
  if (THEATER_PROJECTIONS[dirName]) {
    return dirName
  }
  // Try to read entry.lua to find theater id
  const entryPath = path.join(terrainPath, 'entry.lua')
  if (fs.existsSync(entryPath)) {
    const content = fs.readFileSync(entryPath, 'utf8')
    const idMatch = content.match(/['"]id['"]\s*=\s*['"]([^'"]+)['"]/)
    if (idMatch && THEATER_PROJECTIONS[idMatch[1]]) {
      return idMatch[1]
    }
  }
  // Default to Caucasus
  return 'Caucasus'
}

/**
 * Parse DCS terrain data to extract airbase coordinates
 * @param {string} terrainName - Name of terrain (e.g., "Caucasus")
 * @param {string} dcsInstallPath - Path to DCS installation
 * @returns {Object} - Map of airbase names to coordinates
 */
function parseTerrainData(terrainName, dcsInstallPath) {
  const terrainPath = path.join(dcsInstallPath, 'Mods', 'terrains', terrainName)

  if (!fs.existsSync(terrainPath)) {
    throw new Error(`Terrain "${terrainName}" not found at ${terrainPath}`)
  }

  const theater = detectTheater(terrainPath)
  const result = {
    airbases: {},
    towns: {}
  }

  // Parse towns.lua for coordinate reference
  const townsPath = path.join(terrainPath, 'Map', 'towns.lua')
  if (fs.existsSync(townsPath)) {
    const content = fs.readFileSync(townsPath, 'utf8')
    const parsed = parseLuaFile(content, theater)
    result.towns = parsed
  }

  // Parse Radio.lua for airbase names
  const radioPath = path.join(terrainPath, 'Radio.lua')
  if (fs.existsSync(radioPath)) {
    const content = fs.readFileSync(radioPath, 'utf8')

    // Extract airbase names from Radio.lua
    // Pattern: -- AirbaseName followed by callsign data
    const airbasePattern = /--\s*([A-Za-z0-9_]+)\s*\n\s*radioId\s*=\s*'airfield(\d+)_/g
    let match

    while ((match = airbasePattern.exec(content)) !== null) {
      const airbaseName = match[1]
      const airfieldId = parseInt(match[2])

      // Try to find matching town coordinates
      // Airbase names often match town names
      const townKey = Object.keys(result.towns).find(k =>
        k.toUpperCase().includes(airbaseName.toUpperCase()) ||
        airbaseName.toUpperCase().includes(k.toUpperCase())
      )

      if (townKey && result.towns[townKey]) {
        const town = result.towns[townKey]
        result.airbases[airbaseName] = {
          name: airbaseName,
          airdromeId: airfieldId,
          lat: town.lat,
          lon: town.lon,
          x: town.x,
          y: town.y,
          theater
        }
      } else {
        // No coordinate match found
        result.airbases[airbaseName] = {
          name: airbaseName,
          airdromeId: airfieldId,
          note: 'Coordinates not found - needs manual entry'
        }
      }
    }
  }

  return result
}

export {
  latLonToDCS,
  parseLuaFile,
  parseTerrainData
}
