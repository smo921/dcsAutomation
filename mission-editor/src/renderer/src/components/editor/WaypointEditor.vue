<template>
  <div class="waypoint-editor">
    <!-- Scrollable Waypoint List -->
    <div class="waypoint-list-scroll" :style="{ height: listHeight + 'px' }">
      <div class="waypoint-list">
        <div
          v-for="(wp, index) in waypoints"
          :key="index"
          class="waypoint-item"
          :class="{ active: activeWaypoint === index }"
          :data-waypoint-num="index + 1"
          @click="setActiveWaypoint(index)"
        >
          <div class="waypoint-header">
            <span class="waypoint-index">{{ index + 1 }}</span>
            <span class="waypoint-type">{{ wp.type }}</span>
            <button class="btn-remove" @click.stop="removeWaypoint(index)">✕</button>
          </div>
          <div class="waypoint-coords" v-if="wp.x !== undefined && wp.y !== undefined">
            {{ Math.round(wp.x) }}, {{ Math.round(wp.y) }}
          </div>
          <div class="waypoint-details" v-else>
            <span v-if="wp.altitude">Alt: {{ wp.altitude }}</span>
            <span v-if="wp.altitude && wp.speed"> | </span>
            <span v-if="wp.speed">Spd: {{ wp.speed }}</span>
          </div>
        </div>

        <button class="btn-add-waypoint" @click="addWaypoint">
          <span>+</span> Add Waypoint
        </button>
      </div>
    </div>

    <!-- Resizeable Divider -->
    <div class="content-resizer" @mousedown="startListResize">
      <span class="resizer-line"></span>
    </div>

    <div class="waypoint-editor-form" v-if="activeWaypoint !== null">
      <div class="form-row">
        <div class="form-group">
          <label>Waypoint Type</label>
          <select v-model="activeWp.type" class="form-input">
            <option value="orbit">Orbit</option>
            <option value="turn_point">Turning Point</option>
            <option value="heading">Heading</option>
            <option value="landing">Landing</option>
          </select>
        </div>
      </div>

      <div class="form-row">
        <div class="form-group">
          <label>Altitude (feet)</label>
          <input type="number" v-model="activeWp.altitude" class="form-input" />
        </div>
        <div class="form-group">
          <label>Speed (knots)</label>
          <input type="number" v-model="activeWp.speed" class="form-input" />
        </div>
      </div>

      <div v-if="activeWp.type === 'orbit'" class="form-row">
        <div class="form-group">
          <label>Orbit Radius (NM)</label>
          <input type="number" v-model="activeWp.radius" class="form-input" />
        </div>
        <div class="form-group">
          <label>Pattern</label>
          <select v-model="activeWp.pattern" class="form-input">
            <option value="clockwise">Clockwise</option>
            <option value="counterclockwise">Counter-Clockwise</option>
          </select>
        </div>
      </div>

      <div v-if="activeWp.type === 'turn_point' || activeWp.type === 'heading'" class="form-row">
        <div class="form-group">
          <label>X Offset (NM)</label>
          <input type="number" v-model="activeWp.x" class="form-input" />
        </div>
        <div class="form-group">
          <label>Y Offset (NM)</label>
          <input type="number" v-model="activeWp.y" class="form-input" />
        </div>
      </div>

      <div v-if="activeWp.type === 'landing'" class="form-group">
        <label>Landing Airbase</label>
        <select v-model="activeWp.airbase" class="form-input">
          <option v-for="a in refpoints.airbases" :key="a.name" :value="a.name">
            {{ a.name }}
          </option>
        </select>
      </div>

      <div class="form-row">
        <div class="form-group">
          <label>Bearing (°)</label>
          <input type="number" v-model="activeWp.heading" min="0" max="360" class="form-input" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { useResize } from '../../composables/useResize'

const store = useRefpointsStore()

const refpoints = ref({
  airbases: store.airbases
})

// Watch store changes to update refpoints
watch(() => store.airbases, (newAirbases) => {
  refpoints.value.airbases = newAirbases
}, { immediate: true })

const waypoints = ref([])
const activeWaypoint = ref(null)

const activeWp = ref({
  type: 'orbit',
  x: 0,
  y: 0,
  altitude: 3000,
  speed: 500,
  heading: 0,
  radius: 10,
  pattern: 'clockwise',
  airbase: ''
})

const setActiveWaypoint = (index) => {
  if (index < 0 || index >= waypoints.value.length) {
    activeWaypoint.value = null
    return
  }
  activeWaypoint.value = index
  const wp = waypoints.value[index]
  activeWp.value = { ...wp }
}

// Use resize composable for list/form divider
const listHeight = ref(250)
const { startResize: startListResize, stopResize: stopListResize, onResize: onListResize } = useResize({
  size: listHeight,
  minSize: 100,
  maxSize: 500,
  direction: 'vertical'
})

const addWaypoint = () => {
  waypoints.value.push({ ...activeWp.value })
  activeWaypoint.value = waypoints.value.length - 1
}

const removeWaypoint = (index) => {
  waypoints.value.splice(index, 1)
  if (activeWaypoint.value >= waypoints.value.length) {
    activeWaypoint.value = waypoints.value.length - 1
  }
  if (waypoints.value.length === 0) {
    activeWaypoint.value = null
  }
}

const emit = defineEmits(['update:waypoints'])
watch(waypoints, (newWaypoints) => {
  emit('update:waypoints', newWaypoints)
}, { deep: true })
</script>

<style scoped>
.waypoint-editor {
  width: 100%;
  display: flex;
  flex-direction: column;
}

/* Scrollable Waypoint List Container */
.waypoint-list-scroll {
  flex: 0 0 auto;
  overflow-y: auto;
  min-height: 100px;
  margin-bottom: 12px;
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

.waypoint-list {
  border: 1px solid #3e3e42;
  border-radius: 4px;
  background: #252526;
}

.waypoint-item {
  display: flex;
  align-items: center;
  padding: 8px;
  border-bottom: 1px solid #3e3e42;
  cursor: pointer;
  transition: background 0.2s;
}

.waypoint-item:last-child {
  border-bottom: none;
}

.waypoint-item:hover {
  background: #303030;
}

.waypoint-item.active {
  background: #0e639c;
}

.waypoint-header {
  display: flex;
  align-items: center;
  gap: 8px;
  flex: 1;
}

.waypoint-index {
  font-size: 12px;
  color: #0e639c;
  background: #1e1e22;
  padding: 4px 8px;
  border-radius: 3px;
  font-weight: bold;
  border: 1px solid #2a2a35;
  min-width: 28px;
  text-align: center;
}

.waypoint-item.active .waypoint-index {
  background: #0e639c;
  color: white;
  border-color: #0e639c;
}

.waypoint-type {
  font-size: 12px;
  color: #d4d4d4;
}

.waypoint-coords {
  font-size: 10px;
  color: #888;
  margin-left: 12px;
  font-family: monospace;
}

.waypoint-details {
  font-size: 10px;
  color: #888;
  margin-left: 12px;
}

.btn-remove {
  background: #a31313;
  color: white;
  border: none;
  width: 20px;
  height: 20px;
  border-radius: 3px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-left: 8px;
}

.btn-add-waypoint {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  width: 100%;
  padding: 8px;
  background: #2d5a8e;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  margin-top: 8px;
}

.btn-add-waypoint:hover {
  background: #3d6ebf;
}

.waypoint-editor-form {
  margin-top: 12px;
  padding: 12px;
  background: #252526;
  border-radius: 4px;
  flex: 0 0 auto;
  min-height: 200px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
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
</style>
