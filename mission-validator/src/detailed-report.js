#!/usr/bin/env node

import { MissionValidator } from './validator.js'
import { parseMizFile } from './mizParser.js'
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

/**
 * Generate detailed report showing which specific units fail each check
 */
async function generateDetailedReport(mizPath) {
  console.log('🔍 Generating detailed unit report for:', path.basename(mizPath))
  console.log('=' .repeat(80))

  const configPath = path.join(__dirname, '../mission-checklist-config.json')
  const validator = new MissionValidator(configPath)
  
  // Parse MIZ file
  const missionData = parseMizFile(mizPath)
  
  console.log('\n📊 MISSION OVERVIEW')
  console.log('-'.repeat(80))
  console.log(`Theater: ${missionData.theater}`)
  console.log(`Total Units: ${missionData.units.length}`)
  
  // Group units by coalition and type
  const blueUnits = missionData.units.filter(u => u.coalition === 'Blue')
  const redUnits = missionData.units.filter(u => u.coalition === 'Red')
  
  console.log(`\nBLUE Units: ${blueUnits.length}`)
  console.log(`RED Units: ${redUnits.length}`)
  
  // Find units missing COMM channels
  console.log('\n\n📻 UNITS MISSING COMMUNICATION CHANNELS')
  console.log('-'.repeat(80))
  
  const missingComm = []
  for (const unit of missionData.units) {
    const hasUHF = unit.comm?.UHF || unit.frequency
    const hasVHF = unit.comm?.VHF
    
    if (!hasUHF || !hasVHF) {
      missingComm.push({
        name: unit.name,
        coalition: unit.coalition,
        type: unit.type,
        hasUHF: !!hasUHF,
        hasVHF: !!hasVHF,
        uhfFreq: hasUHF,
        vhfFreq: hasVHF
      })
    }
  }
  
  console.log(`\nFound ${missingComm.length} units missing COMM channels:\n`)
  
  const blueMissingComm = missingComm.filter(u => u.coalition === 'Blue')
  const redMissingComm = missingComm.filter(u => u.coalition === 'Red')
  
  if (blueMissingComm.length > 0) {
    console.log('BLUE Units Missing COMM:')
    console.log('  ' + '-'.repeat(76))
    for (const unit of blueMissingComm) {
      const uhfStatus = unit.hasUHF ? `✅ ${unit.uhfFreq}` : '❌ Missing'
      const vhfStatus = unit.hasVHF ? `✅ ${unit.vhfFreq}` : '❌ Missing'
      console.log(`  ${unit.name.padEnd(30)} | UHF: ${uhfStatus} | VHF: ${vhfStatus}`)
    }
    console.log()
  }
  
  if (redMissingComm.length > 0) {
    console.log('RED Units Missing COMM:')
    console.log('  ' + '-'.repeat(76))
    for (const unit of redMissingComm) {
      const uhfStatus = unit.hasUHF ? `✅ ${unit.uhfFreq}` : '❌ Missing'
      const vhfStatus = unit.hasVHF ? `✅ ${unit.vhfFreq}` : '❌ Missing'
      console.log(`  ${unit.name.padEnd(30)} | UHF: ${uhfStatus} | VHF: ${vhfStatus}`)
    }
    console.log()
  }
  
  // Find player slots not set as client
  console.log('\n\n👤 PLAYER SLOTS NOT SET AS CLIENT')
  console.log('-'.repeat(80))
  console.log('\nNote: Player aircraft should have controlled=false (Client type)')
  console.log('      AI aircraft should have controlled=true\n')
  
  // Assume units with certain tasks or names are player slots
  const potentialPlayerSlots = missionData.units.filter(unit => {
    // Player slots are typically:
    // - BLUE coalition
    // - plane or helicopter type
    // - Not named with generic AI names
    return unit.coalition === 'Blue' && 
           (unit.type === 'plane' || unit.type === 'helicopter')
  })
  
  const notClient = []
  const isClient = []
  
  for (const unit of potentialPlayerSlots) {
    // controlled=false means it's a client (player can join)
    // controlled=true means it's AI
    if (unit.controlled === true || unit.controlled === undefined) {
      notClient.push(unit)
    } else {
      isClient.push(unit)
    }
  }
  
  console.log(`\nPotential Player Slots: ${potentialPlayerSlots.length}`)
  console.log(`  ✅ Set as Client (controlled=false): ${isClient.length}`)
  console.log(`  ❌ NOT Set as Client (controlled=true): ${notClient.length}\n`)
  
  if (notClient.length > 0) {
    console.log('Units that need to be set as Client:')
    console.log('  ' + '-'.repeat(76))
    for (const unit of notClient) {
      const skill = unit.units?.[0]?.skill || 'Unknown'
      console.log(`  ${unit.name.padEnd(30)} | Type: ${unit.type.padEnd(12)} | Skill: ${skill}`)
    }
    console.log()
  }
  
  if (isClient.length > 0) {
    console.log('Units correctly set as Client:')
    console.log('  ' + '-'.repeat(76))
    for (const unit of isClient) {
      const skill = unit.units?.[0]?.skill || 'Unknown'
      console.log(`  ${unit.name.padEnd(30)} | Type: ${unit.type.padEnd(12)} | Skill: ${skill}`)
    }
    console.log()
  }
  
  // AWACS specific issues
  console.log('\n\n🛰️ AWACS CONFIGURATION ISSUES')
  console.log('-'.repeat(80))
  
  const awacsUnits = missionData.units.filter(u => u.task === 'AWACS' || u.name.includes('AWACS'))
  
  console.log(`\nFound ${awacsUnits.length} AWACS unit(s):\n`)
  
  for (const unit of awacsUnits) {
    console.log(`  ${unit.name}`)
    console.log('  ' + '-'.repeat(60))
    
    const freqOk = unit.frequency === 305.00
    const altOk = (unit.altitude || 0) >= 30000
    const waypointsOk = (unit.route?.length || 0) === 2
    
    console.log(`    Frequency: ${freqOk ? '✅' : '❌'} ${unit.frequency || 'NOT SET'} MHz (should be 305.00)`)
    console.log(`    Altitude:  ${altOk ? '✅' : '❌'} ${unit.altitude || 0} feet (should be ≥30000)`)
    console.log(`    Waypoints: ${waypointsOk ? '✅' : '❌'} ${unit.route?.length || 0} waypoints (should be 2)`)
    
    const advancedOk = unit.unlimitedFuel && unit.invincible && unit.invisible
    console.log(`    Advanced:  ${advancedOk ? '✅' : '❌'} UnlimitedFuel:${unit.unlimitedFuel || false}, Invincible:${unit.invincible || false}, Invisible:${unit.invisible || false}`)
    console.log()
  }
  
  // Summary
  console.log('\n\n📋 SUMMARY OF REQUIRED FIXES')
  console.log('-'.repeat(80))
  console.log(`\n1. Set ${notClient.length} player slots as Client type`)
  console.log(`2. Add COMM channels to ${blueMissingComm.length} BLUE units`)
  console.log(`3. Fix AWACS frequency/altitude/waypoints (${awacsUnits.length} units)`)
  console.log(`4. Enable Dynamic Spawn and Hot Start on all FARPs/bases/carriers`)
  console.log()
  
  return {
    missionData,
    missingComm,
    notClient,
    isClient,
    awacsUnits
  }
}

// Run if called from command line
const args = process.argv.slice(2)
if (args.length > 0) {
  generateDetailedReport(args[0]).catch(error => {
    console.error('Error:', error.message)
    process.exit(1)
  })
} else {
  console.log('Usage: node detailed-report.js <mission.miz>')
  process.exit(1)
}
