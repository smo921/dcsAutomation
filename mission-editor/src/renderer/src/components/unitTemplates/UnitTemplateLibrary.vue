<template>
  <div class="unit-template-library">
    <TabbedList
      :categories="categories"
      v-model:activeCategory="activeCategory"
      :items="getTemplatesByCategory(activeCategory)"
      listOnly
      itemKey="name"
      @item-select="onItemSelect"
    >
      <!-- Search input in header slot -->
      <template #list-header>
        <div class="library-header">
          <FormInput
            v-model="searchQuery"
            type="search"
            placeholder="Search unit templates..."
          />
        </div>
      </template>

      <!-- List item rendering -->
      <template #item-meta="{ item }">
        <p v-if="item.description" class="list-item-meta">
          {{ item.description }}
        </p>
      </template>

      <template #item-actions="{ item }">
        <Button variant="primary" size="sm" @click.stop="editTemplate(item, activeCategory)" title="Edit Unit Template">
          Edit
        </Button>
        <Button variant="danger" size="sm" @click.stop="deleteTemplate(item, activeCategory)" title="Delete Unit Template">
          <span class="btn-remove-icon">Delete</span>
        </Button>
        <span v-if="item.units" class="unit-count">
          {{ Array.isArray(item.units) ? item.units.length : 0 }} units
        </span>
      </template>

      <!-- Empty state -->
      <template #empty-state>
        <EmptyState>
          <p>No {{ activeCategory }} unit templates configured.</p>
        </EmptyState>
      </template>
    </TabbedList>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useUnitTemplatesStore } from '../../stores/unitTemplates'
import { Button, FormInput, EmptyState, TabbedList } from '../ui'

const emit = defineEmits(['unit-template-apply', 'unit-template-edit', 'unit-template-delete'])

const store = useUnitTemplatesStore()

const searchQuery = ref('')
const categories = ['air', 'ground', 'naval', 'support']
const activeCategory = ref('air')

const getTemplatesByCategory = (category) => {
  const templates = store.categories[category] || []
  if (!searchQuery.value) return templates
  return templates.filter(t =>
    (t.name && t.name.toLowerCase().includes(searchQuery.value.toLowerCase())) ||
    (t.description && t.description.toLowerCase().includes(searchQuery.value.toLowerCase()))
  )
}

const onItemSelect = ({ item }) => {
  // Optionally emit apply on click, or just select
  // emit('unit-template-apply', { template: item, category: activeCategory.value })
}

const editTemplate = (template, category) => {
  emit('unit-template-edit', { template, category })
}

const deleteTemplate = (template, category) => {
  emit('unit-template-delete', { template, category })
}
</script>

<style scoped>
/* Uses shared classes from _list-editor.css: list-container, list-item, list-item-content, list-item-meta */
/* Uses shared classes from _components.css: editor-section */

/* Library header */
.library-header {
  margin-bottom: var(--spacing-md);
}

/* Unit count badge */
.unit-count {
  background: var(--color-bg-2);
  padding: var(--spacing-xxs) var(--spacing-sm);
  border-radius: var(--spacing-xxs);
  font-size: var(--font-size-xxs);
  margin-top: var(--spacing-xs);
}
</style>
