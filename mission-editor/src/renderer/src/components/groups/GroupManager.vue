<template>
  <div class="group-manager">
    <!-- Group List Header -->
    <div class="group-list-header">
      <h3>Groups</h3>
      <div class="header-actions">
        <Button @click="onAddGroup" variant="primary">+ Add Group</Button>
        <Button @click="showTemplateMenu = !showTemplateMenu" variant="secondary">+ New from Template</Button>
        <div v-if="showTemplateMenu" class="template-menu" @click.stop>
          <div v-for="template in getAllTemplates()" :key="template.id || template.name" class="template-menu-item" @click="onAddFromTemplate(template)">
            {{ template.name }}
          </div>
        </div>
      </div>
    </div>

    <!-- Scrollable Group List -->
    <div class="group-list-scroll" :style="{ height: listHeight + 'px' }">
      <div class="group-list">
      <div
        v-for="group in groups"
        :key="group.groupName"
        class="group-item"
        :class="{ active: selectedGroup === group.groupName }"
        @click="selectGroup(group.groupName)"
      >
        <div class="group-info">
          <h4>{{ group.groupName }}</h4>
          <div class="group-meta">
            <span class="group-category">{{ group.category || 'AIR' }}</span>
            <span class="group-trigger">{{ group.triggerType || 'IMMEDIATE' }}</span>
            <span class="group-country">{{ group.country || 'Unknown' }}</span>
          </div>
        </div>
        <div class="group-actions">
          <!-- Template dropdown -->
          <div class="template-select-wrapper">
            <select
              v-model="group.appliedTemplate"
              @change="onTemplateChange(group, $event.target.value)"
              @click.stop
              class="template-select"
            >
              <option value="">(no template)</option>
              <template v-for="template in getAllTemplates()" :key="template.id || template.name">
                <option :value="template.id || template.name">{{ template.name }}</option>
              </template>
            </select>
          </div>
          <Button @click.stop="onDeleteGroup(group.groupName)" variant="danger" icon-only title="Delete Group">✕</Button>
        </div>
      </div>

      <div v-if="groups.length === 0" class="empty-state">
        <p>No groups configured. Click "Add Group" to create one.</p>
      </div>
      </div>
    </div>

    <!-- Resizeable Divider -->
    <div class="content-resizer" @mousedown="startListResize">
      <span class="resizer-line"></span>
    </div>

    <!-- Group Editor Panel -->
    <div v-if="selectedGroup && currentGroup" class="group-editor-panel">
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
              <Button @click="removeUnit(index)" variant="ghost" icon-only title="Remove Unit">✕</Button>
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
                  <template v-for="b in refpoints.bullseyes" :key="'bs-' + b.name">
                    <option :value="b.name">{{ b.name }}</option>
                  </template>
                  <!-- Airbase options -->
                  <template v-for="a in refpoints.airbases" :key="'ab-' + a.name">
                    <option :value="a.name">{{ a.name }}</option>
                  </template>
                  <!-- Zone options -->
                  <template v-for="z in refpoints.zones" :key="'z-' + z.name">
                    <option :value="z.name">{{ z.name }}</option>
                  </template>
                  <!-- Line options -->
                  <template v-for="l in refpoints.lines" :key="'l-' + l.name">
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
              <Button @click="removeWaypoint(index)" variant="ghost" icon-only title="Remove Waypoint">✕</Button>
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
import CollapsibleSection from '../CollapsibleSection.vue'

const emit = defineEmits(['group-change', 'group-delete', 'group-select'])

const props = defineProps({
  groups: {
    type: Array,
    default: () => []
  },
  templates: {
    type: Object,
    default: () => ({ air: [], ground: [], naval: [], support: [] })
  }
})

const refpointsStore = useRefpointsStore()
const templatesStore = useTemplatesStore()

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

const selectedGroup = ref('')
const currentGroup = ref(null)
const showTemplateMenu = ref(false)

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

const onAddGroup = () => {
  const newGroup = {
    groupName: `Group_${props.groups.length + 1}`,
    category: 'AIRPLANE',
    triggerType: 'IMMEDIATE',
    country: 'USA',
    task: '',
    units: [{ type: 'Su-30SM', quantity: 2, name: '', role: '' }],
    placement: {
      mode: 'BEARING_DISTANCE',
      reference: 'bullseye',
      referenceName: 'BULLSEYE_BLUE',
      bearing: 0,
      distance: 100
    },
    route: [
      { type: 'orbit', altitude: 3000, speed: 500 }
    ]
  }
  emit('group-change', [...props.groups, newGroup])
  selectGroup(newGroup.groupName)
}

const onDeleteGroup = (groupName) => {
  const filtered = props.groups.filter(g => g.groupName !== groupName)
  emit('group-delete', filtered)
  selectedGroup.value = ''
  currentGroup.value = null
}

const onAddFromTemplate = (template) => {
  const newGroup = {
    groupName: `${template.name.replace(/\s+/g, '_')}_${props.groups.length + 1}`,
    category: template.category === 'air' ? 'AIRPLANE' : 'GROUND',
    triggerType: 'IMMEDIATE',
    country: template.category === 'air' ? 'USA' : 'Russia',
    task: '',
    units: template.units || [{ type: '', quantity: 1 }],
    placement: {
      mode: 'BEARING_DISTANCE',
      reference: 'bullseye',
      referenceName: 'BULLSEYE_BLUE',
      bearing: 0,
      distance: 100
    },
    route: template.defaultRoute ? [{ ...template.defaultRoute }] : [{ type: 'orbit', altitude: 3000, speed: 500 }],
    appliedTemplate: template.id || template.name
  }
  emit('group-change', [...props.groups, newGroup])
  showTemplateMenu.value = false
  selectGroup(newGroup.groupName)
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

// Template functions
const getAllTemplates = () => {
  const allTemplates = []
  for (const category of Object.values(props.templates)) {
    if (Array.isArray(category)) {
      allTemplates.push(...category)
    }
  }
  return allTemplates
}

const onTemplateChange = (group, templateId) => {
  if (!templateId) {
    // Remove template association
    delete group.appliedTemplate
    emit('group-change', props.groups.map(g =>
      g.groupName === group.groupName ? g : g
    ))
    return
  }

  const template = getAllTemplates().find(t => (t.id || t.name) === templateId)
  if (template) {
    // Apply template to group
    const updatedGroup = { ...group }
    if (template.units) {
      updatedGroup.units = template.units
    }
    if (template.defaultRoute) {
      updatedGroup.route = [{ ...template.defaultRoute }]
    }
    delete updatedGroup.appliedTemplate // Template is applied, remove association
    emit('group-change', props.groups.map(g =>
      g.groupName === group.groupName ? updatedGroup : g
    ))
    setStatus(`Template "${template.name}" applied to ${group.groupName}`, 'success')
  }
}

const setStatus = (message, type = 'info') => {
  // Dispatch a custom event to notify parent about status changes
  window.dispatchEvent(new CustomEvent('group-status', { detail: { message, type } }))
}

// Save changes when currentGroup changes
watch(currentGroup, (newVal) => {
  if (newVal) {
    emit('group-change', props.groups.map(g =>
      g.groupName === newVal.groupName ? newVal : g
    ))
  }
}, { deep: true })
</script>

<style scoped>
/* Group List Header */
.group-list-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: var(--spacing-md);
}

.group-list-header h3 {
  font-size: var(--font-size-lg);
  color: var(--color-text-4);
  margin: 0;
}

/* Group Manager - flex container for list + editor */
.group-manager {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
}

/* Group List */
.group-list {
  background: var(--color-bg-1);
  border-radius: var(--spacing-xs);
  border: 1px solid var(--color-border);
}

/* Scrollable Group List Container */
.group-list-scroll {
  flex: 0 0 auto;
  overflow-y: auto;
  min-height: 100px;
  margin-bottom: var(--spacing-md);
}

/* Custom Scrollbar Styles for Group List */
.group-list-scroll::-webkit-scrollbar {
  width: 8px;
}

.group-list-scroll::-webkit-scrollbar-track {
  background: var(--color-bg-1);
}

.group-list-scroll::-webkit-scrollbar-thumb {
  background: var(--color-bg-3);
  border-radius: var(--spacing-xxs);
}

.group-list-scroll::-webkit-scrollbar-thumb:hover {
  background: var(--color-text-2);
}

.group-list-scroll::-webkit-scrollbar-corner {
  background: var(--color-bg-1);
}

.group-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--spacing-sm);
  border-bottom: 1px solid var(--color-border);
  cursor: pointer;
  transition: background var(--transition-fast);
}

.group-item:hover {
  background: var(--color-bg-3);
}

.group-item.active {
  background: var(--color-primary);
}

.group-info {
  flex: 1;
}

.group-info h4 {
  font-size: var(--font-size-md);
  color: var(--color-text-4);
  margin: 0 0 var(--spacing-xs) 0;
}

.group-meta {
  display: flex;
  gap: var(--spacing-sm);
  font-size: var(--font-size-xxs);
}

.group-category {
  background: var(--color-bg-2);
  padding: var(--spacing-xxs) var(--spacing-sm);
  border-radius: var(--spacing-xxs);
  color: #66b3ff;
}

.group-trigger {
  background: var(--color-bg-2);
  padding: var(--spacing-xxs) var(--spacing-sm);
  border-radius: var(--spacing-xxs);
  color: #9cdcfe;
}

.group-country {
  background: var(--color-bg-2);
  padding: var(--spacing-xxs) var(--spacing-sm);
  border-radius: var(--spacing-xxs);
  color: #dcdcdc;
}

.group-actions {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
}

.template-select-wrapper {
  position: relative;
}

.template-select {
  background: var(--color-bg-2);
  border: 1px solid var(--color-border);
  color: var(--color-text-4);
  padding: var(--spacing-xs) var(--spacing-sm);
  border-radius: var(--spacing-xxs);
  font-size: var(--font-size-xxs);
  cursor: pointer;
}

.template-select:focus {
  outline: none;
  border-color: var(--color-border-focus);
}

.template-menu {
  position: absolute;
  top: 100%;
  left: 0;
  background: var(--color-bg-1);
  border: 1px solid var(--color-border);
  border-radius: var(--spacing-xs);
  min-width: 180px;
  max-height: 300px;
  overflow-y: auto;
  z-index: 100;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  margin-top: var(--spacing-xs);
}

.template-menu-item {
  padding: var(--spacing-sm) var(--spacing-md);
  cursor: pointer;
  font-size: var(--font-size-md);
  transition: background var(--transition-fast);
}

.template-menu-item:hover {
  background: var(--color-bg-3);
}

.empty-state {
  padding: var(--spacing-lg);
  text-align: center;
  color: var(--color-text-1);
  font-size: var(--font-size-md);
}

/* Resizeable Divider between list and editor */
.content-resizer {
  height: 8px;
  background: var(--color-border);
  cursor: ns-resize;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: var(--spacing-xs) 0;
  border-radius: var(--spacing-xs);
  transition: background var(--transition-fast);
  pointer-events: auto;
  z-index: 10;
}

.content-resizer:hover {
  background: var(--color-primary);
}

.resizer-line {
  width: 32px;
  height: 2px;
  background: var(--color-text-2);
  border-radius: var(--spacing-xs);
}

.content-resizer:hover .resizer-line {
  background: var(--color-text-4);
}

/* Group Editor Panel */
.group-editor-panel {
  background: var(--color-bg-1);
  border-radius: var(--spacing-xs);
  border: 1px solid var(--color-border);
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
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
