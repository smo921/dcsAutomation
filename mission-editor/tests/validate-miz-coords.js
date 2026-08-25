#!/usr/bin/env node

/**
 * Validate coordinate conversion against actual MIZ data
 *
 * Extracts unit coordinates from the MIZ file and compares them
 * to coordinates computed from towns.lua
 */

import { readFileSync } from 'fs'
import luadata from 'luadata'
import { getAllAirbasesFromTerrain, latLonToDCS } from '../src/main/mizParser.js'

const MIZ_TEMP = 'C:\\Users\\steph\\DCS Scripts\\automatic\\miz-temp'
const DCS_PATH = 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\DCSWorld'
const THEATER = 'Caucasus'

// Parse mission file
const missionContent = readFileSync(MIZ_TEMP + '/mission', 'utf8')
const firstBrace = missionContent.indexOf('{')
const lastBrace = missionContent.lastIndexOf('}')
const tableContent = missionContent.substring(firstBrace, lastBrace + 1)
const mission = luadata.serializer.unserialize(tableContent, { dictType: 'object' })

// Find all route points with airdromeId and coordinates
const mizAirdromes = new Map()

function searchAirdromes(obj) {
  if (!obj || typeof obj !== 'object') return
  if (Array.isArray(obj)) {
    obj.forEach(searchAirdromes)
    return
  }

  if (obj.airdromeId !== undefined && obj.x !== undefined && obj.y !== undefined) {
    mizAirdromes.set(obj.airdromeId, {
      x: obj.x,
      y: obj.y,
      action: obj.action
    })
  }

  Object.values(obj).forEach(v => {
    if (typeof v === 'object') searchAirdromes(v)
  })
}

searchAirdromes(mission.mission || mission)

console.log('='.repeat(70))
console.log('MIZ Coordinate Validation')
console.log('='.repeat(70))

console.log(`\nFound ${mizAirdromes.size} airdrome references in MIZ file\n`)

// Get terrain airbase data
const terrainAirbases = getAllAirbasesFromTerrain(THEATER, DCS_PATH)

// Build lookup by airdromeId
const terrainById = new Map()
terrainAirbases.forEach(ab => {
  if (ab.airdromeId) terrainById.set(ab.airdromeId, ab)
})

console.log('=== Coordinate Comparison ===\n')
console.log('ID | Airbase               | MIZ X     | MIZ Y     | Calc X    | Calc Y    | Diff')
console.log('-'.repeat(95))

let matched = 0
let sumDist = 0

for (const [airdromeId, mizData] of mizAirdromes) {
  const terrain = terrainById.get(airdromeId)

  if (terrain && terrain.x && terrain.y) {
    const diffX = Math.abs(terrain.x - mizData.x)
    const diffY = Math.abs(terrain.y - mizData.y)
    const dist = Math.sqrt(diffX * diffX + diffY * diffY)

    const status = dist < 1000 ? '✓' : '✗'

    console.log(`${String(airdromeId).padStart(2)} | ${terrain.name.padEnd(21)} | ${String(Math.round(mizData.x)).padStart(9)} | ${String(Math.round(mizData.y)).padStart(9)} | ${String(Math.round(terrain.x)).padStart(9)} | ${String(Math.round(terrain.y)).padStart(9)} | ${status} ${Math.round(dist)}m`)

    matched++
    sumDist += dist
  } else {
    console.log(`${String(airdromeId).padStart(2)} | (no terrain match)    | ${String(Math.round(mizData.x)).padStart(9)} | ${String(Math.round(mizData.y)).padStart(9)} | ${'N/A'.padStart(9)} | ${'N/A'.padStart(9)} | -`)
  }
}

console.log('\n' + '='.repeat(70))
console.log(`Matched: ${matched}/${mizAirdromes.size}`)
if (matched > 0) {
  console.log(`Average difference: ${Math.round(sumDist / matched)}m`)
}
console.log('='.repeat(70))

if (matched === 0) {
  console.log('\nNo matches found. This could mean:')
  console.log('1. The MIZ uses different airbase names than towns.lua')
  console.log('2. The projection parameters need adjustment')
  console.log('\nMIZ airdromeIds found:', Array.from(mizAirdromes.keys()).join(', '))
}
