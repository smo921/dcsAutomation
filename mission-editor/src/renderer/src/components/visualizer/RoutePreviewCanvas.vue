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

        <!-- Reference points -->
        <g v-if="showReference" class="reference-layer" :transform="`translate(${panX}, ${panY}) scale(${zoom})`">
          <!-- Bullseye -->
          <g
            v-for="bullseye in refpoints.bullseyes"
            :key="`bullseye-${bullseye.name}`"
            :transform="`translate(${bullseye.x || 0}, ${bullseye.y || 0})`"
            class="reference-point"
          >
            <circle r="8" fill="var(--color-primary)" opacity="0.3" />
            <text y="-10" text-anchor="middle" fill="var(--color-text-1)" font-size="10">{{ bullseye.name }}</text>
          </g>

          <!-- Airbases -->
          <g
            v-for="airbase in refpoints.airbases"
            :key="`airbase-${airbase.name}`"
            :transform="`translate(${airbase.x || 0}, ${airbase.y || 0})`"
            class="reference-point"
          >
            <rect x="-6" y="-6" width="12" height="12" fill="var(--color-success)" opacity="0.3" />
            <text y="-10" text-anchor="middle" fill="var(--color-text-1)" font-size="10">{{ airbase.name }}</text>
          </g>

          <!-- Trigger Zones -->
          <g
            v-for="zone in refpoints.zones"
            :key="`zone-${zone.name}`"
            :transform="`translate(${zone.x || 0}, ${zone.y || 0})`"
            class="reference-point"
          >
            <circle :r="zone.radius ? zone.radius / 100 : 50" fill="var(--color-warning)" opacity="0.15" />
            <circle :r="3" fill="var(--color-warning)" opacity="0.5" />
            <text y="-10" text-anchor="middle" fill="var(--color-text-1)" font-size="10">{{ zone.name }}</text>
          </g>

          <!-- Battle Lines -->
          <g
            v-for="line in refpoints.lines"
            :key="`line-${line.name}`"
            class="reference-point"
          >
            <line
              :x1="line.start?.x || 0"
              :y1="line.start?.y || 0"
              :x2="line.end?.x || 0"
              :y2="line.end?.y || 0"
              stroke="var(--color-error)"
              stroke-width="2"
              stroke-dasharray="5,5"
              opacity="0.5"
            />
            <text
              :x="(line.start?.x || 0 + line.end?.x || 0) / 2"
              :y="(line.start?.y || 0 + line.end?.y || 0) / 2"
              fill="var(--color-text-1)"
              font-size="10"
              text-anchor="middle"
            >
              {{ line.name }}
            </text>
          </g>
        </g>

        <!-- Route path -->
        <g class="route-layer" :transform="`translate(${panX}, ${panY}) scale(${zoom})`">
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
            :class="{ 'route-point-active': index === activePoint }"
          >
            <!-- Point marker -->
            <circle
              r="10"
              :fill="getPointColor(point.type)"
              :stroke="getPointStroke(point.type)"
              stroke-width="2"
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

            <!-- Point type label -->
            <text
              y="-12"
              text-anchor="middle"
              fill="var(--color-text-1)"
              font-size="10"
            >
              {{ formatPointType(point.type) }}
            </text>

            <!-- Speed indicator -->
            <text
              v-if="showSpeeds && point.speed"
              y="25"
              text-anchor="middle"
              fill="var(--color-text-2)"
              font-size="9"
            >
              {{ point.speed }} kt
            </text>

            <!-- Altitude indicator -->
            <text
              v-if="point.altitude"
              y="35"
              text-anchor="middle"
              fill="var(--color-text-3)"
              font-size="8"
            >
              {{ formatAltitude(point.altitude) }}
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

const emit = defineEmits(['point-select'])

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

const gridSize = 50
const hasInitializedView = ref(false)

// Compute route points with raw coordinates (transform applied via SVG)
const routePoints = computed(() => {
  return props.route.map((point, index) => {
    let x = 0
    let y = 0

    // Use x/y if available (turn_point, heading), otherwise compute from index
    if (point.x !== undefined && point.y !== undefined) {
      x = point.x
      y = point.y
    } else {
      // Default spacing for visualization
      const spacing = 100
      x = index * spacing
      y = 50 + (index % 3) * 30
    }

    return {
      ...point,
      rawX: x,
      rawY: y
    }
  })
})

// All connection points including start position
const allConnectionPoints = computed(() => {
  const points = []

  // Add start point at (0,0) if we have any placement mode (represents reference point or origin)
  // This connects the start to the first route point
  if (props.placement?.mode) {
    if (props.placement.mode === 'COORDINATE' && props.placement.x && props.placement.y) {
      points.push({ x: props.placement.x, y: props.placement.y })
    } else {
      // For other modes, start is at origin (0,0) relative to the reference point
      points.push({ x: 0, y: 0 })
    }
  }

  // Add all route points
  routePoints.value.forEach(p => {
    points.push({ x: p.rawX, y: p.rawY })
  })

  return points
})

// Calculate the center point for auto-centering
const getCenterPoint = () => {
  const allPoints = []
  let centerOnRefPoint = false

  // Add placement origin based on placement mode
  if (props.placement?.mode) {
    if (props.placement.mode === 'COORDINATE' && props.placement.x && props.placement.y) {
      allPoints.push({ x: props.placement.x, y: props.placement.y })
    } else if (props.placement.mode === 'BEARING_DISTANCE' && props.placement.referenceName) {
      // Find the reference point and center on it
      const refType = props.placement.reference
      let refPoint = null

      if (refType === 'bullseye') {
        refPoint = props.refpoints?.bullseyes?.find(p => p.name === props.placement.referenceName)
      } else if (refType === 'airbase') {
        refPoint = props.refpoints?.airbases?.find(p => p.name === props.placement.referenceName)
      } else if (refType === 'zone') {
        refPoint = props.refpoints?.zones?.find(p => p.name === props.placement.referenceName)
      }

      if (refPoint && refPoint.x !== undefined) {
        allPoints.push({ x: refPoint.x, y: refPoint.y })
        centerOnRefPoint = true
      }
    } else if (props.placement.mode === 'AIRBASE_RAMP' && props.placement.referenceName) {
      const airbase = props.refpoints?.airbases?.find(p => p.name === props.placement.referenceName)
      if (airbase && airbase.x !== undefined) {
        allPoints.push({ x: airbase.x, y: airbase.y })
        centerOnRefPoint = true
      }
    } else if (props.placement.mode === 'ZONE_CENTER' && props.placement.referenceName) {
      const zone = props.refpoints?.zones?.find(p => p.name === props.placement.referenceName)
      if (zone && zone.x !== undefined) {
        allPoints.push({ x: zone.x, y: zone.y })
        centerOnRefPoint = true
      }
    }
  }

  // Add route points
  props.route.forEach((point, index) => {
    if (point.x !== undefined && point.y !== undefined) {
      allPoints.push({ x: point.x, y: point.y })
    } else if (!centerOnRefPoint) {
      // Only add default positions if not centering on a reference point
      const spacing = 100
      allPoints.push({ x: index * spacing, y: 50 + (index % 3) * 30 })
    }
  })

  // Add reference points if showing them
  if (showReference.value) {
    props.refpoints?.bullseyes?.forEach(p => { if (p.x !== undefined) allPoints.push({ x: p.x, y: p.y }) })
    props.refpoints?.airbases?.forEach(p => { if (p.x !== undefined) allPoints.push({ x: p.x, y: p.y }) })
    props.refpoints?.zones?.forEach(p => { if (p.x !== undefined) allPoints.push({ x: p.x, y: p.y }) })
    props.refpoints?.lines?.forEach(line => {
      if (line.start?.x !== undefined) allPoints.push({ x: line.start.x, y: line.start.y })
      if (line.end?.x !== undefined) allPoints.push({ x: line.end.x, y: line.end.y })
    })
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

// Compute placement origin (raw coordinates, transform applied via SVG)
const placementOrigin = computed(() => {
  if (!props.placement || !props.placement.mode) return null

  const mode = props.placement.mode
  if (mode === 'COORDINATE' && props.placement.x && props.placement.y) {
    return {
      rawX: props.placement.x,
      rawY: props.placement.y
    }
  }

  // For BEARING_DISTANCE and other reference-based modes, use (0,0) as the reference point
  // The actual position will be relative to the reference point which is shown on the map
  return {
    rawX: 0,
    rawY: 0
  }
})

// Only show placement origin marker when we have explicit coordinates
const showPlacementOrigin = computed(() => {
  return props.placement?.mode === 'COORDINATE' && props.placement.x && props.placement.y
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
  transition: transform var(--transition-fast);
}

.route-point:hover {
  transform: scale(1.2);
}

.route-point-active circle {
  stroke: var(--color-warning);
  stroke-width: 3;
}

.placement-origin {
  pointer-events: none;
}
</style>
