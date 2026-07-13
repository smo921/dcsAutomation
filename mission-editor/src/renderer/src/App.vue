<template>
  <div class="app">
    <header class="app-header">
      <h1>DCS Mission Editor</h1>
      <nav class="header-nav">
        <Button @click="onNewMission" variant="primary">New Mission</Button>
        <Button @click="onLoadSample" variant="primary">Load Sample Data</Button>
        <Button @click="onLoadJson" variant="primary">Load JSON</Button>
        <Button @click="onExportJson" variant="primary">Export JSON</Button>
        <Button @click="onExportLua" variant="primary">Export Lua</Button>
      </nav>
    </header>

    <div class="app-content">
      <aside class="sidebar" :style="{ width: sidebarWidth + 'px' }" @mousedown="startSidebarResize">
        <CollapsibleSection :expanded="sections.units" @update:expanded="sections.units = $event" title="Units">
          <UnitManager
            ref="unitManagerRef"
            :units="units"
            listOnly
            @unit-change="onUnitChange"
            @unit-edit="onUnitEdit"
            @unit-add-from-template="onUnitAddFromTemplate"
          />
        </CollapsibleSection>

        <CollapsibleSection :expanded="sections.referencePoints" @update:expanded="sections.referencePoints = $event" title="Reference Points">
          <div class="section-load-hint" v-if="refpointsStore.bullseyes.length === 0 && refpointsStore.airbases.length === 0 && refpointsStore.zones.length === 0 && refpointsStore.lines.length === 0">
            <p>No reference points loaded.</p>
            <Button @click="onAddReferencePoints" variant="primary" size="sm">Add Reference Point(s)...</Button>
          </div>
          <div v-else class="section-controls">
            <Button @click="onClearReferencePoints" variant="danger" size="sm">Clear All</Button>
          </div>
          <ReferencePointManager ref="refpointManagerRef" :list-only="true" @select="onReferencePointSelected" @refpoint-edit="onReferencePointEdit" @refpoint-delete="onReferencePointDelete" />
        </CollapsibleSection>

        <CollapsibleSection :expanded="sections.unitTemplates" @update:expanded="sections.unitTemplates = $event" title="Unit Templates">
          <div class="section-load-hint" v-if="!hasUnitTemplatesLoaded">
            <p>No unit templates loaded.</p>
            <Button @click="onAddUnitTemplates" variant="primary" size="sm">Add Unit Template(s)...</Button>
          </div>
          <div v-else class="section-controls">
            <Button @click="onClearUnitTemplates" variant="danger" size="sm">Clear All</Button>
          </div>
          <UnitTemplateLibrary ref="unitTemplateLibraryRef" @unit-template-apply="onUnitTemplateApplied" @unit-template-edit="onUnitTemplateEdit" @unit-template-delete="onUnitTemplateDelete" />
        </CollapsibleSection>

        <CollapsibleSection :expanded="sections.routeTemplates" @update:expanded="sections.routeTemplates = $event" title="Route Templates">
          <div class="section-load-hint" v-if="routeTemplatesStore.templates.length === 0">
            <p>No route templates loaded.</p>
            <Button @click="onAddRouteTemplates" variant="primary" size="sm">Add Route Template(s)...</Button>
          </div>
          <div v-else class="section-controls">
            <Button @click="onClearRouteTemplates" variant="danger" size="sm">Clear All</Button>
          </div>
          <RouteTemplateLibrary @route-template-apply="onRouteTemplateApplied" @route-template-edit="onRouteTemplateEdit" @route-template-delete="onRouteTemplateDelete" />
        </CollapsibleSection>
      </aside>

      <main class="main-content">
        <div class="main-editor">
          <!-- Reference Point Editor - shown when editing a reference point -->
          <ReferencePointDetailEditor
            v-if="editingReferencePoint"
            :key="editingReferencePoint.name || editingReferencePoint.type || Date.now()"
            ref="referencePointDetailEditorRef"
            :ref-point="editingReferencePoint"
            @save="onReferencePointDetailSave"
            @cancel="editingReferencePoint = null"
          />
          <!-- DEBUG: Log what we're passing -->
          <!-- <div v-if="editingReferencePoint" style="position: fixed; top: 0; left: 0; background: yellow; padding: 10px; z-index: 9999;">
            Passing to Editor: {{ JSON.stringify(editingReferencePoint) }}
          </div> -->

          <!-- Unit Template Editor - shown when editing a unit template -->
          <UnitTemplateEditor
            v-else-if="editingUnitTemplate"
            ref="unitTemplateEditorRef"
            :editingTemplate="editingUnitTemplate"
            @unit-template-change="onUnitTemplateChange"
            @save="onUnitTemplateSave"
            @cancel="onUnitTemplateCancel"
          />

          <!-- Route Template Editor - shown when editing a route template -->
          <RouteTemplateEditor
            v-else-if="editingRouteTemplate"
            :key="editingRouteTemplate.id || editingRouteTemplate.name"
            ref="routeTemplateEditorRef"
            :route="editingRouteTemplate.route || []"
            :airbases="refpointsStore.airbases"
            :template-name="editingRouteTemplate.name || editingRouteTemplate.id"
            @update:template-name="editingRouteTemplate.name = $event"
            @save="onRouteTemplateSave"
            @cancel="editingRouteTemplate = null"
          />

          <!-- Unit Editor - shown when editing a unit -->
          <UnitEditor
            v-else-if="selectedUnitIndex !== null"
            ref="unitEditorRef"
            :unit="units[selectedUnitIndex]"
            :units="units"
            :refpoints="{ bullseyes: refpointsStore.bullseyes, airbases: refpointsStore.airbases, zones: refpointsStore.zones, lines: refpointsStore.lines }"
            @unit-change="onUnitEditorChange"
            @cancel="selectedUnitIndex = null"
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
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { useRefpointsStore } from './stores/refpoints'
import { useUnitTemplatesStore } from './stores/unitTemplates'
import { useRouteTemplatesStore } from './stores/routeTemplates'
import ReferencePointManager from './components/refpoints/ReferencePointManager.vue'
import UnitTemplateLibrary from './components/unitTemplates/UnitTemplateLibrary.vue'
import UnitTemplateEditor from './components/unitTemplates/UnitTemplateEditor.vue'
import RouteTemplateLibrary from './components/routeTemplates/RouteTemplateLibrary.vue'
import RouteTemplateEditor from './components/routeTemplates/RouteTemplateEditor.vue'
import UnitManager from './components/units/UnitManager.vue'
import UnitEditor from './components/units/UnitEditor.vue'
import ReferencePointDetailEditor from './components/refpoints/ReferencePointDetailEditor.vue'
import CollapsibleSection from './components/CollapsibleSection.vue'
import { useResize } from './composables/useResize'
import { Button } from './components/ui'
import { generateLuaFromUnits as generateLua, generateRefpointsSection } from './lua/generator'

// Stores
const refpointsStore = useRefpointsStore()
const unitTemplatesStore = useUnitTemplatesStore()
const routeTemplatesStore = useRouteTemplatesStore()

// Refs for component access
const refpointManagerRef = ref(null)
const referencePointDetailEditorRef = ref(null)
const unitTemplateLibraryRef = ref(null)
const routeTemplateLibraryRef = ref(null)
const unitManagerRef = ref(null)
const unitTemplateEditorRef = ref(null)
const routeTemplateEditorRef = ref(null)
const unitEditorRef = ref(null)

// Track selected unit index and editing template
const selectedUnitIndex = ref(null)
const editingReferencePoint = ref(null)
const editingUnitTemplate = ref(null)
const editingRouteTemplate = ref(null)

// Store original descriptions for export preservation
const originalRefpointDescriptions = ref({
  bullseyes: {},
  zones: {},
  airbases: {}
})

// Sidebar sections state - units expanded by default
const sections = ref({
  units: true,
  referencePoints: false,
  unitTemplates: false,
  routeTemplates: false
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

// Units state
const units = ref([])

// Waypoints state (for standalone editing)
const waypoints = ref([])

// Status tracking
const status = ref({ message: '', type: 'info' })

// Shared config loading helper
const loadConfig = async (loadFn, successMessage) => {
  try {
    // Close the unit editor if it's open to prevent watcher conflicts
    selectedUnitIndex.value = null
    unitManagerRef.value?.setSyncing(true)
    await nextTick()

    const result = await loadFn()

    if (result?.success) {
      // Clear existing data and load config
      refpointsStore.clear()
      unitTemplatesStore.clear()
      routeTemplatesStore.clear()
      refpointsStore.loadFromFullConfig(result.config)
      unitTemplatesStore.loadFromFullConfig(result.config)
      routeTemplatesStore.loadFromFullConfig(result.config)

      // Load units if available (sample data uses 'groups', newer configs might use 'units')
      if (result.config.units) {
        units.value = result.config.units
      } else if (result.config.groups) {
        units.value = result.config.groups
      }

      setStatus(successMessage, 'success')
    } else {
      setStatus(`Failed to load: ${result?.error || 'Unknown error'}`, 'error')
    }
  } catch (e) {
    setStatus(`Error loading: ${e.message}`, 'error')
  } finally {
    unitManagerRef.value?.setSyncing(false)
  }
}

// Menu handlers - Add Unit Template(s) and Load Sample handlers
const onLoadJson = () => loadConfig(window.api?.config?.loadJson, 'Configuration loaded successfully')

const onLoadSample = () => loadConfig(window.api?.config?.loadSample, 'Sample data loaded successfully')

const onAddUnitTemplates = async () => {
  try {
    selectedUnitIndex.value = null
    unitManagerRef.value?.setSyncing(true)
    await nextTick()

    const result = await window.api?.unitTemplates?.loadFromFiles?.()
    if (result?.success) {
      if (result.unitTemplates) {
        unitTemplatesStore.loadTemplates(result.unitTemplates)
      }
      setStatus('Unit templates loaded successfully', 'success')
    } else {
      setStatus(`Failed to load unit templates: ${result?.error || 'Unknown error'}`, 'error')
    }
  } catch (e) {
    setStatus(`Error loading unit templates: ${e.message}`, 'error')
  } finally {
    unitManagerRef.value?.setSyncing(false)
  }
}

const onAddReferencePoints = async () => {
  try {
    selectedUnitIndex.value = null
    unitManagerRef.value?.setSyncing(true)
    await nextTick()

    const result = await window.api?.refpoints?.loadFromFile?.()
    if (result?.success) {
      refpointsStore.loadFromFullConfig({ refpoints: result.refpoints })
      setStatus('Reference points loaded successfully', 'success')
    } else {
      setStatus(`Failed to load reference points: ${result?.error || 'Unknown error'}`, 'error')
    }
  } catch (e) {
    setStatus(`Error loading reference points: ${e.message}`, 'error')
  } finally {
    unitManagerRef.value?.setSyncing(false)
  }
}

const onAddRouteTemplates = async () => {
  try {
    selectedUnitIndex.value = null
    await nextTick()

    const result = await window.api?.routeTemplates?.loadFromFiles?.()
    if (result?.success) {
      if (result.routeTemplates) {
        routeTemplatesStore.loadRouteTemplates(result.routeTemplates)
      }
      setStatus('Route templates loaded successfully', 'success')
    } else {
      setStatus(`Failed to load route templates: ${result?.error || 'Unknown error'}`, 'error')
    }
  } catch (e) {
    setStatus(`Error loading route templates: ${e.message}`, 'error')
  }
}

const onClearReferencePoints = () => {
  refpointsStore.clear()
  setStatus('All reference points cleared', 'success')
}

const onClearUnitTemplates = () => {
  unitTemplatesStore.clear()
  setStatus('All unit templates cleared', 'success')
}

const onClearRouteTemplates = () => {
  routeTemplatesStore.clear()
  setStatus('All route templates cleared', 'success')
}

// Computed - check if any unit templates are loaded
const hasUnitTemplatesLoaded = computed(() => {
  return Object.values(unitTemplatesStore.categories).some(arr => arr.length > 0)
})

const onNewMission = () => {
  // Ask for confirmation before clearing all data
  if (!window.confirm('Are you sure you want to create a new mission? This will delete all units, reference points, and templates.')) {
    return
  }

  // Close any open editors
  selectedUnitIndex.value = null
  editingReferencePoint.value = null
  editingUnitTemplate.value = null
  editingRouteTemplate.value = null

  // Clear all store data
  refpointsStore.clear()
  unitTemplatesStore.clear()
  routeTemplatesStore.clear()

  // Clear units
  units.value = []

  // Reset sidebar sections
  sections.value = {
    units: true,
    referencePoints: false,
    unitTemplates: false,
    routeTemplates: false
  }

  setStatus('New mission created', 'success')
}

const onExportJson = async () => {
  try {
    // Generate the complete configuration object in the original format
    const config = {
      refpoints: {
        bullseyes: refpointsStore.bullseyes.map(b => ({
          name: b.name,
          description: b.description
        })).filter(b => b.description !== undefined),
        zones: refpointsStore.zones.map(z => ({
          name: z.name,
          description: z.description
        })).filter(z => z.description !== undefined),
        airbases: refpointsStore.airbases.map(a => ({
          name: a.name,
          description: a.description
        })).filter(a => a.description !== undefined)
      },
      route_templates: routeTemplatesStore.templates.reduce((acc, template) => {
        // Convert to the original format
        acc[template.id] = {
          name: template.name,
          route: template.route || []
        };
        return acc;
      }, {}),
      unit_templates: {
        air: (unitTemplatesStore.categories.air || []).map(template => ({
          id: template.id,
          name: template.name,
          units: template.units || [],
          ...(template.routeTemplate && { routeTemplate: template.routeTemplate })
        })),
        ground: (unitTemplatesStore.categories.ground || []).map(template => ({
          id: template.id,
          name: template.name,
          units: template.units || [],
          ...(template.routeTemplate && { routeTemplate: template.routeTemplate })
        })),
        naval: (unitTemplatesStore.categories.naval || []).map(template => ({
          id: template.id,
          name: template.name,
          units: template.units || [],
          ...(template.routeTemplate && { routeTemplate: template.routeTemplate })
        })),
        support: (unitTemplatesStore.categories.support || []).map(template => ({
          id: template.id,
          name: template.name,
          units: template.units || [],
          ...(template.routeTemplate && { routeTemplate: template.routeTemplate })
        }))
      },
      units: units.value
    };

    // Convert to JSON string with indentation
    const jsonContent = JSON.stringify(config, null, 2);

    // Save the JSON file using the existing file save API
    const result = await window.api?.file?.saveJson?.(jsonContent, 'mission-config.json');
    if (result?.success) {
      setStatus('Configuration exported to JSON successfully', 'success');
    } else {
      setStatus('Failed to export configuration to JSON', 'error');
    }
  } catch (error) {
    console.error('Error exporting JSON:', error);
    setStatus(`Error exporting JSON: ${error.message}`, 'error');
  }
}

const onExportLua = () => {
  // Generate Lua code from units using the shared generator module
  // Pass templates from stores to ensure they are expanded in the final Lua manifest
  const allUnitTemplates = Object.values(unitTemplatesStore.categories).flat();

  const luaCode = generateLua(units.value, refpointsStore, {
    routeTemplates: routeTemplatesStore.templates,
    unitTemplates: allUnitTemplates
  });
  window.api?.file?.saveLua?.(luaCode, 'mission-config.lua')
}

// Unit handlers
const onUnitChange = (newUnits) => {
  // Prevent infinite loop - only update if units actually changed
  const oldLength = units.value.length
  const newLength = newUnits.length
  if (oldLength !== newLength) {
    units.value = newUnits
  } else {
    // Check if arrays are different by comparing unit names
    const oldNames = units.value.map(u => u.unitName).sort().join('|')
    const newNames = newUnits.map(u => u.unitName).sort().join('|')
    if (oldNames !== newNames) {
      units.value = newUnits
    }
  }
}

const onUnitEdit = (unit) => {
  // Find the unit index and open the editor
  const index = units.value.findIndex(u => u.unitName === unit.unitName)
  console.log('onUnitEdit called with:', unit.unitName, 'found at index:', index)
  selectedUnitIndex.value = index
}

const onUnitEditorChange = (updatedUnit) => {
  // UnitEditor emits a single updated unit
  if (selectedUnitIndex.value !== null) {
    const currentUnit = units.value[selectedUnitIndex.value]
    // Only update if the unit actually changed (not just a reference change)
    if (currentUnit && currentUnit.unitName !== updatedUnit.unitName) {
      const newUnits = [...units.value]
      newUnits[selectedUnitIndex.value] = updatedUnit
      units.value = newUnits
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

// Unit Template handlers
const onUnitAddFromTemplate = (category) => {
  // Open the Unit Template library to select a template
  // This will be used when we implement a modal or dialog to select templates
  setStatus(`Select a unit template to add`, 'info')
}

const onUnitTemplateApplied = (payload) => {
  // payload = { template, category }
  const { template, category } = payload
  // Create a new unit from template
  const newUnit = {
    unitName: `${template.name.replace(/\s+/g, '_')}_${units.value.length + 1}`,
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
  units.value = [...units.value, newUnit]
  setStatus(`Unit template "${template.name}" applied to new unit`, 'success')
}

const onUnitTemplateEdit = (payload) => {
  // payload = { template, category }
  const { template, category } = payload
  // Set the template as being edited - UnitTemplateEditor will show it
  editingReferencePoint.value = null
  editingUnitTemplate.value = template
  setStatus(`Editing unit template: "${template.name}"`, 'info')
}

const onUnitTemplateDelete = (payload) => {
  // payload = { template, category }
  const { template, category } = payload
  const categoryTemplates = unitTemplatesStore.categories[category] || []
  const templateIndex = categoryTemplates.findIndex(t =>
    (t.id && t.id === template.id) || (!t.id && t.name === template.name)
  )

  if (templateIndex !== -1) {
    unitTemplatesStore.deleteTemplate(category, templateIndex)
    setStatus(`Unit template "${template.name}" deleted`, 'info')
    // Reset editing template if the deleted template was being edited
    if (editingUnitTemplate.value && editingUnitTemplate.value.name === template.name) {
      editingUnitTemplate.value = null
    }
  }
}

const onUnitTemplateChange = (template) => {
  // Called when a unit template is saved in the editor
  onUnitTemplateSave(template)
}

const onUnitTemplateSave = (template) => {
  const category = template.category || 'air'
  const existingCategory = unitTemplatesStore.categories[category] || []

  // Check for duplicate ID or name
  const existingIndex = existingCategory.findIndex(t =>
    (t.id && t.id === template.id) || (!t.id && t.name === template.name)
  )

  if (existingIndex !== -1) {
    // Update existing template using store method
    unitTemplatesStore.updateTemplate(category, existingIndex, template)
    setStatus(`Unit template "${template.name}" updated`, 'success')
  } else {
    // Add new template using store method
    unitTemplatesStore.addTemplate(category, template)
    setStatus(`Unit template "${template.name}" created`, 'success')
  }
}

const onUnitTemplateCancel = () => {
  editingUnitTemplate.value = null
}

// Route Template handlers
const onRouteTemplateApplied = (template) => {
  // Check if there's a selected unit to apply the template to
  if (selectedUnitIndex.value !== null && selectedUnitIndex.value !== undefined) {
    const unit = units.value[selectedUnitIndex.value]
    if (unit) {
      // Apply route template to unit route
      unit.route = template.waypoints || []
      units.value = [...units.value] // Trigger reactivity
      setStatus(`Route template "${template.name}" applied to "${unit.unitName}"`, 'success')
      return
    }
  }

  // If no unit selected, create a new unit from the route template
  const newUnit = {
    unitName: `${template.name.replace(/\s+/g, '_')}_${units.value.length + 1}`,
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
  units.value = [...units.value, newUnit]
  setStatus(`Route template "${template.name}" applied to new unit`, 'success')
}

const onRouteTemplateDelete = (template) => {
  // Delete the template from the store
  routeTemplatesStore.deleteTemplateById(template.id)
  setStatus(`Route template "${template.name}" deleted`, 'info')
}

const onRouteTemplateEdit = (template) => {
  // Set the template as being edited - RouteTemplateEditor will show it
  editingReferencePoint.value = null
  editingUnitTemplate.value = null
  selectedUnitIndex.value = null
  editingRouteTemplate.value = { ...template }
  setStatus(`Editing route template: "${template.name}"`, 'info')
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

const onRouteTemplateSave = (route) => {
  // Find and update the route template in the store
  const index = routeTemplatesStore.templates.findIndex(t => t.id === editingRouteTemplate.value.id)
  if (index !== -1) {
    // Update both routes and template name
    routeTemplatesStore.templates[index].route = route
    if (editingRouteTemplate.value.name) {
      routeTemplatesStore.templates[index].name = editingRouteTemplate.value.name
    }
    setStatus(`Route template "${editingRouteTemplate.value.name}" saved`, 'success')
    editingRouteTemplate.value = null
  }
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

  // Add listener for menu export JSON event
  const removeJsonListener = window.api?.export?.onJson?.(onExportJson)

  // Add listener for menu export Lua event
  const removeLuaListener = window.api?.export?.onLua?.(onExportLua)

  // Clean up listeners on unmount
  onUnmounted(() => {
    if (removeJsonListener) removeJsonListener()
    if (removeLuaListener) removeLuaListener()
  })
})
</script>

<!-- Global styles (applied to entire app) -->
<style>
/* CSS Reset & Base Styles */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: var(--font-family);
  background: var(--color-bg-0);
  color: var(--color-text-0);
  overflow: hidden;
}

/* Focus styles for accessibility */
:focus {
  outline: 2px solid var(--color-border-focus);
  outline-offset: 2px;
}
</style>

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

/* Tab buttons for Units/Waypoints */
.content-tabs {
  display: flex;
  gap: var(--spacing-md);
  margin-bottom: var(--spacing-md);
}

.content-tabs .tab-btn {
  background: var(--color-bg-2);
  color: var(--color-text-0);
  border: 1px solid var(--color-border);
  padding: var(--spacing-sm) var(--spacing-lg);
  border-radius: var(--spacing-xxs);
  cursor: pointer;
  font-size: var(--font-size-md);
  font-weight: var(--font-weight-medium);
  transition: all var(--transition-normal);
}

.content-tabs .tab-btn:hover {
  background: var(--color-bg-3);
}

.content-tabs .tab-btn.active {
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

/* Content layout wrappers for units and waypoints */
.unit-content-layout,
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

/* Section controls (Clear All button) */
.section-controls {
  margin-bottom: var(--spacing-md);
  text-align: center;
}

.section-controls .btn {
  display: inline-block;
}
</style>
