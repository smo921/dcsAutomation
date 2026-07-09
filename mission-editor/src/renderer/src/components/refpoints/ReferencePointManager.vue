<template>
  <div class="refpoint-manager">
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
    <div class="refpoint-list-scroll" :style="{ height: listHeight + 'px' }">
      <div class="refpoint-list">
        <div
          v-for="refPoint in getRefPointsByCategory"
          :key="refPoint.name"
          class="refpoint-item"
          :class="{ active: selectedRefPointName === refPoint.name && selectedRefPointType === refPoint.type }"
        >
          <div class="refpoint-info">
            <h4 class="refpoint-name">{{ refPoint.name }}</h4>
            <span class="refpoint-type">{{ getCategoryLabel(refPoint.type) }}</span>
          </div>
          <div class="list-item-actions">
            <Button variant="primary" size="sm" @click.stop="onEditRefPoint(refPoint)" title="Edit Reference Point">
              Edit
            </Button>
            <button class="btn-remove" @click.stop="onDeleteRefPoint(refPoint)" title="Delete Reference Point"><span class="btn-remove-icon">✕</span></button>
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
    <div v-if="!listOnly && selectedRefPointName && currentRefPoint" class="refpoint-editor-panel">
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
    <div v-if="!listOnly && !selectedRefPointName" class="no-selection">
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

const selectedRefPointName = ref(null)
const selectedRefPointType = ref('')
const currentRefPoint = ref(null)
const refPointType = ref('')

// Section expansion state (all expanded by default)
const expandedSections = ref({
  basic: true,
  coordinates: true,
  notes: true
})

// Use resize composable for list/editor divider
const listHeight = ref(300)
const { startResize: startListResize } = useResize({
  size: listHeight,
  minSize: 100,
  maxSize: 500,
  direction: 'vertical'
})

const selectRefPoint = (refPoint) => {
  selectedRefPointName.value = refPoint.name
  selectedRefPointType.value = refPoint.type
  currentRefPoint.value = JSON.parse(JSON.stringify(refPoint))
  refPointType.value = refPoint.type
  // Emit the selection to the parent
  emit('select', refPoint)
}

const onEditRefPoint = (refPoint) => {
  emit('refpoint-edit', refPoint)
}

const onDeleteRefPoint = (refPoint) => {
  emit('refpoint-delete', refPoint)
}

// Get reference points filtered by active category
const getRefPointsByCategory = computed(() => {
  if (activeCategory.value === 'bullseye') {
    const result = store.bullseyes.map(bp => ({ ...bp, type: 'bullseye' }))
    console.log('getRefPointsByCategory - bullseye:', result)
    return result
  } else if (activeCategory.value === 'airbase') {
    const result = store.airbases.map(ab => ({ ...ab, type: 'airbase' }))
    console.log('getRefPointsByCategory - airbase:', result)
    return result
  } else if (activeCategory.value === 'zone') {
    const result = store.zones.map(z => ({ ...z, type: 'zone' }))
    console.log('getRefPointsByCategory - zone:', result)
    return result
  } else if (activeCategory.value === 'battle_line') {
    const result = store.lines.map(l => ({ ...l, type: 'battle_line' }))
    console.log('getRefPointsByCategory - battle_line:', result)
    return result
  }
  return []
})

// Save changes when currentRefPoint changes (only when not in list-only mode)
watch(currentRefPoint, (newVal) => {
  if (newVal && selectedRefPointName.value && !props.listOnly) {
    updateRefPointInStore(newVal)
    emit('update')
  }
}, { deep: true })

const updateRefPointInStore = (refPoint) => {
  const type = refPoint.type
  const name = refPoint.name

  if (type === 'bullseye') {
    const index = store.bullseyes.findIndex(b => b.name === name)
    if (index !== -1) {
      store.bullseyes.splice(index, 1, { name })
    }
  } else if (type === 'airbase') {
    const index = store.airbases.findIndex(a => a.name === name)
    if (index !== -1) {
      store.airbases.splice(index, 1, { name })
    }
  } else if (type === 'zone') {
    const index = store.zones.findIndex(z => z.name === name)
    if (index !== -1) {
      store.zones.splice(index, 1, { name })
    }
  } else if (type === 'battle_line') {
    const index = store.lines.findIndex(l => l.name === name)
    if (index !== -1) {
      store.lines.splice(index, 1, {
        name,
        startX: refPoint.startX || 0,
        startY: refPoint.startY || 0,
        endX: refPoint.endX || 0,
        endY: refPoint.endY || 0
      })
    }
  }
}
</script>

<style scoped>
/* Shared styles from _components.css: refpoint-manager, refpoint-list-scroll, content-resizer */
/* Shared styles from _components.css: refpoint-editor-panel, editor-content, info-box */
/* Shared styles from _components.css: no-selection */
/* Shared styles from _components.css: refpoint-item, refpoint-info */
/* Shared styles from _components.css: refpoint-name, refpoint-type */
/* Shared styles from _list-editor.css: list-item-actions */

/* Reference Point Manager - flex container for list + editor */
.refpoint-manager {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
}

/* Reference Point List */
.refpoint-list {
  background: var(--color-bg-1);
  border-radius: var(--spacing-xs);
  border: 1px solid var(--color-border);
}

/* Scrollable Reference Point List Container */
.refpoint-list-scroll {
  flex: 0 0 auto;
  overflow-y: auto;
  min-height: 100px;
  margin-bottom: var(--spacing-md);
}

/* Custom Scrollbar Styles for Reference Point List */
.refpoint-list-scroll::-webkit-scrollbar {
  width: 8px;
}

.refpoint-list-scroll::-webkit-scrollbar-track {
  background: var(--color-bg-1);
}

.refpoint-list-scroll::-webkit-scrollbar-thumb {
  background: var(--color-bg-3);
  border-radius: var(--spacing-xxs);
}

.refpoint-list-scroll::-webkit-scrollbar-thumb:hover {
  background: var(--color-text-2);
}

.refpoint-list-scroll::-webkit-scrollbar-corner {
  background: var(--color-bg-1);
}

/* Category Tabs */
.category-tabs {
  display: flex;
  gap: var(--spacing-xs);
  margin-bottom: var(--spacing-md);
}

.tab-btn {
  background: var(--color-bg-2);
  color: var(--color-text-0);
  border: 1px solid var(--color-border);
  padding: var(--spacing-xs) var(--spacing-sm);
  border-radius: var(--spacing-xxs) var(--spacing-xxs) 0 0;
  cursor: pointer;
  font-size: var(--font-size-sm);
  transition: all var(--transition-fast);
}

.tab-btn:hover {
  background: var(--color-bg-3);
}

.tab-btn.active {
  background: var(--color-bg-1);
  border-bottom: 1px solid var(--color-bg-1);
  color: var(--color-text-4);
  font-weight: var(--font-weight-semibold);
}

.refpoint-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--spacing-sm);
  border-bottom: 1px solid var(--color-border);
  cursor: pointer;
  transition: background var(--transition-fast);
}

.refpoint-item:hover {
  background: var(--color-bg-3);
}

.refpoint-item.active {
  background: var(--color-primary);
}

.refpoint-info {
  flex: 1;
}

.refpoint-name {
  font-size: var(--font-size-md);
  color: var(--color-text-4);
  margin: 0 0 var(--spacing-xs) 0;
}

.refpoint-type {
  font-size: var(--font-size-xxs);
  color: var(--color-text-2);
  font-family: var(--font-family-mono);
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

/* Reference Point Editor Panel */
.refpoint-editor-panel {
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

/* Info box */
.info-box {
  background: var(--color-bg-2);
  padding: var(--spacing-sm);
  border-radius: var(--spacing-xxs);
  font-size: var(--font-size-xs);
  color: var(--color-text-1);
  line-height: 1.6;
}

.info-box strong {
  color: var(--color-text-4);
  display: block;
  margin-bottom: var(--spacing-xs);
}

/* No selection state */
.no-selection {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--color-text-2);
  font-size: var(--font-size-md);
}
</style>
