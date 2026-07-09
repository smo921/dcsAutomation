<template>
  <EditorPanel title="Waypoint Template Editor" variant="primary">
    <template #toolbar>
      <Button @click="onSave" variant="primary">Save</Button>
      <Button @click="onCancel" variant="secondary">Cancel</Button>
    </template>

    <div class="editor-content">
      <div class="waypoint-template-editor-content">
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

            <Button @click="addWaypoint" variant="secondary" size="sm" block>
              <span>+</span> Add Waypoint
            </Button>
          </div>
        </div>

        <!-- Resizable Divider -->
        <div class="content-resizer" @mousedown="startListResize">
          <span class="resizer-line"></span>
        </div>

        <!-- Waypoint Editor Form -->
        <div v-if="activeWaypoint !== null" class="waypoint-editor-form">
          <CollapsiblePanel v-model:expanded="expandedSections.basic" title="Basic Settings">
            <div class="editor-section">
              <FormRow>
                <div class="form-group">
                  <FormLabel label="Waypoint Type" />
                  <FormSelect
                    v-model="activeWp.type"
                    :options="waypointTypeOptions"
                  />
                </div>
              </FormRow>
            </div>
          </CollapsiblePanel>

          <CollapsiblePanel v-model:expanded="expandedSections.flight" title="Flight Settings">
            <div class="editor-section">
              <FormRow>
                <div class="form-group">
                  <FormLabel label="Altitude (ft)" />
                  <FormInput
                    v-model="activeWp.altitude"
                    type="number"
                  />
                </div>
                <div class="form-group">
                  <FormLabel label="Speed (kts)" />
                  <FormInput
                    v-model="activeWp.speed"
                    type="number"
                  />
                </div>
              </FormRow>
            </div>
          </CollapsiblePanel>

          <CollapsiblePanel
            v-if="activeWp.type === 'orbit'"
            v-model:expanded="expandedSections.orbit"
            title="Orbit Settings"
          >
            <div class="editor-section">
              <FormRow>
                <div class="form-group">
                  <FormLabel label="Orbit Radius (NM)" />
                  <FormInput
                    v-model="activeWp.radius"
                    type="number"
                  />
                </div>
                <div class="form-group">
                  <FormLabel label="Pattern" />
                  <FormSelect
                    v-model="activeWp.pattern"
                    :options="patternOptions"
                  />
                </div>
              </FormRow>
            </div>
          </CollapsiblePanel>

          <CollapsiblePanel
            v-if="activeWp.type === 'turn_point' || activeWp.type === 'heading'"
            v-model:expanded="expandedSections.offset"
            title="Offset Settings"
          >
            <div class="editor-section">
              <FormRow>
                <div class="form-group">
                  <FormLabel label="X Offset (NM)" />
                  <FormInput
                    v-model="activeWp.x"
                    type="number"
                  />
                </div>
                <div class="form-group">
                  <FormLabel label="Y Offset (NM)" />
                  <FormInput
                    v-model="activeWp.y"
                    type="number"
                  />
                </div>
              </FormRow>
            </div>
          </CollapsiblePanel>

          <CollapsiblePanel
            v-if="activeWp.type === 'landing'"
            v-model:expanded="expandedSections.landing"
            title="Landing Settings"
          >
            <div class="editor-section">
              <FormRow>
                <div class="form-group">
                  <FormLabel label="Landing Airbase" />
                  <FormSelect
                    v-model="activeWp.airbase"
                    :options="airbaseOptions"
                  />
                </div>
              </FormRow>
            </div>
          </CollapsiblePanel>
        </div>

        <!-- Empty state for waypoint selection -->
        <div v-if="activeWaypoint === null && waypoints.length > 0" class="no-waypoint-selected">
          <p>Select a waypoint to edit</p>
        </div>
        <div v-if="waypoints.length === 0" class="empty-waypoint-list">
          <p>No waypoints configured. Add waypoints to create this template.</p>
        </div>
      </div>
    </div>
  </EditorPanel>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { useResize } from '../../composables/useResize'
import { FormInput, FormSelect, FormRow, EditorPanel, CollapsiblePanel, Button } from '../ui'

const store = useRefpointsStore()

const emit = defineEmits(['save', 'cancel', 'update:waypoints'])

const props = defineProps({
  waypoints: {
    type: Array,
    default: () => []
  },
  airbases: {
    type: Array,
    default: () => []
  }
})

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
  return props.airbases.map(a => ({ value: a.name, label: a.name }))
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
const { startResize: startListResize } = useResize({
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

// Emit updates
watch(waypoints, (newWaypoints) => {
  emit('update:waypoints', newWaypoints)
}, { deep: true })

// Sync when prop changes
watch(() => props.waypoints, (newVal) => {
  if (activeWaypoint.value !== null && activeWaypoint.value >= newVal.length) {
    activeWaypoint.value = null
  }
}, { deep: true })

// Sync activeWp when it changes
watch(activeWp, (newVal) => {
  if (activeWaypoint.value !== null) {
    waypoints.value[activeWaypoint.value] = { ...newVal }
  }
}, { deep: true })

const onSave = () => {
  emit('save', waypoints.value)
}

const onCancel = () => {
  emit('cancel')
}
</script>

<style scoped>
/* Uses shared classes from _components.css:
   - waypoint-template-editor-content, waypoint-list-scroll
   - content-resizer, resizer-line
   - waypoint-editor-form
   - editor-content
   - waypoint-item, waypoint-header, waypoint-index, waypoint-type
   - waypoint-coords, waypoint-details, no-waypoint-selected, empty-waypoint-list
*/

.waypoint-list-scroll::-webkit-scrollbar {
  width: 8px;
}

.waypoint-list-scroll::-webkit-scrollbar-track {
  background: var(--color-bg-1);
}

.waypoint-list-scroll::-webkit-scrollbar-thumb {
  background: var(--color-bg-3);
  border-radius: var(--spacing-xxs);
}

.waypoint-list-scroll::-webkit-scrollbar-thumb:hover {
  background: var(--color-text-2);
}

.waypoint-list-scroll::-webkit-scrollbar-corner {
  background: var(--color-bg-1);
}
</style>
