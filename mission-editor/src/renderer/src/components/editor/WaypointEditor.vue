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
            <button class="btn-remove" @click.stop="removeWaypoint(index)" title="Remove Waypoint"><span class="btn-remove-icon">✕</span></button>
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

        <Button @click="addWaypoint" variant="primary" block>
          <span>+</span> Add Waypoint
        </Button>
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
import { ref, computed, onMounted, watch } from 'vue'
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
  margin-bottom: var(--spacing-md);
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

.waypoint-list {
  border: 1px solid var(--color-border);
  border-radius: var(--spacing-xs);
  background: var(--color-bg-1);
}

.waypoint-item {
  display: flex;
  align-items: center;
  padding: var(--spacing-sm);
  border-bottom: 1px solid var(--color-border);
  cursor: pointer;
  transition: background var(--transition-fast);
}

.waypoint-item:last-child {
  border-bottom: none;
}

.waypoint-item:hover {
  background: var(--color-bg-3);
}

.waypoint-item.active {
  background: var(--color-primary);
}

.waypoint-header {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
  flex: 1;
}

.waypoint-index {
  font-size: var(--font-size-sm);
  color: var(--color-primary);
  background: var(--color-bg-4);
  padding: var(--spacing-xs) var(--spacing-sm);
  border-radius: var(--spacing-xxs);
  font-weight: var(--font-weight-bold);
  border: 1px solid var(--color-bg-2);
  min-width: 28px;
  text-align: center;
}

.waypoint-item.active .waypoint-index {
  background: var(--color-primary);
  color: white;
  border-color: var(--color-primary);
}

.waypoint-type {
  font-size: var(--font-size-sm);
  color: var(--color-text-0);
}

.waypoint-coords {
  font-size: var(--font-size-xxs);
  color: var(--color-text-1);
  margin-left: var(--spacing-sm);
  font-family: monospace;
}

.waypoint-details {
  font-size: var(--font-size-xxs);
  color: var(--color-text-1);
  margin-left: var(--spacing-sm);
}

.btn-remove {
  background: var(--color-error);
  color: white;
  border: none;
  width: 20px;
  height: 20px;
  border-radius: var(--spacing-xxs);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-left: var(--spacing-sm);
}

.btn-add-waypoint {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--spacing-xs);
  width: 100%;
  padding: var(--spacing-sm);
  background: var(--color-primary);
  color: white;
  border: none;
  border-radius: var(--spacing-xs);
  cursor: pointer;
  margin-top: var(--spacing-sm);
}

.btn-add-waypoint:hover {
  background: var(--color-primary-hover);
}

.waypoint-editor-form {
  margin-top: var(--spacing-md);
  padding: var(--spacing-md);
  background: var(--color-bg-1);
  border-radius: var(--spacing-xs);
  flex: 0 0 auto;
  min-height: 200px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--spacing-sm);
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
</style>
