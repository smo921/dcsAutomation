#!/usr/bin/env node

import { MissionValidator } from './validator.js'
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

/**
 * CLI entry point for DCS Mission Validator
 */
async function main() {
  const args = process.argv.slice(2)
  
  // Parse command line arguments
  let mizPath = null
  let configPath = null
  let dcsPath = null
  let outputPath = null
  let help = false
  let version = false

  for (let i = 0; i < args.length; i++) {
    const arg = args[i]
    
    if (arg === '-h' || arg === '--help') {
      help = true
    } else if (arg === '-v' || arg === '--version') {
      version = true
    } else if (arg === '-c' || arg === '--config') {
      configPath = args[++i]
    } else if (arg === '-d' || arg === '--dcs-path') {
      dcsPath = args[++i]
    } else if (arg === '-o' || arg === '--output') {
      outputPath = args[++i]
    } else if (!arg.startsWith('-')) {
      mizPath = arg
    }
  }

  // Show version
  if (version) {
    const pkgPath = path.join(__dirname, '../package.json')
    if (fs.existsSync(pkgPath)) {
      const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'))
      console.log(`DCS Mission Validator v${pkg.version}`)
    } else {
      console.log('DCS Mission Validator v1.0.0')
    }
    process.exit(0)
  }

  // Show help
  if (help || !mizPath) {
    console.log(`
DCS Mission Validator - Validate DCS missions against checklist rules

Usage:
  dcs-validator <miz-file> [options]

Arguments:
  <miz-file>              Path to .miz mission file

Options:
  -c, --config <path>     Path to validation config JSON (optional)
  -d, --dcs-path <path>   Path to DCS installation (optional, for terrain data)
  -o, --output <path>     Export results to JSON file (optional)
  -h, --help              Show this help message
  -v, --version           Show version number

Examples:
  dcs-validator mission.miz
  dcs-validator mission.miz -c custom-config.json
  dcs-validator mission.miz -d "C:\\Program Files\\DCSWorld"
  dcs-validator mission.miz -o results.json

Configuration:
  If no config is specified, the default checklist will be used.
  Custom configs can be created by copying and modifying the default config.

Exit Codes:
  0 - Validation passed (no errors)
  1 - Validation failed (errors found)
  2 - Invalid arguments or file not found
`)
    process.exit(mizPath ? 0 : 2)
  }

  // Validate MIZ file exists
  if (!fs.existsSync(mizPath)) {
    console.error(`❌ Error: MIZ file not found: ${mizPath}`)
    process.exit(2)
  }

  // Validate config exists (if provided)
  if (configPath && !fs.existsSync(configPath)) {
    console.error(`❌ Error: Config file not found: ${configPath}`)
    process.exit(2)
  }

  // Validate DCS path exists (if provided)
  if (dcsPath && !fs.existsSync(dcsPath)) {
    console.error(`❌ Error: DCS installation not found: ${dcsPath}`)
    process.exit(2)
  }

  try {
    // Create validator
    const validator = new MissionValidator(configPath)
    
    // Run validation
    const results = await validator.validateMizFile(mizPath, dcsPath)
    
    // Export results if requested
    if (outputPath) {
      validator.exportResults(outputPath)
    }

    // Exit with appropriate code
    process.exit(results.errors.length > 0 ? 1 : 0)
  } catch (error) {
    console.error(`\n❌ Validation failed: ${error.message}`)
    console.error(error.stack)
    process.exit(2)
  }
}

main()
