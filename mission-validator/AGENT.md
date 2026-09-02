# Mission Validator Agent Instructions

This file provides guidance for AI agents working on the DCS Mission Validator tool.

## Quick Start

```bash
# Validate a mission
npm run validate ../missions/Georgian-Scramble.miz

# Run tests
npm test

# Validate with custom config
npm run validate mission.miz -- --config custom-rules.json
```

---

## Core Principles

### 1. MIZ File Handling
- **Always require explicit MIZ file paths** - Never accept undefined/null paths
- **Extract and read directly** - Unzip `.miz` archives and read extracted Lua contents with `fs` module
- **Clean up temp files** - Delete extracted files after validation completes
- **Avoid library parsing for debugging** - Use direct file reads for validation workflows

### 2. Unit Filtering Rules
- **Distinguish client vs AI units**:
  - `controlled: false` = Client/player aircraft
  - `controlled: true` = AI-controlled units
- **Apply rules appropriately**:
  - Client-specific requirements (naming, COMM) should NOT apply to AI units
  - AI-specific requirements should NOT apply to client units
- **Use `target.controlled` property** in rule definitions to filter correctly

### 3. Validation Scoring
- **Account for warnings** - Missions with warnings should NOT receive 100% score
- **Severity levels matter**:
  - `error` - Mission-breaking, must fix
  - `warning` - Should fix, mission still usable
  - `info` - Suggestions for improvement
- **Score formula**: `(passed / total) * 100` where total includes warnings

---

## Architecture Guidelines

### External Rules System
- **All rules in external JSON** - Load from `./rules/` directory via `RuleInterpreter.js`
- **No hardcoded rules** - All validation logic must be data-driven
- **Rule types supported**:
  - `naming_pattern` - Verify unit names match regex
  - `frequency_check` - Check radio frequencies
  - `altitude_check` - Validate altitude with unit conversion (feet ↔ meters)
  - `speed_check` - Validate speed (use `minSpeed` for tankers ≥250 knots)
  - `property_check` - Generic property validation
  - `advanced_options` - Verify advanced settings enabled
  - `awacs_orbit` - Check for Orbit task in waypoints
  - `waypoint_count` - Validate waypoint numbers
  - `distance_check` - Measure proximity to reference point
  - `presence_check` - Verify features exist
  - `absence_check` - Detect forbidden patterns
  - `task_check` - Validate task assignment
  - `comm_check` - Verify communication channels

### Code Modification Strategy
- **Avoid incremental edits** - The edit tool has whitespace/matching issues
- **Prefer `write` tool** - Write complete clean file replacements for validator code
- **Test after changes** - Always run `npm test` after modifications

---

## Testing Approach

### TDD Workflow
1. **Write test first** - Define expected behavior in test file
2. **Run test (fails)** - Confirm test fails as expected
3. **Implement fix** - Write minimum code to pass test
4. **Run test (passes)** - Verify test passes
5. **Refactor** - Clean up code while keeping tests green

### Test Files
- `tests/validator-test.js` - Core validator tests
- `tests/test-*.lua` - Lua-based unit tests (Busted framework)

---

## File Structure

```
mission-validator/
├── src/
│   ├── cli.js           # Command-line interface
│   ├── validator.js     # Core validation engine
│   ├── mizParser.js     # MIZ file extraction and parsing
│   └── ruleInterpreter.js # External rules loader
├── rules/               # External validation rules (JSON)
│   ├── awacs.json
│   ├── tankers.json
│   ├── naming-conventions.json
│   ├── blue-aircraft-checks.json
│   └── ...
├── tests/               # Test suite
├── docs/                # Documentation
├── validation-results/  # Output directory (gitignored)
├── AGENT.md            # This file
└── package.json
```

---

## Common Pitfalls

### ES Module Path Resolution
```javascript
// ❌ Wrong - import.meta.url is a file: URL
const __dirname = path.dirname(import.meta.url)

// ✅ Correct - convert URL to file path first
const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
```

### Altitude Unit Conversion
```javascript
// DCS stores altitude in METERS
// Rules specify altitude in FEET
const conversionFactor = 3.28084  // feet per meter
const expectedMeters = rule.expectedAltitude / conversionFactor
```

### Tanker Speed Rules
```javascript
// ❌ Wrong - tankers need MINIMUM speed to keep up with receivers
rule.maxSpeed = 300  // This allows 0 knots!

// ✅ Correct - enforce minimum speed
rule.minSpeed = 250  // Must be at least 250 knots
```

---

## Reference

- **Main project docs**: [`../CLAUDE.md`](../CLAUDE.md)
- **Validator overview**: [`MISSION-VALIDATOR-OVERVIEW.md`](MISSION-VALIDATOR-OVERVIEW.md)
- **Integration guide**: [`INTEGRATION-GUIDE.md`](INTEGRATION-GUIDE.md)
- **Quick start**: [`QUICKSTART.md`](QUICKSTART.md)

---

*Note: These preferences are prioritized over other concerns in project decisions.*
