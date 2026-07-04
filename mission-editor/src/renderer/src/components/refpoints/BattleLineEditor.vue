<template>
  <div class="refpoint-editor battleline-editor">
    <div class="editor-header">
      <h3>Battle Lines</h3>
      <button class="btn-add" @click="showAddModal = true">
        <span>+</span> Add Line
      </button>
    </div>

    <div v-if="lines.length === 0" class="empty-state">
      <p>No battle lines configured.</p>
    </div>

    <div v-for="(line, index) in lines" :key="index" class="line-item">
      <div class="line-header">
        <input
          type="text"
          v-model="line.name"
          placeholder="Line Name"
          class="name-input"
        />
        <button class="btn-remove" @click="removeLine(index)">✕</button>
      </div>

      <div class="coordinate-inputs">
        <div class="input-group">
          <label>Start X</label>
          <input
            type="number"
            v-model="line.startX"
            placeholder="e.g., 100000"
            class="coord-input"
          />
        </div>

        <div class="input-group">
          <label>Start Y</label>
          <input
            type="number"
            v-model="line.startY"
            placeholder="e.g., 600000"
            class="coord-input"
          />
        </div>

        <div class="input-group">
          <label>End X</label>
          <input
            type="number"
            v-model="line.endX"
            placeholder="e.g., 200000"
            class="coord-input"
          />
        </div>

        <div class="input-group">
          <label>End Y</label>
          <input
            type="number"
            v-model="line.endY"
            placeholder="e.g., 700000"
            class="coord-input"
          />
        </div>
      </div>
    </div>

    <Modal v-model:open="showAddModal" title="Add Battle Line" close-text="Cancel">
      <template #content>
        <div class="input-group">
          <label>Name</label>
          <input
            type="text"
            v-model="newLineName"
            placeholder="e.g., Line_1"
            class="name-input"
            @keyup.enter="addLine"
            autofocus
          />
        </div>
        <div class="input-group">
          <label>Start X</label>
          <input
            type="number"
            v-model="newLineStartX"
            placeholder="e.g., 100000"
            class="coord-input"
          />
        </div>
        <div class="input-group">
          <label>Start Y</label>
          <input
            type="number"
            v-model="newLineStartY"
            placeholder="e.g., 600000"
            class="coord-input"
          />
        </div>
        <div class="input-group">
          <label>End X</label>
          <input
            type="number"
            v-model="newLineEndX"
            placeholder="e.g., 200000"
            class="coord-input"
          />
        </div>
        <div class="input-group">
          <label>End Y</label>
          <input
            type="number"
            v-model="newLineEndY"
            placeholder="e.g., 700000"
            class="coord-input"
          />
        </div>
      </template>
      <template #actions>
        <button class="btn-add-modal" @click="addLine">Add Line</button>
      </template>
    </Modal>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { Modal } from '../ui'

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
.refpoint-editor {
  padding: var(--spacing-md);
  background: var(--color-bg-0);
  border-radius: var(--spacing-xs);
}

.editor-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: var(--spacing-md);
}

.editor-header h3 {
  font-size: var(--font-size-lg);
}

.btn-add {
  background: var(--color-primary);
  color: white;
  border: none;
  padding: var(--spacing-xs) var(--spacing-sm);
  border-radius: var(--spacing-xxs);
  cursor: pointer;
  font-size: var(--font-size-xxs);
  display: flex;
  align-items: center;
  gap: var(--spacing-xs);
}

.btn-add:hover {
  background: var(--color-primary-hover);
}

.empty-state {
  padding: var(--spacing-lg);
  text-align: center;
  color: var(--color-text-1);
  font-size: var(--font-size-sm);
}

.line-item {
  background: var(--color-bg-1);
  padding: var(--spacing-md);
  border-radius: var(--spacing-xs);
  margin-bottom: var(--spacing-xs);
}

.line-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: var(--spacing-xs);
}

.name-input {
  background: var(--color-bg-2);
  border: 1px solid var(--color-border);
  color: var(--color-text-4);
  padding: var(--spacing-xs);
  border-radius: var(--spacing-xxs);
  flex: 1;
  margin-right: var(--spacing-sm);
}

.btn-remove {
  background: var(--color-error);
  color: white;
  border: none;
  width: 24px;
  height: 24px;
  border-radius: var(--spacing-xxs);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-remove:hover {
  background: var(--color-error-hover);
}

.coordinate-inputs {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--spacing-xs);
}

.input-group label {
  display: block;
  font-size: var(--font-size-xxs);
  color: var(--color-text-3);
  margin-bottom: var(--spacing-xs);
}

.coord-input {
  width: 100%;
  background: var(--color-bg-2);
  border: 1px solid var(--color-border);
  color: var(--color-text-4);
  padding: var(--spacing-xs);
  border-radius: var(--spacing-xxs);
}

.input-group {
  margin-bottom: var(--spacing-md);
}
</style>
