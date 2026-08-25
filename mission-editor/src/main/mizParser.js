import fs from 'fs'
import path from 'path'
import os from 'os'
import AdmZip from 'adm-zip'
import luadata from 'luadata'
import luaparse from 'luaparse'

/**
 * WGS84 ellipsoid constants - computed once at module load
 * NOTE: These constants are duplicated in src/renderer/src/utils/coordinateConverter.js
 * When updating, keep both files in sync.
 */
const ELLIPSOID_A = 6378137.0
const E = 0.081819190842621
const N = (1 - Math.sqrt(1 - E * E)) / (1 + Math.sqrt(1 - E * E))
const A_COEFF = ELLIPSOID_A * (1 - N) / (1 + N) * (1 + N * N / 4 + N * N * N * N / 64)
const ALPHA = [
  A_COEFF * (1 + N * N / 4 + N * N * N * N / 64),
  -A_COEFF * (3 * N / 2 - 9 * N * N * N / 32 + 9 * N * N * N * N * N / 512),
  A_COEFF * (15 * N * N / 16 - 15 * N * N * N * N / 256),
  -A_COEFF * (35 * N * N * N / 48 - 175 * N * N * N * N * N / 3072)
]

/**
 * Projection parameters for each DCS theater
 *
 * TRANSVERSE MERCATOR PROJECTION PARAMETERS:
 * - lat0: Latitude of projection center (radians in calculation)
 * - lon0: Longitude of projection center (radians in calculation)
 * - k0: Scale factor at central meridian (0.9996 standard for UTM)
 * - x0: False easting offset (meters) - DCS-specific
 * - y0: False northing offset (meters) - DCS-specific
 *
 * VERIFIED DATA:
 * - Caucasus: Derived from actual MIZ file coordinates (Batumi airbase)
 *   Validation: node tests/validate-miz-coords.js
 *
 * UNVERIFIED DATA:
 * - All other theaters: Placeholder values only (lat0/lon0 are reasonable
 *   estimates based on theater geography, but x0/y0 offsets are GUESSED)
 *
 * TO VERIFY A THEATER:
 * 1. Load a mission for that theater in DCS Mission Editor
 * 2. Place a unit at a known airbase or create F10 markpoint
 * 3. Note the DCS X/Y coordinates
 * 4. Run tests/derive-projection.js with that theater's MIZ data
 * 5. Update the parameters above with derived x0/y0 values
 *
 * See: tests/derive-projection.js for parameter derivation script
 */
const THEATER_PROJECTIONS = {
  // VERIFIED - derived from Batumi airbase coordinates in actual MIZ file
  'Caucasus': { lat0: 0, lon0: 33, k0: 0.9996, x0: -1076497, y0: -3986242 },

  // UNVERIFIED - lat0/lon0 are geographic estimates, x0/y0 are placeholders
  // Need MIZ coordinate data to derive correct x0/y0 offsets
  'Normandy': { lat0: 49, lon0: 0, k0: 0.9996, x0: 0, y0: 0 }, // TODO: verify
  'PersianGulf': { lat0: 0, lon0: 54, k0: 0.9996, x0: 0, y0: 0 }, // TODO: verify
  'Syria': { lat0: 0, lon0: 38, k0: 0.9996, x0: 0, y0: 0 }, // TODO: verify
  'Nevada': { lat0: 0, lon0: -116, k0: 0.9996, x0: 0, y0: 0 }, // TODO: verify
  'Iraq': { lat0: 0, lon0: 44, k0: 0.9996, x0: 0, y0: 0 }, // TODO: verify
  'TheChannel': { lat0: 49.5, lon0: -1, k0: 0.9996, x0: 0, y0: 0 }, // TODO: verify
  'Sinai': { lat0: 0, lon0: 34, k0: 0.9996, x0: 0, y0: 0 }, // TODO: verify
  'SouthAtlantic': { lat0: -52, lon0: -59, k0: 0.9996, x0: 0, y0: 0 }, // TODO: verify
  'Afghanistan': { lat0: 0, lon0: 67, k0: 0.9996, x0: 0, y0: 0 }, // TODO: verify
  'Falklands': { lat0: -52, lon0: -59, k0: 0.9996, x0: 0, y0: 0 }, // TODO: verify
}

/**
 * Convert latitude/longitude to DCS world coordinates (meters)
 * Uses Transverse Mercator projection with theater-specific parameters
 */
function latLonToDCS(lat, lon, theater = 'Caucasus') {
  const params = THEATER_PROJECTIONS[theater] || THEATER_PROJECTIONS['Caucasus']
  const { lat0, lon0, k0, x0, y0 } = params
  const latRad = lat * Math.PI / 180
  const lonRad = lon * Math.PI / 180
  const lonOriginRad = lon0 * Math.PI / 180
  const v = ELLIPSOID_A / Math.sqrt(1 - E * E * Math.sin(latRad) * Math.sin(latRad))
  const T = Math.tan(latRad) * Math.tan(latRad)
  const C = (E * E) / (1 - E * E) * Math.cos(latRad) * Math.cos(latRad)
  const deltaLon = lonRad - lonOriginRad
  const M = ALPHA[0] * latRad + ALPHA[1] * Math.sin(2 * latRad) + ALPHA[2] * Math.sin(4 * latRad) + ALPHA[3] * Math.sin(6 * latRad)
  const x = x0 + k0 * v * deltaLon * Math.cos(latRad) + k0 * v * Math.pow(deltaLon, 3) * Math.cos(latRad) * Math.cos(latRad) * Math.cos(latRad) / 6 * (1 - T + C)
  const y = y0 + k0 * (M + v * Math.tan(latRad) * deltaLon * deltaLon / 2 * Math.cos(latRad) * Math.cos(latRad) + v * Math.tan(latRad) * Math.pow(deltaLon, 4) / 24 * Math.cos(latRad) * Math.cos(latRad) * Math.cos(latRad) * Math.cos(latRad) * (5 - T + 9 * C + 4 * C * C))
  return { x, y }
}

// Default DCS installation path (Windows Steam)
const DEFAULT_DCS_PATH = process.platform === 'win32'
  ? 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\DCSWorld'
  : null

/**
 * Parse a .miz file (DCS mission archive) and extract reference points
 * @param {string} mizPath - Path to .miz file
 * @param {string} dcsInstallPath - Optional path to DCS installation for airbase resolution
 * @returns {Object} - { bullseyes, airbases, zones, lines, towns, allAirbases }
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

    // Strip the "mission = " wrapper - it's always at the start of DCS mission files
    const firstBrace = missionContent.indexOf('{')
    const lastBrace = missionContent.lastIndexOf('}')
    const tableContent = missionContent.substring(firstBrace, lastBrace + 1)

    // Parse using luadata library
    const parsed = luadata.serializer.unserialize(tableContent, { dictType: 'object' })

    // The parsed result is { mission: { ... } }, extract the inner table
    const missionData = parsed.mission || parsed

    // Validate that parsing succeeded - missionData should have keys
    if (!missionData || Object.keys(missionData).length === 0) {
      throw new Error('Failed to parse mission file: Lua parser returned empty result. The mission file may use unsupported syntax.')
    }

    // Detect theater from mission data - do NOT default, throw error if not found
    if (!missionData.theatre) {
      throw new Error('Failed to parse mission file: theater not found. Available keys: ' + Object.keys(missionData).join(', '))
    }
    const theater = missionData.theatre

    // Extract reference points and units from MIZ
    // Terrain-based data (allAirbases, towns) requires DCS install path
    let allAirbases = []
    let towns = {}

    if (dcsInstallPath) {
      try {
        allAirbases = getAllAirbasesFromTerrain(theater, dcsInstallPath)
        towns = getTownsFromTerrain(theater, dcsInstallPath)
      } catch (e) {
        console.warn('[MIZ Parser] Failed to load terrain data:', e.message)
        // Continue with mission-specific data only
      }
    }

    const result = {
      bullseyes: extractBullseyes(missionData),
      airbases: extractAirbases(missionData, theater, dcsInstallPath),
      zones: extractZones(missionData),
      lines: [], // Battle lines are not stored in .miz files
      // Full lists for user selection (empty if no DCS path)
      allAirbases,
      towns,
      // Units from the mission
      units: extractUnits(missionData, theater)
    }

    console.log('[MIZ Parser] Extracted from', mizPath, ':')
    console.log('[MIZ Parser] Theater:', theater)
    console.log('[MIZ Parser] Bullseyes:', result.bullseyes.length)
    console.log('[MIZ Parser] Airbases (used in mission):', result.airbases.length)
    console.log('[MIZ Parser] Zones:', result.zones.length)
    console.log('[MIZ Parser] All Airbases (from terrain):', result.allAirbases.length)
    console.log('[MIZ Parser] Towns (from terrain):', Object.keys(result.towns).length)
    console.log('[MIZ Parser] Units:', result.units.length)

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
 * Extract bullseye coordinates from parsed mission data
 */
function extractBullseyes(parsed) {
  const bullseyes = []

  // DCS uses both 'coalition' (singular) and 'coalitions' (plural) in different versions
  // Check both locations
  const coalitionData = parsed.coalition || parsed.coalitions

  if (coalitionData) {
    const coalitionNames = ['blue', 'red', 'neutrals']
    for (const coalition of coalitionNames) {
      if (coalitionData[coalition] && coalitionData[coalition].bullseye) {
        const bullseye = coalitionData[coalition].bullseye
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
 * Find all airdromeId references in the mission data
 */
function findAirdromeIds(obj, airdromeIds = new Set()) {
  if (!obj || typeof obj !== 'object') return airdromeIds
  if (Array.isArray(obj)) {
    obj.forEach(item => findAirdromeIds(item, airdromeIds))
    return airdromeIds
  }
  if (obj.airdromeId !== undefined) {
    airdromeIds.add(obj.airdromeId)
  }
  Object.values(obj).forEach(v => {
    if (typeof v === 'object') findAirdromeIds(v, airdromeIds)
  })
  return airdromeIds
}

/**
 * Extract unit coordinates from MIZ for fallback resolution
 */
function extractAirdromeCoordsFromMIZ(obj, coordsMap = {}) {
  if (!obj || typeof obj !== 'object') return coordsMap
  if (Array.isArray(obj)) {
    obj.forEach(item => extractAirdromeCoordsFromMIZ(item, coordsMap))
    return coordsMap
  }
  if (obj.action === 'Land' && obj.airdromeId !== undefined && obj.x && obj.y) {
    coordsMap[obj.airdromeId] = { x: obj.x, y: obj.y }
  }
  Object.values(obj).forEach(v => {
    if (typeof v === 'object') extractAirdromeCoordsFromMIZ(v, coordsMap)
  })
  return coordsMap
}

/**
 * Resolve airdromeId to airbase data using terrain lookup or MIZ fallback
 */
function resolveAirbaseById(airdromeId, allAirbases, mizCoords) {
  const terrainMatch = allAirbases.find(ab => ab.airdromeId === airdromeId)
  if (terrainMatch && terrainMatch.x && terrainMatch.y) {
    return {
      name: terrainMatch.name,
      x: terrainMatch.x,
      y: terrainMatch.y,
      airdromeId,
      source: 'DCS terrain data'
    }
  }
  const mizMatch = mizCoords[airdromeId]
  if (mizMatch) {
    return {
      airdromeId,
      x: mizMatch.x,
      y: mizMatch.y,
      source: 'MIZ unit coords',
      note: 'Airbase name not resolved, using MIZ coordinates'
    }
  }
  return { airdromeId, note: 'Could not resolve coordinates' }
}

/**
 * Extract airbases from parsed mission data (only those used in the mission)
 * If DCS installation is available, resolves airdromeId to names and coordinates
 * @param {Object} parsed - Parsed mission data
 * @param {string} theater - Theater name (e.g., "Caucasus")
 * @param {string} dcsInstallPath - Optional path to DCS installation
 * @returns {Array} - Array of airbase objects
 */
function extractAirbases(parsed, theater = 'Caucasus', dcsInstallPath = null) {
  const airdromeIds = findAirdromeIds(parsed)
  const mizCoords = extractAirdromeCoordsFromMIZ(parsed)

  // Without DCS installation, return IDs or MIZ coords only
  if (!dcsInstallPath) {
    return Array.from(airdromeIds).map(id => {
      const mizMatch = mizCoords[id]
      return mizMatch
        ? { airdromeId: id, x: mizMatch.x, y: mizMatch.y, note: 'Coordinates from MIZ' }
        : { airdromeId: id, note: 'Requires DCS installation path' }
    })
  }

  try {
    const allAirbases = getAllAirbasesFromTerrain(theater, dcsInstallPath)
    return Array.from(airdromeIds)
      .map(id => resolveAirbaseById(id, allAirbases, mizCoords))
      .filter(ab => ab.name || ab.x)
  } catch (e) {
    console.error('Failed to resolve airbases from terrain data:', e.message)
    return Array.from(airdromeIds).map(id => ({ airdromeId: id, note: 'Resolution failed' }))
  }
}

/**
 * Parse Radio.lua to extract airbase names and airdromeIds
 */
function parseRadioFile(radioPath) {
  const content = fs.readFileSync(radioPath, 'utf8')
  const ast = luaparse.parse(content, { comments: true, locations: true })

  const radioTable = ast.body.find(
    stmt => stmt.type === 'AssignmentStatement' &&
            stmt.variables?.[0]?.name === 'radio'
  )?.init?.[0]

  const airbases = []
  if (!radioTable || radioTable.type !== 'TableConstructorExpression') {
    return airbases
  }

  // Build comment map by line number
  const commentByLine = {}
  ast.comments?.forEach(c => {
    if (c.type === 'Comment' && c.raw.startsWith('-- ') && c.loc?.start?.line) {
      commentByLine[c.loc.start.line] = c.raw.replace(/^--\s*/, '').trim()
    }
  })

  for (const field of radioTable.fields) {
    if (field.type !== 'TableValue' || field.value?.type !== 'TableConstructorExpression') {
      continue
    }
    const entry = field.value
    let airbaseName = null
    let airdromeId = null

    // Find comment inside entry by line number
    const entryStartLine = entry.loc?.start?.line
    const entryEndLine = entry.loc?.end?.line
    if (entryStartLine && entryEndLine) {
      for (let line = entryStartLine; line <= entryEndLine; line++) {
        if (commentByLine[line]) {
          airbaseName = commentByLine[line]
          break
        }
      }
    }

    // Find radioId = 'airfieldXX_0'
    for (const entryField of entry.fields) {
      if (entryField.type === 'TableKeyString' && entryField.key?.name === 'radioId') {
        const value = entryField.value
        if (value?.type === 'StringLiteral' && value?.raw) {
          const match = value.raw.match(/airfield(\d+)_/)
          if (match) airdromeId = parseInt(match[1])
        }
      }
    }

    if (airbaseName && airdromeId) {
      airbases.push({ name: airbaseName, airdromeId })
    }
  }

  return airbases
}

/**
 * Parse towns.lua to extract town coordinates
 */
function parseTownsFile(townsPath) {
  let content = fs.readFileSync(townsPath, 'utf8')
  const townsStart = content.indexOf('towns = {')
  if (townsStart !== -1) {
    content = content.substring(townsStart + 'towns = '.length)
  }
  // Fix _() gettext calls
  content = content.replace(/display_name\s*=\s*_\(\s*"([^"]+)"\s*\)/g, 'display_name = "$1"')
  return luadata.serializer.unserialize(content, { dictType: 'object' })
}

/**
 * Match airbase name to town by exact or contains comparison
 */
function matchAirbaseToTown(airbaseName, towns) {
  const normalized = airbaseName.toUpperCase().replace(/[^A-Z0-9']/g, '')
  for (const [townName, townData] of Object.entries(towns)) {
    const normalizedTown = townName.toUpperCase().replace(/[^A-Z0-9']/g, '')
    if (normalizedTown === normalized || normalizedTown.includes(normalized) || normalized.includes(normalizedTown)) {
      return { name: townName, data: townData }
    }
  }
  return null
}

/**
 * Build path to terrain file
 */
function getTerrainFilePath(dcsInstallPath, theater, ...segments) {
  if (!dcsInstallPath) throw new Error('DCS installation path required')
  if (!theater) throw new Error('Theater name required')
  return path.join(dcsInstallPath, 'Mods', 'terrains', theater, ...segments)
}

/**
 * Get all airbases from terrain data (Radio.lua + towns.lua matching)
 * Uses hybrid parsing: luaparse for Radio.lua, luadata for towns.lua
 * @param {string} theater - Theater name
 * @param {string} dcsInstallPath - Path to DCS installation
 * @returns {Array} - Array of all airbases with coordinates
 */
function getAllAirbasesFromTerrain(theater, dcsInstallPath) {
  const radioPath = getTerrainFilePath(dcsInstallPath, theater, 'Radio.lua')
  const townsPath = getTerrainFilePath(dcsInstallPath, theater, 'Map', 'towns.lua')

  if (!fs.existsSync(radioPath)) throw new Error(`Radio.lua not found at ${radioPath}`)
  if (!fs.existsSync(townsPath)) throw new Error(`towns.lua not found at ${townsPath}`)

  const airbases = parseRadioFile(radioPath)
  const towns = parseTownsFile(townsPath)

  return airbases.map(ab => {
    const match = matchAirbaseToTown(ab.name, towns)
    if (match) {
      const coords = latLonToDCS(match.data.latitude, match.data.longitude, theater)
      return {
        name: ab.name,
        airdromeId: ab.airdromeId,
        lat: match.data.latitude,
        lon: match.data.longitude,
        x: coords.x,
        y: coords.y,
        matchedTown: match.name,
        source: 'terrain'
      }
    }
    return {
      name: ab.name,
      airdromeId: ab.airdromeId,
      note: 'No matching town found',
      source: 'terrain'
    }
  })
}

/**
 * Get all towns from terrain data
 * @param {string} theater - Theater name
 * @param {string} dcsInstallPath - Path to DCS installation
 * @returns {Object} - Map of town names to coordinates
 */
function getTownsFromTerrain(theater, dcsInstallPath) {
  const townsPath = getTerrainFilePath(dcsInstallPath, theater, 'Map', 'towns.lua')
  if (!fs.existsSync(townsPath)) throw new Error(`towns.lua not found at ${townsPath}`)
  return parseTownsFile(townsPath)
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

/**
 * Extract all units/groups from the mission
 * @param {Object} missionData - Parsed mission data
 * @param {string} theater - Theater name for coordinate calculations
 * @returns {Array} - Array of unit objects with full configuration
 */
function extractUnits(missionData, theater = 'Caucasus') {
  const units = []

  // DCS mission structure:
  // coalitions: { blue: [countryIds], red: [countryIds], ... }
  // Then under each coalition: { country: [{id, name, plane/ground/ship/helicopter}] }
  const coalitionSections = missionData.blue || missionData.red || missionData.neutrals
  const coalitionKeys = ['blue', 'red', 'neutrals']
  const coalitionDisplay = { blue: 'Blue', red: 'Red', neutrals: 'Neutrals' }

  for (const coalitionKey of coalitionKeys) {
    // Check if this coalition exists in the mission
    const coalitionData = missionData[coalitionKey]
    if (!coalitionData) continue

    // Get country array from coalition (e.g., coalitionData.country = [{id, name, plane...}])
    const countries = coalitionData.country || []
    if (!Array.isArray(countries)) continue

    for (const country of countries) {
      const countryName = country.name || 'Unknown'
      const countryId = country.id

      // Extract different unit types: plane, ground, ship, helicopter
      const unitTypes = ['plane', 'ground', 'ship', 'helicopter']

      for (const unitType of unitTypes) {
        const unitsInType = country[unitType]
        if (!unitsInType) continue

        // Check for groups array
        const groups = unitsInType.group || []
        if (!Array.isArray(groups)) continue

        for (const group of groups) {
          const unit = {
            id: group.name || `unit_${units.length}`,
            name: group.name || `Unnamed ${unitType}`,
            type: unitType,
            coalition: coalitionDisplay[coalitionKey],
            country: countryName,
            countryId,
            task: group.task || null,
            units: [],
            route: []
          }

          // Extract individual units in the group
          if (group.units && Array.isArray(group.units)) {
            for (const u of group.units) {
              unit.units.push({
                name: u.name || '',
                type: u.type || '',
                skill: u.skill || 'Average',
                x: u.x,
                y: u.y,
                heading: u.heading || 0
              })
            }
          }

          // Extract route points
          if (group.route?.points && Array.isArray(group.route.points)) {
            for (const point of group.route.points) {
              unit.route.push({
                x: point.x,
                y: point.y,
                alt: point.alt,
                alt_type: point.alt_type,
                action: point.action,
                speed: point.speed,
                type: point.type
              })
            }
          }

          // Use first unit's position as group position
          if (unit.units.length > 0 && unit.units[0].x && unit.units[0].y) {
            unit.x = unit.units[0].x
            unit.y = unit.units[0].y
          }

          units.push(unit)
        }
      }
    }
  }

  return units
}

export {
  parseMizFile,
  extractBullseyes,
  extractAirbases,
  extractZones,
  extractUnits,
  getAllAirbasesFromTerrain,
  getTownsFromTerrain,
  latLonToDCS,
  THEATER_PROJECTIONS
}
