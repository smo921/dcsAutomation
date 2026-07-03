<template>
  <div class="refpoint-editor battleline-editor">
    <div class="editor-header">
      <h3>Battle Lines</h3>
      <button class="btn-add" @click="addLine">
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
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'

const store = useRefpointsStore()

const lines = ref(store.lines)

const emit = defineEmits(['update'])

const addLine = () => {
  const name = prompt('Line Name:', `Line_${store.lines.length + 1}`)
  if (name) {
    store.addLine(name, 0, 0, 0, 0)
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
  padding: 12px;
  background: #1e1e1e;
  border-radius: 4px;
}

.editor-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.editor-header h3 {
  font-size: 14px;
}

.btn-add {
  background: #2d5a8e;
  color: white;
  border: none;
  padding: 4px 8px;
  border-radius: 3px;
  cursor: pointer;
  font-size: 11px;
  display: flex;
  align-items: center;
  gap: 4px;
}

.btn-add:hover {
  background: #3d6ebf;
}

.empty-state {
  padding: 20px;
  text-align: center;
  color: #888;
  font-size: 13px;
}

.line-item {
  background: #252526;
  padding: 12px;
  border-radius: 4px;
  margin-bottom: 8px;
}

.line-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.name-input {
  background: #3c3c3c;
  border: 1px solid #454545;
  color: white;
  padding: 6px;
  border-radius: 3px;
  flex: 1;
  margin-right: 8px;
}

.btn-remove {
  background: #a31313;
  color: white;
  border: none;
  width: 24px;
  height: 24px;
  border-radius: 3px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-remove:hover {
  background: #c41616;
}

.coordinate-inputs {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}

.input-group label {
  display: block;
  font-size: 11px;
  color: #aaa;
  margin-bottom: 4px;
}

.coord-input {
  width: 100%;
  background: #3c3c3c;
  border: 1px solid #454545;
  color: white;
  padding: 6px;
  border-radius: 3px;
}
</style>
