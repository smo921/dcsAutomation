<template>
  <ListEditor
    ref="listEditorRef"
    v-model:items="internalGroups"
    :list-header="'Groups'"
    :list-only="listOnly"
    :item-key="getGroupKey"
    @select="selectGroup"
  >
    <!-- List Header Actions -->
    <template #actions>
      <Button @click="onAddGroup" variant="secondary" size="sm">+ Add Group</Button>
    </template>

    <!-- List Item Template -->
    <template #item="slotProps">
      <div class="group-list-item">
        <div class="group-list-item-header">
          <h4>{{ slotProps.item.groupName }}</h4>
          <div class="group-list-item-meta">
            <Badge :variant="getCategoryBadge(getCategoryLabel(slotProps.item.category))">
              {{ getCategoryLabel(slotProps.item.category) }}
            </Badge>
            <Badge variant="info">
              {{ slotProps.item.triggerType || 'IMMEDIATE' }}
            </Badge>
            <Badge variant="primary">
              {{ slotProps.item.country || 'Unknown' }}
            </Badge>
          </div>
        </div>
      </div>
    </template>

    <!-- List Item Actions -->
    <template #itemActions="slotProps">
      <Button
        variant="danger"
        size="sm"
        @click.stop="onDeleteGroup(slotProps.item.groupName)"
        title="Delete Group"
      >
        <span class="btn-remove-icon">✕</span>
      </Button>
    </template>

    <!-- Editor Template -->
    <template #editor="slotProps">
      <GroupEditor
        :group="slotProps.item"
        :refpoints="refpoints"
        :templates="templates"
        @update="onGroupUpdate"
        @close="closeEditor"
      />
    </template>
  </ListEditor>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { useTemplatesStore } from '../../stores/templates'
import { ListEditor } from '../ui'
import { Button, Badge } from '../ui'
import GroupEditor from './GroupEditor.vue'

const emit = defineEmits(['group-change', 'group-delete', 'group-select', 'add-group'])

const props = defineProps({
  groups: {
    type: Array,
    default: () => []
  },
  templates: {
    type: Object,
    default: () => ({ air: [], ground: [], naval: [], support: [] })
  },
  listOnly: {
    type: Boolean,
    default: false
  }
})

const refpointsStore = useRefpointsStore()
const templatesStore = useTemplatesStore()

// Refs
const listEditorRef = ref(null)

// Flag to prevent watcher loop during bulk updates
const isSyncingGroups = ref(false)

// Refpoints for dropdowns
const refpoints = ref({
  bullseyes: refpointsStore.bullseyes,
  airbases: refpointsStore.airbases,
  zones: refpointsStore.zones,
  lines: refpointsStore.lines
})

// Watch store changes to update refpoints
// Note: During bulk operations (like loadSample), the store may be cleared
// and repopulated rapidly. The deep watcher is needed for real-time updates,
// but we avoid unnecessary updates when the list is being replaced entirely.
watch(
  () => ({
    bullseyes: refpointsStore.bullseyes,
    airbases: refpointsStore.airbases,
    zones: refpointsStore.zones,
    lines: refpointsStore.lines
  }),
  (newRefpoints) => {
    refpoints.value = newRefpoints
  },
  { immediate: true, deep: true }
)

// Internal groups for v-model
const internalGroups = ref([...props.groups])

watch(() => props.groups, (newVal) => {
  // Only sync from props if we're not in a loop condition
  if (!isSyncingGroups.value) {
    internalGroups.value = [...newVal]
  }
})

// Only emit group-change on direct user edits, not when syncing from props
watch(internalGroups, (newVal) => {
  if (!isSyncingGroups.value) {
    emit('group-change', newVal)
  }
}, { deep: true })

// Get group key for ListEditor
const getGroupKey = (group) => {
  return group.groupName
}

// Selection handler
const selectGroup = (group) => {
  const selectedIndex = internalGroups.value.findIndex((g) => g.groupName === group.groupName)
  emit('group-select', selectedIndex)
}

// Add new group
const onAddGroup = () => {
  const newGroup = {
    groupName: 'New Group',
    category: 'AIRPLANE',
    country: '',
    task: '',
    triggerType: 'IMMEDIATE',
    units: [{ name: '', type: '', quantity: 1, role: '' }],
    placement: { mode: 'BEARING_DISTANCE', reference: 'bullseye', referenceName: '', bearing: 0, distance: 0, x: null, y: null, parking: null, referenceName: '', waypointGroup: '', waypointNumber: 1 },
    route: [{ type: 'orbit', altitude: 3000, speed: 500 }]
  }
  internalGroups.value.push(newGroup)
  emit('add-group', newGroup)
}

// Update group
const onGroupUpdate = (updatedGroup) => {
  const index = internalGroups.value.findIndex((g) => g.groupName === updatedGroup.groupName)
  if (index !== -1) {
    internalGroups.value[index] = updatedGroup
  }
}

// Delete group
const onDeleteGroup = (groupName) => {
  internalGroups.value = internalGroups.value.filter((g) => g.groupName !== groupName)
  emit('group-delete', internalGroups.value)
}

// Close editor
const closeEditor = () => {
  // Reset selection
  emit('group-select', -1)
}

// Category helpers
const getCategoryLabel = (category) => {
  const labelMap = {
    'AIRPLANE': 'Air',
    'HELICOPTER': 'Helo',
    'GROUND': 'Ground',
    'SHIP': 'Naval',
    'STATIONARY': 'Static'
  }
  return labelMap[category] || category
}

const getCategoryBadge = (category) => {
  const badgeMap = {
    'Air': 'primary',
    'Helo': 'info',
    'Ground': 'success',
    'Naval': 'info',
    'Static': 'primary'
  }
  return badgeMap[category] || 'primary'
}

// Expose methods for external control
defineExpose({
  setSyncing(syncing) {
    isSyncingGroups.value = syncing
    listEditorRef.value?.setSyncing(syncing)
  }
})
</script>

<style scoped>
/* Override ListEditor styles for GroupManager-specific look */
.group-list-item {
  display: flex;
  flex-direction: column;
  width: 100%;
}

.group-list-item-header {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-xs);
}

.group-list-item-header h4 {
  font-size: var(--font-size-md);
  color: var(--color-text-0);
  margin: 0;
  font-weight: var(--font-weight-medium);
}

.group-list-item-meta {
  display: flex;
  gap: var(--spacing-xs);
  flex-wrap: wrap;
}

.group-list-item-meta .badge {
  margin: 0;
}
</style>
