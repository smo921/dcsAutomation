# Mission Validator Integration Guide

This guide explains how to integrate the DCS Mission Validator with your existing workflow and the mission editor.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    DCS Mission Validator                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │  CLI Tool        │         │  Mission Editor  │         │
│  │  (dcs-validator) │         │  Integration     │         │
│  └────────┬─────────┘         └────────┬─────────┘         │
│           │                            │                    │
│           └────────────┬───────────────┘                    │
│                        │                                    │
│           ┌────────────▼────────────┐                       │
│           │   MissionValidator      │                       │
│           │   (Core Engine)         │                       │
│           └────────────┬────────────┘                       │
│                        │                                    │
│           ┌────────────▼────────────┐                       │
│           │   Checklist Config      │                       │
│           │   (JSON Rules)          │                       │
│           └─────────────────────────┘                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Install Dependencies

```bash
cd dcsAutomation/mission-validator
npm install

cd ../mission-editor
npm install
```

### 2. Validate a Mission (CLI)

```bash
# From mission-validator directory
npm run validate -- ../../missions/03-Operation-Granite-Crest.miz

# Or if linked globally
dcs-validator ../../missions/03-Operation-Granite-Crest.miz
```

### 3. Use in Mission Editor

The validator panel is automatically available in the mission editor UI under the "Validation" tab.

## Integration Points

### 1. Standalone CLI Tool

**Use Case**: CI/CD pipelines, batch validation, pre-commit hooks

```bash
# Validate single mission
dcs-validator mission.miz

# Validate all missions in directory
for file in missions/*.miz; do
  dcs-validator "$file" -o "reports/$(basename $file .miz).json"
done

# In CI/CD (GitHub Actions)
- name: Validate Missions
  run: |
    npm install -g dcs-mission-validator
    dcs-validator missions/*.miz || exit 1
```

**Example: Pre-commit Hook**

```bash
#!/bin/bash
# .git/hooks/pre-commit

MIZ_FILES=$(git diff --cached --name-only | grep '\.miz$')

if [ -n "$MIZ_FILES" ]; then
  echo "Validating mission files..."
  for file in $MIZ_FILES; do
    dcs-validator "$file"
    if [ $? -ne 0 ]; then
      echo "Validation failed for $file"
      exit 1
    fi
  done
fi
```

### 2. Mission Editor Integration

**Use Case**: Real-time validation during mission creation

The validator is integrated into the mission editor as:
- A Vue component (`MissionValidator.vue`)
- IPC handlers in the main process
- Auto-validation on mission changes

**Features**:
- Real-time validation as you edit
- Visual error/warning indicators
- Click-to-fix suggestions
- Export validation reports

**Usage in Editor**:
1. Open mission in editor
2. Click "Validation" tab in sidebar
3. Review validation results
4. Click on errors to see suggestions
5. Fix issues and re-validate

### 3. Programmatic API

**Use Case**: Custom tools, scripts, or applications

```javascript
import { MissionValidator } from './mission-validator/src/validator.js'

// Create validator instance
const validator = new MissionValidator('path/to/config.json')

// Validate MIZ file
const results = await validator.validateMizFile('mission.miz')

// Access results
console.log(`Score: ${results.summary.score}%`)
console.log(`Errors: ${results.errors.length}`)

// Export results
validator.exportResults('validation-report.json')
```

**Custom Validation**:

```javascript
// Validate specific rule
const rule = {
  id: 'custom-001',
  name: 'Custom Check',
  type: 'property_check',
  target: { coalition: 'blue' }
}

const result = await validator.validateRule(rule, missionData)
```

## Configuration

### Default Configuration

The default checklist config is in `mission-checklist-config.json`. It includes:
- 11 categories
- 40+ validation rules
- 4 severity levels

### Custom Configuration

Create a custom config for your squadron/organization:

```json
{
  "version": "1.0.0",
  "categories": [
    {
      "id": "squadron_rules",
      "name": "Squadron Rules",
      "priority": "high",
      "rules": [
        {
          "id": "sqn-001",
          "name": "Callsign Format",
          "description": "All flights must use squadron callsign format",
          "severity": "error",
          "type": "naming_pattern",
          "pattern": "^SQN\\d+-",
          "target": {
            "coalitions": ["blue"],
            "unitTypes": ["plane"]
          }
        }
      ]
    }
  ]
}
```

### Rule Types Reference

| Rule Type | Description | Example |
|-----------|-------------|---------|
| `naming_pattern` | Check unit names against regex | `^BLUE-.*` |
| `property_check` | Validate boolean properties | `dynamicSpawn: true` |
| `distance_check` | Measure distances | FARP > 10nm from RED |
| `frequency_check` | Radio frequencies | AWACS = 305.00 MHz |
| `altitude_check` | Altitude settings | Tanker = 20k feet |
| `waypoint_count` | Number of waypoints | AWACS = 2 waypoints |
| `speed_check` | Speed limits | Tanker ≤ 300 knots |
| `task_check` | Assigned tasks | RED air = CAP |
| `absence_check` | Forbidden items | No test aircraft |
| `presence_check` | Required items | FARP has windsock |

## Extending the Validator

### Adding New Rule Types

1. **Define the rule type** in `validator.js`:

```javascript
validateCustomCheck(rule, missionData) {
  // Your validation logic
  const units = this.filterUnits(missionData.units, rule.target)
  
  // Check condition
  const passed = units.every(unit => {
    return unit.someProperty === rule.expectedValue
  })

  if (!passed) {
    return {
      passed: false,
      details: `${failing.length} units failed check`,
      suggestion: 'Fix the issue'
    }
  }

  return { passed: true }
}
```

2. **Register the validator**:

```javascript
getValidator(type) {
  const validators = {
    // ... existing validators
    custom_check: this.validateCustomCheck.bind(this)
  }
  return validators[type] || null
}
```

3. **Add to config**:

```json
{
  "rules": [{
    "type": "custom_check",
    "expectedValue": true
  }]
}
```

### Adding Custom Reports

Export validation results in custom formats:

```javascript
exportReport(format, outputPath) {
  if (format === 'html') {
    const html = this.generateHTMLReport()
    fs.writeFileSync(outputPath, html)
  }
  // ... other formats
}
```

## Best Practices

### 1. Rule Design

- **Be Specific**: Each rule should check one thing
- **Clear Messages**: Error messages should explain what's wrong
- **Actionable Suggestions**: Tell users how to fix issues
- **Appropriate Severity**: Don't mark everything as critical

### 2. Performance

- **Debounce Validation**: Use auto-validate debounce (default: 1000ms)
- **Filter Early**: Use target filters to reduce checks
- **Cache Results**: Store last validation for quick access

### 3. Testing

```javascript
// Test your rules
import { MissionValidator } from './validator.js'

const validator = new MissionValidator()

// Mock mission data
const mockData = {
  units: [
    { name: 'BLUE-1', coalition: 'Blue', type: 'plane' }
  ]
}

// Test rule
const result = await validator.validateRule(rule, mockData)
console.assert(result.passed === true)
```

## Troubleshooting

### Validator Not Initializing

**Problem**: "Validator not initialized"

**Solution**:
1. Check config file exists
2. Verify config is valid JSON
3. Ensure all dependencies are installed

### Rules Not Applying

**Problem**: Rules don't match any units

**Solution**:
1. Check target filters (coalition, unitType, task)
2. Verify unit data structure matches expected format
3. Test with mock data first

### Performance Issues

**Problem**: Validation is slow

**Solution**:
1. Increase debounce time
2. Disable auto-validate for large missions
3. Add more specific target filters

## Examples

### Example 1: Squadron Validation

```json
{
  "categories": [
    {
      "id": "squadron_standards",
      "name": "Squadron Standards",
      "rules": [
        {
          "id": "std-001",
          "name": "Flight Naming",
          "type": "naming_pattern",
          "pattern": "^VMFA-\\d+-",
          "target": {
            "coalition": "blue",
            "unitType": "plane"
          },
          "severity": "error"
        }
      ]
    }
  ]
}
```

### Example 2: Training Mission Validation

```json
{
  "categories": [
    {
      "id": "training_requirements",
      "name": "Training Requirements",
      "rules": [
        {
          "id": "train-001",
          "name": "Briefing Included",
          "type": "presence_check",
          "requiredObjects": ["briefing_zone"],
          "severity": "error"
        },
        {
          "id": "train-002",
          "name": "Debrief Triggers",
          "type": "script_check",
          "requiredPatterns": ["debrief"],
          "severity": "warning"
        }
      ]
    }
  ]
}
```

### Example 3: Automated Testing

```javascript
// test/validator.spec.js
import { MissionValidator } from '../src/validator.js'

describe('Mission Validator', () => {
  it('should validate naming conventions', async () => {
    const validator = new MissionValidator()
    const mockData = {
      units: [
        { name: 'BLUE-1', coalition: 'Blue', type: 'plane' },
        { name: 'BadName', coalition: 'Blue', type: 'plane' }
      ]
    }

    const rule = {
      id: 'naming-001',
      type: 'naming_pattern',
      pattern: '^BLUE-',
      target: { coalition: 'blue' }
    }

    const result = await validator.validateRule(rule, mockData)
    expect(result.passed).toBe(false)
    expect(result.details).toContain('BadName')
  })
})
```

## Support

For issues or questions:
1. Check the README.md
2. Review sample validation reports
3. Open an issue on GitHub

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new rules
4. Submit a pull request

---

**Next Steps**:
- Read `README.md` for usage guide
- Check `samples/validation-report-example.json` for output format
- Explore `mission-checklist-config.json` for rule definitions
