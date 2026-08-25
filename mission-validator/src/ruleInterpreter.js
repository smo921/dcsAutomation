import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

/**
 * Rule Interpreter - Loads and interprets validation rules from JSON
 * 
 * This allows rules to be defined externally and interpreted at runtime
 * without hardcoding validation logic in the validator itself.
 */
export class RuleInterpreter {
  constructor() {
    this.ruleHandlers = new Map()
    this.registerBuiltInHandlers()
  }

  /**
   * Register built-in rule handlers
   */
  registerBuiltInHandlers() {
    // Naming pattern handler
    this.registerHandler('naming_pattern', (rule, units) => {
      const regex = new RegExp(rule.pattern)
      const failing = units.filter(unit => !regex.test(unit.name))
      
      if (failing.length > 0) {
        return {
          passed: false,
          details: `${failing.length} unit(s) don't match pattern: ${failing.map(u => u.name).join(', ')}`,
          suggestion: `Rename units to match pattern: ${rule.pattern}`
        }
      }
      return { passed: true }
    })

    // Frequency check handler
    this.registerHandler('frequency_check', (rule, units) => {
      const tolerance = rule.tolerance || 0.01
      const failing = units.filter(unit => {
        if (!unit.frequency) return true
        return Math.abs(unit.frequency - rule.expectedFrequency) > tolerance
      })

      if (failing.length > 0) {
        return {
          passed: false,
          details: `${failing.length} unit(s) have incorrect frequency`,
          suggestion: `Set frequency to ${rule.expectedFrequency} MHz`
        }
      }
      return { passed: true }
    })

    // Altitude check handler (with unit conversion)
    this.registerHandler('altitude_check', (rule, units) => {
      const conversionFactor = rule.unit === 'feet' ? 3.28084 : 1
      let failing = []

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
      } else if (rule.maxAltitude !== undefined) {
        const maxAltMeters = rule.maxAltitude / conversionFactor
        
        failing = units.filter(unit => {
          const alt = unit.altitude || 0
          return alt > maxAltMeters
        })
      }

      if (failing.length > 0) {
        const expected = rule.expectedAltitude !== undefined 
          ? `${rule.expectedAltitude} ${rule.unit}`
          : rule.minAltitude !== undefined
            ? `above ${rule.minAltitude} ${rule.unit}`
            : `below ${rule.maxAltitude} ${rule.unit}`
        
        return {
          passed: false,
          details: `${failing.length} unit(s) have incorrect altitude`,
          suggestion: `Set altitude to ${expected}`
        }
      }
      return { passed: true }
    })

    // Property check handler
    this.registerHandler('property_check', (rule, units) => {
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
    })

    // AWACS orbit check handler
    this.registerHandler('awacs_orbit', (rule, units) => {
      const failing = units.filter(unit => {
        const hasOrbit = unit.route?.some(point => {
          if (point.task?.params?.tasks) {
            return point.task.params.tasks.some(t => t.id === 'Orbit')
          }
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
    })

    // Waypoint count check handler
    this.registerHandler('waypoint_count', (rule, units) => {
      let failing = []
      
      if (rule.exactCount !== undefined) {
        failing = units.filter(unit => {
          const count = unit.route?.length || 0
          return count !== rule.exactCount
        })
      } else if (rule.minCount !== undefined) {
        failing = units.filter(unit => {
          const count = unit.route?.length || 0
          return count < rule.minCount
        })
      } else if (rule.maxCount !== undefined) {
        failing = units.filter(unit => {
          const count = unit.route?.length || 0
          return count > rule.maxCount
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
    })

    // Speed check handler
    this.registerHandler('speed_check', (rule, units) => {
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
    })

    // Task check handler
    this.registerHandler('task_check', (rule, units) => {
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
    })

    // Advanced options check handler
    this.registerHandler('advanced_options', (rule, units) => {
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
    })

    // COMM check handler
    this.registerHandler('comm_check', (rule, units) => {
      const failing = units.filter(unit => {
        return !rule.requiredChannels.every(ch => {
          if (ch === 'UHF') return unit.frequency || unit.comm?.UHF
          if (ch === 'VHF') return unit.comm?.VHF
          return false
        })
      })

      if (failing.length > 0) {
        return {
          passed: false,
          details: `${failing.length} unit(s) missing required communication channels`,
          suggestion: `Configure channels: ${rule.requiredChannels.join(', ')}`
        }
      }
      return { passed: true }
    })

    // Absence check handler
    this.registerHandler('absence_check', (rule, units) => {
      const patterns = rule.forbiddenPatterns.map(p => new RegExp(p, 'i'))
      const matching = units.filter(unit => {
        return patterns.some(pattern => pattern.test(unit.name))
      })

      if (matching.length > 0) {
        return {
          passed: false,
          details: `Found ${matching.length} forbidden unit(s): ${matching.map(u => u.name).join(', ')}`,
          suggestion: rule.suggestion || 'Remove forbidden units'
        }
      }
      return { passed: true }
    })
  }

  /**
   * Register a custom rule handler
   */
  registerHandler(ruleType, handler) {
    this.ruleHandlers.set(ruleType, handler)
  }

  /**
   * Load rules from a JSON file
   */
  loadRulesFromFile(filePath) {
    const content = fs.readFileSync(filePath, 'utf8')
    const config = JSON.parse(content)
    return this.loadRulesFromConfig(config)
  }

  /**
   * Load rules from a config object
   */
  loadRulesFromConfig(config) {
    const rules = []
    
    for (const category of config.categories) {
      for (const ruleDef of category.rules) {
        const rule = {
          id: ruleDef.id,
          name: ruleDef.name,
          description: ruleDef.description,
          severity: ruleDef.severity,
          category: category.id,
          categoryName: category.name,
          type: ruleDef.type,
          target: ruleDef.target,
          params: ruleDef  // All other properties become params
        }
        
        rules.push(rule)
      }
    }
    
    return rules
  }

  /**
   * Interpret and execute a rule
   */
  interpret(rule, units) {
    const handler = this.ruleHandlers.get(rule.type)
    
    if (!handler) {
      console.warn(`Unknown rule type: ${rule.type}`)
      return {
        passed: true,
        warning: `No handler for rule type: ${rule.type}`
      }
    }

    try {
      return handler(rule.params, units)
    } catch (error) {
      return {
        passed: false,
        error: error.message
      }
    }
  }

  /**
   * Validate all rules against units
   */
  validateAll(rules, units) {
    const results = {
      passed: [],
      failed: [],
      warnings: [],
      info: [],
      errors: []
    }

    for (const rule of rules) {
      const filteredUnits = this.filterUnits(units, rule.target)
      const result = this.interpret(rule, filteredUnits)

      const outcome = {
        ruleId: rule.id,
        name: rule.name,
        category: rule.category,
        categoryName: rule.categoryName,
        ...result
      }

      if (result.passed) {
        results.passed.push(outcome)
      } else {
        if (rule.severity === 'error') {
          results.errors.push(outcome)
        } else if (rule.severity === 'warning') {
          results.warnings.push(outcome)
        } else if (rule.severity === 'info') {
          results.info.push(outcome)
        } else {
          results.failed.push(outcome)
        }
      }
    }

    return results
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
   * Create a rule from a simple definition
   * This allows users to create rules without writing code
   */
  createRule(ruleDefinition) {
    return {
      id: ruleDefinition.id,
      name: ruleDefinition.name,
      description: ruleDefinition.description,
      severity: ruleDefinition.severity || 'warning',
      type: ruleDefinition.type,
      target: ruleDefinition.target || {},
      params: ruleDefinition
    }
  }
}

/**
 * Example: Create custom rules programmatically
 */
export function createSampleRules() {
  const interpreter = new RuleInterpreter()
  
  // Create a custom rule
  const customRule = interpreter.createRule({
    id: 'custom-001',
    name: 'Custom Naming Rule',
    description: 'All BLUE fighters must start with BLUE-FIGHTER',
    severity: 'error',
    type: 'naming_pattern',
    pattern: '^BLUE-FIGHTER',
    target: {
      coalition: 'blue',
      unitType: 'plane'
    }
  })

  return [customRule]
}

export default RuleInterpreter
