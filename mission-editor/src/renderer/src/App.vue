<template>
  <div class="app">
    <header class="app-header">
      <h1>DCS Mission Editor</h1>
      <nav class="header-nav">
        <button @click="onLoadSample">Load Sample Data</button>
        <button @click="onExportJson">Export JSON</button>
        <button @click="onExportLua">Export Lua</button>
      </nav>
    </header>

    <div class="app-content">
      <aside class="sidebar" :style="{ width: sidebarWidth + 'px' }" @mousedown="startSidebarResize">
        <CollapsibleSection v-model:expanded="sections.groups" title="Groups" style="margin-top: 20px;">
          <GroupManager
            ref="groupManagerRef"
            :groups="groups"
            listOnly
            @group-change="onGroupChange"
            @group-select="onGroupSelected"
          />
        </CollapsibleSection>

        <CollapsibleSection v-model:expanded="sections.referencePoints" title="Reference Points" style="margin-top: 20px;">
          <ReferencePointManager ref="refpointManagerRef" />
        </CollapsibleSection>

        <CollapsibleSection v-model:expanded="sections.templates" title="Templates" style="margin-top: 20px;">
          <TemplateLibrary ref="templateLibraryRef" @template-apply="onTemplateApplied" @template-edit="onTemplateEdit" @template-delete="onTemplateDelete" />
        </CollapsibleSection>

        <CollapsibleSection v-model:expanded="sections.waypointTemplates" title="Waypoint Templates" style="margin-top: 20px;">
          <WaypointTemplateLibrary @waypoint-template-apply="onWaypointTemplateApplied" @waypoint-template-delete="onWaypointTemplateDelete" />
        </CollapsibleSection>
      </aside>

      <main class="main-content">
        <div class="main-editor">
          <!-- Template Editor - shown when editing a template -->
          <TemplateEditor
            v-if="editingTemplate"
            ref="templateEditorRef"
            :templates="templatesStore.categories"
            :editingTemplate="editingTemplate"
            @template-change="onTemplateChange"
            @template-delete="onTemplateDelete"
            @template-select="onTemplateSelected"
          />

          <!-- Group Editor - shown when editing a group -->
          <GroupEditor
            v-else-if="selectedGroupIndex !== null"
            ref="groupEditorRef"
            :group="groups[selectedGroupIndex]"
            :groups="groups"
            @group-change="onGroupEditorChange"
          />

          <!-- No selection state -->
          <div v-else class="no-selection">
            <p>Select an item from the sidebar to edit</p>
          </div>
        </div>
      </main>
    </div>

    <footer class="app-footer">
      <span v-if="status.message" :class="['status-message', status.type]">
        {{ status.message }}
      </span>
      <span class="version">v0.1.0</span>
    </footer>
  </div>
</template>

<script setup>
import { ref, onMounted, watch, nextTick } from 'vue'
import { useRefpointsStore } from './stores/refpoints'
import { useTemplatesStore } from './stores/templates'
import ReferencePointManager from './components/refpoints/ReferencePointManager.vue'
import TemplateLibrary from './components/templates/TemplateLibrary.vue'
import TemplateEditor from './components/templates/TemplateEditor.vue'
import WaypointTemplateLibrary from './components/templates/WaypointTemplateLibrary.vue'
import GroupManager from './components/groups/GroupManager.vue'
import GroupEditor from './components/groups/GroupEditor.vue'
import WaypointEditor from './components/editor/WaypointEditor.vue'
import CollapsibleSection from './components/CollapsibleSection.vue'
import { useResize } from './composables/useResize'

// Stores
const refpointsStore = useRefpointsStore()
const templatesStore = useTemplatesStore()

// Refs for component access
const refpointManagerRef = ref(null)
const templateLibraryRef = ref(null)
const waypointTemplateLibraryRef = ref(null)
const groupManagerRef = ref(null)
const templateEditorRef = ref(null)
const groupEditorRef = ref(null)

// Track selected group index and editing template
const selectedGroupIndex = ref(null)
const editingTemplate = ref(null)

// Sidebar sections state - groups expanded by default
const sections = ref({
  groups: true,
  referencePoints: false,
  templates: false,
  waypointTemplates: false
})

// Sidebar resize state
const sidebarWidth = ref(320)

// Use resize composable for sidebar
const { startResize: startSidebarResize } = useResize({
  size: sidebarWidth,
  minSize: 280,
  maxSize: 400,
  direction: 'horizontal'
})

// Main content ref (for potential future use)

// Groups state
const groups = ref([])

// Waypoints state (for standalone editing)
const waypoints = ref([])

// Status tracking
const status = ref({ message: '', type: 'info' })

// Menu handlers
const onLoadSample = async () => {
  try {
    const result = await window.api?.config?.loadSample?.()
    if (result?.success) {
      // Clear existing data and load sample
      refpointsStore.clear()
      templatesStore.clear()
      refpointsStore.loadFromFullConfig(result.config)
      templatesStore.loadFromFullConfig(result.config)

      // Load groups if available
      if (result.config.groups) {
        groups.value = result.config.groups
      }

      setStatus('Sample data loaded successfully', 'success')
    } else {
      setStatus(`Failed to load sample: ${result?.error || 'Unknown error'}`, 'error')
    }
  } catch (e) {
    setStatus(`Error loading sample: ${e.message}`, 'error')
  }
}

const onExportJson = () => {
  window.api?.export?.json?.()
}

const onExportLua = () => {
  window.api?.export?.lua?.()
}

// Group handlers
const onGroupChange = (newGroups) => {
  groups.value = newGroups
}

const onGroupSelected = (index) => {
  selectedGroupIndex.value = index
}

const onGroupEditorChange = (updatedGroup) => {
  // GroupEditor emits a single updated group
  if (selectedGroupIndex.value !== null) {
    const newGroups = [...groups.value]
    newGroups[selectedGroupIndex.value] = updatedGroup
    groups.value = newGroups
  }
}

// Template handlers - templates are now managed in the sidebar
const onTemplateApplied = (payload) => {
  // payload = { template, category }
  const { template, category } = payload
  // Create a new group from template - same as before
  const newGroup = {
    groupName: `${template.name.replace(/\s+/g, '_')}_${groups.value.length + 1}`,
    category: template.category === 'air' ? 'AIRPLANE' : 'GROUND',
    triggerType: 'IMMEDIATE',
    country: template.category === 'air' ? 'USA' : 'Russia',
    task: '',
    units: template.units || [],
    placement: {
      mode: 'BEARING_DISTANCE',
      reference: 'bullseye',
      referenceName: 'BULLSEYE_BLUE',
      bearing: 0,
      distance: 100
    },
    route: template.defaultRoute ? [{ ...template.defaultRoute }] : [{ type: 'orbit', altitude: 3000, speed: 500 }]
  }
  groups.value = [...groups.value, newGroup]
  setStatus(`Template "${template.name}" applied to new group`, 'success')
}

const onTemplateEdit = (payload) => {
  // payload = { template, category }
  const { template, category } = payload
  // Set the template as being edited - TemplateEditor will show it
  editingTemplate.value = { ...template, category }
  setStatus(`Editing template: "${template.name}"`, 'info')
}

// Status helper
const setStatus = (message, type = 'info') => {
  status.value = { message, type }
  setTimeout(() => {
    status.value = { message: '', type: 'info' }
  }, 3000)
}

// Initialize
onMounted(() => {
  // Load refpoints
  window.api?.refpoints?.load?.().then(config => {
    if (config) {
      refpointsStore.loadFromConfig(config)
    }
  })

  // Load templates
  window.api?.templates?.loadAll?.().then(templates => {
    if (templates) {
      templatesStore.loadTemplates(templates)
    }
  })
})

// Template management handlers
const onTemplateSave = (template) => {
  const category = template.category || 'air'
  const existingCategory = templatesStore.categories[category] || []

  // Check for duplicate ID or name
  const existingIndex = existingCategory.findIndex(t =>
    (t.id && t.id === template.id) || (!t.id && t.name === template.name)
  )

  if (existingIndex !== -1) {
    // Update existing template using store method
    templatesStore.updateTemplate(category, existingIndex, template)
    setStatus(`Template "${template.name}" updated`, 'success')
  } else {
    // Add new template using store method
    templatesStore.addTemplate(category, template)
    setStatus(`Template "${template.name}" created`, 'success')
  }
}

const onTemplateDelete = (payload) => {
  // payload = { template, category }
  const { template, category } = payload
  const categoryTemplates = templatesStore.categories[category] || []
  const templateIndex = categoryTemplates.findIndex(t =>
    (t.id && t.id === template.id) || (!t.id && t.name === template.name)
  )

  if (templateIndex !== -1) {
    templatesStore.deleteTemplate(category, templateIndex)
    setStatus(`Template "${template.name}" deleted`, 'info')
    // Reset editing template if the deleted template was being edited
    if (editingTemplate.value && editingTemplate.value.name === template.name) {
      editingTemplate.value = null
    }
  }
}

const onTemplateChange = (template) => {
  // Called when a template is saved in the editor
  onTemplateSave(template)
}

const onTemplateSelected = (template) => {
  // Template selected in editor - could be used for keyboard shortcuts later
}

// Waypoint template handlers
const onWaypointTemplateApplied = (template) => {
  // Check if there's a selected group to apply the template to
  if (selectedGroupIndex.value !== null && selectedGroupIndex.value !== undefined) {
    const group = groups.value[selectedGroupIndex.value]
    if (group) {
      // Apply waypoint template to group route
      group.route = template.waypoints || []
      groups.value = [...groups.value] // Trigger reactivity
      setStatus(`Waypoint template "${template.name}" applied to "${group.groupName}"`, 'success')
      return
    }
  }

  // If no group selected, create a new group from the waypoint template
  const newGroup = {
    groupName: `${template.name.replace(/\s+/g, '_')}_${groups.value.length + 1}`,
    category: 'AIRPLANE',
    triggerType: 'IMMEDIATE',
    country: 'USA',
    task: '',
    units: [
      {
        name: `${template.name} Lead`,
        type: 'F/A-18C',
        quantity: 2
      }
    ],
    placement: {
      mode: 'BEARING_DISTANCE',
      reference: 'bullseye',
      referenceName: 'BULLSEYE_BLUE',
      bearing: 0,
      distance: 100
    },
    route: template.waypoints || []
  }
  groups.value = [...groups.value, newGroup]
  setStatus(`Waypoint template "${template.name}" applied to new group`, 'success')
}

const onWaypointTemplateDelete = (template) => {
  // Delete the template from the store
  templatesStore.deleteWaypointTemplate(template.id)
  setStatus(`Waypoint template "${template.name}" deleted`, 'info')
}
</script>

<style>
/* Import design tokens */
@import './styles/index.css';

.app {
  display: flex;
  flex-direction: column;
  height: 100vh;
}

.app-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--spacing-md) var(--spacing-xl);
  background: var(--color-bg-1);
  border-bottom: 1px solid var(--color-border);
}

.app-header h1 {
  font-size: var(--font-size-3xl);
  color: var(--color-text-4);
}

.header-nav button {
  background: var(--color-primary);
  color: white;
  border: none;
  padding: var(--spacing-sm) var(--spacing-md);
  border-radius: var(--spacing-xxs);
  cursor: pointer;
  margin-left: var(--spacing-sm);
  font-size: var(--font-size-sm);
}

.header-nav button:hover {
  background: var(--color-primary-hover);
}

/* Tab buttons for Groups/Waypoints */
.content-tabs {
  display: flex;
  gap: var(--spacing-md);
  margin-bottom: var(--spacing-md);
}

.tab-btn {
  composes: u-btn;
  background: var(--color-bg-2);
  color: var(--color-text-0);
  border: 1px solid var(--color-border);
  padding: var(--spacing-sm) var(--spacing-lg);
  border-radius: var(--spacing-xs);
  cursor: pointer;
  font-size: var(--font-size-md);
  font-weight: var(--font-weight-medium);
  transition: all var(--transition-normal);
}

.tab-btn:hover {
  background: var(--color-bg-3);
}

.tab-btn.active {
  background: var(--color-primary);
  border-color: var(--color-primary);
  color: white;
}

.app-content {
  display: flex;
  flex: 1;
  min-height: 0;
  height: 100%;
}

.sidebar {
  flex: 0 0 auto;
  width: 320px;
  height: 100%;
  background: var(--color-bg-1);
  border-right: 1px solid var(--color-border);
  padding: var(--spacing-lg);
  overflow-y: auto;
  overflow-x: hidden;
  position: relative;
  display: flex;
  flex-direction: column;
}

/* Sidebar section content filling */
.sidebar .flex-fill {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
}

/* Sidebar resize handle */
.sidebar::after {
  content: '';
  position: absolute;
  top: 0;
  right: 0;
  width: 4px;
  height: 100%;
  cursor: col-resize;
  background: transparent;
  z-index: 10;
}

.sidebar::after:hover {
  background: var(--color-primary);
}

.main-content {
  flex: 1;
  min-height: 0;
  padding: var(--spacing-xl);
  background: var(--color-bg-0);
  display: flex;
  flex-direction: column;
}

.main-content h2 {
  font-size: var(--font-size-xl);
  color: var(--color-text-4);
  margin-bottom: var(--spacing-md);
}

/* Fixed divider between tabs and content - kept for backward compatibility */
.content-divider {
  height: 6px;
  background: var(--color-border);
  cursor: default;
  flex: 0 0 auto;
}

.tab-content {
  display: none;
}

/* Content layout wrappers for groups and waypoints */
.group-content-layout,
.waypoint-content-layout {
  width: 100%;
  flex: 1;
  min-height: 0;
  max-height: 100%;
  display: flex;
  flex-direction: column;
}

/* Waypoint count message */
.waypoint-count {
  margin-top: var(--spacing-md);
}

.waypoint-count p {
  font-size: var(--font-size-xxs);
  color: var(--color-text-1);
}

.app-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--spacing-xs) var(--spacing-xl);
  background: var(--color-bg-1);
  border-top: 1px solid var(--color-border);
  font-size: var(--font-size-sm);
}

.status-message {
  padding: var(--spacing-xs) var(--spacing-sm);
  border-radius: var(--spacing-xxs);
}

.status-message.success {
  background: var(--color-success);
  color: white;
}

.status-message.error {
  background: var(--color-error);
  color: white;
}

.status-message.info {
  background: var(--color-primary);
  color: white;
}

.version {
  color: var(--color-text-1);
}

/* Main editor area */
.main-editor {
  flex: 1;
  min-height: 0;
  position: relative;
  display: flex;
  flex-direction: column;
}

/* No selection state */
.no-selection {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: var(--color-text-1);
  font-size: var(--font-size-md);
}
</style>
