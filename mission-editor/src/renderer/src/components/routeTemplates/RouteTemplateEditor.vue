<template>
  <EditorPanel :title="`Route Template: ${localTemplateName}`" variant="primary">
    <template #toolbar>
      <Button @click="onSave" variant="primary">Save</Button>
      <Button @click="onCancel" variant="secondary">Cancel</Button>
    </template>

    <div class="editor-content">
      <div class="route-template-editor-content">
        <!-- Template name input -->
        <div class="editor-section">
          <FormRow>
            <div class="form-group">
              <FormLabel label="Template Name" />
              <FormInput v-model="localTemplateName" placeholder="Enter route template name..." />
            </div>
          </FormRow>
        </div>

        <!-- Scrollable Waypoint List -->
        <div class="list-scroll" :style="{ height: listHeight + 'px' }">
          <div class="list-container">
            <!-- Waypoint Type Header -->
            <div class="list-item-header">
              <span class="waypoint-index">#</span>
              <span class="waypoint-type">Type</span>
              <span class="waypoint-details">Details</span>
              <span></span>
            </div>

            <!-- Waypoint Edit Rows -->
            <div
              v-for="(wp, index) in waypoints"
              :key="index"
              class="list-item"
            >
              <div class="list-item-content">
                <span class="waypoint-index">{{ index + 1 }}</span>

                <!-- Type selector -->
                <FormSelect
                  v-model="wp.type"
                  :options="waypointTypeOptions"
                  class="waypoint-type"
                />

                <!-- Type-specific fields -->
                <div class="waypoint-edit-fields">
                  <!-- Orbit fields -->
                  <div v-if="wp.type === 'orbit'">
                    <FormRow>
                      <div class="form-group">
                        <FormLabel label="Alt" />
                        <FormInput v-model="wp.altitude" type="number" />
                      </div>
                      <div class="form-group">
                        <FormLabel label="Speed" />
                        <FormInput v-model="wp.speed" type="number" />
                      </div>
                    </FormRow>
                    <FormRow>
                      <div class="form-group">
                        <FormLabel label="Radius" />
                        <FormInput v-model="wp.radius" type="number" />
                      </div>
                      <div class="form-group">
                        <FormLabel label="Pattern" />
                        <FormSelect v-model="wp.pattern" :options="patternOptions" />
                      </div>
                    </FormRow>
                  </div>

                  <!-- Turn point / Heading fields -->
                  <div v-if="wp.type === 'turn_point' || wp.type === 'heading'">
                    <FormRow>
                      <div class="form-group">
                        <FormLabel label="X Offset" />
                        <FormInput v-model="wp.x" type="number" />
                      </div>
                      <div class="form-group">
                        <FormLabel label="Y Offset" />
                        <FormInput v-model="wp.y" type="number" />
                      </div>
                    </FormRow>
                    <FormRow>
                      <div class="form-group">
                        <FormLabel label="Alt" />
                        <FormInput v-model="wp.altitude" type="number" />
                      </div>
                      <div class="form-group">
                        <FormLabel label="Speed" />
                        <FormInput v-model="wp.speed" type="number" />
                      </div>
                    </FormRow>
                  </div>

                  <!-- Landing fields -->
                  <div v-if="wp.type === 'landing'">
                    <FormRow>
                      <div class="form-group">
                        <FormLabel label="Airbase" />
                        <FormSelect v-model="wp.airbase" :options="airbaseOptions" />
                      </div>
                    </FormRow>
                  </div>
                </div>
              </div>

              <Button variant="danger" size="sm" @click="removeWaypoint(index)" title="Remove Waypoint">
                <span class="btn-remove-icon">✕</span>
              </Button>
            </div>

            <Button @click="addWaypoint" variant="secondary" size="sm" block>
              <span>+</span> Add Waypoint
            </Button>
          </div>
        </div>
      </div>
    </div>
  </EditorPanel>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { FormInput, FormSelect, FormRow, FormLabel, EditorPanel, Button } from '../ui'

const emit = defineEmits(['save', 'cancel', 'update:waypoints', 'update:templateName'])

const props = defineProps({
  waypoints: {
    type: Array,
    default: () => []
  },
  airbases: {
    type: Array,
    default: () => []
  },
  templateName: {
    type: String,
    default: 'Unnamed Route Template'
  }
})

// Local ref for template name (since prop can't be directly modified)
const localTemplateName = ref(props.templateName)

// Emit update when template name changes
watch(localTemplateName, (newVal) => {
  emit('update:templateName', newVal)
})

// Watch for waypoints changes and emit to parent
watch(() => props.waypoints, (newVal) => {
  emit('update:waypoints', newVal)
}, { deep: true })

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

// Use resize composable for list height (optional - can be removed)
const listHeight = ref(250)

// Add a new waypoint with default values
const addWaypoint = () => {
  props.waypoints.push({
    type: 'orbit',
    altitude: 3000,
    speed: 500,
    radius: 10,
    pattern: 'clockwise',
    x: 0,
    y: 0,
    airbase: ''
  })
}

const removeWaypoint = (index) => {
  props.waypoints.splice(index, 1)
}

const onSave = () => {
  emit('save', props.waypoints)
}

const onCancel = () => {
  emit('cancel')
}
</script>

<style scoped>
/* Uses shared classes from _components.css: editor-content, editor-section */
/* Uses shared classes from _list-editor.css: list-scroll, list-container, list-item, list-item-header */
/* Custom classes for waypoint-specific styling */
</style>
