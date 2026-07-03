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
      <p class="note"> Zones are defined in the DCS Mission Editor. Enter the zone name here to reference it.</p>
    </div>

    <div v-for="(zone, index) in zones" :key="index" class="zone-item">
      <div class="zone-header">
        <input
          type="text"
          v-model="zone.name"
          placeholder="Zone Name"
          class="name-input"
        />
        <button class="btn-remove" @click="removeZone(index)">✕</button>
      </div>
    </div>

    <div v-if="showAddModal" class="modal-overlay" @click.self="showAddModal = false">
      <div class="modal-content">
        <h4>Add Trigger Zone</h4>
        <div class="modal-body">
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
        </div>
        <div class="modal-actions">
          <button class="btn-cancel" @click="showAddModal = false">Cancel</button>
          <button class="btn-add-modal" @click="addZone">Add Zone</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'

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

.empty-state .note {
  font-size: 11px;
  color: #666;
  font-style: italic;
  margin-top: 8px;
}

.zone-item {
  background: #252526;
  padding: 12px;
  border-radius: 4px;
  margin-bottom: 8px;
}

.zone-header {
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

.input-group label {
  display: block;
  font-size: 11px;
  color: #aaa;
  margin-bottom: 4px;
}

.name-input {
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
