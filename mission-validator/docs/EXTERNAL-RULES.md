# External Rules Configuration

The Mission Validator supports **rules as data** - meaning you can define validation rules in JSON files rather than hard-coding them. This makes rules easier to share, modify, and customize.

## Overview

Rules are defined as a structured JSON document that specifies:
- Rule IDs and names
- Validation logic type (frequency_check, naming_pattern, etc.)
- Target units to validate
- Expected values or thresholds
- Severity levels

The validator interprets these rules at runtime without modifying its core code.

## Rule Definition Structure

```json
{
  "$schema": "RULES-META.json",
  "version": "1.0.0",
  "categories": [
    {
      "id": "category_name",
      "name": "Category Display Name",
      "rules": [
        {
          "id": "rule-id-001",
          "name": "Rule Display Name",
          "description": "What this rule checks for",
          "severity": "error|warning|info",
          "type": "rule_type_here", 
          "target": { /* Filter criteria */ },
          /* Rule-specific parameters go here */
        }
      ]
    }
  ],
  "rules": [ /* Additional top-level rules for convenience */ ]
}
```

## Rule Types Available

| Type | Description | Key Fields |
|------|-------------|------------|
| `naming_pattern` | Check unit names match regex pattern | `pattern`, `target: {coalition}` |
| `frequency_check` | Verify radio frequencies | `expectedFrequency`, `tolerance`, `unit` |
| `altitude_check` | Check altitude thresholds | `expectedAltitude`, `minAltitude`, `unit: 'feet'|'meters'` |
| `property_check` | Validate unit property values | `property`, `expectedValue` |
| `distance_check` | Measure distance to reference point | `maxDistance`, `referencePoint` |
| `presence_check` | Verify required features exist | `target: {unitType}` |
| `absence_check` | Check for forbidden patterns | `forbiddenPatterns[]` |
| `awacs_orbit` | Ensure AWACS has Orbit task | Automatically handled |
| `waypoint_count` | Count waypoints requirement | `minCount`, `exactCount`, `maxCount` |
| `advanced_options` | Check required options enabled | `requiredOptions[]` |
| `task_check` | Validate task assignment | `allowedTasks[]` |

## Examples

### Example 1: Naming Pattern Rule

```json
{
  "id": "naming-fighter-001",
  "name": "Blue Fighter Nomenclature",
  "description": "All fighter aircraft must start with BLUE-",
  "severity": "error",
  "type": "naming_pattern",
  "pattern": "^BLUE-FIGHTER|^F-14|^F-15|^Su-37|^A-10A|Jet-Captain|^Blue-A|^(Scourge|Danguy|strAero)",
  "target": {
    "coalition": "blue"
  }
}
```

### Example 2: Frequency Check Rule

```json
{
  "id": "farpc-channel-001", 
  "name": "FARP UHF Channel",
  "description": "UHF should be between 300.0 and 350.0 MHz",
  "severity": "warning",
  "type": "frequency_check",
  "expectedFrequency": 325,
  "tolerance": 1.0,
  "unit": "MHz",
  "target": {
    "coalition": "blue"
  }
}
```

### Example 3: Property Check with Altitude

```json
{
  "id": "tanker-alt-001",
  "name": "Tanker Altitude Standard",  
  "description": "KC-130 tankers should fly at 37,500 feet ± 2000",
  "severity": "info",
  "type": "altitude_check",
  "expectedAltitude": 37500,
  "tolerance": 200,
  "unit": "feet",
  "target": {
    "task": "Tanker"
  }
}
```

### Example 4: Absence Check (Forbidden Units)

```json
{
  "id": "cleanup-test-bad-001", 
  "name": "No Test Aircraft Allowed",
  "description": "Mission must not contain TEST aircraft",
  "severity": "error",
  "type": "absence_check", 
  "forbiddenPatterns": ["/TEST.*/i", /FAKE.*/i, /SPAWN.*/i"],
  "suggestion": "Remove units with TEST/FAKE in their name"
}
```

### Example 5: AWACS Orbit Pattern Check

```json
{
  "id": "awacs-orbit-001",
  "name": "AWACS Must Have Orbit Task", 
  "description": "AWACS must have Orbit task to loiter for air superiority radar coverage",
  "severity": "error",
  "type": "awacs_orbit",
  "target": {
    "task": "AWACS"
  }
}
```

### Example 6: Advanced Options Requirement

```json
{
  "id": "advanced-options-001", 
  "name": "RED Aircraft Need Advanced Options",
  "description": "RED aircraft should have unlimited fuel and invincibility enabled",
  "severity": "warning",  
  "type": "advanced_options",
  "requiredOptions": ["unlimitedFuel", "invincible"],
  "target": {
    "coalition": "red"
  }
}
```

### Example 7: Waypoint Count Requirement

```json
{
  "id": "carrier-waypoints-001",
  "name": "Carrier Has Minimum Points", 
  "description": "Carrier must have at least 3 flight deck points",
  "severity": "info",
  "type": "waypoint_count",
  "minCount": 3,
  "target": {
    "unitType": "CVN"
  }
}
```

## Creating Custom Rules

### Option 1: Extend Category Rules

Add rules to your existing category structure in the missions config file. This keeps all aircraft-related rules together for easy maintenance.

### Option 2: Add Top-Level Rules

The `rules` array at the top level allows you to add quick, flat rules that don't belong to a specific category. Useful for ad-hoc checks or temporary rule sets.

### Example Custom Rule Set

```json
{
  "$schema": "RULES-META.json",
  "version": "1.0.0",
  "categories": [],
  "rules": [
    {
      "id": "company-001",
      "name": "My Custom Rule Set", 
      "description": "Rules specific to our squadron/organization",
      "severity": "error",
      "type": "naming_pattern",
      "pattern": "^CAMPAGN|^DIVISON|^REGIMENT|^BATTALION",
      "target": {}
    }
  ]
}
```

## Loading External Rules

### Using the CLI with Custom Rules

```bash
# Validate mission with default rules
node src/cli.js Georgian-Scramble.miz

# Load additional rules from external file  
node src/cli.js --rules ./my-rules.json Georgian-Scramble.miz

# Override default checklists completely
node src/cli.js --rules-only ./custom-full-checklist.json Georgian-Scramble.miz
```

### Using the Rule Interpreter Directly

```javascript
import { parseMizFile } from './src/mizParser.js';
import RuleInterpreter from './src/ruleInterpreter.js';
import fs from 'fs';

// Parse mission
const data = parseMizFile('Georgian-Scramble.miz');

// Load external rules
const ruleContent = fs.readFileSync('./rules/squadron-rules.json', 'utf8');
const rules = JSON.parse(ruleContent);

// Create interpreter and validate
const interpreter = new RuleInterpreter();
const results = interpreter.validateAll(rules.rules, data.units);

console.log('Custom rule validation complete');
console.log(`  Errors: ${results.errors.length}`);
console.log(`  Warnings: ${results.warnings.length}`);
```

## Creating a Full Custom Ruleset

For organizations wanting to customize the entire checklist:

1. **Copy** the config file: `cp mission-checklist-config.json my-org-rules.json`

2. **Customize** categories in order of priority:
   - Edit `naming` rules for your unit naming convention
   - Modify `farp` and `carrier` dynamic spawn requirements  
   - Adjust `blue_aircraft` COMM channel requirements
   - Change `cleanup` forbidden patterns to match your policies

3. **Share** the `.json` file with validation partners

4. **Validate** using:
   ```bash
   node src/cli.js --rules my-org-rules.json Mission.miz
   ```

## Using Rules in CI/CD Integration

Example GitHub Actions workflow:

```yaml
- name: Validate mission
  run: |
    npm install ./../mission-validator
    npm audit
  env:
    MISSION_VALIDATOR_PATH: ${{ secrets.MISSION_VALIDATOR_PATH }}
    
- name: Check rules
  working-directory: ${{ steps.npm_cache.outputs.cache-path }}
  run: |
    cat mission-checklist-config.json
  continue-on-error: true
  
- name: Run validation with CI rules  
  run: |
    MISSION_CHECKLIST_CONFIG=$PWD/mission-checklist-config-extended.json \
    node src/cli.js --rules "$MISSION_CHECKLIST_CONFIG" $MIZ_FILE
    
- name: Export JSON report to artifacts
  uses: actions/upload-artifact@v4
  with:
    path: 'reports/dcs-mission-validation*.json'
```

## Rule Priority and Severity Levels

| Level | Weight | Action | Auto-Fix? |
|-------|--------|--------|-----------|
| `critical` | 10000 | Must fix immediately, block deployment | No |
| `error` | 1000 | Fix before validation passes | ❌ Must fix |
| `warning` | 100 | Should fix, but mission still usable | ✅ Auto-fix available |
| `info` | 1 | Informational check, no action required | N/A |

### Severity Definitions

- **Critical**: Safety/operational requirement - will cause mission to fail without intervention
- **Error**: Mission won't work correctly (e.g., RED units with incorrect tasks)
- **Warning**: Mission works but may have issues (dynamic spawn not enabled, naming convention warnings)
- **Info**: Best practice suggestion (weather reports, altitude preferences)

## Adding New Rule Types

To add a completely new rule type:

1. **Create** the handler function in `src/ruleInterpreter.js`:

```javascript
this.registerHandler('new_rule_type', (rule, units) => {
  // Implementation
  const failing = units.filter(unit => {
    return unit.someCondition;
  });

  if (failing.length > 0) {
    return {
      passed: false,
      details: `${failing.length} unit(s) fail new check`,
      suggestion: 'Fix units'
    }
  }
  return { passed: true };
});
```

2. **Use** the rule type in your JSON rules file

3. **Reference** it in mission configurations

## Advanced: Rule Templates

Create templates for common rule patterns:

### Rule Template: Frequency Range

```json
{
  "name": "FREQUENCY_RANGE",
  "severity": {{"info"}}
  "type": "frequency_check",
  "expectedFrequency": 305, 
  "tolerance": 1.0,
  "unit": "MHz",
  "target": {"coalition": $COALITION}
}
```

## Best Practices

✅ **Do:**
- Use descriptive rule names (e.g., "AWACS Must Have Orbit Task")
- Set appropriate severity levels based on impact
- Always include helpful suggestions in error messages
- Group related rules into categories
- Document why a rule exists

❌ **Don't:**
- Duplicate rules across multiple files
- Mix different rule types without clear separation
- Use overly complex regex patterns in naming rules  
- Set tolerances too tight without understanding DCS behavior

## Troubleshooting

### Rule Not Matching Expected Units

Add a debug logger:

```javascript
this.registerHandler('debug', (rule, units) => {
  console.log(`Rule ${rule.id} found ${units.length} target units`);
  return { passed: true };
});
```

### Rule Producing False Positives

Adjust tolerance values or add more inclusive patterns. For example:

```json
{
  "type": "frequency_check", 
  "expectedFrequency": 305,  // Original
  "tolerance": 0.5           // Too restrictive → causes issues with DCS rounding
}
// Should be:
{
  "type": "frequency_check",
  "expectedFrequency": 305,
  "tolerance": 1.0          // More reasonable
}
```

---

See the [README.md](../README.md) for complete user documentation and the [SAMPLE-RULES.JSON](../rules/sample-external-rules.json) file for example configurations.
