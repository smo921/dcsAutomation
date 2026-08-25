# Using Extracted JSON Rule Files

## Quick Start

You now have **10 separate rule files** for mission validator customization:

```bash
# Load all extracted rules into main config
cat > complete-checklist.json << 'CONFIG'
{
  "version": "1.0.0",
  "description": "Complete DCS mission validation checklist",
  "categories": [],
  "externalRules": [
    "./rules/awacs.json",
    "./rules/farp-rules.json", 
    "./rules/tankers.json",
    "./rules/carrier-rules.json",
    "./rules/red-air-forces.json",
    "./rules/blue-aircraft-checks.json", 
    "./rules/base-ground-checks.json",
    "./rules/naming-conventions.json",
    "./rules/weather-settings.json",
    "./rules/cleanup-rules.json"
  ]
}
CONFIG

# Validate mission with complete ruleset
node src/cli.js --config complete-checklist.json mission.miz
```

## Extracted Modules Available

| File | Category | Rules | Priority |
|------|----------|-------|----------|
| **awacs.json** | AWACS Control | 6 | Critical |
| **farp-rules.json** | FARP Operations | 4 | Critical |
| **tankers.json** | Tanker/Refueling | 6 | High |
| **carrier-rules.json** | CVN Carriers | 5 | Critical |
| **red-air-forces.json** | RED Air Units | 3 | Medium |
| **blue-aircraft-checks.json** | BLUE Aircraft | 6 | Critical |
| **base-ground-checks.json** | Base Config | 3 | High |
| **naming-conventions.json** | Naming Pattern | 3 | Low |
| **weather-settings.json** | Environment | 4 | Medium |
| **cleanup-rules.json** | Cleanup | 4 | High |

## Usage Examples

### Example 1: Load Specific Category Only

```bash
# AWACS-only check
node src/cli.js --config ./rules/awacs.json mission.miz

# Carrier-only check  
node src/cli.js --config ./rules/carrier-rules.json mission.miz
```

### Example 2: Create Custom Ruleset

```javascript
// squad-03-config.json
{
  "version": "1.0.0",
  "categories": [],  
  "externalRules": [
    "./rules/awacs.json",       // AWACS team needs this
    "./rules/farp-rules.json",   // FARP team needs this
    "./rules/naming-conventions.json"  // Naming standards
  ]
}

node src/cli.js --config squad-03-config.json mission.miz
```

### Example 3: Use Multiple Rule Files in Sequence

```bash
# Check critical issues first
node src/cli.js --config ./rules/critical-safety-checks.json mission.miz

# Then detailed checks  
export MISSION_VALIDATOR_RULES_PATH=./rules/advanced-config.json
node src/cli.js mission.miz
```

### Example 4: CI/CD Pipeline with Multiple Rule Files

```bash
#!/bin/bash -c validation script

# Phase 1: Safety checks only (CI gates must pass)
export MISSION_VALIDATOR_RULES_PATH=./rules/safety-only.json
npm install ./dcsAutomation/mission-validator
node src/cli.js mission.miz | grep -q "passed" || exit 1

# Phase 2: Full validation with all rules
export MISSION_VALIDATOR_RULES_PATH=./rules/full-compliance.json  
node src/cli.js mission.miz > validation-report.txt
```

## How to Add Your Own Rules

### Step 1: Choose Category Rule File

Pick a category to edit:

```bash
# Start from existing file for your category
cp ./rules/tankers.json ./rules/my-tankers.rules.json
```

### Step 2: Modify Rules

Edit the `my-tankers.rules.json` file, add your custom rules:

```json
{
  "categories": [
    {
      "id": "tankers", 
      "name": "Tanker/Refueling",
      "rules": [
        /* ... existing tankers ... */
        {
          "id": "custom-tanker-rules-001",
          "name": "My Tanker Altitude Rule",
          "description": "Custom organization tanker altitude requirement",
          "severity": "warning", 
          "type": "altitude_check",
          "expectedAltitude": 37500,
          "unit": "feet",
          "target": { "task": "Tanker" }
        }
      ]
    }
  ]
}
```

### Step 3: Load Custom File

```bash
node src/cli.js --config ./rules/my-tankers.rules.json mission.miz
```

## Loading Rules in CLI Arguments

```bash
node src/cli.js mission.miz -c config-file.json

# or use env var
export MISSION_VALIDATOR_RULES_PATH=./rules/certified-checklist.json  
node src/cli.js mission.miz
```

## Creating Rule from Scratch

### Create New Category: Carrier Air Support Rules

```bash
cat > ./rules/carrier-air-support.json << 'RULE'
{
  "$schema": "../RULES-META.json", 
  "version": "1.0.0",
  "description": "Air support for CV carrier operations",
  "categories": [
    {
      "id": "air_support_carriers", 
      "name": "Carrier Air Support",
      "description": "Rules for carriers and supporting aircraft",
      "rules": []
    }
  ]
}
RULE

# Add rules as needed:
cat > ./rules/carrier-air-support.json << 'CUSTOM_RULE'  
{
  "$schema": "../RULES-META.json", 
  "version": "1.0.0",
  "description": "CVN carrier air support configuration",
  "categories": [
    {
      "id": "carrier_air_support",
      "name": "Carrier Air Support",
      "priority": "high",
      "rules": [
        {
          "id": "air-support-alt-001",
          "name": "Support Aircraft Altitude Standard", 
          "description": "Escort and support aircraft should fly at appropriate altitudes",
          "severity": "info",
          "type": "altitude_check",
          "expectedAltitude": 40000,
          "unit": "feet",
          "tolerance": 2000 
        }
      ]
    }
  ]
}
CUSTOM_RULE
```

### Step 4: Load in Config

```json
{
  "categories": [],
  "externalRules": [
    "./rules/carrier-air-support.json"
  ]
}
```

## Sharing Rules with Teams

### Export Rules to Team Repository

```bash
# Share only critical rules
git clone https://github.com/company/dcs-critical-rules.git ./rules/critical-checks.json
cp critical-checks.json -r ./mission-checklist-config.rules.json  # Use in mission config


# Import from repo
npm install @company/dcs-critical-checks
npm test
node src/cli.js --config ./rules/@company/dcs-critical/rules/mission-checklist.config.json mission.miz
```

### Team Workflow Example

Team Lead creates rules file:

```bash
cat > rules/squadron-specific-config.rules.json << 'TEAMRULES'  
{
  "$schema": "../RULES-META.json",
  "version": "1.0.0",
  "description": "Squad-3 Specific Rules",
  "categories": [
    {
      "id": "squadron-naming",
      "name": "My Squadron Naming Standards"
    }
  ]
}
TEAMRULES

# Export team-specific configuration file to git  
git push rules repo
```

Team members clone and use:

```bash
cp squad-3-rules.json mission-checklist-config.rules.json
node src/cli.js --config mission-checklist.config.rules.json mission.miz
```

## Troubleshooting

### External Rules File Not Found

```bash
# Check file path exists
ls -la ./rules/my-rule-file.json

# Use absolute path or relative to cwd
absolute_path=/home/smo/tmp/pitest/dcsAutomation/mission-validator/rules/*/*.json
```

### Category Duplicate Error

Each external rules must have unique category_id. Use different IDs:

```json
// ❌ Bad: duplicate awacs category ID
{ "categories": [{ "id": "awacs", ... }] }  // Don't use same ID

// ✅ Good: use distinct categories
{ 
  "categories": [
    { "id": "my-awacs-checks", ... },
    { "id": "awacs-standard", ... }  
  ]
}
```

### External Rules Not Merging

```bash
# Ensure config.json has externalRules array properly defined
cat > test-config.json << 'TESTCONFIG'
{
  "version": "1.0.0",
  "$schema": "../RULES-META.json",
  "externalRules": [
    "./rules/example-rule-file-001.json"
  ]
}
TESTCONFIG

# Load test configuration and see error  
node src/cli.js --config test-config.json mission.miz
```

### Rule IDs Are Duplicates

External files with same rule id:

```json
// ❌ Error: duplicate IDs in merged config  
[
  { "id": "carrier-freq-001", ... }, // from file A
  { "id": "carrier-freq-001", ... }  // from file B - ERROR!
]  

// ✅ Warning: duplicate kept for editing but may cause issues  
// Check rule ID uniqueness before merging multiple files
```

## Best Practices

### Do:
- One categorical file = one JSON rules file
- Unique category_id and rule_id in each external file  
- Include metadata: $schema, version, description
- Test rules with sample missions before publishing  
- Document custom rules in comments

### Don't:
- Duplicate same category across multiple files  
- Embed categories inline when using externalRules field  
- Forget to include target specifications for each rule type  
- Overcomplicate rules - keep them readable and simple  

## Files Reference Diagram

```
mission-checklist-config.base.json          <- base default config (with your rules)
├── → mission-compliance.rules.json         <- merged with all external rules
│   └── externalRules: [
│       "./rules/awacs.json",
│       "./rules/farp-rules.json",
│       "./rules/red-air-forces.json"  ...etc
│     ]

custom-checklist.base-config.json             <- custom configuration for org use
├── → config-extended-with-squadron.rules.json
    └── externalRules: [
        "./rules/squadron-naming-01.rules.json",
        "./rules/mil-standard-compliance-rules.json"  ...etc
      ]

CI/CD pipeline configuration                    <- environment-specific validation
├── → rules-critical-safety-only.json         <- safety checks only for CI gates  
│   └── externalRules: [
│       "./rules/safety-checks-only.rules.json"
│     ]

```

## Complete Example: Full Production Config

Create full checklist configuration:

```bash
cat > complete-checklist.production.rules.json << 'FULLCONFIG'
{
  "$schema": "../RULES-META.json",
  "version": "1.0.0",
  "description": "Complete production DCS mission validation ruleset",
  "externalRules": [
    "./rules/awacs.json",               # AWACS checks (critical)
    "./rules/carrier-rules.json",       # Carrier ops (critical)  
    "./rules/blue-aircraft-checks.json",# BLUE air checks (critical)
    "./rules/cleanup-rules.json",       # Remove test aircraft (critical)
    "./rules/farp-rules.json",          # FARP configs (high priority)  
    "./rules/tankers.json",             # Tanker configurations (high)
    "./rules/carriers.json",            # Carrier variants (high)
    "./rules/base-ground-checks.json",  # Ground base rules (medium priority)
    "./rules/red-air-forces.json",      # RED force configs (low) 
    "./rules/naming-conventions.json",  # Naming standards (suggestion)
    "./rules/weather-settings.json"     # Environmental checks (info)
  ]
}
FULLCONFIG

# Validate complete production configuration  
node src/cli.js --config complete-checklist.production.rules.json mission.miz
```

## See Also

- `docs/EXTERNAL-RULES.md` - Detailed documentation for rule definitions  
- `docs/WITH-EXAMPLES.md` - Usage examples in various scenarios
- `RULES-META.json` (if exists) - Schema for validating rule files

EOF  

echo "Created complete usage guide: USAGE-GUIDE.md" 
