<template>
  <div class="waypoint-editor">
    <!-- Scrollable Waypoint List -->
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
            <Button variant="danger" size="sm" @click.stop="removeWaypoint(index)" title="Remove Waypoint">
              <span class="btn-remove-icon">✕</span>
            </Button>
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
        <FormGroup label="Waypoint Type">
          <FormSelect
            v-model="activeWp.type"
            :options="waypointTypeOptions"
          />
        </FormGroup>
      </div>

      <div class="form-row">
        <FormGroup label="Altitude (ft)">
          <FormInput
            v-model="activeWp.altitude"
            type="number"
          />
        </FormGroup>
        <FormGroup label="Speed (kts)">
          <FormInput
            v-model="activeWp.speed"
            type="number"
          />
        </FormGroup>
      </div>

      <div v-if="activeWp.type === 'orbit'" class="form-row">
        <FormGroup label="Orbit Radius (NM)">
          <FormInput
            v-model="activeWp.radius"
            type="number"
          />
        </FormGroup>
        <FormGroup label="Pattern">
          <FormSelect
            v-model="activeWp.pattern"
            :options="patternOptions"
          />
        </FormGroup>
      </div>

      <div v-if="activeWp.type === 'turn_point' || activeWp.type === 'heading'" class="form-row">
        <FormGroup label="X Offset (NM)">
          <FormInput
            v-model="activeWp.x"
            type="number"
          />
        </FormGroup>
        <FormGroup label="Y Offset (NM)">
          <FormInput
            v-model="activeWp.y"
            type="number"
          />
        </FormGroup>
      </div>

      <div v-if="activeWp.type === 'landing'" class="form-group">
        <FormGroup label="Landing Airbase">
          <FormSelect
            v-model="activeWp.airbase"
            :options="airbaseOptions"
          />
        </FormGroup>
      </div>

      <div class="form-row">
        <FormGroup label="Bearing (°)">
          <FormInput
            v-model="activeWp.heading"
            type="number"
            :min="0"
            :max="360"
          />
        </FormGroup>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { useResize } from '../../composables/useResize'
import { FormInput, FormSelect, FormGroup, Button } from '../ui'

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

const waypointTypeOptions = computed(() => [
  { value: 'orbit', label: 'Orbit' },
  { value: 'turn_point', label: 'Turning Point' },
  { value: 'heading', label: 'Heading' },
  { value: 'landing', label: 'Landing' }
])

const patternOptions = computed(() => [
  { value: 'clockwise', label: 'Clockwise' },
  { value: 'counterclockwise', label: 'Counter-Clockwise' }
])

const airbaseOptions = computed(() => {
  return refpoints.value.airbases.map(a => ({ value: a.name, label: a.name }))
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
/* Uses shared classes from components.css */
.waypoint-editor {
  width: 100%;
  display: flex;
  flex-direction: column;
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
