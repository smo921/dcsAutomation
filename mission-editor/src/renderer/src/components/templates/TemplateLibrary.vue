<template>
  <div class="template-library">
    <div class="library-header">
      <FormInput
        v-model="searchQuery"
        type="search"
        placeholder="Search templates..."
      />
    </div>

    <div class="category-tabs">
      <button
        v-for="category in categories"
        :key="category"
        :class="['tab-btn', { active: activeCategory === category }]"
        @click="activeCategory = category"
      >
        {{ category.charAt(0).toUpperCase() + category.slice(1) }}
      </button>
    </div>

    <EmptyState v-if="getTemplatesByCategory(activeCategory).length === 0">
      <p>No {{ activeCategory }} templates configured.</p>
    </EmptyState>

    <div class="list-scroll list-scroll-fixed-height">
      <div class="list-container">
        <div v-for="template in getTemplatesByCategory(activeCategory)" :key="template.id || template.name" class="list-item">
          <div class="list-item-content">
            <h5>{{ template.name }}</h5>
            <p v-if="template.description" class="list-item-meta">
              {{ template.description }}
            </p>
          </div>
          <div class="list-item-actions">
            <Button variant="primary" size="sm" @click.stop="editTemplate(template, activeCategory)" title="Edit Template">
              Edit
            </Button>
            <Button variant="danger" size="sm" @click.stop="deleteTemplate(template, activeCategory)" title="Delete Template">
              <span class="btn-remove-icon">Delete</span>
            </Button>
          </div>
          <span v-if="template.units" class="unit-count">
            {{ Array.isArray(template.units) ? template.units.length : 0 }} units
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useTemplatesStore } from '../../stores/templates'
import { Button, FormInput, EmptyState } from '../ui'

const emit = defineEmits(['template-apply', 'template-edit', 'template-delete'])

const store = useTemplatesStore()

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

const applyTemplate = (template, category) => {
  emit('template-apply', { template, category })
}

const editTemplate = (template, category) => {
  emit('template-edit', { template, category })
}

const deleteTemplate = (template, category) => {
  emit('template-delete', { template, category })
}
</script>

<style scoped>
/* Uses shared classes from _utils.css: category-tabs, tab-btn */
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
