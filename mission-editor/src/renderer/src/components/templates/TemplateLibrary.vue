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

    <div class="template-categories">
      <div v-for="category in categories" :key="category" class="category-section">
        <div class="category-header" @click="toggleCategory(category)">
          <h4>{{ category }}</h4>
          <Button
            variant="ghost"
            size="sm"
            class="toggle-btn"
            @click.stop="toggleCategory(category)"
          >
            <template #icon>
              <span class="expand-icon" :class="{ expanded: expandedCategories[category] }">▼</span>
            </template>
          </Button>
        </div>
        <div v-if="expandedCategories[category]" class="category-content">
          <div class="templates-list">
            <div
              v-for="template in getTemplatesByCategory(category)"
              :key="template.id || template.name"
              class="template-item"
            >
              <div class="template-info" @click.stop="applyTemplate(template, category)">
                <h5>{{ template.name }}</h5>
                <p v-if="template.description" class="template-desc">
                  {{ template.description }}
                </p>
              </div>
              <div class="template-actions">
                <Button
                  variant="ghost"
                  size="sm"
                  iconOnly
                  title="Edit Template"
                  @click.stop="editTemplate(template, category)"
                >
                  ✎
                </Button>
                <Button
                  variant="ghost"
                  size="sm"
                  iconOnly
                  title="Delete Template"
                  @click.stop="deleteTemplate(template, category)"
                >
                  ✕
                </Button>
                <span v-if="template.units" class="unit-count">
                  {{ Array.isArray(template.units) ? template.units.length : 0 }} units
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useTemplatesStore } from '../../stores/templates'
import { Button } from '../ui'

const emit = defineEmits(['template-apply', 'template-edit', 'template-delete'])

const store = useTemplatesStore()

const searchQuery = ref('')
const categories = ['air', 'ground', 'naval', 'support']

// Track expanded categories
const expandedCategories = ref({
  air: true,
  ground: true,
  naval: true,
  support: true
})

const toggleCategory = (category) => {
  expandedCategories.value[category] = !expandedCategories.value[category]
}

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

// Load templates on mount
onMounted(() => {
  // Templates loaded from store (can be populated via sample data)
  // The App.vue loads templates into the store on mount
})
</script>

<style scoped>
.template-library {
  width: 100%;
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

.template-categories {
  max-height: 400px;
  overflow-y: auto;
}

.category-section {
  margin-bottom: var(--spacing-md);
}

.category-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  user-select: none;
  padding: var(--spacing-xs) 0;
}

.category-header:hover {
  opacity: 0.8;
}

.category-header h4 {
  font-size: var(--font-size-sm);
  text-transform: uppercase;
  color: var(--color-text-1);
  margin: 0;
}

.toggle-btn :deep(.btn) {
  padding: var(--spacing-xs);
  margin-left: var(--spacing-xs);
}

.expand-icon {
  font-size: var(--font-size-xxs);
  color: var(--color-text-1);
  transition: transform var(--transition-fast);
}

.expand-icon.expanded {
  transform: rotate(180deg);
}

.category-content {
  animation: slideDown var(--transition-normal);
}

@keyframes slideDown {
  from {
    max-height: 0;
    opacity: 0;
  }
  to {
    max-height: 500px;
    opacity: 1;
  }
}

.templates-list {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-xs);
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

.template-meta {
  font-size: var(--font-size-xxs);
  color: var(--color-text-2);
}

.template-actions {
  display: flex;
  align-items: center;
  gap: var(--spacing-xs);
}
</style>
