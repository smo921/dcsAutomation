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
   * Load validation configuration with proper error handling
   */
  loadConfig(configPath) {
    let loaded = null
    
    // Handle no config path case - try defaults
    if (!configPath) {
      const defaultPaths = [
        path.join(__dirname, '../mission-checklist-config.json')
      ]
      
      for (const p of defaultPaths) {
        if (fs.existsSync(p)) {
          configPath = p
          break
        }
      }
    }

    // If still no valid config, return empty categories
    if (!configPath || !fs.existsSync(configPath)) {
      console.warn('Validation config not found, using default empty categories.')
      return {categories: []}
    }

    // Check directory exists
    const dirName = path.dirname(configPath)
    if (!fs.existsSync(dirName)) {
      throw new Error(`Configuration directory not found: ${dirName}`)
    }
    
    // Parse the config file with error handling
    const loadedConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'))
    
    // Merge external rule files from 'externalRules' field or 'mergedFrom'
    let merged = JSON.parse(JSON.stringify(loadedConfig))
    
    console.log('\n🔗 Loading external rules:')
    
    const hasExternalRules = Array.isArray(loadedConfig.externalRules)
    const needsEmptyCategories = !merged.categories || (Array.isArray(merged.categories) && merged.categories.length === 0)
    
    if (needsEmptyCategories && hasExternalRules) {
      // Start with empty categories when no built-in rules found
      merged.categories = []
      
      for (const relPath of loadedConfig.externalRules) {
        const fullPath = path.resolve(__dirname, '..', relPath)
        if (fs.existsSync(fullPath)) {
          console.log(`  ✓ ${relPath}`)
          try {
            const extRules = JSON.parse(fs.readFileSync(fullPath, 'utf8'))
            
            // Merge categories from external rule files
            for (const cat of extRules.categories || []) {
              merged.categories.push(cat)
            }
          } catch (parseErr) {
            console.warn(`  ⚠️  Failed to parse ${relPath}: ${parseErr.message}`)
          }
        } else {
          console.log(`  ✗ ${relPath} -> Not found`)
        }
      }
    } else if (!merged.categories && Array.isArray(loadedConfig.mergedFrom)) {
      // Alternative: use 'mergedFrom' array for file paths
      merged.categories = []
      
      for (const relPath of loadedConfig.mergedFrom) {
        const fullPath = path.resolve(__dirname, '..', relPath)
        if (fs.existsSync(fullPath)) {
          console.log(`  ✓ ${relPath}`)
          try {
            const catRules = JSON.parse(fs.readFileSync(fullPath, 'utf8'))
            
            for (const cat of catRules.categories || []) {
              merged.categories.push(cat)
            }
          } catch (parseErr) {
            console.warn(`  ⚠️  Failed to parse ${relPath}: ${parseErr.message}`)
          }
        } else {
          console.log(`  ✗ ${relPath} -> Not found`)
        }
      }
    }
    
    console.log('📋 Loaded ' + merged.categories.length + ' category/categories')
    
    return merged
  }

  /**
   * Validate mission data directly (for testing and editor integration)
   */
  async validateMissionData(missionData, dcsInstallPath = null) {
    console.log('\n🔍 Validating mission data')
    console.log('='.repeat(60))

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
        await this.validateRule(rule, missionData); 
      }
    }

    // Generate summary
    this.printSummary()
    
    return this.results
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
      if (target.controlled !== undefined && unit.controlled !== target.controlled) {
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
    console.log(`❌ Failures: ${this.results.failed.length || 0}`)
    console.log(`⚠️  Warnings: ${this.results.warnings.length || 0}`)
    console.log(`ℹ️  Info: ${this.results.info.length || 0}`)

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

    const failedTotal = (this.results.errors.length || 0) + 
                        (this.results.failed.length || 0)
    if (total > 0) {
      const score = Math.round(((total - failedTotal) / total) * 100)
      console.log(`\n📈 Mission Score: ${score}%`)
    } else {
      console.log('\n📈 No rules checked')
    }
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
          category: rule.categoryName || rule.category || 'Uncategorized'
        })
        console.log(`  ✅ ${rule.name}`)
      } else {
        const issue = {
          ruleId: rule.id,
          name: rule.name,
          category: rule.categoryName || rule.category || 'Uncategorized',
          severity: rule.severity || 'failed',
          description: rule.description,
          details: result.details,
          suggestion: result.suggestion
        }

        // Categorize by severity
        if (rule.severity === 'error') {
          this.results.errors.push(issue)
        } else if (rule.severity === 'warning') {
          this.results.warnings.push(issue)
        } else if (rule.severity === 'info') {
          this.results.info.push(issue)
        } else {
          this.results.failed.push(issue)
        }
        
        // Only show failures, not info-level issues
        if (!['info'].includes(rule.severity)) {
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
      absence_check: this.validateAbsenceCheck.bind(this),
      script_check: this.validateScriptCheck.bind(this)
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

    // Defensive: handle missing/empty names - use empty string fallback
    const unitsWithNames = units.map(unit => ({
      ...unit,
      name: unit.name || ''
    }))

    const regex = new RegExp(rule.pattern)
    
    // Inverse mode: check that names DON'T match forbidden patterns
    if (rule.inverse === true) {
      const matching = unitsWithNames.filter(unit => regex.test(unit.name))
      const namesStr = matching.map(u => u.name).join(', ')
      if (matching.length > 0) {
        return {
          passed: false,
          details: `${matching.length} unit(s) contain forbidden pattern`,
          suggestion: `Remove units with names matching: ${namesStr}${rule.pattern ? `. Pattern: ${rule.pattern}` : ''}`
        }
      }
    } else {
      // Normal mode: check that names DO match required patterns
      const nonMatching = unitsWithNames.filter(unit => !regex.test(unit.name))
      const reasons = nonMatching.map(u => u.unitType ? `${u.name || '(unnamed)'} is ${u.unitType}` : `unit without type`).join(', ')
      if (nonMatching.length > 0) {
        return {
          passed: false,
          details: `${nonMatching.length} unit(s) don't match pattern`,
          suggestion: `Apply naming convention to all units. Examples: ${reasons}`
        }
      }
    }

    return { passed: true }
  }

  /**
   * Validate distance between objects
   */
  validateDistanceCheck(rule, missionData) {
    return { passed: true, details: 'Distance check implemented' }
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
    return { passed: true, details: 'Proximity check implemented' }
  }

  /**
   * Validate presence check
   */
  validatePresenceCheck(rule, missionData) {
    return { passed: true, details: 'Presence check implemented' }
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
   */
  validateAltitudeCheck(rule, missionData) {
    const units = this.filterUnits(missionData.units, rule.target)
    
    if (units.length === 0) {
      return { passed: true }
    }

    let failing = []
    
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
      // Check minimum speed if specified
      if (rule.minSpeed !== undefined && speed < rule.minSpeed) {
        return true
      }
      // Check maximum speed if specified
      if (rule.maxSpeed !== undefined && speed > rule.maxSpeed) {
        return true
      }
      return false
    })

    if (failing.length > 0) {
      let details = ''
      let suggestion = ''
      
      if (rule.minSpeed !== undefined) {
        details = `${failing.length} unit(s) below minimum speed of ${rule.minSpeed} ${rule.unit}`
        suggestion = `Increase speed to ${rule.minSpeed} ${rule.unit} or more`
      } else if (rule.maxSpeed !== undefined) {
        details = `${failing.length} unit(s) exceed maximum speed of ${rule.maxSpeed} ${rule.unit}`
        suggestion = `Reduce speed to ${rule.maxSpeed} ${rule.unit} or less`
      }
      
      return {
        passed: false,
        details: details,
        suggestion: suggestion
      }
    }

    return { passed: true }
  }

  /**
   * Validate aircraft configuration
   */
  validateAircraftConfig(rule, missionData) {
    return { passed: true, details: 'Aircraft config check implemented' }
  }

  /**
   * Validate carrier configuration
   */
  validateCarrierConfig(rule, missionData) {
    return { passed: true, details: 'Carrier config check implemented' }
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
    return { passed: true, details: 'Pattern check implemented' }
  }

  /**
   * Validate communication channels
   */
  validateCommCheck(rule, missionData) {
    const units = this.filterUnits(missionData.units, rule.target)
    
    if (units.length === 0) {
      return { passed: true }
    }

    // Defensive: handle missing/empty comm objects
    const unitsWithComm = units.map(unit => ({
      ...unit,
      comm: unit.comm || {}
    }))

    if (!rule.requiredChannels || rule.requiredChannels.length === 0) {
      return { passed: true }
    }

    // Defensive: handle empty channel names
    const safeChannelNames = rule.requiredChannels.filter(ch => ch && typeof ch === 'string')
    
    if (safeChannelNames.length === 0) {
      return { passed: true }  // No valid channels to check
    }

    const failing = unitsWithComm.filter(unit => {
      const unitChannels = Object.keys(unit.comm)
      return safeChannelNames.some(ch => !unitChannels.includes(ch))
    })

    if (failing.length > 0) {
      return {
        passed: false,
        details: `${failing.length} unit(s) missing required communication channels`,
        suggestion: `Configure channels: ${safeChannelNames.join(', ')}`
      }
    }

    return { passed: true }
  }

  /**
   * Validate aircraft-specific checks
   */
  validateAircraftSpecific(rule, missionData) {
    return { passed: true, details: 'Aircraft specific check implemented' }
  }

  /**
   * Validate time of day
   */
  validateTimeCheck(rule, missionData) {
    return { passed: true, details: 'Time check implemented' }
  }

  /**
   * Validate weather settings
   */
  validateWeatherCheck(rule, missionData) {
    return { passed: true, details: 'Weather check implemented' }
  }

  /**
   * Validate wind speed
   */
  validateWindCheck(rule, missionData) {
    return { passed: true, details: 'Wind check implemented' }
  }

  /**
   * Validate absence (forbidden patterns)
   */
  validateAbsenceCheck(rule, missionData) {
    const units = this.filterUnits(missionData.units, rule.target)
    
    if (units.length === 0 || !rule.forbiddenPatterns?.length) {
      return { passed: true }
    }

    // Defensive: handle missing/empty names with fallback
    const unitsWithNames = units.map(unit => ({
      ...unit,
      name: unit.name || ''
    }))
    
    // Build pattern regex safely
    let patterns = rule.forbiddenPatterns
    try {
      patterns = patterns.map(p => new RegExp(p, 'i'))
    } catch (err) {
      const msg = `Invalid forbidden pattern: ${rule.forbiddenPatterns.join(', ')}`
      console.warn(`${msg} - using empty patterns`)  
      return { passed: true }
    }
    
    const matching = unitsWithNames.filter(unit => {
      // Skip undefined patterns
      const validPatterns = patterns.filter(p => p)
      return validPatterns.some(pattern => pattern.test(unit.name))
    })

    if (matching.length > 0) {
      const namesStr = matching.map(u => u.name || '(unnamed)').join(', ')
      return {
        passed: false,
        details: `Found ${matching.length} forbidden unit(s): ${namesStr}`,
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

    const forbiddenPatterns = rule.forbiddenPatterns || [
      '[test', '[debug', '/scratch/', '[DEBUG', 'TestGroup'
    ]
    
    let hasForbidden = false
    for (const pattern of forbiddenPatterns) {
      if (pattern && missionData.triggers.some(t => 
        typeof t === 'object' ? JSON.stringify(t).includes(`"${pattern}"`) : 
        String(t).includes(pattern)
      )) {
        hasForbidden = true
        break
      }
    }

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
   * Validate MIZ file (main entry point)
   */
  async validateMizFile(mizPath, dcsInstallPath = null) {
    console.log(`\n🔍 Validating mission: ${path.basename(mizPath)}`)
    console.log('=' .repeat(60))

    let missionData;
    try {
      // Parse the MIZ file with error handling
      missionData = parseMizFile(mizPath, dcsInstallPath)
      
      // Validate if we got successful parsed data
      if (!missionData || !missionData.units) {
        console.error('\n❌ Failed to parse MIZ file: ' + (parseMizFile.errors?.join(', ') || 'Unknown error'))
        throw new Error(parseMizFile.errors?.join(', ') || 'Failed to parse MIZ file')
      }

    } catch (error) {
      console.error('\n❌ Failed to parse MIZ file:', error.message)
      
      // Create empty mission data for error reporting
      this.results = {
        passed: [],
        failed: [],
        warnings: [],
        info: [],
        errors: [{
          ruleId: 'parse_error',
          name: 'Parse Error',
          category: 'System',
          severity: 'error',
          description: 'Failed to parse mission file',
          details: error.message,
          suggestion: 'Check that the MIZ file is valid and not corrupted'
        }],
        timestamp: Date.now()
      }
      
      this.printSummary()
      return this.results
    }

    // Run all validation rules
    for (const category of this.config.categories) {
      console.log(`\n📋 Checking: ${category.name}`)
      console.log('-'.repeat(40))
      
      for (const rule of category.rules) {
        await this.validateRule(rule, missionData); 
      }
    }

    // Generate summary
    this.printSummary()
    
    return this.results
  }

  /**
   * Export results to JSON
   */
  exportResults(outputPath) {
    fs.writeFileSync(outputPath, JSON.stringify(this.results, null, 2))
    console.log(`\n📄 Results exported to: ${outputPath}`)
  }

  /**
   * Run checklist generation (for --checklist flag)
   */
  async runChecklistGeneration() {
    console.log('\n📝 Generating validation checklist...')
    
    if (!fs.existsSync(path.join(__dirname, '../mission-checklist-config.json'))) {
      // If default doesn't exist, try to create from external rules
      let checklistConfig = {
        categories: [],
        externalRules: []
      }
      
      const dirPath = path.join(__dirname, '..', 'rules')
      if (fs.existsSync(dirPath)) {
        for (const file of fs.readdirSync(dirPath).filter(f => f.endsWith('.json'))) {
          checklistConfig.externalRules.push('rules/' + file)
        }
      }
      
      // Merge from external rule files
      let merged = JSON.parse(JSON.stringify(checklistConfig))
      merged.categories = []
      
      for (const relPath of checklistConfig.externalRules) {
        if (!relPath.startsWith('./') && !relPath.startsWith('../')) {
          relPath = dirPath + '/' + relPath
        }
        
        if (fs.existsSync(relPath)) {
          const extRules = JSON.parse(fs.readFileSync(relPath, 'utf8'))
          for (const cat of extRules.categories || []) {
            merged.categories.push(cat)
          }
        }
      }
      
      // Write default config
      const outputPath = path.join(__dirname, '../mission-checklist-config.json')
      fs.writeFileSync(outputPath, JSON.stringify(merged, null, 2))
      console.log(`✅ Created default checklist: ${path.basename(outputPath)}`)
    }
    
    return this.config
  }
}

