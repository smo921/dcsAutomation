<template>
  <div class="refpoint-editor airbase-editor">
    <div class="editor-header">
      <h3>Airbase References</h3>
      <button class="btn-add" @click="showAddModal = true">
        <span>+</span> Add Airbase
      </button>
    </div>

    <div v-if="airbases.length === 0" class="empty-state">
      <p>No airbases configured.</p>
      <p class="note">Airbase coordinates are resolved via Airbase.getByName() at runtime.</p>
    </div>

    <div v-for="(airbase, index) in airbases" :key="index" class="airbase-item">
      <div class="airbase-header">
        <input
          type="text"
          v-model="airbase.name"
          placeholder="Airbase Name"
          class="name-input"
        />
        <button class="btn-remove" @click="removeAirbase(index)">
          <span class="btn-remove-icon">✕</span>
        </button>
      </div>
    </div>

    <Modal v-model:open="showAddModal" title="Add Airbase Reference" close-text="Cancel">
      <template #content>
        <div class="input-group">
          <label>Name</label>
          <input
            type="text"
            v-model="newAirbaseName"
            placeholder="e.g., Airbase_1"
            class="name-input"
            @keyup.enter="addAirbase"
            autofocus
          />
        </div>
      </template>
      <template #actions>
        <button class="btn-add-modal" @click="addAirbase">Add Airbase</button>
      </template>
    </Modal>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { Modal } from '../ui'

const store = useRefpointsStore()

const airbases = ref(store.airbases)
const showAddModal = ref(false)
const newAirbaseName = ref('')

const emit = defineEmits(['update'])

const addAirbase = () => {
  if (newAirbaseName.value.trim()) {
    store.addAirbase(newAirbaseName.value.trim())
    newAirbaseName.value = ''
    showAddModal.value = false
    emit('update')
  }
}

const removeAirbase = (index) => {
  store.removeAirbase(index)
  emit('update')
}

watch(() => store.airbases, (newVal) => {
  airbases.value = newVal
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

.empty-state p {
  font-size: var(--font-size-sm);
  color: var(--color-text-1);
  margin-bottom: var(--spacing-xs);
}

.empty-state .note {
  font-size: var(--font-size-xxs);
  color: var(--color-text-2);
  font-style: italic;
}

.airbase-item {
  background: var(--color-bg-1);
  padding: var(--spacing-md);
  border-radius: var(--spacing-xs);
  margin-bottom: var(--spacing-xs);
}

.airbase-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
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
