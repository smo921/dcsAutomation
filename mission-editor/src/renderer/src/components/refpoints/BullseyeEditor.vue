<template>
  <div class="refpoint-editor bullseye-editor">
    <div class="editor-header">
      <h3>Bullseye Reference</h3>
      <Button @click="showAddModal = true" variant="primary">
        <span>+</span> Add Bullseye
      </Button>
    </div>

    <EmptyState v-if="bullseyes.length === 0">
      <p>No bullseye configured. Click "Add Bullseye" to create one.</p>
      <p class="note">Bullseye coordinates are determined dynamically at runtime from DCS coalition data.</p>
    </EmptyState>

    <div v-for="(bullseye, index) in bullseyes" :key="index" class="item-row">
      <div class="item-header">
        <FormInput
          v-model="bullseye.name"
          placeholder="Bullseye Name"
        />
        <Button variant="danger" size="sm" @click="removeBullseye(index)">
          <span class="btn-remove-icon">✕</span>
        </Button>
      </div>
    </div>

    <Modal v-model:open="showAddModal" title="Add Bullseye Reference" close-text="Cancel">
      <template #content>
        <div class="input-group">
          <FormLabel label="Name" required />
          <FormSelect
            v-model="newBullseyeName"
            :options="coalitionOptions"
            placeholder="Select a coalition..."
          />
        </div>
      </template>
      <template #actions>
        <Button @click="addBullseye" variant="primary">Add Bullseye</Button>
      </template>
    </Modal>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { Modal, Button, FormInput, FormSelect, EmptyState } from '../ui'

const store = useRefpointsStore()

const bullseyes = ref(store.bullseyes)
const showAddModal = ref(false)
const newBullseyeName = ref('')

const coalitionOptions = computed(() => [
  { value: 'Red', label: 'Red' },
  { value: 'Blue', label: 'Blue' },
  { value: 'Neutral', label: 'Neutral' }
])

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
</style>
