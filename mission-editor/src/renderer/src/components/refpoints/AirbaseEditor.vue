<template>
  <div class="refpoint-editor airbase-editor">
    <div class="editor-header">
      <h3>Airbase References</h3>
      <Button @click="showAddModal = true" variant="primary">
        <span>+</span> Add Airbase
      </Button>
    </div>

    <EmptyState v-if="airbases.length === 0">
      <p>No airbases configured.</p>
      <p class="note">Airbase coordinates are resolved via Airbase.getByName() at runtime.</p>
    </EmptyState>

    <div v-for="(airbase, index) in airbases" :key="index" class="item-row">
      <div class="item-header">
        <FormInput
          v-model="airbase.name"
          placeholder="Airbase Name"
        />
        <Button variant="danger" size="sm" @click="removeAirbase(index)">
          <span class="btn-remove-icon">✕</span>
        </Button>
      </div>
    </div>

    <Modal v-model:open="showAddModal" title="Add Airbase Reference" close-text="Cancel">
      <template #content>
        <div class="input-group">
          <FormLabel label="Name" required />
          <FormInput
            v-model="newAirbaseName"
            placeholder="e.g., Airbase_1"
          />
        </div>
      </template>
      <template #actions>
        <Button @click="addAirbase" variant="primary">Add Airbase</Button>
      </template>
    </Modal>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { Modal, Button, FormInput } from '../ui'

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
/* Uses shared .refpoint-editor class from components.css */
</style>
