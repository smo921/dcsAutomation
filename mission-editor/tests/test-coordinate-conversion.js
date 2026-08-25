#!/usr/bin/env node

/**
 * Test coordinate conversion: lat/lon → DCS X/Y
 *
 * This test verifies the conversion by checking that:
 * 1. Town coordinates from towns.lua are successfully parsed
 * 2. Airbase names from Radio.lua are extracted
 * 3. Airbases are matched to towns by name
 * 4. Converted coordinates are reasonable (positive values for Caucasus)
 *
 * For accurate verification, compare output coordinates against
 * F10 markpoints in DCS Mission Editor.
 */

import { latLonToDCS, getAllAirbasesFromTerrain, THEATER_PROJECTIONS } from '../src/main/mizParser.js'

const DCS_PATH = 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\DCSWorld'
const THEATER = 'Caucasus'

console.log('='.repeat(70))
console.log('DCS Coordinate Conversion Test')
console.log('='.repeat(70))

// Test 1: Verify projection parameters exist
console.log('\n=== Test 1: Theater projection parameters ===\n')
console.log(`Theater: ${THEATER}`)
console.log('Parameters:', THEATER_PROJECTIONS[THEATER])

if (!THEATER_PROJECTIONS[THEATER]) {
  console.log('✗ FAIL: No projection parameters for this theater')
  process.exit(1)
}
console.log('✓ Projection parameters exist')

// Test 2: Parse terrain data
console.log('\n=== Test 2: Terrain data parsing ===\n')

try {
  const airbases = getAllAirbasesFromTerrain(THEATER, DCS_PATH)
  console.log(`✓ Parsed ${airbases.length} airbases from Radio.lua`)

  const withCoords = airbases.filter(ab => ab.x && ab.y)
  const withoutCoords = airbases.filter(ab => !ab.x || !ab.y)

  console.log(`✓ ${withCoords.length}/${airbases.length} matched to towns and have coordinates`)

  if (withoutCoords.length > 0) {
    console.log(`\n  Airbases without town matches (need MIZ coords):`)
    withoutCoords.forEach(ab => console.log(`    - ${ab.name} (id: ${ab.airdromeId})`))
  }

  // Test 3: Verify coordinates are reasonable
  console.log('\n=== Test 3: Coordinate sanity check ===\n')

  // Caucasus theater should have positive X and Y values roughly in this range:
  // X: 0 to 800000 (west to east)
  // Y: 200000 to 900000 (south to north)
  // These are approximate - actual bounds may vary

  let saneCount = 0
  let warnings = []

  for (const ab of withCoords) {
    const xOk = ab.x > -200000 && ab.x < 1000000
    const yOk = ab.y > 0 && ab.y < 1000000

    if (xOk && yOk) {
      saneCount++
    } else {
      warnings.push({
        name: ab.name,
        x: Math.round(ab.x),
        y: Math.round(ab.y),
        matchedTown: ab.matchedTown
      })
    }
  }

  console.log(`${saneCount}/${withCoords.length} coordinates in expected range`)

  if (warnings.length > 0) {
    console.log('\n  Coordinates outside expected range:')
    warnings.forEach(w => {
      console.log(`    - ${w.name} (${w.matchedTown}): x=${w.x}, y=${w.y}`)
    })
    console.log('\n  Note: These may still be correct. Verify against DCS F10 map.')
  }

  // Test 4: Show sample conversions
  console.log('\n=== Sample airbase coordinates ===\n')
  console.log('Airbase                | DCS X      | DCS Y      | Matched Town')
  console.log('-'.repeat(70))
  withCoords.slice(0, 10).forEach(ab => {
    const xStr = String(Math.round(ab.x)).padStart(10)
    const yStr = String(Math.round(ab.y)).padStart(10)
    const townStr = ab.matchedTown || '(no match)'
    console.log(`${ab.name.padEnd(22)} | ${xStr} | ${yStr} | ${townStr}`)
  })

  console.log('\n' + '='.repeat(70))
  console.log('VERIFICATION INSTRUCTIONS:')
  console.log('1. Open any mission in DCS Mission Editor')
  console.log('2. Fly to or find each airbase listed above')
  console.log('3. Press F10 → create markpoint on the runway center')
  console.log('4. Compare the X/Y coordinates shown with the table')
  console.log('')
  console.log('If coordinates differ significantly, the projection parameters')
  console.log('in mizParser.js need adjustment for your DCS version.')
  console.log('='.repeat(70))

} catch (e) {
  console.log(`✗ Terrain parsing failed: ${e.message}`)
  console.log(e.stack)
  process.exit(1)
}
