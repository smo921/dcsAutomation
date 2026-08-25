/**
 * Create a merged external rules config from multiple rule files
 * Usage: node src/create-external-rules-config.js --input ./rules/ --output my-merged-config.json
 */

import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

function createMergedConfig(rulesDir = './rules', categoriesOnly = false) {
  const ruleFilesPath = path.resolve(__dirname, '..', rulesDir)
  const config = {
    $schema: '../RULES-META.json',
    version: '1.0.0',
    description: `Merged external rule files from ${rulesDir}`,
    externalRules: [],
    categories: []  // Will be populated automatically
  }

  if (!fs.existsSync(ruleFilesPath)) {
    throw new Error(`Rules directory not found: ${ruleFilesPath}`)
  }

  // Find all JSON files in rules directory, excluding config/README files
  const files = fs.readdirSync(ruleFilesPath)
  const ruleFiles = files.filter(f => f.endsWith('.json') && !['sample-external-rules.json', 'RULES-META.json'].includes(f))

  console.log(`\n🔗 Merging external rules from: ${rulesDir}`)
  console.log('=' .repeat(60))

  for (const file of ruleFiles.sort()) {
    const filePath = path.join(ruleFilesPath, file)
    if (fs.existsSync(filePath)) {
      const content = JSON.parse(fs.readFileSync(filePath, 'utf8'))
      
      // Merge rule files into config
      if (!config.externalRules.some(existing => existing === path.basename(file))) {
        config.externalRules.push('./rules/' + file)
        console.log(`  ✓ ${file}`)
        
        const extCategories = content?.categories || []
        for (const cat of extCategories) {
          config.categories.push(JSON.parse(JSON.stringify(cat)))
        }
      } else {
        console.log(`  ⊘ ${file} -\u2192 Already merged`)
      }
    } else {
      console.log(`  ✗ ${file} -\u2192 Not found`)
    }
  }

  console.log('=' .repeat(60))
  console.log(`\n✅ Total loaded: ${config.categories.length} rule categories\n`)

  // Output the merged config to stdout for piping into editor or save to file
  return config
}

// Handle command line arguments
async function main() {
  const args = process.argv.slice(2)
  
  if (args.includes('--help') || args.includes('-h')) {
    console.log(`Usage: ${path.basename(process.argv[1])} [options]`)
    console.log('Options:')
    console.log('  --input <dir>      Rules directory (default: ./rules/)')
    console.log('  --output <file>    Output file path (default: stdout)')
    console.log('  --only-categories  Merge only categories, not full rules (advanced)')
    console.log('  --help              Show this help message\n')
    return
  }

  try {
    const config = createMergedConfig(
      args.find(a => a.startsWith('--input='))?.split('=')[1] || './rules/',
      false
    )

    // Output to console for piping OR save if file specified
    process.stdout.write(JSON.stringify(config, null, 2) + '\n')
  } catch (error) {
    console.error(`Error: ${error.message}`)
    process.exit(1)
  }
}

main()
