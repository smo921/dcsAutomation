<template>
  <Modal
    v-model:open="isOpen"
    title="Add Reference Points from Terrain"
    size="lg"
    :closeOnBackground="true"
  >
    <template #content>
      <div class="terrain-selector-content">
        <!-- Tab selection -->
        <div class="terrain-tabs">
          <button
            v-for="tab in tabs"
            :key="tab.value"
            :class="['terrain-tab', { active: activeTab === tab.value }]"
            @click="activeTab = tab.value"
          >
            {{ tab.label }}
          </button>
        </div>

        <!-- Airbases tab -->
        <div v-if="activeTab === 'airbases'" class="terrain-tab-content">
          <div class="terrain-toolbar">
            <FormInput
              v-model="airbaseSearch"
              placeholder="Search airbases..."
              class="terrain-search"
            />
          </div>
          <div class="terrain-list">
            <div
              v-for="airbase in filteredAirbases"
              :key="airbase.airdromeId"
              :class="['terrain-item', {
                selected: isAirbaseSelectedInSession(airbase),
                'already-added': isAlreadyInStore(airbase)
              }]"
              @click="toggleAirbase(airbase)"
            >
              <div class="terrain-item-name">
                {{ airbase.name }}
                <span v-if="airbase.matchedTown" class="item-subtitle">
                  (matched: {{ airbase.matchedTown }})
                </span>
              </div>
              <div class="terrain-item-meta">
                <span class="terrain-item-coords">
                  X: {{ Math.round(airbase.x) }}, Y: {{ Math.round(airbase.y) }}
                </span>
                <Badge v-if="isAlreadyInStore(airbase)" variant="info">In mission</Badge>
                <Badge v-else-if="isAirbaseSelectedInSession(airbase)" variant="success">Selected</Badge>
              </div>
            </div>
            <div v-if="filteredAirbases.length === 0" class="empty-state">
              <p>No airbases found. Make sure to import a MIZ file first.</p>
            </div>
          </div>
        </div>

        <!-- Towns tab -->
        <div v-if="activeTab === 'towns'" class="terrain-tab-content">
          <div class="terrain-toolbar">
            <FormInput
              v-model="townSearch"
              placeholder="Search towns..."
              class="terrain-search"
            />
          </div>
          <div class="terrain-list">
            <div
              v-for="[townName, townData] in filteredTowns"
              :key="townName"
              :class="['terrain-item', {
                selected: isTownSelectedInSession(townName),
                'already-added': isTownInStore(townName)
              }]"
              @click="toggleTown(townName, townData)"
            >
              <div class="terrain-item-name">
                {{ townName }}
              </div>
              <div class="terrain-item-meta">
                <span class="terrain-item-coords">
                  X: {{ Math.round(computeTownCoords(townData).x) }}, Y: {{ Math.round(computeTownCoords(townData).y) }}
                </span>
                <Badge v-if="isTownInStore(townName)" variant="info">In mission</Badge>
                <Badge v-else-if="isTownSelectedInSession(townName)" variant="success">Selected</Badge>
              </div>
            </div>
            <div v-if="filteredTowns.length === 0" class="empty-state">
              <p>No towns found. Make sure to import a MIZ file first.</p>
            </div>
          </div>
        </div>
      </div>
    </template>

    <template #actions>
      <div class="terrain-actions">
        <Button @click="handleClose" variant="secondary">Cancel</Button>
        <Button @click="handleAdd" variant="primary">Add Selected ({{ selectedCount }})</Button>
      </div>
    </template>
  </Modal>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'
import { Modal, Button, Badge, FormInput } from '../ui'
import { latLonToDCS } from '../../utils/coordinateConverter'

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  theater: {
    type: String,
    default: 'Caucasus'
  }
})

const emit = defineEmits(['update:modelValue', 'add-points'])

const store = useRefpointsStore()
const isOpen = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

const tabs = [
  { label: `Airbases (${store.allAirbases?.length || 0})`, value: 'airbases' },
  { label: `Towns (${Object.keys(store.towns || {}).length})`, value: 'towns' }
]

const activeTab = ref('airbases')
const airbaseSearch = ref('')
const townSearch = ref('')
const selectedAirbases = ref(new Set())
const selectedTowns = ref(new Set())

// Clear selection when modal opens/closes
watch(isOpen, (newVal) => {
  if (!newVal) {
    selectedAirbases.value.clear()
    selectedTowns.value.clear()
  }
})

const filteredAirbases = computed(() => {
  const airbases = store.allAirbases || []
  if (!airbaseSearch.value) return airbases
  const search = airbaseSearch.value.toLowerCase()
  return airbases.filter(ab =>
    ab.name?.toLowerCase().includes(search) ||
    ab.matchedTown?.toLowerCase().includes(search)
  )
})

const filteredTowns = computed(() => {
  const towns = store.terrainTowns || {}
  if (!townSearch.value) return Object.entries(towns)
  const search = townSearch.value.toLowerCase()
  return Object.entries(towns).filter(([name]) =>
    name.toLowerCase().includes(search)
  )
})

// Check if already committed to the store (can't be removed)
const isAlreadyInStore = (airbase) => {
  return store.airbases.some(a => a.name === airbase.name)
}

const isTownInStore = (townName) => {
  return store.towns.some(t => t.name === townName)
}

// Check if selected in current session (for visual feedback)
const isAirbaseSelectedInSession = (airbase) => {
  return selectedAirbases.value.has(airbase)
}

const isTownSelectedInSession = (townName) => {
  return selectedTowns.value.has(townName)
}

// Toggle selection for airbases
const toggleAirbase = (airbase) => {
  // Can't remove if already in store
  if (isAlreadyInStore(airbase)) return

  if (isAirbaseSelectedInSession(airbase)) {
    selectedAirbases.value.delete(airbase)
  } else {
    selectedAirbases.value.add(airbase)
  }
}

// Toggle selection for towns
const toggleTown = (townName, townData) => {
  // Can't remove if already in store
  if (isTownInStore(townName)) return

  if (isTownSelectedInSession(townName)) {
    selectedTowns.value.delete(townName)
  } else {
    selectedTowns.value.add(townName)
  }
}

const computeTownCoords = (townData) => {
  return latLonToDCS(townData.latitude, townData.longitude, props.theater)
}

const selectedCount = computed(() => {
  return selectedAirbases.value.size + selectedTowns.value.size
})

const handleClose = () => {
  isOpen.value = false
}

const handleAdd = () => {
  const pointsToAdd = []

  // Add selected airbases (skip those already in store)
  selectedAirbases.value.forEach(airbase => {
    if (!isAlreadyInStore(airbase)) {
      pointsToAdd.push({
        type: 'airbase',
        name: airbase.name,
        x: airbase.x,
        y: airbase.y
      })
    }
  })

  // Add selected towns as town reference points (skip those already in store)
  selectedTowns.value.forEach(townName => {
    if (!isTownInStore(townName)) {
      const townData = store.terrainTowns[townName]
      const coords = computeTownCoords(townData)
      pointsToAdd.push({
        type: 'town',
        name: townName,
        x: coords.x,
        y: coords.y
      })
    }
  })

  emit('add-points', pointsToAdd)
  isOpen.value = false
}
</script>

<style scoped>
.terrain-selector-content {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md);
}

.terrain-tabs {
  display: flex;
  gap: var(--spacing-xs);
  border-bottom: 1px solid var(--color-border);
  padding-bottom: var(--spacing-sm);
}

.terrain-tab {
  padding: var(--spacing-sm) var(--spacing-md);
  background: var(--color-bg-2);
  border: 1px solid var(--color-border);
  border-radius: 4px;
  cursor: pointer;
  font-size: var(--font-size-sm);
  color: var(--color-text-1);
}

.terrain-tab:hover {
  background: var(--color-bg-3);
}

.terrain-tab.active {
  background: var(--color-primary);
  color: white;
  border-color: var(--color-primary);
}

.terrain-tab-content {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-sm);
}

.terrain-toolbar {
  display: flex;
  gap: var(--spacing-sm);
}

.terrain-search {
  flex: 1;
}

.terrain-list {
  max-height: 400px;
  overflow-y: auto;
  border: 1px solid var(--color-border);
  border-radius: 4px;
}

.terrain-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--spacing-sm) var(--spacing-md);
  border-bottom: 1px solid var(--color-border);
  cursor: pointer;
}

.terrain-item:last-child {
  border-bottom: none;
}

.terrain-item:hover {
  background: var(--color-bg-1);
}

.terrain-item.selected {
  background: var(--color-primary);
  color: white;
}

.terrain-item.selected .terrain-item-name,
.terrain-item.selected .terrain-item-coords,
.terrain-item.selected .item-subtitle {
  color: white;
}

.terrain-item.already-added {
  opacity: 0.6;
  cursor: default;
}

.terrain-item.already-added:hover {
  background: var(--color-bg-0);
}

.terrain-item-name {
  font-weight: var(--font-weight-medium);
  color: var(--color-text-0);
}

.item-subtitle {
  font-size: var(--font-size-xs);
  color: var(--color-text-2);
  font-weight: var(--font-weight-normal);
}

.terrain-item-meta {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
}

.terrain-item-coords {
  font-size: var(--font-size-xs);
  color: var(--color-text-2);
  font-family: var(--font-mono);
}

.terrain-actions {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: var(--spacing-sm);
}
</style>
