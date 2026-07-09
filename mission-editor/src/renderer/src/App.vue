<template>
  <div class="app">
    <header class="app-header">
      <h1>DCS Mission Editor</h1>
      <nav class="header-nav">
        <button @click="onNewMission">New Mission</button>
        <button @click="onLoadSample">Load Sample Data</button>
        <button @click="onExportJson">Export JSON</button>
        <button @click="onExportLua">Export Lua</button>
      </nav>
    </header>

    <div class="app-content">
      <aside class="sidebar" :style="{ width: sidebarWidth + 'px' }" @mousedown="startSidebarResize">
        <CollapsibleSection :expanded="sections.groups" @update:expanded="sections.groups = $event" title="Groups">
          <GroupManager
            ref="groupManagerRef"
            :groups="groups"
            listOnly
            @group-change="onGroupChange"
            @group-edit="onGroupEdit"
          />
        </CollapsibleSection>

        <CollapsibleSection :expanded="sections.referencePoints" @update:expanded="sections.referencePoints = $event" title="Reference Points">
          <div class="section-load-hint" v-if="refpointsStore.bullseyes.length === 0 && refpointsStore.airbases.length === 0 && refpointsStore.zones.length === 0 && refpointsStore.lines.length === 0">
            <p>No reference points loaded.</p>
            <button @click="onLoadReferencePoints" class="btn-load">Load Config</button>
          </div>
          <ReferencePointManager ref="refpointManagerRef" :list-only="true" @select="onReferencePointSelected" @refpoint-edit="onReferencePointEdit" @refpoint-delete="onReferencePointDelete" />
        </CollapsibleSection>

        <CollapsibleSection :expanded="sections.templates" @update:expanded="sections.templates = $event" title="Templates">
          <div class="section-load-hint" v-if="!hasTemplatesLoaded">
            <p>No templates loaded.</p>
            <button @click="onLoadTemplates" class="btn-load">Load Config</button>
          </div>
          <TemplateLibrary ref="templateLibraryRef" @template-apply="onTemplateApplied" @template-edit="onTemplateEdit" @template-delete="onTemplateDelete" />
        </CollapsibleSection>

        <CollapsibleSection :expanded="sections.waypointTemplates" @update:expanded="sections.waypointTemplates = $event" title="Waypoint Templates">
          <div class="section-load-hint" v-if="templatesStore.waypointTemplates.length === 0">
            <p>No waypoint templates loaded.</p>
            <button @click="onLoadWaypointTemplates" class="btn-load">Load Config</button>
          </div>
          <WaypointTemplateLibrary @waypoint-template-apply="onWaypointTemplateApplied" @waypoint-template-edit="onWaypointTemplateEdit" @waypoint-template-delete="onWaypointTemplateDelete" />
        </CollapsibleSection>
      </aside>

      <main class="main-content">
        <div class="main-editor">
          <!-- Reference Point Editor - shown when editing a reference point -->
          <ReferencePointDetailEditor
            v-if="editingReferencePoint"
            :key="editingReferencePoint.name || editingReferencePoint.type || Date.now()"
            ref="referencePointDetailEditorRef"
            :refpoint="editingReferencePoint"
            @save="onReferencePointDetailSave"
            @cancel="editingReferencePoint = null"
          />
          <!-- DEBUG: Log what we're passing -->
          <!-- <div v-if="editingReferencePoint" style="position: fixed; top: 0; left: 0; background: yellow; padding: 10px; z-index: 9999;">
            Passing to Editor: {{ JSON.stringify(editingReferencePoint) }}
          </div> -->

          <!-- Template Editor - shown when editing a template -->
          <TemplateEditor
            v-else-if="editingTemplate"
            ref="templateEditorRef"
            :editingTemplate="editingTemplate"
            @template-change="onTemplateChange"
            @save="onTemplateSave"
            @cancel="onTemplateCancel"
          />

          <!-- Waypoint Template Editor - shown when editing a waypoint template -->
          <WaypointTemplateEditor
            v-else-if="editingWaypointTemplate"
            ref="waypointTemplateEditorRef"
            :waypoints="editingWaypointTemplate.waypoints || []"
            :airbases="refpointsStore.airbases"
            @save="onWaypointTemplateSave"
            @cancel="editingWaypointTemplate = null"
          />

          <!-- Group Editor - shown when editing a group -->
          <GroupEditor
            v-else-if="selectedGroupIndex !== null"
            ref="groupEditorRef"
            :group="groups[selectedGroupIndex]"
            :groups="groups"
            @group-change="onGroupEditorChange"
            @cancel="selectedGroupIndex = null"
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
import { ref, computed, onMounted, watch, nextTick } from 'vue'
import { useRefpointsStore } from './stores/refpoints'
import { useTemplatesStore } from './stores/templates'
import ReferencePointManager from './components/refpoints/ReferencePointManager.vue'
import TemplateLibrary from './components/templates/TemplateLibrary.vue'
import TemplateEditor from './components/templates/TemplateEditor.vue'
import WaypointTemplateLibrary from './components/templates/WaypointTemplateLibrary.vue'
import WaypointTemplateEditor from './components/templates/WaypointTemplateEditor.vue'
import GroupManager from './components/groups/GroupManager.vue'
import GroupEditor from './components/groups/GroupEditor.vue'
import WaypointEditor from './components/editor/WaypointEditor.vue'
import ReferencePointDetailEditor from './components/refpoints/ReferencePointDetailEditor.vue'
import CollapsibleSection from './components/CollapsibleSection.vue'
import { useResize } from './composables/useResize'

// Stores
const refpointsStore = useRefpointsStore()
const templatesStore = useTemplatesStore()

// Refs for component access
const refpointManagerRef = ref(null)
const referencePointDetailEditorRef = ref(null)
const templateLibraryRef = ref(null)
const waypointTemplateLibraryRef = ref(null)
const groupManagerRef = ref(null)
const templateEditorRef = ref(null)
const waypointTemplateEditorRef = ref(null)
const groupEditorRef = ref(null)

// Track selected group index and editing template
const selectedGroupIndex = ref(null)
const editingReferencePoint = ref(null)
const editingTemplate = ref(null)
const editingWaypointTemplate = ref(null)

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
    // Close the group editor if it's open to prevent watcher conflicts
    selectedGroupIndex.value = null
    groupManagerRef.value?.setSyncing(true)
    await nextTick()

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
  } finally {
    groupManagerRef.value?.setSyncing(false)
  }
}

const onNewMission = () => {
  // Ask for confirmation before clearing all data
  if (!window.confirm('Are you sure you want to create a new mission? This will delete all groups, reference points, and templates.')) {
    return
  }

  // Close any open editors
  selectedGroupIndex.value = null
  editingReferencePoint.value = null
  editingTemplate.value = null
  editingWaypointTemplate.value = null

  // Clear all store data
  refpointsStore.clear()
  templatesStore.clear()

  // Clear groups
  groups.value = []

  // Reset sidebar sections
  sections.value = {
    groups: true,
    referencePoints: false,
    templates: false,
    waypointTemplates: false
  }

  setStatus('New mission created', 'success')
}

const onExportJson = () => {
  window.api?.export?.json?.()
}

const onExportLua = () => {
  window.api?.export?.lua?.()
}

// Group handlers
const onGroupChange = (newGroups) => {
  // Prevent infinite loop - only update if groups actually changed
  const oldLength = groups.value.length
  const newLength = newGroups.length
  if (oldLength !== newLength) {
    groups.value = newGroups
  } else {
    // Check if arrays are different by comparing group names
    const oldNames = groups.value.map(g => g.groupName).sort().join('|')
    const newNames = newGroups.map(g => g.groupName).sort().join('|')
    if (oldNames !== newNames) {
      groups.value = newGroups
    }
  }
}

const onGroupEdit = (group) => {
  // Find the group index and open the editor
  selectedGroupIndex.value = groups.value.findIndex(g => g.groupName === group.groupName)
}

const onGroupEditorChange = (updatedGroup) => {
  // GroupEditor emits a single updated group
  if (selectedGroupIndex.value !== null) {
    const currentGroup = groups.value[selectedGroupIndex.value]
    // Only update if the group actually changed (not just a reference change)
    if (currentGroup && currentGroup.groupName !== updatedGroup.groupName) {
      const newGroups = [...groups.value]
      newGroups[selectedGroupIndex.value] = updatedGroup
      groups.value = newGroups
    }
  }
}

// Reference Point handlers
const onReferencePointSelected = (refPoint) => {
  // payload = { refPoint }
  editingReferencePoint.value = { ...refPoint }
  setStatus(`Editing reference point: "${refPoint.name}"`, 'info')
}

const onReferencePointEdit = (refPoint) => {
  // Edit button clicked - set the reference point for editing
  const refPointCopy = { ...refPoint }
  editingReferencePoint.value = refPointCopy
  setStatus(`Editing reference point: "${refPoint.name}"`, 'info')
}

// Watch for editingReferencePoint changes

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
  editingReferencePoint.value = null // Close reference point editor if open
  editingTemplate.value = template
  setStatus(`Editing template: "${template.name}"`, 'info')
}

// Status helper
const setStatus = (message, type = 'info') => {
  status.value = { message, type }
  setTimeout(() => {
    status.value = { message: '', type: 'info' }
  }, 3000)
}

// Initialize - no automatic loading
onMounted(() => {
  // Resources are not loaded automatically
  // User can click "Load Sample Data" or "Load Config" buttons to load data
})

// Load config handlers - explicit user action to load data
const onLoadReferencePoints = () => {
  window.api?.refpoints?.load?.().then(config => {
    if (config) {
      refpointsStore.loadFromConfig(config)
      setStatus('Reference points loaded from config', 'success')
    } else {
      setStatus('No reference point config found', 'info')
    }
  })
}

const onLoadTemplates = () => {
  window.api?.templates?.loadAll?.().then(templates => {
    if (templates && Object.keys(templates).length > 0) {
      templatesStore.loadTemplates(templates)
      setStatus('Templates loaded from config', 'success')
    } else {
      setStatus('No templates found in config', 'info')
    }
  })
}

const onLoadWaypointTemplates = () => {
  window.api?.templates?.loadAll?.().then(templates => {
    if (templates && templates.waypoint_templates) {
      templatesStore.loadWaypointTemplates(templates.waypoint_templates)
      setStatus('Waypoint templates loaded from config', 'success')
    } else {
      setStatus('No waypoint templates found in config', 'info')
    }
  })
}

// Computed - check if any templates are loaded
const hasTemplatesLoaded = computed(() => {
  return Object.values(templatesStore.categories).some(arr => arr.length > 0)
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

const onWaypointTemplateEdit = (template) => {
  // Set the template as being edited - WaypointTemplateEditor will show it
  editingReferencePoint.value = null // Close reference point editor if open
  editingWaypointTemplate.value = { ...template }
  setStatus(`Editing waypoint template: "${template.name}"`, 'info')
}

const onReferencePointDetailSave = (refPoint) => {
  // Called when ReferencePointDetailEditor saves changes
  updateRefPointInStore(refPoint)
  editingReferencePoint.value = null
  setStatus(`Reference point "${refPoint.name}" saved`, 'success')
}

const onReferencePointDelete = (refPoint) => {
  // Delete reference point from store
  const type = refPoint.type
  const name = refPoint.name

  if (type === 'bullseye') {
    const index = refpointsStore.bullseyes.findIndex(b => b.name === name)
    if (index !== -1) {
      refpointsStore.bullseyes.splice(index, 1)
      setStatus(`Bullseye "${name}" deleted`, 'info')
    }
  } else if (type === 'airbase') {
    const index = refpointsStore.airbases.findIndex(a => a.name === name)
    if (index !== -1) {
      refpointsStore.airbases.splice(index, 1)
      setStatus(`Airbase "${name}" deleted`, 'info')
    }
  } else if (type === 'zone') {
    const index = refpointsStore.zones.findIndex(z => z.name === name)
    if (index !== -1) {
      refpointsStore.zones.splice(index, 1)
      setStatus(`Zone "${name}" deleted`, 'info')
    }
  } else if (type === 'battle_line') {
    const index = refpointsStore.lines.findIndex(l => l.name === name)
    if (index !== -1) {
      refpointsStore.lines.splice(index, 1)
      setStatus(`Battle line "${name}" deleted`, 'info')
    }
  }
}

const onTemplateCancel = () => {
  editingTemplate.value = null
}

const updateRefPointInStore = (refPoint) => {
  const type = refPoint.type
  const name = refPoint.name

  if (type === 'bullseye') {
    const index = refpointsStore.bullseyes.findIndex(b => b.name === name)
    if (index !== -1) {
      refpointsStore.bullseyes.splice(index, 1, { name })
    }
  } else if (type === 'airbase') {
    const index = refpointsStore.airbases.findIndex(a => a.name === name)
    if (index !== -1) {
      refpointsStore.airbases.splice(index, 1, { name })
    }
  } else if (type === 'zone') {
    const index = refpointsStore.zones.findIndex(z => z.name === name)
    if (index !== -1) {
      refpointsStore.zones.splice(index, 1, { name })
    }
  } else if (type === 'battle_line') {
    const index = refpointsStore.lines.findIndex(l => l.name === name)
    if (index !== -1) {
      refpointsStore.lines.splice(index, 1, {
        name,
        startX: refPoint.startX || 0,
        startY: refPoint.startY || 0,
        endX: refPoint.endX || 0,
        endY: refPoint.endY || 0
      })
    }
  }
}

const onWaypointTemplateSave = (waypoints) => {
  // Find and update the waypoint template in the store
  const index = templatesStore.waypointTemplates.findIndex(t => t.id === editingWaypointTemplate.value.id)
  if (index !== -1) {
    templatesStore.waypointTemplates[index].waypoints = waypoints
    setStatus(`Waypoint template "${editingWaypointTemplate.value.name}" saved`, 'success')
    editingWaypointTemplate.value = null
  }
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
  width: 320px;
  flex: 1;
  min-height: 0;
  height: 100%;
  background: var(--color-bg-1);
  border-right: 1px solid var(--color-border);
  padding: var(--spacing-lg);
  overflow-y: auto;
  overflow-x: hidden;
  position: relative;
  display: flex;
  flex-direction: column;
  gap: var(--spacing-lg);
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

/* Custom Scrollbar Styles for Sidebar */
.sidebar::-webkit-scrollbar {
  width: 8px;
}

.sidebar::-webkit-scrollbar-track {
  background: var(--color-bg-1);
}

.sidebar::-webkit-scrollbar-thumb {
  background: var(--color-bg-3);
  border-radius: var(--spacing-xxs);
}

.sidebar::-webkit-scrollbar-thumb:hover {
  background: var(--color-text-2);
}

.sidebar::-webkit-scrollbar-corner {
  background: var(--color-bg-1);
}

/* Section Load Hint - shown when no data is loaded */
.section-load-hint {
  background: var(--color-bg-2);
  padding: var(--spacing-sm) var(--spacing-md);
  border-radius: var(--spacing-xxs);
  margin-bottom: var(--spacing-md);
  border: 1px solid var(--color-border);
  text-align: center;
}

.section-load-hint p {
  font-size: var(--font-size-sm);
  color: var(--color-text-1);
  margin: 0 0 var(--spacing-sm) 0;
}

.section-load-hint .btn-load {
  background: var(--color-primary);
  color: white;
  border: none;
  padding: var(--spacing-xs) var(--spacing-md);
  border-radius: var(--spacing-xxs);
  cursor: pointer;
  font-size: var(--font-size-xs);
}

.section-load-hint .btn-load:hover {
  background: var(--color-primary-hover);
}
</style>
