#!/usr/bin/env node

import { fileURLToPath } from 'url'
import path from 'path'
import { MissionValidator } from './validator.js'
import fs from 'fs'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const validatorDir = path.join(__dirname, '../')
const defaultConfigPath = path.join(validatorDir, 'mission-checklist-config.json')
const helpOutput = `\nDCS Mission Validator - Validate DCS missions against checklist rules

Usage:
  dcs-validator <file.miz> [options]

Options:
  --help, -h                    Show this help message
  --version, -v                 Show version number
  --checklist, -c               Generate validation checklist
  --validate                    Validate against external rules

Examples:
  dcs-validator missions/test1.miz
  dcs-validator test1.miz -c custom-config.json

`

/**
 * CLI entry point for mission validation
 */
async function main() {
  const args = process.argv.slice(2)
  
  // Parse flags
  let helpRequested = false
  let versionRequested = false
  let checkListRequested = false
  let validateRequested = false
  let mizPath = null

  // Always show help if no arguments provided
  if (args.length === 0) {
    console.log(helpOutput.replace('>>>', '🔍 DCS Mission Validator - Validate missions against checklist rules\n'))
    process.exit(0)
  }

  // Parse command line arguments
  for (let i = 0; i < args.length; i++) {
    const arg = args[i]
    
    if (arg === '-h' || arg === '--help') {
      helpRequested = true
    } else if (arg === '-v' || arg === '--version') {
      versionRequested = true
    } else if (arg === '--validate' || arg === 'valid') {
      validateRequested = true
    } else if (arg === '-c' || arg === '--config' || arg === '--checklist') {
      const configArg = args[++i]
      configPath = configArg?.replace(/^["']|["']$/g, '')
      checkListRequested = true
    } else if (!arg.startsWith('-')) {
      mizPath = arg
    }
  }

  // Show version
  if (versionRequested) {
    const pkgPath = path.join(__dirname, '../package.json')
    if (fs.existsSync(pkgPath)) {
      const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'))
      console.log(`DCS Mission Validator v${pkg.version}`)
    } else {
      console.log('DCS Mission Validator v1.0.0')
    }
    process.exit(0)
  }

  // Show help if requested
  if (helpRequested) {
    console.log(helpOutput)
    process.exit(0)
  }

  // If validation explicitly requested but no MIZ file provided
  if (validateRequested && !mizPath) {
    console.log('\n✋ No mission file specified. Skipping validation.')
    console.log(helpOutput)
    process.exit(0)
  }
  
  // Load config if not provided - always use our fixed location
  const actualConfigPath = defaultConfigPath
  
  let validator = null
  try {
    // Ensure config exists before using it
    if (!fs.existsSync(actualConfigPath)) {
      console.log('\n⚠️  Configuration file not found.')
      console.log('Run with --checklist to generate rules first.\n')
      process.exit(1)
    }

    // Create validator with explicit config path  
    validator = new MissionValidator(actualConfigPath)
    
    // Log which config was loaded
    console.log(`📂 Loaded from: ${path.basename(actualConfigPath)}`)

  } catch (error) {
    console.error(`❌ Validation failed: ${error.message}`)
    process.exit(2)
  }

  try {
    // Always have mizPath from --validate or positional argument check
    if (!mizPath) {
      // No mission file provided, exit gracefully  
      process.exit(0)
    } else {
      
      console.log(`\n🔍 Validating: ${path.basename(mizPath)}`)
      console.log('=' .repeat(70))

      const results = await validator.validateMizFile(mizPath, null)
      
      // Export results to JSON
      const outputPathDir = path.join(path.dirname(mizPath), 'validation-results')
      if (!fs.existsSync(outputPathDir)) {
        fs.mkdirSync(outputPathDir, { recursive: true })
      }
      
      const timestamp = new Date().toISOString().replace(/[T:.-]/g, '-')
      const outputPath = path.join(outputPathDir, `results-${timestamp}.json`)
      validator.exportResults(outputPath)

    } 
   
  } catch (error) {
    console.error(`\n❌ Validation failed: ${error.message}`)
    process.exit(2)
  }
}

main()
