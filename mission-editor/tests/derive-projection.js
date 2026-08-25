#!/usr/bin/env node

/**
 * Derive DCS projection parameters from known MIZ coordinates
 *
 * Uses Batumi's known position to back-calculate the projection offset
 */

import { readFileSync } from 'fs'
import luadata from 'luadata'
import path from 'path'

const MIZ_TEMP = 'C:\\Users\\steph\\DCS Scripts\\automatic\\miz-temp'
const DCS_PATH = 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\DCSWorld'
const THEATER = 'Caucasus'

// Read towns.lua for Batumi
const townsPath = path.join(DCS_PATH, 'Mods', 'terrains', THEATER, 'Map', 'towns.lua')
let townsContent = readFileSync(townsPath, 'utf8')
const townsStart = townsContent.indexOf('towns = {')
if (townsStart !== -1) {
  townsContent = townsContent.substring(townsStart + 'towns = '.length)
}
townsContent = townsContent.replace(/display_name\s*=\s*_\(\s*"([^"]+)"\s*\)/g, 'display_name = "$1"')
const towns = luadata.serializer.unserialize(townsContent, { dictType: 'object' })

// Find Batumi
const batumi = towns['BATUMI'] || towns['Batumi'] || Object.entries(towns).find(([k]) => k.toUpperCase().includes('BATUMI'))
const batumiTown = Array.isArray(batumi) ? batumi[1] : batumi

if (!batumiTown) {
  console.log('Batumi not found in towns.lua')
  process.exit(1)
}

console.log('Batumi town coordinates:')
console.log(`  Latitude:  ${batumiTown.latitude}`)
console.log(`  Longitude: ${batumiTown.longitude}`)

// Read MIZ for actual DCS coordinates
const missionContent = readFileSync(MIZ_TEMP + '/mission', 'utf8')
const firstBrace = missionContent.indexOf('{')
const lastBrace = missionContent.lastIndexOf('}')
const tableContent = missionContent.substring(firstBrace, lastBrace + 1)
const mission = luadata.serializer.unserialize(tableContent, { dictType: 'object' })

// Find Batumi unit (airdromeId 22)
let batumiMiz = null
function search(obj) {
  if (!obj || typeof obj !== 'object') return
  if (Array.isArray(obj)) {
    obj.forEach(search)
    return
  }
  if (obj.airdromeId === 22 && obj.x !== undefined) {
    batumiMiz = { x: obj.x, y: obj.y }
  }
  Object.values(obj).forEach(v => {
    if (typeof v === 'object') search(v)
  })
}
search(mission.mission || mission)

if (!batumiMiz) {
  console.log('Batumi (airdromeId 22) not found in MIZ')
  process.exit(1)
}

console.log('\nBatumi DCS coordinates from MIZ:')
console.log(`  X: ${batumiMiz.x}`)
console.log(`  Y: ${batumiMiz.y}`)

// Now calculate what the projection offset should be
// Using simple Transverse Mercator without offset first
const ELLIPSOID_A = 6378137.0
const lat0 = 0
const lon0 = 33 * Math.PI / 180
const k0 = 0.9996
const e = 0.081819190842621

const latRad = batumiTown.latitude * Math.PI / 180
const lonRad = batumiTown.longitude * Math.PI / 180

const n = (1 - Math.sqrt(1 - e * e)) / (1 + Math.sqrt(1 - e * e))
const A = ELLIPSOID_A * (1 - n) / (1 + n) * (1 + n * n / 4 + n * n * n * n / 64)
const alpha = [
  A * (1 + n * n / 4 + n * n * n * n / 64),
  -A * (3 * n / 2 - 9 * n * n * n / 32 + 9 * n * n * n * n * n / 512),
  A * (15 * n * n / 16 - 15 * n * n * n * n / 256),
  -A * (35 * n * n * n / 48 - 175 * n * n * n * n * n / 3072)
]
const M = alpha[0] * latRad + alpha[1] * Math.sin(2 * latRad) + alpha[2] * Math.sin(4 * latRad) + alpha[3] * Math.sin(6 * latRad)
const v = ELLIPSOID_A / Math.sqrt(1 - e * e * Math.sin(latRad) * Math.sin(latRad))
const deltaLon = lonRad - lon0

const xRaw = k0 * v * deltaLon * Math.cos(latRad)
const yRaw = k0 * M

console.log('\nRaw projection (no offset):')
console.log(`  xRaw: ${Math.round(xRaw)}`)
console.log(`  yRaw: ${Math.round(yRaw)}`)

// Calculate required offset
const xOffset = batumiMiz.x - xRaw
const yOffset = batumiMiz.y - yRaw

console.log('\nRequired offset to match DCS:')
console.log(`  x0: ${Math.round(xOffset)}`)
console.log(`  y0: ${Math.round(yOffset)}`)

console.log('\nSuggested THEATER_PROJECTIONS for Caucasus:')
console.log(`{ lat0: 0, lon0: 33, k0: 0.9996, x0: ${Math.round(xOffset)}, y0: ${Math.round(yOffset)} }`)
