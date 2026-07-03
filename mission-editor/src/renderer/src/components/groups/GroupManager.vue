<template>
  <div class="group-manager">
    <div class="group-list-header">
      <h3>Groups</h3>
      <button @click="onAddGroup" class="btn-add">+ Add Group</button>
    </div>

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
          <button @click.stop="onDeleteGroup(group.groupName)" class="btn-delete">×</button>
        </div>
      </div>

      <div v-if="groups.length === 0" class="empty-state">
        <p>No groups configured. Click "Add Group" to create one.</p>
      </div>
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
        <div v-for="(unit, index) in currentGroup.units" :key="index" class="unit-row">
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
          <button @click="removeUnit(index)" class="btn-remove-unit">Remove Unit</button>
        </div>
        <button @click="addUnit" class="btn-add-unit">+ Add Unit</button>
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
        <div v-for="(wp, index) in currentGroup.route" :key="index" class="waypoint-row">
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
          <button @click="removeWaypoint(index)" class="btn-remove-waypoint">Remove Waypoint</button>
        </div>
        <button @click="addWaypoint" class="btn-add-waypoint">+ Add Waypoint</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'

const emit = defineEmits(['group-change', 'group-delete'])

const props = defineProps({
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

const selectedGroup = ref('')
const currentGroup = ref(null)

const selectGroup = (groupName) => {
  selectedGroup.value = groupName
  const group = props.groups.find(g => g.groupName === groupName)
  if (group) {
    currentGroup.value = JSON.parse(JSON.stringify(group))
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
}

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

.group-list {
  background: #252526;
  border-radius: 4px;
  overflow: hidden;
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

.empty-state {
  padding: 20px;
  text-align: center;
  color: #888;
  font-size: 13px;
}

.group-editor-panel {
  margin-top: 20px;
  background: #252526;
  border-radius: 4px;
  overflow: hidden;
}

.group-editor-panel h3 {
  font-size: 14px;
  color: #ffffff;
  margin: 0;
  padding: 12px;
  border-bottom: 1px solid #3e3e42;
}

.editor-section {
  padding: 12px;
  border-bottom: 1px solid #3e3e42;
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

.btn-remove-unit,
.btn-remove-waypoint {
  background: #3c3c3c;
  color: #aaa;
  border: none;
  padding: 4px 8px;
  border-radius: 3px;
  cursor: pointer;
  font-size: 11px;
  margin-top: 4px;
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
