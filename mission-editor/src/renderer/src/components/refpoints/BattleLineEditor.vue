<template>
  <BaseReferenceEditor
    v-model:items="lines"
    title="Battle Lines"
    addButtonText="Add Line"
    emptyStateText="No battle lines configured."
    addModalTitle="Add Battle Line"
    namePlaceholder="e.g., Line_1"
    @add="handleAdd"
    @update="emitUpdate"
  >
    <template #customFields="{ item, index }">
      <div class="coordinate-inputs">
        <div class="input-group">
          <FormLabel label="Start X" />
          <FormInput
            v-model="item.startX"
            type="number"
            placeholder="e.g., 100000"
          />
        </div>

        <div class="input-group">
          <FormLabel label="Start Y" />
          <FormInput
            v-model="item.startY"
            type="number"
            placeholder="e.g., 600000"
          />
        </div>

        <div class="input-group">
          <FormLabel label="End X" />
          <FormInput
            v-model="item.endX"
            type="number"
            placeholder="e.g., 200000"
          />
        </div>

        <div class="input-group">
          <FormLabel label="End Y" />
          <FormInput
            v-model="item.endY"
            type="number"
            placeholder="e.g., 700000"
          />
        </div>
      </div>
    </template>

    <template #addModalFields>
      <div class="input-group">
        <FormLabel label="Name" required />
        <FormInput
          v-model="newItemName"
          placeholder="e.g., Line_1"
        />
      </div>
      <div class="input-group">
        <FormLabel label="Start X" />
        <FormInput
          v-model="newLineStartX"
          type="number"
          placeholder="e.g., 100000"
        />
      </div>
      <div class="input-group">
        <FormLabel label="Start Y" />
        <FormInput
          v-model="newLineStartY"
          type="number"
          placeholder="e.g., 600000"
        />
      </div>
      <div class="input-group">
        <FormLabel label="End X" />
        <FormInput
          v-model="newLineEndX"
          type="number"
          placeholder="e.g., 200000"
        />
      </div>
      <div class="input-group">
        <FormLabel label="End Y" />
        <FormInput
          v-model="newLineEndY"
          type="number"
          placeholder="e.g., 700000"
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

const lines = ref(store.lines)
const newItemName = ref('')
const newLineStartX = ref(0)
const newLineStartY = ref(0)
const newLineEndX = ref(0)
const newLineEndY = ref(0)

const emit = defineEmits(['update'])

const emitUpdate = () => {
  emit('update')
}

const handleAdd = (name) => {
  if (name.trim()) {
    store.addLine(
      name.trim(),
      newLineStartX.value,
      newLineStartY.value,
      newLineEndX.value,
      newLineEndY.value
    )
    newItemName.value = ''
    newLineStartX.value = 0
    newLineStartY.value = 0
    newLineEndX.value = 0
    newLineEndY.value = 0
    emit('update')
  }
}

watch(() => store.lines, (newVal) => {
  lines.value = newVal
}, { deep: true })
</script>

<style scoped>
/* Uses shared .refpoint-editor class from components.css */
/* All input styles use shared .form-input from components.css */
</style>
