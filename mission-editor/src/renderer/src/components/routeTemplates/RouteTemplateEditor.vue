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

        <!-- Scrollable Route List -->
        <div class="list-scroll" :style="{ height: listHeight + 'px' }">
          <div class="list-container">
            <!-- Route Type Header -->
            <div class="list-item-header">
              <span class="route-index">#</span>
              <span class="route-type">Type</span>
              <span class="route-details">Details</span>
              <span></span>
            </div>

            <!-- Route Edit Rows -->
            <div
              v-for="(wp, index) in route"
              :key="index"
              class="list-item"
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
  </EditorPanel>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { FormInput, FormSelect, FormRow, FormLabel, EditorPanel, Button } from '../ui'

const emit = defineEmits(['save', 'cancel', 'update:route', 'update:templateName'])

const props = defineProps({
  route: {
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

// Watch for route changes and emit to parent
watch(() => props.route, (newVal) => {
  emit('update:route', newVal)
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

// Use resize composable for list height (optional - can be removed)
const listHeight = ref(250)

// Add a new route point with default values
const addRouteItem = () => {
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
}

const removeRouteItem = (index) => {
  props.route.splice(index, 1)
}

const onSave = () => {
  emit('save', props.route)
}

const onCancel = () => {
  emit('cancel')
}
</script>

<style scoped>
/* Uses shared classes from _components.css: editor-content, editor-section */
/* Uses shared classes from _list-editor.css: list-scroll, list-container, list-item, list-item-header */
/* Custom classes for route-specific styling */
</style>
