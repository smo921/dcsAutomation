<template>
  <div class="refpoint-editor bullseye-editor">
    <div class="editor-header">
      <h3>Bullseye Reference</h3>
      <button class="btn-add" @click="showAddModal = true">
        <span>+</span> Add Bullseye
      </button>
    </div>

    <div v-if="bullseyes.length === 0" class="empty-state">
      <p>No bullseye configured. Click "Add Bullseye" to create one.</p>
      <p class="note">Bullseye coordinates are determined dynamically at runtime from DCS coalition data.</p>
    </div>

    <div v-for="(bullseye, index) in bullseyes" :key="index" class="bullseye-item">
      <div class="bullseye-header">
        <input
          type="text"
          v-model="bullseye.name"
          placeholder="Bullseye Name"
          class="name-input"
          :list="bullseyeSuggestions"
        />
        <button class="btn-remove" @click="removeBullseye(index)">
          <span class="btn-remove-icon">✕</span>
        </button>
      </div>
      <datalist :id="bullseyeSuggestions">
        <option value="Red" />
        <option value="Blue" />
        <option value="Neutral" />
      </datalist>
    </div>

    <Modal v-model:open="showAddModal" title="Add Bullseye Reference" close-text="Cancel">
      <template #content>
        <div class="input-group">
          <label>Name</label>
          <select
            v-model="newBullseyeName"
            class="name-input"
            @keyup.enter="addBullseye"
            autofocus
          >
            <option value="">Select a coalition...</option>
            <option value="Red">Red</option>
            <option value="Blue">Blue</option>
            <option value="Neutral">Neutral</option>
          </select>
        </div>
      </template>
      <template #actions>
        <button class="btn-add-modal" @click="addBullseye">Add Bullseye</button>
      </template>
    </Modal>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { Modal } from '../ui'

const store = useRefpointsStore()

const bullseyes = ref(store.bullseyes)
const showAddModal = ref(false)
const newBullseyeName = ref('')
const bullseyeSuggestions = 'bullseyeSuggestions'

const emit = defineEmits(['update'])

const addBullseye = () => {
  if (newBullseyeName.value.trim()) {
    store.addBullseye(newBullseyeName.value.trim())
    newBullseyeName.value = ''
    showAddModal.value = false
    emit('update')
  }
}

const removeBullseye = (index) => {
  store.removeBullseye(index)
  emit('update')
}

watch(() => store.bullseyes, (newVal) => {
  bullseyes.value = newVal
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
  margin-top: var(--spacing-xs);
}

.bullseye-item {
  background: var(--color-bg-1);
  padding: var(--spacing-md);
  border-radius: var(--spacing-xs);
  margin-bottom: var(--spacing-xs);
}

.bullseye-header {
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

/* Input group label */
.input-group label {
  display: block;
  font-size: var(--font-size-xxs);
  color: var(--color-text-3);
  margin-bottom: var(--spacing-xs);
}

/* Reusing existing modal styles for consistency */
.input-group {
  margin-bottom: var(--spacing-md);
}
</style>
