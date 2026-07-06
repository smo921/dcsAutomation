<template>
  <div class="template-editor">
    <!-- Template List Header -->
    <div class="template-list-header">
      <h3>Templates</h3>
      <div class="header-actions">
        <Button @click="onAddTemplate" variant="primary">+ New Template</Button>
      </div>
    </div>

    <!-- Scrollable Template List -->
    <div class="template-list-scroll" :style="{ height: listHeight + 'px' }">
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

        <div v-if="templatesList.length === 0" class="empty-state">
          <p>No templates configured. Click "New Template" to create one.</p>
        </div>
      </div>
    </div>

    <!-- Resizeable Divider -->
    <div class="content-resizer" @mousedown="startListResize">
      <span class="resizer-line"></span>
    </div>

    <!-- Template Editor Panel -->
    <div v-if="selectedTemplate && currentTemplate" class="template-editor-panel">
      <div class="editor-content">
        <!-- Basic Settings -->
        <CollapsibleSection v-model:expanded="expandedSections.basic" title="Basic Settings">
        <div class="editor-section">
          <div class="form-row">
            <div class="form-group">
              <label>Template Name</label>
              <input type="text" v-model="currentTemplate.name" class="form-input" />
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Category</label>
              <select v-model="currentTemplate.category" class="form-input">
                <option value="air">Air</option>
                <option value="ground">Ground</option>
                <option value="naval">Naval</option>
                <option value="support">Support</option>
              </select>
            </div>
            <div class="form-group">
              <label>Description</label>
              <input type="text" v-model="currentTemplate.description" class="form-input" />
            </div>
          </div>
        </div>
        </CollapsibleSection>

        <!-- Units Section -->
        <CollapsibleSection v-model:expanded="expandedSections.units" title="Units">
          <div class="editor-section">
            <div v-for="(unit, index) in currentTemplate.units" :key="index" class="unit-row" :data-unit-num="index + 1">
              <div class="unit-number-badge">{{ index + 1 }}</div>
              <div class="unit-content">
                <div class="form-row">
                  <div class="form-group">
                    <label>Unit Type</label>
                    <input type="text" v-model="unit.type" class="form-input" />
                  </div>
                  <div class="form-group">
                    <label>Quantity</label>
                    <input type="number" v-model="unit.quantity" min="1" class="form-input" />
                  </div>
                </div>
                <div class="form-row">
                  <div class="form-group">
                    <label>Name</label>
                    <input type="text" v-model="unit.name" class="form-input" />
                  </div>
                  <div class="form-group">
                    <label>Role</label>
                    <input type="text" v-model="unit.role" class="form-input" />
                  </div>
                </div>
                <Button @click="removeUnit(index)" variant="ghost" icon-only title="Remove Unit">✕</Button>
              </div>
            </div>
            <Button @click="addUnit" variant="secondary" size="sm" class="btn-add-unit">+ Add Unit</Button>
          </div>
        </CollapsibleSection>

        <!-- Route Section -->
        <CollapsibleSection v-model:expanded="expandedSections.route" title="Default Route">
          <div class="editor-section">
            <div v-for="(wp, index) in currentTemplate.defaultRoute" :key="index" class="waypoint-row" :data-waypoint-num="index + 1">
              <div class="waypoint-number-badge">{{ index + 1 }}</div>
              <div class="waypoint-content">
                <div class="form-row">
                  <div class="form-group">
                    <label>Type</label>
                    <select v-model="wp.type" class="form-input">
                      <option value="orbit">Orbit</option>
                      <option value="turn_point">Turning Point</option>
                      <option value="heading">Heading</option>
                      <option value="landing">Landing</option>
                    </select>
                  </div>
                </div>
                <div class="form-row">
                  <div class="form-group">
                    <label>Altitude</label>
                    <input type="number" v-model="wp.altitude" class="form-input" />
                  </div>
                  <div class="form-group">
                    <label>Speed</label>
                    <input type="number" v-model="wp.speed" class="form-input" />
                  </div>
                </div>
                <Button @click="removeWaypoint(index)" variant="ghost" icon-only title="Remove Waypoint">✕</Button>
              </div>
            </div>
            <Button @click="addWaypoint" variant="secondary" size="sm" class="btn-add-waypoint">+ Add Waypoint</Button>
          </div>
        </CollapsibleSection>

        <!-- Actions Footer -->
        <div class="template-actions">
          <Button @click="saveTemplate" variant="primary">Save</Button>
          <Button @click="deleteTemplate" variant="danger">Delete</Button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { Button } from '../ui'
import CollapsibleSection from '../CollapsibleSection.vue'

const emit = defineEmits(['template-change', 'template-delete', 'template-select'])

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

// Watch for external template selection
watch(() => props.editingTemplate, (newTemplate) => {
  if (newTemplate) {
    selectTemplate(newTemplate)
  }
}, { immediate: true })

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
.template-editor {
  width: 100%;
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
}

.template-list-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: var(--spacing-md);
}

.template-list-header h3 {
  font-size: var(--font-size-lg);
  color: var(--color-text-4);
  margin: 0;
}

.template-list-header button {
  padding: var(--spacing-xs) var(--spacing-sm);
}

/* Scrollable Template List Container */
.template-list-scroll {
  flex: 0 0 auto;
  overflow-y: auto;
  min-height: 100px;
  margin-bottom: var(--spacing-md);
  max-height: 300px;
}

/* Custom Scrollbar Styles for Template List */
.template-list-scroll::-webkit-scrollbar {
  width: 8px;
}

.template-list-scroll::-webkit-scrollbar-track {
  background: var(--color-bg-1);
}

.template-list-scroll::-webkit-scrollbar-thumb {
  background: var(--color-bg-3);
  border-radius: var(--spacing-xxs);
}

.template-list-scroll::-webkit-scrollbar-thumb:hover {
  background: var(--color-text-2);
}

.template-list-scroll::-webkit-scrollbar-corner {
  background: var(--color-bg-1);
}

.template-list {
  background: var(--color-bg-1);
  border-radius: var(--spacing-xs);
  border: 1px solid var(--color-border);
}

.template-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--spacing-sm);
  border-bottom: 1px solid var(--color-border);
  cursor: pointer;
  transition: background var(--transition-fast);
}

.template-item:hover {
  background: var(--color-bg-3);
}

.template-item.active {
  background: var(--color-primary);
}

.template-item.active .template-category,
.template-item.active .unit-count {
  background: rgba(255, 255, 255, 0.3);
  color: white;
}

.template-info {
  flex: 1;
}

.template-info h4 {
  font-size: var(--font-size-md);
  color: var(--color-text-4);
  margin: 0 0 var(--spacing-xs) 0;
}

.template-meta {
  display: flex;
  gap: var(--spacing-sm);
  font-size: var(--font-size-xxs);
}

.template-category {
  background: var(--color-bg-2);
  padding: var(--spacing-xxs) var(--spacing-sm);
  border-radius: var(--spacing-xxs);
  text-transform: capitalize;
}

.unit-count {
  background: var(--color-bg-2);
  padding: var(--spacing-xxs) var(--spacing-sm);
  border-radius: var(--spacing-xxs);
}

.empty-state {
  padding: var(--spacing-lg);
  text-align: center;
  color: var(--color-text-1);
  font-size: var(--font-size-md);
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

/* Template Editor Panel */
.template-editor-panel {
  background: var(--color-bg-1);
  border-radius: var(--spacing-xs);
  border: 1px solid var(--color-border);
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
}

/* Editor content container - scrollable area */
.editor-content {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  padding: var(--spacing-md);
}

.editor-content:last-child {
  padding-bottom: calc(var(--spacing-md) - var(--spacing-sm));
}

/* Custom Scrollbar Styles for Editor Content */
.editor-content::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

.editor-content::-webkit-scrollbar-track {
  background: var(--color-bg-1);
}

.editor-content::-webkit-scrollbar-thumb {
  background: var(--color-bg-3);
  border-radius: var(--spacing-xxs);
}

.editor-content::-webkit-scrollbar-thumb:hover {
  background: var(--color-text-2);
}

.editor-content::-webkit-scrollbar-corner {
  background: var(--color-bg-1);
}

.template-actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--spacing-sm);
  margin-top: var(--spacing-md);
  padding-top: var(--spacing-md);
  border-top: 1px solid var(--color-border);
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--spacing-sm);
  margin-bottom: var(--spacing-sm);
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

.unit-row,
.waypoint-row {
  display: flex;
  gap: var(--spacing-sm);
  padding: var(--spacing-md);
  background: var(--color-bg-4);
  border-radius: var(--spacing-xs);
  margin-top: var(--spacing-md);
  border: 1px solid var(--color-border);
}

.unit-row + .unit-row,
.waypoint-row + .waypoint-row {
  margin-top: var(--spacing-xl);
  border-top: 2px solid var(--color-primary);
}

.unit-number-badge,
.waypoint-number-badge {
  flex: 0 0 32px;
  height: 32px;
  background: var(--color-primary);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: var(--spacing-xxs);
  font-weight: var(--font-weight-bold);
  font-size: var(--font-size-lg);
  user-select: none;
}

.unit-content,
.waypoint-content {
  flex: 1;
}
</style>
