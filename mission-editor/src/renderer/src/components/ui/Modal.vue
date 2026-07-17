<template>
  <div v-if="isOpen" class="modal-overlay" @click.self="handleBackgroundClick">
    <div class="modal-content" :class="`modal-${size}`" role="dialog" aria-modal="true" :aria-labelledby="dialogId">
      <div v-if="hasHeader" class="modal-header">
        <h3 class="modal-title" :id="dialogId">{{ title }}</h3>
        <button v-if="closable" class="modal-close-btn" @click="close" type="button">
          <span class="close-icon">×</span>
        </button>
      </div>

      <div class="modal-body">
        <slot name="content" />
      </div>

      <div v-if="$slots.actions" class="modal-actions">
        <slot name="actions" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch, useSlots } from 'vue'

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  open: {
    type: Boolean,
    default: false
  },
  title: {
    type: String,
    default: ''
  },
  closable: {
    type: Boolean,
    default: true
  },
  closeOnBackground: {
    type: Boolean,
    default: true
  },
  closeText: {
    type: String,
    default: 'Close'
  },
  size: {
    type: String,
    default: 'md',
    validator: (value) => ['sm', 'md', 'lg', 'xl'].includes(value)
  }
})

const emit = defineEmits(['update:modelValue', 'update:open', 'close'])

// Support both v-model (modelValue) and v-model:open
// Use computed for two-way binding
const isOpen = computed({
  get: () => props.open || props.modelValue,
  set: (value) => {
    emit('update:open', value)
    emit('update:modelValue', value)
  }
})
const dialogId = ref(`modal-${Math.random().toString(36).substring(7)}`)

const hasHeader = computed(() => !!props.title || props.closable)

const hasDefaultSlot = computed(() => {
  const slots = useSlots()
  return slots.default && slots.default().length > 0
})

const open = () => {
  isOpen.value = true
  emit('update:modelValue', true)
}

const close = () => {
  isOpen.value = false
  emit('update:modelValue', false)
  emit('update:open', false)
  emit('close')
}

const handleBackgroundClick = () => {
  if (props.closeOnBackground) {
    close()
  }
}

// Focus management and keyboard handling
onMounted(() => {
  if (props.modelValue) {
    trapFocus()
  }
  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && isOpen.value) {
      close()
    }
  })
})

onUnmounted(() => {
  isOpen.value = false
})

watch(() => props.modelValue, (newVal) => {
  isOpen.value = newVal
  if (newVal) {
    trapFocus()
  }
})

watch(() => props.open, (newVal) => {
  isOpen.value = newVal
  if (newVal) {
    trapFocus()
  }
})

// Focus trap utility
const trapFocus = () => {
  const modal = document.querySelector('.modal-content')
  if (!modal) return

  const focusable = modal.querySelectorAll(
    'a[href], button, input, select, textarea, [tabindex]:not([tabindex="-1"])'
  )
  const first = focusable[0]
  const last = focusable[focusable.length - 1]

  const handleKeydown = (e) => {
    if (e.key !== 'Tab') return

    if (e.shiftKey) {
      if (document.activeElement === first) {
        last.focus()
        e.preventDefault()
      }
    } else {
      if (document.activeElement === last) {
        first.focus()
        e.preventDefault()
      }
    }
  }

  modal.addEventListener('keydown', handleKeydown)
  if (first) first.focus()
}
</script>

<style>
/* Shared styles from _utils.css:
   - modal-overlay, modal-content, modal-header, modal-title, modal-close-btn
   - modal-body, modal-actions, btn-close-modal
   - fadeIn, zoomIn animations
*/
</style>
