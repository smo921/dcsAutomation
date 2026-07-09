<template>
  <div class="list-container group-manager">
    <!-- Category Tabs -->
    <div class="category-tabs">
      <button
        v-for="category in categories"
        :key="category"
        :class="['tab-btn', { active: activeCategory === category }]"
        @click="activeCategory = category"
      >
        {{ category.charAt(0).toUpperCase() + category.slice(1) }}
      </button>
    </div>

    <!-- Scrollable Group List -->
    <div class="list-scroll" :style="{ height: listHeight + 'px' }">
      <div class="list-container">
        <div
          v-for="group in getGroupsByCategory(activeCategory)"
          :key="group.groupName"
          class="list-item"
          :class="{ active: selectedGroup === group.groupName }"
          @click="selectGroup(group.groupName)"
        >
          <div class="list-item-content">
            <h4>{{ group.groupName }}</h4>
            <div class="list-item-meta">
              <span class="group-category">{{ getCategoryLabel(group.category) }}</span>
              <span class="group-trigger">{{ group.triggerType || 'IMMEDIATE' }}</span>
              <span class="group-country">{{ group.country || 'Unknown' }}</span>
            </div>
          </div>
          <div class="list-item-actions">
            <Button variant="primary" size="sm" @click.stop="onEditGroup(group)" title="Edit Group">
              Edit
            </Button>
            <Button variant="danger" size="sm" @click.stop="onDeleteGroup(group.groupName)" title="Delete Group">
              <span class="btn-remove-icon">
                Delete
              </span>
            </Button>
          </div>
        </div>

        <div v-if="getGroupsByCategory(activeCategory).length === 0" class="empty-state">
          <p>No {{ activeCategory }} groups configured.</p>
        </div>
      </div>
    </div>

    <!-- Resizeable Divider -->
    <div v-if="!listOnly" class="content-resizer" @mousedown="startListResize">
      <span class="resizer-line"></span>
    </div>

    <!-- Group Editor Panel -->
    <div v-if="!listOnly && selectedGroup && currentGroup" class="editor-panel">
      <div class="editor-content">
        <!-- Basic Settings -->
        <CollapsibleSection v-model:expanded="expandedSections.basic" title="Basic Settings">
        <div class="editor-section">
          <div class="form-row">
            <div class="form-group">
              <label>Group Name</label>
              <input type="text" v-model="currentGroup.groupName" class="form-input" />
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Category</label>
              <select v-model="currentGroup.category" class="form-input">
                <option value="AIRPLANE">Airplane</option>
                <option value="HELICOPTER">Helicopter</option>
                <option value="GROUND">Ground Unit</option>
                <option value="SHIP">Ship</option>
                <option value="STATIONARY">Stationary</option>
              </select>
            </div>
            <div class="form-group">
              <label>Country</label>
              <input type="text" v-model="currentGroup.country" class="form-input" />
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Task</label>
              <select v-model="currentGroup.task" class="form-input">
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
              <select v-model="currentGroup.triggerType" class="form-input">
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
            <div v-for="(unit, index) in currentGroup.units" :key="index" class="unit-row" :data-unit-num="index + 1">
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
                <button class="btn-remove" @click="removeUnit(index)" title="Remove Unit"><span class="btn-remove-icon">Delete</span></button>
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
                <select v-model="currentGroup.placement.mode" class="form-input">
                  <option value="BEARING_DISTANCE">Bearing + Distance</option>
                  <option value="COORDINATE">Direct Coordinates</option>
                  <option value="AIRBASE_RAMP">Airbase Ramp</option>
                  <option value="ZONE_CENTER">Zone Center</option>
                  <option value="WAYPOINT">Waypoint Anchor</option>
                </select>
              </div>
            </div>

            <!-- Bearing + Distance -->
            <div v-if="currentGroup.placement.mode === 'BEARING_DISTANCE'" class="placement-config">
              <div class="form-row">
                <div class="form-group">
                  <label>Reference Type</label>
                  <select v-model="currentGroup.placement.reference" class="form-input">
                    <option value="bullseye">Bullseye</option>
                    <option value="airbase">Airbase</option>
                    <option value="zone">Zone</option>
                    <option value="battle_line">Battle Line</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>Reference Name</label>
                  <select v-model="currentGroup.placement.referenceName" class="form-input">
                    <option value="" disabled>Select a reference...</option>
                    <!-- Bullseye options -->
                    <template v-for="b in refpoints.bullseyes" :key="'bs-' + b.name" v-if="currentGroup.placement.reference === 'bullseye'">
                      <option :value="b.name">{{ b.name }}</option>
                    </template>
                    <!-- Airbase options -->
                    <template v-for="a in refpoints.airbases" :key="'ab-' + a.name" v-if="currentGroup.placement.reference === 'airbase'">
                      <option :value="a.name">{{ a.name }}</option>
                    </template>
                    <!-- Zone options -->
                    <template v-for="z in refpoints.zones" :key="'z-' + z.name" v-if="currentGroup.placement.reference === 'zone'">
                      <option :value="z.name">{{ z.name }}</option>
                    </template>
                    <!-- Line options -->
                    <template v-for="l in refpoints.lines" :key="'l-' + l.name" v-if="currentGroup.placement.reference === 'battle_line'">
                      <option :value="l.name">{{ l.name }}</option>
                    </template>
                  </select>
                </div>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label>Bearing (degrees)</label>
                  <input type="number" v-model="currentGroup.placement.bearing" min="0" max="360" class="form-input" />
                </div>
                <div class="form-group">
                  <label>Distance (NM)</label>
                  <input type="number" v-model="currentGroup.placement.distance" min="0" class="form-input" />
                </div>
              </div>
            </div>

            <!-- Direct Coordinates -->
            <div v-if="currentGroup.placement.mode === 'COORDINATE'" class="placement-config">
              <div class="form-row">
                <div class="form-group">
                  <label>X Coordinate</label>
                  <input type="number" v-model="currentGroup.placement.x" class="form-input" />
                </div>
                <div class="form-group">
                  <label>Y Coordinate</label>
                  <input type="number" v-model="currentGroup.placement.y" class="form-input" />
                </div>
              </div>
            </div>

            <!-- Airbase Ramp -->
            <div v-if="currentGroup.placement.mode === 'AIRBASE_RAMP'" class="placement-config">
              <div class="form-row">
                <div class="form-group">
                  <label>Airbase Name</label>
                  <select v-model="currentGroup.placement.referenceName" class="form-input">
                    <option value="" disabled>Select airbase...</option>
                    <option v-for="a in refpoints.airbases" :key="'ab-' + a.name" :value="a.name">
                      {{ a.name }}
                    </option>
                  </select>
                </div>
                <div class="form-group">
                  <label>Parking Slot</label>
                  <input type="number" v-model="currentGroup.placement.parking" class="form-input" />
                </div>
              </div>
            </div>

            <!-- Zone Center -->
            <div v-if="currentGroup.placement.mode === 'ZONE_CENTER'" class="placement-config">
              <div class="form-group">
                <label>Zone Name</label>
                <select v-model="currentGroup.placement.referenceName" class="form-input">
                  <option value="" disabled>Select zone...</option>
                  <option v-for="z in refpoints.zones" :key="'z-' + z.name" :value="z.name">
                    {{ z.name }}
                  </option>
                </select>
              </div>
            </div>

            <!-- Waypoint -->
            <div v-if="currentGroup.placement.mode === 'WAYPOINT'" class="placement-config">
              <div class="form-row">
                <div class="form-group">
                  <label>Group Name</label>
                  <select v-model="currentGroup.placement.waypointGroup" class="form-input">
                    <option value="">Select existing group...</option>
                    <option v-for="g in props.groups" :key="'wg-' + g.groupName" :value="g.groupName">
                      {{ g.groupName }}
                    </option>
                  </select>
                </div>
                <div class="form-group">
                  <label>Waypoint Number</label>
                  <input type="number" v-model="currentGroup.placement.waypointNumber" min="1" class="form-input" />
                </div>
              </div>
            </div>
          </div>
        </CollapsibleSection>

        <!-- Route Section -->
        <CollapsibleSection v-model:expanded="expandedSections.route" title="Route">
          <div class="editor-section">
            <div v-for="(wp, index) in currentGroup.route" :key="index" class="waypoint-row" :data-waypoint-num="index + 1">
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
                <button class="btn-remove" @click="removeWaypoint(index)" title="Remove Waypoint"><span class="btn-remove-icon">Delete</span></button>
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
import { useTemplatesStore } from '../../stores/templates'
import { useResize } from '../../composables/useResize'
import { Button } from '../ui'
import { Icon } from '../ui'
import CollapsibleSection from '../CollapsibleSection.vue'

const emit = defineEmits(['group-change', 'group-delete', 'group-select', 'group-edit'])

const props = defineProps({
  groups: {
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
const templatesStore = useTemplatesStore()

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

const selectedGroup = ref('')
const currentGroup = ref(null)
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

// Get groups filtered by active category
const getGroupsByCategory = computed(() => {
  const categoryMap = {
    'air': ['AIRPLANE', 'HELICOPTER'],
    'ground': ['GROUND', 'SHIP', 'STATIONARY']
  }
  return (groupName) => {
    return props.groups.filter(g => {
      const cat = g.category || 'AIRPLANE'
      if (groupName === 'air') return ['AIRPLANE', 'HELICOPTER'].includes(cat)
      if (groupName === 'ground') return ['GROUND', 'SHIP', 'STATIONARY'].includes(cat)
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

const selectGroup = (groupName) => {
  selectedGroup.value = groupName
  const group = props.groups.find(g => g.groupName === groupName)
  if (group) {
    currentGroup.value = JSON.parse(JSON.stringify(group))
    // Emit the selected group index to parent
    const selectedIndex = props.groups.findIndex(g => g.groupName === groupName)
    emit('group-select', selectedIndex)
  }
}

const onDeleteGroup = (groupName) => {
  const filtered = props.groups.filter(g => g.groupName !== groupName)
  emit('group-delete', filtered)
  selectedGroup.value = ''
  currentGroup.value = null
}

const onEditGroup = (group) => {
  emit('group-edit', group)
}

const addUnit = () => {
  currentGroup.value.units.push({ type: '', quantity: 1, name: '', role: '' })
}

const removeUnit = (index) => {
  currentGroup.value.units.splice(index, 1)
}

const addWaypoint = () => {
  currentGroup.value.route.push({ type: 'orbit', altitude: 3000, speed: 500 })
}

const removeWaypoint = (index) => {
  currentGroup.value.route.splice(index, 1)
}

const setStatus = (message, type = 'info') => {
  // Dispatch a custom event to notify parent about status changes
  window.dispatchEvent(new CustomEvent('group-status', { detail: { message, type } }))
}

// Save changes when currentGroup changes
watch(currentGroup, (newVal) => {
  if (newVal && !isSyncingRefpoints.value) {
    emit('group-change', props.groups.map(g =>
      g.groupName === newVal.groupName ? newVal : g
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

/* Group Manager wrapper */
.group-manager {
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

/* Group meta styles - category/trigger/country badges */
.group-category,
.group-trigger,
.group-country {
  background: var(--color-bg-2);
  padding: var(--spacing-xxs) var(--spacing-sm);
  border-radius: var(--spacing-xxs);
}

.group-category {
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
