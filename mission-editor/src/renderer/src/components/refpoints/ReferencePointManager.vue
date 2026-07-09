<template>
  <div class="refpoint-manager list-container">
    <!-- Category Tabs -->
    <div class="category-tabs">
      <button
        v-for="category in categories"
        :key="category"
        :class="['tab-btn', { active: activeCategory === category }]"
        @click="activeCategory = category"
      >
        {{ getCategoryLabelForTab(category) }}
      </button>
    </div>

    <!-- Scrollable Reference Point List -->
    <div class="list-scroll list-scroll-fixed-height">
      <div class="list-container">
        <div
          v-for="refPoint in getRefPointsByCategory"
          :key="refPoint.name"
          class="list-item"
          :class="{ active: selectedRefPoint && selectedRefPoint.name === refPoint.name && selectedRefPoint.type === refPoint.type }"
        >
          <div class="list-item-content">
            <h4 class="list-item-header">{{ refPoint.name }}</h4>
            <span class="list-item-meta">{{ getCategoryLabel(refPoint.type) }}</span>
          </div>
          <div class="list-item-actions">
            <Button variant="primary" size="sm" @click.stop="onEditRefPoint(refPoint)" title="Edit Reference Point">
              Edit
            </Button>
            <Button variant="danger" size="sm" @click.stop="onDeleteRefPoint(refPoint)" title="Delete Reference Point"><span class="btn-remove-icon">Delete</span></Button>
          </div>
        </div>

        <EmptyState v-if="getRefPointsByCategory.length === 0">
          <p>No {{ activeCategory }} reference points configured.</p>
        </EmptyState>
      </div>
    </div>

    <!-- Resizable Divider -->
    <div v-if="!listOnly" class="content-resizer" @mousedown="startListResize">
      <span class="resizer-line"></span>
    </div>

    <!-- Reference Point Detail Editor -->
    <div v-if="!props.listOnly && selectedRefPoint && currentRefPoint" class="editor-panel">
      <div class="editor-content">
        <!-- Basic Settings -->
        <CollapsiblePanel v-model:expanded="expandedSections.basic" title="Basic Settings">
          <div class="editor-section">
            <FormRow>
              <div class="form-group">
                <FormLabel label="Reference Type" />
                <FormInput
                  v-model="refPointType"
                  disabled
                />
              </div>
            </FormRow>
            <FormRow>
              <div class="form-group">
                <FormLabel label="Name" />
                <FormInput
                  v-model="currentRefPoint.name"
                  placeholder="Enter name..."
                />
              </div>
            </FormRow>
          </div>
        </CollapsiblePanel>

        <!-- Coordinates -->
        <CollapsiblePanel
          v-if="refPointType === 'battle_line'"
          v-model:expanded="expandedSections.coordinates"
          title="Coordinates"
        >
          <div class="editor-section">
            <FormRow>
              <div class="form-group">
                <FormLabel label="Start X" />
                <FormInput
                  v-model="currentRefPoint.startX"
                  type="number"
                />
              </div>
              <div class="form-group">
                <FormLabel label="Start Y" />
                <FormInput
                  v-model="currentRefPoint.startY"
                  type="number"
                />
              </div>
            </FormRow>
            <FormRow>
              <div class="form-group">
                <FormLabel label="End X" />
                <FormInput
                  v-model="currentRefPoint.endX"
                  type="number"
                />
              </div>
              <div class="form-group">
                <FormLabel label="End Y" />
                <FormInput
                  v-model="currentRefPoint.endY"
                  type="number"
                />
              </div>
            </FormRow>
          </div>
        </CollapsiblePanel>

        <!-- Notes -->
        <CollapsiblePanel v-model:expanded="expandedSections.notes" title="Notes">
          <div class="editor-section">
            <div class="info-box">
              <p v-if="refPointType === 'bullseye'">
                <strong>Bullseyes</strong> represent coalition reference points. Coordinates are determined dynamically at runtime from DCS coalition data.
              </p>
              <p v-if="refPointType === 'airbase'">
                <strong>Airbases</strong> reference points for airbase locations. Coordinates are resolved via Airbase.getByName() at runtime.
              </p>
              <p v-if="refPointType === 'zone'">
                <strong>Zones</strong> reference trigger zones defined in the DCS Mission Editor. Enter the exact zone name here to reference it.
              </p>
              <p v-if="refPointType === 'battle_line'">
                <strong>Battle Lines</strong> are linear reference points defined by start and end coordinates. Use these for linear deployment patterns along battle fronts.
              </p>
            </div>
          </div>
        </CollapsiblePanel>
      </div>
    </div>

    <!-- No selection state -->
    <div v-if="!props.listOnly && !selectedRefPoint" class="no-selection">
      <p>Select a reference point to edit</p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { useResize } from '../../composables/useResize'
import { EmptyState, FormLabel, FormInput, FormRow, CollapsiblePanel, Button } from '../ui'

const emit = defineEmits(['update', 'select', 'refpoint-edit', 'refpoint-delete'])

const props = defineProps({
  // When true, only show the list (no editor panel) - used in sidebar
  listOnly: {
    type: Boolean,
    default: false
  }
})

const store = useRefpointsStore()

// Categories for tabs
const categories = ['bullseye', 'airbase', 'zone', 'battle_line']
const activeCategory = ref('bullseye')

// Get category label for display
const getCategoryLabel = (type) => {
  const labelMap = {
    'bullseye': 'Bullseye Reference',
    'airbase': 'Airbase Reference',
    'zone': 'Trigger Zone',
    'battle_line': 'Battle Line'
  }
  return labelMap[type] || type
}

// Get category label from category name (for tabs)
const getCategoryLabelForTab = (category) => {
  const labelMap = {
    'bullseye': 'Bullseye',
    'airbase': 'Airbase',
    'zone': 'Zone',
    'battle_line': 'Battle Line'
  }
  return labelMap[category] || category.charAt(0).toUpperCase() + category.slice(1)
}

const selectedRefPoint = ref(null) // Holds the currently selected reference point object
const currentRefPoint = ref(null) // Working copy for editing
const refPointType = ref('')

// Section expansion state (all expanded by default)
const expandedSections = ref({
  basic: true,
  coordinates: true,
  notes: true
})

// Note: list height is now set via CSS class for consistency across components

// ---- Selection logic ----------------------------------------------------
/**
 * Called when a reference point row is clicked.
 * - Stores the original object in `selectedRefPoint`
 * - Creates an editable copy in `currentRefPoint`
 */
const selectRefPoint = (refPoint) => {
  selectedRefPoint.value   = refPoint
  currentRefPoint.value    = JSON.parse(JSON.stringify(refPoint))
  refPointType.value       = refPoint.type
  emit('select', refPoint)
}

const onEditRefPoint = (refPoint) => {
  emit('refpoint-edit', refPoint)
}

const onDeleteRefPoint = (refPoint) => {
  emit('refpoint-delete', refPoint)
}

// ---- Computed list ---------------------------------------------
const getRefPointsByCategory = computed(() => {
  const mapType = t => ({ ...t, type: activeCategory.value })
  switch (activeCategory.value) {
    case 'bullseye': return store.bullseyes.map(mapType)
    case 'airbase':  return store.airbases.map(mapType)
    case 'zone':     return store.zones.map(mapType)
    case 'battle_line': return store.lines.map(mapType)
    default: return []
  }
})

// ---- Watch for edits ----------------------------------------------------
watch(currentRefPoint, (newVal) => {
  if (!props.listOnly && newVal && selectedRefPoint.value) {
    updateRefPointInStore(newVal)
    emit('update')
  }
}, { deep: true })

</script>

<style scoped>
/* Uses shared classes from _utils.css: tab-btn, content-resizer, resizer-line, no-selection */
/* Uses shared classes from _list-editor.css: list-scroll, list-scroll-fixed-height, list-container */
/* Uses shared classes from _components.css: editor-panel, editor-content, info-box */
</style>
