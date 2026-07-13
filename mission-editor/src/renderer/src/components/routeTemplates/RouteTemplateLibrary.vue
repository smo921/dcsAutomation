<template>
  <div class="route-template-library">
    <div class="library-header">
      <FormInput v-model="searchQuery" placeholder="Search route templates..." />
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
            {{ template.route?.length || 0 }} waypoints
          </Badge>
        </div>
        <div class="list-item-actions">
          <Button variant="primary" size="sm" @click.stop="editTemplate(template)" title="Edit Route Template">
            Edit
          </Button>
          <Button variant="danger" size="sm" @click.stop="deleteTemplate(template)" title="Delete Route Template">
            Delete
          </Button>
          <Button variant="primary" size="sm" @click.stop="applyTemplate(template)" title="Apply Template">
            Apply
          </Button>
        </div>
      </div>

      <div v-if="filteredTemplates.length === 0" class="empty-state">
        <p>No route templates found.</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouteTemplatesStore } from '../../stores/routeTemplates'
import { FormInput, Badge, Button } from '../ui'

const store = useRouteTemplatesStore()

const searchQuery = ref('')

const filteredTemplates = computed(() => {
  if (!searchQuery.value) return store.templates
  return store.templates.filter(t =>
    (t.name && t.name.toLowerCase().includes(searchQuery.value.toLowerCase())) ||
    (t.description && t.description.toLowerCase().includes(searchQuery.value.toLowerCase()))
  )
})

const emit = defineEmits(['route-template-apply', 'route-template-edit', 'route-template-delete'])

const applyTemplate = (template) => {
  emit('route-template-apply', template)
}

const editTemplate = (template) => {
  emit('route-template-edit', template)
}

const deleteTemplate = (template) => {
  emit('route-template-delete', template)
}
</script>

<style scoped>
/* Library header */
.library-header {
  margin-bottom: var(--spacing-md);
}

/* Uses shared classes from _list-editor.css: list-container, list-item, list-item-content */
</style>
