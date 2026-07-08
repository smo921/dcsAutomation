<template>
  <div class="refpoint-editor zone-editor">
    <div class="editor-header">
      <h3>Trigger Zones</h3>
      <Button @click="showAddModal = true" variant="primary">
        <span>+</span> Add Zone
      </Button>
    </div>

    <EmptyState v-if="zones.length === 0">
      <p>No trigger zones configured.</p>
      <p class="note">Zones are defined in the DCS Mission Editor. Enter the zone name here to reference it.</p>
    </EmptyState>

    <div v-for="(zone, index) in zones" :key="index" class="item-row">
      <div class="item-header">
        <FormInput
          v-model="zone.name"
          placeholder="Zone Name"
        />
        <Button variant="danger" size="sm" @click="removeZone(index)">
          <span class="btn-remove-icon">✕</span>
        </Button>
      </div>
    </div>

    <Modal v-model:open="showAddModal" title="Add Trigger Zone" close-text="Cancel">
      <template #content>
        <div class="input-group">
          <FormLabel label="Zone Name" required />
          <FormInput
            v-model="newZoneName"
            placeholder="e.g., MY_ZONE"
          />
        </div>
      </template>
      <template #actions>
        <Button @click="addZone" variant="primary">Add Zone</Button>
      </template>
    </Modal>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { Modal, Button, FormInput } from '../ui'

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
