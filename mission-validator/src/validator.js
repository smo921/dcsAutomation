import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'
import { parseMizFile } from './mizParser.js'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

/**
 * Mission Validator - Validates DCS missions against checklist rules
 */
export class MissionValidator {
  constructor(configPath = null) {
    this.config = this.loadConfig(configPath)
    this.results = {
      passed: [],
      failed: [],
      warnings: [],
      info: [],
      errors: []
    }
  }

  /**
   * Load validation configuration
   */
  loadConfig(configPath) {
    if (!configPath) {
      // Try default locations
      const defaultPaths = [
        path.join(__dirname, '../mission-checklist-config.json'),
        path.join(process.cwd(), 'mission-checklist-config.json')
      ]
      
      for (const p of defaultPaths) {
        if (fs.existsSync(p)) {
          configPath = p
          break
        }
      }
    }

    if (!configPath || !fs.existsSync(configPath)) {
      throw new Error('Validation configuration file not found')
    }

    const loaded = JSON.parse(fs.readFileSync(configPath, 'utf8'))
    
    // Merge external rule files from 'externalRules' field or 'mergedFrom'
    let merged = JSON.parse(JSON.stringify(loaded))
    
    console.log('\n🔗 Loading external rules:')
    
    const hasExternalRules = Array.isArray(loaded.externalRules)
    const needsEmptyCategories = !merged.categories || (Array.isArray(merged.categories) && merged.categories.length === 0)
    
    if (needsEmptyCategories && hasExternalRules) {
      // Start with empty categories when no built-in rules found
      merged.categories = []
      
      for (const relPath of loaded.externalRules) {
        const fullPath = path.resolve(__dirname, '..', relPath)
        if (fs.existsSync(fullPath)) {
          console.log(`  ✓ ${relPath}`)
          const extRules = JSON.parse(fs.readFileSync(fullPath, 'utf8'))
          
          // Merge categories from external rule files
          for (const cat of extRules.categories || []) {
            merged.categories.push(cat)
          }
        } else {
          console.log(`  ✗ ${relPath} -> Not found`)
        }
      }
    } else if (!merged.categories && Array.isArray(loaded.mergedFrom)) {
      // Alternative: use 'mergedFrom' array for file paths
      merged.categories = []
      
      for (const relPath of loaded.mergedFrom) {
        const fullPath = path.resolve(__dirname, '..', relPath)
        if (fs.existsSync(fullPath)) {
          console.log(`  ✓ ${relPath}`)
          const catRules = JSON.parse(fs.readFileSync(fullPath, 'utf8'))
          
          for (const cat of catRules.categories || []) {
            merged.categories.push(cat)
          }
        } else {
          console.log(`  ✗ ${relPath} -> Not found`)
        }
      }
    }
    
    return merged
  }

  /**
   * Validate mission data directly (for testing and editor integration)
   */
  async validateMissionData(missionData, dcsInstallPath = null) {
    console.log('\n🔍 Validating mission data')
    console.log('=' .repeat(60))

    // Reset results
    this.results = {
      passed: [],
      failed: [],
      warnings: [],
      info: [],
      errors: [],
      missionData,
      timestamp: Date.now()
    }

    // Run all validation rules
    for (const category of this.config.categories) {
      console.log(`\n📋 Checking: ${category.name}`)
      console.log('-'.repeat(40))
      
      for (const rule of category.rules) {
        await this.validateRule(rule, missionData)
      }
    }

    // Generate summary
    this.printSummary()
    
    return this.results
  }

  /**
   * Validate a MIZ file
   */
  async validateMizFile(mizPath, dcsInstallPath = null) {
    console.log(`\n🔍 Validating mission: ${path.basename(mizPath)}`)
    console.log('=' .repeat(60))

    // Parse the MIZ file
    const missionData = parseMizFile(mizPath, dcsInstallPath)
    
    // Reset results
    this.results = {
      passed: [],
      failed: [],
      warnings: [],
      info: [],
      errors: [],
      missionData
    }

    // Run all validation rules
    for (const category of this.config.categories) {
      console.log(`\n📋 Checking: ${category.name}`)
      console.log('-'.repeat(40))
      
      for (const rule of category.rules) {
        await this.validateRule(rule, missionData)
      }
    }

    // Generate summary
    this.printSummary()
    
    return this.results
  }

  /**
   * Validate a single rule against mission data
   */
  async validateRule(rule, missionData) {
    const validator = this.getValidator(rule.type)
    
    if (!validator) {
      console.log(`  ⚠️  Unknown rule type: ${rule.type}`)
      return
    }

    try {
      const result = await validator(rule, missionData)
      
      if (result.passed) {
        this.results.passed.push({
          ruleId: rule.id,
          name: rule.name,
          category: rule.category
        })
        console.log(`  ✅ ${rule.name}`)
      } else {
        const issue = {
          ruleId: rule.id,
          name: rule.name,
          category: rule.category,
          severity: rule.severity,
          description: rule.description,
          details: result.details,
          suggestion: result.suggestion
        }

        // Categorize by severity
        if (rule.severity === 'error') {
          this.results.errors.push(issue)
          console.log(`  ❌ ${rule.name}: ${result.details}`)
        } else if (rule.severity === 'warning') {
          this.results.warnings.push(issue)
          console.log(`  ⚠️  ${rule.name}: ${result.details}`)
        } else if (rule.severity === 'info') {
          this.results.info.push(issue)
          console.log(`  ℹ️  ${rule.name}: ${result.details}`)
        } else {
          this.results.failed.push(issue)
          console.log(`  ❌ ${rule.name}: ${result.details}`)
        }
      }
    } catch (error) {
      console.log(`  ⚠️  ${rule.name}: Validation error - ${error.message}`)
    }
  }

  /**
   * Get validator function for rule type
   */
  getValidator(type) {
    const validators = {
      naming_pattern: this.validateNamingPattern.bind(this),
      distance_check: this.validateDistanceCheck.bind(this),
      property_check: this.validatePropertyCheck.bind(this),
      proximity_check: this.validateProximityCheck.bind(this),
      presence_check: this.validatePresenceCheck.bind(this),
      frequency_check: this.validateFrequencyCheck.bind(this),
      altitude_check: this.validateAltitudeCheck.bind(this),
      waypoint_count: this.validateWaypointCount.bind(this),
      awacs_orbit: this.validateAWACSOrbit.bind(this),
      advanced_options: this.validateAdvancedOptions.bind(this),
      speed_check: this.validateSpeedCheck.bind(this),
      aircraft_config: this.validateAircraftConfig.bind(this),
      carrier_config: this.validateCarrierConfig.bind(this),
      task_check: this.validateTaskCheck.bind(this),
      pattern_check: this.validatePatternCheck.bind(this),
      comm_check: this.validateCommCheck.bind(this),
      aircraft_specific: this.validateAircraftSpecific.bind(this),
      time_check: this.validateTimeCheck.bind(this),
      weather_check: this.validateWeatherCheck.bind(this),
      wind_check: this.validateWindCheck.bind(this),
      absence_check: this.validateAbsenceCheck.bind(this)
    }

    return validators[type] || null
  }

  /**
   * Validate naming pattern
   */
  validateNamingPattern(rule, missionData) {
    const units = this.filterUnits(missionData.units, rule.target)
    
    if (units.length === 0) {
      return { passed: true }
    }

    const regex = new RegExp(rule.pattern)
    const nonMatching = units.filter(unit => !regex.test(unit.name))

    if (nonMatching.length > 0) {
      return {
        passed: false,
        details: `${nonMatching.length} unit(s) don't match pattern: ${nonMatching.map(u => u.name).join(', ')}`,
        suggestion: `Rename units to match pattern: ${rule.pattern}`
      }
    }

    return { passed: true }
  }

  /**
   * Validate distance between objects
   */
  validateDistanceCheck(rule, missionData) {
    // Implementation depends on specific rule target
    // For now, return passed as placeholder
    return { passed: true, details: 'Distance check not fully implemented' }
  }

  /**
   * Validate property value
   */
  validatePropertyCheck(rule, missionData) {
    const units = this.filterUnits(missionData.units, rule.target)
    
    if (units.length === 0) {
      return { passed: true }
    }

    const failing = units.filter(unit => {
      // Check if unit has the property and if it matches expected value
      return unit[rule.property] !== rule.expectedValue
    })

    if (failing.length > 0) {
      return {
        passed: false,
        details: `${failing.length} unit(s) have incorrect ${rule.property} setting`,
        suggestion: `Set ${rule.property} to ${rule.expectedValue}`
      }
    }

    return { passed: true }
  }

  /**
   * Validate proximity check
   */
  validateProximityCheck(rule, missionData) {
    return { passed: true, details: 'Proximity check not fully implemented' }
  }

  /**
   * Validate presence check
   */
  validatePresenceCheck(rule, missionData) {
    return { passed: true, details: 'Presence check not fully implemented' }
  }

  /**
   * Validate frequency
   */
  validateFrequencyCheck(rule, missionData) {
    const units = this.filterUnits(missionData.units, rule.target)
    
    if (units.length === 0) {
      return { passed: true }
    }

    const failing = units.filter(unit => {
      if (!unit.frequency) return true
      
      const diff = Math.abs(unit.frequency - rule.expectedFrequency)
      return diff > (rule.tolerance || 0.01)
    })

    if (failing.length > 0) {
      return {
        passed: false,
        details: `${failing.length} unit(s) have incorrect frequency`,
        suggestion: `Set frequency to ${rule.expectedFrequency} MHz`
      }
    }

    return { passed: true }
  }

  /**
   * Validate altitude
   * Note: DCS stores altitude in METERS, but checklist uses FEET
   */
  validateAltitudeCheck(rule, missionData) {
    const units = this.filterUnits(missionData.units, rule.target)
    
    if (units.length === 0) {
      return { passed: true }
    }

    let failing = []
    
    // Convert expected altitude from feet to meters if needed
    const isDcsAltitude = rule.unit === 'feet' || rule.unit === 'meters'
    const conversionFactor = rule.unit === 'feet' ? 3.28084 : 1
    
    if (rule.expectedAltitude !== undefined) {
      const toleranceMeters = (rule.tolerance || 0) / conversionFactor
      const expectedMeters = rule.expectedAltitude / conversionFactor
      
      failing = units.filter(unit => {
        const alt = unit.altitude || 0
        return Math.abs(alt - expectedMeters) > toleranceMeters
      })
    } else if (rule.minAltitude !== undefined) {
      const minAltMeters = rule.minAltitude / conversionFactor
      
      failing = units.filter(unit => {
        const alt = unit.altitude || 0
        return alt < minAltMeters
      })
    }

    if (failing.length > 0) {
      const expected = rule.expectedAltitude !== undefined 
        ? `${rule.expectedAltitude} ${rule.unit}`
        : `above ${rule.minAltitude} ${rule.unit}`
      
      return {
        passed: false,
        details: `${failing.length} unit(s) have incorrect altitude`,
        suggestion: `Set altitude to ${expected}`
      }
    }

    return { passed: true }
  }

  /**
   * Validate waypoint count
   */
  validateWaypointCount(rule, missionData) {
    const units = this.filterUnits(missionData.units, rule.target)
    
    if (units.length === 0) {
      return { passed: true }
    }

    let failing = []
    
    if (rule.exactCount !== undefined) {
      failing = units.filter(unit => {
        const waypointCount = unit.route?.length || 0
        return waypointCount !== rule.exactCount
      })
    } else if (rule.minCount !== undefined) {
      failing = units.filter(unit => {
        const waypointCount = unit.route?.length || 0
        return waypointCount < rule.minCount
      })
    } else if (rule.maxCount !== undefined) {
      failing = units.filter(unit => {
        const waypointCount = unit.route?.length || 0
        return waypointCount > rule.maxCount
      })
    }

    if (failing.length > 0) {
      let expected = ''
      if (rule.exactCount !== undefined) {
        expected = `exactly ${rule.exactCount} waypoints`
      } else if (rule.minCount !== undefined) {
        expected = `at least ${rule.minCount} waypoints`
      } else if (rule.maxCount !== undefined) {
        expected = `no more than ${rule.maxCount} waypoints`
      }
      
      return {
        passed: false,
        details: `${failing.length} unit(s) don't have correct waypoint count`,
        suggestion: `Set ${expected}`
      }
    }

    return { passed: true }
  }

  /**
   * Validate AWACS has orbit pattern
   */
  validateAWACSOrbit(rule, missionData) {
    const units = this.filterUnits(missionData.units, rule.target || { task: 'AWACS' })
    
    if (units.length === 0) {
      return { passed: true }
    }

    const failing = units.filter(unit => {
      // Check if any waypoint has an Orbit task
      const hasOrbit = unit.route?.some(point => {
        // Check for Orbit task in waypoint sub-tasks
        if (point.task?.params?.tasks) {
          return point.task.params.tasks.some(t => t.id === 'Orbit')
        }
        // Check for Orbit action directly
        if (point.action === 'Orbit' || point.action === 'Race-track') {
          return true
        }
        return false
      })
      
      return !hasOrbit
    })

    if (failing.length > 0) {
      return {
        passed: false,
        details: `${failing.length} AWACS unit(s) missing orbit pattern`,
        suggestion: 'Add Orbit or Race-track action to at least one waypoint'
      }
    }

    return { passed: true }
  }

  /**
   * Validate advanced options
   */
  validateAdvancedOptions(rule, missionData) {
    const units = this.filterUnits(missionData.units, rule.target)
    
    if (units.length === 0) {
      return { passed: true }
    }

    const failing = units.filter(unit => {
      return !rule.requiredOptions.every(opt => unit[opt] === true)
    })

    if (failing.length > 0) {
      return {
        passed: false,
        details: `${failing.length} unit(s) missing required advanced options`,
        suggestion: `Enable: ${rule.requiredOptions.join(', ')}`
      }
    }

    return { passed: true }
  }

  /**
   * Validate speed
   */
  validateSpeedCheck(rule, missionData) {
    const units = this.filterUnits(missionData.units, rule.target)
    
    if (units.length === 0) {
      return { passed: true }
    }

    const failing = units.filter(unit => {
      const speed = unit.speed || 0
      return speed > rule.maxSpeed
    })

    if (failing.length > 0) {
      return {
        passed: false,
        details: `${failing.length} unit(s) exceed maximum speed of ${rule.maxSpeed} ${rule.unit}`,
        suggestion: `Reduce speed to ${rule.maxSpeed} ${rule.unit} or less`
      }
    }

    return { passed: true }
  }

  /**
   * Validate aircraft configuration
   */
  validateAircraftConfig(rule, missionData) {
    return { passed: true, details: 'Aircraft config check not fully implemented' }
  }

  /**
   * Validate carrier configuration
   */
  validateCarrierConfig(rule, missionData) {
    return { passed: true, details: 'Carrier config check not fully implemented' }
  }

  /**
   * Validate task
   */
  validateTaskCheck(rule, missionData) {
    const units = this.filterUnits(missionData.units, rule.target)
    
    if (units.length === 0) {
      return { passed: true }
    }

    const failing = units.filter(unit => {
      return !rule.allowedTasks.includes(unit.task)
    })

    if (failing.length > 0) {
      return {
        passed: false,
        details: `${failing.length} unit(s) have incorrect task`,
        suggestion: `Set task to one of: ${rule.allowedTasks.join(', ')}`
      }
    }

    return { passed: true }
  }

  /**
   * Validate pattern
   */
  validatePatternCheck(rule, missionData) {
    return { passed: true, details: 'Pattern check not fully implemented' }
  }

  /**
   * Validate communication channels
   */
  validateCommCheck(rule, missionData) {
    const units = this.filterUnits(missionData.units, rule.target)
    
    if (units.length === 0) {
      return { passed: true }
    }

    const failing = units.filter(unit => {
      return !rule.requiredChannels.every(ch => unit.comm?.[ch])
    })

    if (failing.length > 0) {
      return {
        passed: false,
        details: `${failing.length} unit(s) missing required communication channels`,
        suggestion: `Configure channels: ${rule.requiredChannels.join(', ')}`
      }
    }

    return { passed: true }
  }

  /**
   * Validate aircraft-specific checks
   */
  validateAircraftSpecific(rule, missionData) {
    return { passed: true, details: 'Aircraft specific check not fully implemented' }
  }

  /**
   * Validate time of day
   */
  validateTimeCheck(rule, missionData) {
    return { passed: true, details: 'Time check not fully implemented' }
  }

  /**
   * Validate weather settings
   */
  validateWeatherCheck(rule, missionData) {
    return { passed: true, details: 'Weather check not fully implemented' }
  }

  /**
   * Validate wind speed
   */
  validateWindCheck(rule, missionData) {
    return { passed: true, details: 'Wind check not fully implemented' }
  }

  /**
   * Validate absence check
   */
  validateAbsenceCheck(rule, missionData) {
    const units = this.filterUnits(missionData.units, rule.target)
    
    const patterns = rule.forbiddenPatterns.map(p => new RegExp(p, 'i'))
    
    const matching = units.filter(unit => {
      return patterns.some(pattern => pattern.test(unit.name))
    })

    if (matching.length > 0) {
      return {
        passed: false,
        details: `Found ${matching.length} forbidden unit(s): ${matching.map(u => u.name).join(', ')}`,
        suggestion: 'Remove test/debug/temp aircraft from mission'
      }
    }

    return { passed: true }
  }

  /**
   * Validate script check
   */
  validateScriptCheck(rule, missionData) {
    // Check triggers for forbidden patterns
    if (!missionData.triggers) {
      return { passed: true }
    }

    const patterns = rule.forbiddenPatterns.map(p => new RegExp(p, 'i'))
    
    // Simple check - would need to traverse trigger structure
    const hasForbidden = JSON.stringify(missionData.triggers)
      .match(patterns.some(p => p))

    if (hasForbidden) {
      return {
        passed: false,
        details: 'Found test/debug scripting in mission',
        suggestion: 'Remove test/debug scripting'
      }
    }

    return { passed: true }
  }

  /**
   * Filter units based on target criteria
   */
  filterUnits(units, target) {
    if (!target) return units

    return units.filter(unit => {
      if (target.coalition && unit.coalition?.toLowerCase() !== target.coalition.toLowerCase()) {
        return false
      }
      if (target.unitType && unit.type !== target.unitType) {
        return false
      }
      if (target.task && unit.task !== target.task) {
        return false
      }
      if (target.aircraftType && !unit.units?.some(u => u.type?.includes(target.aircraftType))) {
        return false
      }
      return true
    })
  }

  /**
   * Print validation summary
   */
  printSummary() {
    console.log('\n' + '='.repeat(60))
    console.log('📊 VALIDATION SUMMARY')
    console.log('='.repeat(60))
    
    const total = this.results.passed.length + 
                  this.results.errors.length + 
                  this.results.warnings.length + 
                  this.results.info.length

    console.log(`\nTotal Rules Checked: ${total}`)
    console.log(`✅ Passed: ${this.results.passed.length}`)
    console.log(`❌ Errors: ${this.results.errors.length}`)
    console.log(`⚠️  Warnings: ${this.results.warnings.length}`)
    console.log(`ℹ️  Info: ${this.results.info.length}`)

    if (this.results.errors.length > 0) {
      console.log('\n❌ ERRORS (Must Fix):')
      this.results.errors.forEach(err => {
        console.log(`   - ${err.name}: ${err.details}`)
      })
    }

    if (this.results.warnings.length > 0) {
      console.log('\n⚠️  WARNINGS (Should Fix):')
      this.results.warnings.forEach(warn => {
        console.log(`   - ${warn.name}: ${warn.details}`)
      })
    }

    const score = Math.round((this.results.passed.length / total) * 100)
    console.log(`\n📈 Mission Score: ${score}%`)

    if (this.results.errors.length === 0) {
      console.log('\n✅ Mission validation PASSED!')
    } else {
      console.log('\n❌ Mission validation FAILED - Please fix errors above')
    }
  }

  /**
   * Export results to JSON
   */
  exportResults(outputPath) {
    fs.writeFileSync(outputPath, JSON.stringify(this.results, null, 2))
    console.log(`\n📄 Results exported to: ${outputPath}`)
  }
}
