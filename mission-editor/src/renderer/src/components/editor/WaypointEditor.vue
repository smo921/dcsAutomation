<template>
  <div class="waypoint-editor">
    <!-- Scrollable Waypoint List - use scrollbar-custom from components.css -->
    <div class="waypoint-list-scroll scrollbar-custom" :style="{ height: listHeight + 'px' }">
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
/* Use shared classes from components.css */
.waypoint-editor {
  width: 100%;
  display: flex;
  flex-direction: column;
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

/* Waypoint Editor Form */
.waypoint-editor-form {
  margin-top: var(--spacing-md);
  padding: var(--spacing-md);
  background: var(--color-bg-1);
  border-radius: var(--spacing-xs);
  flex: 0 0 auto;
  min-height: 200px;
}
</style>
