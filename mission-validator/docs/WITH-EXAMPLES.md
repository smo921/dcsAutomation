# Using External JSON Rule Files - Quick Reference

## What You Just Created

You now have modular rule files that can be loaded separately:

```
rules/
├── awacs-extracted.json    # 6 AWACS rules
├── tankers.json            # 6 tanker rules  
├── carriers.json           # 5 carrier rules
└── cleanup-rules.json      # 4 cleanup rules
```

## Quick Usage Examples

### Example 1: Load External AWACS Rules Only

```bash
# Override default config with AWACS-only rules
node src/cli.js \
  --config ./rules/awacs-extracted.json \
  mission.miz
```

**Output:** Validates only AWACS-related checks against this mission.

### Example 2: Merge Custom Rules with Default Config

```bash
# Create a custom config that merges external rules
cat > custom-config.json << 'EOF'
{
  "$schema": "RULES-META.json",
  "version": "1.0.0",
  "categories": [],
  "externalRules": [
    "./rules/awacs-extracted.json",
    "./rules/tankers.json",
    "./rules/cleanup-rules.json"
  ]
}
EOF

# Use it
node src/cli.js --config custom-config.json mission.miz
```

### Example 3: Load via Environment Variable

```bash
# Set paths to rules files  
export MISSION_VALIDATOR_RULES_PATH=./rules/snowstorm-checks.json

# Validator automatically merges specified rules with default config
node src/cli.js mission.miz
```

### Example 4: Use Custom Rules File Directly

```bash
# Create mission-specific rule file
cat > ./rules/georgian-scramble-rules.json << 'EOF'
{
  "$schema": "../RULES-META.json",
  "version": "1.0.0",
  "description": "Georgian Scramble specific rules",
  "categories": [
    {
      "id": "gs-specific",
      "name": "Georgian Scramble Checklist",
      "priority": "critical",
      "rules": [/* Your GS rules */]
    }
  ]
}
EOF

# Validate mission with custom ruleset  
node src/cli.js --config ./rules/georgian-scramble-rules.json Georgian-Scramble.miz
```

### Example 5: Create Combined Rules File

**Create:** `complete-checklist.json`

```bash
cat > complete-checklist.json << 'EOF'
{
  "$schema": "RULES-META.json",
  "version": "1.0.0", 
  "description": "Complete DCS mission checklist combining all rules",
  "categories": [],
  "externalRules": [
    "./rules/awacs-extracted.json",      # AWACS checks
    "./rules/tankers.json",              # Tanker checks
    "./rules/carriers.json",             # Carrier checks  
    "./rules/cleanup-rules.json",        # Clean-up checks
    "./rules/naming-conventions.json"    # Naming rules (if exists)
  ]
}
EOF

# Validate mission with complete checklist
node src/cli.js --config complete-checklist.json mission.miz
```

### Example 6: Run Multiple Rule Checks in Sequence

```bash
# Check naming conventions (less severe issues first)
node src/cli.js --config ./rules/naming-rules.json mission.miz

# Then check AWACS (critical mission elements)
node src/cli.js --config ./rules/awacs-extracted.json mission.miz

# Finally full validation  
node src/cli.js --config complete-checklist.json mission.miz
```

### Example 7: Use Rules for CI/CD Pipeline

```yaml
# .github/workflows/validate.yml  
name: Validate Mission
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          
      - name: Validate mission
        run: |
          npm install ./dcsAutomation/mission-validator
          MISSION_VALIDATOR_RULES_PATH=./rules/certified-checklist.json \
          node src/cli.js "$MIZ_FILE" || exit 1
          
      - name: Export validation report
        run: |
          cat results/*.json
```

### Example 8: Environment-Specific Rules

```bash
# Development - skip checks
node src/cli.js mission.miz  # Passes through default config only (if exists)

# Production - full compliance  
export MISSION_VALIDATOR_RULES_PATH=./rules/mil-standard.json
node src/cli.js mission.miz
```

## How the Validator Loads External Rules

The validator automatically:

1. **Loads** your main config file first
2. **Reads** any `externalRules` array field from config  
3. **Merges** rules from each external JSON file into corresponding categories
4. **Preserves** duplicates (for incremental overrides you can edit)
5. **Validates** against all merged rules

### Example of Automatic Merging:

If your main config has an `awacs` category with 2 rules:

```json
{
  "categories": [
    {
      "id": "awacs",
      "name": "AWACS Control", 
      "rules": [/* default awacs-001, awacs-002 */]
    }
  ],
  "externalRules": ["./rules/awacs-extracted.json"]
}
```

The validator merges `awacs-extracted.json` and your config now has **8 AWACS rules total**.

## Creating Your Own Rule File

Template to get started:

```json
{
  "$schema": "../RULES-META.json",
  "version": "1.0.0",
  "description": "Insert description here",
  "categories": [
    {
      "id": "your-category-id",
      "name": "Your Category Name",
      "priority": "high|medium|low",
      "rules": [
        {
          "id": "rule-001",
          "name": "Rule Display Name",
          "description": "What this rule checks for",
          "severity": "error|warning|info|critical",
          "type": "naming_pattern|altitude_check|frequency_check|...",
          /* ... your rule-specific fields here */
          "target": {
            /* target criteria: coalition, unitType, task, etc. */
          }
        }
      ]
    }
  ]
}
```

## Rule Types Available

All of these work in external JSON files:

| Rule Type | Example Use Case |
|-----------|------------------|
| `naming_pattern` | Unit name validation |
| `altitude_check` | AWACS height requirements |
| `frequency_check` | Radio frequency standards  |
| `property_check` | Property value validation |
| `distance_check` | Positional constraints |
| `presence_check` | Required features present |
| `absence_check` | Forbidden elements absent |
| `waypoint_count` | Route waypoint counts |
| `advanced_options` | Enabled mission options |
| `task_check` | Task assignment rules |
| `awacs_orbit` | AWACS orbit pattern |
| `aircraft_config` | Aircraft frequency/settings |

## Tips for External Rules Files

### Start Small:

Don't overload one file. Split by category:

```json
// rules/awacs-only.json    # Just awacs
{ "categories": [/* awacs only */] }

// rules/tankers-only.json  # Just tankers  
{ "categories": [/* tankers only */] }

// rules/carriers.json       # Just carriers
{ "categories": [/* carriers only */] }
```

### Make Editable:

Keep rules sorted by priority so you can find what matters first:

```json
"rules": [
  { "id": "critical-safety-check",   // Must-fix safety rules...
    "severity": "error",
    ... },
  
  { "id": "warning-config-check",    // Config issues...
    "severity": "warning", 
    ... },
    
  { "id": "info-good-practice",      // Suggestions...
    "severity": "info",
    ... }
]
```

## Full Example: Building from Scratch

1. **Create** folder for new rules files:

```bash
mkdir -p dcsAutomation/mission-validator/rules
```

2. **Copy** template and customize:

```bash
# Start with sample file  
cp rules/sample-external-rules.json rules/squadron-specific.json

# Edit squadron-specific.json to match your unit's naming conventions
```

3. **Merge** into main config:

```json
// mission-checklist-custom.json
{
  "$schema": "RULES-META.json",
  "version": "1.0.0",
  "categories": [],
  "externalRules": [
    "./rules/squadron-specific.json",
    "./rules/mil-spec-compliance.json",
    "./rules/mission-type-rules.json"
  ]
}
```

4. **Validate** your mission:

```bash
node src/cli.js --config mission-checklist-custom.json Mission.miz
```

## See Also

- `docs/EXTENDING-MISSIONS-WITH-JSON-RULES.md` - Complete documentation
- `rules/sample-external-rules.json` - Sample ruleset to start from
- `docs/WITH-EXAMPLES.md` (this file) - Usage examples  
- `src/validator.js` - Implementation showing rule loading

## Questions?

If you want to:
- Add a new rule type → see `src/validator.js` for implementation
- Create custom rule syntax → check existing sample rules in `rules/`
- Share rules with a team → use the externalRules field pattern above
- Debug rule issues → check JSON schema against RULES-META.json

---

**That's it!** You can now extract any category of rules into separate JSON files and load them modularly for easier editing, sharing, and combination.
