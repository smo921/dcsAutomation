# DCS Mission Validator

Automated validation tool for DCS World missions based on the mission making checklist.

## Features

- ✅ **Automated Checklist Validation** - Validates missions against comprehensive checklist rules
- 🎯 **Standalone CLI Tool** - Run validation from command line
- 🔌 **Mission Editor Integration** - Real-time validation in the mission editor
- 📊 **Detailed Reports** - Get specific error messages and suggestions
- ⚙️ **Configurable Rules** - Customize validation rules via JSON configuration
- 🚀 **CI/CD Ready** - Perfect for automated mission testing pipelines

## Installation

### As Standalone Tool

```bash
cd mission-validator
npm install
npm link  # Makes 'dcs-validator' available globally
```

### As Part of Mission Editor

The validator is already integrated into the mission editor. No additional installation needed.

## Usage

### Command Line Interface

```bash
# Basic validation
dcs-validator mission.miz

# With custom config
dcs-validator mission.miz -c custom-config.json

# With DCS installation path (for terrain data)
dcs-validator mission.miz -d "C:\Program Files\DCSWorld"

# Export results to JSON
dcs-validator mission.miz -o results.json
```

#### CLI Options

```
Usage:
  dcs-validator <miz-file> [options]

Arguments:
  <miz-file>              Path to .miz mission file

Options:
  -c, --config <path>     Path to validation config JSON
  -d, --dcs-path <path>   Path to DCS installation
  -o, --output <path>     Export results to JSON file
  -h, --help              Show help message
  -v, --version           Show version number
```

### Mission Editor Integration

The validator appears as a panel in the mission editor UI:

1. Open mission in editor
2. Click "Validation" tab
3. Click "Validate Mission"
4. Review errors, warnings, and suggestions

**Auto-Validation**: Enable auto-validate to check the mission as you make changes.

## Validation Rules

The validator checks missions against these categories:

### Naming Conventions
- BLUE force naming pattern
- RED force naming pattern

### FARP Operations
- Distance from RED forces (min 10nm)
- Dynamic spawn enabled
- Hot start allowed
- Support buildings nearby
- Wind sock present

### AWACS Configuration
- Range positioning
- Frequency (305.00 MHz)
- Altitude (above 30k)
- Waypoint count and actions
- Advanced options (unlimited fuel, invincible, invisible)

### Tanker Configuration
- Altitude (20k)
- Speed (max 300 knots)
- Late activation
- Aircraft-specific frequencies and TACAN

### Carrier Configuration
- CVN73/74 frequency and settings
- Dynamic spawn and hot start
- TACAN/ILS activation

### RED Air Forces
- Advanced options
- Task assignments
- Patrol patterns

### BLUE Aircraft
- Client type setting
- Communication channels
- Mission-specific frequencies
- Aircraft-specific configurations

### Base Configuration
- Dynamic spawn and hot start
- RED force proximity

### Weather Settings
- Time of day
- Cloud cover
- Wind speed

### Mission Cleanup
- No test aircraft
- No test scripting

## Severity Levels

- **Critical** (❌) - Mission-breaking errors
- **Error** (❌) - Must be fixed before approval
- **Warning** (⚠️) - Should be fixed, mission still usable
- **Info** (ℹ️) - Suggestions for improvement

## Custom Configuration

Create a custom validation config by copying `mission-checklist-config.json`:

```json
{
  "version": "1.0.0",
  "categories": [
    {
      "id": "custom",
      "name": "Custom Rules",
      "priority": "high",
      "rules": [
        {
          "id": "custom-001",
          "name": "My Custom Rule",
          "description": "Description of what this checks",
          "severity": "warning",
          "type": "property_check",
          "target": {
            "coalition": "blue"
          }
        }
      ]
    }
  ]
}
```

### Rule Types

- `naming_pattern` - Check unit names against regex pattern
- `distance_check` - Validate distances between objects
- `property_check` - Check boolean/property values
- `proximity_check` - Validate nearby objects
- `presence_check` - Check for required objects
- `frequency_check` - Validate radio frequencies
- `altitude_check` - Check altitude settings
- `waypoint_count` - Validate waypoint numbers
- `waypoint_action` - Check waypoint actions
- `speed_check` - Validate speed settings
- `task_check` - Check assigned tasks
- `comm_check` - Validate communication channels
- `absence_check` - Ensure forbidden items are absent
- `script_check` - Validate trigger scripts

## Integration Guide

### Using in Your Own Application

```javascript
import { MissionValidator } from './mission-validator/src/validator.js'

const validator = new MissionValidator('path/to/config.json')
const results = await validator.validateMizFile('mission.miz')

console.log(`Mission Score: ${results.score}%`)
console.log(`Errors: ${results.errors.length}`)
console.log(`Warnings: ${results.warnings.length}`)
```

### Mission Editor Integration

```javascript
import { MissionEditorValidator } from './mission-editor/src/main/missionValidator.js'

const validator = new MissionEditorValidator(editorInstance)
validator.initialize()

// Auto-validates on mission changes
validator.onValidation((results) => {
  console.log('Validation results:', results)
})
```

## Exit Codes

- `0` - Validation passed (no errors)
- `1` - Validation failed (errors found)
- `2` - Invalid arguments or file not found

## Examples

### Validate and Export

```bash
dcs-validator operation.miz -o validation-results.json
```

### Custom Rules

```bash
dcs-validator mission.miz -c squadron-rules.json
```

### CI/CD Pipeline

```yaml
# GitHub Actions example
- name: Validate Mission
  run: |
    npm install -g dcs-mission-validator
    dcs-validator missions/operation.miz
```

## Troubleshooting

### "Config file not found"
Ensure the config file exists at the specified path or use the default config.

### "DCS installation not found"
Provide the correct DCS installation path with `-d` option.

### "Mission file is corrupted"
The .miz file may be corrupted or not a valid DCS mission file.

## Development

### Running Tests

```bash
npm test
```

### Linting

```bash
npm run lint
npm run format
```

## License

ISC - See main project license

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new validation rules
4. Submit a pull request

## Support

For issues or questions, please open an issue on the GitHub repository.
