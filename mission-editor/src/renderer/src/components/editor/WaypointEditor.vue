<template>
  <div class="route-editor">
    <!-- Scrollable Route List -->
    <div class="route-list-scroll scrollbar-custom" :style="{ height: listHeight + 'px' }">
      <div class="route-list">
        <div
          v-for="(wp, index) in route"
          :key="index"
          class="route-item"
          :class="{ active: activeRouteIndex === index }"
          :data-route-num="index + 1"
          @click="setActiveRouteIndex(index)"
        >
          <div class="route-header">
            <span class="route-index">{{ index + 1 }}</span>
            <span class="route-type">{{ wp.type }}</span>
            <Button variant="danger" size="sm" @click.stop="removeRouteItem(index)" title="Remove Route Point">
              <span class="btn-remove">- Delete Route Point</span>
            </Button>
          </div>
          <div class="route-coords" v-if="wp.x !== undefined && wp.y !== undefined">
            {{ Math.round(wp.x) }}, {{ Math.round(wp.y) }}
          </div>
          <div class="route-details" v-else>
            <span v-if="wp.altitude">Alt: {{ wp.altitude }}</span>
            <span v-if="wp.altitude && wp.speed"> | </span>
            <span v-if="wp.speed">Spd: {{ wp.speed }}</span>
          </div>
        </div>

        <Button @click="addRouteItem" variant="primary" block>
          <span>+</span> Add Route Point
        </Button>
      </div>
    </div>

    <!-- Resizeable Divider -->
    <div class="content-resizer" @mousedown="startListResize">
      <span class="resizer-line"></span>
    </div>

    <div class="route-editor-form" v-if="activeRouteIndex !== null">
      <div class="form-row">
        <FormGroup label="Route Type">
          <FormSelect
            v-model="activeRp.type"
            :options="routeTypeOptions"
          />
        </FormGroup>
      </div>

      <div class="form-row">
        <FormGroup label="Altitude (ft)">
          <FormInput
            v-model="activeRp.altitude"
            type="number"
          />
        </FormGroup>
        <FormGroup label="Speed (kts)">
          <FormInput
            v-model="activeRp.speed"
            type="number"
          />
        </FormGroup>
      </div>

      <div v-if="activeRp.type === 'orbit'" class="form-row">
        <FormGroup label="Orbit Radius (NM)">
          <FormInput
            v-model="activeRp.radius"
            type="number"
          />
        </FormGroup>
        <FormGroup label="Pattern">
          <FormSelect
            v-model="activeRp.pattern"
            :options="patternOptions"
          />
        </FormGroup>
      </div>

      <div v-if="activeRp.type === 'turn_point' || activeRp.type === 'heading'" class="form-row">
        <FormGroup label="X Offset (NM)">
          <FormInput
            v-model="activeRp.x"
            type="number"
          />
        </FormGroup>
        <FormGroup label="Y Offset (NM)">
          <FormInput
            v-model="activeRp.y"
            type="number"
          />
        </FormGroup>
      </div>

      <div v-if="activeRp.type === 'landing'" class="form-group">
        <FormGroup label="Landing Airbase">
          <FormSelect
            v-model="activeRp.airbase"
            :options="airbaseOptions"
          />
        </FormGroup>
      </div>

      <div class="form-row">
        <FormGroup label="Bearing (°)">
          <FormInput
            v-model="activeRp.heading"
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

const route = ref([])
const activeRouteIndex = ref(null)

const activeRp = ref({
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

const routeTypeOptions = computed(() => [
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

const setActiveRouteIndex = (index) => {
  if (index < 0 || index >= route.value.length) {
    activeRouteIndex.value = null
    return
  }
  activeRouteIndex.value = index
  const wp = route.value[index]
  activeRp.value = { ...wp }
}

// Use resize composable for list/form divider
const listHeight = ref(250)
const { startResize: startListResize, stopResize: stopListResize, onResize: onListResize } = useResize({
  size: listHeight,
  minSize: 100,
  maxSize: 500,
  direction: 'vertical'
})

const addRouteItem = () => {
  route.value.push({ ...activeRp.value })
  activeRouteIndex.value = route.value.length - 1
}

const removeRouteItem = (index) => {
  route.value.splice(index, 1)
  if (activeRouteIndex.value >= route.value.length) {
    activeRouteIndex.value = route.value.length - 1
  }
  if (route.value.length === 0) {
    activeRouteIndex.value = null
  }
}

const emit = defineEmits(['update:route'])
watch(route, (newRoute) => {
  emit('update:route', newRoute)
}, { deep: true })
</script>

<style scoped>
/* Uses shared classes from _components.css: route-editor, editor-content */
/* Uses shared classes from _list-editor.css: route-editor-form */
</style>
