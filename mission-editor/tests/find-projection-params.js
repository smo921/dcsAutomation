#!/usr/bin/env node

/**
 * Reverse-engineer the DCS projection parameters
 * by solving for the transform that maps known lat/lon to known DCS coords
 */

import { readFileSync } from 'fs'
import path from 'path'

const DCS_PATH = 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\DCSWorld'
const THEATER = 'Caucasus'

// Known pairs: lat/lon → DCS X/Y
const KNOWN_PAIRS = [
  // Batumi airbase center (from DCS Mission Editor F10 markpoint)
  { lat: 41.6458, lon: 41.6278, x: 157396, y: 645843 },
  // Gudauta
  { lat: 42.8667, lon: 40.6167, x: 269106, y: 564823 },
]

// Read towns.lua to get precise coordinates
const townsPath = path.join(DCS_PATH, 'Mods', 'terrains', THEATER, 'Map', 'towns.lua')
let townsContent = readFileSync(townsPath, 'utf8')

// Preprocess
const townsStart = townsContent.indexOf('towns = {')
if (townsStart !== -1) {
  townsContent = townsContent.substring(townsStart + 'towns = '.length)
}
townsContent = townsContent.replace(/display_name\s*=\s*_\(\s*"([^"]+)"\s*\)/g, 'display_name = "$1"')

import luadata from 'luadata'
const towns = luadata.serializer.unserialize(townsContent, { dictType: 'object' })

console.log('Looking up town coordinates...')
for (const pair of KNOWN_PAIRS) {
  // Find matching town
  const match = Object.entries(towns).find(([name]) =>
    name.toUpperCase().includes(pair.lat.toFixed(2).replace('.', '')) ||
    Math.abs(towns[name].latitude - pair.lat) < 0.01
  )
  if (match) {
    console.log(`Found: ${match[0]} = ${match[1].latitude}, ${match[1].longitude}`)
  }
}

// Simple equirectangular approximation for initial guess
console.log('\n=== Simple equirectangular test ===')
const EARTH_RADIUS = 6378137

for (const pair of KNOWN_PAIRS) {
  const latRad = pair.lat * Math.PI / 180
  const lonRad = pair.lon * Math.PI / 180

  // Equirectangular approximation
  const x = lonRad * EARTH_RADIUS * Math.cos(latRad)
  const y = latRad * EARTH_RADIUS

  console.log(`${pair.lat}, ${pair.lon} → x=${Math.round(x)}, y=${Math.round(y)}`)
  console.log(`  Expected: x=${pair.x}, y=${pair.y}`)
  console.log(`  Offset: dx=${pair.x - Math.round(x)}, dy=${pair.y - Math.round(y)}`)
}
