#!/usr/bin/env node

/**
 * Derive projection parameters for ANY DCS theater
 *
 * Usage:
 *   1. Copy a .miz file for the theater you want to calibrate to miz-temp/
 *   2. Extract it: unzip mission.miz -o -d miz-temp/
 *   3. Run: node tests/derive-projection-all.js
 *
 * This script finds ALL units placed at airbases in the MIZ and calculates
 * the projection offset needed to match lat/lon → DCS X/Y
 */

import { readFileSync, writeFileSync } from 'fs'
import { unzipSync } from 'zlib'
import AdmZip from 'adm-zip'
import luadata from 'luadata'
import path from 'path'

const MIZ_TEMP = 'C:\\Users\\steph\\DCS Scripts\\automatic\\miz-temp'
const DCS_PATH = 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\DCSWorld'

// Read mission file
const missionContent = readFileSync(MIZ_TEMP + '/mission', 'utf8')
const firstBrace = missionContent.indexOf('{')
const lastBrace = missionContent.lastIndexOf('}')
const tableContent = missionContent.substring(firstBrace, lastBrace + 1)
const mission = luadata.serializer.unserialize(tableContent, { dictType: 'object' })
const missionData = mission.mission || mission

const theater = missionData.theatre
console.log('='.repeat(70))
console.log(`Projection Derivation for: ${theater}`)
console.log('='.repeat(70))

// Find all units at airbases (have airdromeId + coordinates)
const airdromeUnits = []

function search(obj, depth = 0) {
  if (!obj || typeof obj !== 'object' || depth > 50) return
  if (Array.isArray(obj)) {
    obj.forEach(item => search(item, depth + 1))
    return
  }
  if (obj.airdromeId !== undefined && obj.x !== undefined && obj.y !== undefined) {
    airdromeUnits.push({
      airdromeId: obj.airdromeId,
      x: obj.x,
      y: obj.y,
      unitName: obj.name
    })
  }
  Object.values(obj).forEach(v => {
    if (typeof v === 'object') search(v, depth + 1)
  })
}
search(missionData)

console.log(`\nFound ${airdromeUnits.length} units at airbases\n`)

if (airdromeUnits.length === 0) {
  console.log('No units found at airbases.')
  console.log('This mission does not have any units spawned at airbase ramp slots.')
  console.log('\nTo derive projection parameters, you need a mission with:')
  console.log('  - Units placed at airbases (not just flying units)')
  console.log('  - The units must have "Airbase" as their start type')
  process.exit(1)
}

// Read Radio.lua for airbase names
const radioPath = path.join(DCS_PATH, 'Mods', 'terrains', theater, 'Radio.lua')
let airbaseNames = {}
try {
  const luaparse = (await import('luaparse')).default
  const radioContent = readFileSync(radioPath, 'utf8')
  const ast = luaparse.parse(radioContent, { comments: true, locations: true })
  const radioTable = ast.body.find(
    stmt => stmt.type === 'AssignmentStatement' && stmt.variables?.[0]?.name === 'radio'
  )?.init?.[0]

  if (radioTable) {
    const commentByLine = {}
    ast.comments?.forEach(c => {
      if (c.type === 'Comment' && c.raw.startsWith('-- ') && c.loc?.start?.line) {
        commentByLine[c.loc.start.line] = c.raw.replace(/^--\s*/, '').trim()
      }
    })

    for (const field of radioTable.fields) {
      if (field.type === 'TableValue' && field.value?.type === 'TableConstructorExpression') {
        const entry = field.value
        let name = null
        let id = null

        const startLine = entry.loc?.start?.line
        const endLine = entry.loc?.end?.line
        if (startLine && endLine) {
          for (let line = startLine; line <= endLine; line++) {
            if (commentByLine[line]) { name = commentByLine[line]; break }
          }
        }

        for (const entryField of entry.fields) {
          if (entryField.type === 'TableKeyString' && entryField.key?.name === 'radioId') {
            const match = entryField.value?.raw?.match(/airfield(\d+)_/)
            if (match) id = parseInt(match[1])
          }
        }

        if (name && id) airbaseNames[id] = name
      }
    }
  }
} catch (e) {
  console.log('Could not parse Radio.lua:', e.message)
}

// Read towns.lua
const townsPath = path.join(DCS_PATH, 'Mods', 'terrains', theater, 'Map', 'towns.lua')
let towns = {}
try {
  let townsContent = readFileSync(townsPath, 'utf8')
  const townsStart = townsContent.indexOf('towns = {')
  if (townsStart !== -1) townsContent = townsContent.substring(townsStart + 'towns = '.length)
  townsContent = townsContent.replace(/display_name\s*=\s*_\(\s*"([^"]+)"\s*\)/g, 'display_name = "$1"')
  towns = luadata.serializer.unserialize(townsContent, { dictType: 'object' })
} catch (e) {
  console.log('Could not parse towns.lua:', e.message)
}

// Find unique airdromeIds and their average coordinates
const airdromeCoords = new Map()
for (const unit of airdromeUnits) {
  if (!airdromeCoords.has(unit.airdromeId)) {
    airdromeCoords.set(unit.airdromeId, { x: 0, y: 0, count: 0, name: airbaseNames[unit.airdromeId] || `ID:${unit.airdromeId}` })
  }
  const entry = airdromeCoords.get(unit.airdromeId)
  entry.x += unit.x
  entry.y += unit.y
  entry.count++
}

// Average the coordinates
for (const [id, data] of airdromeCoords) {
  data.x = Math.round(data.x / data.count)
  data.y = Math.round(data.y / data.count)
}

console.log('Airbases found in this mission:')
console.log('ID | Name                  | DCS X        | DCS Y')
console.log('-'.repeat(60))
for (const [id, data] of airdromeCoords) {
  console.log(`${String(id).padStart(2)} | ${data.name.padEnd(21)} | ${String(data.x).padStart(12)} | ${data.y}`)
}

// Now find matching towns and derive projection
console.log('\n=== Deriving Projection Parameters ===\n')

// Use least squares to find best-fit x0, y0 offset
let sumXRaw = 0, sumYRaw = 0, sumXDCS = 0, sumYDCS = 0, n = 0
const ELLIPSOID_A = 6378137.0
const lon0 = 33 * Math.PI / 180 // default for Caucasus, adjust per theater

for (const [airdromeId, data] of airdromeCoords) {
  // Find matching town
  const match = Object.entries(towns).find(([townName]) => {
    const normalizedTown = townName.toUpperCase().replace(/[^A-Z0-9']/g, '')
    const normalizedName = (data.name || '').toUpperCase().replace(/[^A-Z0-9']/g, '')
    return normalizedTown === normalizedName || normalizedTown.includes(normalizedName) || normalizedName.includes(normalizedTown)
  })

  if (match) {
    const town = match[1]
    const latRad = town.latitude * Math.PI / 180
    const lonRad = town.longitude * Math.PI / 180
    const k0 = 0.9996
    const e = 0.081819190842621
    const n_param = (1 - Math.sqrt(1 - e * e)) / (1 + Math.sqrt(1 - e * e))
    const A = ELLIPSOID_A * (1 - n_param) / (1 + n_param) * (1 + n_param * n_param / 4)
    const M = A * latRad // simplified
    const v = ELLIPSOID_A / Math.sqrt(1 - e * e * Math.sin(latRad) * Math.sin(latRad))
    const deltaLon = lonRad - lon0

    const xRaw = k0 * v * deltaLon * Math.cos(latRad)
    const yRaw = k0 * M

    sumXRaw += xRaw
    sumYRaw += yRaw
    sumXDCS += data.x
    sumYDCS += data.y
    n++

    console.log(`${data.name}: town(${town.latitude}, ${town.longitude}) → raw(${Math.round(xRaw)}, ${Math.round(yRaw)}) → DCS(${data.x}, ${data.y})`)
  }
}

if (n > 0) {
  const avgXRaw = sumXRaw / n
  const avgYRaw = sumYRaw / n
  const avgXDCS = sumXDCS / n
  const avgYDCS = sumYDCS / n

  const x0 = Math.round(avgXDCS - avgXRaw)
  const y0 = Math.round(avgYDCS - avgYRaw)

  console.log('\n=== DERIVED PROJECTION PARAMETERS ===\n')
  console.log(`Theater: '${theater}'`)
  console.log(`{ lat0: 0, lon0: 33, k0: 0.9996, x0: ${x0}, y0: ${y0} }`)
  console.log(`\nBased on ${n} airbase matches`)
  console.log('\nAdd this to THEATER_PROJECTIONS in mizParser.js')
} else {
  console.log('\nNo town matches found. Cannot derive projection.')
  console.log('The airbase names in Radio.lua may not match town names in towns.lua')
}
