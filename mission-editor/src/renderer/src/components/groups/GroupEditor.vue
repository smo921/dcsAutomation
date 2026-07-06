<template>
  <div class="group-editor">
    <!-- Save/Cancel Toolbar -->
    <div class="editor-toolbar">
      <Button @click="onSave" variant="primary">Save</Button>
      <Button @click="onCancel" variant="secondary">Cancel</Button>
    </div>

    <div class="editor-content">
      <!-- Basic Settings -->
      <CollapsibleSection v-model:expanded="expandedSections.basic" title="Basic Settings">
        <div class="editor-section">
          <div class="form-row">
            <div class="form-group">
              <label>Group Name</label>
              <input type="text" v-model="group.groupName" class="form-input" />
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Category</label>
              <select v-model="group.category" class="form-input">
                <option value="AIRPLANE">Airplane</option>
                <option value="HELICOPTER">Helicopter</option>
                <option value="GROUND">Ground Unit</option>
                <option value="SHIP">Ship</option>
                <option value="STATIONARY">Stationary</option>
              </select>
            </div>
            <div class="form-group">
              <label>Country</label>
              <input type="text" v-model="group.country" class="form-input" />
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Task</label>
              <select v-model="group.task" class="form-input">
                <option value="">Default</option>
                <option value="AWACS">AWACS</option>
                <option value="Refueling">Tanker</option>
                <option value="CAP">CAP</option>
                <option value="CAS">CAS</option>
                <option value="Intercept">Intercept</option>
                <option value="Ground Attack">Ground Attack</option>
              </select>
            </div>
            <div class="form-group">
              <label>Trigger Type</label>
              <select v-model="group.triggerType" class="form-input">
                <option value="IMMEDIATE">Immediate</option>
                <option value="RADAR">Radar Detection</option>
                <option value="TRIGGER_ZONE">Trigger Zone</option>
                <option value="OBJECTIVE_COMPLETE">Objective Complete</option>
              </select>
            </div>
          </div>
        </div>
      </CollapsibleSection>

      <!-- Units Section -->
      <CollapsibleSection v-model:expanded="expandedSections.units" title="Units">
        <div class="editor-section">
          <div v-for="(unit, index) in group.units" :key="index" class="unit-row" :data-unit-num="index + 1">
            <div class="unit-number-badge">{{ index + 1 }}</div>
            <div class="unit-content">
              <div class="form-row">
                <div class="form-group">
                  <label>Unit Type</label>
                  <input type="text" v-model="unit.type" class="form-input" />
                </div>
                <div class="form-group">
                  <label>Quantity</label>
                  <input type="number" v-model="unit.quantity" min="1" class="form-input" />
                </div>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label>Name</label>
                  <input type="text" v-model="unit.name" class="form-input" />
                </div>
                <div class="form-group">
                  <label>Role</label>
                  <input type="text" v-model="unit.role" class="form-input" />
                </div>
              </div>
              <button class="btn-remove" @click="removeUnit(index)" title="Remove Unit"><span class="btn-remove-icon">✕</span></button>
            </div>
          </div>
          <Button @click="addUnit" variant="secondary" size="sm" class="btn-add-unit">+ Add Unit</Button>
        </div>
      </CollapsibleSection>

      <!-- Placement Section -->
      <CollapsibleSection v-model:expanded="expandedSections.placement" title="Placement">
        <div class="editor-section">
          <div class="form-row">
            <div class="form-group">
              <label>Placement Mode</label>
              <select v-model="group.placement.mode" class="form-input">
                <option value="BEARING_DISTANCE">Bearing + Distance</option>
                <option value="COORDINATE">Direct Coordinates</option>
                <option value="AIRBASE_RAMP">Airbase Ramp</option>
                <option value="ZONE_CENTER">Zone Center</option>
                <option value="WAYPOINT">Waypoint Anchor</option>
              </select>
            </div>
          </div>

          <!-- Bearing + Distance -->
          <div v-if="group.placement.mode === 'BEARING_DISTANCE'" class="placement-config">
            <div class="form-row">
              <div class="form-group">
                <label>Reference Type</label>
                <select v-model="group.placement.reference" class="form-input">
                  <option value="bullseye">Bullseye</option>
                  <option value="airbase">Airbase</option>
                  <option value="zone">Zone</option>
                  <option value="battle_line">Battle Line</option>
                </select>
              </div>
              <div class="form-group">
                <label>Reference Name</label>
                <select v-model="group.placement.referenceName" class="form-input">
                  <option value="" disabled>Select a reference...</option>
                  <!-- Bullseye options -->
                  <template v-for="b in refpoints.bullseyes" :key="'bs-' + b.name" v-if="group.placement.reference === 'bullseye'">
                    <option :value="b.name">{{ b.name }}</option>
                  </template>
                  <!-- Airbase options -->
                  <template v-for="a in refpoints.airbases" :key="'ab-' + a.name" v-if="group.placement.reference === 'airbase'">
                    <option :value="a.name">{{ a.name }}</option>
                  </template>
                  <!-- Zone options -->
                  <template v-for="z in refpoints.zones" :key="'z-' + z.name" v-if="group.placement.reference === 'zone'">
                    <option :value="z.name">{{ z.name }}</option>
                  </template>
                  <!-- Line options -->
                  <template v-for="l in refpoints.lines" :key="'l-' + l.name" v-if="group.placement.reference === 'battle_line'">
                    <option :value="l.name">{{ l.name }}</option>
                  </template>
                </select>
              </div>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Bearing (degrees)</label>
                <input type="number" v-model="group.placement.bearing" min="0" max="360" class="form-input" />
              </div>
              <div class="form-group">
                <label>Distance (NM)</label>
                <input type="number" v-model="group.placement.distance" min="0" class="form-input" />
              </div>
            </div>
          </div>

          <!-- Direct Coordinates -->
          <div v-if="group.placement.mode === 'COORDINATE'" class="placement-config">
            <div class="form-row">
              <div class="form-group">
                <label>X Coordinate</label>
                <input type="number" v-model="group.placement.x" class="form-input" />
              </div>
              <div class="form-group">
                <label>Y Coordinate</label>
                <input type="number" v-model="group.placement.y" class="form-input" />
              </div>
            </div>
          </div>

          <!-- Airbase Ramp -->
          <div v-if="group.placement.mode === 'AIRBASE_RAMP'" class="placement-config">
            <div class="form-row">
              <div class="form-group">
                <label>Airbase Name</label>
                <select v-model="group.placement.referenceName" class="form-input">
                  <option value="" disabled>Select airbase...</option>
                  <option v-for="a in refpoints.airbases" :key="'ab-' + a.name" :value="a.name">
                    {{ a.name }}
                  </option>
                </select>
              </div>
              <div class="form-group">
                <label>Parking Slot</label>
                <input type="number" v-model="group.placement.parking" class="form-input" />
              </div>
            </div>
          </div>

          <!-- Zone Center -->
          <div v-if="group.placement.mode === 'ZONE_CENTER'" class="placement-config">
            <div class="form-group">
              <label>Zone Name</label>
              <select v-model="group.placement.referenceName" class="form-input">
                <option value="" disabled>Select zone...</option>
                <option v-for="z in refpoints.zones" :key="'z-' + z.name" :value="z.name">
                  {{ z.name }}
                </option>
              </select>
            </div>
          </div>

          <!-- Waypoint -->
          <div v-if="group.placement.mode === 'WAYPOINT'" class="placement-config">
            <div class="form-row">
              <div class="form-group">
                <label>Group Name</label>
                <select v-model="group.placement.waypointGroup" class="form-input">
                  <option value="">Select existing group...</option>
                  <option v-for="g in groups" :key="'wg-' + g.groupName" :value="g.groupName">
                    {{ g.groupName }}
                  </option>
                </select>
              </div>
              <div class="form-group">
                <label>Waypoint Number</label>
                <input type="number" v-model="group.placement.waypointNumber" min="1" class="form-input" />
              </div>
            </div>
          </div>
        </div>
      </CollapsibleSection>

      <!-- Route Section -->
      <CollapsibleSection v-model:expanded="expandedSections.route" title="Route">
        <div class="editor-section">
          <div v-for="(wp, index) in group.route" :key="index" class="waypoint-row" :data-waypoint-num="index + 1">
            <div class="waypoint-number-badge">{{ index + 1 }}</div>
            <div class="waypoint-content">
              <div class="form-row">
                <div class="form-group">
                  <label>Type</label>
                  <select v-model="wp.type" class="form-input">
                    <option value="orbit">Orbit</option>
                    <option value="turn_point">Turning Point</option>
                    <option value="heading">Heading</option>
                    <option value="landing">Landing</option>
                  </select>
                </div>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label>Altitude</label>
                  <input type="number" v-model="wp.altitude" class="form-input" />
                </div>
                <div class="form-group">
                  <label>Speed</label>
                  <input type="number" v-model="wp.speed" class="form-input" />
                </div>
              </div>
              <button class="btn-remove" @click="removeWaypoint(index)" title="Remove Waypoint"><span class="btn-remove-icon">✕</span></button>
            </div>
          </div>
          <Button @click="addWaypoint" variant="secondary" size="sm" class="btn-add-waypoint">+ Add Waypoint</Button>
        </div>
      </CollapsibleSection>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { Button } from '../ui'
import { Icon } from '../ui'
import CollapsibleSection from '../CollapsibleSection.vue'

const emit = defineEmits(['group-change', 'save', 'cancel'])

const props = defineProps({
  group: {
    type: Object,
    required: true
  },
  groups: {
    type: Array,
    default: () => []
  }
})

const refpointsStore = useRefpointsStore()

// Refpoints for dropdowns
const refpoints = ref({
  bullseyes: refpointsStore.bullseyes,
  airbases: refpointsStore.airbases,
  zones: refpointsStore.zones,
  lines: refpointsStore.lines
})

// Watch store changes to update refpoints
watch(() => ({
  bullseyes: refpointsStore.bullseyes,
  airbases: refpointsStore.airbases,
  zones: refpointsStore.zones,
  lines: refpointsStore.lines
}), (newRefpoints) => {
  refpoints.value = newRefpoints
}, { immediate: true, deep: true })

// Section expansion state (all expanded by default)
const expandedSections = ref({
  basic: true,
  units: true,
  placement: true,
  route: true
})

const addUnit = () => {
  props.group.units.push({ type: '', quantity: 1, name: '', role: '' })
  emit('group-change', props.group)
}

const removeUnit = (index) => {
  props.group.units.splice(index, 1)
  emit('group-change', props.group)
}

const addWaypoint = () => {
  props.group.route.push({ type: 'orbit', altitude: 3000, speed: 500 })
  emit('group-change', props.group)
}

const removeWaypoint = (index) => {
  props.group.route.splice(index, 1)
  emit('group-change', props.group)
}

// Save changes when group changes
watch(() => props.group, (newVal) => {
  emit('group-change', newVal)
}, { deep: true })

const onSave = () => {
  emit('save', props.group)
}

const onCancel = () => {
  emit('cancel')
}
</script>

<style scoped>
.group-editor {
  width: 100%;
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
}

/* Editor toolbar */
.editor-toolbar {
  display: flex;
  justify-content: flex-end;
  gap: var(--spacing-sm);
  padding: var(--spacing-sm) var(--spacing-md);
  border-bottom: 1px solid var(--color-border);
  background: var(--color-bg-2);
}

/* Editor content container - scrollable area */
.editor-content {
  flex: 1;
  min-height: 0;
  height: 100%;
  overflow-y: auto;
  padding: var(--spacing-md);
}

.editor-content:last-child {
  padding-bottom: calc(var(--spacing-md) - var(--spacing-sm));
}

/* Custom Scrollbar Styles for Editor Content */
.editor-content::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

.editor-content::-webkit-scrollbar-track {
  background: var(--color-bg-1);
}

.editor-content::-webkit-scrollbar-thumb {
  background: var(--color-bg-3);
  border-radius: var(--spacing-xxs);
}

.editor-content::-webkit-scrollbar-thumb:hover {
  background: var(--color-text-2);
}

.editor-content::-webkit-scrollbar-corner {
  background: var(--color-bg-1);
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--spacing-sm);
  margin-bottom: var(--spacing-sm);
}

.form-group {
  margin-bottom: var(--spacing-sm);
}

.form-group label {
  display: block;
  font-size: var(--font-size-xxs);
  color: var(--color-text-3);
  margin-bottom: var(--spacing-xs);
}

.form-input {
  width: 100%;
  background: var(--color-bg-2);
  border: 1px solid var(--color-border);
  color: var(--color-text-4);
  padding: var(--spacing-xs);
  border-radius: var(--spacing-xxs);
}

.form-input:focus {
  outline: none;
  border-color: var(--color-border-focus);
}

.placement-config,
.waypoint-row,
.unit-row {
  margin-top: var(--spacing-xs);
  padding-left: var(--spacing-sm);
  border-left: 2px solid var(--color-bg-2);
}

.unit-row {
  display: flex;
  gap: var(--spacing-sm);
  padding: var(--spacing-md);
  background: var(--color-bg-4);
  border-radius: var(--spacing-xs);
  margin-top: var(--spacing-md);
  border: 1px solid var(--color-border);
}

.unit-row + .unit-row {
  margin-top: var(--spacing-xl);
  border-top: 2px solid var(--color-primary);
}

.unit-number-badge {
  flex: 0 0 32px;
  height: 32px;
  background: var(--color-primary);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: var(--spacing-xxs);
  font-weight: var(--font-weight-bold);
  font-size: var(--font-size-lg);
  user-select: none;
}

.unit-content {
  flex: 1;
}

.waypoint-row {
  display: flex;
  gap: var(--spacing-sm);
  padding: var(--spacing-md);
  background: var(--color-bg-4);
  border-radius: var(--spacing-xs);
  margin-top: var(--spacing-md);
  border: 1px solid var(--color-border);
}

.waypoint-row + .waypoint-row {
  margin-top: var(--spacing-xl);
  border-top: 2px solid var(--color-primary);
}

.waypoint-number-badge {
  flex: 0 0 32px;
  height: 32px;
  background: var(--color-primary);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: var(--spacing-xxs);
  font-weight: var(--font-weight-bold);
  font-size: var(--font-size-lg);
  user-select: none;
}

.waypoint-content {
  flex: 1;
}
</style>
