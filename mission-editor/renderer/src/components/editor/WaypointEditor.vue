<template>
  <div class="waypoint-editor">
    <div class="waypoint-list">
      <div
        v-for="(wp, index) in waypoints"
        :key="index"
        class="waypoint-item"
        :class="{ active: activeWaypoint === index }"
        @click="setActiveWaypoint(index)"
      >
        <div class="waypoint-header">
          <span class="waypoint-index">{{ index + 1 }}</span>
          <span class="waypoint-type">{{ wp.type }}</span>
          <button class="btn-remove" @click.stop="removeWaypoint(index)">✕</button>
        </div>
        <div class="waypoint-coords" v-if="wp.x && wp.y">
          {{ Math.round(wp.x) }}, {{ Math.round(wp.y) }}
        </div>
      </div>

      <button class="btn-add-waypoint" @click="addWaypoint">
        <span>+</span> Add Waypoint
      </button>
    </div>

    <div class="waypoint-editor-form" v-if="activeWaypoint !== null">
      <h4>Waypoint {{ activeWaypoint + 1 }}</h4>

      <div class="form-group">
        <label>Waypoint Type</label>
        <select v-model="activeWp.type" class="form-input">
          <option value="takeoff">Takeoff</option>
          <option value="orbit">Orbit</option>
          <option value="heading">Heading</option>
          <option value="waypoint">Waypoint</option>
          <option value="landing">Landing</option>
        </select>
      </div>

      <div class="form-row">
        <div class="form-group">
          <label>X</label>
          <input type="number" v-model="activeWp.x" class="form-input" />
        </div>
        <div class="form-group">
          <label>Y</label>
          <input type="number" v-model="activeWp.y" class="form-input" />
        </div>
      </div>

      <div class="form-row">
        <div class="form-group">
          <label>Altitude (m)</label>
          <input type="number" v-model="activeWp.altitude" class="form-input" />
        </div>
        <div class="form-group">
          <label>Speed (km/h)</label>
          <input type="number" v-model="activeWp.speed" class="form-input" />
        </div>
      </div>

      <div v-if="activeWp.type === 'orbit'" class="form-group">
        <label>Orbit Radius (km)</label>
        <input type="number" v-model="activeWp.radius" class="form-input" />
      </div>

      <div v-if="activeWp.type === 'heading'" class="form-group">
        <label>Heading (°)</label>
        <input type="number" v-model="activeWp.heading" class="form-input" />
      </div>

      <div class="form-group">
        <label>Airbase (for takeoff/landing)</label>
        <select v-model="activeWp.airbase" class="form-input">
          <option v-for="a in refpoints.airbases" :key="a.name" :value="a.name">
            {{ a.name }}
          </option>
        </select>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'

const store = useRefpointsStore()

const refpoints = ref({
  bullseyes: store.bullseyes,
  airbases: store.airbases,
  zones: store.zones,
  lines: store.lines
})

const waypoints = ref([])
const activeWaypoint = ref(null)

const activeWp = reactive({
  type: 'heading',
  x: 0,
  y: 0,
  altitude: 3000,
  speed: 600,
  heading: 0,
  radius: 10,
  airbase: ''
})

const setActiveWaypoint = (index) => {
  if (index < 0 || index >= waypoints.value.length) {
    activeWaypoint.value = null
    return
  }
  activeWaypoint.value = index
  // Load waypoint data
  const wp = waypoints.value[index]
  Object.assign(activeWp, {
    type: wp.type || 'heading',
    x: wp.x || 0,
    y: wp.y || 0,
    altitude: wp.altitude || 3000,
    speed: wp.speed || 600,
    heading: wp.heading || 0,
    radius: wp.radius || 10,
    airbase: wp.airbase || ''
  })
}

const addWaypoint = () => {
  waypoints.value.push({
    type: 'heading',
    x: 0,
    y: 0,
    altitude: 3000,
    speed: 600,
    heading: 0,
    radius: 10,
    airbase: ''
  })
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

onMounted(() => {
  window.api?.refpoints?.load?.().then(config => {
    if (config) {
      refpoints.value.airbases = config.airbases || []
    }
  })
})
</script>

<style scoped>
.waypoint-editor {
  width: 100%;
}

.waypoint-list {
  max-height: 200px;
  overflow-y: auto;
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
  font-size: 11px;
  color: #666;
}

.waypoint-item.active .waypoint-index {
  color: #d4d4d4;
}

.waypoint-type {
  font-size: 12px;
  color: #d4d4d4;
}

.waypoint-coords {
  font-size: 11px;
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
}

.waypoint-editor-form h4 {
  font-size: 13px;
  color: #ffffff;
  margin-bottom: 12px;
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

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}
</style>
