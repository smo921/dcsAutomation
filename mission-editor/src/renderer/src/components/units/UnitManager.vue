<template>
  <div class="list-container unit-manager">
    <!-- Category Tabs -->
    <div class="category-tabs">
      <Button
        v-for="category in categories"
        :key="category"
        variant="ghost"
        :class="{ active: activeCategory === category }"
        @click="activeCategory = category"
      >
        {{ category.charAt(0).toUpperCase() + category.slice(1) }}
      </Button>
    </div>

    <!-- Scrollable Unit List -->
    <div class="list-scroll" :style="{ height: listHeight + 'px' }">
      <div class="list-container">
        <div
          v-for="unit in getUnitsByCategory(activeCategory)"
          :key="unit.unitName"
          class="list-item"
          :class="{ active: selectedUnit === unit.unitName }"
          @click="selectUnit(unit.unitName)"
        >
          <div class="list-item-content">
            <h5 class="list-item-header">{{ unit.unitName }}</h5>
            <div class="list-item-meta">
              <Badge variant="primary" >{{ getCategoryLabel(unit.category) }}</Badge>
              <Badge variant="primary">{{ unit.triggerType || 'IMMEDIATE' }}</Badge>
              <Badge variant="primary">{{ unit.country || 'Unknown' }}</Badge>
            </div>
          </div>
          <div class="list-item-actions">
            <Button variant="primary" size="sm" @click.stop="onEditUnit(unit)" title="Edit Unit">
              Edit
            </Button>
            <Button variant="danger" size="sm" @click.stop="onDeleteUnit(unit.unitName)" title="Delete Unit">
              <span class="btn-remove-icon">
                Delete
              </span>
            </Button>
          </div>
        </div>

        <div v-if="getUnitsByCategory(activeCategory).length === 0" class="empty-state">
          <p>No {{ activeCategory }} units configured.</p>
        </div>
      </div>
    </div>

    <!-- Add from Template button -->
    <div class="btn-add-from-template" v-if="listOnly">
      <Button @click="onAddFromTemplate" variant="secondary" size="sm" block>
        <span>+</span> Add from Unit Template
      </Button>
    </div>

    <!-- Resizeable Divider -->
    <div v-if="!listOnly" class="content-resizer" @mousedown="startListResize">
      <span class="resizer-line"></span>
    </div>

    <!-- Unit Editor Panel -->
    <div v-if="!listOnly && selectedUnit && currentUnit" class="editor-panel">
      <div class="editor-content">
        <!-- Basic Settings -->
        <CollapsibleSection v-model:expanded="expandedSections.basic" title="Basic Settings">
        <div class="editor-section">
          <FormRow>
            <FormGroup>
              <FormLabel label="Unit Name" />
              <FormInput v-model="currentUnit.unitName" />
            </FormGroup>
          </FormRow>
          <FormRow>
            <FormGroup>
              <FormLabel label="Category" />
              <FormSelect v-model="currentUnit.category" :options="categoryOptions" placeholder="Select category..." />
            </FormGroup>
            <FormGroup>
              <FormLabel label="Country" />
              <FormInput v-model="currentUnit.country" />
            </FormGroup>
          </FormRow>
          <FormRow>
            <FormGroup>
              <FormLabel label="Task" />
              <FormSelect v-model="currentUnit.task" :options="taskOptions" placeholder="Select task..." />
            </FormGroup>
            <FormGroup>
              <FormLabel label="Trigger Type" />
              <FormSelect v-model="currentUnit.triggerType" :options="triggerTypeOptions" placeholder="Select trigger type..." />
            </FormGroup>
          </FormRow>
        </div>
        </CollapsibleSection>

        <!-- Units Section -->
        <CollapsibleSection v-model:expanded="expandedSections.units" title="Units">
          <div class="editor-section">
            <div v-for="(unit, index) in currentUnit.units" :key="index" class="unit-row" :data-unit-num="index + 1">
              <div class="unit-number-badge">{{ index + 1 }}</div>
              <div class="unit-content">
                <FormRow>
                  <FormGroup>
                    <FormLabel label="Unit Type" />
                    <FormInput v-model="unit.type" />
                  </FormGroup>
                  <FormGroup>
                    <FormLabel label="Quantity" />
                    <FormInput v-model="unit.quantity" type="number" :min="1" />
                  </FormGroup>
                </FormRow>
                <FormRow>
                  <FormGroup>
                    <FormLabel label="Name" />
                    <FormInput v-model="unit.name" />
                  </FormGroup>
                  <FormGroup>
                    <FormLabel label="Role" />
                    <FormInput v-model="unit.role" />
                  </FormGroup>
                </FormRow>
                <Button variant="danger" size="sm" @click="removeUnit(index)" title="Remove Unit">
                  <span class="btn-remove-icon">Delete</span>
                </Button>
              </div>
            </div>
            <Button @click="addUnit" variant="secondary" size="sm" class="btn-add-unit">+ Add Unit</Button>
          </div>
        </CollapsibleSection>

        <!-- Placement Section -->
        <CollapsibleSection v-model:expanded="expandedSections.placement" title="Placement">
          <div class="editor-section">
            <FormRow>
              <FormGroup>
                <FormLabel label="Placement Mode" />
                <FormSelect v-model="currentUnit.placement.mode" :options="placementModeOptions" placeholder="Select placement mode..." />
              </FormGroup>
            </FormRow>

            <!-- Bearing + Distance -->
            <div v-if="currentUnit.placement.mode === 'BEARING_DISTANCE'" class="placement-config">
              <FormRow>
                <FormGroup>
                  <FormLabel label="Reference Type" />
                  <FormSelect v-model="currentUnit.placement.reference" :options="referenceTypeOptions" placeholder="Select reference..." />
                </FormGroup>
                <FormGroup>
                  <FormLabel label="Reference Name" />
                  <FormSelect v-model="currentUnit.placement.referenceName" :options="getReferenceOptions" placeholder="Select a reference..." />
                </FormGroup>
              </FormRow>
              <FormRow>
                <FormGroup>
                  <FormLabel label="Bearing (degrees)" />
                  <FormInput v-model="currentUnit.placement.bearing" type="number" :min="0" :max="360" />
                </FormGroup>
                <FormGroup>
                  <FormLabel label="Distance (NM)" />
                  <FormInput v-model="currentUnit.placement.distance" type="number" :min="0" />
                </FormGroup>
              </FormRow>
            </div>

            <!-- Direct Coordinates -->
            <div v-if="currentUnit.placement.mode === 'COORDINATE'" class="placement-config">
              <FormRow>
                <FormGroup>
                  <FormLabel label="X Coordinate" />
                  <FormInput v-model="currentUnit.placement.x" type="number" />
                </FormGroup>
                <FormGroup>
                  <FormLabel label="Y Coordinate" />
                  <FormInput v-model="currentUnit.placement.y" type="number" />
                </FormGroup>
              </FormRow>
            </div>

            <!-- Airbase Ramp -->
            <div v-if="currentUnit.placement.mode === 'AIRBASE_RAMP'" class="placement-config">
              <FormRow>
                <FormGroup>
                  <FormLabel label="Airbase Name" />
                  <FormSelect v-model="currentUnit.placement.referenceName" :options="airbaseOptions" placeholder="Select airbase..." />
                </FormGroup>
                <FormGroup>
                  <FormLabel label="Parking Slot" />
                  <FormInput v-model="currentUnit.placement.parking" type="number" />
                </FormGroup>
              </FormRow>
            </div>

            <!-- Zone Center -->
            <div v-if="currentUnit.placement.mode === 'ZONE_CENTER'" class="placement-config">
              <FormGroup>
                <FormLabel label="Zone Name" />
                <FormSelect v-model="currentUnit.placement.referenceName" :options="zoneOptions" placeholder="Select zone..." />
              </FormGroup>
            </div>

            <!-- Waypoint -->
            <div v-if="currentUnit.placement.mode === 'WAYPOINT'" class="placement-config">
              <FormRow>
                <FormGroup>
                  <FormLabel label="Unit Name" />
                  <FormSelect v-model="currentUnit.placement.waypointUnit" :options="waypointUnitOptions" placeholder="Select existing unit..." />
                </FormGroup>
                <FormGroup>
                  <FormLabel label="Waypoint Number" />
                  <FormInput v-model="currentUnit.placement.waypointNumber" type="number" :min="1" />
                </FormGroup>
              </FormRow>
            </div>
          </div>
        </CollapsibleSection>

        <!-- Route Section -->
        <CollapsibleSection v-model:expanded="expandedSections.route" title="Route">
          <div class="editor-section">
            <div v-for="(wp, index) in currentUnit.route" :key="index" class="waypoint-row" :data-waypoint-num="index + 1">
              <div class="waypoint-number-badge">{{ index + 1 }}</div>
              <div class="waypoint-content">
                <FormRow>
                  <FormGroup>
                    <FormLabel label="Type" />
                    <FormSelect v-model="wp.type" :options="waypointTypeOptions" placeholder="Select type..." />
                  </FormGroup>
                </FormRow>
                <FormRow>
                  <FormGroup>
                    <FormLabel label="Altitude" />
                    <FormInput v-model="wp.altitude" type="number" />
                  </FormGroup>
                  <FormGroup>
                    <FormLabel label="Speed" />
                    <FormInput v-model="wp.speed" type="number" />
                  </FormGroup>
                </FormRow>
                <Button variant="danger" size="sm" @click="removeWaypoint(index)" title="Remove Waypoint">
                  <span class="btn-remove-icon">Delete</span>
                </Button>
              </div>
            </div>
            <Button @click="addWaypoint" variant="secondary" size="sm" class="btn-add-waypoint">+ Add Waypoint</Button>
          </div>
        </CollapsibleSection>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { useUnitTemplatesStore } from '../../stores/unitTemplates'
import { useResize } from '../../composables/useResize'
import { Button, Badge, FormLabel, FormInput, FormSelect, FormRow, FormGroup } from '../ui'
import CollapsibleSection from '../CollapsibleSection.vue'

const emit = defineEmits(['unit-change', 'unit-delete', 'unit-select', 'unit-edit', 'unit-add-from-template'])

const props = defineProps({
  units: {
    type: Array,
    default: () => []
  },
  templates: {
    type: Object,
    default: () => ({ air: [], ground: [], naval: [], support: [] })
  },
  // When true, only show the list (no editor panel) - used in sidebar
  listOnly: {
    type: Boolean,
    default: false
  }
})

const refpointsStore = useRefpointsStore()
const unitTemplatesStore = useUnitTemplatesStore()

// Flag to prevent watcher loop during bulk updates
const isSyncingRefpoints = ref(false)

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
  if (!isSyncingRefpoints.value) {
    refpoints.value = newRefpoints
  }
}, { immediate: true, deep: true })

const selectedUnit = ref('')
const currentUnit = ref(null)
const categories = ['air', 'ground', 'naval', 'support']
const activeCategory = ref('air')

// Section expansion state (all expanded by default)
const expandedSections = ref({
  basic: true,
  units: true,
  placement: true,
  route: true
})

// Use resize composable for list/editor divider
const listHeight = ref(300)
const { startResize: startListResize, stopResize: stopListResize, onResize: onListResize } = useResize({
  size: listHeight,
  minSize: 100,
  maxSize: 500,
  direction: 'vertical'
})

// Get units filtered by active category
const getUnitsByCategory = computed(() => {
  const categoryMap = {
    'air': ['AIRPLANE', 'HELICOPTER'],
    'ground': ['GROUND', 'SHIP', 'STATIONARY']
  }
  return (category) => {
    return props.units.filter(u => {
      const cat = u.category || 'AIRPLANE'
      if (category === 'air') return ['AIRPLANE', 'HELICOPTER'].includes(cat)
      if (category === 'ground') return ['GROUND', 'SHIP', 'STATIONARY'].includes(cat)
      return true
    })
  }
})

const getCategoryLabel = (category) => {
  const labelMap = {
    'AIRPLANE': 'Air',
    'HELICOPTER': 'Helo',
    'GROUND': 'Ground',
    'SHIP': 'Naval',
    'STATIONARY': 'Static'
  }
  return labelMap[category] || category
}

// Category options for FormSelect
const categoryOptions = computed(() => [
  { value: 'AIRPLANE', label: 'Airplane' },
  { value: 'HELICOPTER', label: 'Helicopter' },
  { value: 'GROUND', label: 'Ground Unit' },
  { value: 'SHIP', label: 'Ship' },
  { value: 'STATIONARY', label: 'Stationary' }
])

// Task options for FormSelect
const taskOptions = computed(() => [
  { value: '', label: 'Default' },
  { value: 'AWACS', label: 'AWACS' },
  { value: 'Refueling', label: 'Tanker' },
  { value: 'CAP', label: 'CAP' },
  { value: 'CAS', label: 'CAS' },
  { value: 'Intercept', label: 'Intercept' },
  { value: 'Ground Attack', label: 'Ground Attack' }
])

// Trigger type options for FormSelect
const triggerTypeOptions = computed(() => [
  { value: 'IMMEDIATE', label: 'Immediate' },
  { value: 'RADAR', label: 'Radar Detection' },
  { value: 'TRIGGER_ZONE', label: 'Trigger Zone' },
  { value: 'OBJECTIVE_COMPLETE', label: 'Objective Complete' }
])

// Placement mode options for FormSelect
const placementModeOptions = computed(() => [
  { value: 'BEARING_DISTANCE', label: 'Bearing + Distance' },
  { value: 'COORDINATE', label: 'Direct Coordinates' },
  { value: 'AIRBASE_RAMP', label: 'Airbase Ramp' },
  { value: 'ZONE_CENTER', label: 'Zone Center' },
  { value: 'WAYPOINT', label: 'Waypoint Anchor' }
])

// Reference type options for FormSelect
const referenceTypeOptions = computed(() => [
  { value: 'bullseye', label: 'Bullseye' },
  { value: 'airbase', label: 'Airbase' },
  { value: 'zone', label: 'Zone' },
  { value: 'battle_line', label: 'Battle Line' }
])

// Computed airbase options for FormSelect
const airbaseOptions = computed(() => {
  return (props.refpoints.airbases || []).map(a => ({ value: a.name, label: a.name }))
})

// Computed zone options for FormSelect
const zoneOptions = computed(() => {
  return (props.refpoints.zones || []).map(z => ({ value: z.name, label: z.name }))
})

// Computed waypoint unit options for FormSelect
const waypointUnitOptions = computed(() => {
  return (props.units || []).map(u => ({ value: u.unitName, label: u.unitName }))
})

// Get reference name options based on reference type
const getReferenceOptions = computed(() => {
  if (!currentUnit.value) return []
  const refType = currentUnit.value.placement?.reference
  if (!refType) return []
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

// Waypoint type options for FormSelect
const waypointTypeOptions = computed(() => [
  { value: 'orbit', label: 'Orbit' },
  { value: 'turn_point', label: 'Turning Point' },
  { value: 'heading', label: 'Heading' },
  { value: 'landing', label: 'Landing' }
])

const selectUnit = (unitName) => {
  selectedUnit.value = unitName
  const unit = props.units.find(u => u.unitName === unitName)
  if (unit) {
    currentUnit.value = JSON.parse(JSON.stringify(unit))
    // Emit the selected unit index to parent
    const selectedIndex = props.units.findIndex(u => u.unitName === unitName)
    emit('unit-select', selectedIndex)
  }
}

const onDeleteUnit = (unitName) => {
  const filtered = props.units.filter(u => u.unitName !== unitName)
  emit('unit-delete', filtered)
  selectedUnit.value = ''
  currentUnit.value = null
}

const onEditUnit = (unit) => {
  emit('unit-edit', unit)
}

const addUnit = () => {
  currentUnit.value.units.push({ type: '', quantity: 1, name: '', role: '' })
}

const removeUnit = (index) => {
  currentUnit.value.units.splice(index, 1)
}

const addWaypoint = () => {
  currentUnit.value.route.push({ type: 'orbit', altitude: 3000, speed: 500 })
}

const removeWaypoint = (index) => {
  currentUnit.value.route.splice(index, 1)
}

const onAddFromTemplate = () => {
  emit('unit-add-from-template', activeCategory.value)
}

const setStatus = (message, type = 'info') => {
  // Dispatch a custom event to notify parent about status changes
  window.dispatchEvent(new CustomEvent('group-status', { detail: { message, type } }))
}

// Save changes when currentUnit changes
watch(currentUnit, (newVal) => {
  if (newVal && !isSyncingRefpoints.value) {
    emit('unit-change', props.units.map(u =>
      u.unitName === newVal.unitName ? newVal : u
    ))
  }
}, { deep: true })

// Expose method to control syncing state
defineExpose({
  setSyncing(syncing) {
    isSyncingRefpoints.value = syncing
  }
})
</script>

<style scoped>
/* Uses shared classes from _utils.css: category-tabs, tab-btn, content-resizer, resizer-line */
/* Uses shared classes from _list-editor.css: list-scroll, list-container, editor-panel, editor-content */
/* Uses shared classes from _forms.css: form-row, form-group, form-input */
/* Uses shared classes from _components.css: unit-row, waypoint-row, unit-number-badge, waypoint-number-badge, unit-content, waypoint-content */

/* Unit Manager wrapper */
.unit-manager {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
}

/* List item specific overrides */
.list-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

/* Unit meta styles - category/trigger/country badges */
.unit-category,
.unit-trigger,
.unit-country {
  background: var(--color-bg-2);
  padding: var(--spacing-xxs) var(--spacing-sm);
  border-radius: var(--spacing-xxs);
}

.unit-category {
  text-transform: capitalize;
}

/* Editor content scrollbar - shared in _components.css */
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
</style>
