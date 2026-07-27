<template>
  <VisualCanvas
    :width="width"
    :height="height"
    :show-grid="showGrid"
    @camera-ready="onCameraReady"
  >
    <template #header>
      <h4 class="canvas-title">
        <Icon name="map" />
        Reference Point Layout
      </h4>
      <div class="canvas-controls">
        <label class="control-label">
          <input type="checkbox" v-model="showGrid" />
          Show Grid
        </label>
        <label class="control-label">
          <input type="checkbox" v-model="showCoordinates" />
          Show Coordinates
        </label>
        <span class="zoom-display">Zoom: {{ Math.round(zoom * 100) }}%</span>
        <input type="range" v-model="zoom" :min="0.1" :max="5" :step="0.1" class="zoom-slider" />
      </div>
    </template>

    <template #controls>
      <div class="nav-controls">
        <button @click="resetView" class="nav-btn" title="Reset View (Home)">
          <Icon name="home" />
        </button>
        <button @click="resetOrigin" class="nav-btn" title="Reset Origin">
          <Icon name="crosshair" />
        </button>
      </div>
    </template>

    <template #default="{ zoom: canvasZoom }">
      <!-- Origin marker -->
      <g class="origin-marker" :transform="`translate(${originX}, ${originY})`">
        <line x1="-15" y1="0" x2="15" y2="0" stroke="var(--color-text-3)" :stroke-width="1 / canvasZoom" />
        <line x1="0" y1="-15" x2="0" y2="15" stroke="var(--color-text-3)" :stroke-width="1 / canvasZoom" />
        <circle :r="3 / canvasZoom" fill="var(--color-text-3)" />
        <text x="18" :y="4 / canvasZoom" fill="var(--color-text-3)" :font-size="10 / canvasZoom">(0, 0)</text>
      </g>

      <!-- Bullseyes (only those with x/y coordinates) -->
      <g class="bullseyes-layer">
        <g
          v-for="bullseye in bullseyesWithCoords"
          :key="`bullseye-${bullseye.name}`"
          :transform="`translate(${bullseye.x || 0}, ${bullseye.y || 0})`"
          :class="['reference-element', 'bullseye-element', { selected: selectedElement?.type === 'bullseye' && selectedElement?.item === bullseye }]"
          @mousedown="handleElementMouseDown($event, 'bullseye', bullseye)"
        >
          <circle :r="20 / canvasZoom" fill="var(--color-primary)" opacity="0.15" stroke="var(--color-primary)" :stroke-width="2 / canvasZoom" />
          <circle :r="12 / canvasZoom" fill="var(--color-primary)" opacity="0.3" />
          <circle :r="6 / canvasZoom" fill="var(--color-primary)" />
          <text :y="-28 / canvasZoom" text-anchor="middle" fill="var(--color-text-1)" :font-size="11 / canvasZoom" font-weight="bold">
            {{ bullseye.name }}
          </text>
          <text
            v-if="showCoordinates"
            :y="35 / canvasZoom"
            text-anchor="middle"
            fill="var(--color-text-3)"
            :font-size="9 / canvasZoom"
          >
            ({{ Math.round(bullseye.x || 0) }}, {{ Math.round(bullseye.y || 0) }})
          </text>
        </g>
      </g>

      <!-- Airbases (only those with x/y coordinates) -->
      <g class="airbases-layer">
        <g
          v-for="airbase in airbasesWithCoords"
          :key="`airbase-${airbase.name}`"
          :transform="`translate(${airbase.x || 0}, ${airbase.y || 0})`"
          :class="['reference-element', 'airbase-element', { selected: selectedElement?.type === 'airbase' && selectedElement?.item === airbase }]"
          @mousedown="handleElementMouseDown($event, 'airbase', airbase)"
        >
          <rect
            :x="-12 / canvasZoom"
            :y="-12 / canvasZoom"
            :width="24 / canvasZoom"
            :height="24 / canvasZoom"
            :rx="4 / canvasZoom"
            fill="var(--color-success)"
            opacity="0.3"
            stroke="var(--color-success)"
            :stroke-width="2 / canvasZoom"
          />
          <rect :x="-4 / canvasZoom" :y="-4 / canvasZoom" :width="8 / canvasZoom" :height="8 / canvasZoom" fill="var(--color-success)" />
          <text :y="-18 / canvasZoom" text-anchor="middle" fill="var(--color-text-1)" :font-size="11 / canvasZoom" font-weight="bold">
            {{ airbase.name }}
          </text>
          <text
            v-if="showCoordinates"
            :y="28 / canvasZoom"
            text-anchor="middle"
            fill="var(--color-text-3)"
            :font-size="9 / canvasZoom"
          >
            ({{ Math.round(airbase.x || 0) }}, {{ Math.round(airbase.y || 0) }})
          </text>
        </g>
      </g>

      <!-- Trigger Zones (only those with x/y coordinates) -->
      <g class="zones-layer">
        <g
          v-for="zone in zonesWithCoords"
          :key="`zone-${zone.name}`"
          :transform="`translate(${zone.x || 0}, ${zone.y || 0})`"
          :class="['reference-element', 'zone-element', { selected: selectedElement?.type === 'zone' && selectedElement?.item === zone }]"
          @mousedown="handleElementMouseDown($event, 'zone', zone)"
        >
          <circle
            :r="(zone.radius || 5000) / 100"
            fill="var(--color-warning)"
            opacity="0.15"
            stroke="var(--color-warning)"
            :stroke-width="2 / canvasZoom"
            stroke-dasharray="4,4"
          />
          <circle :r="8 / canvasZoom" fill="var(--color-warning)" />
          <text :y="-15 / canvasZoom" text-anchor="middle" fill="var(--color-text-1)" :font-size="11 / canvasZoom" font-weight="bold">
            {{ zone.name }}
          </text>
          <text
            v-if="showCoordinates"
            :y="25 / canvasZoom"
            text-anchor="middle"
            fill="var(--color-text-3)"
            :font-size="9 / canvasZoom"
          >
            ({{ Math.round(zone.x || 0) }}, {{ Math.round(zone.y || 0) }})
          </text>
        </g>
      </g>

      <!-- Battle Lines -->
      <g class="lines-layer">
        <g
          v-for="line in linesWithCoords"
          :key="`line-${line.name}`"
          :class="['reference-element', 'line-element', { selected: selectedElement?.type === 'line' && selectedElement?.item === line }]"
          @mousedown="handleElementMouseDown($event, 'line', line)"
        >
          <line
            :x1="line.start?.x || 0"
            :y1="line.start?.y || 0"
            :x2="line.end?.x || 0"
            :y2="line.end?.y || 0"
            stroke="var(--color-error)"
            :stroke-width="3 / canvasZoom"
            stroke-dasharray="8,4"
            opacity="0.6"
          />
          <circle
            :cx="line.start?.x || 0"
            :cy="line.start?.y || 0"
            :r="6 / canvasZoom"
            fill="var(--color-error)"
            class="drag-handle"
          />
          <circle
            :cx="line.end?.x || 0"
            :cy="line.end?.y || 0"
            :r="6 / canvasZoom"
            fill="var(--color-error)"
            class="drag-handle"
          />
          <text
            :x="(line.start?.x || 0 + line.end?.x || 0) / 2"
            :y="(line.start?.y || 0 + line.end?.y || 0) / 2 - 10 / canvasZoom"
            fill="var(--color-text-1)"
            :font-size="11 / canvasZoom"
            font-weight="bold"
            text-anchor="middle"
          >
            {{ line.name }}
          </text>
          <text
            v-if="showCoordinates"
            :x="(line.start?.x || 0 + line.end?.x || 0) / 2"
            :y="(line.start?.y || 0 + line.end?.y || 0) / 2 + 10 / canvasZoom"
            fill="var(--color-text-3)"
            :font-size="9 / canvasZoom"
            text-anchor="middle"
          >
            {{ formatCoords(line.start) }} → {{ formatCoords(line.end) }}
          </text>
        </g>
      </g>

      <!-- Drag preview -->
      <g v-if="isDragging && draggingElement" class="drag-preview">
        <circle
          :cx="dragPosition.x"
          :cy="dragPosition.y"
          :r="10 / canvasZoom"
          fill="var(--color-warning)"
          opacity="0.5"
        />
      </g>

      <!-- Empty state hint -->
      <g v-if="showEmptyState" class="empty-state">
        <text
          :x="originX"
          :y="originY"
          text-anchor="middle"
          fill="var(--color-text-3)"
          :font-size="14 / canvasZoom"
        >
          No reference points with coordinates configured.
        </text>
        <text
          :x="originX"
          :y="originY + 25 / canvasZoom"
          text-anchor="middle"
          fill="var(--color-text-4)"
          :font-size="11 / canvasZoom"
        >
          Battle lines need startX/Y and endX/Y. Other types need x/y.
        </text>
      </g>
    </template>
  </VisualCanvas>

  <!-- Info panel (absolute positioned, outside SVG) -->
  <div class="info-panel" v-if="selectedElement">
    <div class="info-header">
      <span class="info-type">{{ selectedElement.type }}</span>
      <span class="info-name">{{ selectedElement.item.name }}</span>
      <button @click="clearSelection" class="close-btn">×</button>
    </div>
    <div class="info-content">
      <div v-if="selectedElement.type === 'line'" class="line-coords">
        <div class="coord-row">
          <span>Start:</span>
          <input
            type="number"
            :value="Math.round(selectedElement.item.start?.x || 0)"
            @change="updateLineCoord('start', 'x', $event.target.value)"
            class="coord-input"
          />
          <input
            type="number"
            :value="Math.round(selectedElement.item.start?.y || 0)"
            @change="updateLineCoord('start', 'y', $event.target.value)"
            class="coord-input"
          />
        </div>
        <div class="coord-row">
          <span>End:</span>
          <input
            type="number"
            :value="Math.round(selectedElement.item.end?.x || 0)"
            @change="updateLineCoord('end', 'x', $event.target.value)"
            class="coord-input"
          />
          <input
            type="number"
            :value="Math.round(selectedElement.item.end?.y || 0)"
            @change="updateLineCoord('end', 'y', $event.target.value)"
            class="coord-input"
          />
        </div>
      </div>
      <div v-else class="point-coords">
        <div class="coord-row">
          <span>X:</span>
          <input
            type="number"
            :value="Math.round(selectedElement.item.x || 0)"
            @change="updatePointCoord('x', $event.target.value)"
            class="coord-input"
          />
          <span>Y:</span>
          <input
            type="number"
            :value="Math.round(selectedElement.item.y || 0)"
            @change="updatePointCoord('y', $event.target.value)"
            class="coord-input"
          />
        </div>
        <div v-if="selectedElement.type === 'zone'" class="coord-row">
          <span>Radius:</span>
          <input
            type="number"
            :value="selectedElement.item.radius || 5000"
            @change="updateZoneRadius($event.target.value)"
            class="coord-input"
          />
        </div>
      </div>
    </div>
  </div>

  <!-- Help text -->
  <div class="canvas-help">
    <span>🖱️ Drag elements to reposition</span>
    <span>🔍 Scroll to zoom</span>
    <span>✋ Drag empty space to pan</span>
    <span>📍 Double-click to set origin</span>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import Icon from '../ui/Icon.vue'
import VisualCanvas from './VisualCanvas.vue'

const props = defineProps({
  refpoints: {
    type: Object,
    default: () => ({
      bullseyes: [],
      airbases: [],
      zones: [],
      lines: []
    })
  },
  width: {
    type: Number,
    default: 800
  },
  height: {
    type: Number,
    default: 500
  }
})

const emit = defineEmits(['refpoints-change'])

// Camera state (synced with VisualCanvas)
const cameraApi = ref(null)

// These will be set to the camera refs when ready
let zoom, panX, panY

const onCameraReady = (api) => {
  cameraApi.value = api
  zoom = api.zoom
  panX = api.panX
  panY = api.panY
}

const showGrid = ref(true)
const showCoordinates = ref(false)
const hasInitializedView = ref(false)

const originX = computed(() => props.width / 2)
const originY = computed(() => props.height / 2)

// Filter reference points to only those with coordinates
const bullseyesWithCoords = computed(() => {
  return (props.refpoints?.bullseyes || []).filter(b => b.x !== undefined && b.x !== null)
})
const airbasesWithCoords = computed(() => {
  return (props.refpoints?.airbases || []).filter(a => a.x !== undefined && a.x !== null)
})
const zonesWithCoords = computed(() => {
  return (props.refpoints?.zones || []).filter(z => z.x !== undefined && z.x !== null)
})
const linesWithCoords = computed(() => {
  return (props.refpoints?.lines || []).filter(l =>
    (l.startX !== undefined && l.startX !== null) || (l.endX !== undefined && l.endX !== null)
  )
})

// Show empty state if no items have coordinates
const showEmptyState = computed(() => {
  return bullseyesWithCoords.value.length === 0 &&
    airbasesWithCoords.value.length === 0 &&
    zonesWithCoords.value.length === 0 &&
    linesWithCoords.value.length === 0
})

// Selection state
const selectedElement = ref(null)

// Drag state
const isDragging = ref(false)
const isPanning = ref(false)
const draggingElement = ref(null)
const dragStart = ref({ x: 0, y: 0 })
const dragPosition = ref({ x: 0, y: 0 })
const panStart = ref({ x: 0, y: 0 })

// Convert screen coordinates to world coordinates
const screenToWorld = (screenX, screenY) => {
  if (!zoom || !panX || !panY || !cameraApi.value?.svgRect?.value) {
    return { x: screenX, y: screenY }
  }
  const rect = cameraApi.value.svgRect.value
  return {
    x: (screenX - rect.left - panX.value) / zoom.value,
    y: (screenY - rect.top - panY.value) / zoom.value
  }
}

// Format coordinates for display
const formatCoords = (point) => {
  if (!point) return ''
  return `(${Math.round(point.x || 0)}, ${Math.round(point.y || 0)})`
}

// Handle element mouse down
const handleElementMouseDown = (e, type, item) => {
  e.stopPropagation()
  isDragging.value = true
  draggingElement.value = { type, item }

  const worldPos = screenToWorld(e.clientX, e.clientY)
  dragStart.value = {
    x: type === 'line' ? null : (item.x || 0),
    y: type === 'line' ? null : (item.y || 0),
    screenX: e.clientX,
    screenY: e.clientY
  }

  selectElement(type, item)
}

// Handle canvas mouse down (pan or deselect)
const handleCanvasMouseDown = (e) => {
  if (e.target === e.currentTarget || e.target.tagName === 'rect') {
    isPanning.value = true
    panStart.value = { x: e.clientX - panX.value, y: e.clientY - panY.value }
    clearSelection()
  }
}

// Handle mouse move
const handleCanvasMouseMove = (e) => {
  if (isDragging.value && draggingElement.value) {
    const worldPos = screenToWorld(e.clientX, e.clientY)
    dragPosition.value = worldPos

    const element = draggingElement.value
    if (element.type === 'line') {
      const line = element.item
      const startDist = Math.hypot(
        (line.start?.x || 0) - worldPos.x,
        (line.start?.y || 0) - worldPos.y
      )
      const endDist = Math.hypot(
        (line.end?.x || 0) - worldPos.x,
        (line.end?.y || 0) - worldPos.y
      )

      if (startDist < endDist && startDist < 20) {
        line.start = { x: worldPos.x, y: worldPos.y }
      } else if (endDist < 20) {
        line.end = { x: worldPos.x, y: worldPos.y }
      }
    } else {
      element.item.x = worldPos.x
      element.item.y = worldPos.y
    }

    emitChange()
  } else if (isPanning.value) {
    panX.value = e.clientX - panStart.value.x
    panY.value = e.clientY - panStart.value.y
  }
}

// Handle mouse up
const handleCanvasMouseUp = () => {
  isDragging.value = false
  isPanning.value = false
  draggingElement.value = null
}

// Handle double click to set origin
const handleDoubleClick = (e) => {
  const worldPos = screenToWorld(e.clientX, e.clientY)
  if (panX && panY) {
    panX.value = -worldPos.x * zoom.value + props.width / 2
    panY.value = -worldPos.y * zoom.value + props.height / 2
  }
}

// Select an element
const selectElement = (type, item) => {
  selectedElement.value = { type, item }
}

// Clear selection
const clearSelection = () => {
  selectedElement.value = null
}

// Update line coordinates
const updateLineCoord = (endpoint, coord, value) => {
  if (selectedElement.value?.type === 'line') {
    const line = selectedElement.value.item
    if (!line[endpoint]) line[endpoint] = {}
    line[endpoint][coord] = parseFloat(value) || 0
    emitChange()
  }
}

// Update point coordinates
const updatePointCoord = (coord, value) => {
  if (selectedElement.value && selectedElement.value.type !== 'line') {
    selectedElement.value.item[coord] = parseFloat(value) || 0
    emitChange()
  }
}

// Update zone radius
const updateZoneRadius = (value) => {
  if (selectedElement.value?.type === 'zone') {
    selectedElement.value.item.radius = parseFloat(value) || 5000
    emitChange()
  }
}

// Emit changes to parent
const emitChange = () => {
  emit('refpoints-change', props.refpoints)
}

// Reset view
const resetView = () => {
  if (cameraApi.value && cameraApi.value.resetView) {
    cameraApi.value.resetView()
  }
  hasInitializedView.value = false
  autoCenter()
}

// Reset origin to center
const resetOrigin = () => {
  if (panX && panY) {
    panX.value = 0
    panY.value = 0
  }
}

// Auto-center on mount and when refpoints change
const autoCenter = () => {
  if (hasInitializedView.value) return
  if (!zoom || !panX || !panY) return

  const allPoints = []

  bullseyesWithCoords.value.forEach(p => {
    allPoints.push({ x: p.x, y: p.y })
  })
  airbasesWithCoords.value.forEach(p => {
    allPoints.push({ x: p.x, y: p.y })
  })
  zonesWithCoords.value.forEach(p => {
    allPoints.push({ x: p.x, y: p.y })
  })
  linesWithCoords.value.forEach(line => {
    if (line.start?.x !== undefined) allPoints.push({ x: line.start.x, y: line.start.y })
    if (line.end?.x !== undefined) allPoints.push({ x: line.end.x, y: line.end.y })
  })

  if (allPoints.length === 0) {
    hasInitializedView.value = true
    return
  }

  const xs = allPoints.map(p => p.x)
  const ys = allPoints.map(p => p.y)
  const minX = Math.min(...xs)
  const maxX = Math.max(...xs)
  const minY = Math.min(...ys)
  const maxY = Math.max(...ys)

  const centerX = (minX + maxX) / 2
  const centerY = (minY + maxY) / 2
  const width = maxX - minX
  const height = maxY - minY

  const padding = 100
  const contentWidth = width + padding * 2
  const contentHeight = height + padding * 2

  const zoomX = props.width / contentWidth
  const zoomY = props.height / contentHeight
  const newZoom = Math.min(zoomX, zoomY, 2)

  zoom.value = newZoom
  panX.value = props.width / 2 - centerX * newZoom
  panY.value = props.height / 2 - centerY * newZoom

  hasInitializedView.value = true
}

// Watch for external changes
watch(() => props.refpoints, () => {
  autoCenter()
}, { deep: true })

onMounted(() => {
  autoCenter()
})
</script>

<style scoped>
.canvas-title {
  display: flex;
  align-items: center;
  gap: var(--spacing-xs);
  font-size: var(--font-size-md);
  font-weight: var(--font-weight-semibold);
  color: var(--color-text-4);
  margin: 0;
}

.canvas-controls {
  display: flex;
  align-items: center;
  gap: var(--spacing-md);
}

.control-label {
  display: flex;
  align-items: center;
  gap: var(--spacing-xs);
  font-size: var(--font-size-sm);
  color: var(--color-text-2);
}

.zoom-slider {
  width: 100px;
  accent-color: var(--color-primary);
}

.zoom-display {
  font-size: var(--font-size-sm);
  color: var(--color-text-2);
  min-width: 70px;
}

.nav-controls {
  position: absolute;
  bottom: var(--spacing-sm);
  right: var(--spacing-sm);
  display: flex;
  gap: var(--spacing-xs);
}

.nav-btn {
  width: 32px;
  height: 32px;
  border-radius: var(--spacing-xs);
  border: 1px solid var(--color-border);
  background: var(--color-bg-2);
  color: var(--color-text-1);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all var(--transition-fast);
}

.nav-btn:hover {
  background: var(--color-bg-3);
}

.info-panel {
  position: absolute;
  top: var(--spacing-sm);
  right: var(--spacing-sm);
  width: 220px;
  background: var(--color-bg-2);
  border: 1px solid var(--color-border);
  border-radius: var(--spacing-xs);
  padding: var(--spacing-sm);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  z-index: 10;
}

.info-header {
  display: flex;
  align-items: center;
  gap: var(--spacing-xs);
  margin-bottom: var(--spacing-sm);
  padding-bottom: var(--spacing-xs);
  border-bottom: 1px solid var(--color-border);
}

.info-type {
  font-size: var(--font-size-xs);
  text-transform: uppercase;
  color: var(--color-text-3);
  font-weight: var(--font-weight-medium);
}

.info-name {
  font-size: var(--font-size-sm);
  font-weight: var(--font-weight-semibold);
  color: var(--color-text-1);
  flex: 1;
}

.close-btn {
  background: none;
  border: none;
  color: var(--color-text-2);
  font-size: 18px;
  cursor: pointer;
  padding: 0;
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.close-btn:hover {
  color: var(--color-text-1);
}

.info-content {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-xs);
}

.coord-row {
  display: flex;
  align-items: center;
  gap: var(--spacing-xs);
}

.coord-row span {
  font-size: var(--font-size-xs);
  color: var(--color-text-2);
  min-width: 40px;
}

.coord-input {
  flex: 1;
  background: var(--color-bg-1);
  border: 1px solid var(--color-border);
  color: var(--color-text-1);
  padding: var(--spacing-xs);
  border-radius: var(--spacing-xxs);
  font-size: var(--font-size-xs);
  width: 60px;
}

.coord-input:focus {
  outline: none;
  border-color: var(--color-border-focus);
}

.canvas-help {
  display: flex;
  justify-content: center;
  gap: var(--spacing-lg);
  padding: var(--spacing-sm) var(--spacing-md);
  background: var(--color-bg-2);
  border-top: 1px solid var(--color-border);
  font-size: var(--font-size-xs);
  color: var(--color-text-2);
}

.reference-element {
  cursor: pointer;
  transition: opacity var(--transition-fast);
}

.reference-element:hover {
  opacity: 0.8;
}

.reference-element.selected circle,
.reference-element.selected rect {
  stroke: var(--color-warning);
  stroke-width: 3;
}

.drag-handle {
  cursor: move;
  opacity: 0;
  transition: opacity var(--transition-fast);
}

.reference-element:hover .drag-handle {
  opacity: 1;
}

.drag-preview {
  pointer-events: none;
}

.origin-marker {
  pointer-events: none;
}

.empty-state {
  pointer-events: none;
}
</style>
