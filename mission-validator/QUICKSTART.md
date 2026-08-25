# DCS Mission Validator - Quick Start Guide

## What is This?

The Mission Validator automates the DCS mission checklist (`dcs-mission-checklist.txt`), turning it into a powerful validation tool that:

✅ Checks 40+ mission rules automatically
✅ Provides clear error messages and fix suggestions  
✅ Works standalone (CLI) or integrated in mission editor
✅ Exports validation reports
✅ Enforces squadron standards

## Installation (5 minutes)

```bash
# Navigate to validator
cd dcsAutomation/mission-validator

# Install dependencies
npm install

# (Optional) Make CLI available globally
npm link
```

## Usage

### Option 1: Command Line (Standalone)

```bash
# Validate a mission
node src/cli.js /path/to/mission.miz

# Or if linked globally
dcs-validator mission.miz

# With DCS installation path (for terrain data)
dcs-validator mission.miz -d "C:\Program Files\DCSWorld"

# Export results to JSON
dcs-validator mission.miz -o results.json
```

### Option 2: Mission Editor (GUI)

1. Open mission in mission editor
2. Click "Validation" tab in sidebar
3. Click "Validate Mission"
4. Review errors, warnings, and suggestions
5. Enable "Auto-Validate" for real-time feedback

### Option 3: Programmatic API

```javascript
import { MissionValidator } from './mission-validator/src/validator.js'

const validator = new MissionValidator()
const results = await validator.validateMizFile('mission.miz')

console.log(`Score: ${results.summary.score}%`)
console.log(`Errors: ${results.errors.length}`)
```

## What Gets Checked?

The validator checks all items from the original checklist:

### Naming Conventions
- BLUE forces named "BLUE-Name"
- RED forces named "RED-Name"

### FARP Operations
- 10nm minimum from RED forces
- Dynamic spawn enabled
- Hot start allowed
- Ammo/Fuel depots nearby
- Wind sock present

### AWACS
- Frequency: 305.00 MHz
- Altitude: above 30k
- 2 waypoints with orbit pattern
- Advanced options set

### Tankers
- Altitude: 20k
- Speed: max 300 knots
- Correct frequencies and TACAN by aircraft type

### Carriers
- CVN73/74 frequencies and settings
- Dynamic spawn and hot start

### RED Air
- Unlimited fuel and afterburner restriction
- CAP or Search/Engage tasks

### BLUE Aircraft
- Client type setting
- COMM channels configured
- Mission-specific frequencies

### Bases
- Dynamic spawn and hot start
- No RED forces within 10nm

### Weather
- Sunrise time
- High Scattered 3 clouds
- Wind under 6 knots

### Cleanup
- No test aircraft
- No test scripting

## Understanding Results

```
📊 VALIDATION SUMMARY
============================================================
Total Rules Checked: 41
✅ Passed: 35
❌ Errors: 3
⚠️  Warnings: 3
ℹ️  Info: 0

📈 Mission Score: 85%
```

- **Errors** (❌): Must fix - mission-breaking issues
- **Warnings** (⚠️): Should fix - mission usable but not ideal
- **Info** (ℹ️): Suggestions for improvement

## Example Output

```
❌ ERRORS (Must Fix):
   - FARP Dynamic Spawn: 2 unit(s) have incorrect setting
     💡 Set dynamicSpawn to true
   
   - No Test Aircraft: Found 1 forbidden unit(s): Test-1
     💡 Remove test/debug/temp aircraft from mission

⚠️  WARNINGS (Should Fix):
   - AWACS Waypoints: 1 unit(s) don't have exactly 2 waypoints
     💡 Set exactly 2 waypoints
```

## Custom Configuration

Create your own rules in `custom-config.json`:

```json
{
  "version": "1.0.0",
  "categories": [
    {
      "id": "squadron_rules",
      "name": "Squadron Standards",
      "rules": [
        {
          "id": "sqn-001",
          "name": "Callsign Format",
          "type": "naming_pattern",
          "pattern": "^VMFA-\\d+-",
          "severity": "error"
        }
      ]
    }
  ]
}
```

Use it with:
```bash
dcs-validator mission.miz -c custom-config.json
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: Validate Missions
  run: |
    npm install -g dcs-mission-validator
    dcs-validator missions/*.miz
```

### Pre-commit Hook
```bash
#!/bin/bash
MIZ_FILES=$(git diff --cached --name-only | grep '\.miz$')
for file in $MIZ_FILES; do
  dcs-validator "$file" || exit 1
done
```

## Testing

```bash
# Run unit tests
npm test

# Run integration tests
node tests/integration-test.js
```

## Troubleshooting

**"Config file not found"**
- Use `-c` to specify config path
- Or copy `mission-checklist-config.json` to your working directory

**"Mission file is corrupted"**
- Verify the .miz file opens in DCS Mission Editor
- Re-export from Mission Editor if needed

**"DCS installation not found"**
- Provide path with `-d` option
- Or omit - validator works without terrain data

## Next Steps

1. ✅ Install and test with your missions
2. ✅ Review validation results
3. ✅ Fix any errors
4. ✅ Customize rules for your squadron (optional)
5. ✅ Integrate into your workflow

## Documentation

- `README.md` - Complete user guide
- `INTEGRATION-GUIDE.md` - Developer guide
- `../MISSION-VALIDATOR-OVERVIEW.md` - Project overview

## Support

For issues or questions, check the documentation or open a GitHub issue.

---

**Ready to validate missions!** 🚀
