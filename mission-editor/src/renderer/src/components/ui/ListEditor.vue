<template>
  <div class="list-editor">
    <!-- List Header (optional) -->
    <div v-if="listHeader || $slots.listHeader" class="list-editor-header">
      <slot name="listHeader">
        <h3>{{ listHeader }}</h3>
      </slot>
      <div v-if="$slots.actions" class="list-editor-actions">
        <slot name="actions" />
      </div>
    </div>

    <!-- Scrollable List Container -->
    <div
      class="list-editor-scroll"
      :class="{ 'scrollbar-custom': !disableScrollbars }"
      :style="{ height: listHeight + 'px' }"
    >
      <div class="list-editor-list">
        <div
          v-for="item in items"
          :key="getItemKey(item)"
          class="list-editor-item"
          :class="{ active: selectedItem === getItemKey(item) }"
          @click="selectItem(item)"
        >
          <div class="list-editor-item-content">
            <slot name="item" :item="item" :key="getItemKey(item)" />
          </div>
          <div v-if="$slots.itemActions" class="list-editor-item-actions">
            <slot name="itemActions" :item="item" />
          </div>
        </div>

        <EmptyState v-if="items.length === 0">
          <slot name="emptyState">
            <p>No items configured.</p>
          </slot>
        </EmptyState>
      </div>
    </div>

    <!-- Resizeable Divider -->
    <div
      v-if="!listOnly && !disableDivider"
      class="content-resizer"
      @mousedown="startListResize"
    >
      <span class="resizer-line"></span>
    </div>

    <!-- Editor Panel -->
    <div
      v-if="!listOnly && selectedItem && currentItem"
      class="list-editor-panel"
    >
      <div class="editor-content" :class="{ 'scrollbar-custom': !disableScrollbars }">
        <slot name="editor" :item="currentItem" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { EmptyState } from './index.js'

const props = defineProps({
  // Items to display in the list
  items: {
    type: Array,
    default: () => []
  },

  // List header text
  listHeader: {
    type: String,
    default: ''
  },

  // When true, only show the list (no editor panel) - used in sidebar
  listOnly: {
    type: Boolean,
    default: false
  },

  // Disable the divider and editor panel
  disableDivider: {
    type: Boolean,
    default: false
  },

  // Disable adding custom scrollbar classes
  disableScrollbars: {
    type: Boolean,
    default: false
  },

  // Key function to get unique item identifier
  itemKey: {
    type: Function,
    default: (item) => item.name || item.id || item.groupName
  },

  // Initial list height
  initialListHeight: {
    type: Number,
    default: 300
  }
})

const emit = defineEmits([
  'update:items',
  'select',
  'change',
  'delete',
  'add',
  'list-resize'
])

const selectedItem = ref('')
const currentItem = ref(null)
const listHeight = ref(props.initialListHeight)

// Flag to prevent watcher loop during bulk updates
const isSyncingItems = ref(false)

// v-model support for items
const internalItems = ref(props.items)

watch(() => props.items, (newVal) => {
  if (!isSyncingItems.value) {
    internalItems.value = newVal
  }
})

watch(internalItems, (newVal) => {
  if (!isSyncingItems.value) {
    emit('update:items', newVal)
  }
}, { deep: true })

// Selection handler
const selectItem = (item) => {
  const key = props.itemKey(item)
  selectedItem.value = key
  currentItem.value = JSON.parse(JSON.stringify(item))
  emit('select', item)
}

// Get item key for Vue v-for
const getItemKey = (item) => {
  return props.itemKey(item)
}

// Resize handling
let isResizing = false
let startY = 0
let startHeight = 0

const startListResize = (e) => {
  if (props.listOnly || props.disableDivider) return
  isResizing = true
  startY = e.clientY
  startHeight = listHeight.value

  document.addEventListener('mousemove', onMouseMove)
  document.addEventListener('mouseup', onMouseUp)
}

const onMouseMove = (e) => {
  if (!isResizing) return
  const dy = e.clientY - startY
  const newSize = Math.max(100, Math.min(500, startHeight + dy))
  listHeight.value = newSize
  emit('list-resize', newSize)
}

const onMouseUp = () => {
  isResizing = false
}

// Watch for external item changes
watch(() => props.items, (newItems) => {
  // If current item is no longer in the list, clear selection
  if (currentItem.value) {
    const stillExists = newItems.find(
      (i) => props.itemKey(i) === selectedItem.value
    )
    if (!stillExists) {
      selectedItem.value = ''
      currentItem.value = null
    }
  }
})

// Watch for external selection
watch(
  () => props.items,
  (newItems) => {
    if (currentItem.value && selectedItem.value) {
      const found = newItems.find(
        (i) => props.itemKey(i) === selectedItem.value
      )
      if (found) {
        currentItem.value = JSON.parse(JSON.stringify(found))
      }
    }
  },
  { deep: true }
)

// Expose methods for external access
defineExpose({
  selectItem,
  currentItem,
  selectedItem,
  listHeight,
  setSyncing(syncing) {
    isSyncingItems.value = syncing
  }
})
</script>

<style scoped>
.list-editor {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
}

/* List Header */
.list-editor-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--spacing-sm) 0;
}

.list-editor-header h3 {
  font-size: var(--font-size-md);
  color: var(--color-text-0);
  margin: 0;
}

.list-editor-actions {
  display: flex;
  gap: var(--spacing-xs);
}

/* List Container */
.list-editor-scroll {
  flex: 0 0 auto;
  overflow-y: auto;
  min-height: 100px;
  margin-bottom: var(--spacing-xs);
}

.list-editor-list {
  display: flex;
  flex-direction: column;
}

/* List Item */
.list-editor-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--spacing-sm) var(--spacing-md);
  background: var(--color-bg-1);
  border: 1px solid var(--color-border);
  border-bottom: none;
  cursor: pointer;
  transition: background var(--transition-fast);
}

.list-editor-item:first-child {
  border-top-left-radius: var(--spacing-xs);
  border-top-right-radius: var(--spacing-xs);
}

.list-editor-item:last-child {
  border-bottom-left-radius: var(--spacing-xs);
  border-bottom-right-radius: var(--spacing-xs);
  border-bottom: 1px solid var(--color-border);
}

.list-editor-item:hover {
  background: var(--color-bg-3);
}

.list-editor-item.active {
  background: var(--color-primary);
  border-color: var(--color-primary-hover);
}

.list-editor-item-content {
  flex: 1;
  min-width: 0;
}

.list-editor-item-actions {
  display: flex;
  align-items: center;
  gap: var(--spacing-xs);
  margin-left: var(--spacing-sm);
}

/* Resizer */
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

/* Editor Panel */
.list-editor-panel {
  background: var(--color-bg-1);
  border-radius: var(--spacing-xs);
  border: 1px solid var(--color-border);
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
  overflow: hidden;
}

.editor-content {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  padding: var(--spacing-md);
}

.editor-content:last-child {
  padding-bottom: calc(var(--spacing-md) - var(--spacing-sm));
}
</style>
