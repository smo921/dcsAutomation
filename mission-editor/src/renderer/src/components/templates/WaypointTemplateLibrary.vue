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
        @click="applyTemplate(template)"
      >
        <div class="template-info">
          <h5>{{ template.name }}</h5>
          <p class="template-desc">
            {{ template.waypoints?.length || 0 }} waypoints
          </p>
        </div>
        <div class="template-meta">
          <span class="apply-indicator">Apply</span>
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

const store = useTemplatesStore()

const searchQuery = ref('')

const filteredTemplates = computed(() => {
  if (!searchQuery.value) return store.waypointTemplates
  return store.waypointTemplates.filter(t =>
    (t.name && t.name.toLowerCase().includes(searchQuery.value.toLowerCase())) ||
    (t.description && t.description.toLowerCase().includes(searchQuery.value.toLowerCase()))
  )
})

const emit = defineEmits(['waypoint-template-apply'])

const applyTemplate = (template) => {
  emit('waypoint-template-apply', template)
}
</script>

<style scoped>
.waypoint-template-library {
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

.waypoint-template-list {
  max-height: 400px;
  overflow-y: auto;
}

.waypoint-template-item {
  background: #252526;
  padding: 10px;
  border-radius: 3px;
  cursor: pointer;
  transition: background 0.2s;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
}

.waypoint-template-item:hover {
  background: #303030;
}

.waypoint-template-item:last-child {
  margin-bottom: 0;
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
  font-size: 10px;
  color: #666;
}

.apply-indicator {
  background: #0e639c;
  padding: 2px 8px;
  border-radius: 3px;
  font-weight: bold;
}

.no-results {
  padding: 20px;
  text-align: center;
  color: #666;
}
</style>
