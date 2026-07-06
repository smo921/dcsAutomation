<template>
  <div class="refpoint-editor zone-editor">
    <div class="editor-header">
      <h3>Trigger Zones</h3>
      <button class="btn-add" @click="showAddModal = true">
        <span>+</span> Add Zone
      </button>
    </div>

    <div v-if="zones.length === 0" class="empty-state">
      <p>No trigger zones configured.</p>
      <p class="note"> Zones are defined in the DCS Mission Editor. Enter the zone name here to reference it.</p>
    </div>

    <div v-for="(zone, index) in zones" :key="index" class="zone-item">
      <div class="zone-header">
        <input
          type="text"
          v-model="zone.name"
          placeholder="Zone Name"
          class="name-input"
        />
        <button class="btn-remove" @click="removeZone(index)">
          <span class="btn-remove-icon">✕</span>
        </button>
      </div>
    </div>

    <Modal v-model:open="showAddModal" title="Add Trigger Zone" close-text="Cancel">
      <template #content>
        <div class="input-group">
          <label>Zone Name (from DCS Mission Editor)</label>
          <input
            type="text"
            v-model="newZoneName"
            placeholder="e.g., MY_ZONE"
            class="name-input"
            @keyup.enter="addZone"
            autofocus
          />
        </div>
      </template>
      <template #actions>
        <button class="btn-add-modal" @click="addZone">Add Zone</button>
      </template>
    </Modal>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { Modal } from '../ui'

const store = useRefpointsStore()

const zones = ref(store.zones)
const showAddModal = ref(false)
const newZoneName = ref('')

const emit = defineEmits(['update'])

const addZone = () => {
  if (newZoneName.value.trim()) {
    store.addZone(newZoneName.value.trim())
    newZoneName.value = ''
    showAddModal.value = false
    emit('update')
  }
}

const removeZone = (index) => {
  store.removeZone(index)
  emit('update')
}

watch(() => store.zones, (newVal) => {
  zones.value = newVal
}, { deep: true })
</script>

<style scoped>
.refpoint-editor {
  padding: var(--spacing-md);
  background: var(--color-bg-0);
  border-radius: var(--spacing-xs);
}

.editor-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: var(--spacing-md);
}

.editor-header h3 {
  font-size: var(--font-size-lg);
}

.btn-add {
  background: var(--color-primary);
  color: white;
  border: none;
  padding: var(--spacing-xs) var(--spacing-sm);
  border-radius: var(--spacing-xxs);
  cursor: pointer;
  font-size: var(--font-size-xxs);
  display: flex;
  align-items: center;
  gap: var(--spacing-xs);
}

.btn-add:hover {
  background: var(--color-primary-hover);
}

.empty-state {
  padding: var(--spacing-lg);
  text-align: center;
  color: var(--color-text-1);
  font-size: var(--font-size-sm);
}

.empty-state .note {
  font-size: var(--font-size-xxs);
  color: var(--color-text-2);
  font-style: italic;
  margin-top: var(--spacing-xs);
}

.zone-item {
  background: var(--color-bg-1);
  padding: var(--spacing-md);
  border-radius: var(--spacing-xs);
  margin-bottom: var(--spacing-xs);
}

.zone-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: var(--spacing-xs);
}

.name-input {
  background: var(--color-bg-2);
  border: 1px solid var(--color-border);
  color: var(--color-text-4);
  padding: var(--spacing-xs);
  border-radius: var(--spacing-xxs);
  flex: 1;
  margin-right: var(--spacing-sm);
}

.btn-remove {
  background: var(--color-error);
  color: white;
  border: none;
  width: 24px;
  height: 24px;
  border-radius: var(--spacing-xxs);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-remove:hover {
  background: var(--color-error-hover);
}

.input-group label {
  display: block;
  font-size: var(--font-size-xxs);
  color: var(--color-text-3);
  margin-bottom: var(--spacing-xs);
}

.input-group {
  margin-bottom: var(--spacing-md);
}
</style>
