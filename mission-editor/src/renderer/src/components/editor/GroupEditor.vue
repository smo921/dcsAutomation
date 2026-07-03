<template>
  <div class="group-editor">
    <!-- Basic Settings -->
    <div class="editor-section">
      <h4>Basic Settings</h4>
      <div class="form-row">
        <div class="form-group">
          <label>Group Name</label>
          <input
            type="text"
            v-model="group.name"
            placeholder="e.g., AWACS Patrol Alpha"
            class="form-input"
          />
        </div>
      </div>

      <div class="form-row">
        <div class="form-group">
          <label>Coalition</label>
          <select v-model="group.coalition" class="form-input">
            <option value="blue">Blue</option>
            <option value="red">Red</option>
          </select>
        </div>
        <div class="form-group">
          <label>Country</label>
          <input
            type="text"
            v-model="group.country"
            placeholder="e.g., Russia"
            class="form-input"
          />
        </div>
      </div>
    </div>

    <!-- Unit Configuration -->
    <div class="editor-section">
      <h4>Unit Configuration</h4>
      <div class="form-row">
        <div class="form-group">
          <label>Unit Type</label>
          <select v-model="selectedUnitType" class="form-input">
            <option value="Su-30SM">Su-30SM</option>
            <option value="MiG-29">MiG-29</option>
            <option value="Su-25T">Su-25T</option>
            <option value="A-10C">A-10C</option>
            <option value="F-15C">F-15C</option>
            <option value="IL-78M">IL-78M</option>
            <option value="Ka-50">Ka-50</option>
            <option value="Mi-8MT">Mi-8MT</option>
            <option value="S-300">S-300</option>
            <option value="T-72B3">T-72B3</option>
            <option value="BTR-82">BTR-82</option>
            <option value="ZSU-23-4">ZSU-23-4</option>
            <option value="T-90">T-90</option>
          </select>
        </div>
        <div class="form-group">
          <label>Quantity</label>
          <input
            type="number"
            v-model="group.quantity"
            min="1"
            max="20"
            class="form-input"
          />
        </div>
      </div>
    </div>

    <!-- Position Configuration -->
    <div class="editor-section">
      <h4>Position Configuration</h4>

      <!-- Step 1: Placement Mode -->
      <div class="form-row">
        <div class="form-group">
          <label>Placement Mode</label>
          <select v-model="group.position.mode" class="form-input">
            <option value="offset_bearing">Bearing + Distance</option>
            <option value="offset_direct">Offset Coordinates</option>
            <option value="zone_random">Random Location</option>
            <option value="waypoint">Near Waypoint</option>
          </select>
        </div>
      </div>

      <!-- Reference Type (for offset_bearing, offset_direct, and zone_random) -->
      <div v-if="group.position.mode === 'offset_bearing' || group.position.mode === 'offset_direct' || group.position.mode === 'zone_random'" class="form-row">
        <div class="form-group">
          <label>Reference Type</label>
          <select v-model="group.position.refType" class="form-input">
            <option value="bullseye">Bullseye</option>
            <option value="airbase">Airbase</option>
            <option value="zone">Trigger Zone</option>
          </select>
        </div>
      </div>

      <!-- Reference Name (shared for all reference types) -->
      <div v-if="group.position.refType === 'bullseye'" class="form-group">
        <label>Bullseye Reference</label>
        <select v-model="group.position.referenceName" class="form-input">
          <option v-for="b in refpoints.bullseyes" :key="b.name" :value="b.name">
            {{ b.name }}
          </option>
        </select>
      </div>
      <div v-if="group.position.refType === 'airbase'" class="form-group">
        <label>Airbase</label>
        <select v-model="group.position.referenceName" class="form-input">
          <option v-for="a in refpoints.airbases" :key="a.name" :value="a.name">
            {{ a.name }}
          </option>
        </select>
      </div>
      <div v-if="group.position.refType === 'zone'" class="form-group">
        <label>Zone Name</label>
        <select v-model="group.position.referenceName" class="form-input">
          <option v-for="z in refpoints.zones" :key="z.name" :value="z.name">
            {{ z.name }}
          </option>
        </select>
      </div>

      <!-- Bearing + Distance Configuration -->
      <div v-if="group.position.mode === 'offset_bearing'" class="offset-config">
        <div class="form-row">
          <div class="form-group">
            <label>Bearing (°)</label>
            <input
              type="number"
              v-model="group.position.bearing"
              min="0"
              max="360"
              class="form-input"
            />
          </div>
          <div class="form-group">
            <label>Distance (NM)</label>
            <input
              type="number"
              v-model="group.position.distance"
              min="0"
              class="form-input"
            />
          </div>
        </div>
      </div>

      <!-- Offset Coordinates Configuration -->
      <div v-if="group.position.mode === 'offset_direct'" class="offset-config">
        <div class="form-row">
          <div class="form-group">
            <label>Offset X (NM)</label>
            <input
              type="number"
              v-model="group.position.offsetX"
              class="form-input"
            />
          </div>
          <div class="form-group">
            <label>Offset Y (NM)</label>
            <input
              type="number"
              v-model="group.position.offsetY"
              class="form-input"
            />
          </div>
        </div>
      </div>

      <!-- Random Location (within zone) -->
      <div v-if="group.position.mode === 'zone_random'" class="offset-config">
        <p style="font-size: 11px; color: #888; margin: 0;">Spawns unit at a random location within the selected trigger zone.</p>
      </div>

      <!-- Waypoint Anchoring -->
      <div v-if="group.position.mode === 'waypoint'" class="offset-config">
        <div class="form-group">
          <label>Group Name</label>
          <select v-model="group.position.waypointGroup" class="form-input">
            <option value="">Select existing group...</option>
            <option v-for="a in refpoints.airbases" :key="'wp-' + a.name" :value="a.name">
              {{ a.name }}
            </option>
          </select>
        </div>
        <div class="form-group">
          <label>Waypoint Number</label>
          <input
            type="number"
            v-model="group.position.waypointNumber"
            min="1"
            class="form-input"
          />
        </div>
      </div>
    </div>

    <!-- Airbase & Parking -->
    <div class="editor-section">
      <h4>Airbase & Parking</h4>
      <div class="form-row">
        <div class="form-group">
          <label>Home Airbase</label>
          <select v-model="group.airbase" class="form-input">
            <option v-for="a in refpoints.airbases" :key="a.name" :value="a.name">
              {{ a.name }}
            </option>
          </select>
        </div>
        <div class="form-group">
          <label>Parking</label>
          <select v-model="group.parking" class="form-input">
            <option value="hot_start">Hot Start</option>
            <option value="cold_start">Cold Start</option>
            <option value="parking_slot">Parking Slot</option>
          </select>
        </div>
      </div>
      <div v-if="group.parking === 'parking_slot'" class="form-group">
        <label>Parking Slot</label>
        <input
          type="number"
          v-model="group.parkingSlot"
          class="form-input"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRefpointsStore } from '../../stores/refpoints'

const store = useRefpointsStore()

const refpoints = ref({
  bullseyes: store.bullseyes,
  airbases: store.airbases,
  zones: store.zones,
  lines: store.lines
})

// Group model
const group = reactive({
  name: '',
  coalition: 'blue',
  country: 'Russia',
  units: [],
  quantity: 3,
  position: {
    mode: 'offset_bearing',      // 'offset_bearing', 'offset_direct', 'zone_random', 'waypoint'
    refType: 'bullseye',         // 'bullseye', 'airbase', 'zone' (for offset_bearing, offset_direct, zone_random)
    referenceName: '',             // unified reference name (bullseye, airbase, or zone)
    bearing: 0,
    distance: 0,
    offsetX: 0,
    offsetY: 0,
    waypointGroup: '',             // group name for waypoint anchoring
    waypointNumber: 1              // waypoint number (1-based)
  },
  airbase: '',
  parking: 'hot_start',
  parkingSlot: null
})

const selectedUnitType = ref('Su-30SM')

// Watch for refpoints changes
onMounted(() => {
  // Load initial refpoints
  window.api?.refpoints?.load?.().then(config => {
    if (config) {
      refpoints.value.bullseyes = config.bullseyes || []
      refpoints.value.airbases = config.airbases || []
      refpoints.value.zones = config.zones || []
      refpoints.value.lines = config.lines || []
    }
  })
})

// Watch unit type changes
import { watch } from 'vue'
watch(selectedUnitType, (newType) => {
  // Reset units array with new type
  group.units = [{
    type: newType,
    quantity: group.quantity,
    role: getRoleForUnitType(newType)
  }]
})

// Watch mode changes to clear refType and referenceName when switching to waypoint mode
watch(() => group.position.mode, (newMode) => {
  if (newMode === 'waypoint') {
    group.position.refType = null
    group.position.referenceName = ''
  } else {
    // When switching away from waypoint, default to bullseye
    group.position.refType = 'bullseye'
  }
})

const getRoleForUnitType = (type) => {
  const airRoles = {
    'Su-30SM': 'awacs',
    'MiG-29': 'interceptor',
    'Su-25T': 'ground_attack',
    'A-10C': 'ground_attack',
    'F-15C': 'interceptor'
  }
  const supportRoles = {
    'IL-78M': 'tanker',
    'Ka-50': 'attack',
    'Mi-8MT': 'transport'
  }
  if (airRoles[type]) return airRoles[type]
  if (supportRoles[type]) return supportRoles[type]
  return 'default'
}
</script>

<style scoped>
.group-editor {
  width: 100%;
}

.editor-section {
  background: #252526;
  padding: 12px;
  border-radius: 4px;
  margin-bottom: 12px;
}

.editor-section h4 {
  font-size: 13px;
  color: #ffffff;
  margin-bottom: 10px;
  padding-bottom: 6px;
  border-bottom: 1px solid #3e3e42;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}

.form-group {
  margin-bottom: 8px;
}

.form-group label {
  display: block;
  font-size: 11px;
  color: #aaa;
  margin-bottom: 4px;
}

.form-input {
  width: 100%;
  background: #3c3c3c;
  border: 1px solid #454545;
  color: white;
  padding: 6px;
  border-radius: 3px;
}

.form-input:focus {
  outline: none;
  border-color: #0e639c;
}

.offset-config {
  margin-top: 8px;
  padding-left: 8px;
  border-left: 2px solid #3c3c3c;
}
</style>
