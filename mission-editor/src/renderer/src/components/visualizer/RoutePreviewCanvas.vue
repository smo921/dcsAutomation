<template>
  <div class="route-preview-canvas">
    <div class="canvas-header">
      <h4 class="canvas-title">
        <Icon name="map" />
        Route Preview
      </h4>
      <div class="canvas-controls">
        <label class="control-label">
          <input type="checkbox" v-model="showSpeeds" />
          Show Speeds
        </label>
        <label class="control-label">
          <input type="checkbox" v-model="showReference" />
          Show Reference
        </label>
        <label class="control-label">
          Zoom: {{ Math.round(zoom * 100) }}%
        </label>
        <input type="range" v-model="zoom" :min="0.25" :max="4" :step="0.25" class="zoom-slider" />
      </div>
    </div>

    <div class="canvas-container" ref="canvasContainer">
      <svg
        ref="svg"
        :width="width"
        :height="height"
        :viewBox="`0 0 ${width} ${height}`"
        @mousedown="startPan"
        @mousemove="handlePan"
        @mouseup="endPan"
        @mouseleave="endPan"
        @wheel="handleWheel"
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
        </defs>
        <rect width="100%" height="100%" fill="url(#grid)" />

        <!-- Reference point (only the one relevant to current placement) -->
        <!-- Shown at local origin (0,0) since route is relative to reference -->
        <g v-if="showReference && referencePoint" class="reference-layer" :transform="`translate(${panX}, ${panY}) scale(${zoom})`">
          <g
            :transform="`translate(0, 0)`"
            class="reference-point"
          >
            <circle r="8" fill="var(--color-warning)" opacity="0.5" />
            <text y="-10" text-anchor="middle" fill="var(--color-text-1)" font-size="10">
              {{ referencePoint.name }} (Ref)
            </text>
          </g>
        </g>

        <!-- Route path -->
        <g class="route-layer" :transform="`translate(${panX}, ${panY}) scale(${zoom})`"
          @mousemove="handleDragMove"
          @mouseup="handleDragEnd"
          @mouseleave="handleDragEnd">
          <!-- Connection lines from start to route points -->
          <polyline
            v-if="allConnectionPoints.length > 1"
            :points="allConnectionPoints.map(p => `${p.x},${p.y}`).join(' ')"
            fill="none"
            stroke="var(--color-primary)"
            stroke-width="2"
            stroke-dasharray="4,4"
            opacity="0.6"
          />

          <!-- Route points -->
          <g
            v-for="(point, index) in routePoints"
            :key="index"
            :transform="`translate(${point.rawX}, ${point.rawY})`"
            class="route-point"
            :class="{
              'route-point-active': index === activePoint,
              'route-point-draggable': isPointDraggable(point),
              'route-point-dragging': isDragging && draggingPointIndex === index
            }"
          >
            <!-- Point marker -->
            <circle
              r="10"
              :fill="getPointColor(point.type)"
              :stroke="getPointStroke(point.type)"
              stroke-width="2"
              :class="{ draggable: isPointDraggable(point) }"
              @mousedown="handlePointDragStart($event, index)"
            />

            <!-- Point number -->
            <text
              y="4"
              text-anchor="middle"
              fill="white"
              font-size="12"
              font-weight="bold"
            >
              {{ index + 1 }}
            </text>

            <!-- Coordinate label for points with x/y (placement info - shown first) -->
            <text
              v-if="hasCoordinates(point)"
              y="-14"
              text-anchor="middle"
              fill="var(--color-primary)"
              font-size="8"
              font-weight="bold"
            >
              ({{ Math.round(point.rawX) }}, {{ Math.round(point.rawY) }})
            </text>

            <!-- Point type label -->
            <text
              y="-26"
              text-anchor="middle"
              fill="var(--color-text-1)"
              font-size="10"
            >
              {{ formatPointType(point.type) }}
            </text>

            <!-- Altitude indicator (before speed for visual hierarchy) -->
            <text
              v-if="point.altitude"
              y="18"
              text-anchor="middle"
              fill="var(--color-text-3)"
              font-size="8"
            >
              {{ formatAltitude(point.altitude) }}
            </text>

            <!-- Speed indicator -->
            <text
              v-if="showSpeeds && point.speed"
              y="30"
              text-anchor="middle"
              fill="var(--color-text-2)"
              font-size="9"
            >
              {{ point.speed }} kt
            </text>

            <!-- Orbit pattern indicator -->
            <circle
              v-if="point.type === 'orbit' && point.radius"
              :r="point.radius * 2"
              fill="none"
              stroke="var(--color-primary)"
              stroke-width="1"
              stroke-dasharray="2,2"
              opacity="0.4"
            />

            <!-- Orbit direction arrow -->
            <path
              v-if="point.type === 'orbit'"
              :d="getOrbitArrowPath(point.pattern)"
              fill="none"
              stroke="var(--color-primary)"
              stroke-width="2"
              marker-end="url(#arrowhead)"
            />
          </g>

          <!-- Placement origin marker -->
          <g v-if="showPlacementOrigin" class="placement-origin" :transform="`translate(${placementOrigin.rawX}, ${placementOrigin.rawY})`">
            <circle r="15" fill="none" stroke="var(--color-warning)" stroke-width="2" stroke-dasharray="4,4" />
            <circle r="4" fill="var(--color-warning)" />
            <text y="-18" text-anchor="middle" fill="var(--color-text-1)" font-size="10">
              Start
            </text>
          </g>

          <!-- Drag preview ghost -->
          <g v-if="isDragging && draggingPointIndex >= 0" class="drag-preview-layer">
            <circle
              :cx="dragPreviewPos.x"
              :cy="dragPreviewPos.y"
              r="10"
              fill="var(--color-primary)"
              opacity="0.3"
              stroke="var(--color-primary)"
              stroke-width="2"
              stroke-dasharray="4,4"
            />
          </g>

          <!-- Coordinate tooltip during drag -->
          <g v-if="isDragging && draggingPointIndex >= 0" class="drag-tooltip-layer">
            <rect
              :x="dragPreviewPos.x - 40"
              :y="dragPreviewPos.y - 45"
              width="80"
              height="20"
              fill="var(--color-bg-2)"
              stroke="var(--color-border)"
              stroke-width="1"
              rx="3"
            />
            <text
              :x="dragPreviewPos.x"
              :y="dragPreviewPos.y - 31"
              text-anchor="middle"
              fill="var(--color-text-1)"
              font-size="9"
            >
              {{ formatCoords(dragPreviewPos) }}
            </text>
          </g>
        </g>

        <!-- Arrow marker definition -->
        <defs>
          <marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
            <polygon points="0 0, 10 3.5, 0 7" fill="var(--color-primary)" />
          </marker>
        </defs>
      </svg>

      <!-- Navigation controls -->
      <div class="nav-controls">
        <button @click="resetView" class="nav-btn" title="Reset View">
          <Icon name="home" />
        </button>
        <button @click="fitToContent" class="nav-btn" title="Fit to Content">
          <Icon name="expand" />
        </button>
      </div>
    </div>

    <!-- Legend -->
    <div class="canvas-legend">
      <div class="legend-item">
        <span class="legend-icon" style="background: var(--color-primary);"></span>
        <span>Route Point</span>
      </div>
      <div class="legend-item">
        <span class="legend-icon" style="background: var(--color-primary); border-radius: 50%;"></span>
        <span>Orbit</span>
      </div>
      <div class="legend-item">
        <span class="legend-icon" style="background: var(--color-primary);"></span>
        <span>Turn Point/Heading</span>
      </div>
      <div class="legend-item">
        <span class="legend-icon" style="background: var(--color-success);"></span>
        <span>Airbase</span>
      </div>
      <div class="legend-item">
        <span class="legend-icon" style="background: var(--color-warning); border-radius: 50%;"></span>
        <span>Zone</span>
      </div>
      <div class="legend-item">
        <span class="legend-icon" style="background: var(--color-primary); border-radius: 50%;"></span>
        <span>Bullseye</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import Icon from '../ui/Icon.vue'

const props = defineProps({
  route: {
    type: Array,
    default: () => []
  },
  refpoints: {
    type: Object,
    default: () => ({
      bullseyes: [],
      airbases: [],
      zones: [],
      lines: []
    })
  },
  placement: {
    type: Object,
    default: () => ({})
  },
  width: {
    type: Number,
    default: 600
  },
  height: {
    type: Number,
    default: 400
  }
})

const emit = defineEmits(['point-select', 'route-point-move'])

const svg = ref(null)
const canvasContainer = ref(null)
const zoom = ref(1)
const panX = ref(0)
const panY = ref(0)
const showSpeeds = ref(true)
const showReference = ref(true)
const activePoint = ref(-1)

// Pan state
const isPanning = ref(false)
const panStart = ref({ x: 0, y: 0 })

// Drag state for route points
const isDragging = ref(false)
const draggingPointIndex = ref(-1)
const dragStartPos = ref({ x: 0, y: 0 })
const dragOffset = ref({ x: 0, y: 0 })

const gridSize = 50
const hasInitializedView = ref(false)

// Compute route points with cumulative coordinates (offsetX/offsetY are relative to previous point)
// For visualization, NM values are used directly as pixels (no conversion)
const routePoints = computed(() => {
  // Start from the placement origin
  const startPos = getStartPosition()
  let currentX = startPos.x
  let currentY = startPos.y

  return props.route.map((point, index) => {
    // offsetX/offsetY are in NM, use directly as pixels for visualization
    const offsetX = point.offsetX ?? 0
    const offsetY = point.offsetY ?? 0

    // Cumulative position: previous position + offset
    currentX = currentX + offsetX
    currentY = currentY + offsetY

    return {
      ...point,
      rawX: currentX,
      rawY: currentY,
      cumulativeX: currentX,
      cumulativeY: currentY
    }
  })
})

// All connection points including start position
const allConnectionPoints = computed(() => {
  const points = []

  // Add start position (placement origin)
  const startPos = getStartPosition()
  points.push(startPos)

  // Add all route points (already cumulative from start)
  routePoints.value.forEach(p => {
    points.push({ x: p.rawX, y: p.rawY })
  })

  return points
})

// Calculate the center point for auto-centering (in local route coordinates)
const getCenterPoint = () => {
  const allPoints = []

  // Add start position (local coordinates, relative to reference)
  allPoints.push(getStartPosition())

  // Add route points (already in local coordinates)
  routePoints.value.forEach(p => {
    allPoints.push({ x: p.rawX, y: p.rawY })
  })

  // Add reference point at origin (0,0) in local coordinates
  if (showReference.value && referencePoint.value) {
    allPoints.push({ x: 0, y: 0 })
  }

  if (allPoints.length === 0) {
    return { x: 0, y: 0, width: 0, height: 0 }
  }

  const xs = allPoints.map(p => p.x)
  const ys = allPoints.map(p => p.y)
  const minX = Math.min(...xs)
  const maxX = Math.max(...xs)
  const minY = Math.min(...ys)
  const maxY = Math.max(...ys)

  return {
    x: (minX + maxX) / 2,
    y: (minY + maxY) / 2,
    width: maxX - minX,
    height: maxY - minY
  }
}

// Get the reference point for the current placement
const getReferencePoint = () => {
  if (!props.placement || !props.placement.mode) return null
  if (!props.placement.referenceName) return null

  const refType = props.placement.reference
  const name = props.placement.referenceName

  if (refType === 'bullseye') {
    return props.refpoints?.bullseyes?.find(p => p.name === name) || null
  } else if (refType === 'airbase') {
    return props.refpoints?.airbases?.find(p => p.name === name) || null
  } else if (refType === 'zone') {
    return props.refpoints?.zones?.find(p => p.name === name) || null
  } else if (refType === 'battle_line') {
    return props.refpoints?.lines?.find(p => p.name === name) || null
  }
  return null
}

// Calculate the start position based on placement mode
// For visualization, NM values are used directly as pixels (no conversion)
const getStartPosition = () => {
  if (!props.placement || !props.placement.mode) return { x: 0, y: 0 }

  const mode = props.placement.mode

  if (mode === 'COORDINATE' && props.placement.offsetX !== undefined && props.placement.offsetY !== undefined) {
    // offsetX/offsetY are in NM, use directly as pixels
    return { x: props.placement.offsetX, y: props.placement.offsetY }
  }

  if (mode === 'BEARING_DISTANCE') {
    const bearing = props.placement.bearing || 0
    const distanceNm = props.placement.distance || 0
    const bearingRad = bearing * Math.PI / 180
    return {
      x: Math.sin(bearingRad) * distanceNm,
      y: Math.cos(bearingRad) * distanceNm
    }
  }

  // AIRBASE_RAMP, ZONE_CENTER, WAYPOINT - start at reference (0,0 relative)
  return { x: 0, y: 0 }
}

// Compute placement origin (raw coordinates, transform applied via SVG)
const placementOrigin = computed(() => {
  const startPos = getStartPosition()
  return {
    rawX: startPos.x,
    rawY: startPos.y
  }
})

// Reference point for display (null if no reference or COORDINATE mode)
const referencePoint = computed(() => {
  if (!props.placement || !props.placement.mode) return null
  if (props.placement.mode === 'COORDINATE') return null
  return getReferencePoint()
})

// Drag preview position
const dragPreviewPos = computed(() => {
  if (!isDragging.value || draggingPointIndex.value < 0) {
    return { x: 0, y: 0 }
  }

  // Get current position from the route-point-move event data
  // This will be updated by the parent component via props
  const point = routePoints.value[draggingPointIndex.value]
  return {
    x: point?.rawX || 0,
    y: point?.rawY || 0
  }
})

// Format coordinates for tooltip
const formatCoords = (pos) => {
  return `${Math.round(pos.x)}, ${Math.round(pos.y)}`
}

// Check if a point has coordinate data (offsetX/offsetY)
const hasCoordinates = (point) => {
  return point.offsetX !== undefined && point.offsetY !== undefined
}

// Show placement origin marker when we have a start position
const showPlacementOrigin = computed(() => {
  if (!props.placement || !props.placement.mode) return false
  const startPos = getStartPosition()
  // Show marker if start position is non-zero (COORDINATE mode) or if we have a reference
  return (props.placement.mode === 'COORDINATE' && (props.placement.offsetX || props.placement.offsetY)) ||
         (props.placement.mode === 'BEARING_DISTANCE' && props.placement.bearing !== undefined)
})

// Point color helpers
const getPointColor = (type) => {
  const colors = {
    orbit: 'var(--color-primary)',
    turn_point: 'var(--color-primary)',
    heading: 'var(--color-primary)',
    landing: 'var(--color-success)'
  }
  return colors[type] || 'var(--color-primary)'
}

const getPointStroke = (type) => {
  return 'var(--color-bg-1)'
}

const formatPointType = (type) => {
  const formats = {
    orbit: 'Orbit',
    turn_point: 'Turn',
    heading: 'Heading',
    landing: 'Land'
  }
  return formats[type] || type
}

const formatAltitude = (altitude) => {
  if (altitude >= 1000) {
    return `${(altitude / 1000).toFixed(1)}k ft`
  }
  return `${altitude} ft`
}

const getOrbitArrowPath = (pattern) => {
  const direction = pattern === 'clockwise' ? 1 : -1
  const r = 14
  const startAngle = -Math.PI / 2
  const endAngle = startAngle + (Math.PI * 1.5 * direction)
  const x1 = Math.cos(startAngle) * r
  const y1 = Math.sin(startAngle) * r
  const x2 = Math.cos(endAngle) * r
  const y2 = Math.sin(endAngle) * r
  return `M ${x1} ${y1} A ${r} ${r} 0 1 ${direction > 0 ? 1 : 0} ${x2} ${y2}`
}

// Check if a route point is draggable
const isPointDraggable = (point) => {
  // turn_point, heading, and orbit types can all have x/y coordinates
  // landing points are airbase-based and cannot be dragged
  return point.type === 'turn_point' || point.type === 'heading' || point.type === 'orbit'
}

// Screen to world coordinate conversion
const screenToWorld = (screenX, screenY, svgRect) => {
  return {
    x: (screenX - svgRect.left - panX.value) / zoom.value,
    y: (screenY - svgRect.top - panY.value) / zoom.value
  }
}

// Calculate cumulative position up to (but not including) a given index
const getCumulativePositionBefore = (index) => {
  let x = 0
  let y = 0
  for (let i = 0; i < index; i++) {
    const point = props.route[i]
    x += point.offsetX ?? 0
    y += point.offsetY ?? 0
  }
  return { x, y }
}

// Drag handlers for route points
const handlePointDragStart = (event, index) => {
  const point = props.route[index]
  if (!isPointDraggable(point)) return

  event.preventDefault()
  event.stopPropagation()

  const svgRect = svg.value.getBoundingClientRect()
  const worldPos = screenToWorld(event.clientX, event.clientY, svgRect)

  // Get cumulative position of this point (sum of all previous offsets + this point's offset)
  const prevPos = getCumulativePositionBefore(index)
  const currentOffsetX = point.offsetX ?? 0
  const currentOffsetY = point.offsetY ?? 0
  const pointX = prevPos.x + currentOffsetX
  const pointY = prevPos.y + currentOffsetY

  dragOffset.value = {
    x: worldPos.x - pointX,
    y: worldPos.y - pointY
  }

  isDragging.value = true
  draggingPointIndex.value = index
  dragStartPos.value = { x: pointX, y: pointY }
}

const handleDragMove = (event) => {
  if (!isDragging.value || draggingPointIndex.value < 0) return

  const svgRect = svg.value.getBoundingClientRect()
  const worldPos = screenToWorld(event.clientX, event.clientY, svgRect)

  // Calculate new cumulative position (accounting for drag offset)
  const newX = worldPos.x - dragOffset.value.x
  const newY = worldPos.y - dragOffset.value.y

  // Emit the move event for parent to handle
  emit('route-point-move', {
    index: draggingPointIndex.value,
    x: newX,
    y: newY,
    isDragging: true
  })
}

const handleDragEnd = (event) => {
  if (!isDragging.value || draggingPointIndex.value < 0) return

  const svgRect = svg.value.getBoundingClientRect()
  const worldPos = screenToWorld(event.clientX, event.clientY, svgRect)

  const newX = worldPos.x - dragOffset.value.x
  const newY = worldPos.y - dragOffset.value.y

  // Emit final position
  emit('route-point-move', {
    index: draggingPointIndex.value,
    x: newX,
    y: newY,
    isDragging: false
  })

  // Reset drag state
  isDragging.value = false
  draggingPointIndex.value = -1
  dragOffset.value = { x: 0, y: 0 }
}

// Pan handlers
const startPan = (e) => {
  if (e.target.tagName === 'circle' || e.target.tagName === 'text') return
  isPanning.value = true
  panStart.value = { x: e.clientX - panX.value, y: e.clientY - panY.value }
}

const handlePan = (e) => {
  if (!isPanning.value) return
  panX.value = e.clientX - panStart.value.x
  panY.value = e.clientY - panStart.value.y
}

const endPan = () => {
  isPanning.value = false
}

// Zoom handler
const handleWheel = (e) => {
  e.preventDefault()
  const delta = e.deltaY > 0 ? 0.9 : 1.1
  zoom.value = Math.max(0.25, Math.min(4, zoom.value * delta))
}

// View controls
const resetView = () => {
  zoom.value = 1
  panX.value = 0
  panY.value = 0
}

const fitToContent = () => {
  const center = getCenterPoint()

  if (!center.width && !center.height) return

  const padding = 50
  const contentWidth = center.width + padding * 2
  const contentHeight = center.height + padding * 2

  const zoomX = props.width / contentWidth
  const zoomY = props.height / contentHeight
  zoom.value = Math.min(zoomX, zoomY, 2)

  // Center the content
  panX.value = props.width / 2 - center.x * zoom.value
  panY.value = props.height / 2 - center.y * zoom.value
}

// Auto-center on mount and when route changes
const autoCenter = () => {
  if (hasInitializedView.value) return

  const center = getCenterPoint()
  if (!center || (!center.width && !center.height && props.route.length === 0)) return

  // Use a comfortable zoom level
  const padding = 80
  const contentWidth = (center.width || 200) + padding * 2
  const contentHeight = (center.height || 200) + padding * 2

  const zoomX = props.width / contentWidth
  const zoomY = props.height / contentHeight
  zoom.value = Math.min(zoomX, zoomY, 2)

  // Center on the content
  panX.value = props.width / 2 - center.x * zoom.value
  panY.value = props.height / 2 - center.y * zoom.value

  hasInitializedView.value = true
}

watch(() => props.route.length, () => {
  if (props.route.length > 0) {
    autoCenter()
  }
})

watch(() => props.refpoints, () => {
  autoCenter()
}, { deep: true })

onMounted(() => {
  autoCenter()
})
</script>

<style scoped>
.route-preview-canvas {
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
  width: 80px;
  accent-color: var(--color-primary);
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

.canvas-legend {
  display: flex;
  flex-wrap: wrap;
  gap: var(--spacing-md);
  padding: var(--spacing-sm) var(--spacing-md);
  background: var(--color-bg-2);
  border-top: 1px solid var(--color-border);
}

.legend-item {
  display: flex;
  align-items: center;
  gap: var(--spacing-xs);
  font-size: var(--font-size-xs);
  color: var(--color-text-2);
}

.legend-icon {
  width: 12px;
  height: 12px;
  border-radius: 2px;
}

.reference-point {
  cursor: pointer;
  transition: opacity var(--transition-fast);
}

.reference-point:hover {
  opacity: 0.7;
}

.route-point {
  cursor: pointer;
}

.route-point-draggable {
  cursor: move;
}

.route-point-draggable circle.draggable {
  cursor: move;
  transition: stroke-width var(--transition-fast);
}

.route-point-draggable circle.draggable:hover {
  stroke-width: 4;
}

.route-point-dragging {
  opacity: 0.5;
}

.route-point-dragging circle {
  stroke-dasharray: 4,4;
  animation: pulse 0.5s ease-in-out infinite;
}

.route-point-dragging circle {
  stroke-dasharray: 4,4;
  animation: pulse 0.5s ease-in-out infinite;
}

.route-point-active circle {
  stroke: var(--color-warning);
  stroke-width: 3;
}

.placement-origin {
  pointer-events: none;
}

.drag-preview-layer {
  pointer-events: none;
}

.drag-tooltip-layer {
  pointer-events: none;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.6;
  }
}
</style>
