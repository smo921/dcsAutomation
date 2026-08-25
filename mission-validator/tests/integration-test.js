import { MissionValidator } from '../src/validator.js'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

/**
 * Integration test with mock mission data
 */
async function runIntegrationTests() {
  console.log('🧪 Mission Validator Integration Tests')
  console.log('=' .repeat(60))

  const configPath = path.join(__dirname, '../mission-checklist-config.json')
  const validator = new MissionValidator(configPath)

  // Mock mission data with various issues
  const mockMission = {
    theater: 'Caucasus',
    units: [
      {
        name: 'BLUE-1',
        coalition: 'Blue',
        type: 'plane',
        task: 'CAP',
        frequency: 135.00,
        altitude: 20000,
        controlled: false,
        comm: { UHF: '305.00', VHF: 'Mission' },
        route: [{ x: 0, y: 0, alt: 20000 }]
      },
      {
        name: 'BadName-1',  // Should fail naming rule
        coalition: 'Blue',
        type: 'plane',
        task: 'SEAD',
        frequency: 130.00,  // Wrong frequency
        altitude: 15000,
        controlled: false,
        comm: { UHF: '305.00' },  // Missing VHF
        route: [{ x: 0, y: 0, alt: 15000 }]
      },
      {
        name: 'RED-1',
        coalition: 'Red',
        type: 'plane',
        task: 'CAP',
        unlimitedFuel: true,
        restrictAfterburner: true,
        route: [
          { x: 0, y: 0 },
          { x: 1000, y: 0 },
          { x: 1000, y: 1000 },
          { x: 0, y: 1000 }
        ]
      },
      {
        name: 'Tanker-1',
        coalition: 'Blue',
        type: 'plane',
        task: 'Tanker',
        altitude: 20000,
        speed: 350,  // Too fast
        lateActivation: true,
        route: [{ x: 0, y: 0 }]
      },
      {
        name: 'AWACS-1',
        coalition: 'Blue',
        type: 'plane',
        task: 'AWACS',
        frequency: 305.00,
        altitude: 35000,
        unlimitedFuel: true,
        invincible: true,
        invisible: true,
        route: [
          { x: 0, y: 0, action: 'Orbit' },
          { x: 1000, y: 0 }
        ]
      },
      {
        name: 'Test-Aircraft',  // Should fail cleanup rule
        coalition: 'Blue',
        type: 'plane',
        task: 'Strike'
      }
    ],
    triggers: {
      zones: []
    }
  }

  const tests = [
    {
      name: 'Naming Pattern Validation',
      ruleId: 'naming-001',
      expectedFailures: 1,
      description: 'Should detect improperly named BLUE aircraft'
    },
    {
      name: 'Frequency Validation',
      ruleId: 'blue-003',
      expectedFailures: 1,
      description: 'Should detect wrong SEAD frequency'
    },
    {
      name: 'Speed Validation',
      ruleId: 'tanker-002',
      expectedFailures: 1,
      description: 'Should detect tanker exceeding max speed'
    },
    {
      name: 'Cleanup Validation',
      ruleId: 'cleanup-001',
      expectedFailures: 1,
      description: 'Should detect test aircraft'
    }
  ]

  let passed = 0
  let failed = 0

  console.log('\n📋 Running validation on mock mission...\n')
  
  // Run full validation
  const results = await validator.validateMissionData(mockMission)

  console.log('\n' + '='.repeat(60))
  console.log('📊 Test Results\n')

  for (const test of tests) {
    const failures = results.errors.filter(e => e.ruleId === test.ruleId)
    const warnings = results.warnings.filter(w => w.ruleId === test.ruleId)
    const totalFailures = failures.length + warnings.length

    if (totalFailures === test.expectedFailures) {
      console.log(`✅ ${test.name}`)
      console.log(`   ${test.description}`)
      console.log(`   Expected: ${test.expectedFailures} failure(s), Got: ${totalFailures}`)
      passed++
    } else {
      console.log(`❌ ${test.name}`)
      console.log(`   ${test.description}`)
      console.log(`   Expected: ${test.expectedFailures} failure(s), Got: ${totalFailures}`)
      failed++
    }
  }

  console.log('\n' + '='.repeat(60))
  console.log(`Results: ${passed} passed, ${failed} failed\n`)

  if (failed > 0) {
    console.log('Failed tests details:')
    for (const test of tests) {
      const failures = [...results.errors.filter(e => e.ruleId === test.ruleId),
                       ...results.warnings.filter(w => w.ruleId === test.ruleId)]
      if (failures.length > 0) {
        console.log(`\n${test.name}:`)
        failures.forEach(f => {
          console.log(`  - ${f.details}`)
        })
      }
    }
  }

  process.exit(failed > 0 ? 1 : 0)
}

runIntegrationTests().catch(error => {
  console.error('Test suite failed:', error)
  process.exit(1)
})
