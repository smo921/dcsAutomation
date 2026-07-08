<template>
  <div class="group-editor">
    <!-- Save/Cancel Toolbar - use shared .editor-toolbar from components.css -->
    <div class="editor-toolbar">
      <Button @click="onSave" variant="primary">Save</Button>
      <Button @click="onCancel" variant="secondary">Cancel</Button>
    </div>

    <div class="editor-content scrollbar-custom">
      <!-- Basic Settings -->
      <CollapsibleSection v-model:expanded="expandedSections.basic" title="Basic Settings">
        <div class="editor-section">
          <div class="form-row">
            <div class="form-group">
              <FormLabel label="Group Name" required />
              <FormInput
                v-model="group.groupName"
                placeholder="Enter group name..."
                error=""
              />
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <FormLabel label="Category" required />
              <FormSelect
                v-model="group.category"
                :options="categoryOptions"
                placeholder="Select category..."
              />
            </div>
            <div class="form-group">
              <FormLabel label="Country" />
              <FormInput
                v-model="group.country"
                placeholder="Enter country..."
              />
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <FormLabel label="Task" />
              <FormSelect
                v-model="group.task"
                :options="taskOptions"
                placeholder="Select task..."
              />
            </div>
            <div class="form-group">
              <FormLabel label="Trigger Type" required />
              <FormSelect
                v-model="group.triggerType"
                :options="triggerTypeOptions"
                placeholder="Select trigger type..."
              />
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
                  <FormLabel label="Unit Type" required />
                  <FormInput
                    v-model="unit.type"
                    placeholder="Enter unit type..."
                  />
                </div>
                <div class="form-group">
                  <FormLabel label="Quantity" required />
                  <FormInput
                    v-model="unit.quantity"
                    type="number"
                    :min="1"
                    placeholder="1"
                  />
                </div>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <FormLabel label="Name" />
                  <FormInput
                    v-model="unit.name"
                    placeholder="Enter unit name..."
                  />
                </div>
                <div class="form-group">
                  <FormLabel label="Role" />
                  <FormInput
                    v-model="unit.role"
                    placeholder="Enter role..."
                  />
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
              <FormLabel label="Placement Mode" required />
              <FormSelect
                v-model="group.placement.mode"
                :options="placementModeOptions"
                placeholder="Select placement mode..."
              />
            </div>
          </div>

          <!-- Bearing + Distance -->
          <div v-if="group.placement.mode === 'BEARING_DISTANCE'" class="placement-config">
            <div class="form-row">
              <div class="form-group">
                <FormLabel label="Reference Type" required />
                <FormSelect
                  v-model="group.placement.reference"
                  :options="referenceTypeOptions"
                  placeholder="Select reference..."
                />
              </div>
              <div class="form-group">
                <FormLabel label="Reference Name" required />
                <FormSelect
                  v-model="group.placement.referenceName"
                  :options="getReferenceOptions()"
                  placeholder="Select a reference..."
                />
              </div>
            </div>
            <div class="form-row">
              <div class="form-group">
                <FormLabel label="Bearing (degrees)" />
                <FormInput
                  v-model="group.placement.bearing"
                  type="number"
                  :min="0"
                  :max="360"
                  placeholder="0-360"
                />
              </div>
              <div class="form-group">
                <FormLabel label="Distance (NM)" />
                <FormInput
                  v-model="group.placement.distance"
                  type="number"
                  :min="0"
                  placeholder="0"
                />
              </div>
            </div>
          </div>

          <!-- Direct Coordinates -->
          <div v-if="group.placement.mode === 'COORDINATE'" class="placement-config">
            <div class="form-row">
              <div class="form-group">
                <FormLabel label="X Coordinate" />
                <FormInput
                  v-model="group.placement.x"
                  type="number"
                  placeholder="X coordinate"
                />
              </div>
              <div class="form-group">
                <FormLabel label="Y Coordinate" />
                <FormInput
                  v-model="group.placement.y"
                  type="number"
                  placeholder="Y coordinate"
                />
              </div>
            </div>
          </div>

          <!-- Airbase Ramp -->
          <div v-if="group.placement.mode === 'AIRBASE_RAMP'" class="placement-config">
            <div class="form-row">
              <div class="form-group">
                <FormLabel label="Airbase Name" required />
                <FormSelect
                  v-model="group.placement.referenceName"
                  :options="airbaseOptions"
                  placeholder="Select airbase..."
                />
              </div>
              <div class="form-group">
                <FormLabel label="Parking Slot" />
                <FormInput
                  v-model="group.placement.parking"
                  type="number"
                  placeholder="Enter parking slot..."
                />
              </div>
            </div>
          </div>

          <!-- Zone Center -->
          <div v-if="group.placement.mode === 'ZONE_CENTER'" class="placement-config">
            <div class="form-group">
              <FormLabel label="Zone Name" required />
              <FormSelect
                v-model="group.placement.referenceName"
                :options="zoneOptions"
                placeholder="Select zone..."
              />
            </div>
          </div>

          <!-- Waypoint -->
          <div v-if="group.placement.mode === 'WAYPOINT'" class="placement-config">
            <div class="form-row">
              <div class="form-group">
                <FormLabel label="Group Name" required />
                <FormSelect
                  v-model="group.placement.waypointGroup"
                  :options="waypointGroupOptions"
                  placeholder="Select existing group..."
                />
              </div>
              <div class="form-group">
                <FormLabel label="Waypoint Number" />
                <FormInput
                  v-model="group.placement.waypointNumber"
                  type="number"
                  :min="1"
                  placeholder="1"
                />
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
                  <FormLabel label="Type" required />
                  <FormSelect
                    v-model="wp.type"
                    :options="waypointTypeOptions"
                    placeholder="Select type..."
                  />
                </div>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <FormLabel label="Altitude" />
                  <FormInput
                    v-model="wp.altitude"
                    type="number"
                    placeholder="Altitude in meters"
                  />
                </div>
                <div class="form-group">
                  <FormLabel label="Speed" />
                  <FormInput
                    v-model="wp.speed"
                    type="number"
                    placeholder="Speed in m/s"
                  />
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
import { useTemplatesStore } from '../../stores/templates'
import { Button, FormLabel, FormInput, FormSelect } from '../ui'
import CollapsibleSection from '../CollapsibleSection.vue'

const emit = defineEmits(['group-change', 'save', 'cancel', 'update'])

const props = defineProps({
  group: {
    type: Object,
    required: true
  },
  refpoints: {
    type: Object,
    default: () => ({
      bullseyes: [],
      airbases: [],
      zones: [],
      lines: []
    })
  },
  templates: {
    type: Object,
    default: () => ({ air: [], ground: [], naval: [], support: [] })
  }
})

const refpointsStore = useRefpointsStore()
const templatesStore = useTemplatesStore()

// Category options
const categoryOptions = computed(() => [
  { value: 'AIRPLANE', label: 'Airplane' },
  { value: 'HELICOPTER', label: 'Helicopter' },
  { value: 'GROUND', label: 'Ground Unit' },
  { value: 'SHIP', label: 'Ship' },
  { value: 'STATIONARY', label: 'Stationary' }
])

// Task options
const taskOptions = computed(() => [
  { value: '', label: 'Default' },
  { value: 'AWACS', label: 'AWACS' },
  { value: 'Refueling', label: 'Tanker' },
  { value: 'CAP', label: 'CAP' },
  { value: 'CAS', label: 'CAS' },
  { value: 'Intercept', label: 'Intercept' },
  { value: 'Ground Attack', label: 'Ground Attack' }
])

// Trigger type options
const triggerTypeOptions = computed(() => [
  { value: 'IMMEDIATE', label: 'Immediate' },
  { value: 'RADAR', label: 'Radar Detection' },
  { value: 'TRIGGER_ZONE', label: 'Trigger Zone' },
  { value: 'OBJECTIVE_COMPLETE', label: 'Objective Complete' }
])

// Placement mode options
const placementModeOptions = computed(() => [
  { value: 'BEARING_DISTANCE', label: 'Bearing + Distance' },
  { value: 'COORDINATE', label: 'Direct Coordinates' },
  { value: 'AIRBASE_RAMP', label: 'Airbase Ramp' },
  { value: 'ZONE_CENTER', label: 'Zone Center' },
  { value: 'WAYPOINT', label: 'Waypoint Anchor' }
])

// Reference type options
const referenceTypeOptions = computed(() => [
  { value: 'bullseye', label: 'Bullseye' },
  { value: 'airbase', label: 'Airbase' },
  { value: 'zone', label: 'Zone' },
  { value: 'battle_line', label: 'Battle Line' }
])

// Computed airbase options
const airbaseOptions = computed(() => {
  return props.refpoints.airbases.map(a => ({ value: a.name, label: a.name }))
})

// Computed zone options
const zoneOptions = computed(() => {
  return props.refpoints.zones.map(z => ({ value: z.name, label: z.name }))
})

// Computed waypoint group options
const waypointGroupOptions = computed(() => {
  // Will be populated by parent with all groups
  return []
})

// Get reference name options based on reference type
const getReferenceOptions = () => {
  const refType = props.group.placement.reference
  switch (refType) {
    case 'bullseye':
      return props.refpoints.bullseyes.map(b => ({ value: b.name, label: b.name }))
    case 'airbase':
      return props.refpoints.airbases.map(a => ({ value: a.name, label: a.name }))
    case 'zone':
      return props.refpoints.zones.map(z => ({ value: z.name, label: z.name }))
    case 'battle_line':
      return props.refpoints.lines.map(l => ({ value: l.name, label: l.name }))
    default:
      return []
  }
}

// Waypoint type options
const waypointTypeOptions = computed(() => [
  { value: 'orbit', label: 'Orbit' },
  { value: 'turn_point', label: 'Turning Point' },
  { value: 'heading', label: 'Heading' },
  { value: 'landing', label: 'Landing' }
])

// Section expansion state (all expanded by default)
const expandedSections = ref({
  basic: true,
  units: true,
  placement: true,
  route: true
})

const addUnit = () => {
  props.group.units.push({ type: '', quantity: 1, name: '', role: '' })
  updateGroup()
}

const removeUnit = (index) => {
  props.group.units.splice(index, 1)
  updateGroup()
}

const addWaypoint = () => {
  props.group.route.push({ type: 'orbit', altitude: 3000, speed: 500 })
  updateGroup()
}

const removeWaypoint = (index) => {
  props.group.route.splice(index, 1)
  updateGroup()
}

// Emit group changes
const updateGroup = () => {
  emit('group-change', props.group)
  emit('update', props.group)
}

// Watch for deep changes in group
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
/* Use shared classes from components.css */
.group-editor {
  width: 100%;
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
}
</style>
