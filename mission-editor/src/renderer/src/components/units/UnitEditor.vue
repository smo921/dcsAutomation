<template>
  <EditorPanel title="Unit Editor" variant="primary">
    <template #toolbar>
      <Button @click="onSave" variant="primary">Save</Button>
      <Button @click="onCancel" variant="secondary">Cancel</Button>
    </template>

    <div class="editor-content scrollbar-custom">
      <!-- Basic Settings -->
      <CollapsiblePanel v-model:expanded="expandedSections.basic" title="Basic Settings">
        <div class="editor-section">
          <FormRow>
            <FormGroup>
              <FormLabel label="Unit Name" required />
              <FormInput v-model="unit.unitName" placeholder="Enter unit name..." />
            </FormGroup>
          </FormRow>
          <FormRow>
            <FormGroup>
              <FormLabel label="Category" required />
              <FormSelect v-model="unit.category" :options="categoryOptions" placeholder="Select category..." />
            </FormGroup>
            <FormGroup>
              <FormLabel label="Country" />
              <FormInput v-model="unit.country" placeholder="Enter country..." />
            </FormGroup>
          </FormRow>
          <FormRow>
            <FormGroup>
              <FormLabel label="Task" />
              <FormSelect v-model="unit.task" :options="taskOptions" placeholder="Select task..." />
            </FormGroup>
            <FormGroup>
              <FormLabel label="Trigger Type" required />
              <FormSelect v-model="unit.triggerType" :options="triggerTypeOptions" placeholder="Select trigger type..." />
            </FormGroup>
          </FormRow>
          <FormRow>
            <FormGroup>
              <FormLabel label="Unit Type" />
              <FormSelect v-model="unit.unitType" :options="unitTypeOptions" placeholder="Select unit type from template..." />
            </FormGroup>
          </FormRow>
        </div>
      </CollapsiblePanel>

      <!-- Units Section -->
      <CollapsiblePanel v-model:expanded="expandedSections.units" title="Units">
        <div class="editor-section">
          <div
            v-for="(unit, index) in unit.units"
            :key="index"
            class="unit-row"
            :data-unit-num="index + 1"
          >
            <div class="unit-number-badge">{{ index + 1 }}</div>
            <div class="unit-content">
              <FormRow>
                <FormGroup>
                  <FormLabel label="Unit Type" required />
                  <FormInput v-model="unit.type" placeholder="Enter unit type..." />
                </FormGroup>
                <FormGroup>
                  <FormLabel label="Quantity" required />
                  <FormInput v-model="unit.quantity" type="number" :min="1" placeholder="1" />
                </FormGroup>
              </FormRow>
              <FormRow>
                <FormGroup>
                  <FormLabel label="Name" />
                  <FormInput v-model="unit.name" placeholder="Enter unit name..." />
                </FormGroup>
                <FormGroup>
                  <FormLabel label="Role" />
                  <FormInput v-model="unit.role" placeholder="Enter role..." />
                </FormGroup>
              </FormRow>
              <Button variant="danger" size="sm" @click="removeUnit(index)">
                <span class="btn-remove-icon">- Delete Unit</span>
              </Button>
            </div>
          </div>
          <Button @click="addUnit" variant="secondary" size="sm">
            + Add Unit
          </Button>
        </div>
      </CollapsiblePanel>

      <!-- Placement Section -->
      <CollapsiblePanel v-model:expanded="expandedSections.placement" title="Placement">
        <div class="editor-section">
          <FormRow>
            <FormGroup>
              <FormLabel label="Placement Mode" required />
              <FormSelect
                v-model="unit.placement.mode"
                :options="placementModeOptions"
                placeholder="Select placement mode..."
              />
            </FormGroup>
          </FormRow>

          <!-- Bearing + Distance -->
          <div v-if="unit.placement.mode === 'BEARING_DISTANCE'" class="placement-config">
            <FormRow>
              <FormGroup>
                <FormLabel label="Reference Type" required />
                <FormSelect
                  v-model="unit.placement.reference"
                  :options="referenceTypeOptions"
                  placeholder="Select reference..."
                />
              </FormGroup>
              <FormGroup>
                <FormLabel label="Reference Name" required />
                <FormSelect
                  v-model="unit.placement.referenceName"
                  :options="getReferenceOptions"
                  placeholder="Select a reference..."
                />
              </FormGroup>
            </FormRow>
            <FormRow>
              <FormGroup>
                <FormLabel label="Bearing (degrees)" />
                <FormInput
                  v-model="unit.placement.bearing"
                  type="number"
                  :min="0"
                  :max="360"
                  placeholder="0-360"
                />
              </FormGroup>
              <FormGroup>
                <FormLabel label="Distance (NM)" />
                <FormInput
                  v-model="unit.placement.distance"
                  type="number"
                  :min="0"
                  placeholder="0"
                />
              </FormGroup>
            </FormRow>
          </div>

          <!-- Direct Coordinates -->
          <div v-if="unit.placement.mode === 'COORDINATE'" class="placement-config">
            <FormRow>
              <FormGroup>
                <FormLabel label="X Coordinate" />
                <FormInput v-model="unit.placement.x" type="number" placeholder="X coordinate" />
              </FormGroup>
              <FormGroup>
                <FormLabel label="Y Coordinate" />
                <FormInput v-model="unit.placement.y" type="number" placeholder="Y coordinate" />
              </FormGroup>
            </FormRow>
          </div>

          <!-- Airbase Ramp -->
          <div v-if="unit.placement.mode === 'AIRBASE_RAMP'" class="placement-config">
            <FormRow>
              <FormGroup>
                <FormLabel label="Airbase Name" required />
                <FormSelect
                  v-model="unit.placement.referenceName"
                  :options="airbaseOptions"
                  placeholder="Select airbase..."
                />
              </FormGroup>
              <FormGroup>
                <FormLabel label="Parking Slot" />
                <FormInput
                  v-model="unit.placement.parking"
                  type="number"
                  placeholder="Enter parking slot..."
                />
              </FormGroup>
            </FormRow>
          </div>

          <!-- Zone Center -->
          <div v-if="unit.placement.mode === 'ZONE_CENTER'" class="placement-config">
            <FormGroup>
              <FormLabel label="Zone Name" required />
              <FormSelect
                v-model="unit.placement.referenceName"
                :options="zoneOptions"
                placeholder="Select zone..."
              />
            </FormGroup>
          </div>

          <!-- Waypoint -->
          <div v-if="unit.placement.mode === 'WAYPOINT'" class="placement-config">
            <FormRow>
              <FormGroup>
                <FormLabel label="Unit Name" required />
                <FormSelect
                  v-model="unit.placement.waypointUnit"
                  :options="waypointUnitOptions"
                  placeholder="Select existing unit..."
                />
              </FormGroup>
              <FormGroup>
                <FormLabel label="Waypoint Number" />
                <FormInput
                  v-model="unit.placement.waypointNumber"
                  type="number"
                  :min="1"
                  placeholder="1"
                />
              </FormGroup>
            </FormRow>
          </div>
        </div>
      </CollapsiblePanel>

      <!-- Route Section - uses shared RouteEditor component -->
      <CollapsiblePanel v-model:expanded="expandedSections.route" title="Route">
        <div class="editor-section">
          <RouteEditor
            :route="unit.route"
            :airbases="refpoints.airbases"
            @update:route="unit.route = $event"
          />
        </div>
      </CollapsiblePanel>
    </div>
  </EditorPanel>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { useUnitTemplatesStore } from '../../stores/unitTemplates'
import { Button, FormLabel, FormInput, FormSelect, FormRow, FormGroup, EditorPanel, CollapsiblePanel } from '../ui'
import RouteEditor from '../routeTemplates/RouteEditor.vue'

const emit = defineEmits(['unit-change', 'save', 'cancel', 'update'])

const props = defineProps({
  unit: {
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
  unitTemplates: {
    type: Object,
    default: () => ({ air: [], ground: [], naval: [], support: [] })
  }
})

const refpointsStore = useRefpointsStore()
const unitTemplatesStore = useUnitTemplatesStore()

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

// Unit type options (from unit templates)
const unitTypeOptions = computed(() => {
  const types = []
  Object.values(unitTemplatesStore.categories).forEach(category => {
    category.forEach(template => {
      template.units?.forEach(unit => {
        if (unit.type && !types.find(t => t.value === unit.type)) {
          types.push({ value: unit.type, label: `${unit.type} (${template.name})` })
        }
      })
    })
  })
  return types
})

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
  return (props.refpoints.airbases || []).map(a => ({ value: a.name, label: a.name }))
})

// Computed zone options
const zoneOptions = computed(() => {
  return (props.refpoints.zones || []).map(z => ({ value: z.name, label: z.name }))
})

// Computed waypoint unit options
const waypointUnitOptions = computed(() => {
  // Will be populated by parent with all units
  return []
})

// Get reference name options based on reference type
const getReferenceOptions = computed(() => {
  const refType = props.unit.placement.reference
  switch (refType) {
    case 'bullseye':
      return (props.refpoints.bullseyes || []).map(b => ({ value: b.name, label: b.name }))
    case 'airbase':
      return (props.refpoints.airbases || []).map(a => ({ value: a.name, label: a.name }))
    case 'zone':
      return (props.refpoints.zones || []).map(z => ({ value: z.name, label: z.name }))
    case 'battle_line':
      return (props.refpoints.lines || []).map(l => ({ value: l.name, label: l.name }))
    default:
      return []
  }
})

const altitudeTypeOptions = computed(() => [
  { value: 'msl', label: 'MSL' },
  { value: "baro", label: 'Barometric' },
  { value: "agl", label: 'AGL' }
])

// Section expansion state (all collapsed by default)
const expandedSections = ref({
  basic: false,
  units: false,
  placement: false,
  route: false
})

const addUnit = () => {
  props.unit.units.push({ type: '', quantity: 1, name: '', role: '' })
  updateUnit()
}

const removeUnit = (index) => {
  props.unit.units.splice(index, 1)
  updateUnit()
}

const addWaypoint = () => {
  props.unit.route.push({ type: 'orbit', altitude: 3000, speed: 500 })
  updateUnit()
}

const removeWaypoint = (index) => {
  props.unit.route.splice(index, 1)
  updateUnit()
}

// Emit unit changes
const updateUnit = () => {
  emit('unit-change', props.unit)
  emit('update', props.unit)
}

// Watch for deep changes in unit
watch(() => props.unit, (newVal) => {
  emit('unit-change', newVal)
}, { deep: true })

const onSave = () => {
  emit('save', props.unit)
}

const onCancel = () => {
  emit('cancel')
}
</script>

<style scoped>
/* Uses shared classes from components.css */
</style>
