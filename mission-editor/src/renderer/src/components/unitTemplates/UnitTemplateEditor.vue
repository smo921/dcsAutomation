<template>
  <EditorPanel title="Unit Template Editor" variant="primary">
    <template #toolbar>
      <Button @click="onSave" variant="primary">Save</Button>
      <Button @click="onCancel" variant="secondary">Cancel</Button>
    </template>

    <div class="editor-content">
      <!-- Basic Settings -->
      <CollapsiblePanel v-model:expanded="expandedSections.basic" title="Basic Settings">
        <div class="editor-section">
          <FormRow>
            <div class="form-group">
              <FormLabel label="Unit Template Name" required />
              <FormInput v-model="editingTemplate.name" placeholder="Enter unit template name..." />
            </div>
          </FormRow>
          <FormRow>
            <div class="form-group">
              <FormLabel label="Category" required />
              <FormSelect
                v-model="editingTemplate.category"
                :options="categoryOptions"
                placeholder="Select category..."
              />
            </div>
            <div class="form-group">
              <FormLabel label="Description" />
              <FormInput v-model="editingTemplate.description" placeholder="Enter description..." />
            </div>
          </FormRow>
        </div>
      </CollapsiblePanel>

      <!-- Units Section -->
      <CollapsiblePanel v-model:expanded="expandedSections.units" title="Units">
        <div class="editor-section">
          <div
            v-for="(unit, index) in editingTemplate.units"
            :key="index"
            class="unit-row"
            :data-unit-num="index + 1"
          >
            <div class="unit-number-badge">{{ index + 1 }}</div>
            <div class="unit-content">
              <div class="form-row">
                <div class="form-group">
                  <FormLabel label="Unit Type" required />
                  <FormInput
                    v-model="unit.type"
                    placeholder="Enter unit type..."
                  />
                </div>
                <div class="form-group">
                  <FormLabel label="Quantity" required />
                  <FormInput
                    v-model="unit.quantity"
                    type="number"
                    :min="1"
                    placeholder="1"
                  />
                </div>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <FormLabel label="Name" />
                  <FormInput
                    v-model="unit.name"
                    placeholder="Enter unit name..."
                  />
                </div>
                <div class="form-group">
                  <FormLabel label="Role" />
                  <FormInput
                    v-model="unit.role"
                    placeholder="Enter role..."
                  />
                </div>
              </div>
              <Button variant="danger" size="sm" @click="removeUnit(index)" title="Remove Unit">
                <span class="btn-remove-icon">✕</span>
              </Button>
            </div>
          </div>
          <Button @click="addUnit" variant="secondary" size="sm" class="btn-add-unit">
            + Add Unit
          </Button>
        </div>
      </CollapsiblePanel>

      <!-- Default Route Section -->
      <CollapsiblePanel v-model:expanded="expandedSections.route" title="Default Route">
        <div class="editor-section">
          <div
            v-for="(wp, index) in editingTemplate.defaultRoute"
            :key="index"
            class="waypoint-row"
            :data-waypoint-num="index + 1"
          >
            <div class="waypoint-number-badge">{{ index + 1 }}</div>
            <div class="waypoint-content">
              <div class="form-row">
                <div class="form-group">
                  <FormLabel label="Type" required />
                  <FormSelect
                    v-model="wp.type"
                    :options="waypointTypeOptions"
                    placeholder="Select type..."
                  />
                </div>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <FormLabel label="Altitude" />
                  <FormInput
                    v-model="wp.altitude"
                    type="number"
                    placeholder="Altitude in meters"
                  />
                </div>
                <div class="form-group">
                  <FormLabel label="Speed" />
                  <FormInput
                    v-model="wp.speed"
                    type="number"
                    placeholder="Speed in m/s"
                  />
                </div>
              </div>
              <Button variant="danger" size="sm" @click="removeWaypoint(index)" title="Remove Waypoint">
                <span class="btn-remove-icon">✕</span>
              </Button>
            </div>
          </div>
          <Button @click="addWaypoint" variant="secondary" size="sm" class="btn-add-waypoint">
            + Add Waypoint
          </Button>
        </div>
      </CollapsiblePanel>
    </div>
  </EditorPanel>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { Button, FormLabel, FormInput, FormSelect, FormRow, EditorPanel, CollapsiblePanel } from '../ui'

const emit = defineEmits(['unit-template-change', 'save', 'cancel'])

const props = defineProps({
  editingTemplate: {
    type: Object,
    default: null
  }
})

const expandedSections = ref({
  basic: true,
  units: true,
  route: true
})

// Category options
const categoryOptions = computed(() => [
  { value: 'air', label: 'Air' },
  { value: 'ground', label: 'Ground' },
  { value: 'naval', label: 'Naval' },
  { value: 'support', label: 'Support' }
])

// Waypoint type options
const waypointTypeOptions = computed(() => [
  { value: 'orbit', label: 'Orbit' },
  { value: 'turn_point', label: 'Turning Point' },
  { value: 'heading', label: 'Heading' },
  { value: 'landing', label: 'Landing' }
])

// Add/remove functions
const addUnit = () => {
  props.editingTemplate.units.push({ name: '', type: '', quantity: 1, role: '' })
  emit('unit-template-change', props.editingTemplate)
}

const removeUnit = (index) => {
  props.editingTemplate.units.splice(index, 1)
  emit('unit-template-change', props.editingTemplate)
}

const addWaypoint = () => {
  props.editingTemplate.defaultRoute.push({ type: 'orbit', altitude: 3000, speed: 500 })
  emit('unit-template-change', props.editingTemplate)
}

const removeWaypoint = (index) => {
  props.editingTemplate.defaultRoute.splice(index, 1)
  emit('unit-template-change', props.editingTemplate)
}

// Emit changes on deep modifications
watch(() => props.editingTemplate, (newVal) => {
  emit('unit-template-change', newVal)
}, { deep: true })

const onSave = () => {
  if (!props.editingTemplate.name) {
    window.dispatchEvent(new CustomEvent('group-status', {
      detail: { message: 'Unit template name is required', type: 'error' }
    }))
    return
  }
  emit('save', props.editingTemplate)
}

const onCancel = () => {
  emit('cancel')
}
</script>

<style scoped>
/* Uses shared classes from _components.css and _utils.css */
</style>
