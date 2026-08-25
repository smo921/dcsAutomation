import { MissionValidator } from '../src/validator.js'
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

/**
 * Test suite for MissionValidator
 */
async function runTests() {
  console.log('🧪 Mission Validator Test Suite')
  console.log('=' .repeat(60))

  const tests = [
    testConfigLoading,
    testValidatorInitialization,
    testRuleTypes,
    testUnitFiltering,
    testSeverityLevels
  ]

  let passed = 0
  let failed = 0

  for (const test of tests) {
    try {
      await test()
      passed++
      console.log(`✅ ${test.name}`)
    } catch (error) {
      failed++
      console.log(`❌ ${test.name}`)
      console.log(`   Error: ${error.message}`)
    }
  }

  console.log('\n' + '='.repeat(60))
  console.log(`Results: ${passed} passed, ${failed} failed`)
  
  process.exit(failed > 0 ? 1 : 0)
}

/**
 * Test: Configuration Loading
 */
async function testConfigLoading() {
  const configPath = path.join(__dirname, '../mission-checklist-config.json')
  
  if (!fs.existsSync(configPath)) {
    throw new Error('Config file not found')
  }

  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'))
  
  if (!config.version) {
    throw new Error('Config missing version')
  }

  if (!config.categories || config.categories.length === 0) {
    throw new Error('Config missing categories')
  }

  console.log(`   Loaded config v${config.version} with ${config.categories.length} categories`)
}

/**
 * Test: Validator Initialization
 */
async function testValidatorInitialization() {
  const configPath = path.join(__dirname, '../mission-checklist-config.json')
  const validator = new MissionValidator(configPath)

  if (!validator.config) {
    throw new Error('Validator failed to load config')
  }

  if (!validator.results) {
    throw new Error('Validator results not initialized')
  }

  console.log('   Validator initialized successfully')
}

/**
 * Test: Rule Types
 */
async function testRuleTypes() {
  const configPath = path.join(__dirname, '../mission-checklist-config.json')
  const validator = new MissionValidator(configPath)

  const ruleTypes = new Set()
  
  for (const category of validator.config.categories) {
    for (const rule of category.rules) {
      ruleTypes.add(rule.type)
    }
  }

  const expectedTypes = [
    'naming_pattern',
    'property_check',
    'frequency_check',
    'altitude_check',
    'waypoint_count',
    'speed_check',
    'task_check',
    'absence_check'
  ]

  for (const type of expectedTypes) {
    if (!ruleTypes.has(type)) {
      throw new Error(`Missing rule type: ${type}`)
    }
  }

  console.log(`   Found ${ruleTypes.size} rule types`)
}

/**
 * Test: Unit Filtering
 */
async function testUnitFiltering() {
  const configPath = path.join(__dirname, '../mission-checklist-config.json')
  const validator = new MissionValidator(configPath)

  const mockUnits = [
    { name: 'BLUE-1', coalition: 'Blue', type: 'plane', task: 'CAP' },
    { name: 'BLUE-2', coalition: 'Blue', type: 'helicopter', task: 'Strike' },
    { name: 'RED-1', coalition: 'Red', type: 'plane', task: 'CAP' },
    { name: 'Test-Aircraft', coalition: 'Blue', type: 'plane', task: 'SEAD' }
  ]

  // Test coalition filter
  const blueUnits = validator.filterUnits(mockUnits, { coalition: 'blue' })
  if (blueUnits.length !== 3) {
    throw new Error(`Expected 3 blue units, got ${blueUnits.length}`)
  }

  // Test unit type filter
  const planes = validator.filterUnits(mockUnits, { unitType: 'plane' })
  if (planes.length !== 3) {
    throw new Error(`Expected 3 planes, got ${planes.length}`)
  }

  // Test task filter
  const capUnits = validator.filterUnits(mockUnits, { task: 'CAP' })
  if (capUnits.length !== 2) {
    throw new Error(`Expected 2 CAP units, got ${capUnits.length}`)
  }

  console.log('   Unit filtering working correctly')
}

/**
 * Test: Severity Levels
 */
async function testSeverityLevels() {
  const configPath = path.join(__dirname, '../mission-checklist-config.json')
  const validator = new MissionValidator(configPath)

  const severityLevels = validator.config.severityLevels
  
  const expectedSeverities = ['critical', 'error', 'warning', 'info']
  
  for (const severity of expectedSeverities) {
    if (!severityLevels[severity]) {
      throw new Error(`Missing severity level: ${severity}`)
    }
    
    if (severityLevels[severity].weight === undefined) {
      throw new Error(`Severity ${severity} missing weight`)
    }
  }

  console.log('   All severity levels defined')
}

// Run tests
runTests().catch(error => {
  console.error('Test suite failed:', error)
  process.exit(1)
})
