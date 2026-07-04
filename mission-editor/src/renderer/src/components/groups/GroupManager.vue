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
      <h3>Edit Group</h3>
      <div class="editor-section">
        <h4>Basic Settings</h4>
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

      <!-- Units Section -->
      <div class="editor-section">
        <h4>Units</h4>
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
        <Button @click="addUnit" variant="ghost">+ Add Unit</Button>
      </div>

      <!-- Placement Section -->
      <div class="editor-section">
        <h4>Placement</h4>
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

      <!-- Route Section -->
      <div class="editor-section">
        <h4>Route</h4>
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
        <Button @click="addWaypoint" variant="ghost">+ Add Waypoint</Button>
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
.group-manager {
  width: 100%;
  display: flex;
  flex-direction: column;
  height: 100%;
}

/* Group List Header */
.group-list-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.group-list-header h3 {
  font-size: 14px;
  color: #ffffff;
  margin: 0;
}

.btn-add {
  background: #0e639c;
  color: white;
  border: none;
  padding: 6px 12px;
  border-radius: 3px;
  cursor: pointer;
  font-size: 12px;
}

.btn-add:hover {
  background: #1177bb;
}

/* Group List */
.group-list {
  background: #252526;
  border-radius: 4px;
  border: 1px solid #3e3e42;
}

/* Scrollable Group List Container */
.group-list-scroll {
  flex: 0 0 auto;
  overflow-y: auto;
  min-height: 100px;
  margin-bottom: 12px;
}

.group-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px;
  border-bottom: 1px solid #3e3e42;
  cursor: pointer;
  transition: background 0.2s;
}

.group-item:hover {
  background: #303030;
}

.group-item.active {
  background: #0e639c;
}

.group-info {
  flex: 1;
}

.group-info h4 {
  font-size: 13px;
  color: #ffffff;
  margin: 0 0 4px 0;
}

.group-meta {
  display: flex;
  gap: 8px;
  font-size: 11px;
}

.group-category {
  background: #3c3c3c;
  padding: 2px 6px;
  border-radius: 3px;
  color: #66b3ff;
}

.group-trigger {
  background: #3c3c3c;
  padding: 2px 6px;
  border-radius: 3px;
  color: #9cdcfe;
}

.group-country {
  background: #3c3c3c;
  padding: 2px 6px;
  border-radius: 3px;
  color: #dcdcdc;
}

.group-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.template-select-wrapper {
  position: relative;
}

.template-select {
  background: #3c3c3c;
  border: 1px solid #454545;
  color: white;
  padding: 4px 8px;
  border-radius: 3px;
  font-size: 11px;
  cursor: pointer;
}

.template-select:focus {
  outline: none;
  border-color: #0e639c;
}

.btn-delete {
  background: #a31313;
  color: white;
  border: none;
  width: 24px;
  height: 24px;
  border-radius: 3px;
  cursor: pointer;
  font-weight: bold;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-delete:hover {
  background: #c32323;
}

.header-actions {
  position: relative;
}

.btn-add-template {
  background: #0e639c;
  color: white;
  border: none;
  padding: 6px 12px;
  border-radius: 3px;
  cursor: pointer;
  font-size: 12px;
  margin-left: 8px;
}

.btn-add-template:hover {
  background: #1177bb;
}

.template-menu {
  position: absolute;
  top: 100%;
  left: 0;
  background: #252526;
  border: 1px solid #3e3e42;
  border-radius: 4px;
  min-width: 180px;
  max-height: 300px;
  overflow-y: auto;
  z-index: 100;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  margin-top: 4px;
}

.template-menu-item {
  padding: 10px 12px;
  cursor: pointer;
  font-size: 13px;
  transition: background 0.2s;
}

.template-menu-item:hover {
  background: #303030;
}

.empty-state {
  padding: 20px;
  text-align: center;
  color: #888;
  font-size: 13px;
}

/* Resizeable Divider between list and editor */
.content-resizer {
  height: 8px;
  background: #3e3e42;
  cursor: ns-resize;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 4px 0;
  border-radius: 4px;
  transition: background 0.2s;
  pointer-events: auto;
  z-index: 10;
}

.content-resizer:hover {
  background: #0e639c;
}

.resizer-line {
  width: 32px;
  height: 2px;
  background: #666;
  border-radius: 2px;
}

.content-resizer:hover .resizer-line {
  background: #0e639c;
}

/* Group Editor Panel */
.group-editor-panel {
  background: #252526;
  border-radius: 4px;
  overflow: hidden;
  border: 1px solid #3e3e42;
  flex: 0 0 auto;
  min-height: 200px;
  display: flex;
  flex-direction: column;
}

.group-editor-panel h3 {
  font-size: 14px;
  color: #ffffff;
  margin: 0;
  padding: 12px;
  border-bottom: 1px solid #3e3e42;
  flex: 0 0 auto;
}

.editor-section {
  padding: 12px;
  border-bottom: 1px solid #3e3e42;
  flex: 0 0 auto;
}

.editor-section:last-child {
  border-bottom: none;
}

.editor-section h4 {
  font-size: 13px;
  color: #ffffff;
  margin: 0 0 10px 0;
  padding-bottom: 6px;
  border-bottom: 1px solid #3e3e42;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
  margin-bottom: 8px;
}

.form-group {
  margin-bottom: 8px;
}

.form-group label {
  display: block;
  font-size: 11px;
  color: #aaa;
  margin-bottom: 4px;
}

.form-input {
  width: 100%;
  background: #3c3c3c;
  border: 1px solid #454545;
  color: white;
  padding: 6px;
  border-radius: 3px;
}

.form-input:focus {
  outline: none;
  border-color: #0e639c;
}

.placement-config,
.waypoint-row,
.unit-row {
  margin-top: 8px;
  padding-left: 8px;
  border-left: 2px solid #3c3c3c;
}

.unit-row {
  display: flex;
  gap: 8px;
  padding: 12px;
  background: #2d2d30;
  border-radius: 4px;
  margin-top: 12px;
  border: 1px solid #3e3e42;
}

.unit-row + .unit-row {
  margin-top: 20px;
  border-top: 2px solid #0e639c;
}

.unit-number-badge {
  flex: 0 0 32px;
  height: 32px;
  background: #0e639c;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 3px;
  font-weight: bold;
  font-size: 14px;
  user-select: none;
}

.unit-content {
  flex: 1;
}

.waypoint-row {
  display: flex;
  gap: 8px;
  padding: 12px;
  background: #2d2d30;
  border-radius: 4px;
  margin-top: 12px;
  border: 1px solid #3e3e42;
}

.waypoint-row + .waypoint-row {
  margin-top: 20px;
  border-top: 2px solid #0e639c;
}

.waypoint-number-badge {
  flex: 0 0 32px;
  height: 32px;
  background: #0e639c;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 3px;
  font-weight: bold;
  font-size: 14px;
  user-select: none;
}

.waypoint-content {
  flex: 1;
}

.btn-remove-unit,
.btn-remove-waypoint {
  background: #3c3c3c;
  color: #aaa;
  border: none;
  padding: 4px 8px;
  border-radius: 3px;
  cursor: pointer;
  font-size: 11px;
  margin-top: 8px;
}

.btn-remove-unit:hover,
.btn-remove-waypoint:hover {
  color: white;
  background: #454545;
}

.btn-add-unit,
.btn-add-waypoint {
  background: #3c3c3c;
  color: #d4d4d4;
  border: none;
  padding: 6px 12px;
  border-radius: 3px;
  cursor: pointer;
  font-size: 12px;
  margin-top: 8px;
  width: 100%;
}

.btn-add-unit:hover,
.btn-add-waypoint:hover {
  background: #454545;
  color: white;
}
</style>
