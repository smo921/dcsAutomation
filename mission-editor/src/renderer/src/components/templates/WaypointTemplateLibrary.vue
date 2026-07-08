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

const emit = defineEmits(['waypoint-template-apply', 'waypoint-template-delete'])

const applyTemplate = (template) => {
  emit('waypoint-template-apply', template)
}

const deleteTemplate = (template) => {
  emit('waypoint-template-delete', template)
}
</script>

<style scoped>
/* Uses shared classes from components.css */
.waypoint-template-library {
  width: 100%;
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
}
</style>
