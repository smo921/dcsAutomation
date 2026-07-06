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

    <div v-for="(airbase, index) in airbases" :key="index" class="item-row">
      <div class="item-header">
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
/* Uses shared .refpoint-editor class from components.css */
</style>
