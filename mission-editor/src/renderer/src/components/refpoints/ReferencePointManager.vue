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
  gap: var(--spacing-xs);
  margin-bottom: var(--spacing-md);
}

.tab-btn {
  background: var(--color-bg-2);
  color: var(--color-text-0);
  border: 1px solid var(--color-border);
  padding: var(--spacing-xs) var(--spacing-sm);
  border-radius: var(--spacing-xxs) var(--spacing-xxs) 0 0;
  cursor: pointer;
  font-size: var(--font-size-sm);
  flex: 1;
  text-align: center;
  transition: all var(--transition-fast);
}

.tab-btn:hover {
  background: var(--color-bg-3);
}

.tab-btn.active {
  background: var(--color-bg-1);
  border-bottom: 1px solid var(--color-bg-1);
  color: var(--color-text-4);
  font-weight: var(--font-weight-semibold);
}

.refpoint-content {
  min-height: 200px;
}
</style>
