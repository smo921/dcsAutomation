<template>
  <button
    :class="['btn', `btn-${variant}`, `btn-${size}`, { 'btn-icon-only': iconOnly, 'btn-block': block }]"
    :disabled="disabled"
    :type="type"
    v-bind="$attrs"
  >
    <span v-if="$slots.icon" class="btn-icon">
      <slot name="icon" />
    </span>
    <slot />
  </button>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  variant: {
    type: String,
    default: 'primary',
    validator: (value) => ['primary', 'danger', 'secondary', 'ghost'].includes(value)
  },
  size: {
    type: String,
    default: 'md',
    validator: (value) => ['sm', 'md', 'lg'].includes(value)
  },
  type: {
    type: String,
    default: 'button',
    validator: (value) => ['button', 'submit', 'reset'].includes(value)
  },
  disabled: {
    type: Boolean,
    default: false
  },
  block: {
    type: Boolean,
    default: false
  },
  iconOnly: {
    type: Boolean,
    default: false
  }
})

// Compute the CSS class prefix based on variant
const getVariantStyles = computed(() => {
  const styles = {
    primary: {
      background: 'var(--color-primary)',
      color: 'white',
      hover: 'var(--color-primary-hover)',
      focus: 'var(--color-border-focus)'
    },
    danger: {
      background: 'var(--color-error)',
      color: 'white',
      hover: 'var(--color-error-hover)',
      focus: 'var(--color-border-focus)'
    },
    secondary: {
      background: 'var(--color-bg-2)',
      color: 'var(--color-text-0)',
      border: 'var(--color-border)',
      hover: 'var(--color-bg-3)',
      focus: 'var(--color-border-focus)'
    },
    ghost: {
      background: 'transparent',
      color: 'var(--color-text-0)',
      hover: 'var(--color-bg-3)',
      focus: 'var(--color-border-focus)'
    }
  }
  return styles[props.variant]
})
</script>

<style scoped>
/* Base button styles */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  border-radius: var(--spacing-xxs);
  cursor: pointer;
  font-size: var(--font-size-sm);
  transition: all var(--transition-fast);
  white-space: nowrap;
}

/* Variants */
.btn-primary {
  background: var(--color-primary);
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: var(--color-primary-hover);
}

.btn-primary:focus:not(:disabled) {
  outline: 2px solid var(--color-border-focus);
  outline-offset: 2px;
}

.btn-danger {
  background: var(--color-error);
  color: white;
}

.btn-danger:hover:not(:disabled) {
  background: var(--color-error-hover);
}

.btn-danger:focus:not(:disabled) {
  outline: 2px solid var(--color-border-focus);
  outline-offset: 2px;
}

.btn-secondary {
  background: var(--color-bg-2);
  color: var(--color-text-0);
  border: 1px solid var(--color-border);
}

.btn-secondary:hover:not(:disabled) {
  background: var(--color-bg-3);
}

.btn-secondary:focus:not(:disabled) {
  outline: 2px solid var(--color-border-focus);
  outline-offset: 2px;
}

.btn-secondary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-ghost {
  background: transparent;
  color: var(--color-text-0);
}

.btn-ghost:hover:not(:disabled) {
  background: var(--color-bg-3);
}

.btn-ghost:focus:not(:disabled) {
  outline: 2px solid var(--color-border-focus);
  outline-offset: 2px;
}

/* Sizes */
.btn-sm {
  font-size: var(--font-size-xxs);
  padding: var(--spacing-xxs) var(--spacing-sm);
}

.btn-md {
  font-size: var(--font-size-sm);
  padding: var(--spacing-xs) var(--spacing-md);
}

.btn-lg {
  font-size: var(--font-size-md);
  padding: var(--spacing-sm) var(--spacing-lg);
}

/* Special variants */
.btn-icon-only {
  width: 32px;
  height: 32px;
  padding: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.btn-block {
  width: 100%;
}

/* Icon spacing */
.btn:not(.btn-icon-only) .btn-icon {
  margin-right: var(--spacing-xs);
}

.btn-icon-only .btn-icon {
  margin: 0;
}

/* Disabled state */
.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}
</style>
