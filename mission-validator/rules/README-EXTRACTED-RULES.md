# Extracted Rules Files for Mission Validator

## What Are These?

Each JSON file here contains rules extracted from the mission validator's main configuration into separate modular files. This makes it easy to:
- Edit specific rule categories independently
- Share single-category rules with teams that need only those checks
- Create custom rule sets by combining relevant files
- Maintain compliance with different organizations' policies

## How to Use

### Quick Start - Load Multiple Categories

```bash
# Create main config with externalRules field
cat > mission-checklist-config.json << 'CONFIG'
{
  "version": "1.0.0",
  "description": "Mission validation checklist",
  "categories": [],
  "externalRules": [
    "./rules/awacs.json",
    "./rules/farp-rules.json", 
    "./rules/naming-conventions.json",
    "./rules/tankers.json",
    "./rules/carrier-rules.json"
  ]
}
CONFIG

# Validate mission  
node src/cli.js --config mission-checklist-config.json mission.miz
```

### Load Specific Rule Files

You can mix and match rule files:

```bash
# Only AWACS checks
npm install ./dcsAutomation/mission-validator
node src/cli.js \
  --config ./rules/awacs.json \
  mission.miz
```

### Environment Variable Method

Set `MISSION_VALIDATOR_RULES_PATH` to additional rules:

```bash
export MISSION_VALIDATOR_RULES_PATH=./rules/snowstorm-winter-rules.json
node src/cli.js mission.miz  # Uses default + snowstorm rules
```

## Rules Files Available

| File | Category | Description | Rule Count |
|------|----------|-------------|------------|
| `awacs.json` | AWACS Control | E-2C AWACS configuration (6 rules) |
| `farp-rules.json` | FARP Operations | Forward Arming Refueling Point checks (4 rules) |
| `tankers.json` | Tanker/Refueling | KC-130/KC-135 refueling rules (6 rules) |
| `carrier-rules.json` | CVN Carriers | CVN carrier frequency/settings (5 rules) |
| `red-air-forces.json` | RED Air Units | RED coalition aircraft requirements (3 rules) |
| `blue-aircraft-checks.json` | BLUE Aircraft | Communication channels/frequencies (6 rules) |
| `base-ground-checks.json` | Base Config | Ground base and proximity checks (3 rules) |
| `naming-conventions.json` | Naming Rules | Unit naming pattern patterns (3 rules) |
| `weather-settings.json` | Environment | Mission weather/time settings (4 rules) |
| `cleanup-rules.json` | Cleanup | Remove test aircraft (4 rules) |

## How to Create Custom Rule Files

### Step 1: Find Source Rules

Look in sample-external-rules.json or main config for rules you want to extract.

### Step 2: Create JSON File

Create a file with category structure:

```json
{
  "$schema": "../RULES-META.json", 
  "version": "1.0.0",
  "description": "My custom tanker rules",
  "categories": [
    {
      "id": "tanker_special",
      "name": "Tanker Special Checks",
      "rules": [/* extract your tanker rules here */]
    }
  ]
}
```

### Step 3: Load in Config

Point to your custom file using `externalRules` field.

## Best Practices

1. **One category per file** - Keep files small and focused (e.g., carriers.json for only carrier checks)
2. **Use descriptive names** - farp-rules.json is clearer than rules-047.json  
3. **Include metadata** - Always include $schema, version, description fields
4. **Group by related functionality** - Don't mix naming and frequency rules together
5. **Avoid duplication** - Reference files for reusability rather than inline copy-paste

## Troubleshooting

### Rules Loading Slowly?

Use environment variable `MISSION_VALIDATOR_USE_EXTERNAL_ONLY=1` to skip base config loading.

### Category Duplicate Errors?

Each external rules file must have unique category IDs. Avoid overlapping categories like two awacs files.

### JSON Syntax Errors?

Validate each rules file with JSON linting tool before merging. Check for trailing commas, missing quotes, etc.

## Support

- See `docs/EXTENDING-MISSIONS-WITH-JSON-RULES.md` for extending the validator
- See `docs/WITH-EXAMPLES.md` for usage examples  
- See `docs/EXTERNAL-RULES.md` for full documentation
