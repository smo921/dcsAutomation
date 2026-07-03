<template>
  <div class="refpoint-editor bullseye-editor">
    <div class="editor-header">
      <h3>Bullseye Reference</h3>
      <button class="btn-add" @click="showAddModal = true">
        <span>+</span> Add Bullseye
      </button>
    </div>

    <div v-if="bullseyes.length === 0" class="empty-state">
      <p>No bullseye configured. Click "Add Bullseye" to create one.</p>
    </div>

    <div v-for="(bullseye, index) in bullseyes" :key="index" class="bullseye-item">
      <div class="bullseye-header">
        <input
          type="text"
          v-model="bullseye.name"
          placeholder="Bullseye Name"
          class="name-input"
        />
        <button class="btn-remove" @click="removeBullseye(index)">✕</button>
      </div>

      <div class="coordinate-inputs">
        <div class="input-group">
          <label>X Coordinate</label>
          <input
            type="number"
            v-model="bullseye.x"
            placeholder="e.g., 123456"
            class="coord-input"
          />
        </div>

        <div class="input-group">
          <label>Y Coordinate</label>
          <input
            type="number"
            v-model="bullseye.y"
            placeholder="e.g., 654321"
            class="coord-input"
          />
        </div>
      </div>
    </div>

    <div v-if="showAddModal" class="modal-overlay" @click.self="showAddModal = false">
      <div class="modal-content">
        <h4>Add Bullseye Reference</h4>
        <div class="modal-body">
          <div class="input-group">
            <label>Name</label>
            <input
              type="text"
              v-model="newBullseyeName"
              placeholder="e.g., BULLSEYE_1"
              class="name-input"
              @keyup.enter="addBullseye"
              autofocus
            />
          </div>
          <div class="input-group">
            <label>X Coordinate</label>
            <input
              type="number"
              v-model="newBullseyeX"
              placeholder="e.g., 123456"
              class="coord-input"
            />
          </div>
          <div class="input-group">
            <label>Y Coordinate</label>
            <input
              type="number"
              v-model="newBullseyeY"
              placeholder="e.g., 654321"
              class="coord-input"
            />
          </div>
        </div>
        <div class="modal-actions">
          <button class="btn-cancel" @click="showAddModal = false">Cancel</button>
          <button class="btn-add-modal" @click="addBullseye">Add Bullseye</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'

const store = useRefpointsStore()

const bullseyes = ref(store.bullseyes)
const showAddModal = ref(false)
const newBullseyeName = ref('')
const newBullseyeX = ref(0)
const newBullseyeY = ref(0)

const emit = defineEmits(['update'])

const addBullseye = () => {
  if (newBullseyeName.value.trim()) {
    store.addBullseye(newBullseyeName.value.trim(), newBullseyeX.value, newBullseyeY.value)
    newBullseyeName.value = ''
    newBullseyeX.value = 0
    newBullseyeY.value = 0
    showAddModal.value = false
    emit('update')
  }
}

const removeBullseye = (index) => {
  store.removeBullseye(index)
  emit('update')
}

watch(() => store.bullseyes, (newVal) => {
  bullseyes.value = newVal
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

.bullseye-item {
  background: #252526;
  padding: 12px;
  border-radius: 4px;
  margin-bottom: 8px;
}

.bullseye-header {
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

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: #252526;
  border: 1px solid #454545;
  border-radius: 4px;
  padding: 20px;
  min-width: 300px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5);
}

.modal-content h4 {
  font-size: 16px;
  margin-bottom: 16px;
  color: #ffffff;
}

.modal-body {
  margin-bottom: 16px;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}

.btn-cancel {
  background: #3c3c3c;
  color: #d4d4d4;
  border: 1px solid #454545;
  padding: 6px 12px;
  border-radius: 3px;
  cursor: pointer;
  font-size: 12px;
}

.btn-cancel:hover {
  background: #454545;
}

.btn-add-modal {
  background: #2d5a8e;
  color: white;
  border: none;
  padding: 6px 12px;
  border-radius: 3px;
  cursor: pointer;
  font-size: 12px;
}

.btn-add-modal:hover {
  background: #3d6ebf;
}
</style>
