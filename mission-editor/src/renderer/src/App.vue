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
        <CollapsibleSection v-model:expanded="sections.referencePoints" title="Reference Points">
          <ReferencePointManager ref="refpointManagerRef" />
        </CollapsibleSection>

        <CollapsibleSection v-model:expanded="sections.templates" title="Templates" style="margin-top: 20px;">
          <TemplateLibrary ref="templateLibraryRef" @template-apply="onTemplateApplied" />
        </CollapsibleSection>

        <CollapsibleSection v-model:expanded="sections.waypointTemplates" title="Waypoint Templates" style="margin-top: 20px;">
          <WaypointTemplateLibrary @waypoint-template-apply="onWaypointTemplateApplied" />
        </CollapsibleSection>
      </aside>

      <main class="main-content">
        <div class="content-tabs">
          <button
            class="tab-btn"
            :class="{ active: activeTab === 'groups' }"
            @click="activeTab = 'groups'"
          >
            Groups
          </button>
          <button
            class="tab-btn"
            :class="{ active: activeTab === 'waypoints' }"
            @click="activeTab = 'waypoints'"
          >
            Waypoints
          </button>
        </div>

        <!-- Fixed divider - not resizeable -->
        <div class="content-divider"></div>

        <div class="tab-content">
          <div v-if="activeTab === 'groups'" class="group-content-layout">
            <GroupManager
              ref="groupManagerRef"
              :groups="groups"
              :templates="templatesStore.categories"
              @group-change="onGroupChange"
              @group-delete="onGroupDelete"
              @group-select="onGroupSelected"
            />
          </div>

          <div v-if="activeTab === 'waypoints'" class="waypoint-content-layout">
            <WaypointEditor v-model:waypoints="waypoints" />
            <div v-if="waypoints.length > 0" class="waypoint-count">
              <p>Waypoints: {{ waypoints.length }} total</p>
            </div>
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
import { ref, onMounted, watch } from 'vue'
import { useRefpointsStore } from './stores/refpoints'
import { useTemplatesStore } from './stores/templates'
import ReferencePointManager from './components/refpoints/ReferencePointManager.vue'
import TemplateLibrary from './components/templates/TemplateLibrary.vue'
import WaypointTemplateLibrary from './components/templates/WaypointTemplateLibrary.vue'
import GroupManager from './components/groups/GroupManager.vue'
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

// Track selected group index for waypoint template application
const selectedGroupIndex = ref(null)

// Tab state
const activeTab = ref('groups')

// Sidebar sections state - all collapsed by default
const sections = ref({
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

const onGroupDelete = (newGroups) => {
  groups.value = newGroups
}

// Template handlers
const onTemplateApplied = (template) => {
  // Create a new group from template
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
  overflow: hidden;
}

.sidebar {
  flex: 0 0 auto;
  width: 320px;
  height: 100%;
  background: var(--color-bg-1);
  border-right: 1px solid var(--color-border);
  padding: var(--spacing-lg);
  overflow-y: auto;
  position: relative;
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
  padding: var(--spacing-xl);
  overflow: hidden;
  background: var(--color-bg-0);
  display: flex;
  flex-direction: column;
}

.main-content h2 {
  font-size: var(--font-size-xl);
  color: var(--color-text-4);
  margin-bottom: var(--spacing-md);
}

/* Fixed divider between tabs and content */
.content-divider {
  height: 6px;
  background: var(--color-border);
  cursor: default;
  flex: 0 0 auto;
}

.tab-content {
  overflow: hidden;
  flex: 1;
  position: relative;
  display: flex;
  flex-direction: column;
}

/* Content layout wrappers for groups and waypoints */
.group-content-layout,
.waypoint-content-layout {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  overflow: hidden;
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
</style>
