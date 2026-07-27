<template>
  <div class="visual-canvas">
    <div class="canvas-header">
      <slot name="header" />
    </div>

    <div class="canvas-container" ref="canvasContainer">
      <svg
        ref="svg"
        :width="width"
        :height="height"
        :viewBox="`0 0 ${width} ${height}`"
        @mousedown="onMouseDown"
        @mousemove="onMouseMove"
        @mouseup="onMouseUp"
        @mouseleave="onMouseUp"
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
        <rect width="100%" height="100%" fill="var(--color-bg-1)" />
        <rect v-if="showGrid" width="100%" height="100%" fill="url(#grid)" />

        <!-- Transformed Content Layer -->
        <g :transform="`translate(${panX}, ${panY}) scale(${zoom})`">
          <slot :zoom="zoom" :panX="panX" :panY="panY" />
        </g>
      </svg>
      <slot name="controls" />
    </div>
  </div>
</template>

<script setup>
import { ref, provide, onMounted, computed, watch } from 'vue'
import { useCanvasCamera } from '../../composables/useCanvasCamera'

const props = defineProps({
  width: { type: Number, default: 800 },
  height: { type: Number, default: 500 },
  showGrid: { type: Boolean, default: true }
})

const emit = defineEmits(['camera-ready'])

const svg = ref(null)
const canvasContainer = ref(null)
const gridSize = 50
const svgRect = ref(null)

const camera = useCanvasCamera()
const { zoom, panX, panY, handleWheel } = camera

// Update svgRect when svg is mounted
onMounted(() => {
  if (svg.value) {
    svgRect.value = svg.value.getBoundingClientRect()
  }
  // Emit camera API to parent
  emit('camera-ready', {
    zoom,
    panX,
    panY,
    autoCenter: camera.autoCenter,
    resetView: camera.resetView,
    screenToWorld: camera.screenToWorld,
    svgRect
  })
})

// Provide camera instance to children who might need screenToWorld or autoCenter
provide('canvasCamera', { ...camera, svgRect })

const onMouseDown = (e) => {
  // We only pan if clicking the SVG background or grid, not elements
  if (e.target === svg.value || e.target.tagName === 'rect') {
    camera.startPan(e)
  }
}

const onMouseMove = (e) => {
  camera.handlePan(e)
}

const onMouseUp = () => {
  camera.endPan()
}

</script>

<style scoped>
.visual-canvas {
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

.canvas-container {
  position: relative;
  overflow: hidden;
  cursor: grab;
}

.canvas-container:active {
  cursor: grabbing;
}

:deep(.nav-controls) {
  position: absolute;
  bottom: var(--spacing-sm);
  right: var(--spacing-sm);
  display: flex;
  gap: var(--spacing-xs);
}
</style>
