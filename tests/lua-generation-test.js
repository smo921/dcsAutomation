/**
 * Node.js test script for Lua generation
 *
 * Tests the mission-editor code by:
 * 1. Loading sample-data.json
 * 2. Using configLoader.js to load refpoints and templates
 * 3. Using lua/generator.js to generate Lua
 * 4. Running Lua validation on the output
 *
 * Usage:
 *   node tests/lua-generation-test.js sample-data.json
 *   node tests/lua-generation-test.js sample-data.json generated-mission.lua
 */

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

// Use dynamic import to load ES modules
async function main() {
  const args = process.argv.slice(2);
  const sampleDataPath = args[0];
  const outputPath = args[1] || 'generated-mission.lua';

  if (!sampleDataPath) {
    console.log('Usage: node tests/lua-generation-test.js <sample-data.json> [output.lua]');
    process.exit(1);
  }

  const projectRoot = path.resolve(__dirname, '..');
  const inputPath = path.resolve(projectRoot, sampleDataPath);
  const outputPathFull = path.resolve(projectRoot, outputPath);

  if (!fs.existsSync(inputPath)) {
    console.error(`Error: Input file not found: ${inputPath}`);
    process.exit(1);
  }

  // Import mission-editor modules dynamically
  const configLoader = await import(`file://${projectRoot}/mission-editor/src/renderer/src/config/configLoader.mjs`);
  const luaGenerator = await import(`file://${projectRoot}/mission-editor/src/renderer/src/lua/generator.mjs`);

  // ==============================================================================
  // MINIMAL STORE MOCKS (just the state, no Pinia)
  // ==============================================================================

  const refpointsStore = {
    bullseyes: [],
    airbases: [],
    zones: [],
    lines: [],
    loadFromFullConfig(config) { configLoader.loadRefpointsFromConfig(this, config); },
    clear() { this.bullseyes = []; this.airbases = []; this.zones = []; this.lines = []; }
  };

  const unitTemplatesStore = {
    categories: { air: [], ground: [], naval: [], support: [] },
    loadFromFullConfig(config) { configLoader.loadUnitTemplatesFromConfig(this, config); },
    clear() { for (const c of Object.keys(this.categories)) this.categories[c] = []; }
  };

  const routeTemplatesStore = {
    templates: [],
    loadFromFullConfig(config) { configLoader.loadRouteTemplatesFromConfig(this.templates, config); },
    clear() { this.templates = []; }
  };

  console.log('=== Lua Generation Test ===\n');

  // Load sample data
  console.log('1. Loading sample data...');
  const sampleData = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
  console.log(`   Units: ${sampleData.units ? sampleData.units.length : 0}`);

  // Load using mission-editor stores
  console.log('\n2. Loading using mission-editor stores...');
  refpointsStore.clear();
  unitTemplatesStore.clear();
  routeTemplatesStore.clear();

  refpointsStore.loadFromFullConfig(sampleData);
  unitTemplatesStore.loadFromFullConfig(sampleData);
  routeTemplatesStore.loadFromFullConfig(sampleData);

  console.log(`   Bullseyes: ${refpointsStore.bullseyes.length}`);
  console.log(`   Airbases: ${refpointsStore.airbases.length}`);
  console.log(`   Zones: ${refpointsStore.zones.length}`);
  console.log(`   Lines: ${refpointsStore.lines.length}`);
  console.log(`   Unit Templates: ${Object.values(unitTemplatesStore.categories).reduce((a, b) => a + b.length, 0)}`);
  console.log(`   Route Templates: ${routeTemplatesStore.templates.length}`);

  // Flatten unit templates (all categories into one array)
  const allUnitTemplates = Object.values(unitTemplatesStore.categories).flat();

  // Generate Lua using mission-editor generator
  console.log('\n3. Generating Lua using mission-editor generator...');
  const luaContent = luaGenerator.generateLuaFromUnits(sampleData.units || [], refpointsStore, {
    makeGlobal: true,
    routeTemplates: routeTemplatesStore.templates,
    unitTemplates: allUnitTemplates
  });

  // Write output
  fs.writeFileSync(outputPathFull, luaContent);
  console.log(`   Output: ${outputPathFull}`);

  // Validate
  console.log('\n4. Running Lua validation...');
  const luaValidationPath = path.join(projectRoot, 'tests', 'validate-generated-lua.lua');
  const luaExe = 'C:/Program Files (x86)/Lua/5.1/lua.exe';

  const validateChild = spawn(luaExe, [luaValidationPath, outputPathFull], {
    cwd: projectRoot,
    stdio: 'inherit'
  });

  validateChild.on('close', (code) => {
    console.log('\n=== Test Complete ===');
    if (code === 0) {
      console.log('All validations passed! ✓');
    } else {
      console.log(`Validation failed with exit code: ${code}`);
    }
    process.exit(code);
  });
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
