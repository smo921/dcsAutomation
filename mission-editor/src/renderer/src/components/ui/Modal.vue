<template>
  <div v-if="isOpen" class="modal-overlay" @click.self="handleBackgroundClick">
    <div class="modal-content" role="dialog" aria-modal="true" :aria-labelledby="dialogId">
      <div v-if="hasHeader" class="modal-header">
        <h3 class="modal-title" :id="dialogId">{{ title }}</h3>
        <button v-if="closable" class="modal-close-btn" @click="close" type="button">
          <span class="close-icon">×</span>
        </button>
      </div>

      <div class="modal-body">
        <slot name="content" />
      </div>

      <div v-if="$slots.actions || hasDefaultSlot" class="modal-actions">
        <slot name="actions">
          <button v-if="hasDefaultSlot" class="btn-close-modal" @click="close">
            {{ closeText }}
          </button>
        </slot>
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
  }
})

const emit = defineEmits(['update:modelValue', 'close'])

const isOpen = ref(props.modelValue)
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

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: var(--color-overlay);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  animation: fadeIn var(--transition-normal);
}

.modal-content {
  background: var(--color-bg-1);
  border: 1px solid var(--color-border);
  border-radius: var(--spacing-xs);
  padding: var(--spacing-xl);
  min-width: 300px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5);
  animation: zoomIn var(--transition-normal);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: var(--spacing-md);
}

.modal-title {
  font-size: var(--font-size-2xl);
  color: var(--color-text-4);
  margin: 0;
}

.modal-close-btn {
  background: transparent;
  border: none;
  color: var(--color-text-1);
  font-size: var(--font-size-3xl);
  cursor: pointer;
  padding: var(--spacing-xs);
  line-height: 1;
  border-radius: var(--spacing-xxs);
  transition: all var(--transition-fast);
}

.modal-close-btn:hover {
  background: var(--color-bg-2);
  color: var(--color-text-0);
}

.modal-body {
  margin-bottom: var(--spacing-lg);
}

.modal-body :deep(*) {
  margin-bottom: var(--spacing-sm);
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--spacing-sm);
}

.btn-close-modal {
  background: var(--color-bg-2);
  color: var(--color-text-0);
  border: 1px solid var(--color-border);
  padding: var(--spacing-sm) var(--spacing-md);
  border-radius: var(--spacing-xxs);
  cursor: pointer;
  font-size: var(--font-size-sm);
  transition: all var(--transition-fast);
}

.btn-close-modal:hover {
  background: var(--color-bg-3);
}

/* Animations */
@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes zoomIn {
  from {
    transform: scale(0.95);
    opacity: 0;
  }
  to {
    transform: scale(1);
    opacity: 1;
  }
}
</style>
