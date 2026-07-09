<template>
  <div class="waypoint-template-library">
    <div class="library-header">
      <Input v-model="searchQuery" placeholder="Search waypoint templates..." />
    </div>

    <div class="list-container">
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
            Delete
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
/* Library header */
.library-header {
  margin-bottom: var(--spacing-md);
}

/* Uses shared classes from _list-editor.css: list-container, list-item, list-item-content */
</style>
