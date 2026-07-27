import { ref } from 'vue'

export function useCanvasCamera() {
  const zoom = ref(1)
  const panX = ref(0)
  const panY = ref(0)
  const isPanning = ref(false)
  const panStart = ref({ x: 0, y: 0 })

  const handleWheel = (e) => {
    if (e.cancelable) e.preventDefault()
    const delta = e.deltaY > 0 ? 0.9 : 1.1
    zoom.value = Math.max(0.1, Math.min(5, zoom.value * delta))
  }

  const startPan = (e) => {
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

  const screenToWorld = (screenX, screenY, svgRect) => {
    return {
      x: (screenX - svgRect.left - panX.value) / zoom.value,
      y: (screenY - svgRect.top - panY.value) / zoom.value
    }
  }

  const autoCenter = (points, width, height, padding = 100) => {
    if (!points || points.length === 0) return

    const xs = points.map(p => p.x)
    const ys = points.map(p => p.y)
    const minX = Math.min(...xs)
    const maxX = Math.max(...xs)
    const minY = Math.min(...ys)
    const maxY = Math.max(...ys)

    const centerX = (minX + maxX) / 2
    const centerY = (minY + maxY) / 2
    const contentWidth = (maxX - minX) + padding * 2
    const contentHeight = (maxY - minY) + padding * 2

    const zoomX = width / contentWidth
    const zoomY = height / contentHeight
    zoom.value = Math.min(zoomX, zoomY, 2)

    panX.value = width / 2 - centerX * zoom.value
    panY.value = height / 2 - centerY * zoom.value
  }

  const resetView = () => {
    zoom.value = 1
    panX.value = 0
    panY.value = 0
  }

  return {
    zoom,
    panX,
    panY,
    isPanning,
    handleWheel,
    startPan,
    handlePan,
    endPan,
    screenToWorld,
    autoCenter,
    resetView
  }
}
