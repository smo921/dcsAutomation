import { MissionValidator } from '../../../mission-validator/src/validator.js'
import path from 'path'

/**
 * Mission Editor Integration - Validator Service
 * Provides real-time validation as users edit missions
 */
export class MissionEditorValidator {
  constructor(editorInstance) {
    this.editor = editorInstance
    this.validator = null
    this.lastValidation = null
    this.validationListeners = []
    this.autoValidateEnabled = true
    this.validationDebounce = 1000 // ms
    this.debounceTimer = null
  }

  /**
   * Initialize validator with current mission
   */
  initialize(configPath = null) {
    try {
      this.validator = new MissionValidator(configPath)
      console.log('[Validator] Initialized')
      return true
    } catch (error) {
      console.error('[Validator] Initialization failed:', error.message)
      return false
    }
  }

  /**
   * Run validation on current mission
   */
  async validate(dcsInstallPath = null) {
    if (!this.validator) {
      console.error('[Validator] Not initialized')
      return null
    }

    try {
      // Get current mission data from editor
      const missionData = this.editor.getMissionData()
      
      if (!missionData) {
        console.error('[Validator] No mission data available')
        return null
      }

      // Run validation
      const results = await this.validator.validateMissionData(missionData, dcsInstallPath)
      this.lastValidation = results

      // Notify listeners
      this.notifyListeners(results)

      return results
    } catch (error) {
      console.error('[Validator] Validation error:', error.message)
      return {
        error: error.message,
        timestamp: Date.now()
      }
    }
  }

  /**
   * Trigger validation with debounce
   */
  triggerValidation(dcsInstallPath = null) {
    if (!this.autoValidateEnabled) return

    // Clear existing timer
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    // Set new timer
    this.debounceTimer = setTimeout(() => {
      this.validate(dcsInstallPath)
    }, this.validationDebounce)
  }

  /**
   * Add validation result listener
   */
  onValidation(listener) {
    this.validationListeners.push(listener)
  }

  /**
   * Remove validation result listener
   */
  offValidation(listener) {
    const index = this.validationListeners.indexOf(listener)
    if (index > -1) {
      this.validationListeners.splice(index, 1)
    }
  }

  /**
   * Notify all listeners
   */
  notifyListeners(results) {
    for (const listener of this.validationListeners) {
      try {
        listener(results)
      } catch (error) {
        console.error('[Validator] Listener error:', error.message)
      }
    }
  }

  /**
   * Enable/disable auto-validation
   */
  setAutoValidate(enabled) {
    this.autoValidateEnabled = enabled
    if (!enabled && this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
  }

  /**
   * Get last validation results
   */
  getLastValidation() {
    return this.lastValidation
  }

  /**
   * Get validation summary
   */
  getSummary() {
    if (!this.lastValidation) return null

    return {
      passed: this.lastValidation.passed?.length || 0,
      errors: this.lastValidation.errors?.length || 0,
      warnings: this.lastValidation.warnings?.length || 0,
      info: this.lastValidation.info?.length || 0,
      timestamp: this.lastValidation.timestamp
    }
  }

  /**
   * Validate specific unit
   */
  validateUnit(unit) {
    if (!this.validator) return null

    const results = []
    
    // Run unit-specific rules
    for (const category of this.validator.config.categories) {
      for (const rule of category.rules) {
        if (this.ruleAppliesToUnit(rule, unit)) {
          const result = this.validator.validateRule(rule, { units: [unit] })
          results.push({
            ruleId: rule.id,
            name: rule.name,
            passed: result.passed,
            details: result.details,
            severity: rule.severity
          })
        }
      }
    }

    return results
  }

  /**
   * Check if rule applies to unit
   */
  ruleAppliesToUnit(rule, unit) {
    if (!rule.target) return true

    const target = rule.target
    
    if (target.coalition && unit.coalition !== target.coalition) {
      return false
    }
    if (target.unitType && unit.type !== target.unitType) {
      return false
    }
    if (target.task && unit.task !== target.task) {
      return false
    }

    return true
  }

  /**
   * Export validation report
   */
  exportReport(format = 'json', outputPath) {
    if (!this.lastValidation) {
      throw new Error('No validation results to export')
    }

    if (format === 'json') {
      const fs = await import('fs')
      fs.writeFileSync(outputPath, JSON.stringify(this.lastValidation, null, 2))
      return outputPath
    }

    // Add more formats as needed (HTML, markdown, etc.)
    throw new Error(`Unsupported export format: ${format}`)
  }
}

/**
 * Extend MissionValidator to support direct mission data validation
 */
MissionValidator.prototype.validateMissionData = async function(missionData, dcsInstallPath = null) {
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
