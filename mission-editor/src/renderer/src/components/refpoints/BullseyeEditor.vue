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

    <div v-for="(bullseye, index) in bullseyes" :key="index" class="item-row">
      <div class="item-header">
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
/* Uses shared .refpoint-editor class from components.css */
/* Bullseye-specific overrides */
.bullseye-editor .input-group {
  margin-bottom: var(--spacing-md);
}
</style>
