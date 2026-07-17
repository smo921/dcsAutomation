<template>
  <div class="reference-point-canvas">
    <div class="canvas-header">
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
    </div>

    <div class="canvas-container" ref="canvasContainer">
      <svg
        ref="svg"
        :width="width"
        :height="height"
        :viewBox="`0 0 ${width} ${height}`"
        @mousedown="handleCanvasMouseDown"
        @mousemove="handleCanvasMouseMove"
        @mouseup="handleCanvasMouseUp"
        @mouseleave="handleCanvasMouseUp"
        @wheel="handleWheel"
        @dblclick="handleDoubleClick"
      >
        <!-- Grid background -->
        <defs>
          <pattern id="grid" :width="gridSize * zoom" :height="gridSize * zoom" patternUnits="userSpaceOnUse">
            <path
              :d="`M ${gridSize * zoom} 0 L 0 0 0 ${gridSize * zoom}`"
              fill="none"
              stroke="var(--color-border)"
              stroke-width="0.5"
            />
          </pattern>
          <pattern id="grid-major" :width="gridSizeMajor * zoom" :height="gridSizeMajor * zoom" patternUnits="userSpaceOnUse">
            <path
              :d="`M ${gridSizeMajor * zoom} 0 L 0 0 0 ${gridSizeMajor * zoom}`"
              fill="none"
              stroke="var(--color-border)"
              stroke-width="1"
            />
          </pattern>
        </defs>

        <!-- Background -->
        <rect width="100%" height="100%" fill="var(--color-bg-1)" />

        <!-- Grid layers -->
        <g v-if="showGrid" class="grid-layer">
          <rect width="100%" height="100%" fill="url(#grid-major)" />
          <rect width="100%" height="100%" fill="url(#grid)" />
        </g>

        <!-- Origin marker -->
        <g class="origin-marker" :transform="`translate(${originX}, ${originY})`">
          <line x1="-15" y1="0" x2="15" y2="0" stroke="var(--color-text-3)" stroke-width="1" />
          <line x1="0" y1="-15" x2="0" y2="15" stroke="var(--color-text-3)" stroke-width="1" />
          <circle r="3" fill="var(--color-text-3)" />
          <text x="18" y="4" fill="var(--color-text-3)" font-size="10">(0, 0)</text>
        </g>

        <!-- Battle Lines (draw first so they're behind other elements) -->
        <g class="lines-layer" :transform="`translate(${panX}, ${panY}) scale(${zoom})`">
          <g
            v-for="line in refpoints.lines"
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
              stroke-width="3"
              stroke-dasharray="8,4"
              opacity="0.6"
            />
            <!-- Line endpoints (draggable) -->
            <circle
              :cx="line.start?.x || 0"
              :cy="line.start?.y || 0"
              r="6"
              fill="var(--color-error)"
              class="drag-handle"
            />
            <circle
              :cx="line.end?.x || 0"
              :cy="line.end?.y || 0"
              r="6"
              fill="var(--color-error)"
              class="drag-handle"
            />
            <!-- Line label -->
            <text
              :x="(line.start?.x || 0 + line.end?.x || 0) / 2"
              :y="(line.start?.y || 0 + line.end?.y || 0) / 2 - 10"
              fill="var(--color-text-1)"
              font-size="11"
              font-weight="bold"
              text-anchor="middle"
            >
              {{ line.name }}
            </text>
            <!-- Coordinates label -->
            <text
              v-if="showCoordinates"
              :x="(line.start?.x || 0 + line.end?.x || 0) / 2"
              :y="(line.start?.y || 0 + line.end?.y || 0) / 2 + 10"
              fill="var(--color-text-3)"
              font-size="9"
              text-anchor="middle"
            >
              {{ formatCoords(line.start) }} → {{ formatCoords(line.end) }}
            </text>
          </g>
        </g>

        <!-- Trigger Zones -->
        <g class="zones-layer" :transform="`translate(${panX}, ${panY}) scale(${zoom})`">
          <g
            v-for="zone in refpoints.zones"
            :key="`zone-${zone.name}`"
            :transform="`translate(${zone.x || 0}, ${zone.y || 0})`"
            :class="['reference-element', 'zone-element', { selected: selectedElement?.type === 'zone' && selectedElement?.item === zone }]"
            @mousedown="handleElementMouseDown($event, 'zone', zone)"
          >
            <!-- Zone circle -->
            <circle
              :r="zone.radius || 5000"
              fill="var(--color-warning)"
              opacity="0.15"
              stroke="var(--color-warning)"
              stroke-width="2"
              stroke-dasharray="4,4"
            />
            <!-- Center point -->
            <circle r="8" fill="var(--color-warning)" />
            <!-- Zone label -->
            <text y="-15" text-anchor="middle" fill="var(--color-text-1)" font-size="11" font-weight="bold">
              {{ zone.name }}
            </text>
            <!-- Coordinates label -->
            <text
              v-if="showCoordinates"
              y="25"
              text-anchor="middle"
              fill="var(--color-text-3)"
              font-size="9"
            >
              ({{ Math.round(zone.x || 0) }}, {{ Math.round(zone.y || 0) }})
            </text>
          </g>
        </g>

        <!-- Airbases -->
        <g class="airbases-layer" :transform="`translate(${panX}, ${panY}) scale(${zoom})`">
          <g
            v-for="airbase in refpoints.airbases"
            :key="`airbase-${airbase.name}`"
            :transform="`translate(${airbase.x || 0}, ${airbase.y || 0})`"
            :class="['reference-element', 'airbase-element', { selected: selectedElement?.type === 'airbase' && selectedElement?.item === airbase }]"
            @mousedown="handleElementMouseDown($event, 'airbase', airbase)"
          >
            <!-- Airbase marker (square with rounded corners) -->
            <rect
              x="-12"
              y="-12"
              width="24"
              height="24"
              rx="4"
              fill="var(--color-success)"
              opacity="0.3"
              stroke="var(--color-success)"
              stroke-width="2"
            />
            <!-- Center point -->
            <rect x="-4" y="-4" width="8" height="8" fill="var(--color-success)" />
            <!-- Airbase label -->
            <text y="-18" text-anchor="middle" fill="var(--color-text-1)" font-size="11" font-weight="bold">
              {{ airbase.name }}
            </text>
            <!-- Coordinates label -->
            <text
              v-if="showCoordinates"
              y="28"
              text-anchor="middle"
              fill="var(--color-text-3)"
              font-size="9"
            >
              ({{ Math.round(airbase.x || 0) }}, {{ Math.round(airbase.y || 0) }})
            </text>
          </g>
        </g>

        <!-- Bullseyes -->
        <g class="bullseyes-layer" :transform="`translate(${panX}, ${panY}) scale(${zoom})`">
          <g
            v-for="bullseye in refpoints.bullseyes"
            :key="`bullseye-${bullseye.name}`"
            :transform="`translate(${bullseye.x || 0}, ${bullseye.y || 0})`"
            :class="['reference-element', 'bullseye-element', { selected: selectedElement?.type === 'bullseye' && selectedElement?.item === bullseye }]"
            @mousedown="handleElementMouseDown($event, 'bullseye', bullseye)"
          >
            <!-- Bullseye circles -->
            <circle r="20" fill="var(--color-primary)" opacity="0.15" stroke="var(--color-primary)" stroke-width="2" />
            <circle r="12" fill="var(--color-primary)" opacity="0.3" />
            <circle r="6" fill="var(--color-primary)" />
            <!-- Bullseye label -->
            <text y="-28" text-anchor="middle" fill="var(--color-text-1)" font-size="11" font-weight="bold">
              {{ bullseye.name }}
            </text>
            <!-- Coordinates label -->
            <text
              v-if="showCoordinates"
              y="35"
              text-anchor="middle"
              fill="var(--color-text-3)"
              font-size="9"
            >
              ({{ Math.round(bullseye.x || 0) }}, {{ Math.round(bullseye.y || 0) }})
            </text>
          </g>
        </g>

        <!-- Drag preview -->
        <g v-if="isDragging && draggingElement" class="drag-preview">
          <circle
            :cx="dragPosition.x"
            :cy="dragPosition.y"
            r="10"
            fill="var(--color-warning)"
            opacity="0.5"
          />
        </g>
      </svg>

      <!-- Navigation controls -->
      <div class="nav-controls">
        <button @click="resetView" class="nav-btn" title="Reset View (Home)">
          <Icon name="home" />
        </button>
        <button @click="resetOrigin" class="nav-btn" title="Reset Origin">
          <Icon name="crosshair" />
        </button>
      </div>

      <!-- Info panel -->
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
    </div>

    <!-- Help text -->
    <div class="canvas-help">
      <span>🖱️ Drag elements to reposition</span>
      <span>🔍 Scroll to zoom</span>
      <span>✋ Drag empty space to pan</span>
      <span>📍 Double-click to set origin</span>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import Icon from '../ui/Icon.vue'

onMounted(() => {
  autoCenter()
})

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

const svg = ref(null)
const canvasContainer = ref(null)
const zoom = ref(0.5)
const panX = ref(0)
const panY = ref(0)
const showGrid = ref(true)
const showCoordinates = ref(false)
const hasInitializedView = ref(false)

const gridSize = 50
const gridSizeMajor = 250

// Origin position (center of canvas)
const originX = computed(() => props.width / 2)
const originY = computed(() => props.height / 2)

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
  const rect = svg.value.getBoundingClientRect()
  const x = (screenX - rect.left - panX.value) / zoom.value
  const y = (screenY - rect.top - panY.value) / zoom.value
  return { x, y }
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
  if (e.target === svg.value || e.target.tagName === 'rect') {
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
      // Check if dragging start or end point
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

// Handle wheel zoom
const handleWheel = (e) => {
  e.preventDefault()
  const delta = e.deltaY > 0 ? 0.9 : 1.1
  zoom.value = Math.max(0.1, Math.min(5, zoom.value * delta))
}

// Handle double click to set origin
const handleDoubleClick = (e) => {
  const worldPos = screenToWorld(e.clientX, e.clientY)
  panX.value = -worldPos.x * zoom.value + props.width / 2
  panY.value = -worldPos.y * zoom.value + props.height / 2
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
  zoom.value = 0.5
  panX.value = 0
  panY.value = 0
  hasInitializedView.value = false
  autoCenter()
}

// Reset origin to center
const resetOrigin = () => {
  panX.value = 0
  panY.value = 0
}

// Auto-center on mount and when refpoints change
const autoCenter = () => {
  if (hasInitializedView.value) return

  const allPoints = []

  props.refpoints.bullseyes?.forEach(p => {
    if (p.x !== undefined) allPoints.push({ x: p.x, y: p.y })
  })
  props.refpoints.airbases?.forEach(p => {
    if (p.x !== undefined) allPoints.push({ x: p.x, y: p.y })
  })
  props.refpoints.zones?.forEach(p => {
    if (p.x !== undefined) allPoints.push({ x: p.x, y: p.y })
  })
  props.refpoints.lines?.forEach(line => {
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
  zoom.value = Math.min(zoomX, zoomY, 2)

  // Center the content
  panX.value = props.width / 2 - centerX * zoom.value
  panY.value = props.height / 2 - centerY * zoom.value

  hasInitializedView.value = true
}

// Watch for external changes
watch(() => props.refpoints, () => {
  autoCenter()
}, { deep: true })

// Fit content to view
const fitToContent = () => {
  hasInitializedView.value = false
  autoCenter()
}
</script>

<style scoped>
.reference-point-canvas {
  display: flex;
  flex-direction: column;
  background: var(--color-bg-1);
  border-radius: var(--spacing-xs);
  border: 1px solid var(--color-border);
  overflow: hidden;
}

.canvas-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--spacing-sm) var(--spacing-md);
  background: var(--color-bg-2);
  border-bottom: 1px solid var(--color-border);
}

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

.canvas-container {
  position: relative;
  overflow: hidden;
  cursor: grab;
}

.canvas-container:active {
  cursor: grabbing;
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

.grid-layer {
  pointer-events: none;
}

.origin-marker {
  pointer-events: none;
}
</style>
