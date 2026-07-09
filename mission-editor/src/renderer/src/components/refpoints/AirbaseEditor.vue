<template>
  <BaseReferenceEditor
    v-model:items="airbases"
    title="Airbase References"
    addButtonText="Add Airbase"
    emptyStateText="No airbases configured."
    emptyStateNote="Airbase coordinates are resolved via Airbase.getByName() at runtime."
    addModalTitle="Add Airbase Reference"
    namePlaceholder="e.g., Airbase_1"
    @add="handleAdd"
    @update="emitUpdate"
  >
    <template #addModalFields>
      <div class="input-group">
        <FormLabel label="Name" required />
        <FormInput
          v-model="newItemName"
          placeholder="e.g., Airbase_1"
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

const airbases = ref(store.airbases)
const newItemName = ref('')

const emit = defineEmits(['update'])

const emitUpdate = () => {
  emit('update')
}

const handleAdd = (name) => {
  if (name.trim()) {
    store.addAirbase(name.trim())
    emit('update')
  }
}

watch(() => store.airbases, (newVal) => {
  airbases.value = newVal
}, { deep: true })
</script>

<style scoped>
/* Uses shared .refpoint-editor class from components.css */
</style>
