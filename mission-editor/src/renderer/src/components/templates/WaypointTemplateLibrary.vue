<template>
  <div class="waypoint-template-library">
    <div class="library-header">
      <Input v-model="searchQuery" placeholder="Search waypoint templates..." />
    </div>

    <div class="waypoint-template-list">
      <div
        v-for="template in filteredTemplates"
        :key="template.id"
        class="list-item"
      >
        <div class="list-item-content">
          <h5>{{ template.name }}</h5>
          <Badge variant="primary">
            {{ template.waypoints?.length || 0 }} waypoints
          </Badge>
        </div>
        <div class="list-item-actions">
          <Button variant="primary" size="sm" @click.stop="editTemplate(template)" title="Edit Template">
            Edit
          </Button>
          <Button variant="danger" size="sm" @click.stop="deleteTemplate(template)" title="Delete Template">
            Remove
          </Button>
          <Button variant="primary" size="sm" @click.stop="applyTemplate(template)" title="Apply Template">
            Apply
          </Button>
        </div>
      </div>

      <div v-if="filteredTemplates.length === 0" class="empty-state">
        <p>No waypoint templates found.</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useTemplatesStore } from '../../stores/templates'
import { Input, Badge, Button } from '../ui'

const store = useTemplatesStore()

const searchQuery = ref('')

const filteredTemplates = computed(() => {
  if (!searchQuery.value) return store.waypointTemplates
  return store.waypointTemplates.filter(t =>
    (t.name && t.name.toLowerCase().includes(searchQuery.value.toLowerCase())) ||
    (t.description && t.description.toLowerCase().includes(searchQuery.value.toLowerCase()))
  )
})

const emit = defineEmits(['waypoint-template-apply', 'waypoint-template-edit', 'waypoint-template-delete'])

const applyTemplate = (template) => {
  emit('waypoint-template-apply', template)
}

const editTemplate = (template) => {
  emit('waypoint-template-edit', template)
}

const deleteTemplate = (template) => {
  emit('waypoint-template-delete', template)
}
</script>

<style scoped>
/* Uses shared classes from _components.css: waypoint-template-library */
/* Uses shared classes from _components.css: library-header */
/* Uses shared classes from _components.css: waypoint-template-list, list-item */
/* Uses shared classes from _components.css: list-item-content, list-item-actions */

/* Waypoint Template List */
.waypoint-template-list {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-sm);
}

.list-item {
  background: var(--color-bg-1);
  padding: var(--spacing-sm);
  border-radius: var(--spacing-xxs);
  display: flex;
  justify-content: space-between;
  align-items: center;
  border: 1px solid var(--color-border);
  transition: all var(--transition-fast);
}

.list-item:hover {
  border-color: var(--color-border-focus);
}

.list-item-content {
  flex: 1;
}

.list-item-content h5 {
  font-size: var(--font-size-md);
  color: var(--color-text-4);
  margin: 0 0 var(--spacing-xs) 0;
}

.list-item-actions {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
}
</style>
