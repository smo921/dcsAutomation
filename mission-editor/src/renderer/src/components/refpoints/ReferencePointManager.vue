<template>
  <div class="refpoint-manager">
    <div class="refpoint-tabs">
      <button
        v-for="tab in tabs"
        :key="tab.name"
        :class="['tab-btn', { active: activeTab === tab.name }]"
        @click="activeTab = tab.name"
      >
        {{ tab.label }}
      </button>
    </div>

    <div class="refpoint-content">
      <component
        :is="currentComponent"
        ref="activeEditorRef"
        @update="handleChildUpdate"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, toRaw } from 'vue'
import BullseyeEditor from './BullseyeEditor.vue'
import AirbaseEditor from './AirbaseEditor.vue'
import ZoneEditor from './ZoneEditor.vue'
import BattleLineEditor from './BattleLineEditor.vue'
import { useRefpointsStore } from '../../stores/refpoints'

const store = useRefpointsStore()

const activeTab = ref('bullseye')
const activeEditorRef = ref(null)
let saveTimeout = null

const tabs = [
  { name: 'bullseye', label: 'Bullseye' },
  { name: 'airbase', label: 'Airbases' },
  { name: 'zone', label: 'Zones' },
  { name: 'line', label: 'Battle Lines' }
]

const currentComponent = computed(() => {
  const componentMap = {
    'bullseye': BullseyeEditor,
    'airbase': AirbaseEditor,
    'zone': ZoneEditor,
    'line': BattleLineEditor
  }
  return componentMap[activeTab.value]
})

const emit = defineEmits(['update'])

// Relay updates from child components
const handleChildUpdate = () => {
  emit('update')
}

// Load from config on mount
const loadConfig = () => {
  window.api?.refpoints?.load?.().then(config => {
    if (config) {
      store.loadFromConfig(config)
    }
  })
}

// Save config when update is triggered
const saveConfig = () => {
  const config = JSON.parse(JSON.stringify(store.toConfig()))
  window.api?.refpoints?.save?.(config)
}

// Watch for changes and auto-save
watch(() => store.toConfig(), (newConfig) => {
  // Debounce save - would be better with a proper debounce function
  clearTimeout(saveTimeout)
  saveTimeout = setTimeout(() => {
    saveConfig()
  }, 500)
}, { deep: true })

// Initialize
loadConfig()
</script>

<style scoped>
.refpoint-manager {
  width: 100%;
}

.refpoint-tabs {
  display: flex;
  gap: 4px;
  margin-bottom: 12px;
}

.tab-btn {
  background: #3c3c3c;
  color: #d4d4d4;
  border: 1px solid #454545;
  padding: 6px 12px;
  border-radius: 3px 3px 0 0;
  cursor: pointer;
  font-size: 12px;
  flex: 1;
  text-align: center;
  transition: all 0.2s;
}

.tab-btn:hover {
  background: #454545;
}

.tab-btn.active {
  background: #252526;
  border-bottom: 1px solid #252526;
  color: #ffffff;
  font-weight: 600;
}

.refpoint-content {
  min-height: 200px;
}
</style>
