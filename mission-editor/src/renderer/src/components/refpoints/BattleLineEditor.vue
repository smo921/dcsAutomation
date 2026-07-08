<template>
  <div class="refpoint-editor battleline-editor">
    <div class="editor-header">
      <h3>Battle Lines</h3>
      <Button @click="showAddModal = true" variant="primary">
        <span>+</span> Add Line
      </Button>
    </div>

    <EmptyState v-if="lines.length === 0">
      <p>No battle lines configured.</p>
    </EmptyState>

    <div v-for="(line, index) in lines" :key="index" class="item-row">
      <div class="item-header">
        <FormInput
          v-model="line.name"
          placeholder="Line Name"
        />
        <Button variant="danger" size="sm" @click="removeLine(index)">
          <span class="btn-remove-icon">✕</span>
        </Button>
      </div>

      <div class="coordinate-inputs">
        <div class="input-group">
          <FormLabel label="Start X" />
          <FormInput
            v-model="line.startX"
            type="number"
            placeholder="e.g., 100000"
          />
        </div>

        <div class="input-group">
          <FormLabel label="Start Y" />
          <FormInput
            v-model="line.startY"
            type="number"
            placeholder="e.g., 600000"
          />
        </div>

        <div class="input-group">
          <FormLabel label="End X" />
          <FormInput
            v-model="line.endX"
            type="number"
            placeholder="e.g., 200000"
          />
        </div>

        <div class="input-group">
          <FormLabel label="End Y" />
          <FormInput
            v-model="line.endY"
            type="number"
            placeholder="e.g., 700000"
          />
        </div>
      </div>
    </div>

    <Modal v-model:open="showAddModal" title="Add Battle Line" close-text="Cancel">
      <template #content>
        <div class="input-group">
          <FormLabel label="Name" required />
          <FormInput
            v-model="newLineName"
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
      <template #actions>
        <Button @click="addLine" variant="primary">Add Line</Button>
      </template>
    </Modal>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { Modal, Button, FormInput } from '../ui'

const store = useRefpointsStore()

const lines = ref(store.lines)
const showAddModal = ref(false)
const newLineName = ref('')
const newLineStartX = ref(0)
const newLineStartY = ref(0)
const newLineEndX = ref(0)
const newLineEndY = ref(0)

const emit = defineEmits(['update'])

const addLine = () => {
  if (newLineName.value.trim()) {
    store.addLine(
      newLineName.value.trim(),
      newLineStartX.value,
      newLineStartY.value,
      newLineEndX.value,
      newLineEndY.value
    )
    newLineName.value = ''
    newLineStartX.value = 0
    newLineStartY.value = 0
    newLineEndX.value = 0
    newLineEndY.value = 0
    showAddModal.value = false
    emit('update')
  }
}

const removeLine = (index) => {
  store.removeLine(index)
  emit('update')
}

watch(() => store.lines, (newVal) => {
  lines.value = newVal
}, { deep: true })
</script>

<style scoped>
/* Uses shared .refpoint-editor class from components.css */
/* All input styles use shared .form-input from components.css */
</style>
