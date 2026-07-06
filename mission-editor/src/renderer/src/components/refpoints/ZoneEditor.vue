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
      <p class="note">Zones are defined in the DCS Mission Editor. Enter the zone name here to reference it.</p>
    </div>

    <div v-for="(zone, index) in zones" :key="index" class="item-row">
      <div class="item-header">
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
/* Uses shared .refpoint-editor class from components.css */
</style>
