<template>
  <div class="refpoint-editor zone-editor">
    <div class="editor-header">
      <h3>Trigger Zones</h3>
      <button class="btn-add" @click="addZone">
        <span>+</span> Add Zone
      </button>
    </div>

    <div v-if="zones.length === 0" class="empty-state">
      <p>No trigger zones configured.</p>
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

      <div class="coordinate-inputs">
        <div class="input-group">
          <label>Center X</label>
          <input
            type="number"
            v-model="zone.centerX"
            placeholder="e.g., 150000"
            class="coord-input"
          />
        </div>

        <div class="input-group">
          <label>Center Y</label>
          <input
            type="number"
            v-model="zone.centerY"
            placeholder="e.g., 650000"
            class="coord-input"
          />
        </div>

        <div class="input-group">
          <label>Radius (m)</label>
          <input
            type="number"
            v-model="zone.radius"
            placeholder="e.g., 5000"
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

const zones = ref(store.zones)

const emit = defineEmits(['update'])

const addZone = () => {
  const name = prompt('Zone Name:', `Zone_${store.zones.length + 1}`)
  if (name) {
    store.addZone(name, 0, 0, 5000)
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

.coordinate-inputs {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
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
