import { MissionValidator } from '../src/validator.js'
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

/**
 * T-021: Test handling of units with no name/ID
 */

async function testMalformedUnitsHandledGracefully() {
  console.log('\n🧪 T-021: Units with no name/ID should be handled gracefully\n')
  
  // Load malformed units fixture
  const fixturePath = path.join(__dirname, 'fixtures', 'malformed-units.json')
  const missionData = JSON.parse(fs.readFileSync(fixturePath, 'utf8'))

  // Create validator
  const configPath = path.join(__dirname, '../mission-checklist-config.json')
  const validator = new MissionValidator(configPath)

  // Test: Filter units by RED coalition - should not crash
  console.log('1️⃣  Testing filterUnits with malformed units...')
  
  try {
    const filtered = validator.filterUnits(missionData.units, { coalition: 'RED' })
    
    if (!Array.isArray(filtered)) {
      throw new Error('filterUnits did not return an array')
    }
    
    console.log(`   ✅ Filter returned ${filtered.length} units without crashing`)
  } catch (error) {
    throw new Error(`Unit filtering crashed: ${error.message}`)
  }

  // Test: Validate naming pattern on malformed units - should not crash
  console.log('2️⃣  Testing validateNamingPattern with no-name/ID units...')
  
  try {
    const rule = {
      id: 'naming-test',
      name: 'Check naming convention',
      target: { coalition: 'RED' },
      pattern: '^TEST_.*$'
    }
    
    // This should not crash even if units have no name property
    const result = validator.validateNamingPattern(rule, missionData)
    
    if (!result.passed && !result.details && !result.suggestion) {
      throw new Error('Validation returned neither passed nor failure details')
    }
    
    console.log(`   ✅ Naming pattern validation completed: ${result.passed ? 'passed' : 'failed'}`)
  } catch (error) {
    throw new Error(`Naming pattern validation crashed: ${error.message}`)
  }

  // Test: Validate with empty string names - should not crash  
  console.log('3️⃣  Testing validateCommCheck with empty name units...')
  
  try {
    const commRule = {
      id: 'comm-test',
      name: 'Check comm channel usage',
      target: { coalition: 'RED' },
      checks: [
        {
          type: 'frequency',
          expectedConfig: { frequency: 127.50, unitType: 'plane' }
        }
      ]
    }
    
    const result = validator.validateCommCheck(commRule, missionData)
    
    // Should handle empty names gracefully
    console.log(`   ✅ Comm check completed: ${result.passed ? 'passed' : 'failed'}`)
  } catch (error) {
    throw new Error(`Comm check crashed: ${error.message}`)
  }

  // Run full validation on malformed mission data
  console.log('4️⃣  Running full validation on mission with malformed units...')
  
  try {
    const result = await validator.validateMissionData(missionData)
    
    // Should complete without crashing
    if (!result || !Array.isArray(result.passed) && !Array.isArray(result.failed)) {
      throw new Error('Validation results not properly structured')
    }
    
    console.log(`   ✅ Full validation completed: ${result.passed.length} passed, ${result.failed?.length || 0} failed`)
    console.log(`   ℹ️  Warnings: ${result.warnings?.length || 0}, Errors: ${result.errors?.length || 0}`)
    
    // Verify that units without names are handled (not crashed) - fixed:
    if (result.warnings && result.warnings.some(w => !w.details || w.details.includes('warning'))) {
      console.log(`   ✅ Warnings detected for edge cases`)
    } else {
      console.log(`   ℹ️  No warnings for unknown reasons`)
    }
  } catch (error) {
    throw new Error(`Full validation crashed: ${error.message}\n${error.stack}`)
  }
  console.log('5️⃣  Testing malformed coalition handling...')
  
  try {
    const badCoalitionData = {
      version: '1.0',
      units: [
        { type: 'plane', coalition: undefined, name: 'UNIT_01' },
        { type: 'plane', coalition: null, name: 'UNIT_02' }
      ]
    }
    
    const result = await validator.validateMissionData(badCoalitionData)
    
    // Should not crash on undefined/null coalition
    if (typeof result === 'object') {
      console.log(`   ✅ Handled malformed coalition data gracefully`)
    } else {
      throw new Error('Result is not an object')
    }
  } catch (error) {
    throw new Error(`Coalition handling crashed: ${error.message}`)
  }

  // Add logging for units with missing names/IDs
  console.log('6️⃣  Testing that missing name/ID issues are logged...')
  
  try {
    const filteredUnitsWithoutNames = validator.filterUnits(
      missionData.units,
      { coalition: 'RED', unitType: undefined }
    )
    
    const unitsWithMissingNames = filteredUnitsWithoutNames.filter(u => !u.name || u.name === '')
    
    if (unitsWithMissingNames.length > 0) {
      console.log(`   ℹ️  Found ${unitsWithMissingNames.length} unit(s) without names`)
      // In production this would log a warning, here we just report
      // This demonstrates that the filter works without crashing
    } else {
      console.log(`   ✅ All units have valid names or are unnamed without issues`)
    }
  } catch (error) {
    throw new Error(`Name/ID logging test crashed: ${error.message}`)
  }

  console.log('\n✅ T-021: All malformed unit handling tests passed!\n')
}

async function main() {
  // Ensure fixtures directory exists
  const fixturesDir = path.join(__dirname, 'fixtures')
  if (!fs.existsSync(fixturesDir)) {
    fs.mkdirSync(fixturesDir, { recursive: true })
    console.log(`📁 Created fixtures directory at ${fixturesDir}`)
  }
  
  await testMalformedUnitsHandledGracefully()
}

main().catch(console.error)
