# Validation Rules Fix Plan

## Overview
After running validation on Georgian-Scramble.miz, several rules produced false positives because they don't account for different unit types (client vs AI, air vs ground, etc.).

## Issues Identified

### 1. BLUE Force Naming Standard (naming-blue-force-001)
**Problem**: Requires ALL blue units to have specific prefixes (Blue-X, etc.), but:
- Client/player aircraft use their own naming (callsigns like "Hodges", "Trigger", etc.)
- Only AI units need standardized naming for identification
- Ground units may have different naming conventions

**Fix Needed**: 
- Split into separate rules for AI vs Client units
- OR exclude client-controlled units from naming pattern checks
- Add ground unit naming exceptions

**Priority**: HIGH

---

### 2. BLUE COMM Channels Set (blue-comm-001)
**Problem**: Requires ALL blue units to have UHF/VHF radios, but:
- AI ground units don't need communication channels
- Only client aircraft and some AI aircraft need COM radios
- Static ground units don't need radios

**Fix Needed**:
- Limit to aircraft only (type: "plane" or "helicopter")
- OR limit to client-controlled units only
- Add exception for ground units

**Priority**: HIGH

---

### 3. BLUE Base Dynamic Spawn (blue-base-dynspawn-001)
**Problem**: Checks all blue ground units for dynSpawnTemplate, but:
- Only dynamic spawn units need this property
- Static units don't need dynamic spawn enabled
- Aircraft don't need ground spawn settings

**Fix Needed**:
- Clarify target to only dynamic ground units
- OR change severity to "warning" for non-critical units
- Add unit type filtering

**Priority**: MEDIUM

---

### 4. BLUE Base Hot Start Support (blue-base-hotstart-001)
**Problem**: Same as #3 - applies to all blue units
**Fix Needed**: Same approach as #3
**Priority**: MEDIUM

---

### 5. CAP Frequency Standard (blue-cap-freq-001)
**Problem**: Requires 485 MHz for CAP missions, but:
- Need to verify if 485 MHz is the correct standard frequency
- Different aircraft may use different frequencies
- Tolerance of 1.0 MHz may be too strict

**Fix Needed**:
- Verify correct CAP frequency standard
- Adjust tolerance if needed
- Consider different frequencies for different aircraft types

**Priority**: LOW (after verifying correct frequency)

---

### 6. RED Force Naming Standard (naming-red-force-001)
**Problem**: Requires specific Red-X patterns, but actual mission uses simpler names
**Fix Needed**:
- Update pattern to match actual naming conventions used
- OR make rule less strict (warning instead of error)

**Priority**: MEDIUM

---

### 7. RED Air Advanced Options (red-air-advanced-001)
**Problem**: Requires advanced options for all RED air units, but:
- Some units may not need advanced options
- Client-controlled RED units may not need AI tasks

**Fix Needed**:
- Limit to AI-controlled units only
- Add exceptions for certain mission types

**Priority**: MEDIUM

---

### 8. RED Air Task Standard (red-air-task-001)
**Problem**: Requires specific tasks for all RED air units
**Fix Needed**:
- Verify task requirements are appropriate
- Consider different tasks for different mission phases

**Priority**: LOW

---

## Implementation Order

### Phase 1: Critical Fixes (HIGH Priority)
1. Fix BLUE naming rule to exclude client aircraft
2. Fix BLUE COMM rule to exclude ground units

### Phase 2: Important Fixes (MEDIUM Priority)
3. Fix BLUE base rules to target only appropriate units
4. Fix RED naming rule
5. Fix RED air advanced options rule

### Phase 3: Verification (LOW Priority)
6. Verify CAP frequency standards
7. Verify RED air task requirements

---

## Rule File Locations

- `mission-validator/rules/naming-conventions.json` - Naming patterns
- `mission-validator/rules/blue-aircraft-checks.json` - BLUE aircraft rules
- `mission-validator/rules/base-ground-checks.json` - Base configuration rules
- `mission-validator/rules/red-air-forces.json` - RED air force rules

---

## Testing Strategy

For each rule fix:
1. Update the rule JSON with corrected target/conditions
2. Run validation on Georgian-Scramble.miz
3. Verify false positives are eliminated
4. Verify legitimate issues are still caught
5. Document the change

---

## Success Criteria

- ✅ No false positives for client aircraft naming
- ✅ No false positives for AI ground unit COMM channels
- ✅ Base rules only apply to appropriate unit types
- ✅ All rules have clear, documented purpose
- ✅ Validation score reflects actual mission quality issues
