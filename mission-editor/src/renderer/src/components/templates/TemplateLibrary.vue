<template>
  <div class="template-library">
    <div class="library-header">
      <input
        type="text"
        v-model="searchQuery"
        placeholder="Search templates..."
        class="search-input"
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

    <div class="category-content">
      <div v-if="getTemplatesByCategory(activeCategory).length === 0" class="empty-state">
        <p>No {{ activeCategory }} templates configured.</p>
      </div>
      <div v-for="template in getTemplatesByCategory(activeCategory)" :key="template.id || template.name" class="template-item">
        <div class="template-info" @click.stop="applyTemplate(template, activeCategory)">
          <h5>{{ template.name }}</h5>
          <p v-if="template.description" class="template-desc">
            {{ template.description }}
          </p>
        </div>
        <div class="template-actions">
          <button class="btn-remove" @click.stop="deleteTemplate(template, activeCategory)" title="Delete Template">✕</button>
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
import { Button } from '../ui'
import { Icon } from '../ui'

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
.template-library {
  width: 100%;
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
}

.library-header {
  margin-bottom: var(--spacing-md);
}

.search-input {
  width: 100%;
  background: var(--color-bg-2);
  border: 1px solid var(--color-border);
  color: var(--color-text-4);
  padding: var(--spacing-sm);
  border-radius: var(--spacing-xxs);
  font-size: var(--font-size-sm);
}

.search-input:focus {
  outline: none;
  border-color: var(--color-border-focus);
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

/* Category Content */
.category-content {
  max-height: 400px;
  overflow-y: auto;
}

.empty-state {
  padding: var(--spacing-lg);
  text-align: center;
  color: var(--color-text-1);
  font-size: var(--font-size-sm);
}

.template-item {
  background: var(--color-bg-1);
  padding: var(--spacing-sm);
  border-radius: var(--spacing-xxs);
  cursor: pointer;
  transition: background var(--transition-fast);
  display: flex;
  justify-content: space-between;
  align-items: center;
  border: 1px solid var(--color-border);
}

.template-item:hover {
  background: var(--color-bg-3);
  border-color: var(--color-primary);
}

.template-info {
  flex: 1;
}

.template-info h5 {
  font-size: var(--font-size-md);
  color: var(--color-text-4);
  margin-bottom: var(--spacing-xs);
}

.template-desc {
  font-size: var(--font-size-xxs);
  color: var(--color-text-1);
  line-height: 1.4;
}

.template-actions {
  display: flex;
  align-items: center;
  gap: var(--spacing-xs);
}

.unit-count {
  background: var(--color-bg-2);
  padding: var(--spacing-xxs) var(--spacing-sm);
  border-radius: var(--spacing-xxs);
  font-size: var(--font-size-xxs);
}
</style>
