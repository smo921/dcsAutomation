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
          <span class="expand-icon" :class="{ expanded: expandedCategories[category] }">▼</span>
        </div>
        <div v-if="expandedCategories[category]" class="category-content">
          <div class="templates-list">
            <div
              v-for="template in getTemplatesByCategory(category)"
              :key="template.id || template.name"
              class="template-item"
              @click="applyTemplate(template)"
            >
              <div class="template-info">
                <h5>{{ template.name }}</h5>
                <p v-if="template.description" class="template-desc">
                  {{ template.description }}
                </p>
              </div>
              <div class="template-meta">
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

// Load templates on mount
onMounted(() => {
  // Templates loaded from store (can be populated via sample data)
  // The App.vue loads templates into the store on mount
})

const getTemplatesByCategory = (category) => {
  const templates = store.categories[category] || []
  if (!searchQuery.value) return templates
  return templates.filter(t =>
    (t.name && t.name.toLowerCase().includes(searchQuery.value.toLowerCase())) ||
    (t.description && t.description.toLowerCase().includes(searchQuery.value.toLowerCase()))
  )
}

const emit = defineEmits(['template-apply', 'template-select'])

const applyTemplate = (template) => {
  emit('template-apply', template)
}

// Also emit when user just selects/hovers over a template
const templateSelect = (template) => {
  emit('template-select', template)
}
</script>

<style scoped>
.template-library {
  width: 100%;
}

.library-header {
  margin-bottom: 12px;
}

.search-input {
  width: 100%;
  background: #3c3c3c;
  border: 1px solid #454545;
  color: white;
  padding: 8px;
  border-radius: 3px;
  font-size: 12px;
}

.search-input:focus {
  outline: none;
  border-color: #0e639c;
}

.template-categories {
  max-height: 400px;
  overflow-y: auto;
}

.category-section {
  margin-bottom: 16px;
}

.category-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  user-select: none;
  padding: 8px 0;
}

.category-header:hover {
  opacity: 0.8;
}

.category-header h4 {
  font-size: 12px;
  text-transform: uppercase;
  color: #888;
  margin: 0;
}

.expand-icon {
  font-size: 10px;
  color: #888;
  transition: transform 0.2s;
}

.expand-icon.expanded {
  transform: rotate(180deg);
}

.category-content {
  animation: slideDown 0.3s ease-out;
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
  gap: 4px;
}

.template-item {
  background: #252526;
  padding: 10px;
  border-radius: 3px;
  cursor: pointer;
  transition: background 0.2s;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.template-item:hover {
  background: #303030;
}

.template-info {
  flex: 1;
}

.template-info h5 {
  font-size: 13px;
  color: #ffffff;
  margin-bottom: 4px;
}

.template-desc {
  font-size: 11px;
  color: #888;
  line-height: 1.4;
}

.template-meta {
  font-size: 11px;
  color: #666;
}

.unit-count {
  background: #3c3c3c;
  padding: 2px 6px;
  border-radius: 3px;
}
</style>
