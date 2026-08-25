// Standalone MIZ Parser for Mission Validator
// Copied from mission-editor with minimal dependencies

import fs from 'fs'
import path from 'path'
import os from 'os'
import AdmZip from 'adm-zip'
import luadata from 'luadata'

/**
 * Parse a .miz file and extract mission data
 * Simplified version for validation purposes
 */
export function parseMizFile(mizPath, dcsInstallPath = null) {
  const tempDir = path.join(os.tmpdir(), 'miz-extract-' + Date.now())
  fs.mkdirSync(tempDir, { recursive: true })

  try {
    const zip = new AdmZip(mizPath)
    zip.extractAllTo(tempDir, true)

    const missionPath = path.join(tempDir, 'mission')
    if (!fs.existsSync(missionPath)) {
      throw new Error('Mission file not found in .miz archive')
    }

    const missionContent = fs.readFileSync(missionPath, 'utf8')

    const firstBrace = missionContent.indexOf('{')
    const lastBrace = missionContent.lastIndexOf('}')
    const tableContent = missionContent.substring(firstBrace, lastBrace + 1)

    const parsed = luadata.serializer.unserialize(tableContent, { dictType: 'object' })
    const missionData = parsed.mission || parsed

    if (!missionData || Object.keys(missionData).length === 0) {
      throw new Error('Failed to parse mission file')
    }

    if (!missionData.theatre) {
      throw new Error('Theater not found in mission')
    }

    const theater = missionData.theatre

    // Extract units from mission
    const units = extractUnits(missionData, theater)

    console.log('[MIZ Parser] Extracted from', path.basename(mizPath), ':')
    console.log('[MIZ Parser] Theater:', theater)
    console.log('[MIZ Parser] Units:', units.length)

    return {
      theater,
      units,
      raw: missionData
    }
  } catch (err) {
    if (/corrupt|invalid|empty/i.test(err.message)) {
      throw new Error('Mission file is corrupted or empty')
    }
    if (/no such file/i.test(err.message)) {
      throw new Error('Mission file not found')
    }
    throw err
  } finally {
    try {
      fs.rmSync(tempDir, { recursive: true, force: true })
    } catch (e) {
      console.error('Failed to cleanup temp directory:', e)
    }
  }
}

/**
 * Extract all units/groups from the mission
 */
function extractUnits(missionData, theater = 'Caucasus') {
  const units = []

  // Handle both 'coalition' and 'coalitions' formats
  const coalitionData = missionData.coalition || missionData.coalitions
  if (!coalitionData) {
    console.log('[MIZ Parser] No coalition data found')
    return units
  }

  const coalitionKeys = ['blue', 'red', 'neutrals']
  const coalitionDisplay = { blue: 'Blue', red: 'Red', neutrals: 'Neutrals' }

  for (const coalitionKey of coalitionKeys) {
    const coalitionSection = coalitionData[coalitionKey]
    if (!coalitionSection) continue

    const countries = coalitionSection.country || []
    if (!Array.isArray(countries)) continue

    for (const country of countries) {
      const countryName = country.name || `Country_${country.id || 'unknown'}`
      const countryId = country.id

      const unitTypes = ['plane', 'ground', 'ship', 'helicopter', 'vehicle']

      for (const unitType of unitTypes) {
        const unitsInType = country[unitType]
        if (!unitsInType) continue

        const groups = unitsInType.group || []
        if (!Array.isArray(groups)) continue

        for (const group of groups) {
          // Get group-level properties
          const groupFreq = group.frequency
          const groupAlt = group.route?.points?.[0]?.alt
          const groupTask = group.task
          
          const unit = {
            id: group.groupId || group.name || `unit_${units.length}`,
            name: group.name || `Unnamed ${unitType}`,
            type: unitType,
            coalition: coalitionDisplay[coalitionKey],
            country: countryName,
            countryId,
            task: groupTask || (group.taskSelected ? group.task : null),
            frequency: groupFreq,
            altitude: groupAlt,
            controlled: group.uncontrolled === false ? false : (group.uncontrolled === true ? true : undefined),
            radioSet: group.radioSet,
            unlimitedFuel: false, // Will check in tasks
            invincible: false,
            invisible: false,
            units: [],
            route: []
          }
          
          // Check for advanced options in route tasks
          if (group.route?.points?.[0]?.task?.params?.tasks) {
            const tasks = group.route.points[0].task.params.tasks
            for (const task of tasks) {
              if (task.params?.action?.id === 'SetUnlimitedFuel' && task.params.action.params.value) {
                unit.unlimitedFuel = true
              }
              if (task.params?.action?.id === 'SetImmortal' && task.params.action.params.value) {
                unit.invincible = true
              }
              if (task.params?.action?.id === 'SetInvisible' && task.params.action.params.value) {
                unit.invisible = true
              }
            }
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
                type: point.type,
                task: point.task  // Keep full task structure for advanced checks
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

  console.log(`[MIZ Parser] Extracted ${units.length} units from coalitions`)
  return units
}

export { extractUnits }
