<template>
  <BaseReferenceEditor
    v-model:items="zones"
    title="Trigger Zones"
    addButtonText="Add Zone"
    emptyStateText="No trigger zones configured."
    emptyStateNote="Zones are defined in the DCS Mission Editor. Enter the zone name here to reference it."
    addModalTitle="Add Trigger Zone"
    namePlaceholder="e.g., MY_ZONE"
    @add="handleAdd"
    @update="emitUpdate"
  >
    <template #addModalFields>
      <div class="input-group">
        <FormLabel label="Zone Name" required />
        <FormInput
          v-model="newItemName"
          placeholder="e.g., MY_ZONE"
        />
      </div>
    </template>
  </BaseReferenceEditor>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { FormInput, BaseReferenceEditor } from '../ui'

const store = useRefpointsStore()

const zones = ref(store.zones)
const newItemName = ref('')

const emit = defineEmits(['update'])

const emitUpdate = () => {
  emit('update')
}

const handleAdd = (name) => {
  if (name.trim()) {
    store.addZone(name.trim())
    emit('update')
  }
}

watch(() => store.zones, (newVal) => {
  zones.value = newVal
}, { deep: true })
</script>

<style scoped>
/* Uses shared .refpoint-editor class from components.css */
</style>
