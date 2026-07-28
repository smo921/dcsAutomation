<template>
  <div class="tabbed-list">
    <!-- Toolbar Slot (optional) -->
    <div v-if="$slots['list-header']" class="list-header">
      <slot name="list-header"></slot>
    </div>

    <!-- Category Tabs -->
    <div v-if="categories.length > 0" class="category-tabs">
      <button
        v-for="(category, index) in categories"
        :key="getCategoryValue(category)"
        :class="['tab-btn', { active: activeCategory === getCategoryValue(category) }]"
        @click="selectCategory(getCategoryValue(category))"
        @keydown.enter="selectCategory(getCategoryValue(category))"
        @keydown.arrow-left="focusPreviousTab(index)"
        @keydown.arrow-right="focusNextTab(index)"
        ref="tabButtons"
        :tabindex="activeCategory === getCategoryValue(category) ? 0 : -1"
      >
        {{ getCategoryLabel(category) }}
      </button>
    </div>

    <!-- Scrollable List Container -->
    <div class="list-scroll" :class="listHeightClass" :style="listStyle">
      <div class="list-container">
        <slot
          name="list"
          :items="items"
          :activeCategory="activeCategory"
        >
          <!-- Default: render items if no slot provided -->
          <div
            v-for="(item, index) in items"
            :key="getItemKey(item, index)"
            class="list-item"
            :class="{ active: isSelected(item) }"
            @click="selectItem(item, index)"
          >
            <div class="list-item-content">
              <h5 class="list-item-header">{{ getItemLabel(item) }}</h5>
              <slot name="item-meta" :item="item" :index="index"></slot>
            </div>
            <slot name="item-actions" :item="item" :index="index"></slot>
          </div>
        </slot>

        <!-- Empty State -->
        <slot v-if="items.length === 0" name="empty-state">
          <div class="empty-state">
            <p>No items in this category.</p>
          </div>
        </slot>
      </div>
    </div>

    <!-- Resizable Divider (only when not listOnly) -->
    <div v-if="!listOnly && $slots.editor" class="content-resizer" @mousedown="startResize">
      <span class="resizer-line"></span>
    </div>

    <!-- Detail Editor Panel (only when not listOnly) -->
    <div v-if="!listOnly && $slots.editor" class="editor-panel">
      <div class="editor-content">
        <slot
          name="editor"
          :selectedItem="selectedItem"
          :selectedIndex="selectedIndex"
        >
          <!-- Default: show no-selection message -->
          <div class="no-selection">
            <p>Select an item to edit</p>
          </div>
        </slot>
      </div>
    </div>

    <!-- No selection state (when listOnly and no item selected) -->
    <div v-if="listOnly && $slots['no-selection'] && !selectedItem" class="no-selection">
      <slot name="no-selection"></slot>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useResize } from '../../composables/useResize'

const emit = defineEmits([
  'update:activeCategory',
  'item-select',
  'item-click'
])

const props = defineProps({
  // Categories can be strings or objects with { value, label }
  categories: {
    type: Array,
    default: () => []
  },
  // Currently active category (v-model support)
  activeCategory: {
    type: String,
    default: ''
  },
  // Items to display in the list (filtered by parent based on activeCategory)
  items: {
    type: Array,
    default: () => []
  },
  // When true, only show the list (no editor panel)
  listOnly: {
    type: Boolean,
    default: false
  },
  // Fixed list height in pixels, or null for flex height
  listHeight: {
    type: Number,
    default: null
  },
  // Key field for items (for v-if)
  itemKey: {
    type: String,
    default: ''
  },
  // Label field for items (for default rendering)
  itemLabel: {
    type: String,
    default: 'name'
  },
  // Currently selected item (for highlighting)
  selectedItem: {
    type: [Object, null],
    default: null
  }
})

// Tab button refs for keyboard navigation
const tabButtons = ref([])

// Internal selection state
const selectedIndex = ref(-1)

// Focus previous tab (for keyboard navigation)
const focusPreviousTab = (currentIndex) => {
  const prevIndex = currentIndex > 0 ? currentIndex - 1 : categories.length - 1
  const button = tabButtons.value[prevIndex]
  if (button) {
    button.focus()
    selectCategory(getCategoryValue(props.categories[prevIndex]))
  }
}

// Focus next tab (for keyboard navigation)
const focusNextTab = (currentIndex) => {
  const nextIndex = currentIndex < props.categories.length - 1 ? currentIndex + 1 : 0
  const button = tabButtons.value[nextIndex]
  if (button) {
    button.focus()
    selectCategory(getCategoryValue(props.categories[nextIndex]))
  }
}

// Get category value (handles both string and object formats)
const getCategoryValue = (category) => {
  return typeof category === 'string' ? category : category.value
}

// Get category label (handles both string and object formats)
const getCategoryLabel = (category) => {
  return typeof category === 'string'
    ? capitalize(category)
    : (category.label || capitalize(category.value))
}

// Capitalize first letter
const capitalize = (str) => {
  return str.charAt(0).toUpperCase() + str.slice(1)
}

// Select a category
const selectCategory = (category) => {
  emit('update:activeCategory', category)
}

// Get item key for v-if
const getItemKey = (item, index) => {
  if (props.itemKey) {
    return item[props.itemKey]
  }
  return `${index}-${getItemLabel(item)}`
}

// Get item label for default rendering
const getItemLabel = (item) => {
  if (!item) return ''
  if (typeof item === 'string') return item
  return item[props.itemLabel] || item.name || item.label || String(index)
}

// Check if item is selected
const isSelected = (item) => {
  if (!props.selectedItem) return false
  if (props.itemKey) {
    return item[props.itemKey] === props.selectedItem[props.itemKey]
  }
  return item === props.selectedItem
}

// Select an item
const selectItem = (item, index) => {
  selectedIndex.value = index
  emit('item-select', { item, index })
  emit('item-click', { item, index })
}

// List height class
const listHeightClass = computed(() => {
  if (props.listHeight) {
    return 'list-scroll-fixed-height'
  }
  return 'list-scroll-flex'
})

// Inline style for fixed height
const listStyle = computed(() => {
  if (props.listHeight) {
    return { height: props.listHeight + 'px' }
  }
  return {}
})

// Resize functionality
const listHeightRef = ref(props.listHeight || 300)
const { startResize: startListResize } = useResize({
  size: listHeightRef,
  minSize: 100,
  maxSize: 500,
  direction: 'vertical'
})

const startResize = (event) => {
  startListResize(event)
}

// Watch for external listHeight changes
watch(() => props.listHeight, (newVal) => {
  if (newVal !== null) {
    listHeightRef.value = newVal
  }
})
</script>

<style scoped>
/* Uses shared classes from _utils.css: category-tabs, tab-btn, content-resizer, resizer-line, no-selection, empty-state */
/* Uses shared classes from _list-editor.css: list-scroll, list-scroll-fixed-height, list-container, list-item, list-item-content, list-item-header, editor-panel, editor-content */

.tabbed-list {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
  height: 100%;
}

/* List flex height variant */
.list-scroll-flex {
  flex: 1;
  overflow-y: auto;
  margin-bottom: 0;
}

/* Ensure list-scroll-fixed-height has proper height - height is set via inline style */
.list-scroll-fixed-height {
  overflow-y: auto;
}

/* Keyboard focus indicator for tabs */
.tab-btn:focus {
  outline: 2px solid var(--color-primary);
  outline-offset: -2px;
}
</style>
