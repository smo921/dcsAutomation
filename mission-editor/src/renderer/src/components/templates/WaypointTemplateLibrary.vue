<template>
  <div class="waypoint-template-library">
    <div class="library-header">
      <input
        type="text"
        v-model="searchQuery"
        placeholder="Search waypoint templates..."
        class="search-input"
      />
    </div>

    <div class="waypoint-template-list">
      <div
        v-for="template in filteredTemplates"
        :key="template.id"
        class="waypoint-template-item"
      >
        <div class="template-info" @click="applyTemplate(template)">
          <h5>{{ template.name }}</h5>
          <span class="template-badge">
            {{ template.waypoints?.length || 0 }} waypoints
          </span>
        </div>
        <div class="template-meta">
          <button class="btn-remove" @click.stop="deleteTemplate(template)" title="Delete Template">
            <span class="btn-remove-icon">✕</span>
          </button>
          <Button variant="primary" size="sm" @click.stop="applyTemplate(template)" title="Apply Template">
            Apply
          </Button>
        </div>
      </div>

      <div v-if="filteredTemplates.length === 0" class="no-results">
        <p>No waypoint templates found.</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useTemplatesStore } from '../../stores/templates'
import { Button } from '../ui'

const store = useTemplatesStore()

const searchQuery = ref('')

const filteredTemplates = computed(() => {
  if (!searchQuery.value) return store.waypointTemplates
  return store.waypointTemplates.filter(t =>
    (t.name && t.name.toLowerCase().includes(searchQuery.value.toLowerCase())) ||
    (t.description && t.description.toLowerCase().includes(searchQuery.value.toLowerCase()))
  )
})

const emit = defineEmits(['waypoint-template-apply', 'waypoint-template-delete'])

const applyTemplate = (template) => {
  emit('waypoint-template-apply', template)
}

const deleteTemplate = (template) => {
  emit('waypoint-template-delete', template)
}
</script>

<style scoped>
.waypoint-template-library {
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

.waypoint-template-list {
  max-height: 400px;
  overflow-y: auto;
}

.waypoint-template-item {
  background: var(--color-bg-1);
  padding: var(--spacing-sm);
  border-radius: var(--spacing-xxs);
  cursor: pointer;
  transition: background var(--transition-fast);
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: var(--spacing-xs);
}

.waypoint-template-item:hover {
  background: var(--color-bg-3);
}

.waypoint-template-item:last-child {
  margin-bottom: 0;
}

.template-info {
  flex: 1;
}

.template-info h5 {
  font-size: var(--font-size-md);
  color: var(--color-text-4);
  margin-bottom: var(--spacing-xs);
}

.template-badge {
  background: var(--color-bg-2);
  padding: var(--spacing-xxs) var(--spacing-sm);
  border-radius: var(--spacing-xxs);
  font-size: var(--font-size-xxs);
  color: var(--color-text-1);
  margin-top: var(--spacing-xs);
  display: inline-block;
}

.template-meta {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
}

/* Make apply button same height as delete icon (24px) */
.template-meta .btn {
  padding: var(--spacing-xs) var(--spacing-sm);
  height: 24px;
  font-size: var(--font-size-xxs);
}

.no-results {
  padding: var(--spacing-lg);
  text-align: center;
  color: var(--color-text-2);
}
</style>
