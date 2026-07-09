<template>
  <BaseReferenceEditor
    ref="baseEditor"
    v-model:items="bullseyes"
    title="Bullseye Reference"
    addButtonText="Add Bullseye"
    emptyStateText="No bullseye configured. Click 'Add Bullseye' to create one."
    emptyStateNote="Bullseye coordinates are determined dynamically at runtime from DCS coalition data."
    addModalTitle="Add Bullseye Reference"
    namePlaceholder="Select a coalition..."
    @add="handleAdd"
    @update="emitUpdate"
  >
    <template #addModalFields>
      <div class="input-group">
        <FormLabel label="Name" required />
        <FormSelect
          v-model="newItemName"
          :options="coalitionOptions"
          placeholder="Select a coalition..."
        />
      </div>
    </template>
  </BaseReferenceEditor>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { FormSelect, BaseReferenceEditor } from '../ui'

const store = useRefpointsStore()

const bullseyes = ref(store.bullseyes)
const newItemName = ref('')

const coalitionOptions = computed(() => [
  { value: 'Red', label: 'Red' },
  { value: 'Blue', label: 'Blue' },
  { value: 'Neutral', label: 'Neutral' }
])

const emit = defineEmits(['update'])

const emitUpdate = () => {
  emit('update')
}

const handleAdd = (name) => {
  if (name.trim()) {
    store.addBullseye(name.trim())
    emit('update')
  }
}

watch(() => store.bullseyes, (newVal) => {
  bullseyes.value = newVal
}, { deep: true })
</script>

<style scoped>
/* Uses shared .refpoint-editor class from components.css */
</style>
