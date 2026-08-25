# DCS Mission Validator - Project Overview

## Summary

Extended the `dcs-mission-checklist.txt` into an automated validation system that works both as a standalone CLI tool and integrated into the mission editor.

## What Was Built

### 1. Mission Validator Package (`mission-validator/`)

A complete validation engine with:

- **Core Validator** (`src/validator.js`)
  - 40+ automated validation rules
  - 11 validation categories
  - 4 severity levels (critical, error, warning, info)
  - Configurable via JSON

- **CLI Tool** (`src/cli.js`)
  - Command-line validation
  - Export to JSON reports
  - CI/CD ready
  - Exit codes for automation

- **Configuration** (`mission-checklist-config.json`)
  - Structured rule definitions
  - Extensible format
  - Squadron-customizable

### 2. Mission Editor Integration

- **Main Process Service** (`mission-editor/src/main/missionValidator.js`)
  - Real-time validation
  - Auto-validate on changes
  - Event-driven architecture

- **UI Component** (`mission-editor/src/renderer/src/components/units/MissionValidator.vue`)
  - Visual validation dashboard
  - Collapsible result sections
  - Mission score display
  - Export functionality

- **IPC Handlers** (updated `mission-editor/src/main/index.js`)
  - Validator initialization
  - Validation triggers
  - Report export

### 3. Documentation

- **README.md** - User guide
- **INTEGRATION-GUIDE.md** - Developer guide
- **Sample Report** - Example output

## Checklist Coverage

The automated validator covers all items from the original checklist:

### ✅ Naming Conventions
- BLUE force naming pattern
- RED force naming pattern

### ✅ FARP Operations
- Distance from RED forces (10nm minimum)
- Dynamic spawn enabled
- Hot start allowed
- Support buildings nearby
- Wind sock presence

### ✅ AWACS Configuration
- Range positioning (180nm max)
- Frequency (305.00 MHz)
- Altitude (above 30k)
- Waypoint count (2)
- Orbit racetrack pattern
- Advanced options (unlimited fuel, invincible, invisible)

### ✅ Tanker Configuration
- Altitude (20k)
- Speed (max 300 knots)
- Late activation
- KC130: 255.00 MHz, TACAN 10X
- KC135: 257.00 MHz, TACAN 11X
- KC135-MPRS: 259.00 MHz, TACAN 12X

### ✅ Carrier Configuration
- CVN73: 127.500 MHz, TACAN 73X, ILS 3
- CVN74: 129.00 MHz, TACAN 74X, ILS 4
- Dynamic spawn enabled
- Hot start allowed

### ✅ RED Air Forces
- Unlimited fuel
- Afterburner restriction
- CAP or Search/Engage task
- Circular patrol pattern

### ✅ BLUE Aircraft
- Client type setting
- COMM channels (UHF, VHF)
- SEAD frequency (131.00 MHz)
- CAP frequency (135.00 MHz)
- STRIKE frequency (137.50 MHz)
- ROTARY frequency (30 FM)
- F14 INS configuration

### ✅ Base Configuration
- Dynamic spawn enabled
- Hot start allowed
- RED force proximity (10nm minimum)

### ✅ Weather Settings
- Time of day (sunrise)
- Cloud cover (High Scattered 3)
- Wind speed (max 6 knots)

### ✅ Mission Cleanup
- No test aircraft
- No test scripting

## Usage Examples

### Standalone CLI

```bash
# Install
cd dcsAutomation/mission-validator
npm install
npm link

# Validate a mission
dcs-validator mission.miz

# With DCS path for terrain data
dcs-validator mission.miz -d "C:\Program Files\DCSWorld"

# Export results
dcs-validator mission.miz -o results.json
```

### Mission Editor

1. Open mission in editor
2. Click "Validation" tab
3. Enable "Auto-Validate"
4. Review errors and warnings
5. Fix issues using suggestions

### Programmatic API

```javascript
import { MissionValidator } from './mission-validator/src/validator.js'

const validator = new MissionValidator()
const results = await validator.validateMizFile('mission.miz')

console.log(`Mission Score: ${results.summary.score}%`)
console.log(`Errors: ${results.errors.length}`)
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Mission Validator                       │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────────┐      ┌──────────────────┐          │
│  │  CLI Tool      │      │  Mission Editor  │          │
│  │  dcs-validator │      │  Vue Component   │          │
│  └───────┬────────┘      └────────┬─────────┘          │
│          │                       │                     │
│          └───────────┬───────────┘                     │
│                      │                                 │
│          ┌───────────▼───────────┐                     │
│          │  MissionValidator     │                     │
│          │  (Core Engine)        │                     │
│          └───────────┬───────────┘                     │
│                      │                                 │
│          ┌───────────▼───────────┐                     │
│          │  Checklist Config     │                     │
│          │  (JSON Rules)         │                     │
│          └───────────────────────┘                     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## File Structure

```
dcsAutomation/
├── mission-validator/
│   ├── src/
│   │   ├── validator.js          # Core validation engine
│   │   └── cli.js                 # CLI entry point
│   ├── tests/
│   │   └── validator-test.js      # Unit tests
│   ├── samples/
│   │   └── validation-report-example.json
│   ├── mission-checklist-config.json  # Rule definitions
│   ├── package.json
│   ├── README.md
│   └── INTEGRATION-GUIDE.md
│
├── mission-editor/
│   ├── src/
│   │   ├── main/
│   │   │   ├── index.js           # Updated with IPC handlers
│   │   │   └── missionValidator.js # Editor integration
│   │   └── renderer/
│   │       └── src/
│   │           └── components/
│   │               └── units/
│   │                   └── MissionValidator.vue  # UI component
│   └── package.json
│
└── MISSION-VALIDATOR-OVERVIEW.md  # This file
```

## Benefits

### For Mission Makers
- ✅ Automated checklist validation
- ✅ Real-time feedback in editor
- ✅ Clear error messages and suggestions
- ✅ Consistent mission quality

### For Squadrons
- ✅ Enforce squadron standards
- ✅ Customizable rules
- ✅ Batch validation
- ✅ CI/CD integration

### For Training
- ✅ Validate training missions
- ✅ Ensure briefing/debriefing elements
- ✅ Standardize mission parameters

## Next Steps

### Immediate
1. ✅ Install dependencies
2. ✅ Test with existing missions
3. ✅ Customize rules for your squadron

### Future Enhancements
- [ ] Auto-fix for common issues
- [ ] HTML report generation
- [ ] Web-based validator
- [ ] More rule types (pattern checks, script analysis)
- [ ] Integration with DCS server
- [ ] Multi-mission validation
- [ ] Validation templates for different mission types

## Testing

Run the test suite:

```bash
cd dcsAutomation/mission-validator
npm test
```

## Validation Report Example

See `mission-validator/samples/validation-report-example.json` for a complete example of validation output.

## Configuration

The validator is highly configurable:

- **Severity Levels**: Adjust rule severity
- **Custom Rules**: Add squadron-specific rules
- **Rule Targets**: Filter by coalition, unit type, task
- **Output Formats**: JSON, HTML (future), Markdown (future)

## Support

For questions or issues:
1. Check `mission-validator/README.md`
2. Review `INTEGRATION-GUIDE.md`
3. Examine sample validation reports
4. Open a GitHub issue

## License

ISC - Same as main project

---

**Status**: ✅ Complete and ready for use

The mission validator successfully extends the original checklist into a fully automated, configurable validation system that works both standalone and integrated into the mission editor.
