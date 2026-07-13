<template>
  <div class="route-editor">
    <!-- Route List Section -->
    <div class="route-editor-list-section">
      <div class="list-scroll list-scroll--flex">
        <div class="list-container">
          <!-- Route Header -->
          <div class="list-item-header">
            <span class="route-index">#</span>
            <span class="route-type">Type</span>
            <span class="route-details">Details</span>
            <span></span>
          </div>

          <!-- Route Items -->
          <div
            v-for="(wp, index) in route"
            :key="index"
            class="waypoint-row"
            :data-waypoint-num="index + 1"
          >
            <div class="list-item-content">
              <span class="route-index">{{ index + 1 }}</span>

              <!-- Type selector -->
              <FormSelect
                v-model="wp.type"
                :options="routeTypeOptions"
                class="route-type"
              />

              <!-- Type-specific fields -->
              <div class="route-edit-fields">
                <!-- Orbit fields -->
                <div v-if="wp.type === 'orbit'">
                  <FormRow>
                    <FormGroup>
                      <FormLabel label="Altitude" />
                      <FormInput v-model="wp.altitude" type="number" />
                    </FormGroup>
                    <FormGroup>
                      <FormLabel label="Altitude Type" />
                      <FormInput v-model="wp.altitudeType" />
                    </FormGroup>
                    <FormGroup>
                      <FormLabel label="Speed" />
                      <FormInput v-model="wp.speed" type="number" />
                    </FormGroup>
                  </FormRow>
                  <FormRow>
                    <FormGroup>
                      <FormLabel label="Radius" />
                      <FormInput v-model="wp.radius" type="number" />
                    </FormGroup>
                    <FormGroup>
                      <FormLabel label="Pattern" />
                      <FormSelect v-model="wp.pattern" :options="patternOptions" />
                    </FormGroup>
                  </FormRow>
                </div>

                <!-- Turn point / Heading fields -->
                <div v-if="wp.type === 'turn_point' || wp.type === 'heading'">
                  <FormRow>
                    <FormGroup>
                      <FormLabel label="X Offset" />
                      <FormInput v-model="wp.x" type="number" />
                    </FormGroup>
                    <FormGroup>
                      <FormLabel label="Y Offset" />
                      <FormInput v-model="wp.y" type="number" />
                    </FormGroup>
                  </FormRow>
                  <FormRow>
                    <FormGroup>
                      <FormLabel label="Altitude" />
                      <FormInput v-model="wp.altitude" type="number" />
                    </FormGroup>
                    <FormGroup>
                      <FormLabel label="Altitude Type" />
                      <FormInput v-model="wp.altitudeType" />
                    </FormGroup>
                    <FormGroup>
                      <FormLabel label="Speed" />
                      <FormInput v-model="wp.speed" type="number" />
                    </FormGroup>
                  </FormRow>
                </div>

                <!-- Landing fields -->
                <div v-if="wp.type === 'landing'">
                  <FormRow>
                    <FormGroup>
                      <FormLabel label="Airbase" />
                      <FormSelect v-model="wp.airbase" :options="airbaseOptions" />
                    </FormGroup>
                  </FormRow>
                </div>
              </div>
            </div>

            <Button variant="danger" size="sm" @click="removeRouteItem(index)" title="Remove Route Point">
              <span class="btn-remove-icon">✕</span>
            </Button>
          </div>

          <Button @click="addRouteItem" variant="secondary" size="sm" block>
            <span>+</span> Add Route Point
          </Button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick } from 'vue'
import { FormInput, FormSelect, FormRow, FormLabel, Button } from '../ui'
import FormGroup from '../ui/FormGroup.vue'

const emit = defineEmits(['update:route', 'add', 'remove'])

const props = defineProps({
  route: {
    type: Array,
    default: () => []
  },
  airbases: {
    type: Array,
    default: () => []
  }
})

// Watch for route changes and emit to parent
const isUpdating = ref(false)

watch(() => props.route, (newVal) => {
  if (!isUpdating.value) {
    emit('update:route', newVal)
  }
}, { deep: true })

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
  return props.airbases.map(a => ({ value: a.name, label: a.name }))
})

// Add a new route point with default values
const addRouteItem = () => {
  isUpdating.value = true
  props.route.push({
    type: 'orbit',
    altitude: 3000,
    speed: 500,
    radius: 10,
    pattern: 'clockwise',
    x: 0,
    y: 0,
    airbase: ''
  })
  // Scroll to new item after next tick
  nextTick(() => {
    isUpdating.value = false
  })
}

const removeRouteItem = (index) => {
  isUpdating.value = true
  props.route.splice(index, 1)
  nextTick(() => {
    isUpdating.value = false
  })
}
</script>

<style scoped>
/* Uses shared classes from _components.css: list-container, list-item, list-item-header */
/* Uses shared classes from _list-editor.css: list-scroll, list-scroll--flex, list-item-content */
/* Route-specific styles */

.route-editor {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
}

/* Route-specific column widths */
.route-index {
  flex: 0 0 50px;
}

.route-type {
  flex: 0 0 120px;
}

.route-details {
  flex: 1;
}

/* Route edit fields container */
.route-edit-fields {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-sm);
}
</style>
