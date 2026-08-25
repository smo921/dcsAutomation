# Extending Mission Validator with JSON Rule Files

## Quick Start

You can create JSON rule files for any mission category and load them into the validator. The validator automatically merges categories while preserving duplicates.

## How to Create Your Own Rules File

### Step 1: Define a Category-Specific Rules File

Create a file like `rules/awacs-custom.json`:

```json
{
  "$schema": "../RULES-META.json",
  "version": "1.0.0",
  "description": "Custom AWACS rules for Georgian Scramble",
  "categories": [
    {
      "id": "awacs",
      "name": "AWACS Control",
      "rules": [
        {
          "id": "awacs-custom-gs-001",
          "name": "Georgian Scramble AWACS Requirement",
          "description": "AWACS must be present in Georgian Scramble missions",
          "severity": "critical",
          "type": "presence_check",
          "requiredObjects": ["awacs"],
          "target": {
            "task": "AWACS"
          }
        },
        {
          "id": "awacs-dynspawn-001", 
          "name": "AWACS Dynamic Spawn",
          "description": "AWACS should have dynamic spawn enabled for hot missions",
          "severity": "error",
          "type": "property_check",
          "property": "dynSpawnTemplate",
          "expectedValue": true,
          "target": {
            "task": "AWACS"
          }
        }
      ]
    }
  ],
  "$comment": "Add more rules to this category as needed"
}
```

### Step 2: Merge Rules from Multiple Files

Create your main rules file that loads external files:

**Option A: Using `externalRules` field**

```json
{
  "$schema": "../RULES-META.json",
  "version": "1.0.0",
  "categories": [
    /* Your base categories here */
  ],
  "externalRules": [
    "./rules/awacs-custom.json",
    "./rules/basedefinedbyyou.json"
  ]
}
```

**Option B: Using environment variable**

Set `MISSION_VALIDATOR_RULES_PATH` to your rules file path:

```bash
MISSION_VALIDATOR_RULES_PATH=./rules/awacs-rules.json node src/cli.js mission.miz
```

### Step 3: Use with Multiple Rule Files

Create category-specific files:

**rules/naming-conventions.json**
```json
{
  "$schema": "../RULES-META.json", 
  "version": "1.0.0",
  "categories": [
    {
      "id": "naming",
      "name": "Naming Conventions",
      "rules": [
        /* Your naming rules */
      ]
    }
  ]
}
```

**rules/farp-operations.json**
```json
{
  "$schema": "../RULES-META.json",
  "version": "1.0.0",
  "categories": [
    {
      "id": "farp",
      "name": "FARP Operations",
      "rules": [/* FARP rules */]
    }
  ]
}
```

**rules/aircraft-safety.json**
```json
{
  "$schema": "../RULES-META.json",
  "version": "1.0.0", 
  "categories": [
    {
      "id": "safety",
      "name": "Aircraft Safety Checks",
      "rules": [/* Safety rules */]
    }
  ]
}
```

Then merge them:

```json
{
  "$schema": "../RULES-META.json",
  "version": "1.0.0",
  "categories": [],  // Start empty
  "externalRules": [
    "./rules/naming-conventions.json",
    "./rules/farp-operations.json",
    "./rules/tankers.json",
    "./rules/carriers.json",
    "./rules/awacs.json"
  ]
}
```

## Example: Create Separate AWACS Rules File

**Create:** `rules/awacs-rules.json`

```json
{
  "$schema": "../RULES-META.json",
  "version": "1.0.0",
  "description": "AWACS Control rules - separated from main config",
  "categories": [
    {
      "id": "awacs",
      "name": "AWACS Control", 
      "description": "E-2C AWACS configuration rules",
      "rules": [
        {
          "id": "awacs-range-001",
          "name": "AWACS Range Positioning", 
          "description": "AWACS should be positioned for optimal radar coverage",
          "severity": "warning",
          "type": "distance_check",
          "maxDistance": 3000,
          "referencePoint": {
            "x": 0,
            "y": 0
          },
          "target": {
            "task": "AWACS"
          }
        },
        {
          "id": "awacs-freq-001", 
          "name": "AWACS Frequency Standard",
          "description": "AWACS should broadcast 305.00 MHz surveillance",
          "severity": "error",
          "type": "frequency_check",
          "expectedFrequency": 305,
          "tolerance": 0.1,
          "unit": "MHz",
          "target": {
            "task": "AWACS"
          }
        },
        {
          "id": "awacs-alt-001",
          "name": "AWACS High Altitude Standard",
          "description": "AWACS should fly at minimum 30,000 feet for coverage",
          "severity": "info", 
          "type": "altitude_check",
          "minAltitude": 30000,
          "unit": "feet",
          "target": {
            "task": "AWACS"
          }
        },
        {
          "id": "awacs-wp-001", 
          "name": "AWACS Sufficient Waypoints",
          "description": "AWACS should have multiple waypoints for complex orbit pattern",
          "severity": "info",
          "type": "waypoint_count",
          "minCount": 2,
          "target": {
            "task": "AWACS"
          }
        },
        {
          "id": "awacs-orbit-001",
          "name": "AWACS Orbit Pattern Required", 
          "description": "AWACS must have Orbit or Race-track on waypoints to loiter for air superiority coverage",
          "severity": "error",
          "type": "awacs_orbit",
          "target": {
            "task": "AWACS"
          }
        },
        {
          "id": "awacs-options-001", 
          "name": "AWACS Advanced Options Required", 
          "description": "AWACS should have unlimited fuel, invincible, and invisible settings enabled",
          "severity": "info",
          "type": "advanced_options",
          "requiredOptions": ["unlimitedFuel", "invincible", "invisible"],
          "target": {
            "task": "AWACS"
          }
        }
      ]
    }
  ],
  "$comment": "All AWACS rules extracted into separate file for easy editing/sharing"
}
```

Then configure your main config to load it:

**Update** `mission-checklist-config.json`:

```json
{
  /* ... existing categories ... */
  
  "externalRules": [
    "./rules/awacs-rules.json",
    "./rules/farp-rules.json"
  ]
}
```

## Benefits of JSON Rule Extraction

| Benefit | Description |
|---------|-------------|
| **Modularity** | Separate files per category = easier to edit specific areas |
| **Sharing** | Share just `awacs-rules.json` with AWACS-focused teams |
| **Versioning** | Git each rules file separately, track changes by category |
| **Combinations** | Mix-and-match rules for different mission types (e.g., carrier vs land mission) |
| **Testing** | Test one ruleset before integrating into full config |

## Use Cases

### 1. Team-Specific Rules

Each squadron/team maintains their own rule files:

```bash
# Squadrons have custom naming conventions
git clone squad-01-rules.git ./rules/squadron-01.json
cp ./rules/squadron-01.json mission-checklist-config.external.rules

npm install mission-validator
node src/cli.js --rules mission-checklist-config.extended.json Mission.miz
```

### 2. Specialized Mission Types

Create rules for specific mission categories:

- `rules/carrier-missions.json` - CVN/Nimitz-carrier-specific checks  
- `rules/land-battlefield.json` - Ground vehicle + FARP ruleset
- `rules/snowstorm.json` - Winter operations weather settings
- `rules/red-forces-only.json` - RED coalition validation
- `rules/blue-squadron-03.json` - Custom squadron naming
- `rules/dynspawn-required.json` - Hot mission requirements

### 3. Compliance Rulesets

Create compliance documents for deployment:

```json
// rules/compliance-mil-spec.json
{
  "version": "1.0.0",
  "categories": [
    {
      "id": "mil-compliance",
      "name": "MIL-STD Compliance",
      "rules": [/* MILSPEC rules */]  
    }
  ]
}
```

### 4. Predefined Environments

Create environment-specific rules:

```bash
# Dev/DevOps use case
cp mission-checklist-config.json mission-checklist-dev.json

# Only add non-critical warnings in dev
{
  "externalRules": [
    "./rules/safety-only.json",  // Just critical safety checks
    "./rules/dev-environment.json"  // Lenient dev ruleset
  ]
}
```

## Rule File Organization

Recommended folder structure:

```
mission-checklist-config.json          # Main config with externalRules field
├── rules/                              # External rule files
│   ├── awacs-rules.json               # AWACS checks only  
│   ├── carrier-rules.json             # Carrier configuration
│   ├── tanker-specs.json              # Tanker frequency/altitude
│   ├── red-force.json                 # RED coalition validation
│   ├── blue-aircraft.json             # BLUE player requirements
│   ├── farp-ops.json                  # FARP checks
│   └── cleanup.json                   # Test aircraft removal
├── missions/                           # Mission-specific configs
│   ├── mission1-rules.json            # Mission 1 custom rules
│   └── mission2-rules.json
└── cli.js                             # Command line interface
```

Command usage:

```bash
# Load specific rule file for mission
node src/cli.js --rules ./rules/awacs-rules.json mission.miz

# Or set via environment variable  
export MISSION_VALIDATOR_RULES_PATH=./rules/snowstorm-checks.json
node src/cli.js mission.miz  # Uses snowstorm rules automatically
```

## Example CLI Usage Patterns

### Pattern 1: Load External Rules Only

```bash
# Use only external rules, ignore default config
MISSION_VALIDATOR_USE_EXTERNAL_ONLY=1 \
node src/cli.js --rules ./rules/squadron-rules.json Mission.miz
```

This creates a new validation ruleset from scratch using just the external rules files.

### Pattern 2: Merge Base + External Rules  

```bash
# Validate mission with both default and custom rules
export MISSION_VALIDATOR_RULES_PATH=./rules/awacs-checks.json \
node src/cli.js mission.miz
```

The validator merges default config rules + external rules automatically. Duplicates are preserved for you to edit.

### Pattern 3: Switching Rule Sets by Environment

```yaml
# CI/CD pipeline example
name: Validate Mission
run: |
  case $ENV in
    production)
      MISSION_VALIDATOR_RULES_PATH=./rules/certified-checklist.json
      ;;
    staging)  
      MISSION_VALIDATOR_RULES_PATH=./rules/staging-checklist.json
      ;;
    development)
      # No rules = pass-through validation
      ;;
  esac
  
  node src/cli.js $MIZ_FILE
```

## Valid Rule File Format

Every rule file should follow this schema:

```json
{
  "$schema": "../RULES-META.json",
  "version": "1.0.0",
  "description": "Description of this ruleset", 
  "categories": [
    {
      "id": "category_id",
      "name": "Category Display Name",
      "priority": "high|medium|low",
      "rules": [
        /* Array of rule objects */
      ]
    }
  ],
  "$schemaHint": "Optional hint for validators about this file's purpose"
}
```

## Tips for Creating Rule Files

✅ **Good Practices:**

- Start with 5-10 rules, split into different categories if you grow beyond that
- Use descriptive rule IDs from your unit numbering system (e.g., `naming-gs-001`)
- Document any special reasoning in description field
- Use appropriate severity levels based on impact

❌ **Avoid:**

- Combining unrelated rules into single large file
- Duplicating rule logic across multiple files  
- Creating circular categories or duplicate rule IDs

## Next Steps

1. **Review** the existing `rules/sample-external-rules.json` file
2. **Extract** individual category rules if you want to maintain them separately
3. **Update** your main config to load external rules using the `externalRules` field
4. **Test** with different rule combinations before committing

## Validation Checklist

Before sharing your rules file:

- [ ] Use unique rule IDs (no duplicates)
- [ ] Each rule has description explaining why
- [ ] Severity levels match impact (critical for safety/mission-blocking)
- [ ] No missing fields in rule objects
- [ ] File path relative to config is correct
- [ ] Test with a sample mission first

## See Also

- [`docs/EXTERNAL-RULES.md`](./EXTERNAL-RULES.md) - Full documentation 
- [`rules/sample-external-rules.json`](../rules/sample-external-rules.json) - Sample ruleset
- [`src/validator.js`](../src/validator.js) - Implementation showing how rules are loaded

## License Notes

If you modify rule files, remember to keep the license header in any distribution. Don't redistribute proprietary rulesets without authorization.
