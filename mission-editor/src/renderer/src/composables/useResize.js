import { ref, onMounted, onUnmounted } from 'vue'

/**
 * Composable for handling resize functionality
 * @param {Object} options
 * @param {Ref<number>} options.size - Reactive ref for size value (height or width)
 * @param {number} options.minSize - Minimum size in pixels
 * @param {number} options.maxSize - Maximum size in pixels
 * @param {string} options.direction - Resize direction: 'vertical' or 'horizontal'
 * @returns {Object} Resize handlers
 */
export function useResize(options = {}) {
  const {
    size,
    minSize = 100,
    maxSize = 500,
    direction = 'vertical'
  } = options

  const isResizing = ref(false)
  const startValue = ref(0)
  const startSize = ref(0)

  // Create unique event handlers for this instance
  const handleMouseUp = () => {
    isResizing.value = false
    document.body.style.cursor = ''
    document.body.style.userSelect = ''
  }

  const handleMouseMove = (e) => {
    if (!isResizing.value) return

    const currentValue = direction === 'vertical' ? e.clientY : e.clientX
    const delta = currentValue - startValue.value
    const newSize = Math.max(minSize, Math.min(maxSize, startSize.value + delta))

    size.value = newSize
  }

  const startResize = (e) => {
    isResizing.value = true
    startValue.value = direction === 'vertical' ? e.clientY : e.clientX
    startSize.value = size.value

    document.body.style.cursor = direction === 'vertical' ? 'ns-resize' : 'col-resize'
    document.body.style.userSelect = 'none'
  }

  const stopResize = () => {
    isResizing.value = false
    document.body.style.cursor = ''
    document.body.style.userSelect = ''
  }

  // Add event listeners on mount
  onMounted(() => {
    document.addEventListener('mouseup', handleMouseUp)
    document.addEventListener('mousemove', handleMouseMove)
  })

  // Cleanup on unmount
  onUnmounted(() => {
    document.removeEventListener('mouseup', handleMouseUp)
    document.removeEventListener('mousemove', handleMouseMove)
  })

  return {
    isResizing,
    startResize,
    stopResize,
    onResize: handleMouseMove
  }
}
