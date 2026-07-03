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
      <aside class="sidebar">
        <h2>Reference Points</h2>
        <ReferencePointManager ref="refpointManagerRef" />

        <h2 style="margin-top: 20px;">Templates</h2>
        <TemplateLibrary ref="templateLibraryRef" @template-apply="onTemplateApplied" />

        <h2 style="margin-top: 20px;">Groups</h2>
        <GroupManager
          :groups="groups"
          :templates="templatesStore.categories"
          @group-change="onGroupChange"
          @group-delete="onGroupDelete"
        />
      </aside>

      <main class="main-content">
        <h2>Group Configuration</h2>
        <GroupEditor ref="groupEditorRef" />

        <h2 style="margin-top: 20px;">Waypoints</h2>
        <WaypointEditor ref="waypointEditorRef" />
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
import { ref, onMounted } from 'vue'
import { useRefpointsStore } from './stores/refpoints'
import { useTemplatesStore } from './stores/templates'
import ReferencePointManager from './components/refpoints/ReferencePointManager.vue'
import TemplateLibrary from './components/templates/TemplateLibrary.vue'
import GroupManager from './components/groups/GroupManager.vue'
import GroupEditor from './components/editor/GroupEditor.vue'
import WaypointEditor from './components/editor/WaypointEditor.vue'

// Stores
const refpointsStore = useRefpointsStore()
const templatesStore = useTemplatesStore()

// Refs for component access
const refpointManagerRef = ref(null)
const templateLibraryRef = ref(null)
const groupEditorRef = ref(null)
const waypointEditorRef = ref(null)

// Groups state
const groups = ref([])

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
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
  background: #1e1e1e;
  color: #d4d4d4;
  overflow: hidden;
}

.app {
  display: flex;
  flex-direction: column;
  height: 100vh;
}

.app-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 20px;
  background: #252526;
  border-bottom: 1px solid #3e3e42;
}

.app-header h1 {
  font-size: 18px;
  color: #ffffff;
}

.header-nav button {
  background: #0e639c;
  color: white;
  border: none;
  padding: 6px 12px;
  border-radius: 3px;
  cursor: pointer;
  margin-left: 8px;
  font-size: 12px;
}

.header-nav button:hover {
  background: #1177bb;
}

.app-content {
  display: flex;
  flex: 1;
  overflow: hidden;
}

.sidebar {
  width: 320px;
  background: #252526;
  border-right: 1px solid #3e3e42;
  padding: 16px;
  overflow-y: auto;
}

.sidebar h2 {
  font-size: 14px;
  text-transform: uppercase;
  color: #888;
  margin-bottom: 12px;
  padding-bottom: 4px;
  border-bottom: 1px solid #3e3e42;
}

.main-content {
  flex: 1;
  padding: 20px;
  overflow-y: auto;
  background: #1e1e1e;
}

.main-content h2 {
  font-size: 16px;
  color: #ffffff;
  margin-bottom: 12px;
}

.app-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 20px;
  background: #252526;
  border-top: 1px solid #3e3e42;
  font-size: 12px;
}

.status-message {
  padding: 4px 8px;
  border-radius: 3px;
}

.status-message.success {
  background: #1e7a3b;
  color: white;
}

.status-message.error {
  background: #a31313;
  color: white;
}

.status-message.info {
  background: #0e639c;
  color: white;
}

.version {
  color: #888;
}
</style>
