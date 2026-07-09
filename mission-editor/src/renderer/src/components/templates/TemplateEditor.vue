<template>
  <EditorPanel title="Template Editor" variant="primary">
    <template #headerActions>
      <Button @click="onAddTemplate" variant="primary">+ New Template</Button>
    </template>

    <div class="template-editor-content">
      <!-- Scrollable Template List -->
      <div class="template-list-scroll scrollbar-custom" :style="{ height: listHeight + 'px' }">
        <div class="template-list">
          <div
            v-for="template in templatesList"
            :key="template.id || template.name"
            class="template-item"
            :class="{ active: selectedTemplate === (template.id || template.name) }"
            @click="selectTemplate(template)"
          >
            <div class="template-info">
              <h4>{{ template.name }}</h4>
              <div class="template-meta">
                <span class="template-category">{{ template.category || 'general' }}</span>
                <span v-if="template.units" class="unit-count">
                  {{ Array.isArray(template.units) ? template.units.length : 0 }} units
                </span>
              </div>
            </div>
          </div>

          <EmptyState v-if="templatesList.length === 0">
            <p>No templates configured. Click "New Template" to create one.</p>
          </EmptyState>
        </div>
      </div>

      <!-- Resizeable Divider -->
      <div class="content-resizer" @mousedown="startListResize">
        <span class="resizer-line"></span>
      </div>

      <!-- Template Editor Form -->
      <div v-if="selectedTemplate && currentTemplate" class="template-form">
        <CollapsiblePanel v-model:expanded="expandedSections.basic" title="Basic Settings">
          <div class="editor-section">
            <div class="form-row">
              <div class="form-group">
                <FormLabel label="Template Name" required />
                <FormInput
                  v-model="currentTemplate.name"
                  placeholder="Enter template name..."
                />
              </div>
            </div>
            <div class="form-row">
              <div class="form-group">
                <FormLabel label="Category" required />
                <FormSelect
                  v-model="currentTemplate.category"
                  :options="categoryOptions"
                  placeholder="Select category..."
                />
              </div>
              <div class="form-group">
                <FormLabel label="Description" />
                <FormInput
                  v-model="currentTemplate.description"
                  placeholder="Enter description..."
                />
              </div>
            </div>
          </div>
        </CollapsiblePanel>

        <CollapsiblePanel v-model:expanded="expandedSections.units" title="Units">
          <div class="editor-section">
            <div
              v-for="(unit, index) in currentTemplate.units"
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
                <button class="btn-remove" @click="removeUnit(index)" title="Remove Unit">
                  <span class="btn-remove-icon">✕</span>
                </button>
              </div>
            </div>
            <Button @click="addUnit" variant="secondary" size="sm" class="btn-add-unit">
              + Add Unit
            </Button>
          </div>
        </CollapsiblePanel>

        <CollapsiblePanel v-model:expanded="expandedSections.route" title="Default Route">
          <div class="editor-section">
            <div
              v-for="(wp, index) in currentTemplate.defaultRoute"
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
                <button class="btn-remove" @click="removeWaypoint(index)" title="Remove Waypoint">
                  <span class="btn-remove-icon">✕</span>
                </button>
              </div>
            </div>
            <Button @click="addWaypoint" variant="secondary" size="sm" class="btn-add-waypoint">
              + Add Waypoint
            </Button>
          </div>
        </CollapsiblePanel>

        <div class="template-actions">
          <Button @click="saveTemplate" variant="primary">Save</Button>
          <Button @click="deleteTemplate" variant="danger">Delete</Button>
        </div>
      </div>
    </div>
  </EditorPanel>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { Button, FormLabel, FormInput, FormSelect, EmptyState, EditorPanel, CollapsiblePanel } from '../ui'

const emit = defineEmits(['template-change', 'template-delete', 'template-select', 'add-template'])

const props = defineProps({
  templates: {
    type: Object,
    default: () => ({ air: [], ground: [], naval: [], support: [] })
  },
  editingTemplate: {
    type: Object,
    default: null
  }
})

const selectedTemplate = ref('')
const currentTemplate = ref(null)

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

// Get all templates from all categories
const templatesList = computed(() => {
  const all = []
  for (const [category, items] of Object.entries(props.templates)) {
    if (Array.isArray(items)) {
      all.push(...items.map(t => ({ ...t, category })))
    }
  }
  return all
})

// Section expansion state (all expanded by default)
const expandedSections = ref({
  basic: true,
  units: true,
  route: true
})

// Use resize composable for list/editor divider
const listHeight = ref(300)

// Simple resize handler
let isResizing = false
let startY = 0
let startHeight = 0

const startListResize = (e) => {
  isResizing = true
  startY = e.clientY
  startHeight = listHeight.value
  document.addEventListener('mousemove', onMouseMove)
  document.addEventListener('mouseup', onMouseUp)
}

const onMouseMove = (e) => {
  if (!isResizing) return
  const dy = e.clientY - startY
  listHeight.value = Math.max(100, Math.min(500, startHeight + dy))
}

const onMouseUp = () => {
  isResizing = false
}

const selectTemplate = (template) => {
  selectedTemplate.value = template.id || template.name
  currentTemplate.value = JSON.parse(JSON.stringify(template))
  emit('template-select', template)
}

const onAddTemplate = () => {
  const newTemplate = {
    name: 'New Template',
    category: 'air',
    description: '',
    units: [{ name: '', type: '', quantity: 1, role: '' }],
    defaultRoute: [{ type: 'orbit', altitude: 3000, speed: 500, radius: 15 }]
  }
  emit('template-change', newTemplate)
  selectedTemplate.value = newTemplate.name
  currentTemplate.value = newTemplate
  emit('add-template', newTemplate)
}

const onDeleteTemplate = (template) => {
  emit('template-delete', template)
  selectedTemplate.value = ''
  currentTemplate.value = null
}

const saveTemplate = () => {
  if (!currentTemplate.value.name) {
    window.dispatchEvent(new CustomEvent('group-status', {
      detail: { message: 'Template name is required', type: 'error' }
    }))
    return
  }
  emit('template-change', currentTemplate.value)
  setStatus('Template saved', 'success')
}

const deleteTemplate = () => {
  if (currentTemplate.value) {
    emit('template-delete', currentTemplate.value)
    selectedTemplate.value = ''
    currentTemplate.value = null
  }
}

const addUnit = () => {
  currentTemplate.value.units.push({ name: '', type: '', quantity: 1, role: '' })
}

const removeUnit = (index) => {
  currentTemplate.value.units.splice(index, 1)
}

const addWaypoint = () => {
  currentTemplate.value.defaultRoute.push({ type: 'orbit', altitude: 3000, speed: 500 })
}

const removeWaypoint = (index) => {
  currentTemplate.value.defaultRoute.splice(index, 1)
}

const setStatus = (message, type = 'info') => {
  window.dispatchEvent(new CustomEvent('group-status', { detail: { message, type } }))
}

// Watch for external template selection
watch(() => props.editingTemplate, (newTemplate) => {
  if (newTemplate) {
    selectTemplate(newTemplate)
  }
}, { immediate: true })

// Watch for external template changes
watch(() => props.templates, (newVal) => {
  // Refresh if templates changed externally
}, { deep: true })

// Expose methods for external access
defineExpose({
  selectTemplate
})
</script>

<style scoped>
/* Use shared classes from components.css */
.template-editor-content {
  width: 100%;
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
}

.template-form {
  width: 100%;
  display: flex;
  flex-direction: column;
}

/* Template Actions Footer */
.template-actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--spacing-sm);
  padding-top: var(--spacing-md);
  border-top: 1px solid var(--color-border);
}
</style>
