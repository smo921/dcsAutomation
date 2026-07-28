<template>
  <div class="refpoint-manager list-container">
    <TabbedList
      :categories="categories"
      v-model:activeCategory="activeCategory"
      :items="getRefPointsByCategory"
      :listOnly="props.listOnly"
      itemKey="name"
      @item-select="onItemSelect"
    >
      <!-- Toolbar slot -->
      <template #list-header>
        <div class="refpoint-toolbar">
          <Button @click="showVisualLayout = true" variant="secondary" size="sm">
            <Icon name="map" />
            Visual Layout
          </Button>
        </div>
      </template>

      <!-- List item rendering -->
      <template #item-meta="{ item }">
        <Badge variant="primary">{{ getCategoryLabel(item.type) }}</Badge>
      </template>

      <template #item-actions="{ item }">
        <Button variant="primary" size="sm" @click.stop="onEditRefPoint(item)" title="Edit Reference Point">
          Edit
        </Button>
        <Button variant="danger" size="sm" @click.stop="onDeleteRefPoint(item)" title="Delete Reference Point">
          <span class="btn-remove-icon">Delete</span>
        </Button>
      </template>

      <!-- Empty state -->
      <template #empty-state>
        <EmptyState>
          <p>No {{ activeCategory }} reference points configured.</p>
        </EmptyState>
      </template>

      <!-- Detail editor -->
      <template #editor="{ selectedItem }">
        <div v-if="selectedItem && currentRefPoint" class="editor-content">
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
        <div v-else class="no-selection">
          <p>Select a reference point to edit</p>
        </div>
      </template>
    </TabbedList>

    <!-- Visual Layout Modal -->
    <Modal
      v-model:open="showVisualLayout"
      title="Reference Point Visual Layout"
      :closeOnBackground="true"
      size="lg"
    >
      <template #content>
        <div class="visual-layout-modal-content">
          <ReferencePointCanvas
            :refpoints="store"
            :width="900"
            :height="550"
            @refpoints-change="handleRefpointsChange"
          />
        </div>
      </template>
    </Modal>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { EmptyState, FormLabel, FormInput, FormRow, CollapsiblePanel, Button, Badge, Modal, TabbedList } from '../ui'
import Icon from '../ui/Icon.vue'
import ReferencePointCanvas from '../visualizer/ReferencePointCanvas.vue'

const showVisualLayout = ref(false)

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

const selectedRefPoint = ref(null) // Holds the currently selected reference point object
const currentRefPoint = ref(null) // Working copy for editing
const refPointType = ref('')

// Update refpoint in store
const updateRefPointInStore = (refPoint) => {
  const type = refPoint.type
  const index = store[type + 's'].findIndex(r => r.name === refPoint.name)
  if (index !== -1) {
    store[type + 's'][index] = refPoint
  }
}

// Section expansion state (all expanded by default)
const expandedSections = ref({
  basic: true,
  coordinates: true,
  notes: true
})

// Handle item selection from TabbedList
const onItemSelect = ({ item }) => {
  selectRefPoint(item)
}

// ---- Selection logic ----------------------------------------------------
/**
 * Called when a reference point row is clicked.
 * - Stores the original object in `selectedRefPoint`
 * - Creates an editable copy in `currentRefPoint`
 */
const selectRefPoint = (refPoint) => {
  selectedRefPoint.value = refPoint
  currentRefPoint.value  = JSON.parse(JSON.stringify(refPoint))
  refPointType.value     = refPoint.type
  emit('select', refPoint)
}

const onEditRefPoint = (refPoint) => {
  emit('refpoint-edit', refPoint)
}

const onDeleteRefPoint = (refPoint) => {
  emit('refpoint-delete', refPoint)
}

const handleRefpointsChange = (updatedRefpoints) => {
  // Emit change event to notify parent
  emit('update')
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

.refpoint-toolbar {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  margin-bottom: var(--spacing-sm);
}

.visual-layout-modal-content {
  padding: var(--spacing-md);
}
</style>
